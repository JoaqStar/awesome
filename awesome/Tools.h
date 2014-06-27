//
//  Tools.h
//  awesome
//
//  Created by Joaquin Brown on 12/3/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
@interface Tools : NSObject

+ (UIColor *)getBackgroundColor;
+ (UIColor *)getAwesomeBlueColor;
+ (NSString *)getDistanceString:(CLLocationDistance)distance isMeters:(BOOL)isMeters;
+ (NSString *)getStringSinceDate:(NSDate *)startDate;
+ (NSString *)getStringSinceStringDate:(NSString *)stringDate;

@end
