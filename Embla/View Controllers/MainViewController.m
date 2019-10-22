/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2019 Miðeind ehf.
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


#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SCSiriWaveformView.h"
#import "MainViewController.h"
#import "QuerySession.h"
#import "Common.h"
#import "SDRecordButton.h"
#import "AudioRecordingController.h"
#import "Reachability.h"
#import "NSString+Additions.h"

static NSString * const kIntroMessage = @"Segðu „Hæ Embla“ til þess að tala við Emblu.";
static NSString * const kNoInternetConnectivityMessage = @"Ekki næst samband við netið.";
static NSString * const kServerErrorMessage = @"Villa kom upp í samskiptum við netþjón.";
static NSString * const kReachabilityHostname = @"greynir.is";

@interface MainViewController () <QuerySessionDelegate>
{
    AVAudioPlayer *player;
    NSMutableDictionary *uiSounds;
    CADisplayLink *displayLink;
    Reachability *reach;
}
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet SDRecordButton *button;
@property (nonatomic, weak) IBOutlet SCSiriWaveformView *waveformView;
@property (nonatomic, retain) QuerySession *currentSession;
@property BOOL connected;

@end


@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    
    self.textView.text = kIntroMessage;
    
    [self preloadSounds];
    [self setUpReachability];
    
    // Set up user interface
    [self.waveformView setDensity:8];
    [self.waveformView setIdleAmplitude:0.0f];
    [self.waveformView setFrequency:2.0];
    [self.waveformView setPrimaryWaveLineWidth:3.0f];
    [self.waveformView setSecondaryWaveLineWidth:1.5f];
    [self.waveformView updateWithLevel:0.f];
    
    // Adjust spacing between button image and title
    CGFloat spacing = 10;
    self.button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, spacing);
    self.button.titleEdgeInsets = UIEdgeInsetsMake(0, spacing, 0, 0);
    [self.button setButtonColor:[UIColor whiteColor]];
    [self.button setProgressColor:[UIColor whiteColor]];
    
    // Listen for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becameActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resignedActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    // Prepare for audio recording
    [[AudioRecordingController sharedInstance] prepareWithSampleRate:REC_SAMPLE_RATE];
}

- (void)viewDidAppear:(BOOL)animated {
    DLog(@"Main view did appear");
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [self setUpReachability];
    self.textView.text = kIntroMessage;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"VoiceActivation"]) {
        [[ActivationListener sharedInstance] setDelegate:self];
        [[ActivationListener sharedInstance] startListening];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    DLog(@"Main view did disappear");
    
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
        self.currentSession = nil;
    }
    [[ActivationListener sharedInstance] stopListening];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

#pragma mark - Respond to app state changes

- (void)becameActive:(NSNotification *)notification {
    DLog(@"%@", [notification description]);
    [[ActivationListener sharedInstance] startListening];
}

- (void)resignedActive:(NSNotification *)notification {
    DLog(@"%@", [notification description]);
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
        self.currentSession = nil;
    }
    [[ActivationListener sharedInstance] stopListening];
}

#pragma mark - Reachability

- (void)becameReachable {
    self.connected = YES;
}

- (void)becameUnreachable {
    self.connected = NO;
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
        self.currentSession = nil;
        [self playSystemSound:@"conn"];
        [self log:kNoInternetConnectivityMessage];
    }
}

- (void)setUpReachability {
    if (reach) {
        [reach stopNotifier];
    }
    reach = [Reachability reachabilityWithHostname:kReachabilityHostname];

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
    [[ActivationListener sharedInstance] stopListening];
    [self startSession];
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
        } else {
            [self startSession];
        }
    }
}

- (void)startSession {
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
    }
    
    [self clearLog];
    
    if (!self.connected) {
        [self playSystemSound:@"conn"];
        [self log:kNoInternetConnectivityMessage];
        return;
    }
    
    [self activateWaveform];
    [self.button setTitle:@"Hætta" forState:UIControlStateNormal];
    
    // Create new session
    self.currentSession = [[QuerySession alloc] initWithDelegate:self];
    [self playSystemSound:@"rec_begin"];
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
    [self.waveformView setIdleAmplitude:0.025f];
//    self.button.tintColor = [UIColor redColor];
//    [self.button setImage:[UIImage imageNamed:@"Microphone"] forState:UIControlStateNormal];
}

- (void)sessionDidStopRecording {
    [self.waveformView setIdleAmplitude:0.0f];
//    self.button.tintColor = self.view.tintColor;
}

- (void)sessionDidReceiveInterimResults:(NSArray<NSString *> *)results {
    [self clearLog];
    [self log:@"%@", [[results firstObject] sentenceCapitalizedString]];
}

- (void)sessionDidReceiveTranscripts:(NSArray<NSString *> *)alternatives {
    [self clearLog];
    if (alternatives && [alternatives count]) {
        NSString *questionStr = [[alternatives firstObject] sentenceCapitalizedString];
        [self log:@"%@", questionStr];
        [self playSystemSound:@"rec_confirm"];
//        [self.button setImage:[UIImage imageNamed:@"Radio"] forState:UIControlStateNormal];
//        [self.button setTitle:@"🔊" forState:UIControlStateNormal];
    } else {
        [self playSystemSound:@"rec_cancel"];
    }
}

- (void)sessionDidReceiveAnswer:(NSString *)answer
                     toQuestion:(NSString *)question
                        withURL:(NSURL *)url {
    [self clearLog];
    
    NSString *aStr = answer ? answer : @"";
    NSString *separator = answer ? @"\n\n" : @"";
    [self log:@"%@%@%@",  [question sentenceCapitalizedString], separator,
                            [[aStr sentenceCapitalizedString] periodTerminatedString]];
    
    // If we receive an URL in the response from the query server,
    // we terminate the session and ask the OS to open the URL.
    if (url) {
        [self.currentSession terminate];
        DLog(@"Opening URL: %@", url);
        [[UIApplication sharedApplication] openURL:url
                                           options:@{}
                                 completionHandler:^(BOOL success){}];
    }
    
//    [self.button setImage:[UIImage imageNamed:@"Audio"] forState:UIControlStateNormal];
}

- (void)sessionDidRaiseError:(NSError *)error {
    [self clearLog];
    if (self.connected) {
        [self log:kServerErrorMessage];
#ifdef DEBUG
        [self log:[error localizedDescription]];
#endif
        [self playSystemSound:@"err"];
    } else {
        [self log:kNoInternetConnectivityMessage];
        [self playSystemSound:@"conn"];
    }
    [self.currentSession terminate];
}

- (void)sessionDidTerminate {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.button setTitle:@"Hlusta" forState:UIControlStateNormal];
        [self.button setImage:nil forState:UIControlStateNormal];
        [self deactivateWaveform];
        [[ActivationListener sharedInstance] startListening];
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

- (void)activateWaveform {
    if (displayLink) {
        return;
    }
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateWaveform)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)deactivateWaveform {
    [self.waveformView updateWithLevel:0.f];
    if (displayLink) {
        [displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        displayLink = nil;
    }
}

- (void)updateWaveform {
    CGFloat level = self.currentSession ? [self.currentSession audioLevel] : 0.0f;
    [self.waveformView updateWithLevel:level];
}

#pragma mark - UI sounds

- (void)playSystemSound:(NSString *)fileName {
    NSArray *voiceSounds = @[@"err", @"conn", @"dunno"];
    
    if ([voiceSounds containsObject:fileName]) {
        NSUInteger vid = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Voice"] unsignedIntegerValue];
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
        NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"caf"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
            uiSounds[fileName] = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedAlways error:nil];
        } else {
            DLog(@"Unable to load audio file '%@'", fileName);
        }
    }
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
}


@end
