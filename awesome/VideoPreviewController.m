//
//  VideoPreviewController.m
//  awesome
//
//  Created by Joaquin Brown on 1/10/14.
//  Copyright (c) 2014 Joaquin Brown. All rights reserved.
//

#import "VideoPreviewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <FacebookSDK/FacebookSDK.h>

@interface VideoPreviewController ()

@property (nonatomic, strong) MPMoviePlayerController *moviePlayerController;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *playButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *shareButton;

@end

@implementation VideoPreviewController

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
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:self.videoInfo[@"name"] ofType:self.videoInfo[@"type"]];
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];

    if (player)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification  object:[self moviePlayerController]];
    }

    [self setMoviePlayerController:player];

    [player setMovieSourceType:MPMovieSourceTypeFile];

    [player setControlStyle:MPMovieControlModeDefault];

    [[player backgroundView] setBackgroundColor:[UIColor whiteColor]];
    [[player view] setBackgroundColor:[UIColor whiteColor]];
    
    [[player view] setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width)];
    [[player view] setCenter:self.view.center];

    [self.view addSubview:[player view]];
    
    [self playVideo:nil];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[self moviePlayerController] stop];
}
     
- (IBAction)playVideo:(id)sender
{
    [[self moviePlayerController] play];
    [self.playButton setEnabled:NO];
}

- (void)moviePlayerDidFinish:(NSNotification *)note
{
    if (note.object == [self moviePlayerController]) {
        NSInteger reason = [[note.userInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
        if (reason == MPMovieFinishReasonPlaybackEnded){
            [[self moviePlayerController] prepareToPlay];
            [self.playButton setEnabled:YES];
        }
    }
}

- (IBAction)share:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Share Video."
                                                        message:@"Share this video to Facebook? You can add some text if you like."
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Ok", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.placeholder = @"No text";
    [textField setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        [self performPublishAction:^{
            NSString *text = [[alertView textFieldAtIndex:0] text];
            NSString *fileName = [NSString stringWithFormat:@"%@.%@", self.videoInfo[@"name"], self.videoInfo[@"type"]];
            NSString *filePath = [[NSBundle mainBundle] pathForResource:self.videoInfo[@"name"] ofType:self.videoInfo[@"type"]];
            NSData *fileData = [NSData dataWithContentsOfFile:filePath];
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           fileData, fileName,
                                           @"video/quicktime", @"contentType",
                                           @"", @"title",
                                           text, @"descriptions",
                                           nil];
            [FBRequestConnection startWithGraphPath:@"me/videos"
                                         parameters:params
                                         HTTPMethod:@"POST"
                                  completionHandler:^(
                                                      FBRequestConnection *connection,
                                                      id result,
                                                      NSError *error
                                                      ) {
                                      if (error) {
                                          [[[UIAlertView alloc] initWithTitle:@"Whoops!"
                                                                      message:@"We could not connect to Facebook. Please try again."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil] show];
                                      } else {
                                          [[[UIAlertView alloc] initWithTitle:@"Awesome."
                                                                      message:@"The video was posted to your wall!"
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil] show];
                                      }
            }];
        }];
    }
}

// Convenience method to perform some action that requires the "publish_actions" permissions.
- (void) performPublishAction:(void (^)(void)) action {
    // we defer request for permission to post to the moment of post, then we check for the permission
    if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
        // if we don't already have the permission, then we request it now
        [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions"]
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                            completionHandler:^(FBSession *session, NSError *error) {
                                                if (!error) {
                                                    action();
                                                } else if (error.fberrorCategory != FBErrorCategoryUserCancelled){
                                                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Permission denied"
                                                                                                        message:@"Unable to get permission to post"
                                                                                                       delegate:nil
                                                                                              cancelButtonTitle:@"OK"
                                                                                              otherButtonTitles:nil];
                                                    [alertView show];
                                                }
                                            }];
    } else {
        action();
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
