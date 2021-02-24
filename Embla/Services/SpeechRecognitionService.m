/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2019-2021 Miðeind ehf.
 * Author: Sveinbjorn Thordarson
 * Adapted from Apache 2-licensed code Copyright (C) 2016 Google Inc.
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
    Singleton wrapper class for Google's gRPC-based speech recognition API.
*/

#import "SpeechRecognitionService.h"
#import "Common.h"
#import "Keys.h"
#import <GRPCClient/GRPCCall.h>
#import <ProtoRPC/ProtoRPC.h>
#import <RxLibrary/GRXBufferedPipe.h>

// Phrases sent to API as part of speech context. Should make their speech
// recognition more likely to identify these words. Doesn't seem to work for Icelandic. :/
#define PHRASES_ARRAY   @[] // Empty for now

@interface SpeechRecognitionService ()

@property(readonly) BOOL streaming;
@property(nonatomic, strong) Speech *client;
@property(nonatomic, strong) GRXBufferedPipe *writer;
@property(nonatomic, strong) GRPCProtoCall *call;
@property(nonatomic, strong) NSString *apiKey;

@end

@implementation SpeechRecognitionService

// Singleton
+ (instancetype)sharedInstance {
    static SpeechRecognitionService *instance = nil;
    if (!instance) {
        instance = [self new];
        
        NSData *d = [NSData dataWithBytes:gak length:strlen(gak)];
        NSData *d2 = [[NSData alloc] initWithBase64EncodedData:d options:0];
        instance.apiKey = [[NSString alloc] initWithData:d2 encoding:NSASCIIStringEncoding];
        if (!instance.apiKey) {
            instance.apiKey = @"";
        }
        
        // Default values
        instance.sampleRate = REC_SAMPLE_RATE;
        instance.singleUtterance = YES;
        instance.interimResults = YES;
    }
    return instance;
}

- (void)streamAudioData:(NSData *)audioData withCompletion:(SpeechRecognitionCompletionHandler)completion {

    if (!_streaming) {
        // If we aren't already streaming, set up a gRPC connection
        NSString *host = [DEFAULTS stringForKey:@"Speech2TextServer"];
        if (!host || [host length] < 5) { // No domain is going to be shorter than 5 chars
            host = DEFAULT_SPEECH2TEXT_SERVER;
        }
        _client = [[Speech alloc] initWithHost:host];
        _writer = [[GRXBufferedPipe alloc] init];
        _call = [_client RPCToStreamingRecognizeWithRequestsWriter:_writer
                                                      eventHandler:^(BOOL done, StreamingRecognizeResponse *response, NSError *error) {
                                                          completion(response, error);
                                                      }];
        
        // Authenticate using an API key obtained from the Google Cloud Console
        _call.requestHeaders[@"X-Goog-Api-Key"] = self.apiKey;
        // Specify the bundle ID in case the API key has a bundle ID restriction
        _call.requestHeaders[@"X-Ios-Bundle-Identifier"] = [[NSBundle mainBundle] bundleIdentifier];
        
        [_call start];
        _streaming = YES;
        
        // Send an initial request message to configure the service
        RecognitionConfig *recognitionConfig = [RecognitionConfig message];
        recognitionConfig.encoding = RecognitionConfig_AudioEncoding_Linear16;
        recognitionConfig.sampleRateHertz = self.sampleRate;
        recognitionConfig.languageCode = SPEECH2TEXT_LANGUAGE;
        recognitionConfig.maxAlternatives = NUM_SPEECH2TEXT_ALTERNATIVES;
        
//        SpeechContext *sc = [SpeechContext new];
//        [sc setPhrasesArray:[PHRASES_ARRAY mutableCopy]];
//        recognitionConfig.speechContextsArray = [@[sc] mutableCopy];
        
        StreamingRecognitionConfig *streamingRecognitionConfig = [StreamingRecognitionConfig message];
        streamingRecognitionConfig.config = recognitionConfig;
        streamingRecognitionConfig.singleUtterance = self.singleUtterance;
        streamingRecognitionConfig.interimResults = self.interimResults;
        
        StreamingRecognizeRequest *streamingRecognizeRequest = [StreamingRecognizeRequest message];
        streamingRecognizeRequest.streamingConfig = streamingRecognitionConfig;
        
        [_writer writeValue:streamingRecognizeRequest];
    }

    // Send a request message containing the audio data
    StreamingRecognizeRequest *streamingRecognizeRequest = [StreamingRecognizeRequest message];
    streamingRecognizeRequest.audioContent = audioData;
    [_writer writeValue:streamingRecognizeRequest];
}

- (void)stopStreaming {
    if (!_streaming) {
        return;
    }
    [_writer finishWithError:nil];
    _streaming = NO;
}

- (BOOL)isStreaming {
    return _streaming;
}

- (BOOL)hasAPIKey {
    return ([self.apiKey length] > 0);
}

@end
