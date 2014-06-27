//
//  HistoryCell.m
//  awesome
//
//  Created by Joaquin Brown on 11/27/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import "HistoryCell.h"
#import "Tools.h"

@implementation HistoryCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureCell:(NSDictionary *)localAwesome
{
    self.userImage.profileID = nil;
    self.userImage.profileID = localAwesome[@"theirUserId"];
    self.awesomeLabel.text = nil;
    self.timeSinceLabel.text = nil;
    self.commentLabel.text = nil;
    self.userName = nil;
    [FBRequestConnection startWithGraphPath:localAwesome[@"theirUserId"]
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              if (!error) {
                                  NSDictionary<FBGraphUser> *fbUser = result;
                                  self.awesomeLabel.text = [NSString stringWithFormat:@"%@ said you are Awesome.", fbUser.name];
                                  self.userName = fbUser.name;
                              } else {
                                  self.awesomeLabel.text = [NSString stringWithFormat:@"An anonymous user thinks you're Awesome."];
                              }
                              self.timeSinceLabel.text = [Tools getStringSinceDate:localAwesome[@"awesomeDate"]];
                              if (localAwesome[@"comment"] != nil) {
                                  self.commentLabel.text = localAwesome[@"comment"];
                              }
                          }];
}

@end
