//
//  SplashViewController.m
//  awesome
//
//  Created by Joaquin Brown on 11/22/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import "SplashViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import "AmazonClientManager.h"
#import "AppDelegate.h"
#import "Tools.h"


typedef enum {
    AuthenticationError = -1,
    IsNotAuthorized = 0,
    IsAuthorized = 1,
} AuthenticationStatus;

@interface SplashViewController ()

@property (nonatomic, strong) UILabel *awesomeLabel;
@property (nonatomic, strong) UILabel *youLabel;
@property (nonatomic, strong) UILabel *areLabel;
@property (nonatomic, strong) AVAudioPlayer *soundPlayer;
@property (nonatomic, strong) IBOutlet UIImageView *sparkleImage;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@end

@implementation SplashViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.awesomeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 115, 44)];
    self.awesomeLabel.textColor = [UIColor colorWithRed:(0/255.0) green:(128.0/255.0) blue:(255.0/255.0) alpha:1] ;
    self.awesomeLabel.text = @"Awesome";
    self.awesomeLabel.textAlignment = NSTextAlignmentCenter;
    self.awesomeLabel.font = [UIFont systemFontOfSize:0];
    self.awesomeLabel.center = CGPointMake(160, 240);
    [self.awesomeLabel setTextAlignment:NSTextAlignmentLeft];
    [self.view addSubview:self.awesomeLabel];
    
    self.youLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
    self.youLabel.textColor = [UIColor colorWithRed:(0/255.0) green:(128.0/255.0) blue:(255.0/255.0) alpha:1] ;
    self.youLabel.textAlignment = NSTextAlignmentCenter;
    self.youLabel.font = [UIFont systemFontOfSize:0];
    self.youLabel.center = CGPointMake(160, 240);
    self.youLabel.text = @"You";
    [self.view addSubview:self.youLabel];

    self.areLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
    self.areLabel.textColor = [UIColor colorWithRed:(0/255.0) green:(128.0/255.0) blue:(255.0/255.0) alpha:1] ;
    self.areLabel.textAlignment = NSTextAlignmentCenter;
    self.areLabel.font = [UIFont systemFontOfSize:0];
    self.areLabel.center = CGPointMake(160, 240);
    self.areLabel.text = @"Are";
    [self.view addSubview:self.areLabel];

    
    [self.view setBackgroundColor:[Tools getBackgroundColor]];

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    
    NSURL* musicFile = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                               pathForResource:@"Glass"
                                               ofType:@"m4a"]];
    NSError *error;
    self.soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicFile error:&error];
    [self.soundPlayer setVolume:0.3f];
    if (error)
        NSLog(@"%@", error);
    [self.soundPlayer prepareToPlay];
    
    self.sparkleImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spark.png"]];
    self.sparkleImage.frame = CGRectMake(224, 244, 10, 10);
    self.sparkleImage.alpha = 0.0f;
    [self.view addSubview:self.sparkleImage];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
//    if ([self isAuthenticated]) {
//        [self performSegueWithIdentifier:@"homeSegue" sender:self];
//    } else {
//        [self performSegueWithIdentifier:@"signinSegue" sender:self];
//    }
    
    static BOOL firstTime = YES;
    
    if (firstTime)
    {
        firstTime = NO;
        
        self.youLabel.font = [UIFont boldSystemFontOfSize:88]; // set font size which you want instead of 35
        self.youLabel.transform = CGAffineTransformScale(self.youLabel.transform, 0.05, 0.05);
        [UIView animateWithDuration:1.0 delay:0.2 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.youLabel.transform = CGAffineTransformScale(self.youLabel.transform, 40, 40);
            self.youLabel.alpha = 0.0f;
        } completion:^(BOOL finished) {
            
            self.areLabel.font = [UIFont boldSystemFontOfSize:88]; // set font size which you want instead of 35
            self.areLabel.transform = CGAffineTransformScale(self.areLabel.transform, 0.1, 0.1);
            [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.areLabel.transform = CGAffineTransformScale(self.areLabel.transform, 20, 20);
                self.areLabel.alpha = 0.0f;
            } completion:^(BOOL finished) {
            
                self.awesomeLabel.font = [UIFont boldSystemFontOfSize:24]; // set font size which you want instead of 35
                self.awesomeLabel.transform = CGAffineTransformScale(self.awesomeLabel.transform, 0.1, 0.1);
                [UIView animateWithDuration:1.0 animations:^{
                    self.awesomeLabel.transform = CGAffineTransformScale(self.awesomeLabel.transform, 12.5, 12.5);
                } completion:^(BOOL finished) {
                    
                    [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                        self.sparkleImage.alpha = 0.7f;
                        self.sparkleImage.transform = CGAffineTransformScale(self.sparkleImage.transform, 10.0, 10.0);
                        [self.soundPlayer play];
                    } completion:^(BOOL finished) {
                        [UIView animateWithDuration:0.3 animations:^{
                            self.sparkleImage.transform = CGAffineTransformScale(self.sparkleImage.transform, 0.0, 0.0);
                            self.sparkleImage.alpha = 0.0f;
                            self.awesomeLabel.text = @"Awesome.";
                        } completion:^(BOOL finished) {
                            [UIView animateWithDuration:2.0 delay:1.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                                self.awesomeLabel.center = CGPointMake(160, 37);
                            } completion:^(BOOL finished) {
                                //self.activityIndicator
                                [self checkUserAuthentication];
                            }];
                        }];
                    }];
                }];
            }];
        }];
    } else {
        [self performSegueWithIdentifier:@"signinSegue" sender:self];
    }
    
}

- (void) checkUserAuthentication
{
    AuthenticationStatus status = [self isAuthenticated];
    if (status == AuthenticationError) {
        [[[UIAlertView alloc] initWithTitle:@"Whoops!"
                                    message:@"We could not connect to our Awesome Network. Please try again."
                                   delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    } else if (status == IsAuthorized) {
        [self.activityIndicator startAnimating];
        [self performSegueWithIdentifier:@"homeSegue" sender:self];
    } else if (status == IsNotAuthorized) {
        [self performSegueWithIdentifier:@"signinSegue" sender:self];
    }
}

- (AuthenticationStatus)isAuthenticated {
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    
    if (!appDelegate.session.isOpen) {
        // create a fresh session object
        appDelegate.session = [[FBSession alloc] init];
        
        // if we don't have a cached token, a call to open here would cause UX for login to
        // occur; we don't want that to happen unless the user clicks the login button, and so
        // we check here to make sure we have a token before calling open
        if (appDelegate.session.state == FBSessionStateCreatedTokenLoaded) {
            NSArray *permissions = FBSession.activeSession.permissions;
            if ([permissions count] == 0) {
                return NO;
            } else {
                // if the session isn't open, let's open it now and present the login UX to the user
                [appDelegate.session openWithCompletionHandler:^(FBSession *session,
                                                                 FBSessionState status,
                                                                 NSError *error) {
                }];
                // Set up amazon client access
                if ([AmazonClientManager FBLogin:appDelegate.session]) {
                
                    if (!FBSession.activeSession.isOpen) {
                        if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
                            // even though we had a cached token, we need to login to make the session usable
                            [FBSession.activeSession openWithCompletionHandler:^(FBSession *session,
                                                                                 FBSessionState status,
                                                                                 NSError *error) {
                                if (error) {
                                    NSLog(@"Could not login to facebook because: %@", error);
                                } else {
                                    NSLog(@"Successfuly logged into facebook");
                                }
                            }];
                        }
                    }
                } else {
                    [FBSession.activeSession closeAndClearTokenInformation];
                    [appDelegate.session close];
                    return AuthenticationError;
                }

                return IsAuthorized;
            }
        } else {
            return IsNotAuthorized;
        }
    } else {
        return IsAuthorized;
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self checkUserAuthentication];
}

@end
