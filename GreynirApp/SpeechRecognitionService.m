/*
 * This file is part of the Greynir iOS app
 * Copyright (c) 2019 Miðeind ehf.
 * Adapted from Apache 2-licensed code Copyright 2016 Google Inc.
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

#import "SpeechRecognitionService.h"
#import "Config.h"
#import <GRPCClient/GRPCCall.h>
#import <ProtoRPC/ProtoRPC.h>
#import <RxLibrary/GRXBufferedPipe.h>

#define HOST @"speech.googleapis.com"

@interface SpeechRecognitionService ()

@property(nonatomic, assign) BOOL streaming;
@property(nonatomic, strong) Speech *client;
@property(nonatomic, strong) GRXBufferedPipe *writer;
@property(nonatomic, strong) GRPCProtoCall *call;
@property(nonatomic, strong) NSString *apiKey;

@end

@implementation SpeechRecognitionService

+ (instancetype)sharedInstance {
    static SpeechRecognitionService *instance = nil;
    if (!instance) {
        instance = [[self alloc] init];
        instance.sampleRate = 16000.0; // Default value
        instance.apiKey = GOOGLE_SPEECH_API_KEY; // Read from bundled file
    }
    return instance;
}

- (void)streamAudioData:(NSData *)audioData withCompletion:(SpeechRecognitionCompletionHandler)completion {

    if (!_streaming) {
        // If we aren't already streaming, set up a gRPC connection
        _client = [[Speech alloc] initWithHost:HOST];
        _writer = [[GRXBufferedPipe alloc] init];
        _call = [_client RPCToStreamingRecognizeWithRequestsWriter:_writer
                                                      eventHandler:^(BOOL done, StreamingRecognizeResponse *response,
                                                                     NSError *error) {
                                                          completion(response, error);
                                                      }];

        // Authenticate using an API key obtained from the Google Cloud Console
        _call.requestHeaders[@"X-Goog-Api-Key"] = GOOGLE_SPEECH_API_KEY;
        // If the API key has a bundle ID restriction, specify the bundle ID like this
        _call.requestHeaders[@"X-Ios-Bundle-Identifier"] = [[NSBundle mainBundle] bundleIdentifier];

        NSLog(@"HEADERS: %@", _call.requestHeaders);

        [_call start];
        _streaming = YES;

        // Send an initial request message to configure the service
        RecognitionConfig *recognitionConfig = [RecognitionConfig message];
        recognitionConfig.encoding = RecognitionConfig_AudioEncoding_Linear16;
        recognitionConfig.sampleRateHertz = self.sampleRate;
        recognitionConfig.languageCode = @"is-IS";
        recognitionConfig.maxAlternatives = 30;

        StreamingRecognitionConfig *streamingRecognitionConfig = [StreamingRecognitionConfig message];
        streamingRecognitionConfig.config = recognitionConfig;
        streamingRecognitionConfig.singleUtterance = NO;
        streamingRecognitionConfig.interimResults = YES;

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

@end
