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
#import "AudioController.h"
#import "SpeechRecognitionService.h"
#import "ViewController.h"

@import AWSCore;
@import AWSPolly;

#define SAMPLE_RATE 16000.0f

@interface ViewController () <AudioControllerDelegate>

@property(nonatomic, strong) IBOutlet UITextView *textView;
@property(nonatomic, weak) IBOutlet UIButton *startButton;
@property(nonatomic, weak) IBOutlet UIButton *stopButton;
@property(nonatomic, strong) NSMutableData *audioData;
@property(atomic, strong) AVPlayer *player;
@property(atomic, strong) NSString *queryString;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [AudioController sharedInstance].delegate = self;
}

- (IBAction)recordAudio:(id)sender {
    
    [self clearLog];
    
    NSLog(@"Starting recording");
    
    // Configure controls
    [_stopButton setEnabled:YES];
    [_startButton setEnabled:NO];
    self.queryString = @"";
    
    // Configure audio session
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                           error:nil];
    _audioData = [[NSMutableData alloc] init];
    [[AudioController sharedInstance] prepareWithSampleRate:SAMPLE_RATE];
    [[SpeechRecognitionService sharedInstance] setSampleRate:SAMPLE_RATE];
    [[AudioController sharedInstance] start];
}

- (IBAction)stopAudio:(id)sender {
    NSLog(@"Stopping audio");

    // Stop audio session
    [[AudioController sharedInstance] stop];
    [[SpeechRecognitionService sharedInstance] stopStreaming];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [_stopButton setEnabled:NO];
        [_startButton setEnabled:YES];
        
        if (self.queryString && [self.queryString length]) {
            [self askGreynir:self.queryString];
        } else {
            //[self log:@"Engin fyrirspurn."];
        }
    }];
}

- (void)clearLog {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        _textView.text = [_textView.text stringByAppendingString:@""];
    }];
}

- (void)log:(NSString *)str {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        _textView.text = [_textView.text stringByAppendingString:str];
        _textView.text = [_textView.text stringByAppendingString:@"\n"];
    }];
}

- (void)processSampleData:(NSData *)data {
    [self.audioData appendData:data];
    
    NSInteger frameCount = [data length] / 2;
    int16_t *samples = (int16_t *)[data bytes];
    int64_t sum = 0;
    for (int i = 0; i < frameCount; i++) {
        sum += abs(samples[i]);
    }
    NSLog(@"Audio frame count %d %d", (int)frameCount, (int)(sum * 1.0 / frameCount));

    // Google recommends sending samples in 100ms chunks
    int chunk_size = 0.1 /* seconds/chunk */ * SAMPLE_RATE * 2 /* bytes/sample */; /* bytes/chunk */

    if ([self.audioData length] > chunk_size) {
        NSLog(@"SENDING");
        [[SpeechRecognitionService sharedInstance]
            streamAudioData:self.audioData
             withCompletion:^(StreamingRecognizeResponse *response, NSError *error) {
                 if (error) {
                     NSLog(@"ERROR: %@", error);
                     [self log:[error localizedDescription]];
                     [self stopAudio:nil];
                 } else if (response) {
                     BOOL finished = NO;
                     NSLog(@"RESPONSE: %@", response);
                     NSLog(@"Speech event type: %d", response.speechEventType);
                     for (StreamingRecognitionResult *result in response.resultsArray) {
                         if (result.isFinal) {
                             if ([result.alternativesArray count]) {
                                 SpeechRecognitionAlternative *best = result.alternativesArray[0];
                                 NSString *transcr = best.transcript;
                                 _queryString = transcr;
                                 [self log:@"Interpretation:"];
                                 [self log:_queryString];
                             } else {
                                 [self log:@"No alternative found."];
                             }
                             finished = YES;
                         }
                     }
                     NSLog(@"%@", [response description]);
                     if (finished) {
                         [self stopAudio:nil];
                     }
                 }
             }];
        self.audioData = [[NSMutableData alloc] init];
    }
}

- (void)askGreynir:(NSString *)questionStr {
    [self log:@"Querying Greynir:"];
    [self log:questionStr];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

    NSString *apiEndpoint = @"https://greynir.is/query.api/v1";
    NSDictionary *parameters = @{@"q" : questionStr};
    NSURLRequest *req = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET"
                                                                      URLString:apiEndpoint
                                                                     parameters:parameters
                                                                          error:nil];
    NSURLSessionDataTask *dataTask = [manager
        dataTaskWithRequest:req
          completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
              if (error) {
                  [self log:[NSString stringWithFormat:@"Error: %@", error]];
              } else {
                  NSDictionary *r = responseObject;
                  NSString *s = @"Ekkert svar fannst.";
                  if ([r[@"valid"] boolValue]) {
                      // TODO: Support responses with a single answer (JSON format differs)
                      NSDictionary *greynirResponse = r[@"response"];
                      if ([greynirResponse objectForKey:@"answers"] != nil && [greynirResponse[@"answers"] count]) {
                          NSArray *manyAnsw = greynirResponse[@"answers"];
                          NSString *bestResponse = manyAnsw[0][@"answer"];
                          s = bestResponse;
                      }
                  }
                  [self speakText:s];
              }
          }];
    [dataTask resume];
}

- (void)speakText:(NSString *)txt {
    [self log:@"Speaking text"];
    [self log:txt];
    
    AWSPollySynthesizeSpeechURLBuilderRequest *input = [[AWSPollySynthesizeSpeechURLBuilderRequest alloc] init];
    input.text = txt;
    input.voiceId = AWSPollyVoiceIdDora;
    input.outputFormat = AWSPollyOutputFormatMp3;

    AWSTask *builder = [[AWSPollySynthesizeSpeechURLBuilder defaultPollySynthesizeSpeechURLBuilder] getPreSignedURL:input];
    [builder continueWithSuccessBlock:^id(AWSTask *t) {

        NSURL *url = [t result];
        NSLog(@"%@", url.description);
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                         withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                               error:nil];
        NSError *err;
        [[AVAudioSession sharedInstance] setActive:YES error:&err];
        self.player = [AVPlayer playerWithURL:[url copy]];
        [self.player setAllowsExternalPlayback:YES];
        [self.player setVolume:1.0f];
        [self.player play];

        return nil;
    }];
}

@end
