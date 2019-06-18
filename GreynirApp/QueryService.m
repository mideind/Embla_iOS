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

// Greynir API endpoint
#define GREYNIR_API_ENDPOINT @"https://greynir.is/query.api/v1"

@implementation QueryService

+ (instancetype)sharedInstance {
    static QueryService *instance = nil;
    if (!instance) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (void)sendQuery:(NSString *)query withCompletionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSString *apiEndpoint = GREYNIR_API_ENDPOINT;
    
    // Query key/value pairs
    NSMutableDictionary *parameters = [@{
        @"q" : query,
        @"voice": @(YES)
    } mutableCopy];
    
    // Add location info, if available
    NSDictionary *loc = [self location];
    if (loc) {
        [parameters addEntriesFromDictionary:loc];
    }
    
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
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:req completionHandler:completionHandler];
#pragma GCC diagnostic pop

    [dataTask resume];
}

- (NSDictionary *)location {
    AppDelegate *appDel = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CLLocation *currentLoc = [appDel latestLocation];
    if (currentLoc) {
        CLLocationCoordinate2D coords = currentLoc.coordinate;
        return @{
            @"location": @{
                @"latitude": @(coords.latitude),
                @"longitude": @(coords.longitude)
            }
        };
    }
    
    return nil;
}

@end
