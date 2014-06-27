//
//  BTBroadcast.m
//  awesome
//
//  Created by Joaquin Brown on 11/27/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import "BTBroadcast.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface BTBroadcast () <CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic) NSDictionary              *advertisementData;

@end

@implementation BTBroadcast

+ (id)sharedManager {
    static BTBroadcast *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
    }
    return self;
}

- (BOOL) startBeaming:(NSString *)userId {
    
    BOOL isBeaming = YES;
    
    if (self.peripheralManager == nil) {
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    }
    
    if (self.advertisementData == nil) {
        //self.advertisementData = [[NSDictionary alloc] initWithObjectsAndKeys:userId, CBAdvertisementDataLocalNameKey,
        //                          @[[CBUUID UUIDWithString:@"AF034954-2B1C-FAD4-73FF-DDE1782289E9"]],CBAdvertisementDataServiceUUIDsKey,nil];
        self.advertisementData = [[NSDictionary alloc] initWithObjectsAndKeys:userId, CBAdvertisementDataLocalNameKey,nil];
    }
    NSLog(@"%@", self.advertisementData);
    
    [self.peripheralManager startAdvertising:self.advertisementData];
    
    return isBeaming;
}

- (BOOL) stopBeaming {
    [self.peripheralManager stopAdvertising];
    
    return YES;
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    // Opt out from any other state
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        // We got an error
        NSLog(@"State is %d", (int)peripheral.state);
    } else {
        // We're in CBPeripheralManagerStatePoweredOn state...
        NSLog(@"self.peripheralManager powered on.");
    }
}

@end
