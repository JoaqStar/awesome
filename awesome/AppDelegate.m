//
//  AppDelegate.m
//  awesome
//
//  Created by Joaquin Brown on 11/22/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import "AppDelegate.h"
#import "DataManager.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    
    [FBProfilePictureView class];
    
    self.applicationIsActive = YES;
    
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    
    if (userInfo) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateAwesomes" object:nil];
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    // attempt to extract a token from the url
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                    fallbackHandler:^(FBAppCall *call) {
                        NSLog(@"In fallback handler");
                    }];
}

/*
 * Callback for session changes.
 */
- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen:
            if (!error) {
                // We have a valid session
                NSLog(@"User session found");
            }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

/*
 * Opens a Facebook session and optionally shows the login UX.
 */
- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI withCompletion:(void (^)(FBSession *session, NSError *error))callback  {
    NSArray *permissions = [NSArray arrayWithObjects:@"basic_info", nil];
    return [FBSession openActiveSessionWithReadPermissions:permissions
                                       allowLoginUI:YES
                                  completionHandler:^(FBSession *session,
                                                      FBSessionState state,
                                                      NSError *error) {
                                      if (!error) {
                                          [self sessionStateChanged:session
                                                              state:state
                                                              error:error];
                                          
                                      }
                                      if (callback != nil) {
                                          callback(session, error);
                                      }
                                  }];
}



- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [FBSession.activeSession handleOpenURL:url];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    self.applicationIsActive = NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    self.applicationIsActive = YES;
    
    [FBAppEvents activateApp];
    
    [FBAppCall handleDidBecomeActiveWithSession:self.session];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateAwesomes" object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.session close];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    self.deviceToken = token;
    
    NSLog(@"content---%@", token);
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Could not register toke because of error: %@",error);
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    application.applicationIconBadgeNumber = 1;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateAwesomes" object:nil];
    
    if (self.applicationIsActive) {
        NSString *alertMessage = userInfo[@"aps"][@"alert"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Awesome." message:alertMessage delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:
                                  nil];
        [alertView show];
    }
}

@end
