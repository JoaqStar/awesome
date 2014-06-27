//
//  BTScan.h
//  awesome
//
//  Created by Joaquin Brown on 11/27/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BTScanDelegate <NSObject>
- (void)didUpdateListOfBTDevices:(NSArray *)nearbyUsers;
@end

@interface BTScan : NSObject

@property(nonatomic, unsafe_unretained)id<BTScanDelegate>     delegate;
-(void) scanAllTags;

@end
