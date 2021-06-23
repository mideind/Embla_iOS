//
//  HotwordModelViewController.m
//  Embla
//
//  Created by Sveinbjorn Thordarson on 15.6.2021.
//  Copyright © 2021 Google. All rights reserved.
//

#import "HotwordModelViewController.h"
#import "AFURLSessionManager.h"
#import "Common.h"

@interface HotwordModelViewController ()

@end

@implementation HotwordModelViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return -5.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Model training

- (IBAction)trainModel {
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    //serializer.acceptableContentTypes = [NSSet setWithObject:@"binary/octet-stream"];
    
    NSError *err;
    NSString *urlString = [NSString stringWithFormat:@"%@%@", DEFAULT_HOTWORD_SERVER, HOTWORD_TRAINING_API_PATH];
    NSMutableURLRequest *req = [serializer multipartFormRequestWithMethod:@"POST" URLString:urlString
                                                               parameters:@{ @"text": @YES }
                                                constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        NSString *w1path = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"wav"];
        NSString *w2path = [[NSBundle mainBundle] pathForResource:@"2" ofType:@"wav"];
        NSString *w3path = [[NSBundle mainBundle] pathForResource:@"3" ofType:@"wav"];
        
        NSData *data1 = [NSData dataWithContentsOfFile:w1path];
        NSData *data2 = [NSData dataWithContentsOfFile:w2path];
        NSData *data3 = [NSData dataWithContentsOfFile:w3path];
        
        [formData appendPartWithFileData:data1 name:@"files" fileName:@"1.wav" mimeType:@"audio/wav"];
        [formData appendPartWithFileData:data2 name:@"files" fileName:@"2.wav" mimeType:@"audio/wav"];
        [formData appendPartWithFileData:data3 name:@"files" fileName:@"3.wav" mimeType:@"audio/wav"];

    } error:&err];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionUploadTask *uploadTask = [manager
    uploadTaskWithStreamedRequest:req
    progress: nil //^(NSProgress * _Nonnull uploadProgress) {}
    completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            DLog(@"Error: %@", error);
            DLog(@"%@ %@", response, responseObject);
            return;
        }
        
        DLog(@"%@ %@", response, responseObject);
        
        NSDictionary *resp = (NSDictionary *)responseObject;
        NSString *base64String = [resp objectForKey:@"data"];
        NSString *name = [resp objectForKey:@"name"];
        if (name == nil || base64String == nil) {
            DLog(@"Mangled response from hotword training server");
            return;
        }
        
        // Decode base64 data and write to directory
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
        NSString *filename = [NSString stringWithFormat:@"%@.pmdl", resp[@"name"]];
        DLog(@"Writing model %@", filename);
        [self writeFile:filename withData:decodedData];
        [DEFAULTS setObject:filename forKey:@"HotwordModelName"];
    }];
    
    [uploadTask resume];
}

- (void)writeFile:(NSString *)filename withData:(NSData *)data {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [NSString stringWithFormat:@"%@/%@", documentsDirectory, filename];
    [data writeToFile:path atomically:YES];
}


@end
