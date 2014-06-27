//
//  SigninViewController.m
//  awesome
//
//  Created by Joaquin Brown on 11/22/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import "SigninViewController.h"
#import "AmazonClientManager.h"
#import "DataManager.h"
#import "AppDelegate.h"
#import "Tools.h"

@interface SigninViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *facebookButton;

- (IBAction)anonymousSignin:(id)sender;
- (IBAction)facebookSignin:(id)sender;


@end

@implementation SigninViewController

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
	
    self.appDelegate = [[UIApplication sharedApplication] delegate];
    
    [self.view setBackgroundColor:[Tools getBackgroundColor]];
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([self.activityIndicator isAnimating] == NO) {
        [self.facebookButton setHidden:NO];
    }
}

- (IBAction)anonymousSignin:(id)sender {
    
    [self performSegueWithIdentifier:@"homeSegue" sender:self];
}

- (IBAction)facebookSignin:(id)sender {
    
    if (!FBSession.activeSession.isOpen) {
        [self.facebookButton setHidden:YES];
        [self.activityIndicator startAnimating];
        [NSTimer scheduledTimerWithTimeInterval:15.0
                                         target:self
                                       selector:@selector(stopActivityIndicator)
                                       userInfo:nil
                                        repeats:NO];
        [self.appDelegate openSessionWithAllowLoginUI:YES withCompletion:^(FBSession *session, NSError *error) {
            if (!error) {
                [self getUserInfo:session];
            } else {
                [self.facebookButton setHidden:NO];
                [self.activityIndicator stopAnimating];
                NSString *alertMessage = @"Awesome does not have access to your facebook.\nGo to Settings->Facebook and allow Awesome. to user your account.";
                [[[UIAlertView alloc] initWithTitle:@"Whoops!"
                                            message:alertMessage
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            }
        }];
    } else {
        [self getUserInfo:FBSession.activeSession];
    }
}

-(void) getUserInfo:(FBSession *)session {
    static FBSession *savedSession;
    
    if (session == nil) {
        session = savedSession;
    } else {
        savedSession = session;
    }
    // Get facebook user
    [[FBRequest requestForMe] startWithCompletionHandler:
     ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *fbUser, NSError *error) {
         if (!error) {
             NSLog(@"User is %@", fbUser);
             if ([AmazonClientManager FBLogin:session]) {
                 
                 // add facebook user to database
                 DataManager *dataManager = [DataManager sharedManager];
                 [dataManager addFacebookUser:fbUser];
                 [self performSegueWithIdentifier:@"homeSegue" sender:self];
                 [self.activityIndicator stopAnimating];
             } else {
                 [[[UIAlertView alloc] initWithTitle:@"Whoops!"
                                             message:@"Oops, we could not connect. Press ok to try again."
                                            delegate:self
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil] show];
             }

         }
     }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self getUserInfo:nil];
}

#pragma mark - FBLoginViewDelegate
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    
    NSLog(@"user logged in");
}

- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    
    NSLog(@"User is %@", user);
    
    [AmazonClientManager FBLogin:self.appDelegate.session];
}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    
    NSLog(@"login in view");
}

- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    // see https://developers.facebook.com/docs/reference/api/errors/ for general guidance on error handling for Facebook API
    // our policy here is to let the login view handle errors, but to log the results
    NSLog(@"FBLoginView encountered an error=%@", error);
}

-(void)stopActivityIndicator
{
    [self.facebookButton setHidden:NO];
    [self.activityIndicator stopAnimating];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
