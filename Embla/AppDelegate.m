/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2019-2023 Miðeind ehf.
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

#import "AppDelegate.h"
#import "Common.h"

#import <WebKit/WKWebsiteDataStore.h>

@interface AppDelegate ()
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation AppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initial defaults
    NSDictionary *startingDefaults = [self startingDefaults];
    [DEFAULTS registerDefaults:startingDefaults];
    
    // This hack is here for backward compatibility reasons.
    // In versions prior to 1.2, the selected voice in defaults was stored
    // as an integer (0 for female voice and 1 for male) under the key "Voice".
    // As of 1.2, it is stored as a string under the key "VoiceID"
    // This code ensures that the user's previously selected voice gender
    // choice is preserved when he updates the client.
    if ([DEFAULTS objectForKey:@"Voice"] != nil) {
        NSInteger voiceIdx = [DEFAULTS integerForKey:@"Voice"];
        [DEFAULTS removeObjectForKey:@"Voice"];
        NSString *v = (voiceIdx == 0) ? DEFAULT_VOICE_ID : NEW_MALE_VOICE_ID;
        [DEFAULTS setObject:v forKey:@"VoiceID"];
    }
    
    // This hack is also here for backward compatibility reasons.
    // As of 1.3.2 we have a new default voice (Guðrún). Users are
    // automatically migrated to the new voice.
    NSString *vID = [DEFAULTS stringForKey:@"VoiceID"];
    if ([vID isEqualToString:OLD_DEFAULT_VOICE_ID_1] || [vID isEqualToString:OLD_DEFAULT_VOICE_ID_2] ) {
        [DEFAULTS setObject:DEFAULT_VOICE_ID forKey:@"VoiceID"];
    }
    else if ([vID isEqualToString:OLD_MALE_VOICE_ID]) {
        // Migrate those with old male voice to the new one (Gunnar)
        [DEFAULTS setObject:NEW_MALE_VOICE_ID forKey:@"VoiceID"];
    }
    
#ifdef DEBUG
    // Dump app-specific defaults to standard output
    NSArray *defaultKeys = [startingDefaults allKeys];
    NSMutableDictionary *finalDefaults = [[DEFAULTS dictionaryRepresentation] mutableCopy];
    for (NSString *k in [finalDefaults allKeys]) {
        if ([defaultKeys containsObject:k] == NO) {
            [finalDefaults removeObjectForKey:k];
        }
    }
    DLog(@"Current application defaults:\n%@", [finalDefaults description]);
#endif
    
#ifdef DEBUG
    // Clear web cache every time app is relaunched when in debug mode
    // Makes it easier to test changes to remote HTML documents
    [self clearWebCache];
#endif
    
    // Manually create window and load storyboard
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    [DEFAULTS setBool:NO forKey:@"InitialLaunch"];
    
    // Onboarding stuff disabled for now
//    if ([DEFAULTS boolForKey:@"InitialLaunch"]) {
//        // Present onboarding view controller
//        [self showOnboarding];
//        [DEFAULTS setBool:NO forKey:@"InitialLaunch"];
//    } else {
        // Present main storyboard
        [self showMainStoryboard];
//    }
    
    // Show window
    [self.window makeKeyAndVisible];
    
    // Enable location tracking
    if ([DEFAULTS boolForKey:@"UseLocation"]) {
        [self startLocationServices];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    DLog(@"Application will resign active");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    DLog(@"Application did enter background");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    DLog(@"Application did enter foreground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    DLog(@"Application did become active");
}

- (void)applicationWillTerminate:(UIApplication *)application {
    DLog(@"Application will terminate");
}

#pragma mark - Web cache

- (void)clearWebCache {
    NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes
                                               modifiedSince:dateFrom
                                           completionHandler:^{
        DLog(@"Cleared web cache");
    }];
}

#pragma mark - Onboarding

- (void)showMainStoryboard {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"Main"];
    self.window.rootViewController = viewController;
}

//- (void)showOnboarding {
////    self.window.rootViewController = onboardingVC;
//}

#pragma mark - Defaults

- (NSDictionary *)startingDefaults {
    // Default settings for app
    return @{
        @"InitialLaunch": @(YES),
        @"VoiceActivation": @(YES),
        @"UseLocation": @(YES),
        @"PrivacyMode": @(NO),
        @"VoiceID": DEFAULT_VOICE_ID,
        @"SpeechSpeed": [NSNumber numberWithFloat:1.0f],
        @"QueryServer": DEFAULT_QUERY_SERVER,
        @"Speech2TextServer": DEFAULT_SPEECH2TEXT_SERVER,
        @"HotwordDetector": DEFAULT_HOTWORD_DETECTOR,
        @"HotwordModel": DEFAULT_HOTWORD_MODEL
    };
}

#pragma mark - Location Services

- (void)startLocationServices {
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest]; // kCLLocationAccuracyBestForNavigation
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager setDelegate:self];
    [self.locationManager startUpdatingLocation];
}

- (void)stopLocationServices {
    [self.locationManager stopUpdatingLocation];
    self.locationManager = nil;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    // Ignore location update if disabled in defaults
    if ([DEFAULTS boolForKey:@"UseLocation"] == NO) {
        return;
    }
    
    if ([locations count]) {
        self.latestLocation = [locations lastObject];
        // DLog(@"Location received: %@", [self.latestLocation description]);
    }
}

@end
