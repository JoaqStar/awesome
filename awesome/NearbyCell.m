//
//  NearbyCell.m
//  awesome
//
//  Created by Joaquin Brown on 11/26/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import "NearbyCell.h"
#import "Tools.h"

@interface NearbyCell ()

@property (nonatomic, strong) NSMutableArray *cachedImages;

@end

@implementation NearbyCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.cachedImages = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)configureCellWithUserID:(NSString *)userId
{
    [self configureCellWithUserID:userId andDistance:nil];
}

- (void)configureCellWithUserID:(NSString *)userId andDistance:(NSNumber *)distance
{
    self.userId = userId;
    self.userImage.profileID = nil;
    self.userImage.profileID = userId;
    self.userName.text = nil;
    self.usersAwesomeness.text = nil;
    if (distance != nil) {
        self.distance.text = [Tools getDistanceString:[distance floatValue]  isMeters:YES];
    } else {
        self.distance.text = nil;
    }
    [FBRequestConnection startWithGraphPath:userId
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              if (!error) {
                                  NSDictionary<FBGraphUser> *fbUser = result;
                                  self.userName.text = fbUser.name;
                                  self.gender = fbUser[@"gender"];
                              }
                          }];
}

- (void)configureCellwithFBInfo:(NSDictionary *)fbInfo
{
    self.userId = fbInfo[@"id"];
    //self.userImage = [self getCachedImageForID:self.userId];
    self.userImage.profileID = nil;
    self.userImage.profileID = self.userId;
    self.userName.text = fbInfo[@"name"];
    self.gender = fbInfo[@"gender"];
}

- (FBProfilePictureView *) getCachedImageForID:(NSString *)userId
{
    FBProfilePictureView *cachedImage = [[FBProfilePictureView alloc] init];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userId = %@", userId];
    NSArray *filteredArray = [self.cachedImages filteredArrayUsingPredicate:predicate];
    if ([filteredArray count] > 0) {
        cachedImage = filteredArray[0][@"image"];
    } else {
        cachedImage.profileID = userId;
        NSDictionary *cachedDictionary = @{@"UserId" : userId,
                                           @"image" : cachedImage};
        [self.cachedImages addObject:cachedDictionary];
    }
    return cachedImage;
}

@end
