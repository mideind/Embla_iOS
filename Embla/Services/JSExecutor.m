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

#import "JSExecutor.h"
#import <WebKit/WebKit.h>
#import "Common.h"

#define PAYLOAD @"var REMOTE_SERVER_ADDR = \"%@\"; %@"

@interface JSExecutor()
{
    WKWebView *webView;
}
@end

@implementation JSExecutor

+ (instancetype)sharedInstance {
    static JSExecutor *instance = nil;
    if (!instance) {
        instance = [self new];
    }
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.websiteDataStore = [WKWebsiteDataStore defaultDataStore];
        webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) configuration:config];
    }
    return self;
}

#pragma mark -

// NB: This code runs asynchronously, so repeated serial invocations of this
// method will result in shared JS namespace.
// TODO: Perhaps better to initialise a new web view for each call
- (void)run:(NSString *)jsCode completionHandler:(void (^)(id, NSError *))completionHandler {
    NSString *payload = [NSString stringWithFormat:PAYLOAD, [DEFAULTS stringForKey:@"QueryServer"], jsCode];
    
    if (@available(iOS 14.0, *)) {
        
        // Async JS - only supported in iOS 14 or later
        [webView callAsyncJavaScript:payload arguments:nil inFrame:nil inContentWorld:[WKContentWorld defaultClientWorld] completionHandler:^(id res, NSError *err) {
            completionHandler(res, err);
            //[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        }];
        
    } else {
        
        // Sync JS on iOS < 14
        [webView evaluateJavaScript:payload completionHandler:^(id res, NSError *err) {
            completionHandler(res, err);
            //[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        }];
    }
}

@end
