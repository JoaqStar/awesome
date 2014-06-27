//
//  VideoCell.h
//  awesome
//
//  Created by Joaquin Brown on 1/9/14.
//  Copyright (c) 2014 Joaquin Brown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoCell : UICollectionViewCell

- (void)configureVideo:(NSString *)videoName ofType:(NSString *)videoType isImage:(BOOL)isImage color:(UIColor *)color;

@end
