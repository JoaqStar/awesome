//
//  Tools.m
//  awesome
//
//  Created by Joaquin Brown on 12/3/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import "Tools.h"

@implementation Tools

+(UIColor *)getBackgroundColor
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour fromDate:[NSDate date]];
    long hour = [components hour];
    if (hour > 20 || hour < 6) {
        return [UIColor whiteColor];
    } else {
        return [UIColor whiteColor];
    }
}

+ (UIColor *)getAwesomeBlueColor
{
    return  [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
}

+ (NSString *)getDistanceString:(CLLocationDistance)distance isMeters:(BOOL)isMeters {
    NSString *distanceString;
    // Get regional settings
    NSLocale *locale = [NSLocale currentLocale];
    BOOL localeUsesMetric = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
    
    if (localeUsesMetric) {
        if (distance >= 1000)
            distanceString = [NSString stringWithFormat:@"(%.0f kilometers away}", distance/1000];
        else
            if (distance < 10) {
                distanceString = [NSString stringWithFormat:@"(less than 10 meters)"];
            } else {
                distanceString = [NSString stringWithFormat:@"(%.0f meters away)", distance];
            }
        
    }
    else {
        CLLocationDistance distanceInFeet = distance * 3.28084;
        if (distanceInFeet >= 500)
            distanceString = [NSString stringWithFormat:@"(%.1f miles away)", distanceInFeet * 0.000189394];
        else
            if (distance < 30) {
                distanceString = [NSString stringWithFormat:@"(less than 30 feet)"];
            } else {
                distanceString = [NSString stringWithFormat:@"(%.0f feet away)", distanceInFeet];
            }
    }
    
    return distanceString;
}

+ (NSString *)getStringSinceDate:(NSDate *)startDate {
    if (startDate == nil) {
        return nil;
    }
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    
    unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit;
    
    NSDate *toDate = [NSDate date];
    NSDateComponents *dateComponents = [theCalendar components:unitFlags fromDate:startDate toDate:toDate  options:0];
    
    NSString *durationString;
    
    int dateComponent = 0;
    NSString *unitString;
    
    if ([dateComponents year] > 0)
    {
        dateComponent = (int)[dateComponents year];
        if (dateComponent > 1)
            unitString = @"years ago";
        else
            unitString = @"year ago";
    }
    else if ([dateComponents month] > 0)
    {
        dateComponent = (int)[dateComponents month];
        if (dateComponent > 1)
            unitString = @"months ago";
        else
            unitString = @"month ago";
    }
    else if ([dateComponents day] > 0)
    {
        dateComponent = (int)[dateComponents day];
        if (dateComponent > 1)
            unitString = @"days ago";
        else
            unitString = @"day ago";
    }
    else if ([dateComponents hour] > 0)
    {
        dateComponent = (int)[dateComponents hour];
        if (dateComponent > 1)
            unitString = @"hours ago";
        else
            unitString = @"hour ago";
    }
    else if ([dateComponents minute] > 0)
    {
        dateComponent = (int)[dateComponents minute];
        if (dateComponent > 1)
            unitString = @"minutes ago";
        else
            unitString = @"minute ago";
    } else {
        unitString = @"just now";
    }
    
    if ([unitString isEqualToString:@"just now"]) {
        durationString = unitString;
    } else {
        durationString = [NSString stringWithFormat:@"%d %@", dateComponent, unitString];
    }
    
    return durationString;
}

+ (NSString *)getStringSinceStringDate:(NSString *)stringDate {
    
    // Convert string to date object
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateFormatter setTimeZone:gmt];
    NSDate *startDate = [dateFormatter dateFromString:stringDate];
    
    return [self getStringSinceDate:startDate];
}


@end
