//
//  BJLIcToolbarViewController+phoneUserVideoUpside.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolbarViewController+phoneUserVideoUpside.h"
#import "BJLIcToolbarViewController+private.h"

@implementation BJLIcToolbarViewController (phoneUserVideoUpside)

- (void)makePhoneUserVideoUpsideSubviews {
    // iphone 只有 containerView 是模糊效果
    self.backgroundView = ({
        UIView *view = [UIView new];
        view.backgroundColor = BJLIcTheme.toolboxBackgroundColor;;
        view.accessibilityLabel = BJLKeypath(self, backgroundView);
        view.layer.cornerRadius = BJLIcAppearance.toolbarCornerRadius;
        view.layer.masksToBounds = NO;
        view.layer.borderColor = [UIColor bjl_colorWithHex:0XDDDDDD alpha:0.1].CGColor;
        view.layer.borderWidth = 1.0;
        view.layer.shadowRadius = 5.0;
        view.layer.shadowColor = BJLIcTheme.windowShadowColor.CGColor;
        view.layer.shadowOffset = CGSizeMake(0, 0);
        view.layer.shadowOpacity = 1;
        view.userInteractionEnabled = NO;
        view;
    });
    // 菜单使用单独的模糊效果
    self.menuBackgroundView = ({
        UIView *view = [UIView new];
        view.backgroundColor = BJLIcTheme.toolboxBackgroundColor;
        view.accessibilityLabel = BJLKeypath(self, menuBackgroundView);
        view.layer.cornerRadius = BJLIcAppearance.toolbarCornerRadius;
        view.layer.masksToBounds = NO;
        view.layer.borderColor = [UIColor bjl_colorWithHex:0XDDDDDD alpha:0.1].CGColor;
        view.layer.borderWidth = 1.0;
        view.layer.shadowRadius = 5.0;
        view.layer.shadowColor = BJLIcTheme.windowShadowColor.CGColor;
        view.layer.shadowOffset = CGSizeMake(0, 0);
        view.layer.shadowOpacity = 1;
        view.userInteractionEnabled = NO;
        view;
    });
    self.menuButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, menuButton);
        // 由于菜单按钮用于显示背景，因此菜单按钮的大小需要大些，实际图片的大小和 toolbarButtonSize 一致，因此需要设置 inset
        CGFloat offset = BJLIcAppearance.toolbarButtonImageInset;
        button.imageEdgeInsets = UIEdgeInsetsMake(offset, offset, offset, offset);
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = BJLIcAppearance.toolbarCornerRadius;
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_menu_normal"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_menu_selected"] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(updatePhoneUserVideoUpsideContainerViewHidden) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    self.singleLine = [UIView bjlic_createSeparateLine];
}

- (void)remakePhoneUserVideoUpsideContainerViewForTeacherOrAssistantWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    // 先添加背景
    [self.view addSubview:self.backgroundView];
    // 添加 containerView
    [self.view addSubview:self.containerView];
    // 添加菜单背景
    [self.view addSubview:self.menuBackgroundView];
    // 最后添加菜单
    [self.menuButton addSubview:self.menuRedDot];
    [self.view addSubview:self.menuButton];
    // 先布局 containerView 和背景
    [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.height.equalTo(@(BJLIcAppearance.toolbarButtonWidth));
        make.right.equalTo(self.view).offset(-BJLIcAppearance.toolbarOffset);
        make.bottom.equalTo(self.view).offset(-BJLIcAppearance.toolbarSmallSpace);
        make.width.equalTo(@(BJLIcAppearance.toolbarOffset * 2 + (BJLIcAppearance.toolbarButtonSize + BJLIcAppearance.toolbarButtonSpace)  * (optionButtons.count + mediaButtons.count + 1))).priorityHigh();
    }];
    [self.backgroundView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
    // 添加并且布局按钮
    [self remakePhoneUserVideoUpsideConstraintsWithMediaButtons:mediaButtons];
    [self remakePhoneUserVideoUpsideConstraintsWithOptionButtons:optionButtons];
    // 分割线
    [self.containerView addSubview:self.singleLine];
    UIView *lastButton = mediaButtons.lastObject;
    [self.singleLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(lastButton.bjl_right).offset(BJLIcAppearance.toolbarButtonSpace - BJLIcAppearance.toolbarButtonImageInset);
        make.height.equalTo(@(BJLIcAppearance.toolbarLineLength));
        make.width.equalTo(@1.0);
        make.centerY.equalTo(self.containerView);
    }];
    // 最后布局菜单和菜单背景
    [self.menuButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.containerView);
        make.centerY.equalTo(self.containerView);
        make.width.height.equalTo(@(BJLIcAppearance.toolbarButtonWidth));
    }];
    [self.menuRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.menuButton).offset(BJLIcAppearance.toolbarRedDotSize);
        make.left.equalTo(self.menuButton.bjl_right).offset(-3.0);
        make.height.width.equalTo(@(BJLIcAppearance.toolbarRedDotSize));
    }];
    [self.menuBackgroundView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.menuButton);
    }];
    if (!self.isPhoneToolbarInitialized) {
        // 初始化时显示操作菜单
        self.isPhoneToolbarInitialized = YES;
        [self updatePhoneUserVideoUpsideContainerViewHidden];
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

- (void)remakePhoneUserVideoUpsideContainerViewForStudentWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    // 举手按钮超过toolbar的界限，放到父视图层级
    UIView *view = nil;
    if (self.requestReferenceViewCallback) {
        view = self.requestReferenceViewCallback();
    }
    if (!view) {
        return;
    }
    // 先添加背景
    [self.view addSubview:self.backgroundView];
    // 添加 containerView
    [self.view addSubview:self.containerView];
    // 添加菜单背景
    [self.view addSubview:self.menuBackgroundView];
    // 添加菜单
    [self.view addSubview:self.menuButton];
    // 举手按钮
    [view addSubview:self.speakRequestButton];
    [self.speakRequestButton addSubview:self.speakRequestProgressView];
    
    // 先布局 containerView 和背景
    [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.height.equalTo(@(BJLIcAppearance.toolbarButtonWidth));
        make.right.equalTo(self.view).offset(-BJLIcAppearance.toolbarOffset);
        make.bottom.equalTo(self.view).offset(-BJLIcAppearance.toolbarSmallSpace);
        make.width.equalTo(@(BJLIcAppearance.toolbarOffset * 2 + (BJLIcAppearance.toolbarButtonSize + BJLIcAppearance.toolbarButtonSpace)  * (optionButtons.count + mediaButtons.count + 1))).priorityHigh();
    }];
    [self.backgroundView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
    // 添加并且布局按钮
    [self remakePhoneUserVideoUpsideConstraintsWithMediaButtons:mediaButtons];
    [self remakePhoneUserVideoUpsideConstraintsWithOptionButtons:optionButtons];
    // 分割线
    [self.containerView addSubview:self.singleLine];
    UIView *lastButton = mediaButtons.lastObject;
    [self.singleLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(lastButton.bjl_right).offset(BJLIcAppearance.toolbarButtonSpace - BJLIcAppearance.toolbarButtonImageInset);
        make.height.equalTo(@(BJLIcAppearance.toolbarLineLength));
        make.width.equalTo(@1.0);
        make.centerY.equalTo(self.containerView);
    }];
    // 最后布局菜单和菜单背景
    [self.menuButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.containerView);
        make.centerY.equalTo(self.containerView);
        make.width.height.equalTo(@(BJLIcAppearance.toolbarButtonWidth));
    }];
    [self.menuBackgroundView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.menuButton);
    }];
    if (!self.isPhoneToolbarInitialized) {
        // 初始化时显示操作菜单
        self.isPhoneToolbarInitialized = YES;
        [self updatePhoneUserVideoUpsideContainerViewHidden];
    }
    // 举手
    [self.speakRequestButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.menuButton);
        make.width.height.equalTo(@(BJLIcAppearance.speakRequestButtonWidth));
        make.bottom.equalTo(self.menuButton.bjl_top).offset(-BJLIcAppearance.toolbarSmallSpace);
    }];
    [self.speakRequestProgressView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.speakRequestButton);
    }];
    self.needSpeakRequestBackground = YES;
    
    [self.containerView addSubview:self.chatListRedDot];
    [self.chatListRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.chatListButton.imageView);
        make.left.equalTo(self.chatListButton.imageView.bjl_right).offset(-3.0);
        make.height.width.equalTo(@(BJLIcAppearance.toolbarRedDotSize));
    }];
}

- (void)updatePhoneUserVideoUpsideContainerViewHidden {
    NSMutableArray<UIButton *> *buttons = [@[/*self.speakerButton,*/
                                                 self.microphoneButton,
                                                 self.cameraButton,
                                                 self.eyeProtectedButton,
                                                 self.blackboardLayoutButton,
                                                 self.cloudRecordingButton,
                                                 self.unmuteAllMicrophoneButton,
                                                 self.muteAllMicrophoneButton,
                                                 self.forbidSpeakRequestButton,
                                                 self.userListButton,
                                                 self.homeworkButton,
                                                 self.chatListButton] mutableCopy];
    // 非云端录制不显示录制按钮
    if (self.room.featureConfig.cloudRecordType != BJLServerRecordingType_cloud) {
        [buttons removeObject:self.cloudRecordingButton];
    }
    
    switch (self.room.loginUser.role) {
        case BJLUserRole_teacher:
            [buttons removeObject:self.homeworkButton];
            break;
            
        case BJLUserRole_assistant:
            [buttons removeObjectsInArray:@[self.blackboardLayoutButton, self.homeworkButton]];
            break;
            
        case BJLUserRole_student:
        {
            if (!self.room.featureConfig.enableHomework) {
                [buttons removeObject:self.homeworkButton];
            }
            [buttons removeObjectsInArray:@[self.blackboardLayoutButton, self.cloudRecordingButton, self.unmuteAllMicrophoneButton,self.muteAllMicrophoneButton, self.forbidSpeakRequestButton, self.userListButton]];
        }
            break;
            
        default:
            buttons = nil;
            break;
    }
    self.menuButton.selected = !self.menuButton.isSelected;
    if (self.menuButton.isSelected) {
        // 显示菜单项时，显示模糊效果
        self.backgroundView.hidden = NO;
        self.menuBackgroundView.hidden = YES;
        self.containerView.hidden = NO;
        self.menuRedDot.hidden = YES;
        [self.containerView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.width.equalTo(@(BJLIcAppearance.toolbarOffset * 2 + (BJLIcAppearance.toolbarButtonSize + BJLIcAppearance.toolbarButtonSpace)  * (buttons.count + 1))).priorityHigh();
        }];
    }
    else {
        // 隐藏菜单项时，显示菜单按钮单独的模糊效果
        self.backgroundView.hidden = YES;
        self.menuBackgroundView.hidden = NO;
        self.containerView.hidden = YES;
        [self.containerView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.width.equalTo(@(BJLIcAppearance.toolbarButtonWidth)).priorityHigh();
        }];
    }
}

- (void)remakePhoneUserVideoUpsideConstraintsWithMediaButtons:(NSArray *)buttons {
    UIButton *lastMediaButton = nil;
    for (UIButton *button in buttons) {
        [self.containerView addSubview:button];
        // iphone 布局基于 containerview
        [button bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.bottom.centerY.equalTo(self.containerView);
            make.width.equalTo(button.bjl_height);
            if (lastMediaButton) {
                make.left.equalTo(lastMediaButton.bjl_right).offset(BJLIcAppearance.toolbarButtonSpace - 2 * BJLIcAppearance.toolbarButtonImageInset);
            }
            else {
                make.left.equalTo(self.containerView.bjl_left).offset(BJLIcAppearance.toolbarOffset);
            }
        }];
        lastMediaButton = button;
    }
}

- (void)remakePhoneUserVideoUpsideConstraintsWithOptionButtons:(NSArray *)buttons {
    UIButton *lastButton = nil;
    for (UIButton *button in [buttons reverseObjectEnumerator]) {
        [self.containerView addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            // iphone 按钮没有标题，宽高相等
            make.top.bottom.centerY.equalTo(self.containerView);
            if (lastButton) {
                make.right.equalTo(lastButton.bjl_left).offset(-(BJLIcAppearance.toolbarButtonSpace - 2 * BJLIcAppearance.toolbarButtonImageInset));
            }
            else {
                make.right.equalTo(self.containerView.bjl_right).offset(-(BJLIcAppearance.toolbarButtonWidth + BJLIcAppearance.toolbarButtonSpace - 2 * BJLIcAppearance.toolbarButtonImageInset));
            }
            make.width.equalTo(button.bjl_height);
        }];
        lastButton = button;
    }
}

@end
