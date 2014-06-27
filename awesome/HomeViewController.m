//
//  HomeViewController.m
//  awesome
//
//  Created by Joaquin Brown on 11/24/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import "HomeViewController.h"
#import "AppDelegate.h"
#import "DataManager.h"
#import "Utilities.h"
#import "UserInfo.h"
#import "HistoryViewController.h"
#import "BTBroadcast.h"
#import "Tools.h"

@interface HomeViewController ()

@property (weak, nonatomic) IBOutlet FBProfilePictureView *profilePic;
@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) DataManager *dataManager;
@property (nonatomic, strong) BTBroadcast *btBroadcast;
@property (nonatomic, weak) IBOutlet UIButton *awsmeButton;
@property (nonatomic, strong) NSArray *awesomes;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) IBOutlet UIButton *retryButton;

@end


@implementation HomeViewController

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
    
    self.dataManager = [DataManager sharedManager];
    
    if ([self.dataManager thisUserId] != nil)
    {
        self.profilePic.profileID = [self.dataManager thisUserId];
        [NSTimer scheduledTimerWithTimeInterval:5.0
                                         target:self
                                       selector:@selector(updateRetryButton)
                                       userInfo:nil
                                        repeats:NO];
    }

    [self.view setBackgroundColor:[Tools getBackgroundColor]];
    
    self.awesomes = [self.dataManager getMyAwesomes];
    
    [self updateAwesomeCount];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAwesomes) name:@"updateAwesomes" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    [self updateAwesomes];
}

- (void)updateRetryButton
{
    [self.retryButton setTitle:@"Retry" forState:UIControlStateNormal];
    [self.retryButton setEnabled:YES];
}

- (void)updateAwesomeCount
{
    int numberOfAwesomes = (int)[self.awesomes count];

    switch (numberOfAwesomes) {
        case 0:
            self.awsmeButton.enabled = NO;
            [self.awsmeButton setTitle:@"You're Awesome." forState:UIControlStateNormal];
            break;
        case 1:
            self.awsmeButton.enabled = YES;
            [self.awsmeButton setTitle:@"1 Awesome" forState:UIControlStateNormal];
            break;
        default:
            self.awsmeButton.enabled = YES;
            [self.awsmeButton setTitle:[NSString stringWithFormat:@"%d Awesomes", numberOfAwesomes] forState:UIControlStateNormal];
            break;
    }
}


- (void) updateAwesomes
{
    if ([UIApplication sharedApplication].applicationIconBadgeNumber > 0) {
        
        // Update awesome count
        self.awesomes = [self.dataManager getMyAwesomes];
        [self updateAwesomeCount];
        // If there is a new notification, the pulsate awesome button
        [self.timer invalidate];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                      target:self
                                                    selector:@selector(pulsateAwesomeButton)
                                                    userInfo:nil
                                                     repeats:YES];
    } else {
        [self.timer invalidate];
        [self.awsmeButton.titleLabel setAlpha:1.0];
    }
    
}
- (void) pulsateAwesomeButton
{
    static BOOL toggle = NO;
    
    [UIView animateWithDuration:.1 animations:^{
        if (toggle) {
            [self.awsmeButton.titleLabel setAlpha:1.0];
        } else {
            [self.awsmeButton.titleLabel setAlpha:0.0];
        }
    }];
    
    toggle = !toggle;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"history"]) {
        HistoryViewController *historyViewController = [segue destinationViewController];
        historyViewController.awesomes = self.awesomes;
    }
}

- (IBAction)retryButtonPressed:(id)sender
{
    self.profilePic.profileID = nil;
    self.profilePic.profileID = [self.dataManager thisUserId];
    
    self.awesomes = [self.dataManager getMyAwesomes];
    [self updateAwesomeCount];
    
    [self.retryButton setTitle:@"loading..." forState:UIControlStateNormal];
    [self.retryButton setEnabled:NO];
    [NSTimer scheduledTimerWithTimeInterval:5.0
                                     target:self
                                   selector:@selector(updateRetryButton)
                                   userInfo:nil
                                    repeats:NO];
}

- (IBAction)logout:(id)sender
{
    // Close facebook
    [FBSession.activeSession closeAndClearTokenInformation];
    [self.appDelegate.session close];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
