//
//  BJLScToolOptionCell.h
//  BJLiveUI
//
//  Created by xyp on 2020/8/24.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScToolOptionCell : UICollectionViewCell

@property (nonatomic) BOOL showSelectBorder;
@property (nonatomic, nullable, copy) void (^selectCallback)(BOOL selected);

- (void)updateBackgroundIcon:(UIImage *)icon
                selectedIcon:(UIImage *)selectedIcon
                 description:(NSString * _Nullable)description
                  isSelected:(BOOL)selected;

- (void)updateBackgroundIcon:(UIImage *)icon
                selectedIcon:(UIImage *)selectedIcon
             backgroundColor:(nullable UIColor *)backgroundColor
                 description:(NSString * _Nullable)description
                  isSelected:(BOOL)selected;

- (void)updateContentWithOptionIcon:(UIImage *)icon
                       selectedIcon:(UIImage * _Nullable)selectedIcon
                        description:(NSString * _Nullable)description
                         isSelected:(BOOL)selected;


@end

NS_ASSUME_NONNULL_END
