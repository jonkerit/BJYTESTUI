//
//  BJLIcToolbarViewController+padUserVideoUpside.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolbarViewController+padUserVideoUpside.h"
#import "BJLIcToolbarViewController+private.h"

@implementation BJLIcToolbarViewController (padUserVideoUpside)

- (void)remakePadUserVideoUpsideContainerViewForTeacherOrAssistantWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    // 优先布局媒体控制按钮
    [self remakePadUserVideoUpsideConstraintsWithMediaButtons:mediaButtons];
    // ipad 的 containerView 仅包括一般操作按钮
    [self.view addSubview:self.containerView];
    [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.height.equalTo(@(BJLIcAppearance.toolbarButtonWidth));
        make.left.greaterThanOrEqualTo(self.cameraButton.bjl_right);
        make.right.centerY.equalTo(self.view);
        make.width.equalTo(@((BJLIcAppearance.toolbarButtonWidth + BJLIcAppearance.toolbarLargeSpace)  * optionButtons.count)).priorityHigh();
    }];
    // 布局一般操作按钮
    [self remakePadUserVideoUpsideConstraintsWithOptionButtons:optionButtons];

    [self.containerView addSubview:self.userListRedDot];
    [self.userListRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.userListButton.imageView);
        make.left.equalTo(self.userListButton.imageView.bjl_right).offset(-6.0);
        make.height.width.equalTo(@(BJLIcAppearance.toolbarRedLabelSize));
    }];
    
    [self.containerView addSubview:self.chatListRedDot];
    [self.chatListRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.chatListButton.imageView);
        make.left.equalTo(self.chatListButton.imageView.bjl_right).offset(-6.0);
        make.height.width.equalTo(@(BJLIcAppearance.toolbarRedDotSize));
    }];
}

- (void)remakePadUserVideoUpsideContainerViewForStudentWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    [self remakePadUserVideoUpsideConstraintsWithMediaButtons:mediaButtons];
    // 举手按钮
    [self.view addSubview:self.speakRequestButton];
    [self.speakRequestButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.width.equalTo(@(BJLIcAppearance.speakRequestButtonWidth));
        make.centerY.equalTo(self.view);
        make.right.equalTo(self.view).offset(-BJLIcAppearance.toolbarButtonSpace);
    }];
    [self.speakRequestButton addSubview:self.speakRequestProgressView];
    [self.speakRequestProgressView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.speakRequestButton);
    }];
    // 学生的聊天按钮没有标题
    [self.chatListButton setTitle:nil forState:UIControlStateNormal];
    [self.chatListButton setTitle:nil forState:UIControlStateHighlighted];
    [self.chatListButton setTitle:nil forState:UIControlStateSelected];
    [self.chatListButton setTitle:nil forState:UIControlStateHighlighted | UIControlStateSelected];
    [self.view addSubview:self.chatListButton];
    [self.chatListButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.width.equalTo(@(BJLIcAppearance.toolbarLargeSpace));
        make.right.equalTo(self.speakRequestButton.bjl_left).offset(-BJLIcAppearance.toolbarMediumSpace);
        make.centerY.equalTo(self.view);
    }];
    [self.view addSubview:self.chatListRedDot];
    [self.chatListRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.chatListButton.imageView);
        make.left.equalTo(self.chatListButton.imageView.bjl_right).offset(-6.0);
        make.height.width.equalTo(@(BJLIcAppearance.toolbarRedDotSize));
    }];
    
    if (self.room.featureConfig.enableHomework) {
        [self.view addSubview:self.homeworkButton];
        [self.homeworkButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.width.equalTo(@(BJLIcAppearance.toolbarLargeSpace));
            make.right.equalTo(self.chatListButton.bjl_left).offset(-BJLIcAppearance.toolbarMediumSpace);
            make.centerY.equalTo(self.view);
        }];
    }
}

- (void)remakePadUserVideoUpsideConstraintsWithMediaButtons:(NSArray *)buttons {
    UIButton *lastMediaButton = nil;
    for (UIButton *button in buttons) {
        [self.view addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            // ipad 布局基于整个 view
            make.height.width.equalTo(@(BJLIcAppearance.toolbarButtonSize)).priorityHigh();
            make.left.greaterThanOrEqualTo(lastMediaButton.bjl_right?:self.view.bjl_left);
            if (lastMediaButton) {
                make.left.equalTo(lastMediaButton.bjl_right).offset(BJLIcAppearance.toolbarButtonSpace).priorityHigh();
            }
            else {
                make.left.equalTo(self.view.bjl_left).offset(BJLIcAppearance.toolbarButtonSpace).priorityHigh();
            }
            make.centerY.equalTo(self.view);
        }];
        lastMediaButton = button;
    }
}

- (void)remakePadUserVideoUpsideConstraintsWithOptionButtons:(NSArray *)buttons {
    UIButton *lastButton = nil;
    for (UIButton *button in [buttons reverseObjectEnumerator]) {
        [self.containerView addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.top.bottom.equalTo(self.containerView);
            // ipad 按钮相对 containerView
            if (lastButton) {
                make.width.equalTo(lastButton);
                make.right.lessThanOrEqualTo(lastButton.bjl_left);
            }
            else {
                make.width.equalTo(@(BJLIcAppearance.toolbarButtonWidth)).priorityHigh();
                make.right.lessThanOrEqualTo(self.containerView);
            }
        }];
        lastButton = button;
    }
}

@end
