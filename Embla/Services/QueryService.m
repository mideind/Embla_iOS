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

/*
    Wrapper singleton class for sending requests to the query API.
*/

#import "QueryService.h"
#import "Common.h"
#import "AFNetworking.h"
#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>

#define REQ_TIMEOUT 15.0f

@implementation QueryService

+ (instancetype)sharedInstance {
    static QueryService *instance = nil;
    if (!instance) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (NSString *)_APIEndpoint {
    NSString *server = [[NSUserDefaults standardUserDefaults] stringForKey:@"QueryServer"];
    return [NSString stringWithFormat:@"%@%@", server, QUERY_API_PATH];
}

- (void)sendQuery:(id)query withCompletionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler {
    BOOL isString = [query isKindOfClass:[NSString class]];
    BOOL isArray = [query isKindOfClass:[NSArray class]];
    NSAssert(isString || isArray, @"Query argument passed to sendQuery must be string or array.");
    
    // Query argument is a |-separated list
    NSArray *alternatives = isString ? @[query] : query;
    NSString *qstr = [alternatives componentsJoinedByString:@"|"];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [configuration setTimeoutIntervalForRequest:REQ_TIMEOUT];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSString *apiEndpoint = [self _APIEndpoint];
    
    // Query key/value pairs
    NSString *voiceName = [[NSUserDefaults standardUserDefaults] integerForKey:@"Voice"] == 0 ? @"Dora" : @"Karl";
    NSMutableDictionary *parameters = [@{
        @"q": qstr,
        @"voice": @(YES),
        @"voice_id": voiceName,
    } mutableCopy];
    
    BOOL privacyMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"PrivacyMode"];
    BOOL useLocation = [[NSUserDefaults standardUserDefaults] boolForKey:@"UseLocation"];
    
    // Add location info, if enabled and available
    if (useLocation && !privacyMode) {
        NSDictionary *loc = [self _location];
        if (loc) {
            [parameters addEntriesFromDictionary:loc];
        }
    }
    
    if (privacyMode) {
        // User has set the client to private mode. Notify server that
        // queries should not be logged.
        [parameters setObject:@"1" forKey:@"private"];
    } else {
        // Send unique device ID
        // This is a UUID that may be used to uniquely identify the
        // device, and is the same across apps from a single vendor.
        NSString *uniqueID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        [parameters setObject:uniqueID forKey:@"client_id"];
        
        // Client type and version
        [parameters setObject:@"ios" forKey:@"client_type"];
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        [parameters setObject:version forKey:@"client_version"];
    }
    
    // Create request
    NSError *err = nil;
    NSURLRequest *req = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET"
                                                                      URLString:apiEndpoint
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
                                                completionHandler:completionHandler];
    [dataTask resume];
}

- (NSDictionary *)_location {
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
