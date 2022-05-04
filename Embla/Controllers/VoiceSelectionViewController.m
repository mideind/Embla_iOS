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

#import "VoiceSelectionViewController.h"
#import "QueryService.h"
#import "Common.h"

#define FALLBACK_VOICES     @[@"Dora", @"Karl"]

NSArray<NSString *> *voices;

@interface VoiceSelectionViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *progressView;;

@end

@implementation VoiceSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    
    if (voices != nil) {
        return;
    }
    
    self.progressView = [[UIActivityIndicatorView alloc] initWithFrame:self.view.bounds];
    self.progressView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleLarge;
    
    [self.progressView startAnimating];
    [self.view addSubview:self.progressView];
    
    // Completion handler block for query server voice list API request
    id completionHandler = ^(NSURLResponse *response, id responseObject, NSError *error) {
        voices = FALLBACK_VOICES;
        if (error || responseObject == nil) {
            DLog(@"Error from query server voices API: %@", [error localizedDescription]);
        }
#ifdef DEBUG
        else if ([responseObject objectForKey:@"supported"] != nil) {
            voices = [responseObject objectForKey:@"supported"];
        }
#else
        else if ([responseObject objectForKey:@"recommended"] != nil) {
            voices = [responseObject objectForKey:@"recommended"];
        }
#endif
        
        // Make sure voice ID in settings is sane
        NSString *currVoiceID = [DEFAULTS objectForKey:@"VoiceID"];
        if ([voices containsObject:currVoiceID] == NO) {
            if (responseObject != nil) {
                [DEFAULTS setObject:[responseObject objectForKey:@"default"] forKey:@"VoiceID"];
            } else {
                [DEFAULTS setObject:DEFAULT_VOICE_ID forKey:@"VoiceID"];
            }
        }
        
        [self.tableView reloadData];
        [self.progressView stopAnimating];
        [self.progressView removeFromSuperview];
    };
    
    [[QueryService sharedInstance] requestVoicesWithCompletionHandler:completionHandler];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *voiceName = [voices objectAtIndex:indexPath.row];
    [DEFAULTS setObject:voiceName forKey:@"VoiceID"];
    [DEFAULTS synchronize];
    DLog(@"Set VoiceID to \"%@\"", voiceName);
    [self.tableView reloadData];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return -5.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [voices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VoiceCellIdentifier"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"VoiceCellIdentifier"];
        cell.backgroundColor = [UIColor clearColor];
        cell.imageView.image = [UIImage systemImageNamed:@"waveform"];
    }
    
    NSString *voiceName = [voices objectAtIndex:indexPath.row];
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
