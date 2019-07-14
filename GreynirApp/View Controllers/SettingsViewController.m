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

#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "Common.h"

@interface SettingsViewController ()

@property (nonatomic, weak) IBOutlet UISwitch *useLocationSwitch;
@property (nonatomic, weak) IBOutlet UISegmentedControl *voiceSegmentedControl;
@property (nonatomic, weak) IBOutlet UITextField *queryServerTextField;

@end

@implementation SettingsViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [self.useLocationSwitch becomeFirstResponder];
    [self configureControlsFromDefaults];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self saveToDefaults];
}

#pragma mark -

- (void)configureControlsFromDefaults {
    // Configure controls according to defaults
    // Horrible to have to do this manually. Why no bindings on iOS?
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self.useLocationSwitch setOn:[defaults boolForKey:@"UseLocation"]];
    [self.voiceSegmentedControl setSelectedSegmentIndex:[defaults integerForKey:@"Voice"]];
    [self.queryServerTextField setText:[defaults stringForKey:@"QueryServer"]];
}

- (void)saveToDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.useLocationSwitch.isOn forKey:@"UseLocation"];
    [defaults setInteger:[self.voiceSegmentedControl selectedSegmentIndex] forKey:@"Voice"];
    
    // Sanitize query server URL
    NSString *server = [self.queryServerTextField text];
    NSString *trimmed = [server stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (![trimmed hasPrefix:@"https://"] && ![trimmed hasPrefix:@"http://"]) {
        // Make sure URL has URI scheme component
        trimmed = [@"https://" stringByAppendingString:trimmed];
    }
    [defaults setObject:trimmed forKey:@"QueryServer"];
    
    [defaults synchronize];
}

#pragma mark - Button actions

- (IBAction)useLocationToggled:(id)sender {
    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([sender isOn]) {
        if ([del locationServicesAvailable]) {
            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:^(BOOL success) {
                [del startLocationServices];
            }];
        }
    } else {
        [del stopLocationServices];
    }
    [self saveToDefaults];
}

- (IBAction)restoreDefaults:(id)sender {
    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSDictionary *def = [del startingDefaults];
    for (NSString *key in def) {
        [[NSUserDefaults standardUserDefaults] setObject:def[key] forKey:key];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self configureControlsFromDefaults];
}

#pragma mark - Text field delegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.queryServerTextField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self saveToDefaults];
}

@end
