//
//  BJLIcToolbarViewController+pad1to1.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/7/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolbarViewController+pad1to1.h"
#import "BJLIcToolbarViewController+private.h"

@implementation BJLIcToolbarViewController (pad1to1)

- (void)remakePad1to1ContainerViewForTeacherOrAssistantWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    UIView *referenceView;
    if (self.requestReferenceViewCallback) {
        referenceView = self.requestReferenceViewCallback();
    }
    if (!referenceView) {
        return;
    }
    [self.view addSubview:self.exitButton];
    [self.exitButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.view).offset(BJLIcAppearance.toolboxButtonSize + BJLIcAppearance.toolboxButtonSpace);
        make.centerY.equalTo(self.view);
        make.width.height.equalTo(@(BJLIcAppearance.toolbarButtonSize));
    }];
    [self remakePad1to1ConstraintsWithMediaButtons:mediaButtons];
    
    [referenceView addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.equalTo(referenceView).offset(-(BJLIcAppearance.toolboxButtonSize + BJLIcAppearance.toolboxButtonSpace));
        make.height.equalTo(@(BJLIcAppearance.toolbarButtonSize));
        make.right.equalTo(referenceView.bjl_right).offset(-BJLIcAppearance.toolbarButtonSpace);
        make.width.equalTo(@(optionButtons.count * BJLIcAppearance.toolbarButtonSize + (optionButtons.count - 1) * BJLIcAppearance.toolbarButtonSpace));
    }];
    [self remakePad1to1ConstraintsWithOptionButtons:optionButtons];
    
    [self.containerView addSubview:self.userListRedDot];
    [self.userListRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.userListButton.imageView);
        make.left.equalTo(self.userListButton.imageView.bjl_right).offset(-12.0);
        make.height.width.equalTo(@(BJLIcAppearance.toolbarRedDotSize));
    }];
    
    [self.containerView addSubview:self.chatListRedDot];
    [self.chatListRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.chatListButton.imageView);
        make.left.equalTo(self.chatListButton.imageView.bjl_right).offset(-6.0);
        make.height.width.equalTo(@(BJLIcAppearance.toolbarRedDotSize));
    }];
}

- (void)remakePad1to1ContainerViewForStudentWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    UIView *referenceView;
    if (self.requestReferenceViewCallback) {
        referenceView = self.requestReferenceViewCallback();
    }
    if (!referenceView) {
        return;
    }
    [self.view addSubview:self.exitButton];
    [self.exitButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.view).offset(BJLIcAppearance.toolboxButtonSize + BJLIcAppearance.toolboxButtonSpace);
        make.centerY.equalTo(self.view);
        make.width.height.equalTo(@(BJLIcAppearance.toolbarButtonSize));
    }];
    [self remakePad1to1ConstraintsWithMediaButtons:mediaButtons];
    
    [referenceView addSubview:self.speakRequestButton];
    [self.speakRequestButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(referenceView.bjl_right).offset(-BJLIcAppearance.toolbarButtonSpace);
        make.width.height.equalTo(@(BJLIcAppearance.speakRequestButtonWidth));
    }];
    [self.speakRequestButton addSubview:self.speakRequestProgressView];
    [self.speakRequestProgressView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.speakRequestButton);
    }];
    
    [referenceView addSubview:self.chatListButton];
    [self.chatListButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.speakRequestButton.bjl_left).offset(-BJLIcAppearance.toolbarButtonSpace);
        make.width.height.equalTo(@(BJLIcAppearance.toolbarButtonSize));
        make.bottom.equalTo(referenceView).offset(-(BJLIcAppearance.toolboxButtonSize + BJLIcAppearance.toolboxButtonSpace));
        make.centerY.equalTo(self.speakRequestButton.bjl_centerY);
    }];
    [referenceView addSubview:self.chatListRedDot];
    [self.chatListRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.chatListButton.imageView);
        make.left.equalTo(self.chatListButton.imageView.bjl_right).offset(-6.0);
        make.height.width.equalTo(@(BJLIcAppearance.toolbarRedDotSize));
    }];
    
    if (self.room.featureConfig.enableHomework) {
        [referenceView addSubview:self.homeworkButton];
        [self.homeworkButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.chatListButton.bjl_left).offset(-BJLIcAppearance.toolbarButtonSpace);
            make.width.height.equalTo(@(BJLIcAppearance.toolbarButtonSize));
            make.bottom.equalTo(referenceView).offset(-(BJLIcAppearance.toolboxButtonSize + BJLIcAppearance.toolboxButtonSpace));
            make.centerY.equalTo(self.speakRequestButton.bjl_centerY);
        }];
    }
}

- (void)remakePad1to1ConstraintsWithMediaButtons:(NSArray *)buttons {
    UIButton *lastMediaButton = nil;
    for (UIButton *button in [buttons reverseObjectEnumerator]) {
        [self.view addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.equalTo(self.view);
            make.width.height.equalTo(@(BJLIcAppearance.toolbarButtonSize));
            make.right.equalTo(lastMediaButton.bjl_left ?: self.view).offset(-BJLIcAppearance.toolbarButtonSpace);
        }];
        lastMediaButton = button;
    }
}

- (void)remakePad1to1ConstraintsWithOptionButtons:(NSArray *)buttons {
    UIButton *lastButton = nil;
    for (UIButton *button in [buttons reverseObjectEnumerator]) {
        [self.containerView addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.equalTo(self.containerView);
            make.width.height.equalTo(@(BJLIcAppearance.toolbarButtonSize));
            if (lastButton) {
                make.right.equalTo(lastButton.bjl_left).offset(-BJLIcAppearance.toolbarButtonSpace);
            }
            else {
                make.right.equalTo(self.containerView);
            }
            if (lastButton == buttons.firstObject) {
                make.left.equalTo(self.containerView.bjl_left);
            }
        }];
        lastButton = button;
    }
}

@end
