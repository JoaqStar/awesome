//
//  HistoryViewController.m
//  awesome
//
//  Created by Joaquin Brown on 11/27/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import "HistoryViewController.h"
#import "HistoryCell.h"
#import "Tools.h"

@interface HistoryViewController ()

@property (nonatomic, strong) NSString *theirUserId;

@end

@implementation HistoryViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.view setBackgroundColor:[Tools getBackgroundColor]];
    
    [self resetBadge];
}

- (void)resetBadge
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.awesomes count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"historyCell";
    HistoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary *localAwesome = [self.awesomes objectAtIndex:indexPath.row];
    
    [cell configureCell:localAwesome];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 0.0f;
    
    // Get length of comments
    NSDictionary *localAwesome = [self.awesomes objectAtIndex:indexPath.row];
    if ([localAwesome[@"comment"] length] == 0) {
        height = 44.0f;
    } else {
        height = [self getExpectedLabelHeight:localAwesome[@"comment"]] + 44.0;
    }
    return height;
}

- (CGFloat)getExpectedLabelHeight:(NSString *)text {
    CGFloat height = 0.0f;
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0,310,0)];
    [label setFont:[UIFont systemFontOfSize:12]];
    //[label sizeToFit];
    if ([text length] == 0) {
        height = 0.0f;
    } else {
        
        NSAttributedString *attributedText =
        [[NSAttributedString alloc]
         initWithString:text
         attributes:@
         {
         NSFontAttributeName: [UIFont systemFontOfSize:12.0f]
         }];
        CGSize maxSize = CGSizeMake(310, 400);
        CGRect rect = [attributedText boundingRectWithSize:maxSize
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                   context:nil];
        CGSize size = rect.size;
        
        height = ceilf(size.height);
    }
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb://requests"]]) {
        NSDictionary *localAwesome = [self.awesomes objectAtIndex:indexPath.row];
        self.theirUserId = localAwesome[@"theirUserId"];
        NSString *message = [NSString stringWithFormat:@"Would you like to visit this person in the facebook app?"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Facebook?"
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Ok", nil];
        [alertView show];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSString *userFacebookString = [NSString stringWithFormat:@"fb://profile/%@", self.theirUserId];
        NSURL *url = [NSURL URLWithString:userFacebookString];
        [[UIApplication sharedApplication] openURL:url];
    }

}
@end
