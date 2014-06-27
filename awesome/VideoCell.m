//
//  VideoCell.m
//  awesome
//
//  Created by Joaquin Brown on 1/9/14.
//  Copyright (c) 2014 Joaquin Brown. All rights reserved.
//

#import "VideoCell.h"
#import <QuartzCore/QuartzCore.h>
#import "Tools.h"

@interface VideoCell ()

@property (nonatomic, weak) IBOutlet UIImageView *videoImage;
@property (nonatomic, weak) IBOutlet UILabel *videoNameLabel;
@property (nonatomic, weak) IBOutlet UIView *background;

@end

@implementation VideoCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)configureVideo:(NSString *)videoName ofType:(NSString *)videoType isImage:(BOOL)isImage color:(UIColor *)color
{
    if (isImage) {
        self.videoNameLabel.text = nil;
        [self.videoImage setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@.jpg",videoName]]];
    } else {
        self.videoNameLabel.text = videoName;
        [self.videoImage setImage:nil];
    }
    
    if ([color isEqual:[UIColor whiteColor]])
    {
        [self.background setBackgroundColor:[UIColor whiteColor]];
        [self.videoNameLabel setTextColor:[Tools getAwesomeBlueColor]];
    } else
    {
        [self.background setBackgroundColor:color];
        [self.videoNameLabel setTextColor:[UIColor whiteColor]];
    }
    
}

@end
