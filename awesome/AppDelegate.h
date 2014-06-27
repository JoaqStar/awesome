//
//  AppDelegate.h
//  awesome
//
//  Created by Joaquin Brown on 11/22/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) FBSession *session;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSString *deviceToken;
@property (assign) BOOL applicationIsActive;

- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI withCompletion:(void (^)(FBSession *session, NSError *error))callback;

@end
