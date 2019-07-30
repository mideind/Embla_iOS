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

/*
    Session class that handles the process of receiving speech input,
    communicating with the speech recognition API, sending the ensuing
    query to the query API and playing the synthesized response.
*/

#import "QuerySession.h"
#import "AudioRecordingController.h"
#import "Common.h"
#import "QueryService.h"
#import "SpeechRecognitionService.h"
#import <AVFoundation/AVFoundation.h>


static NSString * const kDontKnowAnswer = @"Það veit ég ekki.";


@interface QuerySession () <AudioRecordingControllerDelegate, AVAudioPlayerDelegate>
{
    CGFloat recordingDecibelLevel;
    BOOL endOfSingleUtteranceReceived;
    BOOL hasSentQuery;
}
@property (nonatomic, strong) NSMutableData *audioData;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSString *queryString;

@end


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
    NSAssert(self.terminated == FALSE, @"Reusing one-off QuerySession object");
    DLog(@"Starting session");
    [self startRecording];
}

- (void)terminate {
    if (self.terminated) {
        return;
    }
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
    
    [[AudioRecordingController sharedInstance] setDelegate:self];
    [[AudioRecordingController sharedInstance] start];
    
    // We want to receive interim results from the speech recognition server
    [SpeechRecognitionService sharedInstance].interimResults = YES;
    
    [self.delegate sessionDidStartRecording];
}

- (void)stopRecording {
    _isRecording = NO;
    recordingDecibelLevel = 0.f;
    
    [[AudioRecordingController sharedInstance] stop];
    [[SpeechRecognitionService sharedInstance] stopStreaming];
    
    [self.delegate sessionDidStopRecording];
}

#pragma mark - AudioControllerDelegate

// Receives audio data from microphone and accumulates until enough
// samples have been received to send to speech recognition server.
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
    
    // Send data to speech recognition server.
    [self sendSpeechData:self.audioData];
    
    // Discard the accumulated audio data
    self.audioData = [NSMutableData new];
}

#pragma mark - Speech recognition

- (void)sendSpeechData:(NSData *)audioData {
    // Send audio data to speech recognition server
    
    // Completion handler
    SpeechRecognitionCompletionHandler compHandler = ^(StreamingRecognizeResponse *response, NSError *error) {
        if (self.terminated) {
            DLog(@"Terminated task received speech recognition response: %@", [response description]);
            return;
        }
        if (error) {
            // Stop recording on error
            DLog(@"Speech recognition error: %@", error);
            [self stopRecording];
            [self.delegate sessionDidRaiseError:error];
        }
        else {
            [self handleSpeechRecognitionResponse:response];
        }
    };
    
    DLog(@"Sending audio data to speech recognition server");
    [[SpeechRecognitionService sharedInstance] streamAudioData:self.audioData withCompletion:compHandler];
}

- (void)handleSpeechRecognitionResponse:(StreamingRecognizeResponse *)response {
    DLog(@"Received speech recognition response: %@", response);
    
    if (endOfSingleUtteranceReceived && !hasSentQuery && response == nil) {
        // The speech recognition session has timed out without recognition
        [self.delegate sessionDidReceiveTranscripts:nil];
        [self terminate];
        return;
    }
    
    if (response.speechEventType == StreamingRecognizeResponse_SpeechEventType_EndOfSingleUtterance) {
        // Speech recognition server is notifying us that it has
        // detected the end of a single utterance so we stop recording.
        endOfSingleUtteranceReceived = YES;
        [self stopRecording];
        return;
    }
    
    if (!response.resultsArray_Count) {
        // TODO: Handle this case.
    }
    
    // Iterate through speech recognition results.
    // The response contains an array of StreamingRecognitionResult
    // objects (typically just one). Each result object has an associated array
    // of SpeechRecognitionAlternative objects ordered by probability.
    BOOL finished = NO;
    NSArray *res;
    for (StreamingRecognitionResult *result in response.resultsArray) {
        // For now, we're only interested in final results.
        if (result.isFinal) {
            // If true, this is the final time the speech service will return
            // this particular `StreamingRecognitionResult`. The recognizer
            // will not return any further hypotheses for this portion of
            // the transcript and corresponding audio.
            res = [self _transcriptsFromRecognitionResult:result];
            finished = YES;
        } else {
            if (result.stability > 0.3) { // TODO: Arbitrary stability requirement
                res = [self _transcriptsFromRecognitionResult:result];
                [self.delegate sessionDidReceiveInterimResults:res];
            }
        }
    }
    
    // We've received a final answer from the speech recognition server.
    // Terminate recording and submit query, if any, to query server.
    if (finished) {
        [self stopRecording];
        if ([res count]) {
            [self.delegate sessionDidReceiveTranscripts:res];
            [self sendQuery:[res copy]];
        } else {
            [self terminate];
        }
    }
}

- (NSArray<NSString *> *)_transcriptsFromRecognitionResult:(StreamingRecognitionResult *)result {
    NSMutableArray<NSString *> *res = [NSMutableArray new];
    if ([result.alternativesArray count]) {
        for (SpeechRecognitionAlternative *a in result.alternativesArray) {
            [res addObject:a.transcript];
        }
    }
    return [res copy]; // Return immutable copy
}

#pragma mark - Send query to server

- (void)sendQuery:(NSArray<NSString *> *)alternatives {
    DLog(@"Sending query to server: %@", [alternatives description]);
    hasSentQuery = YES;
    
    // Completion handler block for query server API request
    id completionHandler = ^(NSURLResponse *response, id responseObject, NSError *error) {
        if (self.terminated) {
            // Ignore response if task has already been terminated
            DLog(@"Terminated task received query server response: %@", [response description]);
            return;
        }
        
        if (error) {
//            [self log:[NSString stringWithFormat:@"Error: %@", error]];
            DLog(@"Error from query server: %@", [error localizedDescription]);
            [self.delegate sessionDidRaiseError:error];
        } else {
            [self handleQueryResponse:responseObject];
        }
    };
    
    // Post query to the API
    [[QueryService sharedInstance] sendQuery:alternatives withCompletionHandler:completionHandler];
}

- (void)handleQueryResponse:(id)responseObject {
    DLog(@"Handling query server response: %@", [responseObject description]);
    NSDictionary *r = responseObject;
    
    NSString *answer = kDontKnowAnswer;
    NSString *question = @"";
    
    // If response data is valid, play back the provided audio URL
    if ([r isKindOfClass:[NSDictionary class]] && [r[@"valid"] boolValue]) {
        
        answer = [r objectForKey:@"answer"] ? r[@"answer"] : [r objectForKey:@"voice"];
        question = [r objectForKey:@"q"];
        
        NSString *audioURLStr = [r objectForKey:@"audio"];
        if (audioURLStr) {
            [self playRemoteURL:[NSURL URLWithString:audioURLStr]];
        } else {
            answer = kDontKnowAnswer;
            [self playDontKnow];
        }
    }
    else {
        // If response is not valid, use local "I don't know" reply
        [self playDontKnow];
    }
    
    // Notify delegate
    [self.delegate sessionDidReceiveAnswer:answer toQuestion:question];
}

#pragma mark - Audio Playback

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
            DLog(@"Playing audio file '%@'", filename);
            player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
        } else {
            DLog(@"Unable to find audio file '%@.caf' in bundle", filename);
            return;
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
    
    if (err) {
        DLog(@"%@", [err localizedDescription]);
        [self.delegate sessionDidRaiseError:err];
        return;
    }
    
    // Configure player and set it off
    [player setMeteringEnabled:YES];
    [player setDelegate:self];
    [player play];
    self.audioPlayer = player;
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

- (void)playDontKnow {
    NSUInteger vid = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Voice"] unsignedIntegerValue];
    NSString *suffix = vid == 0 ? @"dora" : @"karl";
    NSString *fn = [NSString stringWithFormat:@"dunno-%@", suffix];
    [self playAudio:fn];
}

#pragma mark - AVAudioPlayerDelegate

// Audio playback of the response is the final task in the pipeline.
// Once the speech audio file is done playing, the session is over.

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self terminate];
}

#pragma mark - Audio level

// The session has an audio level property. If we are recording, this is the volume of
// the latest microphone input. Otherwise, the volume of the audio player is returned.

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
