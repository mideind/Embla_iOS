/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2019-2020 Miðeind ehf.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/*
    View controller for the main Embla session view.
*/


#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MainViewController.h"
#import "QuerySession.h"
#import "Common.h"
#import "AudioRecordingService.h"
#import "Reachability.h"
#import "NSString+Additions.h"


static NSString * const kIntroMessage = \
@"Segðu „Hæ Embla“ eða smelltu á hnappinn til þess að tala við Emblu.";

static NSString * const kIntroNoVoiceActivationMessage = \
@"Smelltu á hnappinn til þess að tala við Emblu.";

static NSString * const kNoInternetConnectivityMessage = \
@"Ekki næst samband við netið.";

static NSString * const kServerErrorMessage = \
@"Villa kom upp í samskiptum við netþjón.";


#define CANCEL_COMMANDS \
@[@"hætta", @"hætta við", @"hættu", @"ekkert", @"skiptir ekki máli"]

#define DISABLE_VOICEACTIV_COMMANDS \
@[@"þegiðu", @"þegi þú", @"ekki hlusta", @"hættu að hlusta"]


@interface MainViewController () <QuerySessionDelegate>
{
    AVAudioPlayer *player;
    NSMutableDictionary *uiSounds;
    CADisplayLink *displayLink;
    Reachability *reach;
}
@property (nonatomic, weak) IBOutlet UIBarButtonItem *micItem;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet SessionButton *button;
@property (nonatomic, retain) QuerySession *currentSession;
@property BOOL connected;

@end


@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    
    self.textView.text = [self introMessage];
    
    [self preloadSounds];
    [self setUpReachability];
    
    self.button.audioLevelSource = self;
    
    // Listen for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becameActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resignedActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    // Receive messages from activation listener
    [[ActivationListener sharedInstance] setDelegate:self];
    
    // Prepare for audio recording
    [[AudioRecordingService sharedInstance] prepareWithSampleRate:REC_SAMPLE_RATE];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    DLog(@"Main view will appear");
    
    [self setUpReachability];
        
    // Don't let device go to sleep while this view is active
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    // Voice activation
    BOOL voiceActivation = [DEFAULTS boolForKey:@"VoiceActivation"];
    if (voiceActivation) {
        [[ActivationListener sharedInstance] startListening];
    }
    // Update state of voice activation bar button item and intro message
    self.micItem.image = [UIImage imageNamed:voiceActivation ? @"Microphone" : @"MicrophoneSlash"];
    self.textView.text = [self introMessage];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    DLog(@"Main view will disappear");
    
    // Terminate any ongoing session
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
        self.currentSession = nil;
    }
    player = nil; // Silence any sound being played
    [[ActivationListener sharedInstance] stopListening];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)viewDidLayoutSubviews {
    // Add fadeout gradient to text view
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.textView.superview.bounds;
    gradient.colors = @[(id)[UIColor clearColor].CGColor,
                        (id)[UIColor blackColor].CGColor,
                        (id)[UIColor blackColor].CGColor,
                        (id)[UIColor clearColor].CGColor];
    gradient.locations = @[@0.0, @0.05, @0.95, @1.0];
    self.textView.superview.layer.mask = gradient;
}

#pragma mark - Respond to notifications

- (void)becameActive:(NSNotification *)notification {
    DLog(@"%@", [notification description]);
    if ([DEFAULTS boolForKey:@"VoiceActivation"]) {
        // Only reactivate if this is the frontmost view controller
        UINavigationController *navCtrl = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
        if (navCtrl.topViewController == self) {
            [[ActivationListener sharedInstance] startListening];
        }
    }
}

- (void)resignedActive:(NSNotification *)notification {
    DLog(@"%@", [notification description]);
    // Terminate any ongoing session
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
        self.currentSession = nil;
    }
    
    [[ActivationListener sharedInstance] stopListening];
}

- (void)cancelCommandReceived:(NSNotification *)notification {
    [self sessionDidReceiveTranscripts:nil];
    [self.currentSession terminate];
}

- (void)disableVoiceActivationReceived:(NSNotification *)notification {
    [self toggleVoiceActivation:self];
    [self sessionDidReceiveTranscripts:nil];
    [self.currentSession terminate];
}

#pragma mark - Reachability

- (void)becameReachable {
    DLog(@"Network became reachable");
    self.connected = YES;
}

- (void)becameUnreachable {
    DLog(@"Network became unreachable");
    self.connected = NO;
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
        self.currentSession = nil;
        [self playUISound:@"conn"];
        [self log:kNoInternetConnectivityMessage];
    }
}

- (void)setUpReachability {
    if (reach) {
        [reach stopNotifier];
    }
    reach = [Reachability reachabilityWithHostname:REACHABILITY_HOSTNAME];

    id controller = self;
    reach.reachableBlock = ^(Reachability*reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [controller becameReachable];
        });
    };

    reach.unreachableBlock = ^(Reachability*reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [controller becameUnreachable];
        });
    };

    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
}

#pragma mark - Alerts

- (void)showMicAlert {
    NSString *msg = @"Þetta forrit þarf aðgang að hljóðnema til þess að virka sem skyldi.\
Aðgangi er stýrt í kerfisstillingum.";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Lokað á hljóðnema"
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *activateAction = [UIAlertAction actionWithTitle:@"Virkja"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                               [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                                                           }];
    [alert addAction:activateAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Hætta við"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - ActivationListenerDelegate

- (void)didHearActivationPhrase:(NSString *)phrase {
    if (!(self.currentSession && !self.currentSession.terminated)) {
        [[ActivationListener sharedInstance] stopListening];
        [self startSession];
    }
}

- (IBAction)toggleVoiceActivation:(id)sender {
    BOOL enabled = [DEFAULTS boolForKey:@"VoiceActivation"];
    [DEFAULTS setBool:!enabled forKey:@"VoiceActivation"];
    [DEFAULTS synchronize];
    enabled = !enabled;
    
    DLog(@"Voice activation: %d", enabled);
    
    if (enabled && !self.currentSession) {
        [[ActivationListener sharedInstance] startListening];
    } else {
        [[ActivationListener sharedInstance] stopListening];
    }
    self.micItem.image = [UIImage imageNamed:enabled ? @"Microphone" : @"MicrophoneSlash"];
    self.textView.text = [self introMessage];
}

- (NSString *)introMessage {
    if ([DEFAULTS boolForKey:@"VoiceActivation"]) {
        return kIntroMessage;
    } else {
        return kIntroNoVoiceActivationMessage;
    }
}

#pragma mark - Session

- (IBAction)buttonPressed:(id)sender {
    if (self.currentSession && !self.currentSession.terminated) {
        [self endSession];
    } else {
        // Make sure that we have permission to access the mic
        if ([AVAudioSession sharedInstance].recordPermission != AVAudioSessionRecordPermissionGranted) {
            [self showMicAlert];
            return;
        }
        [self startSession];
    }
}

- (void)startSession {
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
    }
    
    [self clearLog];
    
    // Abort if no internet connection
    if (!self.connected) {
        [self playUISound:@"conn"];
        [self log:kNoInternetConnectivityMessage];
        return;
    }
    
    [[ActivationListener sharedInstance] stopListening];
    
    // Create new session
    self.currentSession = [[QuerySession alloc] initWithDelegate:self];
    [self playUISound:@"rec_begin"];
    [self.button expand];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.35 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.currentSession start];
    });
}

- (void)endSession {
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
        self.currentSession = nil;
    }
}

#pragma mark - QuerySessionDelegate

- (void)sessionDidStartRecording {
    [self.textView setContentOffset:CGPointZero animated:NO];
    [self.button startWaveform];
}

- (void)sessionDidStopRecording {
    [self.button stopWaveform];
    [self.button startAnimating];
}

- (void)sessionDidReceiveInterimResults:(NSArray<NSString *> *)results {
    [self clearLog];
    [self log:@"%@", [[results firstObject] sentenceCapitalizedString]];
}

- (void)sessionDidReceiveTranscripts:(NSArray<NSString *> *)alternatives {
    [self clearLog];
    if (!alternatives || ![alternatives count]) {
        [self playUISound:@"rec_cancel"];
        return;
    }
    
    // Check if the transcript contains a command to be handled locally
    // on the client without sending transcripts to query server.
    // TODO: Make this cleaner.
    NSString *cmd;
    if ((cmd = [self _containsCancelCommand:alternatives])) {
        [self log:@"%@", [cmd sentenceCapitalizedString]];
        [self playUISound:@"rec_cancel"];
        [self.currentSession terminate];
    }
    else if ((cmd = [self _containsDisableVoiceActivationCommand:alternatives])) {
        [self log:@"%@", [cmd sentenceCapitalizedString]];
        [self playUISound:@"rec_confirm"];
        if ([DEFAULTS boolForKey:@"VoiceActivation"]) {
            [self toggleVoiceActivation:self];
        }
        [self.currentSession terminate];
    }
    // This is not a local command, handle normally
    else {
        NSString *questionStr = [[alternatives firstObject] sentenceCapitalizedString];
        [self log:@"%@", questionStr];
        [self playUISound:@"rec_confirm"];
    }
}

- (NSString *)_containsCancelCommand:(NSArray *)strings {
    if ([strings count] == 0) {
        return nil;
    }
    for (NSString *s in [strings subarrayWithRange:NSMakeRange(0, MIN([strings count], 5))]) {
        if ([CANCEL_COMMANDS containsObject:s]) {
            return s;
        }
    }
    return nil;
}

- (NSString *)_containsDisableVoiceActivationCommand:(NSArray *)strings {
    if ([strings count] == 0) {
        return nil;
    }
    for (NSString *s in [strings subarrayWithRange:NSMakeRange(0, MIN([strings count], 5))]) {
        if ([DISABLE_VOICEACTIV_COMMANDS containsObject:s]) {
            return s;
        }
    }
    return nil;
}

- (void)sessionDidReceiveAnswer:(NSString *)answer
                     toQuestion:(NSString *)question
                         source:(NSString *)source
                        withURL:(NSURL *)url {
    [self clearLog];
    
    NSString *aStr = answer ? answer : @"";
    NSString *separator = answer ? @"\n\n" : @"";
    NSString *srcStr = source ? [NSString stringWithFormat:@" (%@)", source] : @"";
    [self log:@"%@%@%@%@",  [question sentenceCapitalizedString], separator,
                            [[aStr sentenceCapitalizedString] periodTerminatedString],
                            srcStr];
    
    // If we receive an URL in the response from the query server,
    // we terminate the session and ask the OS to open the URL.
    if (url) {
        [self.currentSession terminate];
        DLog(@"Opening URL: %@", url);
        [[UIApplication sharedApplication] openURL:url
                                           options:@{}
                                 completionHandler:^(BOOL success){}];
    }
}

- (void)sessionDidRaiseError:(NSError *)error {
    [self clearLog];
    if (self.connected) {
        [self log:kServerErrorMessage];
#ifdef DEBUG
        [self log:[error localizedDescription]];
#endif
        [self playUISound:@"err"];
    } else {
        [self log:kNoInternetConnectivityMessage];
        [self playUISound:@"conn"];
    }
    [self.currentSession terminate];
    self.currentSession = nil;
}

- (void)sessionDidTerminate {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.button contract];
        [self.button stopAnimating];
        [self.button stopWaveform];
        if ([DEFAULTS boolForKey:@"VoiceActivation"]) {
            [[ActivationListener sharedInstance] startListening];
        }
        if ([self.textView.text isEqualToString:@""]) {
            self.textView.text = [self introMessage];
        }
    }];
}

#pragma mark - User Interface Log

- (void)clearLog {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.textView.text = @"";
    }];
}

- (void)log:(NSString *)message, ... {
    va_list args;
    va_start(args, message);
    NSString *formattedString = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.textView.text = [NSString stringWithFormat:@"%@%@\n", self.textView.text, formattedString];
    }];
}

#pragma mark - Waveform view

- (CGFloat)audioLevel {
    return self.currentSession ? [self.currentSession audioLevel] : 0.0f;
}

#pragma mark - UI sounds

- (void)playUISound:(NSString *)fileName {
    NSArray *voiceSounds = @[@"err", @"conn", @"dunno"];
    
    if ([voiceSounds containsObject:fileName]) {
        NSUInteger vid = [[DEFAULTS objectForKey:@"Voice"] unsignedIntegerValue];
        NSString *suffix = vid == 0 ? @"dora" : @"karl";
        fileName = [NSString stringWithFormat:@"%@-%@", fileName, suffix];
    }
    
    if ([uiSounds objectForKey:fileName]) {
        player = [[AVAudioPlayer alloc] initWithData:uiSounds[fileName] error:nil];
        [player setVolume:1.0];
        [player play];
    } else {
        DLog(@"Unable to play audio file '%@'", fileName);
    }
}

- (void)preloadSounds {
    uiSounds = [NSMutableDictionary new];
    
    NSArray *files = @[@"rec_begin", @"rec_cancel", @"rec_confirm",
                       @"err-dora", @"conn-dora", @"dunno-dora",
                       @"err-karl", @"conn-karl", @"dunno-karl"];
    
    // Load all sound files into memory
    for (NSString *fileName in files) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"wav"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
            uiSounds[fileName] = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedAlways error:nil];
        } else {
            DLog(@"Unable to load audio file '%@'", fileName);
        }
    }
}

@end
