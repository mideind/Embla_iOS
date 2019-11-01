/*
 * This file is part of the Embla iOS app
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
#import "QueryService.h"

@interface SettingsViewController ()

@property (nonatomic, weak) IBOutlet UISwitch *useLocationSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *voiceActivationSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *privacyModeSwitch;

@property (nonatomic, weak) IBOutlet UISegmentedControl *voiceSegmentedControl;
@property (nonatomic, weak) IBOutlet UITextField *queryServerTextField;
@property (nonatomic, weak) IBOutlet UISegmentedControl *serverSegmentedControl;

@end

@implementation SettingsViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.useLocationSwitch becomeFirstResponder];
    [self configureControlsFromDefaults];
    [self updateLocationControl];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [self saveToDefaults];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Only show query server selection in debug mode
#ifdef DEBUG
    return 2;
#endif
    return 1;
}

#pragma mark - Location control handling

// Use Location switch shouldn't be on if the app doesn't
// have permission from the OS to receive location data
- (void)updateLocationControl {
    BOOL locEnabled = [DEFAULTS boolForKey:@"UseLocation"];
    [self.useLocationSwitch setOn:[self canUseLocation] && locEnabled];
}
    
- (BOOL)canUseLocation {
    if ([CLLocationManager locationServicesEnabled]) {
        switch ([CLLocationManager authorizationStatus]) {
            
            case kCLAuthorizationStatusRestricted:
            case kCLAuthorizationStatusDenied:
            case kCLAuthorizationStatusNotDetermined:
                return NO;
                break;
            
            case kCLAuthorizationStatusAuthorizedAlways:
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                return YES;
                break;
        }
    }
    return NO;
}

#pragma mark - Synchronize defaults & controls

// Configure controls according to defaults
// Horrible to have to do this manually. Why no bindings on iOS?
- (void)configureControlsFromDefaults {
    [self.voiceActivationSwitch setOn:[DEFAULTS boolForKey:@"VoiceActivation"]];
    [self.useLocationSwitch setOn:[DEFAULTS boolForKey:@"UseLocation"]];
    [self.privacyModeSwitch setOn:[DEFAULTS boolForKey:@"PrivacyMode"]];
    [self.voiceSegmentedControl setSelectedSegmentIndex:[DEFAULTS integerForKey:@"Voice"]];
    [self.queryServerTextField setText:[DEFAULTS stringForKey:@"QueryServer"]];
}

// Configure defaults according to controls in Settings view, synchronize
- (void)saveToDefaults {
    [DEFAULTS setBool:self.voiceActivationSwitch.isOn forKey:@"VoiceActivation"];
    [DEFAULTS setBool:self.useLocationSwitch.isOn forKey:@"UseLocation"];
    [DEFAULTS setBool:self.privacyModeSwitch.isOn forKey:@"PrivacyMode"];
    [DEFAULTS setInteger:[self.voiceSegmentedControl selectedSegmentIndex] forKey:@"Voice"];
    
    // Sanitize query server URL
    NSString *server = [self.queryServerTextField text];
    NSString *trimmed = [server stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (![trimmed hasPrefix:@"https://"] && ![trimmed hasPrefix:@"http://"]) {
        // Make sure URL has URI scheme component
        trimmed = [@"http://" stringByAppendingString:trimmed];
    }
    [DEFAULTS setObject:trimmed forKey:@"QueryServer"];
    [DEFAULTS synchronize];
}

#pragma mark - Button actions

- (IBAction)useLocationToggled:(id)sender {
    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([sender isOn]) {
        [self.privacyModeSwitch setOn:NO];
        if ([self canUseLocation] == NO) {
            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:^(BOOL success) {
                [del startLocationServices];
            }];
        } else {
            [del startLocationServices];
        }
    } else {
        [del stopLocationServices];
    }
    [self saveToDefaults];
}

- (IBAction)privacyModeToggled:(id)sender {
    if ([sender isOn]) {
        [self showPrivacyModeAlert:^(void) {
            [self.useLocationSwitch setOn:NO];
            [self useLocationToggled:self.useLocationSwitch];
            [self saveToDefaults];
        }];
    } else {
        [self saveToDefaults];
    }
}

- (IBAction)serverPresetSelected:(id)sender {
    NSString *url = DEFAULT_QUERY_SERVER;
    switch ([sender selectedSegmentIndex]) {
        case 1:
            url = @"http://46.4.45.9:5000";
            break;
        case 2:
            url = @"http://192.168.1.45:5000";
            break;
        case 3:
            url = @"http://192.168.1.3:5000";
            break;
        default:
            break;
    }
    [self.queryServerTextField setText:url];
}

- (IBAction)clearHistoryPressed:(id)sender {
    [self showClearHistoryAlert];
}

#pragma mark - Clear query history

// Send HTTP request to query server asking for the deletion of the device's query history
- (void)clearHistory {
    [[QueryService sharedInstance] clearDeviceHistory:^(NSURLResponse *response, id responseObject, NSError *err) {
         if (err == nil && [[responseObject objectForKey:@"valid"] boolValue]) {
             NSString *msg = @"Öllum fyrirspurnum frá þessu tæki hefur nú verið eytt.";
             [self showAlert:@"Fyrirspurnasögu eytt" message:msg];
         } else {
             NSString *msg = @"Ekki tókst að eyða fyrirspurnasögu tækis.";
             [self showAlert:@"Villa kom upp" message:msg];
             DLog(@"Error deleting query history: %@", [err localizedDescription]);
         }
    }];
}

#pragma mark - Alerts

// Show alert asking user to confirm that he wants to activate Privacy Mode
- (void)showPrivacyModeAlert:(void (^ __nullable)(void))completionHandler {
    NSString *msg = @"Í einkaham sendir forritið engar upplýsingar frá sér að fyrirspurnatexta undanskildum.\
 Þetta kemur í veg fyrir að fyrirspurnaþjónn geti nýtt staðsetningu, gerð tækis o.fl. til þess að bæta svör.";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Virkja einkaham?"
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Virkja"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) { completionHandler(); }];
    [alert addAction:confirmAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Hætta við"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             [self.privacyModeSwitch setOn:NO];
                                                             [self saveToDefaults];
                                                         }];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// Show alert asking user whether he wants to delete query history
- (void)showClearHistoryAlert {
    NSString *msg = @"Þessi aðgerð hreinsar alla fyrirspurnasögu þessa tækis.\
 Fyrirspurnir eru aðeins vistaðar í 30 daga og gögnin einungis nýtt til þess að bæta svör.";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hreinsa fyrirspurnasögu?"
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Hreinsa"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) { [self clearHistory]; }];
    [alert addAction:confirmAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Hætta við"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// Show generic alert with "OK" button
- (void)showAlert:(NSString *)title message:(NSString *)msg {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Allt í lagi"
                                                            style:UIAlertActionStyleDefault
                                                          handler:nil];
    [alert addAction:confirmAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Query Server text field delegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.queryServerTextField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self saveToDefaults];
}

@end