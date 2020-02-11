/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2019-2020 Miðeind ehf.
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
    Session class that handles the process of receiving speech input,
    communicating with the speech recognition API, sending the ensuing
    query to the query API and playing the synthesized response.
*/

#import "QuerySession.h"
#import "AudioRecordingService.h"
#import "Common.h"
#import "QueryService.h"
#import "SpeechRecognitionService.h"
#import <AVFoundation/AVFoundation.h>


#define SESSION_MIN_AUDIO_LEVEL 0.03f


static NSString * const kDontKnowAnswer = @"Það veit ég ekki.";


@interface QuerySession () <AudioRecordingServiceDelegate, AVAudioPlayerDelegate>
{
    CGFloat recordingDecibelLevel;
    CGFloat speechDuration;
    int speechAudioSize;
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

    [[AudioRecordingService sharedInstance] setDelegate:self];
    [[AudioRecordingService sharedInstance] start];
    
    [self.delegate sessionDidStartRecording];
}

- (void)stopRecording {
    _isRecording = NO;
    recordingDecibelLevel = 0.f;
    
    [[AudioRecordingService sharedInstance] stop];
    [[SpeechRecognitionService sharedInstance] stopStreaming];
    
    DLog(@"Speech recognition duration: %.2f seconds (%d bytes)", speechDuration, speechAudioSize);
    
    [self.delegate sessionDidStopRecording];
}

#pragma mark - AudioRecordingServiceDelegate

// Accumulates audio data from microphone until enough samples
// have been received to send to speech recognition server.
- (void)processSampleData:(NSData *)data {
    if (!_isRecording) {
        DLog(@"Received audio data (%d bytes) after recording ended.", (int)[data length]);
        return;
    }
    
    [self.audioData appendData:data];
    
    // Get audio frame properties
    NSInteger frameCount = [data length] / 2; // Mono 16-bit audio means each frame is 2 bytes
    int16_t *samples = (int16_t *)[data bytes]; // Cast void pointer
    
    // Calculate the average, max and sum of the received audio frames
//    int64_t sum = 0;
//    int64_t avg = 0;
    int16_t max = 0;
    for (int i = 0; i < frameCount; i++) {
//        sum += abs(samples[i]);
//        avg = !avg ? abs(samples[i]) : (avg + abs(samples[i])) / 2;
        max = (samples[i] > max) ? samples[i] : max;
    }
//    DLog(@"Audio frame count: %d avg: %d max: %d", (int)frameCount, (int)avg, (int)max);
    
    // We get amplitude range of 0.0-1.0 by dividing by the max value of a signed 16-bit integer
    float ampl = max/(float)SHRT_MAX;
//    float ampl = avg/(float)SHRT_MAX; // This also works but produces boring waveforms
    float decibels = 20.f * log10(ampl);
//    DLog(@"Ampl: %.8f", ampl);
//    DLog(@"DecB: %.2f", decibels);
    
    recordingDecibelLevel = decibels;
        
    // Google recommends sending samples in 100 ms chunks
    float duration = 0.1f;
    int bytes_per_sample = 2;
    int chunk_size = duration * REC_SAMPLE_RATE * bytes_per_sample;
    
    if ([self.audioData length] < chunk_size) {
        // Not enough data yet...
        return;
    }
    
    // Send data to speech recognition server.
    [self sendSpeechData:self.audioData];
    
    // Keep track of stats on data sent to recognition server
    speechDuration += duration;
    speechAudioSize += [self.audioData length];
    
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
    
//    DLog(@"Sending audio data to speech recognition server");
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
    
    // Iterate through speech recognition results.
    // The response contains an array of StreamingRecognitionResult
    // objects (typically just one). Each result object contains an array
    // of SpeechRecognitionAlternative objects ordered by probability.
    BOOL finished = NO;
    NSArray *transcripts;
    for (StreamingRecognitionResult *result in response.resultsArray) {
        if (result.isFinal) {
            // If true, this is the final time the speech service will return
            // this particular `StreamingRecognitionResult`. The recognizer
            // will not return any further hypotheses for this portion of
            // the transcript and corresponding audio.
            transcripts = [self _transcriptsFromRecognitionResult:result];
            finished = YES;
        } else {
            // These are interim results, with more results from the speech service
            // expected. Notify delegate if the results are sufficently stable.
            if (result.stability > MIN_STT_RESULT_STABILITY) {
                transcripts = [self _transcriptsFromRecognitionResult:result];
                [self.delegate sessionDidReceiveInterimResults:transcripts];
            }
        }
    }
    
    // We've received a final answer from the speech recognition server.
    // Stop recording and submit query, if any, to query server.
    if (finished) {
        [self stopRecording];
        if ([transcripts count]) {
            // Notify delegate
            [self.delegate sessionDidReceiveTranscripts:transcripts];
            // Send to query server
            [self sendQuery:[transcripts copy]];
        } else {
            [self terminate];
        }
    }
}

- (NSArray<NSString *> *)_transcriptsFromRecognitionResult:(StreamingRecognitionResult *)result {
    // Take data structure received from speech recognition server and
    // boil it down to an array of strings ordered by likelihood.
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
    NSDictionary *r = responseObject;
    DLog(@"Handling query server response: %@", [r description]);
    
    NSString *answer = kDontKnowAnswer;
    NSString *question = @"";
    NSString *source;
    NSURL *url;
    
    // If response data is valid, handle it
    if ([r isKindOfClass:[NSDictionary class]]) {
        
        answer = [r objectForKey:@"answer"];
        question = [r objectForKey:@"q"];
        source = [r objectForKey:@"source"];
        
        NSString *audioURLStr = [r objectForKey:@"audio"];
        NSString *openURLStr = [r objectForKey:@"open_url"];
        
        // If response contains a URL to open, there's no audio response playback
        if (openURLStr && [openURLStr isKindOfClass:[NSString class]]) {
            url = [NSURL URLWithString:openURLStr];
        }
        // Play back audio response
        else if (audioURLStr && [audioURLStr isKindOfClass:[NSString class]]) {
            [self playRemoteURL:[NSURL URLWithString:audioURLStr]];
        }
        // No audio response...
        else {
            answer = kDontKnowAnswer;
            [self playDontKnow];
        }
    }
    // Malformed response from query server
    else {
        NSString *msg = [NSString stringWithFormat:@"Malformed response from query server: %@", [r description]];
        NSError *error = [NSError errorWithDomain:@"Embla" code:0 userInfo:@{ NSLocalizedDescriptionKey: msg }];
        [self.delegate sessionDidRaiseError:error];
        return;
    }
    
    // Notify delegate
    [self.delegate sessionDidReceiveAnswer:answer toQuestion:question source:source withURL:url];
}

#pragma mark - Audio Playback

- (void)playAudio:(id)filenameOrData {
    // Utility function that creates an AVAudioPlayer to play either a local file or audio data
    NSAssert([filenameOrData isKindOfClass:[NSString class]] || [filenameOrData isKindOfClass:[NSData class]],
             @"playAudio argument neither filename string nor data.");
    
    // Change audio session to playback mode
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
//                                     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
//                                           error:nil];
    NSError *err;
    AVAudioPlayer *player;
    
    if ([filenameOrData isKindOfClass:[NSString class]]) {
        // Local filename specified, init player with local file URL
        NSString *filename = (NSString *)filenameOrData;
        NSURL *url = [[NSBundle mainBundle] URLForResource:filename withExtension:@"wav"];
        if (url) {
            DLog(@"Playing audio file '%@'", filename);
            player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
        } else {
            NSString *errStr = [NSString stringWithFormat:@"Unable to find audio file '%@' in bundle", filename];
            err = [NSError errorWithDomain:@"Embla" code:0 userInfo:@{ NSLocalizedDescriptionKey: errStr }];
        }
    }
    else {
        // Init player with audio data
        NSData *data = (NSData *)filenameOrData;
        DLog(@"Playing audio data (size %d bytes)", (int)[data length]);
        player = [[AVAudioPlayer alloc] initWithData:data error:&err];
    }
    
    if (err) {
        DLog(@"%@", [err localizedDescription]);
        [self.delegate sessionDidRaiseError:err];
        return;
    }
    
    // Configure player and set it off
    self.audioPlayer = player;
//    [player setMeteringEnabled:YES];
    [player setDelegate:self];
    [player play];
}

- (void)playRemoteURL:(NSURL *)url {
    // Download remote MP3 file and play it when download is complete
    DLog(@"Downloading audio URL: %@", [url description]);

    NSURLSessionDataTask *downloadTask = \
    [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        DLog(@"Response was: %@", [response description]);
        
        if (self.terminated) {
            DLog(@"Terminated task finished downloading audio file: %@", [response description]);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSDictionary *headerFields = [httpResponse allHeaderFields];
        
        // Make sure content-type is audio/mpeg
        NSString *contentType = [headerFields objectForKey:@"Content-Type"];
        if (!error && (!contentType || ![contentType isEqualToString:@"audio/mpeg"])) {
            NSString *msg = [NSString stringWithFormat:@"Wrong content type from speech audio server: %@", contentType];
            error = [NSError errorWithDomain:@"Embla" code:0 userInfo:@{ NSLocalizedDescriptionKey: msg }];
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
    NSUInteger vid = [[DEFAULTS objectForKey:@"Voice"] unsignedIntegerValue];
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
    CGFloat level = 0.f;
    CGFloat min = SESSION_MIN_AUDIO_LEVEL;
    if (_isRecording) {
        level = [self _normalizedPowerLevelFromDecibels:recordingDecibelLevel];
//        DLog(@"Audio level: %.2f", level);
    }
//    else if (self.audioPlayer && [self.audioPlayer isPlaying]) {
//        [self.audioPlayer updateMeters];
//        float decibels = [self.audioPlayer averagePowerForChannel:0];
//        level = [self _normalizedPowerLevelFromDecibels:decibels];
//    }
    return (isnan(level) || level < min) ? min : level;
}

// Given a decibel range, normalize it to a value between 0.0 and 1.0
- (CGFloat)_normalizedPowerLevelFromDecibels:(CGFloat)decibels {
    if (decibels < -60.0f || decibels == 0.0f) {
        return 0.0f;
    }
    CGFloat exp = 0.05f;
    return powf(
                    (powf(10.0f, exp * decibels) - powf(10.0f, exp * -60.0f))
                    * (1.0f / (1.0f - powf(10.0f, exp * -60.0f))),
                    1.0f / 2.0f
                );
}

@end
