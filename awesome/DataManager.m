//
//  aDataManager.m
//  awesome
//
//  Created by Joaquin Brown on 10/22/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import "DataManager.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "UserInfo.h"
#import "Location.h"
#import "LocationWDistance.h"
#import "Awesome.h"
#import "AWSPersistenceDynamoDBIncrementalStore.h"
#import <AWSRuntime/AWSRuntime.h>
#import "AmazonClientManager.h"
#import "SNSMessenger.h"

@interface DataManager ()

@property (nonatomic, strong) NSString *deviceToken;
@property (nonatomic, strong) NSMutableArray *localAwesomes;

@end

@implementation DataManager

#pragma mark Singleton Methods
+ (id)sharedManager {
    static DataManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        
        [AmazonErrorHandler shouldNotThrowExceptions];
        
        // call managed context just to set up context and to set up persistant store coordianator 
        [self managedObjectContext];
        
        [self getThisUser:nil];
        
        self.localAwesomes = [[NSUserDefaults standardUserDefaults] objectForKey:@"localAwesomes"];
        
        if (self.localAwesomes == nil) {
            self.localAwesomes = [[NSMutableArray alloc] init];
            [self saveLocalAwesomes];
        }
    }
    return self;
}

#pragma mark User Methods
- (BOOL)updateUserWithToken:(NSString *)deviceToken {

    UserInfo *user = [self getThisUser:nil];
    
    self.deviceToken = deviceToken;
    
    if (user != nil && [user.deviceToken isEqualToString:deviceToken] == NO && [self.deviceToken length] > 0) {
        NSLog(@"updating token to %@", self.deviceToken);
        user.deviceToken = self.deviceToken;
        [self saveContext];
    }
    
    return YES;
}
- (NSString *)addUser:(NSString *)userId
{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    UserInfo *user = [NSEntityDescription insertNewObjectForEntityForName:@"UserInfo" inManagedObjectContext:context];
    
    user.userId = userId;
    user.createDate = [NSDate date];
    [self setTokenAndEndpointARNForUser:user];
    
    self.thisUserId = user.userId;
    [self saveContext];
    return @"success";
}

- (NSString *)addFacebookUser:(NSDictionary *)fbUser
{
    UserInfo *user = [self getThisUser:fbUser[@"id"]];
    
    if (user == nil) {
        return [self addUser:fbUser[@"id"]];
    } else {
        return @"success";
    }
}

- (Location *)setLocation:(CLLocationCoordinate2D)coordinates untilStopDate:(NSDate *)stopDate {
    NSManagedObjectContext *context = [self managedObjectContext];
    
    Location *location;
    
    if (self.thisUserId != nil) {
        
        location = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:context];
        
        location.locationKey = [NSString stringWithFormat:@"%.02f,%.02f", coordinates.longitude, coordinates.latitude];
        location.longitude = [NSNumber numberWithDouble:coordinates.longitude];
        location.latitude = [NSNumber numberWithDouble:coordinates.latitude];
        location.stopDate = stopDate;
        location.userId = self.thisUserId;
    
        NSError *error = [self saveContext];
        
        if (error) {
            [self throwError:error];
            return nil;
        }
        
        // Save last Location in user defaults
        NSDictionary *lastLocation = @{@"locationKey" : location.locationKey,
                                       @"locationUserId" : location.userId};
        [[NSUserDefaults standardUserDefaults] setObject:lastLocation forKey:@"lastLocation"];
    }
    
    return location;
}

- (BOOL) deleteLastLocation
{
    BOOL success = YES;
    NSDictionary *lastLocation = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastLocation"];
    
    if (lastLocation != nil && [lastLocation[@"locationUserId"] isEqualToString:self.thisUserId])
    {
        Location *serverLocation = [self getLastLocation:lastLocation];
        
        if (serverLocation != nil) {
            [self delete:serverLocation];
            NSError *error = [self saveContext];
            if (error) {
                [self throwError:error];
                success = NO;
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastLocation"];
            }
        } else {
            success = NO;
        }
    }
    return success;
}

- (Location *) getLastLocation
{
    Location *location;
    NSDictionary *lastLocation = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastLocation"];
    
    if (lastLocation != nil && [lastLocation[@"locationUserId"] isEqualToString:self.thisUserId])
    {
        location = [self getLastLocation:lastLocation];
        
        NSDate *date1 = location.stopDate;
        NSDate *date2 = [NSDate date];
        
        NSTimeInterval secondsBetween = [date1 timeIntervalSinceDate:date2];
        
        if (secondsBetween <= 0) {
            [self deleteLastLocation];
            location = nil;
        }
    }
    
    return location;
}

- (Location *)getLastLocation:(NSDictionary *)lastLocation
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSArray *locations;
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"locationKey = %@ && userId = %@", lastLocation[@"locationKey"], lastLocation[@"locationUserId"]];
    [request setPredicate:predicate];
    
    NSError *error;
    locations = [context executeFetchRequest:request error:&error];
    
    if (error) {
        [self throwError:error];
        return nil;
    }
    
    if ([locations count] > 0) {
        return [locations lastObject];
    } else {
        return nil;
    }
}

-(NSDate *) dateRoundedDownTo5Minutes:(NSDate *)dt{
    int referenceTimeInterval = (int)[dt timeIntervalSinceReferenceDate];
    int remainingSeconds = referenceTimeInterval % 300;
    int timeRoundedTo5Minutes = referenceTimeInterval - remainingSeconds;
    NSDate *roundedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)timeRoundedTo5Minutes];
    return roundedDate;
}

- (NSArray *)getAllUsers {
    @synchronized([self class])
    {
        NSManagedObjectContext *context = [self managedObjectContext];
        
        NSEntityDescription *entity = [NSEntityDescription
                                       entityForName:@"UserInfo" inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entity];
        
        NSError *error;
        NSArray *users = [context executeFetchRequest:request error:&error];
        NSMutableArray *mutableUsers = [users mutableCopy];
        
        NSSortDescriptor *sortCreateDate = [NSSortDescriptor
                                          sortDescriptorWithKey:@"lastUseDate"
                                          ascending:YES];
        [mutableUsers sortUsingDescriptors:[NSArray arrayWithObject:sortCreateDate]];
        
        return mutableUsers;
    }
}

- (NSArray *)getNearbyUserLocationsWDistance:(CLLocationCoordinate2D)coordinates {
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSMutableArray *mutableLocations = [[NSMutableArray alloc] init];
    NSArray *locations;

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    NSError *error;
    
    // Convert longitude and latitude to 2 decimal precision
    CGFloat longitude = round(coordinates.longitude * 100) / 100;
    CGFloat latitude = round(coordinates.latitude * 100) / 100;
    
    // Get first group
    NSString *key = [NSString stringWithFormat:@"%.02f,%.02f", longitude, latitude];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"locationKey = %@", key];
    [request setPredicate:predicate];
    locations = [context executeFetchRequest:request error:&error];
    if (error) {
        [self throwError:error];
        return nil;
    }
    [mutableLocations addObjectsFromArray:locations];
    
    // Determine if we are plus or minus latitude
    NSInteger latitudeNorthSouth;
    if (coordinates.latitude < 0) {
        latitudeNorthSouth = -1;
    } else {
        latitudeNorthSouth = 1;
    }
    
    // If the lattitude is close to middle of being rounded (.xx5), then get other side of the round
    key = nil;
    NSInteger latitudePrecision = abs(coordinates.latitude*1000);
    latitudePrecision = latitudePrecision%10;
    if (latitudePrecision >= 3 && latitudePrecision < 5) {
        key = [NSString stringWithFormat:@"%.02f,%.02f", longitude, latitude+.01*latitudeNorthSouth];
    } else if (latitudePrecision < 6 && latitudePrecision >= 5) {
        key = [NSString stringWithFormat:@"%.02f,%.02f", longitude, latitude-.01*latitudeNorthSouth];
    }
    if (key != nil) {
        predicate = [NSPredicate predicateWithFormat:@"locationKey = %@", key];
        [request setPredicate:predicate];
        locations = [context executeFetchRequest:request error:&error];
        if (error) {
            [self throwError:error];
            return nil;
        }
        [mutableLocations addObjectsFromArray:locations];
    }
    
    // Determine if we are plus or minus latitude
    NSInteger longitudeEastWest;
    if (coordinates.longitude < 0) {
        longitudeEastWest = -1;
    } else {
        longitudeEastWest = 1;
    }
    // If the lattitude is close to middle of being rounded (.xx5), then get other side of the round
    key = nil;
    NSInteger longitudePrecision = abs(coordinates.longitude*1000);
    longitudePrecision = longitudePrecision%10;
    if (longitudePrecision >= 3 && longitudePrecision < 5) {
        key = [NSString stringWithFormat:@"%.02f,%.02f", longitude+.01*longitudeEastWest, latitude];
    } else if (longitudePrecision < 6 && longitudePrecision >= 5) {
        key = [NSString stringWithFormat:@"%.02f,%.02f", longitude-.01*longitudeEastWest, latitude];
    }
    if (key != nil) {
        predicate = [NSPredicate predicateWithFormat:@"locationKey = %@", key];
        [request setPredicate:predicate];
        locations = [context executeFetchRequest:request error:&error];
        if (error) {
            [self throwError:error];
            return nil;
        }
        [mutableLocations addObjectsFromArray:locations];
    }
    
    key = nil;
    if (latitudePrecision >= 3 && latitudePrecision < 5 && longitudePrecision > 3 && longitudePrecision < 5)
    {
        key = [NSString stringWithFormat:@"%.02f,%.02f", longitude+.01*longitudeEastWest, latitude+.01*latitudeNorthSouth];
    } else if (latitudePrecision < 6 && latitudePrecision >= 5 && longitudePrecision > 3 && longitudePrecision < 5)
    {
        key = [NSString stringWithFormat:@"%.02f,%.02f", longitude-.01*longitudeEastWest, latitude+.01*latitudeNorthSouth];
    } else if (latitudePrecision >= 3 && latitudePrecision < 5 && longitudePrecision < 6 && longitudePrecision >= 5)
    {
        key = [NSString stringWithFormat:@"%.02f,%.02f", longitude+.01*longitudeEastWest, latitude-.01*latitudeNorthSouth];
    } else if (latitudePrecision < 6 && latitudePrecision >= 5 && longitudePrecision < 6 && longitudePrecision >= 5)
    {
        key = [NSString stringWithFormat:@"%.02f,%.02f", longitude-.01*longitudeEastWest, latitude-.01*latitudeNorthSouth];
    }
    if (key != nil) {
        predicate = [NSPredicate predicateWithFormat:@"locationKey = %@", key];
        [request setPredicate:predicate];
        locations = [context executeFetchRequest:request error:&error];
        if (error) {
            [self throwError:error];
            return nil;
        }
        [mutableLocations addObjectsFromArray:locations];
    }
    
    if (error) {
        NSLog(@"Error was %@", error);
    } else {
        // Delete anything older than 5 minutes
        BOOL somethingDeleted = NO;
        for (Location *location in [mutableLocations copy]) {
            // If the following statement is true, then location.date is more than 5 minutes old
            if ([location.stopDate compare:[NSDate date]] == NSOrderedAscending)
            {
                somethingDeleted = YES;
                [mutableLocations removeObject:location];
                [self delete:location];
            }
        }
        if (somethingDeleted) {
            [self saveContext];
        }
    }
    
    // Now order locations based on nearness to user
    CLLocation *myLocation = [[CLLocation alloc] initWithLatitude:coordinates.latitude longitude:coordinates.longitude];
    NSMutableArray *mutableLocationWDistance = [[NSMutableArray alloc] init];
    for (Location *location in mutableLocations) {
        LocationWDistance *locationWDistance = [[LocationWDistance alloc] init];
        locationWDistance.userId = location.userId;
        CGFloat latitude = [location.latitude floatValue];
        CGFloat longitude = [location.longitude floatValue];
        CLLocation *thisLocation = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        locationWDistance.distance = [NSNumber numberWithDouble:[thisLocation distanceFromLocation:myLocation]];
        [mutableLocationWDistance addObject:locationWDistance];
        thisLocation = nil;
    }
    
    NSSortDescriptor *sortDistance = [NSSortDescriptor
                                      sortDescriptorWithKey:@"distance"
                                      ascending:YES];
    [mutableLocationWDistance sortUsingDescriptors:[NSArray arrayWithObject:sortDistance]];
    
    return mutableLocationWDistance;
}


- (void)delete:(NSManagedObject *)object
{
    [self.managedObjectContext deleteObject:object];
}

-(UserInfo *)getThisUser:(NSString *)userId {
    
    // If userId is nil, then see if there is any value stored in thisUserId
    if (userId == nil && self.thisUserId != nil) {
        userId = self.thisUserId;
    }
    
    @synchronized([self class])
    {
        NSManagedObjectContext *context = [self managedObjectContext];
        UserInfo *user;
        
        NSEntityDescription *entity = [NSEntityDescription
                                                  entityForName:@"UserInfo" inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate
                                  predicateWithFormat:@"userId = %@", userId];
        [request setPredicate:predicate];
        
        NSError *error;
        NSArray *users = [context executeFetchRequest:request error:&error];
        
        if (error) {
            [self throwError:error];
            return nil;
        }
        
        if ([users count] == 0) {
            [self addUser:userId];
        } else {
            user = [users objectAtIndex:0];
            user.lastUseDate = [NSDate date];
            [self setTokenAndEndpointARNForUser:user];
            self.thisUserId = user.userId;
            
            [self saveContext];
        }
        
        return user;
    }
}

-(void) setTokenAndEndpointARNForUser:(UserInfo *)user
{
    // If the token is empty, or if it's changed then add it
    AppDelegate *appDelegate =  (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.deviceToken != nil && [appDelegate.deviceToken isEqualToString:user.deviceToken] == NO) {
        user.deviceToken = appDelegate.deviceToken;
        // Set endpointARN to nil so we know to update it
        user.endpointARN = nil;
    }
    // If we have a device token but not an endpointARN, add it
    if (user.deviceToken != nil && user.endpointARN == nil) {
        SNSMessenger *messenger = [SNSMessenger sharedManager];
        NSString *endpoint = [messenger createEndpointARNFromToken:user.deviceToken forUser:user.userId];
        if (endpoint != nil) {
            user.endpointARN = endpoint;
        }
    }
}

-(NSString *)getEndpointARNForUserID:(NSString *)userId
{
    @synchronized([self class])
    {
        NSString *endpointARN;
        
        NSManagedObjectContext *context = [self managedObjectContext];
        UserInfo *user;
        
        NSEntityDescription *entity = [NSEntityDescription
                                       entityForName:@"UserInfo" inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate
                                  predicateWithFormat:@"userId = %@", userId];
        [request setPredicate:predicate];
        
        NSError *error;
        NSArray *users = [context executeFetchRequest:request error:&error];
        
        if (error) {
            NSLog(@"Error was %@", error);
        } else {
            if ([users count] > 0) {
                user = [users objectAtIndex:0];
                endpointARN = user.endpointARN;
            }
        }
        
        return endpointARN;
    }
}

-(NSArray *)getMyAwesomes
{
    @synchronized([self class])
    {
        NSManagedObjectContext *context = [self managedObjectContext];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Awesome" inManagedObjectContext:context];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entity];
        
        [self getLocalAwesomes];
        
        NSPredicate *predicate;
        if ([self.localAwesomes count] == 0) {
            predicate = [NSPredicate predicateWithFormat:@"myUserId = %@", self.thisUserId];
        } else {
            NSDictionary *localAwesome = self.localAwesomes[0];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"yyyy-MM-dd";
            NSString *dateString = [dateFormatter stringFromDate:localAwesome[@"awesomeDate"]];
            predicate = [NSPredicate predicateWithFormat:@"myUserId = %@ and rangeKey > %@", self.thisUserId, dateString];
        }
        [request setPredicate:predicate];
        
        NSError *error;
        NSArray *array = [context executeFetchRequest:request error:&error];
        
        if (error) {
            [self throwError:error];
            return nil;
        }
        
        // Add any new awesomes to local awesome table
        if ([array count] > 0) {
            for (Awesome *awesome in array) {
                [self addLocalAwesome:awesome];
            }
            
            NSSortDescriptor *sortDate = [NSSortDescriptor
                                          sortDescriptorWithKey:@"awesomeDate"
                                          ascending:NO];
            NSArray *orderedArray = [self.localAwesomes sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDate]];
            self.localAwesomes = [orderedArray mutableCopy];
            
            [self saveLocalAwesomes];
        }
        
        return self.localAwesomes;
    }
}

- (void) addLocalAwesome:(Awesome *)awesome {
    NSDictionary *localAwesome = [[NSDictionary alloc] initWithObjectsAndKeys:[awesome.myUserId copy], @"myUserId",
                                                                              [awesome.rangeKey copy], @"rangeKey",
                                                                              [awesome.awesomeDate copy], @"awesomeDate",
                                                                              [awesome.theirUserId copy], @"theirUserId",
                                                                              [awesome.comment copy], @"comment", nil];
    
    if ([self.localAwesomes containsObject:localAwesome] == NO) {
        [self.localAwesomes addObject:localAwesome];
    }
}

- (Awesome *)getAwesome:(NSString *)userId withRangeKey:(NSString *)rangeKey
{
    @synchronized([self class])
    {
        NSManagedObjectContext *context = [self managedObjectContext];
        
        Awesome *awesome;
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Awesome" inManagedObjectContext:context];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entity];
    
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"myUserId = %@ AND rangeKey = %@", userId, rangeKey];
        [request setPredicate:predicate];
        
        [self saveContext];
        
        NSError *error;
        NSArray *array = [context executeFetchRequest:request error:&error];
        
        if ([array count] > 0) {
            awesome = [array objectAtIndex:0];
        }
        
        return awesome;
    }
}

- (void) getLocalAwesomes
{
    NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey:@"localAwesomes"];
    
    
    self.localAwesomes = [array mutableCopy];
}

- (void) saveLocalAwesomes
{
    [[NSUserDefaults standardUserDefaults] setObject:self.localAwesomes forKey:@"localAwesomes"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (AwesomeStatus)awesomeUser:(NSString *)userId withComment:(NSString *)comment
{
    @synchronized([self class])
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
        NSString *rangeKey = [NSString stringWithFormat:@"%@,%@", [dateFormatter stringFromDate:[NSDate date]], self.thisUserId];
        
        if ([self getAwesome:userId withRangeKey:rangeKey] != nil) {
            return CantAwesomeAgain;
        }
        
        if (userId == self.thisUserId) {
            return CantAwesomeSelf;
        }
        
        NSManagedObjectContext *context = [self managedObjectContext];
        
        if (self.thisUserId != nil) {
            
            Awesome *awesome = [NSEntityDescription insertNewObjectForEntityForName:@"Awesome" inManagedObjectContext:context];
            
            awesome.myUserId = userId;
            awesome.rangeKey = rangeKey;
            awesome.theirUserId = self.thisUserId;
            awesome.awesomeDate = [NSDate date];
            if ([comment length] > 0) {
                awesome.comment = comment;
            }
        }
        
        [self saveContext];
        
        return Success;
    }
}
#pragma mark - Error handling
- (void)throwError:(NSError *)error
{
    [[[UIAlertView alloc] initWithTitle:@"Whoops!"
                                message:@"We could not connect to our Awesome Network. Please try again."
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

#pragma mark - Core Data stack
- (NSError *)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    }
    return error;
}
// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        
        //Undo Support
        NSUndoManager *undoManager = [NSUndoManager new];
        _managedObjectContext.undoManager = undoManager;
        
        _managedObjectContext.persistentStoreCoordinator = coordinator;
        _managedObjectContext.mergePolicy = [[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyStoreTrumpMergePolicyType];
    }

    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSError *error;
    
    // Registers the AWSNSIncrementalStore
    [NSPersistentStoreCoordinator registerStoreClass:[AWSPersistenceDynamoDBIncrementalStore class] forStoreType:AWSPersistenceDynamoDBIncrementalStoreType];
    
    // Instantiates PersistentStoreCoordinator
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
//    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Model.sqlite"];
//    
//    // handle db upgrade
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
//                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
//                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
//    
//    NSError *error = nil;
//    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
//    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
//        /*
//         Replace this implementation with code to handle the error appropriately.
//         
//         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//         
//         Typical reasons for an error here include:
//         * The persistent store is not accessible;
//         * The schema for the persistent store is incompatible with current managed object model.
//         Check the error message to determine what the actual problem was.
//         
//         
//         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
//         
//         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
//         * Simply deleting the existing store:
//         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
//         
//         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
//         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
//         
//         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
//         
//         */
//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
//    }
    
    // Creates options for the AWSNSIncrementalStore
    NSDictionary *hashKeys = [NSDictionary dictionaryWithObjectsAndKeys:
                              USERS_KEY, @"UserInfo",
                              LOCATIONS_HASH_KEY, @"Location",
                              AWESOME_HASH_KEY, @"Awesome",
                              nil];
    NSDictionary *rangeKeys = [NSDictionary dictionaryWithObjectsAndKeys:
                               LOCATIONS_RANGE_KEY, @"Location",
                               AWESOME_RANGE_KEY, @"Awesome",
                               nil];
    NSDictionary *versions = [NSDictionary dictionaryWithObjectsAndKeys:
                              USERS_VERSIONS, @"UserInfo",
                              LOCATIONS_VERSIONS, @"Location",
                              AWESOME_VERSIONS, @"Awesome",
                              nil];
    NSDictionary *tableMapper = [NSDictionary dictionaryWithObjectsAndKeys:
                                 USERS_TABLE, @"UserInfo",
                                 LOCATIONS_TABLE, @"Location",
                                 AWESOME_TABLE, @"Awesome",
                                 nil];
    
    AmazonWIFCredentialsProvider *provider = [AmazonClientManager provider];
    
    self.thisUserId = provider.subjectFromWIF;
    
    //AmazonClientManager *provider = [AmazonClientManager new];
    
    AmazonDynamoDBClient *ddb = [[AmazonDynamoDBClient alloc] initWithCredentialsProvider:provider];
    ddb.endpoint = [AmazonEndpoints ddbEndpoint:US_WEST_2];
    
    NSDictionary *storeOoptions = [NSDictionary dictionaryWithObjectsAndKeys:
                             hashKeys, AWSPersistenceDynamoDBHashKey,
                             rangeKeys, AWSPersistenceDynamoDBRangeKey,
                             versions, AWSPersistenceDynamoDBVersionKey,
                             ddb, AWSPersistenceDynamoDBClient,
                             tableMapper, AWSPersistenceDynamoDBTableMapper, nil];
    
    // Adds the AWSNSIncrementalStore to the PersistentStoreCoordinator
    if(![_persistentStoreCoordinator addPersistentStoreWithType:AWSPersistenceDynamoDBIncrementalStoreType
                                                  configuration:nil
                                                            URL:nil
                                                        options:storeOoptions
                                                          error:&error])
    {
        // Handle the error.
        NSLog(@"Unable to create store. Error: %@", error);
    }

    
    
    return _persistentStoreCoordinator;
}

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
