/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2019-2020 Miðeind ehf.
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
    
    // Clear web cache every time app is relaunched.
    // Makes it easier to test changes to HTML documents and results
    // in a faster rollout to end users at the cost of bandwidth.
    [self clearWebCache];
    
    // Location tracking
    if ([DEFAULTS boolForKey:@"UseLocation"]) {
        [self startLocationServices];
    }
    
    //[self showOnboarding];
    
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
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{}];
}

#pragma mark - Onboarding

- (void)showOnboarding {
    UINavigationController *rootController = (UINavigationController *)self.window.rootViewController;
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Onboarding" bundle:nil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"start"];
    [rootController pushViewController:vc animated:YES];
}

#pragma mark - Defaults

- (NSDictionary *)startingDefaults {
    // Default settings for app
    return @{
        @"VoiceActivation": @(YES),
        @"UseLocation": @(YES),
        @"PrivacyMode": @(NO),
        @"Voice": [NSNumber numberWithInteger:0],
        @"SpeechSpeed": [NSNumber numberWithFloat:1.0f],
        @"QueryServer": DEFAULT_QUERY_SERVER
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
