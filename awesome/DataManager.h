//
//  aDataManager.h
//  awesome
//
//  Created by Joaquin Brown on 10/22/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>
#import <CoreLocation/CoreLocation.h>
#import "UserInfo.h"
#import "Location.h"

typedef enum {
    Success = 0,
    CantAwesomeSelf,
    CantAwesomeAgain,
} AwesomeStatus;

@interface DataManager : NSObject

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) NSString *thisUserId;
@property (strong, nonatomic) NSString *thisUserName;

+ (id)sharedManager;

- (NSString *)addFacebookUser:(NSDictionary *)fbUser;
- (BOOL)updateUserWithToken:(NSString *)deviceToken;
- (Location *)setLocation:(CLLocationCoordinate2D)coordinates untilStopDate:(NSDate *)stopDate;
- (Location *) getLastLocation;
- (BOOL) deleteLastLocation;
- (NSArray *)getNearbyUserLocationsWDistance:(CLLocationCoordinate2D)coordinates;
- (NSArray *)getAllUsers;

-(NSString *)getEndpointARNForUserID:(NSString *)userId;

-(NSArray *)getMyAwesomes;

- (AwesomeStatus)awesomeUser:(NSString *)userId withComment:(NSString *)comment;

- (NSError *)saveContext;

@end
