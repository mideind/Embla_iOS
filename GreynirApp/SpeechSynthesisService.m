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

#import "SpeechSynthesisService.h"

@import AWSCore;
@import AWSPolly;

@implementation SpeechSynthesisService

+ (instancetype)sharedInstance {
    static SpeechSynthesisService *instance = nil;
    if (!instance) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (void)synthesizeText:(NSString *)text completionHandler:(void (^)(NSData *audioData))completionHandler {
    
    AWSPollySynthesizeSpeechURLBuilderRequest *input = [AWSPollySynthesizeSpeechURLBuilderRequest new];
    input.text = text;
    input.voiceId = AWSPollyVoiceIdDora;
    input.outputFormat = AWSPollyOutputFormatMp3;
    
    // Request synthesis and receive audio URL
    AWSTask *builder = [[AWSPollySynthesizeSpeechURLBuilder defaultPollySynthesizeSpeechURLBuilder] getPreSignedURL:input];
    [builder continueWithSuccessBlock:^id(AWSTask *t) {
        // Download audio file from URL and hand over to completion handler
        NSURL *url = [t result];
        NSURLSessionDataTask *downloadTask = \
        [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            completionHandler(data);
        }];
        [downloadTask resume];
        return nil;
    }];
}

@end
