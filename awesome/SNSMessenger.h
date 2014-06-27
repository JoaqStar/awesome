//
//  SNSMessenger.h
//  awesome
//
//  Created by Joaquin Brown on 1/6/14.
//  Copyright (c) 2014 Joaquin Brown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SNSMessenger : NSObject

+ (id)sharedManager;

- (BOOL) sendNotificationToEndpoint:(NSString *)endpointARN withComment:(NSString *)comment;
- (NSString *) createEndpointARNFromToken:(NSString *)token forUser:(NSString *)userId;

@end
