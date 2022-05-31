/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2019-2022 Miðeind ehf.
 * Author: Sveinbjorn Thordarson
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
#import "SessionViewController.h"
#import "QuerySession.h"
#import "Common.h"
#import "AudioRecordingService.h"
#import "SpeechRecognitionService.h"
#import "JSExecutor.h"
#import "Reachability.h"
#import "NSString+Additions.h"
#import "UIImage+Additions.h"
#import "QueryService.h"

static NSString * const kIntroMessage = \
@"Segðu „Hæ Embla“ eða smelltu á hnappinn til þess að tala við Emblu.";

static NSString * const kIntroNoHotwordMessage = \
@"Smelltu á hnappinn til þess að tala við Emblu.";

static NSString * const kNoInternetConnectivityMessage = \
@"Ekki næst samband við netið.";

static NSString * const kServerErrorMessage = \
@"Villa kom upp í samskiptum við netþjón.";

static NSString * const kMicrophoneDisabledMessage = \
@"Þetta forrit þarf aðgang að hljóðnema til þess að virka sem skyldi. \
Aðgangi er stýrt í kerfisstillingum.";

static NSString * const kNoSpeechAPIKeyMessage = \
@"Enginn aðgangslykill fyrir forritaskil talgreiningar.";

static NSString * const kSessionButtonLabelResting = \
@"Tala við Emblu";

static NSString * const kSessionButtonLabelActive = \
@"Hætta að tala við Emblu";

#define CANCEL_COMMANDS \
@[@"hætta", @"hætta við", @"hættu", @"ekkert", @"skiptir ekki máli"]

#define DISABLE_VOICEACTIV_COMMANDS \
@[@"þegiðu", @"þegi þú", @"ekki hlusta", @"hættu að hlusta"]


@interface SessionViewController () <QuerySessionDelegate>
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


@implementation SessionViewController

#pragma mark - UIViewController

- (id<HotwordDetector>)detector {
    NSString *detectorPref = [DEFAULTS stringForKey:@"HotwordDetector"];
    NSString *detectorName = detectorPref ? detectorPref : DEFAULT_HOTWORD_DETECTOR;
    NSString *detectorClassName = [detectorName stringByAppendingString:@"Detector"];
    Class detectorClass = NSClassFromString(detectorClassName);
    if (detectorClass == nil) {
        NSClassFromString([NSString stringWithFormat:@"%@Detector", DEFAULT_HOTWORD_DETECTOR]);
    }
    [[detectorClass sharedInstance] setDelegate:self];
    return [detectorClass sharedInstance];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    
    // Preload/pre-initialize the following to prevent any delay when session is activated
    [self preloadSounds];
    
    // Receive messages from hotword detector
    [[self detector] setDelegate:self];
    
    [AVAudioSession sharedInstance];
    [SpeechRecognitionService sharedInstance];
    
    // Prepare for audio recording
    [[AudioRecordingService sharedInstance] prepare];
    
    // Provide audio level to button in waveform state
    self.button.audioLevelSource = self;
    
    // Listen for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didResignActive:)
                                                 name:UIApplicationWillResignActiveNotification object:nil];
    
    // Configure Dynamic Type for the text view. Setting this in Interface Builder doesn't
    // work because we're using a custom bundled font so we have to do it manually.
    UIFont *customFont = [UIFont fontWithName:@"Lato-Italic" size:23.0f];
    if (customFont) {
        self.textView.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:customFont];
        self.textView.adjustsFontForContentSizeCategory = YES;
    }
}

#pragma mark - Respond to app state changes

- (void)didBecomeActive:(NSNotification *)notification {
    DLog(@"%@", notification);
    [self setup];
}

- (void)didResignActive:(NSNotification *)notification {
    DLog(@"%@", notification);
    [self teardown];
}

#pragma mark - Respond to view state changes

- (void)viewWillAppear:(BOOL)animated {
    DLog(@"Main view will appear");
    [super viewWillAppear:animated];
    [self setup];
}

- (void)viewWillDisappear:(BOOL)animated {
    DLog(@"Main view will disappear");
    [super viewWillDisappear:animated];
    [self teardown];
}

#pragma mark - Setup & teardown

- (void)setup {
    DLog(@"Main view setup");
    
    [self setUpReachability];
        
    // Don't let device go to sleep while this view is active
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    // Hotword activation
    BOOL hotwordActivation = [DEFAULTS boolForKey:@"VoiceActivation"];
    if (hotwordActivation) {
        // Only reactivate hotword detection if this is the frontmost view controller
        id rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        UINavigationController *navCtrl = (UINavigationController *)rootVC;
        if (navCtrl.topViewController == self) {
            [[self detector] startListening];
        }
    }
    // Update state of hotword detection bar button item and intro message
    self.micItem.image = [UIImage systemImageNamed:hotwordActivation ? @"mic.fill" : @"mic.slash.fill"];
    self.textView.text = [self introMessage];
}

- (void)teardown {
    DLog(@"Main view teardown");
    
    // Terminate any ongoing session
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
        self.currentSession = nil;
    }
    player = nil; // Silence any sound being played
    [[self detector] stopListening];
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

#pragma mark - Reachability (internet connectivity)

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

#pragma mark - Alerts

- (void)showMicAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Lokað á hljóðnema"
                                                                   message:kMicrophoneDisabledMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    // Open settings if user wants to enable mic
    UIAlertAction *activateAction = [UIAlertAction actionWithTitle:@"Virkja"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                               [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                                                           }];
    [alert addAction:activateAction];
    
    // Cancel
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Hætta við"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - ActivationListenerDelegate

- (void)didHearHotword:(NSString *)phrase {
    if (!(self.currentSession && !self.currentSession.terminated)) {
        [[self detector] stopListening];
        [self startSession];
    }
}

- (IBAction)toggleVoiceActivation:(id)sender {
    BOOL enabled = [DEFAULTS boolForKey:@"VoiceActivation"];
    [DEFAULTS setBool:!enabled forKey:@"VoiceActivation"];
    [DEFAULTS synchronize];
    enabled = !enabled;
    
    DLog(@"Hotword activation: %d", enabled);
    
    if (enabled && (!self.currentSession || self.currentSession.terminated)) {
        [[self detector] startListening];
    } else {
        [[self detector] stopListening];
    }
    self.micItem.image = [UIImage systemImageNamed:enabled ? @"mic.fill" : @"mic.slash.fill"];
    self.textView.text = [self introMessage];
}

- (NSString *)introMessage {
    if ([DEFAULTS boolForKey:@"VoiceActivation"]) {
        return kIntroMessage;
    } else {
        return kIntroNoHotwordMessage;
    }
}

#pragma mark - Session

- (IBAction)buttonPressed:(id)sender {
    if (self.currentSession && !self.currentSession.terminated) {
        [self playUISound:@"rec_cancel"];
        [self endSession];
    } else {
        // Make sure that we have permission to access the mic
        if ([AVAudioSession sharedInstance].recordPermission != AVAudioSessionRecordPermissionGranted) {
            [self showMicAlert];
            return;
        }
        // Make sure we have a speech recognition API key before proceeding
        if ([[SpeechRecognitionService sharedInstance] hasAPIKey] == NO) {
            [self clearLog];
            [self log:kNoSpeechAPIKeyMessage];
            [self playUISound:@"rec_cancel"];
            return;
        }
        [self startSession];
    }
}

- (void)startSession {
    // Terminate any ongoing session
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
    
    // Prepare for new session by pausing hotword activation
    [[self detector] stopListening];
    
    // Start new session
    [self playUISound:@"rec_begin"];
    [self.button setAccessibilityLabel:kSessionButtonLabelActive];
    [self.button expand];
    self.currentSession = [[QuerySession alloc] initWithDelegate:self];
    // Add slight delay so that UI sound isn't playing when recording starts
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.35 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.currentSession start];
    });
}

- (void)endSession {
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
    }
    self.currentSession = nil;
    [self.button setAccessibilityLabel:kSessionButtonLabelResting];
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

- (void)sessionDidReceiveAnswer:(NSString *)answer
                     toQuestion:(NSString *)question
                         source:(NSString *)source
                        openURL:(NSURL *)url
                       imageURL:(NSURL *)imgURL
                        command:(NSString *)cmd {
    [self clearLog];
    
    // We have received a JS command
    if (cmd) {
        id synthesisCompletionHandler = ^(NSURLResponse *response, id responseObject, NSError *error) {
            NSDictionary *respDict = (NSDictionary *)responseObject;
            NSString *audioURLStr = [respDict objectForKey:@"audio_url"];
            if ([[respDict objectForKey:@"err"] boolValue] || !audioURLStr || !self.currentSession) {
                return;
            }
            [self.currentSession playRemoteURL:audioURLStr];
        };
        
        [[JSExecutor sharedInstance] run:cmd completionHandler:^(id res, NSError *err) {
            // Put JS eval result into text field on main thread
            NSString *str = err ? [NSString stringWithFormat:@"%@ - %@", [err localizedDescription], err.userInfo] : [NSString stringWithFormat:@"%@", res];
            [self clearLog];
            [self log:str];
            // Speech synthesise text via Greynir API and play
            [[QueryService sharedInstance] requestSpeechSynthesis:str
                                                completionHandler:synthesisCompletionHandler];
        }];
        return;
    }
    
    // Standard answer (w. optional URL to open)
    NSString *aStr = answer ? answer : @"";
    NSString *separator = answer ? @"\n\n" : @"";
    NSString *srcStr = source ? [NSString stringWithFormat:@" (%@)", source] : @"";
    NSString *logStr = [NSString stringWithFormat:@"%@%@%@%@",
                        [question sentenceCapitalizedString],
                        separator,
                        [[aStr sentenceCapitalizedString] periodTerminatedString],
                        srcStr];
    if (imgURL) {
        NSData *data = [NSData dataWithContentsOfURL:imgURL];
        UIImage *img = [[UIImage alloc] initWithData:data];
        [self logString:logStr withImage:img];
        return;
    }
    [self log:logStr];
    
    // If we receive an URL in the response from the query server, we terminate
    // the session and ask the operating system to open the URL in question.
    if (url) {
        [self.currentSession terminate];
        DLog(@"Opening URL: %@", url);
        [[UIApplication sharedApplication] openURL:url
                                           options:@{}
                                 completionHandler:nil];
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
    // Upload session audio to server
//    NSUInteger audioSize = [self.currentSession.totalAudioData length];
//    if (audioSize && audioSize <= MAX_SESSION_AUDIO_SIZE) {
//        [[QueryService sharedInstance] uploadAudioToServer:self.currentSession.totalAudioData];
//    } else {
//        DLog(@"Session audio size exceeds max (%lu > %d)",
//             (unsigned long)audioSize, MAX_SESSION_AUDIO_SIZE);
//    }
    
    // Update UI controls on the main thread
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.button contract];
        [self.button stopAnimating];
        [self.button stopWaveform];
        if ([DEFAULTS boolForKey:@"VoiceActivation"]) {
            [[self detector] startListening];
        }
        if ([self.textView.text isEqualToString:@""]) {
            self.textView.text = [self introMessage];
        }
    }];
}

#pragma mark - Local commands

- (void)cancelCommandReceived:(NSNotification *)notification {
    [self sessionDidReceiveTranscripts:nil];
    [self.currentSession terminate];
}

- (void)disableVoiceActivationReceived:(NSNotification *)notification {
    [self toggleVoiceActivation:self];
    [self sessionDidReceiveTranscripts:nil];
    [self.currentSession terminate];
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

#pragma mark - User Interface Log

- (void)clearLog {
    // Update UI text view on the main thread
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.textView setContentOffset:CGPointZero animated:NO];
        self.textView.text = @"";
    }];
}

- (void)log:(NSString *)message, ... {
    NSString *formattedString = @"(null)";
    if (message && [message isKindOfClass:[NSString class]]) {
        va_list args;
        va_start(args, message);
        formattedString = [[NSString alloc] initWithFormat:message arguments:args];
        va_end(args);
    }
    // Update UI text view on the main thread
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *txt = [NSString stringWithFormat:@"%@%@\n", self.textView.text, formattedString];
        NSDictionary *attrs = @{    NSForegroundColorAttributeName: [self.textView textColor],
                                    NSFontAttributeName: [self.textView font]
                                };
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:txt
                                                                                             attributes:attrs];
        self.textView.attributedText = attributedString;
    }];
}

- (void)logString:(NSString *)message withImage:(UIImage *)img {
    NSString *s = [NSString stringWithFormat:@"%@\n\n", message];
    NSDictionary *attrs = @{    NSForegroundColorAttributeName: [self.textView textColor],
                                NSFontAttributeName: [self.textView font]
                            };
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:s
                                                                                         attributes:attrs];
    NSTextAttachment *imageAttachment = [NSTextAttachment new];
    float tvWidth = self.textView.bounds.size.width;
    UIImage *finalImg = [UIImage imageWithImage:img scaledToWidth:tvWidth];

    imageAttachment.image = finalImg;

    NSAttributedString *stringWithImage = [NSAttributedString attributedStringWithAttachment:imageAttachment];
    [attributedString replaceCharactersInRange:NSMakeRange([s length], 0) withAttributedString:stringWithImage];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.textView.attributedText = attributedString;
    }];
}

#pragma mark - AudioLevelSource (for button)

- (CGFloat)audioLevel {
    return self.currentSession ? [self.currentSession audioLevel] : 0.0f;
}

#pragma mark - UI sounds

- (void)playUISound:(NSString *)fileName {
    NSArray *voiceSounds = @[@"err", @"conn", @"dunno"];
    
    BOOL adjustRate = NO;
    if ([voiceSounds containsObject:fileName]) {
        NSString *suffix = [[DEFAULTS stringForKey:@"VoiceID"] lowercaseString];
        fileName = [NSString stringWithFormat:@"%@-%@", fileName, suffix];
        adjustRate = YES;
    }
    
    if ([uiSounds objectForKey:fileName]) {
        player = [[AVAudioPlayer alloc] initWithData:uiSounds[fileName] error:nil];
        [player setVolume:1.0];
        float speed = [DEFAULTS floatForKey:@"SpeechSpeed"];
        if (speed != 1.0 && adjustRate) {
            player.enableRate = YES;
            player.rate = speed;
        }
        [player play];
    } else {
        DLog(@"Unable to play audio file '%@'", fileName);
    }
}

// Preload audio files into memory so there isn't even the slightest delay when first played
- (void)preloadSounds {
    uiSounds = [NSMutableDictionary new];
    
    NSMutableArray *files = [@[@"rec_begin", @"rec_cancel", @"rec_confirm",
                              @"err-dora", @"conn-dora", @"err-karl", @"conn-karl"] mutableCopy];
    
    for (int i = 1; i < 8; i++) {
        [files addObject:[NSString stringWithFormat:@"dunno%02d-dora", i]];
        [files addObject:[NSString stringWithFormat:@"dunno%02d-karl", i]];
    }
    
    // Load files into memory, make the OS cache them
    for (NSString *fileName in files) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"wav"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
            uiSounds[fileName] = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedAlways error:nil];
            if (![uiSounds objectForKey:fileName]) {
                DLog(@"Error loading audio file %@", fileName);
            }
        } else {
            DLog(@"Unable to load non-existent audio file '%@'", fileName);
        }
    }
}

@end
