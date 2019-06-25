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
//#import "SpeechSynthesisService.h"
#import "QueryService.h"
#import "MainController.h"
#import "Config.h"
#import "SDRecordButton.h"

#define SAMPLE_RATE 16000.0f

@interface MainController () <AudioControllerDelegate>
{
    BOOL isRecording;
    BOOL hasPlayedActivationSound;
    float lastRecDec;
}

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIButton *button;
@property (nonatomic, weak) IBOutlet SCSiriWaveformView *waveformView;

@property (nonatomic, strong) NSMutableData *audioData;
@property (atomic, strong) AVAudioPlayer *audioPlayer;
@property (atomic, strong) NSString *queryString;

- (IBAction)startRecording:(id)sender;
- (IBAction)stopRecording:(id)sender;

@end

@implementation MainController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set up user interface
    [self clearLog];
    // Configure sinus wave view
    [self.waveformView setDensity:10];
    [self.waveformView setIdleAmplitude:0.0f];
    //    [self.waveformView setWaveColor:[UIColor grayColor]];
    //    [self.waveformView setPrimaryWaveLineWidth:3.0f];
    //    [self.waveformView setSecondaryWaveLineWidth:1.0];
    //    [self.waveformView setBackgroundColor:[UIColor whiteColor]];
    
    UIBarButtonItem *settingsItem = [[UIBarButtonItem alloc] initWithTitle:@"Hello"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(startRecording:)];
    [self setToolbarItems:@[settingsItem] animated:NO];
    
    self.navigationController.toolbarHidden = NO;

    
    [AudioController sharedInstance].delegate = self;
    
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
//    [self performSelector:@selector(askGreynir:) withObject:@"Hver er Katrín Jakobsdóttir?" afterDelay:2.0f];
    
    CADisplayLink *displaylink = [CADisplayLink displayLinkWithTarget:self
                                                             selector:@selector(updateWaveform)];
    [displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//
//    [self speakText:@"Það veit ég ekki."];
    
//    [self playAudio:@"dunno"];
    
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
        [self playAudio:@"rec_cancel"];
    } else {
        [self startRecording:sender];
    }
}

- (IBAction)startRecording:(id)sender {
    DLog(@"Starting recording");
    isRecording = YES;
    hasPlayedActivationSound = NO;
    [self.waveformView setIdleAmplitude:0.025f];
    
    [self.button setTitle:@"Hætta" forState:UIControlStateNormal];
    
    [self clearLog];
    self.queryString = @"";
    
    // Configure audio session
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                           error:nil];
    self.audioData = [NSMutableData new];
    [[AudioController sharedInstance] prepareWithSampleRate:SAMPLE_RATE];
    [[SpeechRecognitionService sharedInstance] setSampleRate:SAMPLE_RATE];
    [[AudioController sharedInstance] start];
}

- (IBAction)stopRecording:(id)sender {
    DLog(@"Stopping recording");
    [self playAudio:@"rec_confirm"];
    isRecording = NO;
    [self.waveformView setIdleAmplitude:0.0f];
    
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

#pragma mark - UI Log

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

#pragma mark -

- (void)processSampleData:(NSData *)data {
    // There is a noticeable delay between starting recording session and receiving
    // the first audio data packets from the microphone. Only play activation sound
    // when the first audio packet has arrived.
    if (!hasPlayedActivationSound) {
        [self playAudio:@"rec_begin"];
//        NSURL *soundFileURL = [[NSBundle mainBundle] URLForResource:@"rec_begin" withExtension:@"caf"];
//        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
//        [self.audioPlayer play];
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
        avg = !avg ? abs(samples[i]) : (avg + abs(samples[i])) / 2;
        max = (samples[i] > max) ? samples[i] : max;
    }
    DLog(@"Audio frame count %d %d %d %d", (int)frameCount, (int)(sum * 1.0 / frameCount), (int)avg, (int)max);
    
    float ampl = max/32767.f;
    float decibels = 20 * log10(ampl);
//    NSLog(@"Ampl: %.8f", ampl);
//    NSLog(@"DecB: %.2f", decibels);
    
    lastRecDec = decibels;
    
//    return;
    
    // Google recommends sending samples in 100 ms chunks
    float dur = 0.1;
    int bytes_per_sample = 2;
    int chunk_size = dur * SAMPLE_RATE * bytes_per_sample;
    
    if ([self.audioData length] < chunk_size) {
        // Not enough data yet...
        return;
    }
    
    // We have enough audio data to send to speech recognition server.
    SpeechRecognitionCompletionHandler compHandler = ^(StreamingRecognizeResponse *response, NSError *error) {
        if (error) {
            DLog(@"ERROR: %@", error);
            [self log:[error localizedDescription]];
            [self stopRecording:nil];
        }
        else if (response) {
            BOOL finished = NO;
            
            DLog(@"RESPONSE: %@", response);
//            DLog(@"Speech event type: %d", response.speechEventType);
//            DLog(@"%@", [response.resultsArray description]);
            
            for (StreamingRecognitionResult *result in response.resultsArray) {
                if (result.isFinal) {
                    if ([result.alternativesArray count]) {
                        
                        SpeechRecognitionAlternative *best = result.alternativesArray[0];
                        // TODO: Ugh, refactor this away.
                        NSString *transcr = best.transcript;
                        NSString *repl = [[transcr substringToIndex:1] capitalizedString];
                        NSString *capitalized = [transcr stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                                 withString:repl];
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
    
    // Discard previously accumulated audio data
    self.audioData = [NSMutableData new];
}

- (void)askGreynir:(NSString *)questionStr {
//    [self log:@"Querying Greynir:"];
    
    // Completion handler for Greynir API request
    id completionHandler = ^(NSURLResponse *response, id responseObject, NSError *error) {
        DLog(@"Greynir server response: %@", [responseObject description]);
        
        if (error) {
            [self log:[NSString stringWithFormat:@"Error: %@", error]];
        } else {
            NSDictionary *r = responseObject;
            
            if ([r isKindOfClass:[NSDictionary class]] && [r[@"valid"] boolValue]) {
                id greynirResponse = [r objectForKey:@"response"];
                if (greynirResponse && [greynirResponse isKindOfClass:[NSString class]]) {
                    [self log:@"\n%@", greynirResponse];
                } else {
                    DLog(@"Malformed response: %@", [greynirResponse description]);
                }
                
                NSString *audioURLStr = [r objectForKey:@"audio"];
                if (audioURLStr) {
                    [self playRemoteURL:[NSURL URLWithString:audioURLStr]];
                }
                
            }
            else {
                [self playAudio:@"dunno"];
            }
        }
    };
    
    // Post query to the API
    [[QueryService sharedInstance] sendQuery:questionStr withCompletionHandler:completionHandler];
}

#pragma mark - Playback

- (void)playAudio:(id)filenameOrData {
    // Utility function that creates an AVAudioPlayer to play either a local file or audio data
    
    // Change audio session to playback mode
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                           error:nil];
    NSError *err;
    AVAudioPlayer *player;
    
    if ([filenameOrData isKindOfClass:[NSString class]]) {
        // Local filename specified, init player with local file URL
        NSString *filename = (NSString *)filenameOrData;
        NSURL *url = [[NSBundle mainBundle] URLForResource:filename withExtension:@"caf"];
        if (url) {
            player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
        } else {
            DLog(@"Unable to find audio file '%@.caf' in bundle", filename);
        }
    } else if ([filenameOrData isKindOfClass:[NSData class]]) {
        // Init player with audio data
        player = [[AVAudioPlayer alloc] initWithData:(NSData *)filenameOrData error:&err];
    } else {
        DLog(@"playAudio argument neither filename nor data.");
        return;
    }
    
    if (err == nil) {
        // Configure player and set it off
        [player setMeteringEnabled:YES];
        [player play];
        self.audioPlayer = player;
    } else {
        DLog(@"%@", [err localizedDescription]);
    }
}

- (void)playRemoteURL:(NSURL *)url {
    DLog(@"Speech audio URL: %@", [url description]);
    NSURLSessionDataTask *downloadTask = \
    [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            DLog(@"%@", [error localizedDescription]);
            return;
        }
        //        completionHandler(data);
        DLog(@"Playing audio file of size %d", (int)[data length]);
        [self playAudio:data];
    }];
    [downloadTask resume];
}

#pragma mark - Waveform view

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
    // TODO: Tweak this for better results?
    return powf(
            // 10 to the power of 0.1*DB  - 10 to the power of 0.1*-60
            (powf(10.0f, 0.1f * decibels) - powf(10.0f, 0.1f * -60.0f)) *
            // Multiplied by 1 / 1 -
            (1.0f / (1.0f - powf(10.0f, 0.1f * -60.0f))),
            // To the power of 0.5
            1.0f / 2.0f);
}

@end
