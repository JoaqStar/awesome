//
//  Awesome.h
//  awesome
//
//  Created by Joaquin Brown on 12/13/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Awesome : NSManagedObject

@property (nonatomic, retain) NSDate * awesomeDate;
@property (nonatomic, retain) NSString * myUserId;
@property (nonatomic, retain) NSString * theirUserId;
@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSString * rangeKey;

@end
