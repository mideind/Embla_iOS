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


#import "QuerySession.h"
#import "AudioController.h"
#import "Config.h"
#import "QueryService.h"
#import "SpeechRecognitionService.h"
#import <AVFoundation/AVFoundation.h>


@interface QuerySession () <AudioControllerDelegate, AVAudioPlayerDelegate>
{
    CGFloat recordingDecibelLevel;
}
@property (nonatomic, strong) NSMutableData *audioData;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSString *queryString;

@end


#define REC_SAMPLE_RATE 16000.0f


@implementation QuerySession

- (instancetype)initWithDelegate:(id<QuerySessionDelegate>)del {
    self = [super init];
    if (self) {
        _delegate = del;
    }
    return self;
}

#pragma mark -

- (void)start {
    DLog(@"Starting session");
    [self startRecording];
}

- (void)terminate {
    DLog(@"Terminating session");
    if (_isRecording) {
        [self stopRecording];
    }
    if (self.audioPlayer) {
        [self.audioPlayer stop];
        self.audioPlayer = nil;
    }
    _terminated = YES;
    [self.delegate sessionDidTerminate];
}

#pragma mark - Recording

- (void)startRecording {
    _isRecording = YES;

    self.audioData = [NSMutableData new];
    
    [[SpeechRecognitionService sharedInstance] setSampleRate:REC_SAMPLE_RATE];

    [[AudioController sharedInstance] prepareWithSampleRate:REC_SAMPLE_RATE];
    [[AudioController sharedInstance] setDelegate:self];
    [[AudioController sharedInstance] start];
    
    [self.delegate sessionDidStartRecording];
}

- (void)stopRecording {
    _isRecording = NO;
    recordingDecibelLevel = 0.f;
    
    [[AudioController sharedInstance] stop];
    [[SpeechRecognitionService sharedInstance] stopStreaming];
    
    [self.delegate sessionDidStopRecording];
}

// Receives audio data from microphone and accumulates it
// until there's enough to send to the speech recognition server
- (void)processSampleData:(NSData *)data {
    if (!_isRecording) {
        DLog(@"Received audio data (%d bytes) after recording was ended.", (int)[data length]);
        return;
    }
    
    [self.audioData appendData:data];
    
    // Get audio frame properties
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
    
    float ampl = max/32767.f; // Divide by max value of signed 16-bit integer
    float decibels = 20 * log10(ampl);
    //    DLog(@"Ampl: %.8f", ampl);
    //    DLog(@"DecB: %.2f", decibels);
    
    recordingDecibelLevel = decibels;
        
    // Google recommends sending samples in 100 ms chunks
    float dur = 0.1;
    int bytes_per_sample = 2;
    int chunk_size = dur * REC_SAMPLE_RATE * bytes_per_sample;
    
    if ([self.audioData length] < chunk_size) {
        // Not enough data yet...
        return;
    }
    
    // We have enough audio data to send to speech recognition server.
    SpeechRecognitionCompletionHandler compHandler = ^(StreamingRecognizeResponse *response, NSError *error) {
        if (self.terminated) {
            DLog(@"Terminated task received speech recognition response: %@", [response description]);
            return;
        }
        
        if (error) {
            DLog(@"ERROR: %@", error);
            [self stopRecording];
            [self.delegate sessionDidRaiseError:error];
        }
        else if (response) {
            BOOL finished = NO;
            
            DLog(@"RESPONSE: %@", response);
//            DLog(@"Speech event type: %d", response.speechEventType);
//            DLog(@"%@", [response.resultsArray description]);
            
            NSString *query = nil;
            for (StreamingRecognitionResult *result in response.resultsArray) {
                if (result.isFinal) {
                    if ([result.alternativesArray count]) {                        
                        SpeechRecognitionAlternative *best = result.alternativesArray[0];
                        query = best.transcript;
                    }
                    finished = YES;
                }
            }
            
            // We've received a final answer from the speech recognition server.
            // Terminate recording and submit query, if any, to query server.
            if (finished) {
                [self stopRecording];
                if (query) {
                    [self.delegate sessionDidHearQuestion:query];
                    [self sendQuery:query];
                } else {
                    [self terminate];
                }
            }
        }
        
    };
    
    DLog(@"SENDING");
    [[SpeechRecognitionService sharedInstance] streamAudioData:self.audioData withCompletion:compHandler];
    
    // Discard previously accumulated audio data
    self.audioData = [NSMutableData new];
}

#pragma mark - Send query to server

- (void)sendQuery:(NSString *)queryStr {
    DLog(@"Sending query to server: '%@'", queryStr);
    
    // Completion handler for Greynir API request
    id completionHandler = ^(NSURLResponse *response, id responseObject, NSError *error) {
        if (self.terminated) {
            DLog(@"Terminated task received query server response: %@", [response description]);
            return;
        }
        
        DLog(@"Greynir server response: %@", [responseObject description]);
        
        if (error) {
//            [self log:[NSString stringWithFormat:@"Error: %@", error]];
            DLog(@"Error from query server: %@", [error localizedDescription]);
            [self.delegate sessionDidRaiseError:error];
        } else {
            NSDictionary *r = responseObject;
            NSString *answer = @"Það veit ég ekki";
            
            // If response data is valid, play back the provided audio URL
            if ([r isKindOfClass:[NSDictionary class]] && [r[@"valid"] boolValue]) {
                id greynirResponse = [r objectForKey:@"response"];
                if (greynirResponse && [greynirResponse isKindOfClass:[NSString class]]) {
                    answer = greynirResponse;
                } else {
                    DLog(@"Malformed response: %@", [greynirResponse description]);
                }
                
                NSString *audioURLStr = [r objectForKey:@"audio"];
                if (audioURLStr) {
                    [self playRemoteURL:[NSURL URLWithString:audioURLStr]];
                }
            }
            else {
                // If response is not valid, use local "I don't know" reply
                [self playAudio:@"dunno"];
            }
            
            // Notify delegate
            [self.delegate sessionDidReceiveAnswer:answer];
        }
    };
    
    // Post query to the API
    [[QueryService sharedInstance] sendQuery:queryStr withCompletionHandler:completionHandler];
}

#pragma mark - Playback

- (void)playAudio:(id)filenameOrData {
    // Utility function that creates an AVAudioPlayer to play either a local file or audio data
    
    // Change audio session to playback mode
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
//                                     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
//                                           error:nil];
    NSError *err;
    AVAudioPlayer *player;
    
    if ([filenameOrData isKindOfClass:[NSString class]]) {
        // Local filename specified, init player with local file URL
        NSString *filename = (NSString *)filenameOrData;
        NSURL *url = [[NSBundle mainBundle] URLForResource:filename withExtension:@"caf"];
        if (url) {
            DLog(@"Playing audio file %@", filename);
            player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
        } else {
            DLog(@"Unable to find audio file '%@.caf' in bundle", filename);
        }
    }
    else if ([filenameOrData isKindOfClass:[NSData class]]) {
        // Init player with audio data
        NSData *data = (NSData *)filenameOrData;
        DLog(@"Playing audio data of size %d", (int)[data length]);
        player = [[AVAudioPlayer alloc] initWithData:data error:&err];
    }
    else {
        DLog(@"playAudio argument neither filename nor data.");
        return;
    }
    
    if (err == nil) {
        // Configure player and set it off
        [player setMeteringEnabled:YES];
        [player setDelegate:self];
        [player play];
        self.audioPlayer = player;
    } else {
        DLog(@"%@", [err localizedDescription]);
        [self.delegate sessionDidRaiseError:err];
    }
}

- (void)playRemoteURL:(NSURL *)url {
    // Download remote file, then play it
    DLog(@"Downloading audio URL: %@", [url description]);
    
    NSURLSessionDataTask *downloadTask = \
    [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (self.terminated) {
            DLog(@"Terminated task finished downloading audio file: %@", [response description]);
            return;
        }
        if (error) {
            DLog(@"Error downloading audio: %@", [error localizedDescription]);
            [self.delegate sessionDidRaiseError:error];
            return;
        }
        [self playAudio:data];
    }];
    [downloadTask resume];
}

#pragma mark - AVAudioPlayerDelegate

// Audio playback of the response is the final task in the pipeline.
// Once the speech audio file is done playing, the session is over.

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self terminate];
}

#pragma mark - Audio level

// The session has an audio level property. If we are recording, this is the volume
// of microphone input. Otherwise, the volume of the audio player is returned.

- (CGFloat)audioLevel {
    CGFloat level = 0.0f;
    if (_isRecording) {
        level = [self _normalizedPowerLevelFromDecibels:recordingDecibelLevel];
    }
    else if (self.audioPlayer && [self.audioPlayer isPlaying]) {
        [self.audioPlayer updateMeters];
        float decibels = [self.audioPlayer averagePowerForChannel:0];
        level = [self _normalizedPowerLevelFromDecibels:decibels];
    }
    return level;
}

- (CGFloat)_normalizedPowerLevelFromDecibels:(CGFloat)decibels {
    if (decibels < -64.0f || decibels == 0.0f) {
        return 0.0f;
    }
    // TODO: Tweak this for better results?
    return powf(
                // 10 to the power of 0.1*DB  - 10 to the power of 0.1*-60
                (powf(10.0f, 0.1f * decibels) - powf(10.0f, 0.1f * -60.0f)) *
                // Multiplied by
                (1.0f / (1.0f - powf(10.0f, 0.1f * -60.0f))),
                // To the power of 0.5
                1.0f / 2.0f);
}

@end
