//
//  BJLIcUserSeatCell.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/28.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcUserSeatCell.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserSeatCell ()

// placehoder
@property (nonatomic) UIView *placeholderView;
@property (nonatomic) UIImageView *placeholderImageView;
@property (nonatomic) UILabel *placeholderTipLabel, *placeholderNameLabel;
@property (nonatomic) UIView *placeholderGroupView;

// media info
@property (nonatomic, readwrite) UIView *mediaInfoContainerView;

@end

@implementation BJLIcUserSeatCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        bjl_weakify(self);
        [self bjl_kvo:BJLMakeProperty(self, reuseIdentifier)
             observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 if (self.reuseIdentifier) {
                     [self setupSubviews];
                     [self prepareForReuse];
                     return NO;
                 }
                 return YES;
             }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *subView in self.mediaInfoContainerView.subviews) {
        [subView removeFromSuperview];
    }
}

#pragma mark - subviews

- (void)setupSubviews {    
    BOOL enlargeVideo = [self.reuseIdentifier isEqualToString:cellReuseIdentifierFor1to1];
    CGFloat videoRatio = 3.0 / 4.0;
    // 占位视图
    self.placeholderView = ({
        UIView *view = [[UIView alloc] init];
        view.backgroundColor =  [UIColor bjl_colorWithHex:0X313847];
        view.userInteractionEnabled = NO;
        view.accessibilityLabel = BJLKeypath(self, placeholderView);
        bjl_return view;
    });
    [self.contentView addSubview:self.placeholderView];
    [self.placeholderView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        if (enlargeVideo) {
            make.left.right.top.equalTo(self.contentView);
            make.height.equalTo(self.placeholderView.bjl_width).multipliedBy(videoRatio);
        }
        else {
            make.edges.equalTo(self.contentView);
        }
    }];
        
    self.placeholderImageView = ({
        UIImage *image = [UIImage bjlic_imageNamed:@"bjl_ic_user_seat"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.accessibilityLabel = @"placeholderImageView";
        bjl_return imageView;
    });
    [self.placeholderView addSubview:self.placeholderImageView];
    [self.placeholderImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.placeholderView);
        make.centerY.equalTo(self.placeholderView).offset(-6);
        make.height.equalTo(self.bjl_height).multipliedBy(0.5);
        make.width.equalTo(self.placeholderImageView.bjl_height);
        make.height.width.lessThanOrEqualTo(@(BJLIcAppearance.userVideoPlaceholderImageMaxWidth)).priorityHigh();
        make.height.width.greaterThanOrEqualTo(@(BJLIcAppearance.userVideoPlaceholderImageMaxWidth)).priorityHigh();
    }];
    
    self.placeholderTipLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:1 alpha:0.5];
        label.alpha = 0.5;
        label.font = [UIFont systemFontOfSize:12.0];
        label.numberOfLines = 1;
        label.text = @"休息一下~";
        label.hidden = YES;
        label.accessibilityLabel = BJLKeypath(self, placeholderTipLabel);
        bjl_return label;
    });
    [self.placeholderView addSubview:self.placeholderTipLabel];
    [self.placeholderTipLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self.placeholderImageView.bjl_bottom);
        make.width.equalTo(self);
        make.height.equalTo(@(17));
    }];

    self.placeholderGroupView = ({
        UIView *view = [[UIView alloc] init];
        view.alpha = 0.6;
        view.accessibilityLabel = @"placeholderGroupView";
        bjl_return view;
    });
    [self.placeholderView addSubview:self.placeholderGroupView];
    [self.placeholderGroupView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        if (enlargeVideo) {
            make.left.right.equalTo(self.placeholderView);
            make.top.equalTo(self.placeholderView.bjl_bottom);
            make.height.equalTo(@40.0);
        }
        else {
            make.left.bottom.right.equalTo(self.placeholderView);
            make.height.equalTo(@20.0);
        }
    }];
    
    self.placeholderNameLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12.0];
        label.numberOfLines = 1;
        label.accessibilityLabel = BJLKeypath(self, placeholderNameLabel);
        bjl_return label;
    });
    [self.placeholderGroupView addSubview:self.placeholderNameLabel];
    [self.placeholderNameLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.greaterThanOrEqualTo(self.placeholderGroupView);
        make.right.lessThanOrEqualTo(self.placeholderGroupView);
        make.center.equalTo(self.placeholderGroupView);
        make.height.equalTo(@14.0);
    }];
    
    self.mediaInfoContainerView = ({
        UIView *view = [[UIView alloc] init];
        // 单击 离开/回到 座位
        bjl_weakify(self);
        UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
            bjl_strongify(self);
            if (self.singleTapCallback) {
                self.singleTapCallback();
            }
        }];
        [self.contentView addGestureRecognizer:tapGesture];
        view.accessibilityLabel = BJLKeypath(self, mediaInfoContainerView);
        view;
    });
    [self.contentView addSubview:self.mediaInfoContainerView];
    [self.mediaInfoContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        if (enlargeVideo) {
            make.top.left.right.equalTo(self.contentView);
            make.bottom.equalTo(self.contentView).offset(-40.0);
        }
        else {
            make.edges.equalTo(self.contentView);
        }
    }];
}

#pragma mark - public

- (void)updateContentWithUser:(nullable BJLUser *)user leavSeat:(BOOL)leaveSeat isTeacher:(BOOL)isTeacher {
    // 占位视图
    self.placeholderView.hidden = !leaveSeat;
    self.placeholderNameLabel.text = (user && ![self.reuseIdentifier isEqualToString:cellReuseIdentifierFor1to1]) ? [NSString stringWithFormat:@"%@的座位", user.displayName] : nil;
    if (!user && isTeacher) {
        self.placeholderImageView.image = [UIImage bjlic_imageNamed:@"bjl_ic_noteacher"];
    }
    else {
        self.placeholderImageView.image = [UIImage bjlic_imageNamed:@"bjl_ic_user_seat"];
    }
    self.placeholderGroupView.hidden = !user;
    self.placeholderTipLabel.hidden = user || !isTeacher;
}

@end

NS_ASSUME_NONNULL_END
