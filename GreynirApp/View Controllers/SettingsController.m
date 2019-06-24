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

#import "SettingsController.h"
#import "AppDelegate.h"

@interface SettingsController ()

@property (nonatomic, weak) IBOutlet UISwitch *useLocationSwitch;
@property (nonatomic, weak) IBOutlet UISegmentedControl *voiceSegmentedControl;
@property (nonatomic, weak) IBOutlet UITextField *queryServerTextField;

@end

@implementation SettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [self configureControlsFromDefaults];
}

- (void)configureControlsFromDefaults {
    // Configure controls according to defaults
    // Horrible to do this manually. Why no bindings on iOS?
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self.useLocationSwitch setOn:[defaults boolForKey:@"UseLocation"]];
    [self.voiceSegmentedControl setSelectedSegmentIndex:[defaults integerForKey:@"Voice"]];
    [self.queryServerTextField setText:[defaults stringForKey:@"QueryServer"]];
}

- (void)viewWillDisappear:(BOOL)animated {
    // Save to defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.useLocationSwitch.isOn forKey:@"UseLocation"];
    [defaults setInteger:[self.voiceSegmentedControl selectedSegmentIndex] forKey:@"Voice"];
    [defaults setObject:[self.queryServerTextField text] forKey:@"QueryServer"];
    [defaults synchronize];
}

#pragma mark -

- (IBAction)useLocationToggled:(id)sender {
    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([sender isOn]) {
        [del startLocationServices];
    } else {
        [del stopLocationServices];
    }
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

@end
