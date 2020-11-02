//
//  BJLIcToolbarViewController+phone1to1.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/7/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolbarViewController+phone1to1.h"
#import "BJLIcToolbarViewController+private.h"

@implementation BJLIcToolbarViewController (phone1to1)

- (void)makePhone1to1Subviews {
    self.backgroundView = ({
        UIView *view = [UIView new];
        view.backgroundColor = BJLIcTheme.statusBackgroungColor;;
        view.accessibilityLabel = BJLKeypath(self, backgroundView);
        view.userInteractionEnabled = NO;
        view;
    });
    
    // 老师教具
    self.teachingAidSelectView = ({
        BJLIcTeachingAidSelectView *view = [[BJLIcTeachingAidSelectView alloc] initWithRoom:self.room];
        view.hidden = YES;
        bjl_weakify(self);
        view.countDownCallback = ^(void) {
            bjl_strongify(self);
            [self hideTeachingAid];
            if (self.countDownCallback) {
                self.countDownCallback();
            }
        };

        view.openWebViewCallback = ^(void) {
            bjl_strongify(self);
            [self hideTeachingAid];
            if (self.openWebViewCallback) {
                self.openWebViewCallback();
            }
        };
        bjl_return view;
    });
}

- (void)remakePhone1to1ContainerViewForTeacherOrAssistantWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {    
    UIView *view = nil;
    if (self.requestReferenceViewCallback) {
        view = self.requestReferenceViewCallback();
    }
    if (!view) {
        return;
    }

    [self.view addSubview:self.backgroundView];
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.view addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.view.bjl_bottom).multipliedBy(3.0/4.0);
        make.centerX.equalTo(self.backgroundView);
        make.width.equalTo(@(BJLIcAppearance.toolbarButtonWidth));
    }];
    
    [self remakePhone1to1ConstraintsWithOptionButtons:optionButtons];
    [self remakePhone1to1ConstraintsWithMediaButtons:mediaButtons];
    
    if (self.teachingAidButton.superview) {
        [view addSubview:self.teachingAidSelectView];
        CGFloat teachingAidOptionWidth = 50.0;
        CGFloat teachingAidOptionHeight = 54.0;
        CGSize teachingAidSelectViewSize = CGSizeMake(teachingAidOptionWidth * 2 + 8.0 * 3,
                                                      teachingAidOptionHeight * 1 + 10.0 * 2);
        [self.teachingAidSelectView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.backgroundView.bjl_right).offset(1.0);
            make.centerY.equalTo(self.teachingAidButton).priorityHigh();
            make.top.greaterThanOrEqualTo(self.view);
            make.bottom.lessThanOrEqualTo(self.view);
            make.size.equal.sizeOffset(teachingAidSelectViewSize).priorityHigh();
        }];
    }

    [self.containerView addSubview:self.userListRedDot];
    [self.userListRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.userListButton.imageView);
        make.left.equalTo(self.userListButton.imageView.bjl_right).offset(-3.0);
        make.height.width.equalTo(@(BJLIcAppearance.toolbarRedDotSize));
    }];
    
    [self.containerView addSubview:self.chatListRedDot];
    [self.chatListRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.chatListButton.imageView);
        make.left.equalTo(self.chatListButton.imageView.bjl_right).offset(-3.0);
        make.height.width.equalTo(@(BJLIcAppearance.toolbarRedDotSize));
    }];
}

- (void)remakePhone1to1ContainerViewForStudentWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    [self.view addSubview:self.backgroundView];
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.view addSubview:self.speakRequestButton];
    [self.speakRequestButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.height.equalTo(@(BJLIcAppearance.speakRequestButtonWidth));
        make.bottom.equalTo(self.view).offset(-BJLIcAppearance.toolbarButtonSpace);
        make.centerX.equalTo(self.backgroundView).priorityHigh();
        make.left.greaterThanOrEqualTo(self.view);
    }];
    [self.view addSubview:self.speakRequestProgressView];
    [self.speakRequestProgressView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.speakRequestButton);
    }];
    self.needSpeakRequestBackground = YES;
    
    [self.view addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.equalTo(self.speakRequestButton.bjl_top).offset(-BJLIcAppearance.toolbarButtonSpace);
        make.centerX.equalTo(self.backgroundView);
        make.width.equalTo(@(BJLIcAppearance.toolbarButtonWidth));
    }];
    
    [self remakePhone1to1ConstraintsWithOptionButtons:optionButtons];
    [self remakePhone1to1ConstraintsWithMediaButtons:mediaButtons];
    
    [self.view addSubview:self.chatListRedDot];
    [self.chatListRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.chatListButton.imageView);
        make.left.equalTo(self.chatListButton.imageView.bjl_right).offset(-3.0);
        make.height.width.equalTo(@(BJLIcAppearance.toolbarRedDotSize));
    }];
}

- (void)remakePhone1to1ConstraintsWithMediaButtons:(NSArray *)buttons {
    UIButton *lastMediaButton = nil;
    for (UIButton *button in buttons) {
        [self.containerView addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.right.centerX.equalTo(self.containerView);
            make.height.equalTo(button.bjl_width);
            if (lastMediaButton) {
                make.top.equalTo(lastMediaButton.bjl_bottom).offset(BJLIcAppearance.toolbarButtonSpace - 2 * BJLIcAppearance.toolbarButtonImageInset);
            }
            else {
                make.top.equalTo(self.containerView);
            }
            if (button == buttons.lastObject) {
                make.bottom.equalTo(self.containerView);
            }
        }];
        lastMediaButton = button;
    }
}

- (void)remakePhone1to1ConstraintsWithOptionButtons:(NSArray *)buttons {
    UIButton *lastButton = nil;
    for (UIButton *button in buttons) {
        [self.view addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.right.centerX.equalTo(self.containerView);
            make.height.equalTo(button.bjl_width);
            make.top.equalTo(lastButton.bjl_bottom ?: self.view).offset(BJLIcAppearance.toolbarButtonSpace - 2 * BJLIcAppearance.toolbarButtonImageInset);
        }];
        lastButton = button;
    }
}

@end
