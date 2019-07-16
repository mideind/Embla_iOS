/*
 * This file is part of the Greynir iOS app
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


static NSString * const kNoInternetConnectivityMessage = @"Ekki næst samband við netið.";
static NSString * const kServerErrorMessage = @"Villa kom upp í samskiptum við netþjón.";

static NSString * const kReachabilityHostname = @"greynir.is";


@interface MainViewController () <QuerySessionDelegate>
{
    SystemSoundID begin;
    SystemSoundID confirm;
    SystemSoundID cancel;
    SystemSoundID conn;
    SystemSoundID err;
    
    CADisplayLink *displayLink;
}
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIButton *button;
@property (nonatomic, weak) IBOutlet SCSiriWaveformView *waveformView;
@property (nonatomic, retain) QuerySession *currentSession;
@property BOOL connected;

@end


@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self preloadUISounds];
    [self setUpReachability];
    
    // Set up user interface
    [self clearLog];

    [self.waveformView setDensity:8];
    [self.waveformView setIdleAmplitude:0.0f];
    [self.waveformView setFrequency:2.0];
//    [self.waveformView setWaveColor:[UIColor grayColor]];
    [self.waveformView setPrimaryWaveLineWidth:2.0f];
    [self.waveformView setSecondaryWaveLineWidth:1.0];
//    [self.waveformView setBackgroundColor:[UIColor whiteColor]];
    [self.waveformView updateWithLevel:0.f];
    
    // Adjust spacing between button image and title
    CGFloat spacing = 10;
    self.button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, spacing);
    self.button.titleEdgeInsets = UIEdgeInsetsMake(0, spacing, 0, 0);
    
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
}

- (void)viewDidDisappear:(BOOL)animated {
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
        self.currentSession = nil;
    }
}

#pragma mark - Respond to app state changes

- (void)becameActive:(NSNotification *)notification {
    DLog(@"%@", [notification description]);
}

- (void)resignedActive:(NSNotification *)notification {
    DLog(@"%@", [notification description]);
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
        self.currentSession = nil;
    }
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
        [self playSystemSound:conn];
        [self log:kNoInternetConnectivityMessage];
    }
}

- (void)setUpReachability {
    Reachability *reach = [Reachability reachabilityWithHostname:kReachabilityHostname];
    
    reach.reachableBlock = ^(Reachability*reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self becameReachable];
        });
    };
    
    reach.unreachableBlock = ^(Reachability*reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self becameUnreachable];
        });
    };
    
    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
}

#pragma mark - Session

- (IBAction)buttonPressed:(id)sender {
    if (self.currentSession && !self.currentSession.terminated) {
        [self endSession];
    } else {
        [self startSession];
    }
}

- (void)startSession {
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
    }
    
    [self clearLog];
    
    if (!self.connected) {
        [self playSystemSound:conn];
        [self log:kNoInternetConnectivityMessage];
        return;
    }
    
    [self activateWaveform];
    [self.button setTitle:@"Hætta" forState:UIControlStateNormal];

    
    // Create new session
    self.currentSession = [[QuerySession alloc] initWithDelegate:self];
    [self playSystemSound:begin];
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
    [self.waveformView setIdleAmplitude:0.025f];
    self.button.tintColor = [UIColor redColor];
    [self.button setImage:[UIImage imageNamed:@"Microphone"] forState:UIControlStateNormal];
}

- (void)sessionDidStopRecording {
    [self.waveformView setIdleAmplitude:0.0f];
    self.button.tintColor = self.view.tintColor;
}

- (void)sessionDidReceiveInterimResults:(NSArray<NSString *> *)results {
    [self clearLog];
    [self log:@"%@", [[results firstObject] sentenceCapitalizedString]];
}

- (void)sessionDidReceiveTranscripts:(NSArray<NSString *> *)alternatives {
    if (alternatives && [alternatives count]) {
        NSString *questionStr = [[alternatives firstObject] sentenceCapitalizedString];
        [self clearLog];
        [self log:@"%@?", [questionStr sentenceCapitalizedString]];
        [self playSystemSound:confirm];
        [self.button setImage:[UIImage imageNamed:@"Radio"] forState:UIControlStateNormal];
    } else {
        [self playSystemSound:cancel];
    }
}

- (void)sessionDidReceiveAnswer:(NSString *)answer toQuestion:(NSString *)question {
    [self clearLog];
    
    NSString *aStr = answer ? answer : @"";
    [self log:@"%@\n\n%@",  [[question sentenceCapitalizedString] questionMarkTerminatedString],
                            [[aStr sentenceCapitalizedString] periodTerminatedString]];
    [self.button setImage:[UIImage imageNamed:@"Audio"] forState:UIControlStateNormal];
}

- (void)sessionDidRaiseError:(NSError *)error {
    [self clearLog];
    if (self.connected) {
        [self log:kServerErrorMessage];
        [self log:[error localizedDescription]];
        [self playSystemSound:err];
    } else {
        [self log:kNoInternetConnectivityMessage];
        [self playSystemSound:conn];
    }
    [self.currentSession terminate];
}

- (void)sessionDidTerminate {
    [self.button setTitle:@"Hlusta" forState:UIControlStateNormal];
    [self.button setImage:nil forState:UIControlStateNormal];
    [self deactivateWaveform];
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

- (void)playSystemSound:(SystemSoundID)soundID {
    AudioServicesPlaySystemSound(soundID);
}

- (void)preloadUISounds {
    NSURL *url;
    
    url = [[NSBundle mainBundle] URLForResource:@"rec_begin" withExtension:@"caf"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &begin);
    url = [[NSBundle mainBundle] URLForResource:@"rec_confirm" withExtension:@"caf"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &confirm);
    url = [[NSBundle mainBundle] URLForResource:@"rec_cancel" withExtension:@"caf"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &cancel);
    url = [[NSBundle mainBundle] URLForResource:@"conn" withExtension:@"caf"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &conn);
    url = [[NSBundle mainBundle] URLForResource:@"err" withExtension:@"caf"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &err);
}

@end
