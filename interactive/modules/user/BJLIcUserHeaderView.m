//
//  BJLIcUserHeaderView.m
//  BJLiveUI
//
//  Created by 辛亚鹏 on 2020/6/10.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcUserHeaderView.h"
#import "BJLIcAppearance.h"

@interface BJLIcUserHeaderView()

@property (nonatomic) BJLIcUserHeaderType type;
@property (nonatomic) UIStackView *stackView;
// 上下的分割线
@property (nonatomic) UIView *topLineView, *bottomLineView;
@property (nonatomic, readwrite) UILabel *titleLabel;
@property (nonatomic, readwrite) BOOL isExpand;
// 展开按钮
@property (nonatomic) UIButton *expandButton;
// 解除所有黑名单按钮
@property (nonatomic, readwrite) UIButton *freeBlockedUserButton;

@end

@implementation BJLIcUserHeaderView

- (instancetype)initWithHeaderTppe:(BJLIcUserHeaderType)type {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.type = type;
        [self setupViews:type];
    }
    return self;
}

- (void)updateExpand:(BOOL)isExpand {
    self.isExpand = isExpand;
    self.stackView.hidden = !isExpand;
    self.expandButton.hidden = isExpand;
    self.titleLabel.font = isExpand ? [UIFont boldSystemFontOfSize:14.0] : [UIFont systemFontOfSize:14.0];
    if (self.type == BJLIcUserHeaderTypeBlockedUser) {
        self.stackView.hidden = YES;
        self.freeBlockedUserButton.hidden = !isExpand;
        self.bottomLineView.hidden = !isExpand;
        self.topLineView.hidden = isExpand;
    }
    else if (self.type == BJLIcUserHeaderTypeOnStage) {
        self.topLineView.hidden = YES;
        self.bottomLineView.hidden = !isExpand;
    }
}

- (void)setupViews:(BJLIcUserHeaderType)type {
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(expandAction)];
    [self addGestureRecognizer:tap];
    
    // titleLabel
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, titleLabel);
        label.textColor = BJLIcTheme.viewTextColor;
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self addSubview:self.titleLabel];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self).offset(BJLIcAppearance.userViewMaxSpace);
        make.top.equalTo(self).offset(BJLIcAppearance.userViewSmallSpace);
        make.bottom.equalTo(self).offset(-BJLIcAppearance.userViewSmallSpace);
        make.width.equalTo(@(BJLIcAppearance.userHeaderTitleWidth));
    }];
    
    // foldButton
    self.expandButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_userlist_expand"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(expandAction) forControlEvents:UIControlEventTouchUpInside];
        button.userInteractionEnabled = NO;
        button.hidden = YES;
        button;
    });
    [self addSubview:self.expandButton];
    [self.expandButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.titleLabel.bjl_right).offset(BJLIcAppearance.userViewMediumSpace);
        make.top.bottom.equalTo(self.titleLabel);
        make.width.equalTo(@50);
    }];
    
    // stack view
    self.stackView = ({
        UIStackView *view = [[UIStackView alloc] initWithArrangedSubviews:[self arrangedSubviewsWithType:type]];
        view.axis = UILayoutConstraintAxisHorizontal;
        view.distribution = UIStackViewDistributionFillEqually;
        view.alignment = UIStackViewAlignmentCenter;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            view.spacing = -10.0;
        }
        view;
    });
    [self addSubview:self.stackView];
    [self.stackView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.titleLabel.bjl_right).offset(BJLIcAppearance.userViewMaxSpace);
        make.top.bottom.equalTo(self.titleLabel);
        make.right.equalTo(self);
    }];
    
    // line view
    self.topLineView = [UIView bjlic_createSeparateLine];
    self.bottomLineView = [UIView bjlic_createSeparateLine];
    [self addSubview:self.topLineView];
    [self addSubview:self.bottomLineView];
    [self.topLineView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self).offset(1.0);
        make.right.equalTo(self).offset(-1.0);
        make.top.equalTo(self);
        make.height.equalTo(@0.5);
    }];
    [self.bottomLineView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.height.equalTo(self.topLineView);
        make.bottom.equalTo(self);
    }];
    
    if(type == BJLIcUserHeaderTypeBlockedUser) {
        self.freeBlockedUserButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_userlist_lock"] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(freeBlockedAction) forControlEvents:UIControlEventTouchUpInside];
            button.hidden = YES;
            button;
        });
        [self addSubview:self.freeBlockedUserButton];
        [self.freeBlockedUserButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self).offset(-2*BJLIcAppearance.userViewMaxSpace);
            make.centerY.equalTo(self);
            make.width.height.equalTo(@(BJLIcAppearance.userCellButtonSize));
        }];
    }
}

- (void)expandAction {
    if (self.expandCallback) {
        self.expandCallback();
    }
}

- (void)freeBlockedAction {
    if (self.freeBlockedCallback) {
        self.freeBlockedCallback();
    }
}

#pragma mark -

- (NSArray <UILabel *> *)arrangedSubviewsWithType:(BJLIcUserHeaderType)type {
    NSMutableArray <UILabel *> *arrM = [NSMutableArray array];
    if (type == BJLIcUserHeaderTypeOnStage) {
        NSArray *onStageArray = @[@"奖励", @"摄像头", @"麦克风", @"画笔", @"PPT", @"聊天", @"屏幕分享", @"上下台", @"拉黑"];
        for (NSString *text in onStageArray) {
             [arrM addObject:[self labelWith:text]];
        }
        
    }
    else if (type == BJLIcUserHeaderTypeDownStage) {
        NSArray *downStageArray = @[@"奖励", @"画笔", @"PPT", @"聊天", @"屏幕分享", @"上下台", @"拉黑"];
        for (NSString *text in downStageArray) {
             [arrM addObject:[self labelWith:text]];
        }
    }
    return arrM.copy;
}

- (UILabel *)labelWith:(NSString *)text {
    UILabel *label = [UILabel new];
    label.text = text;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = BJLIcTheme.viewTextColor;
    label.font = [UIFont systemFontOfSize:12.0];
    return label;
}

@end
