//
//  BTBroadcast.h
//  awesome
//
//  Created by Joaquin Brown on 11/27/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BTBroadcast : NSObject

+ (id)sharedManager;
- (BOOL) startBeaming:(NSString *)userId;
- (BOOL) stopBeaming;

@end
