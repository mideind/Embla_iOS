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

#import "AppDelegate.h"
#import "Common.h"

@interface AppDelegate ()
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation AppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self registerDefaults];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseLocation"]) {
        [self startLocationServices];
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

#pragma mark - Defaults

- (NSDictionary *)startingDefaults {
    // Default settings for app
    return @{
        @"UseLocation": @(YES),
        @"Voice": [NSNumber numberWithInteger:0],
        @"QueryServer": DEFAULT_QUERY_SERVER
    };
}

- (void)registerDefaults {
    [[NSUserDefaults standardUserDefaults] registerDefaults:[self startingDefaults]];
}

#pragma mark - Location services

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
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseLocation"] == NO) {
        return;
    }
    
    if ([locations count]) {
        self.latestLocation = [locations lastObject];
//        DLog(@"Location: %@", [self.latestLocation description]);
    }
}

#pragma mark - Unique device ID

- (NSString *)deviceID {
    // This returns a UUID that may be used to uniquely identify the
    // device, and is the same across apps from a single vendor.
    NSUUID *oNSUUID = [[UIDevice currentDevice] identifierForVendor];
    return [oNSUUID UUIDString];
}

@end
