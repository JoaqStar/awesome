//
//  NearbyCell.h
//  awesome
//
//  Created by Joaquin Brown on 11/26/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface NearbyCell : UICollectionViewCell

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *gender;
@property (nonatomic, weak) IBOutlet FBProfilePictureView *userImage;
@property (nonatomic, weak) IBOutlet UILabel *userName;
@property (nonatomic, weak) IBOutlet UILabel *usersAwesomeness;
@property (nonatomic, weak) IBOutlet UILabel *distance;

- (void)configureCellWithUserID:(NSString *)userId;
- (void)configureCellWithUserID:(NSString *)userId andDistance:(NSNumber *)distance;
- (void)configureCellwithFBInfo:(NSDictionary *)fbInfo;

@end
