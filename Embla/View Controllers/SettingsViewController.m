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
#import "AFNetworking.h"

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
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [self.useLocationSwitch becomeFirstResponder];
    [self configureControlsFromDefaults];
    [self updateLocationControl];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self saveToDefaults];
}

#pragma mark -

- (void)updateLocationControl {
    BOOL locEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"UseLocation"];
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

#pragma mark -

- (void)configureControlsFromDefaults {
    // Configure controls according to defaults
    // Horrible to have to do this manually. Why no bindings on iOS?
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self.voiceActivationSwitch setOn:[defaults boolForKey:@"VoiceActivation"]];
    [self.useLocationSwitch setOn:[defaults boolForKey:@"UseLocation"]];
    [self.privacyModeSwitch setOn:[defaults boolForKey:@"PrivacyMode"]];
    [self.voiceSegmentedControl setSelectedSegmentIndex:[defaults integerForKey:@"Voice"]];
    [self.queryServerTextField setText:[defaults stringForKey:@"QueryServer"]];
}

- (void)saveToDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.voiceActivationSwitch.isOn forKey:@"VoiceActivation"];
    [defaults setBool:self.useLocationSwitch.isOn forKey:@"UseLocation"];
    [defaults setBool:self.privacyModeSwitch.isOn forKey:@"PrivacyMode"];
    [defaults setInteger:[self.voiceSegmentedControl selectedSegmentIndex] forKey:@"Voice"];
    
    // Sanitize query server URL
    NSString *server = [self.queryServerTextField text];
    NSString *trimmed = [server stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (![trimmed hasPrefix:@"https://"] && ![trimmed hasPrefix:@"http://"]) {
        // Make sure URL has URI scheme component
        trimmed = [@"http://" stringByAppendingString:trimmed];
    }
    [defaults setObject:trimmed forKey:@"QueryServer"];
    
    [defaults synchronize];
}

#pragma mark - Button actions

- (IBAction)useLocationToggled:(id)sender {
    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([sender isOn]) {
        if ([self canUseLocation] == NO) {
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

- (IBAction)privacyModeToggled:(id)sender {
    if ([sender isOn]) {
        [self showPrivacyModeAlert:^(void) {
            [self.useLocationSwitch setOn:NO];
            [self useLocationToggled:nil];
            [self saveToDefaults];
        }];
    } else {
        [self saveToDefaults];
    }
    
}

- (IBAction)serverPresetSelected:(id)sender {
    NSString *url = @"https://greynir.is";
    switch ([sender selectedSegmentIndex]) {
        case 1:
            url = @"http://46.4.45.9:5000";
            break;
        case 2:
            url = @"http://192.168.1.45:5000";
            break;
    }
    [self.queryServerTextField setText:url];
}

- (IBAction)restoreDefaults:(id)sender {
    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSDictionary *def = [del startingDefaults];
    for (NSString *key in def) {
        [[NSUserDefaults standardUserDefaults] setObject:def[key] forKey:key];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.serverSegmentedControl setSelectedSegmentIndex:0];
    [self configureControlsFromDefaults];
}

- (IBAction)clearHistoryPressed:(id)sender {
    [self showClearHistoryAlert];
}

- (void)clearHistory {
    // This is a UUID that may be used to uniquely identify the
    // device, and is the same across apps from a single vendor.
    NSString *uniqueID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    // Configure session
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

    NSDictionary *parameters = @{   @"action": @"clear",
                                    @"unique_id": uniqueID,
                                    @"client_type": @"ios",
                                    @"client_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]
                                };
    
    // Create request
    NSError *err = nil;
    NSString *server = [[NSUserDefaults standardUserDefaults] objectForKey:@"QueryServer"];
    NSString *remoteURLStr = [NSString stringWithFormat:@"%@%@", server, CLEAR_QHISTORY_API_PATH];
    NSURLRequest *req = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET"
                                                                      URLString:remoteURLStr
                                                                     parameters:parameters
                                                                          error:&err];
    if (req == nil) {
        DLog(@"%@", [err localizedDescription]);
        return;
    }
    DLog(@"Sending request %@\n%@", [req description], [parameters description]);
    
    // Run task with request
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:req
                                                   uploadProgress:nil
                                                 downloadProgress:nil
                                                completionHandler:^(NSURLResponse * response, id responseObject, NSError *err) {
                                                    if (err == nil) {
                                                        NSString *msg = @"Öllum fyrirspurnum frá þessu tæki hefur nú verið eytt.";
                                                        [self showAlert:@"Fyrirspurnasögu eytt" message:msg];
                                                    } else {
                                                        NSString *msg = @"Ekki tókst að eyða fyrirspurnum.";
                                                        [self showAlert:@"Villa kom upp" message:msg];
                                                        DLog(@"Error deleting query history: %@", [err localizedDescription]);
                                                    }
                                                }];
    [dataTask resume];
}

#pragma mark - Alerts

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

#pragma mark - Text field delegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.queryServerTextField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self saveToDefaults];
}

@end
