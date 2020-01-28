/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2019-2020 Miðeind ehf.
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

#import "google/cloud/speech/v1/CloudSpeech.pbrpc.h"
#import <Foundation/Foundation.h>

typedef void (^SpeechRecognitionCompletionHandler)(StreamingRecognizeResponse *object, NSError *error);

@interface SpeechRecognitionService : NSObject

@property(nonatomic, assign) double sampleRate;
@property(nonatomic, assign) BOOL interimResults;
@property(nonatomic, assign) BOOL singleUtterance;

+ (instancetype)sharedInstance;
- (void)streamAudioData:(NSData *)audioData withCompletion:(SpeechRecognitionCompletionHandler)completion;
- (void)stopStreaming;
- (BOOL)isStreaming;
- (BOOL)hasAPIKey;

@end
