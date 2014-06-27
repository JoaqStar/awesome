//
//  NearbyViewController.m
//  awesome
//
//  Created by Joaquin Brown on 11/26/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import "NearbyViewController.h"
#import <AWSSNS/AWSSNS.h>
#import <CoreLocation/CoreLocation.h>
#import "DataManager.h"
#import "SNSMessenger.h"
#import "NearbyCell.h"
#import "LocationWDistance.h"
#import "BTScan.h"
#import "Tools.h"

typedef enum {
    kNearby = 0,
    kFacebook
} kViewing;

@interface NearbyViewController () <CLLocationManagerDelegate, BTScanDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) DataManager *dataManager;
@property (nonatomic, strong) SNSMessenger *messenger;
@property (nonatomic, strong) BTScan *btScan;
@property (nonatomic, strong) UIAlertView *progressAlert;
@property (nonatomic, strong) NSArray *nearbyUsers;
@property (nonatomic, strong) NSArray *facebookUsers;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, weak) IBOutlet UIView *noUsersView;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSString *userIdToAwesome;

@end

@implementation NearbyViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(startScanning)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    
    self.btScan = [BTScan alloc];
    self.btScan.delegate = self;
    
    self.dataManager = [DataManager sharedManager];
    self.messenger = [SNSMessenger sharedManager];
    
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.delegate = self;
    }
    
    [self startScanning];
    
    [self.view setBackgroundColor:[Tools getBackgroundColor]];
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.btScan = nil;
    self.locationManager = nil;
}

-(IBAction) segmentChanged:(id)sender
{
    [self.noUsersView setHidden:YES];
    if (self.segmentedControl.selectedSegmentIndex == 0){
        [self startNearby];
    } else {
        [self findFacebookFriends];
    }
}

- (void) findFacebookFriends
{
    if (FBSession.activeSession.isOpen) {
        FBRequest *friendRequest = [FBRequest requestForMyFriends];
        [friendRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                     NSDictionary<FBGraphUser> *myDictionary,
                                                     NSError *error) {
            if(!error) {
                // Friend request
                self.facebookUsers = [self sortByLastNameFirst:[myDictionary objectForKey:@"data"]];
                [self.collectionView reloadData];
            } else {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Facebook Error!" message:@"Please check your connection and try again." delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:nil];
                [alert show];
            }
        }];
    }
}

- (NSMutableArray *) sortByLastNameFirst:(NSArray *)array {
    NSMutableArray *sortDescriptors = [NSMutableArray  arrayWithCapacity:2];
    NSSortDescriptor *sortLast = [NSSortDescriptor
                                  sortDescriptorWithKey:@"last_name"
                                  ascending:YES
                                  selector:@selector(localizedCaseInsensitiveCompare:)];
    [sortDescriptors addObject:sortLast];
    NSSortDescriptor *sortFirst = [NSSortDescriptor
                                   sortDescriptorWithKey:@"first_name"
                                   ascending:YES
                                   selector:@selector(localizedCaseInsensitiveCompare:)];
    [sortDescriptors addObject:sortFirst];
    return [[array sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
}

- (void) startScanning
{
    [self.noUsersView setHidden:YES];
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        [self startNearby];
    } else {
        [self findFacebookFriends];
    }
}

- (void) startNearby
{
    
    self.lastLocation = nil;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                  target:self
                                                selector:@selector(checkLocation)
                                                userInfo:nil
                                                 repeats:NO];
    
    [self showProgressAlert];
    
    [self.locationManager startUpdatingLocation];
    
    //[self.btScan scanAllTags];
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    self.lastLocation = newLocation;
    
    if (self.lastLocation.horizontalAccuracy < 100 && self.timer != nil)
    {
        [self.timer invalidate];
        self.timer = nil;
        
        [self.locationManager stopUpdatingLocation];
        [self.progressAlert dismissWithClickedButtonIndex:0 animated:YES];
        
        [self getNearbyUsers];
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
	NSLog(@"Error: %@", [error description]);
    
    [self.timer invalidate];
    self.timer = nil;
    
    [self.progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    
    UIAlertView *alertView =  [[UIAlertView alloc] initWithTitle:@"Oops."
                                                         message:@"Could not get location."
                                                        delegate: self
                                               cancelButtonTitle: @"Ok"
                                               otherButtonTitles: nil];
    [alertView show];
    
}

- (void)checkLocation
{
    [self.locationManager stopUpdatingLocation];
    [self.progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    
    if (self.lastLocation != nil && self.lastLocation.horizontalAccuracy < 500)
    {
        [self getNearbyUsers];
    } else {
        UIAlertView *alertView =  [[UIAlertView alloc] initWithTitle:@"Oops."
                                                             message:@"We could not get your location. Have you tried turning on Wifi? It helps."
                                                            delegate: self
                                                   cancelButtonTitle: @"Ok"
                                                   otherButtonTitles: nil];
        [alertView show];
    }
}

- (void)getNearbyUsers
{
    self.nearbyUsers = [self.dataManager getNearbyUserLocationsWDistance:self.lastLocation.coordinate];
    [self.collectionView reloadData];
    
    if (self.nearbyUsers != nil && [self.nearbyUsers count] == 0) {
        [self.noUsersView setHidden:NO];
    } else {
        [self.noUsersView setHidden:YES];
    }
}

- (void) showProgressAlert {
    self.progressAlert = [[UIAlertView alloc] initWithTitle:@"Finding Nearby Awesomeness"
                                                    message:@"Please Wait..."
                                                   delegate: self
                                          cancelButtonTitle: nil
                                          otherButtonTitles: nil];
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityView.frame = CGRectMake(139.0f-18.0f, 78.0f, 37.0f, 37.0f);
    [self.progressAlert addSubview:activityView];
    [activityView startAnimating];
    
    [self.progressAlert show];
}

- (void) didUpdateListOfBTDevices:(NSArray *)devices {
    
    NSLog(@"received devices %@", devices);
//    self.nearbyUsers = devices;
//    [self.progressAlert dismissWithClickedButtonIndex:0 animated:YES];
//    [self.collectionView reloadData];
}


#pragma mark - Collection View Controller Data Source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count;
    if (self.segmentedControl.selectedSegmentIndex == kNearby) {
        count = [self.nearbyUsers count];
    } else {
        count = [self.facebookUsers count];
    }
    
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NearbyCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"nearbyCell" forIndexPath:indexPath];
    
    if (self.segmentedControl.selectedSegmentIndex == kNearby) {
        LocationWDistance *location = [self.nearbyUsers objectAtIndex:indexPath.row];
        [cell configureCellWithUserID:location.userId andDistance:location.distance];
    } else {
        NSDictionary *fbInfo = [self.facebookUsers objectAtIndex:indexPath.row];
        [cell configureCellwithFBInfo:fbInfo];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NearbyCell *cell = (NearbyCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (self.segmentedControl.selectedSegmentIndex == kNearby) {
        [self awesomeUser:cell];
    } else {
        [self awesomeFacebookUser:cell];
    }
    
}

-(void)awesomeUser:(NearbyCell *)cell {
    
    if ([cell.userId isEqualToString:self.dataManager.thisUserId]) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry."
                                    message:@"You can't awesome yourself :("
                                   delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }
    
    self.userIdToAwesome = cell.userId;
    
    NSString *heShe;
    if ([cell.gender isEqualToString:@"male"]) {
        heShe = @"he";
    } else {
        heShe = @"she";
    }
    NSString *message = [NSString stringWithFormat:@"We'll tell %@ that %@ is Awesome. Add a comment if you like!", cell.userName.text, heShe];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:cell.userName.text
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Ok", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.autocorrectionType = UITextAutocorrectionTypeYes;
    textField.placeholder = @"No comment";
    [textField setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
    [alertView show];
}

-(void)awesomeFacebookUser:(NearbyCell *)cell {

//    [FBDialogs presentShareDialogWithLink:nil
//                                  handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
//                                      if(error) {
//                                          NSLog(@"Error: %@", error.description);
//                                      } else {
//                                          NSLog(@"Success!");
//                                      }
//                                  }];
    
//    id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
//
//    [action setTags:@[cell.userId]];
//    
//    [FBDialogs presentShareDialogWithOpenGraphAction:action actionType:@"awesome:user" previewPropertyName:@"Joaquin is Awesome." handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
//        if(error) {
//            NSLog(@"Error: %@", error.description);
//        } else {
//            NSLog(@"Success!");
//        }
//    }];
    
//    id<FBGraphObject> awesomeObject =
//    [FBGraphObject openGraphObjectForPostWithType:@"awesome:user"
//                                            title:@"Awesome"
//                                            image:nil
//                                              url:nil
//                                      description:nil];
//    
//    id<FBOpenGraphAction> cookAction = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
//    [cookAction setObject:awesomeObject forKey:@"awesome"];
//    
//    [FBDialogs presentShareDialogWithOpenGraphAction:cookAction
//                                          actionType:@"awesome:user"
//                                 previewPropertyName:@"awesome"
//                                             handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
//                                                 if(error) {
//                                                     NSLog(@"Error: %@", error.description);
//                                                 } else {
//                                                     NSLog(@"Success!");
//                                                 }
//                                             }];
//    // Put together the dialog parameters
//    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                   @"Sharing Tutorial", @"name",
//                                   @"Build great social apps and get more installs.", @"caption",
//                                   @"Allow your users to share stories on Facebook from your app using the iOS SDK.", @"description",
//                                   @"https://developers.facebook.com/docs/ios/share/", @"link",
//                                   @"http://i.imgur.com/g3Qc1HN.png", @"picture",
//                                   [NSArray arrayWithObject:cell.userId], @"friends",
//                                   nil];
//    
//    // Make the request
//    [FBRequestConnection startWithGraphPath:@"/me/feed"
//                                 parameters:params
//                                 HTTPMethod:@"POST"
//                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//                              if (!error) {
//                                  // Link posted successfully to Facebook
//                                  NSLog(@"Posted successfully");
//                              } else {
//                                  // An error occurred, we need to handle the error
//                                  // See: https://developers.facebook.com/docs/ios/errors
//                                  NSLog(@"Error was %@", error);
//                              }
//                          }];
    
    // Check if the Facebook app is installed and we can present the share dialog
//    FBShareDialogParams *params = [[FBShareDialogParams alloc] init];
//    params.link = [NSURL URLWithString:@"http://youtu.be/ypW-r3Mz3Pk"];
//    params.name = @"Awesome.";
//    params.caption = @"You are Awesome.";
//    params.description = @"Download the app to tell your friends they are Awesome.";
//    params.friends = [NSArray arrayWithObject:cell.userId];
//    // If the Facebook app is installed and we can present the share dialog
//    if ([FBDialogs canPresentShareDialogWithParams:params]) {
//        [FBDialogs presentShareDialogWithParams:params
//                                    clientState:nil
//                                      handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
//                                          if(error) {
//                                              // An error occurred, we need to handle the error
//                                              // See: https://developers.facebook.com/docs/ios/errors
//                                              NSLog(@"Error was %@",error);
//                                          } else {
//                                              // Success
//                                              NSLog(@"result %@", results);
//                                          }
//                                      }];
//    } else {
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry"
//                                                            message:@"You must have the Facebook app installed for this feature to work."
//                                                           delegate:self
//                                                  cancelButtonTitle:@"Ok" otherButtonTitles:nil];
//        [alertView show];
//    }
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"youAreAwesome" ofType:@"mp4"];
//    NSData *videoData = [NSData dataWithContentsOfFile:filePath];
//    NSArray *friendsIDs = [NSArray arrayWithObject:cell.userId];
//    NSError *error;
//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:friendsIDs options:NSJSONWritingPrettyPrinted error:&error];
//    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                   videoData, @"youAreAwesome.mp4",
//                                   @"video/quicktime", @"contentType",
//                                   @"Video Test Title", @"title",
//                                   @"Video Test Description", @"description",
//                                   jsonString, @"tags",
//                                   nil];
//    [FBRequestConnection startWithGraphPath:@"me/videos"
//                                 parameters:params
//                                 HTTPMethod:@"POST"
//                          completionHandler:^(
//                                              FBRequestConnection *connection,
//                                              id result,
//                                              NSError *error
//                                              ) {
//                              if (error)
//                                  NSLog(@"error %@", error);
//    }];
    
}

// A function for parsing URL parameters returned by the Feed Dialog.
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (![alertView.title isEqualToString:@"Oops."])
    {
        if (buttonIndex == 1) {
            NSString *comment = [[alertView textFieldAtIndex:0] text];
            AwesomeStatus status = [self.dataManager awesomeUser:self.userIdToAwesome withComment:comment];
            if (status == CantAwesomeAgain) {
                [[[UIAlertView alloc] initWithTitle:@"Sorry."
                                            message:@"You can't Awesome the same person more than once day."
                                           delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            } else {
                NSString *endpointARN = [self.dataManager getEndpointARNForUserID:self.userIdToAwesome];
                if (endpointARN != nil) {
                    [FBRequestConnection startWithGraphPath:[self.dataManager thisUserId]
                                                 parameters:nil
                                                 HTTPMethod:@"GET"
                                          completionHandler:^(
                                                              FBRequestConnection *connection,
                                                              id result,
                                                              NSError *error
                                                              ) {
                                              if (!error) {
                                                  NSDictionary<FBGraphUser> *fbUser = result;
                                                  NSString *notificationComment;
                                                  if ([comment length] > 0) {
                                                      notificationComment = [NSString stringWithFormat:@"%@ thinks you're Awesome and said '%@'", fbUser.name, comment];
                                                  } else {
                                                      notificationComment = [NSString stringWithFormat:@"%@ thinks you're Awesome.", fbUser.name];
                                                  }
                                                  [self.messenger sendNotificationToEndpoint:endpointARN withComment:notificationComment];
                                              }
                    }];
                }
            }
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
