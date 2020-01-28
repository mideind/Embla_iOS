/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2019-2020 Miðeind ehf.
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
    View controller superclass to load a web page into a web view
*/

#import "WebViewController.h"
#import "Common.h"

@interface WebViewController ()

@property (nonatomic, weak) IBOutlet WKWebView *webView;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    
    [self.webView setNavigationDelegate:self];
    
    DLog(@"Requesting URL %@", self.url);
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    [self.webView loadRequest:req];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self handleFailure];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    [self handleFailure];
}

// Load local file if web view fails to load remote URL
- (void)handleFailure {
    DLog(@"%@ failed to load remote URL %@", NSStringFromClass([self class]), self.url);
    if (!self.fallbackFilename) {
        DLog(@"No local file fallback");
        return; // No fallback
    }
    NSURL *url = [[NSBundle mainBundle] URLForResource:self.fallbackFilename
                                         withExtension:nil
                                          subdirectory:nil];
    DLog(@"Using local fallback %@", url);
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

// Open clicked links in external web browser
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))handler {
    
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        handler(WKNavigationActionPolicyCancel);
        UIApplication *app = [UIApplication sharedApplication];
        [app openURL:navigationAction.request.URL options:@{} completionHandler:nil];
        return;
    }
    handler(WKNavigationActionPolicyAllow);
}

@end
