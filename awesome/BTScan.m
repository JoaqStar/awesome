//
//  BTScan.m
//  awesome
//
//  Created by Joaquin Brown on 11/27/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import "BTScan.h"
#import "BTBroadcast.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface BTScan () <CBCentralManagerDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) NSDictionary *mgrOptions;
@property (strong, nonatomic) NSMutableArray *nearbyUsers;

@end

@implementation BTScan

#pragma mark - Dealing with Tags
-(void) scanAllTags {
    
    if (self.nearbyUsers == nil) {
        self.nearbyUsers = [[NSMutableArray alloc] init];
    }
    // If manager is nil or state is not on, then reset manager
    if (self.centralManager == nil || [self.centralManager state] != CBCentralManagerStatePoweredOn) {
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
    //[self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"AF034954-2B1C-FAD4-73FF-DDE1782289E9"]] options:options];
    [self.centralManager scanForPeripheralsWithServices:nil options:options];
    // Set up timer to stop scan and call delegate with results
    [NSTimer scheduledTimerWithTimeInterval:2.1 target:self selector:@selector(sendResultsToDelegate) userInfo:nil repeats:NO];
}

- (void) sendResultsToDelegate {
    [self.centralManager stopScan];
    
    NSArray *nearbyUsers = self.nearbyUsers;
    if ( [self.delegate respondsToSelector:@selector(didUpdateListOfBTDevices:)]) {
        [self.delegate didUpdateListOfBTDevices:nearbyUsers];
    }
}

#pragma mark - CBManagerDelegate methods
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"Did update state %d", (int)central.state);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Did discover peripheral. peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ RSSI: %@", peripheral, RSSI, peripheral, advertisementData, RSSI);
    // Determine if this UUID is already in the array
    BOOL found = NO;
    
    for (NSString *userId in self.nearbyUsers) {
        if ([userId isEqualToString:[peripheral name]]) {
            found = YES;
            return;
        }
    }
    if (found == NO && [peripheral name] != nil) {
        [self.nearbyUsers addObject:[peripheral name]];
    }
}


@end
