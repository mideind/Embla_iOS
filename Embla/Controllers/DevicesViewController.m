//
//  DevicesViewController.m
//  Embla
//
//  Created by Sveinbjorn Thordarson on 23.4.2021.
//  Copyright © 2021 Google. All rights reserved.
//

#import "DevicesViewController.h"

@interface DevicesViewController ()
@property (nonatomic) CBCentralManager *cbManager;
@end

@implementation DevicesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self checkBluetoothAccess];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    OZMenuTableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"OZLanguagePickerCell"];
//    if (cell == nil) {
//        cell = [[OZMenuTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"OZLanguagePickerCell"];
//        cell.textLabel.textAlignment = NSTextAlignmentCenter;
//    }
//
//    NSString *locale = [_locales objectAtIndex:indexPath.row];
//    cell.textLabel.text = [OZLocalizedStringStore languageNameForLocale:locale];
    
    return nil;
}

- (void)checkBluetoothAccess {

     if(!self.cbManager) {
          self.cbManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
     }
    [self logCBState];
}

- (void)logCBState {
    CBCentralManagerState state = [self.cbManager state];
    
   if(state == CBCentralManagerStateUnknown) {
       NSLog(@"UNKNOWN");
   }
   else if(state == CBCentralManagerStateUnauthorized) {
       NSLog(@"DENIED");
   }
   else {
       NSLog(@"GRANTED");
   }

}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    CBCentralManagerState state = [self.cbManager state];
    [self logCBState];
    
    [self.cbManager scanForPeripheralsWithServices:nil options:nil];

}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    //NSLog(@"%@", advertisementData);
    NSLog(@"%@", [peripheral name]);
    NSLog(@"%@", [peripheral services]);
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

@end
