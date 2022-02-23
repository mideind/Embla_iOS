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

#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "Common.h"
#import "QueryService.h"

#define QUERY_SERVER_PRESETS \
@[DEFAULT_QUERY_SERVER,\
@"http://brandur.mideind.is:5000",\
@"http://192.168.1.113:5000",\
@"http://192.168.1.3:5000"]

@interface SettingsViewController ()

@property (nonatomic, weak) IBOutlet UILabel *swVersionLabel;
@property (nonatomic, weak) IBOutlet UISwitch *hotwordSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *useLocationSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *privacyModeSwitch;
@property (nonatomic, weak) IBOutlet UISegmentedControl *voiceSegmentedControl;
@property (nonatomic, weak) IBOutlet UILabel *speechSpeedLabel;
@property (nonatomic, weak) IBOutlet UISlider *speechSpeedSlider;

// Controls only visible in debug mode
@property (nonatomic, weak) IBOutlet UITextField *queryServerTextField;
@property (nonatomic, weak) IBOutlet UISegmentedControl *serverSegmentedControl;
@property (nonatomic, weak) IBOutlet UITextField *speech2textServerTextField;

@end

@implementation SettingsViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    
    // Configure segmented control text attributes
    UIFont *font = [UIFont fontWithName:@"Lato" size:15.0f];
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    [self.voiceSegmentedControl setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    // Software version label
    NSString *v = [NSString stringWithFormat:@"%@ (%@) - %@",
                   CLIENT_VERSION, CLIENT_BUILD, CLIENT_OSNAME];
#ifdef DEBUG
    v = [v stringByAppendingString:@" dbg"];
#endif
    [self.swVersionLabel setText:v];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.useLocationSwitch becomeFirstResponder];
    [self configureControlsFromDefaults];
    [self updateLocationControl];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveToDefaults];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return -5.0f;
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
    [self.hotwordSwitch setOn:[DEFAULTS boolForKey:@"VoiceActivation"]];
    [self.useLocationSwitch setOn:[DEFAULTS boolForKey:@"UseLocation"]];
    [self.privacyModeSwitch setOn:[DEFAULTS boolForKey:@"PrivacyMode"]];
    [self.speechSpeedSlider setValue:[DEFAULTS floatForKey:@"SpeechSpeed"]];
    [self updateSpeechSpeedLabel];

#ifdef DEBUG
    [self.voiceSegmentedControl removeAllSegments];
    for (NSString *name in @[@"Gunnar", @"Gudrun", @"Karl", @"Dora"]) {
        [self.voiceSegmentedControl insertSegmentWithTitle:name
                                                   atIndex:0
                                                  animated:NO];
    }
#endif
    
    // Find which voice segment to select
    NSString *voiceName = [DEFAULTS stringForKey:@"VoiceID"];
    NSUInteger voiceToSelect = 0;
    for (int i = 0; i < [self.voiceSegmentedControl numberOfSegments]; i++) {
        NSString *title = [self.voiceSegmentedControl titleForSegmentAtIndex:i];
        if ([title isEqualToString:voiceName]) {
            voiceToSelect = i;
            break;
        }
    }
    [self.voiceSegmentedControl setSelectedSegmentIndex:voiceToSelect];
    
#ifdef DEBUG
    // Query server settings
    NSString *url = [DEFAULTS stringForKey:@"QueryServer"];
    [self.queryServerTextField setText:url];
    NSInteger toSelect = [QUERY_SERVER_PRESETS indexOfObject:url];
    [self.serverSegmentedControl setSelectedSegmentIndex:toSelect];
    
    // Speech to text server settings
    [self.speech2textServerTextField setText:[DEFAULTS stringForKey:@"Speech2TextServer"]];
#endif
}

// Configure defaults according to controls in Settings view, synchronize
- (void)saveToDefaults {
    [DEFAULTS setBool:self.hotwordSwitch.isOn forKey:@"VoiceActivation"];
    [DEFAULTS setBool:self.useLocationSwitch.isOn forKey:@"UseLocation"];
    [DEFAULTS setBool:self.privacyModeSwitch.isOn forKey:@"PrivacyMode"];
    NSString *voiceName = [self.voiceSegmentedControl titleForSegmentAtIndex:[self.voiceSegmentedControl selectedSegmentIndex]];
    if ([voiceName isEqualToString:@"Kona"]) {
        voiceName = @"Dora";
    } else if ([voiceName isEqualToString:@"Karl"]) {
        voiceName = @"Karl";
    }
    [DEFAULTS setObject:voiceName forKey:@"VoiceID"];
    [DEFAULTS setFloat:[self.speechSpeedSlider value] forKey:@"SpeechSpeed"];
    
    // Sanitize query server URL
    NSString *server = [self.queryServerTextField text];
    NSString *trimmed = [server stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (![trimmed hasPrefix:@"https://"] && ![trimmed hasPrefix:@"http://"]) {
        // Make sure URL has URI scheme component
        trimmed = [@"http://" stringByAppendingString:trimmed];
    }
    [DEFAULTS setObject:trimmed forKey:@"QueryServer"];
        
    // Speech to text server
    NSString *txt = self.speech2textServerTextField.text;
    NSString *sttVal = txt && ![txt isEqualToString:@""] ? txt : DEFAULT_SPEECH2TEXT_SERVER;
    [DEFAULTS setObject:sttVal forKey:@"Speech2TextServer"];
    
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

// Implements fixed step size for speech speed slider control.
// Snaps to nearest value that is a multiple of 0.1, range is 0.7-1.3.
-(IBAction)speechSpeedChanged:(UISlider *)sender {
    float stepSize = 0.05f;
    float newStep = roundf((sender.value) / stepSize);
    float val = newStep * stepSize;
    sender.value = val;
    [self updateSpeechSpeedLabel];
}

- (void)updateSpeechSpeedLabel {
    float val = self.speechSpeedSlider.value;
    NSString *s = [NSString stringWithFormat:@"%.2f", val];
    if ([s hasSuffix:@"0"]) {
        s = [s substringToIndex:[s length] - 1];
    }
    s = [s stringByReplacingOccurrencesOfString:@"." withString:@","];
    [self.speechSpeedLabel setText:[NSString stringWithFormat:@"Talhraði (%@x)", s]];
}

- (IBAction)serverPresetSelected:(id)sender {
    NSString *url = DEFAULT_QUERY_SERVER;
    NSArray *presets = QUERY_SERVER_PRESETS;
    NSInteger idx = [sender selectedSegmentIndex];
    
    if (idx < [presets count]) {
        url = [presets objectAtIndex:(NSUInteger)idx];
    }
    [self.queryServerTextField setText:url];
}

#pragma mark -

- (IBAction)clearHistoryPressed:(id)sender {
    [self showClearHistoryAlert];
}

- (IBAction)clearAllDataPressed:(id)sender {
    [self showClearAllDataAlert];
}

#pragma mark - Clear query history

// Send HTTP request to query server asking for the deletion of the device's query history
- (void)clearHistory {
    [[QueryService sharedInstance] clearUserData:NO completionHandler:^(NSURLResponse *response, id responseObject, NSError *err) {
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

// Send HTTP request to query server asking for the deletion of all user data associated w. device
- (void)clearAllUserData {
    [[QueryService sharedInstance] clearUserData:YES completionHandler:^(NSURLResponse *response, id responseObject, NSError *err) {
         if (err == nil && [[responseObject objectForKey:@"valid"] boolValue]) {
             NSString *msg = @"Öllum gögnum sem tengjast þessu tæki hefur nú verið eytt.";
             [self showAlert:@"Öllum gögnum eytt" message:msg];
         } else {
             DLog(@"Error deleting user data: %@", [err localizedDescription]);
             NSString *msg = @"Ekki tókst að eyða gögnum sem tengjast þessu tæki.";
             [self showAlert:@"Villa kom upp" message:msg];
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

// Show alert asking user whether he wants to delete query history
- (void)showClearAllDataAlert {
    NSString *msg = @"Þessi aðgerð hreinsar öll gögn Emblu sem tengjast þessu tæki.\
 Gögnin eru einungis nýtt til þess að bæta svör.";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hreinsa öll gögn?"
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Hreinsa"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) { [self clearAllUserData]; }];
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
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self saveToDefaults];
}

@end
