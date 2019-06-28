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
#import "google/cloud/speech/v1/CloudSpeech.pbrpc.h"
#import "SCSiriWaveformView.h"
#import "AudioController.h"
#import "SpeechRecognitionService.h"
#import "QueryService.h"
#import "MainController.h"
#import "QuerySession.h"
#import "Config.h"
#import "SDRecordButton.h"


#define SAMPLE_RATE 16000.0f


@interface MainController () <QuerySessionDelegate>

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIButton *button;
@property (nonatomic, weak) IBOutlet SCSiriWaveformView *waveformView;

@property (nonatomic, retain) QuerySession *currentSession;

- (IBAction)startSession:(id)sender;
- (IBAction)endSession:(id)sender;

@end


@implementation MainController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set up user interface
    [self clearLog];
    
    // Configure wave form view
    [self.waveformView setDensity:10];
    [self.waveformView setIdleAmplitude:0.0f];
//    [self.waveformView setWaveColor:[UIColor grayColor]];
//    [self.waveformView setPrimaryWaveLineWidth:3.0f];
//    [self.waveformView setSecondaryWaveLineWidth:1.0];
//    [self.waveformView setBackgroundColor:[UIColor whiteColor]];
    
    // Listen for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becameActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resignedActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    CADisplayLink *displaylink = [CADisplayLink displayLinkWithTarget:self
                                                             selector:@selector(updateWaveform)];
    [displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - Respond to app state changes

-(void)becameActive:(NSNotification *)notification {
    NSLog(@"%@", [notification description]);
}

-(void)resignedActive:(NSNotification *)notification {
    NSLog(@"%@", [notification description]);
    [self endSession:self];
}

#pragma mark - Session

- (IBAction)toggle:(id)sender {
    if (self.currentSession && !self.currentSession.terminated) {
        [self endSession:self];
    } else {
        [self startSession:self];
    }
}

- (IBAction)startSession:(id)sender {
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
    }

    [self.button setTitle:@"Hætta" forState:UIControlStateNormal];
    [self clearLog];
    
    // Create new session
    self.currentSession = [[QuerySession alloc] initWithDelegate:self];
    [self.currentSession start];
}

- (IBAction)endSession:(id)sender {
    if (self.currentSession && !self.currentSession.terminated) {
        [self.currentSession terminate];
        self.currentSession = nil;
    }
}

#pragma mark - QuerySessionDelegate

- (void)sessionDidStartRecording {
    [self.waveformView setIdleAmplitude:0.025f];
}

- (void)sessionDidStopRecording {
    [self.waveformView setIdleAmplitude:0.0f];
}

- (void)sessionDidHearQuestion:(NSString *)questionStr {
    NSString *repl = [[questionStr substringToIndex:1] capitalizedString];
    NSString *capitalized = [questionStr stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:repl];
    [self log:@"%@?\n", capitalized];
}

- (void)sessionDidReceiveAnswer:(NSString *)answerStr {
    [self log:@"%@", answerStr];
}

- (void)sessionDidRaiseError:(NSError *)err {
    [self clearLog];
    [self log:[err localizedDescription]];
}

- (void)sessionDidTerminate {
    [self.button setTitle:@"Hlusta" forState:UIControlStateNormal];
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

- (void)updateWaveform {
    CGFloat level = self.currentSession ? [self.currentSession audioLevel] : 0.0f;
    [self.waveformView updateWithLevel:level];
}

@end
