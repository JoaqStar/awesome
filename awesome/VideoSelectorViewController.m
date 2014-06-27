//
//  VideoSelectorViewController.m
//  awesome
//
//  Created by Joaquin Brown on 1/9/14.
//  Copyright (c) 2014 Joaquin Brown. All rights reserved.
//

#import "VideoSelectorViewController.h"
#import "VideoCell.h"
#import "VideoPreviewController.h"
#import "Tools.h"

@interface VideoSelectorViewController ()

@property (nonatomic, strong) NSArray *array;

@end

@implementation VideoSelectorViewController

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
	
    // Load videos
    NSDictionary *video1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"Being Single", @"name",
                                                                        @"m4v", @"type",
                                                                        @"0", @"isImage",
                                                                        [Tools getAwesomeBlueColor], @"color", nil];
    NSDictionary *video2 = [[NSDictionary alloc] initWithObjectsAndKeys:@"Deep House", @"name",
                                                                        @"m4v", @"type",
                                                                        @"0", @"isImage",
                                                                        [Tools getAwesomeBlueColor], @"color", nil];
    NSDictionary *video3 = [[NSDictionary alloc] initWithObjectsAndKeys:@"Last Night", @"name",
                                                                        @"m4v", @"type",
                                                                        @"0", @"isImage",
                                                                        [Tools getAwesomeBlueColor], @"color", nil];
    NSDictionary *video4 = [[NSDictionary alloc] initWithObjectsAndKeys:@"Love", @"name",
                                                                        @"m4v", @"type",
                                                                        @"0", @"isImage",
                                                                        [UIColor whiteColor], @"color", nil];
    NSDictionary *video5 = [[NSDictionary alloc] initWithObjectsAndKeys:@"My Boyfriend", @"name",
                                                                        @"m4v", @"type",
                                                                        @"0", @"isImage",
                                                                        [Tools getAwesomeBlueColor], @"color", nil];
    NSDictionary *video6 = [[NSDictionary alloc] initWithObjectsAndKeys:@"My Wife", @"name",
                                                                        @"m4v", @"type",
                                                                        @"0", @"isImage",
                                                                        [Tools getAwesomeBlueColor], @"color", nil];
    NSDictionary *video8 = [[NSDictionary alloc] initWithObjectsAndKeys:@"Equality", @"name",
                            @"m4v", @"type",
                            @"0", @"isImage",
                            [Tools getAwesomeBlueColor], @"color", nil];
    NSDictionary *video10 = [[NSDictionary alloc] initWithObjectsAndKeys:@"My Girlfriend", @"name",
                             @"m4v", @"type",
                             @"0", @"isImage",
                             [UIColor whiteColor], @"color", nil];
    NSDictionary *video11 = [[NSDictionary alloc] initWithObjectsAndKeys:@"My Husband", @"name",
                             @"m4v", @"type",
                             @"0", @"isImage",
                             [UIColor whiteColor], @"color", nil];
    NSDictionary *video12 = [[NSDictionary alloc] initWithObjectsAndKeys:@"My Kids", @"name",
                             @"m4v", @"type",
                             @"0", @"isImage",
                             [Tools getAwesomeBlueColor], @"color", nil];
    NSDictionary *video13 = [[NSDictionary alloc] initWithObjectsAndKeys:@"Om", @"name",
                             @"m4v", @"type",
                             @"1", @"isImage",
                             [UIColor whiteColor], @"color", nil];
    
    self.array = [NSArray arrayWithObjects:video1, video2, video13, video4, video6, video8, video11, video10, video12, video3, video5, nil];
}

#pragma mark - Collection View Controller Data Source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.array count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"videoCell" forIndexPath:indexPath];
    
    NSDictionary *video = [self.array objectAtIndex:indexPath.row];
    
    [cell configureVideo:video[@"name"] ofType:video[@"type"] isImage:[video[@"isImage"] boolValue] color:video[@"color"]];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"videoPlayer"])
    {
        // Get reference to the destination view controller
        NSArray *selectedItems = [self.collectionView indexPathsForSelectedItems];
        NSIndexPath *indexPath = selectedItems[0];
        VideoPreviewController *videoPreviewController = [segue destinationViewController];
        videoPreviewController.videoInfo = self.array[indexPath.row];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
