/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2019-2022 Miðeind ehf.
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

#import <AVFoundation/AVFoundation.h>

#import "VoiceSelectionViewController.h"
#import "QueryService.h"
#import "DataURI.h"
#import "Common.h"

#define FALLBACK_VOICES     @[@"Dora", @"Karl"]

@interface VoiceSelectionViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *progressView;;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSArray *voices;

@end

@implementation VoiceSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    
    self.voices = FALLBACK_VOICES;
    
#ifdef DEBUG
    // Load list of voices from remote server when in debug mode
    self.progressView = [[UIActivityIndicatorView alloc] initWithFrame:self.view.bounds];
    self.progressView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleLarge;
    
    [self.progressView startAnimating];
    [self.view addSubview:self.progressView];
    
    // Completion handler block for query server voice list API request
    id completionHandler = ^(NSURLResponse *response, id responseObject, NSError *error) {
        [self.progressView stopAnimating];
        [self.progressView removeFromSuperview];
        
        if (error || responseObject == nil) {
            DLog(@"Error from query server voices API: %@", [error localizedDescription]);
        }
        else if ([responseObject objectForKey:@"supported"] != nil) {
            self.voices = [responseObject objectForKey:@"supported"];
        }
        
        // Make sure voice ID in settings is sane
        NSString *currVoiceID = [DEFAULTS objectForKey:@"VoiceID"];
        if ([self.voices containsObject:currVoiceID] == NO) {
            if (responseObject != nil) {
                [DEFAULTS setObject:[responseObject objectForKey:@"default"] forKey:@"VoiceID"];
            } else {
                [DEFAULTS setObject:DEFAULT_VOICE_ID forKey:@"VoiceID"];
            }
        }
        
        [self.tableView reloadData];
    };
    
    [[QueryService sharedInstance] requestVoicesWithCompletionHandler:completionHandler];
#endif

    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *voiceName = [self.voices objectAtIndex:indexPath.row];
    [DEFAULTS setObject:voiceName forKey:@"VoiceID"];
    [DEFAULTS synchronize];
    DLog(@"Set VoiceID to \"%@\"", voiceName);
    [self.tableView reloadData];
//    [self.navigationController popViewControllerAnimated:YES];
    
    id synthesisCompletionHandler = ^(NSURLResponse *response, id responseObject, NSError *error) {
        NSDictionary *respDict = (NSDictionary *)responseObject;
        NSString *audioURLStr = [respDict objectForKey:@"audio_url"];
        if ([[respDict objectForKey:@"err"] boolValue] || !audioURLStr) {
            return;
        }
        [self playRemoteURL:audioURLStr];
    };
    
    // Speech synthesise text via Greynir API and play
    [[QueryService sharedInstance] requestSpeechSynthesis:@"Þessi rödd hljómar svona"
                                        completionHandler:synthesisCompletionHandler];

}

- (void)playAudio:(id)filenameOrData {
    [self playAudio:filenameOrData rate:1.0];
}

// Utility function that creates an AVAudioPlayer to play either a local file or audio data
- (void)playAudio:(id)filenameOrData rate:(float)rate {
    NSAssert([filenameOrData isKindOfClass:[NSString class]] || [filenameOrData isKindOfClass:[NSData class]],
             @"playAudio argument neither filename string nor data.");
    
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
        player = [[AVAudioPlayer alloc] initWithData:data error:&err];
        DLog(@"Playing audio data (%.2f seconds, size %d bytes)", player.duration, (int)[data length]);
    }
    
    if (err) {
        DLog(@"%@", [err localizedDescription]);
        return;
    }
    
    // Configure player and set it off
    self.audioPlayer = player;
    [self.audioPlayer setVolume:1.0];
    if (rate != 1.0) {
        self.audioPlayer.enableRate = YES;
        [self.audioPlayer setRate:rate];
    }
//    [player setMeteringEnabled:YES];
    [player play];
}


// Download remote MP3 file and play it when download is complete
- (void)playRemoteURL:(NSString *)urlString {
    
    // Special handling of Data URIs
    if ([DataURI isDataURI:urlString]) {
        DataURI *uri = [[DataURI alloc] initWithString:urlString];
        NSData *data = [uri data];
        if (uri == nil || data == nil) {
            NSString *msg = [NSString stringWithFormat:@"Failed to decode Data URI %@", urlString];
            NSError *error = [NSError errorWithDomain:@"Embla" code:0 userInfo:@{ NSLocalizedDescriptionKey:msg }];
            DLog(@"Error fetching audio: %@", [error localizedDescription]);
            return;
        }
        [self playAudio:data];
        return;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    DLog(@"Downloading audio URL: %@", [url description]);

    NSURLSessionDataTask *downloadTask = \
    [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        DLog(@"Response was: %@", [response description]);
                
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSDictionary *headerFields = [httpResponse allHeaderFields];
        
        // Make sure content-type is audio/mpeg
        NSString *contentType = [headerFields objectForKey:@"Content-Type"];
        if (!error && (!contentType || ![contentType isEqualToString:@"audio/mpeg"])) {
            NSString *msg = [NSString stringWithFormat:@"Wrong content type from speech audio server: %@", contentType];
            error = [NSError errorWithDomain:@"Embla" code:0 userInfo:@{ NSLocalizedDescriptionKey:msg }];
        }
        
        if (error) {
            DLog(@"Error downloading audio: %@", [error localizedDescription]);
            return;
        }
        DLog(@"Commencing audio answer playback");
        [self playAudio:data];
    }];
    [downloadTask resume];
}


#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return -5.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.voices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VoiceCellIdentifier"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"VoiceCellIdentifier"];
        cell.backgroundColor = [UIColor clearColor];
        cell.imageView.image = [UIImage systemImageNamed:@"waveform"];
    }
    
    NSString *voiceName = [self.voices objectAtIndex:indexPath.row];
    cell.textLabel.text = voiceName;
    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([voiceName isEqualToString:[DEFAULTS objectForKey:@"VoiceID"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
