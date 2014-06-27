//
//  UserInfo.h
//  awesome
//
//  Created by Joaquin Brown on 1/10/14.
//  Copyright (c) 2014 Joaquin Brown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface UserInfo : NSManagedObject

@property (nonatomic, retain) NSString * deviceToken;
@property (nonatomic, retain) NSString * endpointARN;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSDate * lastUseDate;
@property (nonatomic, retain) NSDate * createDate;

@end
