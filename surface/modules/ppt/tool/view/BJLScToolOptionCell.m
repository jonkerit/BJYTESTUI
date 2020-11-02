//
//  BJLScToolOptionCell.m
//  BJLiveUI
//
//  Created by xyp on 2020/8/24.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLScToolOptionCell.h"
#import "BJLScAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScToolOptionCell ()

@property (nonatomic) BJLScImageButton *optionButton;

@end

@implementation BJLScToolOptionCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

#pragma mark - subviews

- (void)setupSubviews {
    self.optionButton = ({
        BJLScImageButton *button = [BJLScImageButton new];
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = BJLScToolViewCornerRadius;
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#9FA8B5"] forState:UIControlStateNormal];
//        [button setTitleColor:BJLIcTheme.toolButtonTitleColor forState:UIControlStateSelected];
        
        button.selectedColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        button.normalColor = [UIColor clearColor];
        button.backgroundSize = CGSizeMake(28, 28);
        button.backgroundCornerRadius = BJLScToolViewCornerRadius;

        bjl_weakify(self);
        [button bjl_addHandler:^(UIButton * _Nonnull button) {
            bjl_strongify(self);
            if (self.selectCallback) {
                self.selectCallback(!button.selected);
            }
        }];
        button;
    });
    [self.contentView addSubview:self.optionButton];
    [self.optionButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.contentView);
    }];
}

#pragma mark - public

- (void)updateBackgroundIcon:(UIImage *)icon
                selectedIcon:(UIImage *)selectedIcon
                 description:(NSString * _Nullable)description
                  isSelected:(BOOL)selected {
    [self updateBackgroundIcon:icon selectedIcon:selectedIcon backgroundColor:nil description:description isSelected:selected];
}

// 目前仅用于字体按钮
- (void)updateBackgroundIcon:(UIImage *)icon
                selectedIcon:(UIImage *)selectedIcon
             backgroundColor:(nullable UIColor *)backgroundColor
                 description:(NSString * _Nullable)description
                  isSelected:(BOOL)selected {
    if (backgroundColor) {
        self.optionButton.backgroundColor = backgroundColor;
    }
    self.optionButton.selectedColor = [UIColor clearColor];
    [self.optionButton setBackgroundImage:icon forState:UIControlStateNormal];
    [self.optionButton setBackgroundImage:selectedIcon forState:UIControlStateSelected];
    [self.optionButton setTitle:description forState:UIControlStateNormal];
    self.optionButton.titleEdgeInsets = UIEdgeInsetsMake(0, 1.0, 0, BJLScToolViewFontIconSize);
    self.optionButton.titleLabel.font = [UIFont systemFontOfSize:BJLScToolViewDrawFontSize];
    self.optionButton.selected = selected;
}

- (void)updateContentWithOptionIcon:(UIImage *)icon
                       selectedIcon:(UIImage * _Nullable)selectedIcon
                        description:(NSString * _Nullable)description
                         isSelected:(BOOL)selected {
    // 如果要显示边框就不要显示背景色
    if (self.showSelectBorder) {
        self.optionButton.selectedColor = [UIColor clearColor];
    }
    
    [self.optionButton setImage:icon forState:UIControlStateNormal];
    [self.optionButton setImage:selectedIcon forState:UIControlStateSelected];
    [self.optionButton setTitle:description forState:UIControlStateNormal];
    self.optionButton.selected = selected;
    
    if (self.showSelectBorder) {
        UIColor *borderColor = selected ? [UIColor whiteColor] : [UIColor clearColor];
        CGFloat borderWidth = selected ? 2.0 : 0.0;
        self.optionButton.layer.borderColor = borderColor.CGColor;
        self.optionButton.layer.borderWidth = borderWidth;
    }
}


@end

NS_ASSUME_NONNULL_END
