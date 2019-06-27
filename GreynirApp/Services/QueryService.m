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

#import "QueryService.h"
#import "Config.h"
#import "AFNetworking.h"
#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>

@implementation QueryService

+ (instancetype)sharedInstance {
    static QueryService *instance = nil;
    if (!instance) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (NSString *)APIEndpoint {
    NSString *server = [[NSUserDefaults standardUserDefaults] stringForKey:@"QueryServer"];
    return [NSString stringWithFormat:@"%@%@", server, QUERY_API_PATH];
}

- (void)sendQuery:(NSString *)query withCompletionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSString *apiEndpoint = [self APIEndpoint];
    
    // Query key/value pairs
    NSString *voiceName = [[NSUserDefaults standardUserDefaults] integerForKey:@"Voice"] == 0 ? @"Dora" : @"Karl";
    NSMutableDictionary *parameters = [@{
        @"q" : query,
        @"voice": @(YES),
        @"voice_id": voiceName
    } mutableCopy];
    
    // Add location info, if enabled and available
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseLocation"]) {
        NSDictionary *loc = [self location];
        if (loc) {
            [parameters addEntriesFromDictionary:loc];
        }
    }
    
    // Create request
    NSError *err = nil;
    NSURLRequest *req = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET"
                                                                      URLString:apiEndpoint
                                                                     parameters:parameters
                                                                          error:nil];
    if (req == nil) {
        NSLog(@"%@", [err localizedDescription]);
        return;
    }
    DLog(@"Sending request %@", [req description]);
    
    // Silence deprecation warnings (Xcode mistakenly thinks this is a call to NSURLSession[!])
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    // Run task with request
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:req completionHandler:completionHandler];
    [dataTask resume];
#pragma GCC diagnostic pop
}

- (NSDictionary *)location {
    AppDelegate *appDel = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CLLocation *currentLoc = [appDel latestLocation];
    if (currentLoc) {
        CLLocationCoordinate2D coords = currentLoc.coordinate;
        return @{
            @"latitude": @(coords.latitude),
            @"longitude": @(coords.longitude)
        };
    }
    
    return nil;
}

@end
