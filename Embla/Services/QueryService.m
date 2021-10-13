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

/*
    Singleton wrapper class for sending requests to the query API.
*/

#import "QueryService.h"
#import "Common.h"
#import "Keys.h"
#import "AFURLSessionManager.h"
#import "AFURLRequestSerialization.h"
#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>

// Number of seconds before a query server request should time out
#define QUERY_SERVICE_REQ_TIMEOUT   15.0f

@implementation QueryService

+ (instancetype)sharedInstance {
    static QueryService *instance = nil;
    if (!instance) {
        instance = [self new];
    }
    return instance;
}

#pragma mark - Util

- (NSString *)_queryAPIEndpoint {
    NSString *server = [DEFAULTS stringForKey:@"QueryServer"];
    if ([server length] == 0 || [server hasPrefix:@"http"] == NO) {
        server = DEFAULT_QUERY_SERVER;
    }
    return [NSString stringWithFormat:@"%@%@", server, QUERY_API_PATH];
}

- (NSString *)_speechAPIEndpoint {
    NSString *server = [DEFAULTS stringForKey:@"QueryServer"];
    if ([server length] == 0 || [server hasPrefix:@"http"] == NO) {
        server = DEFAULT_QUERY_SERVER;
    }
    return [NSString stringWithFormat:@"%@%@", server, SPEECH_API_PATH];
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

#pragma mark - Query

- (void)sendQuery:(id)query withCompletionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler {
    BOOL isString = [query isKindOfClass:[NSString class]];
    NSAssert(isString || [query isKindOfClass:[NSArray class]], @"Query argument passed to sendQuery must be string or array.");
    
    // Query argument is a |-separated list
    NSArray *alternatives = isString ? @[query] : query;
    NSString *qstr = [alternatives componentsJoinedByString:@"|"];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [configuration setTimeoutIntervalForRequest:QUERY_SERVICE_REQ_TIMEOUT];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSString *apiEndpoint = [self _queryAPIEndpoint];
    
    // Query key/value pairs
    NSString *voiceName = [DEFAULTS stringForKey:@"VoiceID"];
    NSString *voiceSpeed = [NSString stringWithFormat:@"%.2f", [DEFAULTS floatForKey:@"SpeechSpeed"]];
    NSMutableDictionary *parameters = [@{
        @"q": qstr,
        @"voice": @(YES),
        @"voice_id": voiceName,
        @"voice_speed": voiceSpeed
    } mutableCopy];
    
    BOOL privacyMode = [DEFAULTS boolForKey:@"PrivacyMode"];
    BOOL useLocation = [DEFAULTS boolForKey:@"UseLocation"];
    
    // Add location info, if enabled and available
    if (useLocation && !privacyMode) {
        NSDictionary *loc = [self _location];
        if (loc) {
            [parameters addEntriesFromDictionary:loc];
        } else {
            DLog(@"User location not available");
        }
    }
    
    if (privacyMode) {
        // User has set the client to private mode. Notify server that
        // queries should not be logged.
        parameters[@"private"] = @"1";
    } else {
        // Send unique device ID
        // This is a UUID that may be used to uniquely identify the
        // device, and is the same across apps from a single vendor.
        parameters[@"client_id"] = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        
        // Client type and version
        parameters[@"client_type"] = CLIENT_TYPE;
        parameters[@"client_version"] = CLIENT_VERSION;
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

#pragma mark - Speech synthesis

- (void)requestSpeechSynthesis:(NSString *)str
         withCompletionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [configuration setTimeoutIntervalForRequest:QUERY_SERVICE_REQ_TIMEOUT];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    // API key for query server
    NSData *d = [NSData dataWithBytes:sak length:strlen(sak)];
    NSData *d2 = [[NSData alloc] initWithBase64EncodedData:d options:0];
    NSString *apiKey = [[NSString alloc] initWithData:d2 encoding:NSASCIIStringEncoding];
    if (!apiKey) {
        apiKey = @"";
    }
    
    NSString *voiceName = [DEFAULTS stringForKey:@"VoiceID"];
    
    NSDictionary *parameters = @{
        @"text": str,
        @"api_key": apiKey,
        @"voice_id": voiceName,
        @"format": @"text" // No SSML for now...
    };
    
    // Create request
    NSError *err = nil;
    NSURLRequest *req = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET"
                                                                      URLString:[self _speechAPIEndpoint]
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

#pragma mark - Clear user data & history

// Send HTTP request to query server asking for the deletion of the device's query
// history and (optionally) any other user data (allData boolean flag)
- (void)clearUserData:(BOOL)allData completionHandler:(id)completionHandler {
    // This is a UUID that may be used to uniquely identify the
    // device, and is the same across apps from a single vendor.
    NSString *uniqueID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    
    // API key for query server
    NSData *d = [NSData dataWithBytes:sak length:strlen(sak)];
    NSData *d2 = [[NSData alloc] initWithBase64EncodedData:d options:0];
    NSString *apiKey = [[NSString alloc] initWithData:d2 encoding:NSASCIIStringEncoding];
    if (!apiKey) {
        apiKey = @"";
    }
    
    // Configure session
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [configuration setTimeoutIntervalForRequest:QUERY_SERVICE_REQ_TIMEOUT];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSString *action = allData ? @"clear_all" : @"clear";
    NSDictionary *parameters = @{   @"action": action,
                                    @"client_id": uniqueID,
                                    @"client_type": @"ios",
                                    @"client_version": version,
                                    @"api_key": apiKey
                                };
    
    // Create request
    NSError *err = nil;
    NSString *server = [DEFAULTS objectForKey:@"QueryServer"];
    NSString *remoteURLStr = [NSString stringWithFormat:@"%@%@", server, CLEAR_QHISTORY_API_PATH];
    NSURLRequest *req = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST"
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
                                                completionHandler:completionHandler];
    [dataTask resume];
}

@end
