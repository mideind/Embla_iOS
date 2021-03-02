/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2019-2021 Miðeind ehf.
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
    [DEFAULTS registerDefaults:[self startingDefaults]];
    
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

- (void)showOnboarding {
//    self.window.rootViewController = onboardingVC;
}

#pragma mark - Defaults

- (NSDictionary *)startingDefaults {
    // Default settings for app
    return @{
        @"InitialLaunch": @(YES),
        @"VoiceActivation": @(YES),
        @"UseLocation": @(YES),
        @"PrivacyMode": @(NO),
        @"Voice": [NSNumber numberWithInteger:0],
        @"SpeechSpeed": [NSNumber numberWithFloat:1.0f],
        @"QueryServer": DEFAULT_QUERY_SERVER,
        @"Speech2TextServer": DEFAULT_SPEECH2TEXT_SERVER
    };
}

#pragma mark - Location Services

- (void)startLocationServices {
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest]; // kCLLocationAccuracyBestForNavigation
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
    [self.locationManager setDelegate:self];
}

- (void)stopLocationServices {
    self.locationManager = nil;
}
    
- (BOOL)locationServicesAvailable {
    return [CLLocationManager locationServicesEnabled];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if ([DEFAULTS boolForKey:@"UseLocation"] == NO) {
        return;
    }
    
    if ([locations count]) {
        self.latestLocation = [locations lastObject];
        // DLog(@"Location received: %@", [self.latestLocation description]);
    }
}

@end
