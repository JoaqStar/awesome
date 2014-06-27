//
//  Location.h
//  awesome
//
//  Created by Joaquin Brown on 12/30/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Location : NSManagedObject

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * locationKey;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSDate * stopDate;
@property (nonatomic, retain) NSString * userId;

@end
