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
//#import <SDWebImage/SDWebImage.h>
#import "SCSiriWaveformView.h"
#import "AudioController.h"
#import "SpeechRecognitionService.h"
#import "SpeechSynthesisService.h"
#import "QueryService.h"
#import "ViewController.h"
#import "Config.h"
#import "SDRecordButton.h"

#define SAMPLE_RATE 16000.0f

@interface ViewController () <AudioControllerDelegate>
{
    BOOL isRecording;
    BOOL hasPlayedActivationSound;
    float lastRecDec;
}

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIButton *button;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet SCSiriWaveformView *waveformView;

@property (nonatomic, strong) NSMutableData *audioData;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSString *queryString;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [AudioController sharedInstance].delegate = self;
    [self clearLog];
    
    // Listen for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becameActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resignedActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
//    [self askGreynir:@"Hver er Katrín Jakobsdóttir?"];
    [self performSelector:@selector(askGreynir:) withObject:@"Hver er Katrín Jakobsdóttir?" afterDelay:2.0f];
    
    CADisplayLink *displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateWaveform)];
    [displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//
//    [self speakText:@"Það veit ég ekki."];
    
//    [self playAudio:@"dunno"];
    
    // Configure sinus wave view
    [self.waveformView setDensity:10];
//    [self.waveformView setWaveColor:[UIColor grayColor]];
//    [self.waveformView setPrimaryWaveLineWidth:3.0f];
//    [self.waveformView setSecondaryWaveLineWidth:1.0];
//    [self.waveformView setBackgroundColor:[UIColor whiteColor]];

//    [self startRecording:self];
}

-(void)becameActive:(NSNotification *)notification {
    NSLog(@"%@", [notification description]);
}

-(void)resignedActive:(NSNotification *)notification {
    NSLog(@"%@", [notification description]);
    [self stopRecording:self];
}

- (IBAction)toggle:(id)sender {
    if (isRecording) {
        [self stopRecording:sender];
    } else {
        [self startRecording:sender];
    }
}

- (IBAction)startRecording:(id)sender {
    DLog(@"Starting recording");
    isRecording = YES;
    hasPlayedActivationSound = NO;
    
    [self.button setTitle:@"Hætta" forState:UIControlStateNormal];
    [self.imageView setImage:[UIImage imageNamed:@"Greynir"]];
    
    [self clearLog];
    self.queryString = @"";
    
    // Configure audio session
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord
                                     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                           error:nil];
    self.audioData = [NSMutableData new];
    [[AudioController sharedInstance] prepareWithSampleRate:SAMPLE_RATE];
    [[SpeechRecognitionService sharedInstance] setSampleRate:SAMPLE_RATE];
    [[AudioController sharedInstance] start];
}

- (IBAction)stopRecording:(id)sender {
    DLog(@"Stopping recording");
    isRecording = NO;
    
    // Stop audio session
    [[AudioController sharedInstance] stop];
    [[SpeechRecognitionService sharedInstance] stopStreaming];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.button setTitle:@"Hlusta" forState:UIControlStateNormal];
        if ([self.queryString length]) {
            [self askGreynir:self.queryString];
        } else {
//            [self log:@"Engin fyrirspurn."];
        }
    }];
}

- (void)clearLog {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.textView.text = @"";
    }];
}

- (void)log:(NSString *)str {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.textView.text = [NSString stringWithFormat:@"%@%@\n", self.textView.text, str];
    }];
}

- (void)logQuote:(NSString *)str {
    [self log:[NSString stringWithFormat:@"“%@”", str]];
}

- (void)processSampleData:(NSData *)data {
    if (!hasPlayedActivationSound) {
        NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"rec_begin" ofType:@"caf"];
        NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
        
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
        [self.audioPlayer play];
        hasPlayedActivationSound = YES;
    }
    
    [self.audioData appendData:data];
    
    NSInteger frameCount = [data length] / 2;
    int16_t *samples = (int16_t *)[data bytes]; // Cast void pointer
    int64_t sum = 0;
    int64_t avg = 0;
    int16_t max = 0;
    for (int i = 0; i < frameCount; i++) {
        sum += abs(samples[i]);
        if (!avg) {
            avg = abs(samples[i]);
        } else {
            avg = (avg + abs(samples[i])) / 2;
        }
        if (samples[i] > max) {
            max = samples[i];
        }
    }
    DLog(@"Audio frame count %d %d %d %d", (int)frameCount, (int)(sum * 1.0 / frameCount), avg, max);
    
//    short *bytes = [data bytes];
    
//    NSLog(@"Audio frame: %d", bytes[0]);
    float ampl = max/32767.f;
    float decibels = 20 * log10(ampl);
//
//    NSLog(@"Ampl: %.8f", ampl);
//    NSLog(@"DecB: %.2f", decibels);
    
    lastRecDec = decibels;
    
//    return;
    
    // Google recommends sending samples in 100 ms chunks
    int chunk_size = 0.1 /* seconds/chunk */ * SAMPLE_RATE * 2 /* bytes/sample */; /* bytes/chunk */
    if ([self.audioData length] < chunk_size) {
        // Not enough data yet...
        return;
    }
    
    SpeechRecognitionCompletionHandler compHandler = ^(StreamingRecognizeResponse *response, NSError *error) {
        if (error) {
            DLog(@"ERROR: %@", error);
            [self log:[error localizedDescription]];
            [self stopRecording:nil];
        }
        else if (response) {
            BOOL finished = NO;
            
            DLog(@"RESPONSE: %@", response);
            DLog(@"Speech event type: %d", response.speechEventType);
//            DLog(@"%@", [response.resultsArray description]);
            
            for (StreamingRecognitionResult *result in response.resultsArray) {
                if (result.isFinal) {
                    if ([result.alternativesArray count]) {
                        SpeechRecognitionAlternative *best = result.alternativesArray[0];
                        NSString *transcr = best.transcript;
                        NSString *capitalized = [transcr stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                                 withString:[[transcr substringToIndex:1] capitalizedString]];
                        [self clearLog];
                        [self log:[NSString stringWithFormat:@"%@?", capitalized]];
                        self.queryString = transcr;
                    }
                    else {
                        [self log:@"No interpretation found."];
                    }
                    finished = YES;
                }
            }
            
            DLog(@"%@", [response description]);
            
            if (finished) {
                [self stopRecording:nil];
            }
        }
    };

    DLog(@"SENDING");
    [[SpeechRecognitionService sharedInstance] streamAudioData:self.audioData withCompletion:compHandler];
    
    self.audioData = [NSMutableData new];
}

- (void)askGreynir:(NSString *)questionStr {
//    [self log:@"Querying Greynir:"];
//    [self logQuote:questionStr];
    
    // Completion handler for Greynir API request
    id completionHandler = ^(NSURLResponse *response, id responseObject, NSError *error) {
        DLog(@"Greynir server response: %@", [responseObject description]);
        if (error) {
            [self log:[NSString stringWithFormat:@"Error: %@", error]];
        } else {
            NSDictionary *r = responseObject;
            NSString *s = @"Það veit ég ekki.";
            
            if ([r isKindOfClass:[NSDictionary class]] && [r[@"valid"] boolValue]) {
                id greynirResponse = r[@"response"];
//                id greynirImage = [r objectForKey:@"image"];
                
//                if (greynirImage != nil && [greynirImage isKindOfClass:[NSDictionary class]] && [(NSDictionary *)greynirImage objectForKey:@"src"]) {
//                    NSString *imgURLStr = [(NSDictionary *)greynirImage objectForKey:@"src"];
//                    [self.imageView sd_setImageWithURL:[NSURL URLWithString:imgURLStr]
//                                      placeholderImage:[UIImage imageNamed:@"Greynir"]];
//                }
                
                if (greynirResponse && [greynirResponse isKindOfClass:[NSString class]]) {
                    s = greynirResponse;
                }
                [self synthesizeText:s];
            }
            else {
                [self playAudio:@"dunno"];
            }
        }
    };
    
    // Post query to the API
    [[QueryService sharedInstance] sendQuery:questionStr withCompletionHandler:completionHandler];
}

- (void)synthesizeText:(NSString *)txt {
//    [self log:@"Speaking text:"];
//    [self logQuote:txt];
    [[SpeechSynthesisService sharedInstance] synthesizeText:txt completionHandler:^(NSData *audioData) {
        [self playAudio:audioData];
    }];
}

- (void)playAudio:(id)filenameOrData {
    // Utility function that creates an AVAudioPlayer to play either a local file or audio data
    NSError *err;
    
    if ([filenameOrData isKindOfClass:[NSString class]]) {
        // Local filename specified, init player with local file URL
        NSString *filename = (NSString *)filenameOrData;
        NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"caf"];
        NSURL *url = [NSURL fileURLWithPath:path];
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    } else {
        // Init player with audio data
        self.audioPlayer = [[AVAudioPlayer alloc] initWithData:(NSData *)filenameOrData error:&err];
    }
    
    if (err == nil) {
        // Configure player and set it off
        [self.audioPlayer setMeteringEnabled:YES];
        [self.audioPlayer play];
    } else {
        DLog(@"%@", [err localizedDescription]);
    }
}

- (void)updateWaveform {
    CGFloat level = 0.0f;
    if (isRecording) {
        level = [self _normalizedPowerLevelFromDecibels:lastRecDec];
    }
    else if (self.audioPlayer && [self.audioPlayer isPlaying]) {
        [self.audioPlayer updateMeters];
        float decibels = [self.audioPlayer averagePowerForChannel:0];
        level = [self _normalizedPowerLevelFromDecibels:decibels];
    }
    [self.waveformView updateWithLevel:level];
}

- (CGFloat)_normalizedPowerLevelFromDecibels:(CGFloat)decibels {
    if (decibels < -64.0f || decibels == 0.0f) {
        return 0.0f;
    }
    return powf(
            // 10 to the power of 0.1xDB  - 10 to the power of 0.1xDB
            (powf(10.0f, 0.1f * decibels) - powf(10.0f, 0.1f * -60.0f)) *
            // Multiplied by 1 / 1 -
            (1.0f / (1.0f - powf(10.0f, 0.1f * -60.0f))),
                
            1.0f / 2.0f);
}

@end
