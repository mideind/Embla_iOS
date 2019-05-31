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
#import "AFNetworking.h"
#import <SDWebImage/SDWebImage.h>
#import "AudioController.h"
#import "SpeechRecognitionService.h"
#import "ViewController.h"
#import "Config.h"

@import AWSCore;
@import AWSPolly;

#define SAMPLE_RATE 16000.0f

@interface ViewController () <AudioControllerDelegate>

@property(nonatomic, weak) IBOutlet UITextView *textView;
@property(nonatomic, weak) IBOutlet UIButton *button;
@property(nonatomic, weak) IBOutlet UIImageView *imageView;
@property(nonatomic, strong) NSMutableData *audioData;
@property(atomic, strong) AVPlayer *player;
@property(atomic, strong) NSString *queryString;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [AudioController sharedInstance].delegate = self;
    [self clearLog];
//    [self askGreynir:@"Hver er Katrín Jakobsdóttir?"];
}

- (IBAction)toggle:(id)sender {
    if ([self.button.currentTitle isEqualToString:@"Hlusta"]) {
        [self recordAudio:sender];
    } else {
        [self stopAudio:sender];
    }
}

- (IBAction)recordAudio:(id)sender {
    DLog(@"Starting recording");

    [self.button setTitle:@"Hætta" forState:UIControlStateNormal];
    [self.imageView setImage:[UIImage imageNamed:@"Greynir"]];
    
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

- (IBAction)stopAudio:(id)sender {
    DLog(@"Stopping audio");

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
    [self.audioData appendData:data];
    
    NSInteger frameCount = [data length] / 2;
    int16_t *samples = (int16_t *)[data bytes];
    int64_t sum = 0;
    for (int i = 0; i < frameCount; i++) {
        sum += abs(samples[i]);
    }
    DLog(@"Audio frame count %d %d", (int)frameCount, (int)(sum * 1.0 / frameCount));

    // Google recommends sending samples in 100ms chunks
    int chunk_size = 0.1 /* seconds/chunk */ * SAMPLE_RATE * 2 /* bytes/sample */; /* bytes/chunk */

    if ([self.audioData length] > chunk_size) {
        DLog(@"SENDING");
        [[SpeechRecognitionService sharedInstance]
            streamAudioData:self.audioData
             withCompletion:^(StreamingRecognizeResponse *response, NSError *error) {
                 if (error) {
                     DLog(@"ERROR: %@", error);
                     [self log:[error localizedDescription]];
                     [self stopAudio:nil];
                 } else if (response) {
                     BOOL finished = NO;
                     DLog(@"RESPONSE: %@", response);
                     DLog(@"Speech event type: %d", response.speechEventType);
                     DLog(@"%@", [response.resultsArray description]);
                     for (StreamingRecognitionResult *result in response.resultsArray) {
                         if (result.isFinal) {
                             SpeechRecognitionAlternative *best = result.alternativesArray[0];
                             self.queryString = best.transcript;
                             if ([result.alternativesArray count]) {
                                 [self clearLog];
                                 [self log:@"Interpretation:"];
                                 [self logQuote:self.queryString];
                             } else {
                                 [self log:@"No interpretation found."];
                             }
                             finished = YES;
                         }
//                         else if ([result.alternativesArray count]) {
//                             SpeechRecognitionAlternative *best = result.alternativesArray[0];
//                             [self clearLog];
//                             [self log:best.transcript];
//                         }
                     }
                     DLog(@"%@", [response description]);
                     if (finished) {
                         [self stopAudio:nil];
                     }
                 }
             }];
        self.audioData = [NSMutableData new];
    }
}

- (void)askGreynir:(NSString *)questionStr {
    [self log:@"Querying Greynir:"];
    [self logQuote:questionStr];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

    NSString *apiEndpoint = @"https://greynir.is/query.api/v1";
    NSDictionary *parameters = @{@"q" : questionStr};
    NSURLRequest *req = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET"
                                                                      URLString:apiEndpoint
                                                                     parameters:parameters
                                                                          error:nil];
    
    // Completion handler for Greynir API request
    id completionHandler = ^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            [self log:[NSString stringWithFormat:@"Error: %@", error]];
        } else {
            NSDictionary *r = responseObject;
            NSString *s = @"Það veit ég ekki.";
            
            if ([r[@"valid"] boolValue]) {
//                [self log:@"Answer found"];
                id greynirResponse = r[@"response"];
                id greynirImage = [r objectForKey:@"image"];
                
                if (greynirImage != nil && [greynirImage isKindOfClass:[NSDictionary class]] && [(NSDictionary *)greynirImage objectForKey:@"src"]) {
                    NSString *imgURLStr = [(NSDictionary *)greynirImage objectForKey:@"src"];
                    [self.imageView sd_setImageWithURL:[NSURL URLWithString:imgURLStr]
                                      placeholderImage:[UIImage imageNamed:@"Greynir"]];
                }
                
                // Array response
                if ([greynirResponse isKindOfClass:[NSArray class]]) {
                    NSArray *gresp = greynirResponse;
                    if ([gresp count]) {
                        NSDictionary *first = gresp[0];
                        if ([first objectForKey:@"answer"]) {
                            s = first[@"answer"];
                        }
                    }
                }
                // Dict response
                else if ([greynirResponse isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *gresp = greynirResponse;
                    // Single answer
                    if ([gresp objectForKey:@"answer"] && [gresp[@"answer"] isKindOfClass:[NSString class]]) {
                        s = gresp[@"answer"];
                    }
                    // Multiple answers
                    else if ([gresp objectForKey:@"answers"] && [gresp[@"answers"] count]) {
                        NSArray *manyAnsw = gresp[@"answers"];
                        NSString *bestResponse = manyAnsw[0][@"answer"];
                        if ([bestResponse isKindOfClass:[NSString class]]) {
                            s = bestResponse;
                        }
                    }
                    
                }
            
            }
            [self speakText:s];
        }
    };
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:req completionHandler:completionHandler];
    [dataTask resume];
}

- (void)speakText:(NSString *)txt {
    [self log:@"Speaking text:"];
    [self logQuote:txt];
    
    AWSPollySynthesizeSpeechURLBuilderRequest *input = [AWSPollySynthesizeSpeechURLBuilderRequest new];
    input.text = txt;
    input.voiceId = AWSPollyVoiceIdDora;
    input.outputFormat = AWSPollyOutputFormatMp3;

    AWSTask *builder = [[AWSPollySynthesizeSpeechURLBuilder defaultPollySynthesizeSpeechURLBuilder] getPreSignedURL:input];
    [builder continueWithSuccessBlock:^id(AWSTask *t) {

        NSURL *url = [t result];
//        DLog(@"%@", url.description);
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                         withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                               error:nil];
        NSError *err;
        [[AVAudioSession sharedInstance] setActive:YES error:&err];
        self.player = [AVPlayer playerWithURL:url];
        [self.player setAllowsExternalPlayback:YES];
        [self.player setVolume:1.0f];
        [self.player play];

        return nil;
    }];
}

@end
