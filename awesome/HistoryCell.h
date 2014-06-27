//
//  HistoryCell.h
//  awesome
//
//  Created by Joaquin Brown on 11/27/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface HistoryCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet FBProfilePictureView *userImage;
@property (nonatomic, weak) IBOutlet UILabel *awesomeLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeSinceLabel;
@property (nonatomic, weak) IBOutlet UILabel *commentLabel;
@property (nonatomic, strong) NSString *userName;

- (void)configureCell:(NSDictionary *)localAwesome;

@end
