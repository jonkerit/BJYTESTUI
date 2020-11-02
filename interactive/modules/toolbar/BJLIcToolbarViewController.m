//
//  BJLIcToolbarViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcToolbarViewController.h"
#import "BJLIcToolbarViewController+private.h"
#import "BJLIcToolbarViewController+padUserVideoUpside.h"
#import "BJLIcToolbarViewController+phoneUserVideoUpside.h"
#import "BJLIcToolbarViewController+phone1to1.h"
#import "BJLIcToolbarViewController+pad1to1.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcToolbarViewController 

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    bjl_weakify(self);
    self.view = [BJLHitTestView viewWithTitTestBlock:^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
        bjl_strongify(self);
        if ([hitView isKindOfClass:[UIButton class]]
            || [hitView isKindOfClass:[UICollectionView class]]) {
            return hitView;
        }
        
        // 点击toolbar空白区域可以关闭教具工具箱
        if (self.teachingAidButton.selected) {
            [self hideTeachingAid];
            return hitView;
        }

        return nil;
    }];
    
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    [self makeSubviews];
#if DEBUG
    [self makeDebugSubviewsAndConstraints];
#endif
    [self makeObserving];
}

- (void)didMoveToParentViewController:(nullable UIViewController *)parent {
    // 布局和父视图有关，因此不能在 viewdidload 中布局，需要在此方法中布局，而此方法会调用多次，需要使用 remake 来正确布局
    [super didMoveToParentViewController:parent];
    if (parent) {
        if (self.room.loginUser.isStudent) {
            [self remakeContainerViewForStudent];
        }
        else {
            [self remakeContainerViewForTeacherOrAssistant:self.room.loginUser.isAssistant];
        }
    }
}

- (void)makeSubviews {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    
    self.containerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view;
    });
    if (iPhone) {
        // iphone 通过 backgroundview 设置背景色
        if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
            [self makePhone1to1Subviews];
        }
        else {
            [self makePhoneUserVideoUpsideSubviews];
        }
    }
    else {
        // ipad 直接设置背景色
        self.view.backgroundColor = BJLIcTheme.statusBackgroungColor;
    }
    self.exitButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_statusbar_exit"]
                              selectedImage:nil
                         accessibilityLabel:BJLKeypath(self, exitButton)];
    self.speakerButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_toolbar_speaker_normal"]
                                 selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_speaker_selected"]
                            accessibilityLabel:BJLKeypath(self, speakerButton)];
    self.microphoneButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_toolbar_microphone_normal"]
                                    selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_microphone_selected"]
                               accessibilityLabel:BJLKeypath(self, microphoneButton)];
    self.cameraButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_toolbar_camera_normal"]
                                selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_camera_selected"]
                           accessibilityLabel:BJLKeypath(self, cameraButton)];
    self.eyeProtectedButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_ic_eyeProtected_close"]
                                selectedImage:[UIImage bjlic_imageNamed:@"bjl_ic_eyeProtected_open"]
                                 accessibilityLabel:BJLKeypath(self, eyeProtectedButton)];

    self.blackboardLayoutButton = [self makeButtonWithTitle:@"板书布局"
                                              selectedTitle:nil
                                                      image:[UIImage bjlic_imageNamed:@"bjl_toolbar_boardlayout_normal"]
                                              selectedImage:nil
                                         accessibilityLabel:BJLKeypath(self, blackboardLayoutButton)];
    self.gallerylayoutButton = [self makeButtonWithTitle:@"画廊布局"
                                           selectedTitle:nil
                                                   image:[UIImage bjlic_imageNamed:@"bjl_toolbar_gallerylayout_normal"]
                                           selectedImage:nil
                                      accessibilityLabel:BJLKeypath(self, gallerylayoutButton)];
    self.cloudRecordingButton = [self makeButtonWithTitle:@"录制课程"
                                            selectedTitle:@"录制中..."
                                                    image:[UIImage bjlic_imageNamed:@"bjl_toolbar_cloudrecording_normal"]
                                            selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_cloudrecording_selected"]
                                       accessibilityLabel:BJLKeypath(self, cloudRecordingButton)];
    self.unmuteAllMicrophoneButton = [self makeButtonWithTitle:@"全体开麦"
                                                 selectedTitle:nil
                                                         image:[UIImage bjlic_imageNamed:@"bjl_toolbar_unmuteallmicrophone"]
                                                 selectedImage:nil
                                            accessibilityLabel:BJLKeypath(self, unmuteAllMicrophoneButton)];
    self.muteAllMicrophoneButton = [self makeButtonWithTitle:@"全体关麦"
                                               selectedTitle:nil
                                                       image:[UIImage bjlic_imageNamed:@"bjl_toolbar_muteallmicrophone"]
                                               selectedImage:nil
                                          accessibilityLabel:BJLKeypath(self, muteAllMicrophoneButton)];
    self.speakRequestButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_toolbar_speakrequest_normal"]
                                      selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_speakrequest_selected"]
                                 accessibilityLabel:BJLKeypath(self, speakRequestButton)];
    [self.speakRequestButton setImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_speakrequest_unable"] forState:UIControlStateDisabled];
    self.speakRequestProgressView = ({
        BJLAnnularProgressView *progressView = [BJLAnnularProgressView new];
        progressView.size = BJLIcAppearance.speakRequestButtonWidth;
        progressView.annularWidth = 2.0;
        progressView.color = [BJLIcTheme brandColor];
        progressView.userInteractionEnabled = NO;
        progressView;
    });
    self.forbidSpeakRequestButton = [self makeButtonWithTitle:@"禁止举手"
                                                selectedTitle:@"允许举手"
                                                        image:[UIImage bjlic_imageNamed:@"bjl_toolbar_forbidspeakrequest_normal"]
                                                selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_forbidspeakrequest_selected"]
                                           accessibilityLabel:BJLKeypath(self, forbidSpeakRequestButton)];
    [self.forbidSpeakRequestButton setTitleColor:BJLIcTheme.toolButtonTitleColor forState:UIControlStateSelected];
    [self.forbidSpeakRequestButton setTitleColor:BJLIcTheme.toolButtonTitleColor forState:UIControlStateHighlighted];
    [self.forbidSpeakRequestButton setTitleColor:BJLIcTheme.toolButtonTitleColor forState:UIControlStateHighlighted | UIControlStateSelected];

    self.userListButton = [self makeButtonWithTitle:@"用户列表"
                                      selectedTitle:nil
                                              image:[UIImage bjlic_imageNamed:@"bjl_toolbar_userlist_normal"]
                                      selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_userlist_selected"]
                                 accessibilityLabel:BJLKeypath(self, userListButton)];
    self.chatListButton = [self makeButtonWithTitle:@"聊天"
                                      selectedTitle:nil
                                              image:[UIImage bjlic_imageNamed:@"bjl_toolbar_chat_normal"]
                                      selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_chat_selected"]
                                 accessibilityLabel:BJLKeypath(self, chatListButton)];
    self.homeworkButton = [self makeButtonWithTitle:nil
                                      selectedTitle:nil
                                              image:[UIImage bjlic_imageNamed:@"bjl_toolbar_homework_normal"]
                                      selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_homework_selected"]
                                 accessibilityLabel:BJLKeypath(self, homeworkButton)];
    self.coursewareButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_toolbox_courseware_normal"]
                                    selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_courseware_selected"]
                               accessibilityLabel:BJLKeypath(self, coursewareButton)];
    self.teachingAidButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_toolbox_teachingaid_normal"]
                                     selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_teachingaid_selected"]
                                accessibilityLabel:BJLKeypath(self, teachingAidButton)];
    [self.teachingAidButton addTarget:self action:@selector(showTeachingAid) forControlEvents:UIControlEventTouchUpInside];
    self.userListRedDot = [self makeRedDotWithSize:(iPhone || (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType)) ? BJLIcAppearance.toolbarRedDotSize : BJLIcAppearance.toolbarRedLabelSize];
    self.chatListRedDot = [self makeRedDotWithSize:BJLIcAppearance.toolbarRedDotSize];
    self.menuRedDot = [self makeRedDotWithSize:BJLIcAppearance.toolbarRedDotSize];
}

#pragma mark - teacher style

- (void)remakeContainerViewForTeacherOrAssistant:(BOOL)isAssistant {
    [self clearToolbar];

    // 媒体控制按钮
    NSArray *mediaButtons = [self mediaButtons];
    // 一般操作按钮
    NSMutableArray<UIButton *> *optionButtons = [@[self.blackboardLayoutButton,
                                                 self.cloudRecordingButton,
                                                 self.unmuteAllMicrophoneButton,
                                                 self.muteAllMicrophoneButton,
                                                 self.forbidSpeakRequestButton,
                                                 self.userListButton,
                                                 self.chatListButton] mutableCopy];

    // 助教不显示布局切换按钮
    if (isAssistant) {
        [optionButtons removeObject:self.blackboardLayoutButton];
    }
    
    // 非云端录制不显示录制按钮
    if (self.room.featureConfig.cloudRecordType != BJLServerRecordingType_cloud) {
        [optionButtons removeObject:self.cloudRecordingButton];
    }
    
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        // 1v1 无布局切换，静音，禁止举手等控制
        if (iPhone) {
            NSMutableArray<UIButton *> *options = isAssistant ? [@[self.coursewareButton, self.cloudRecordingButton, self.userListButton, self.chatListButton] mutableCopy] : [@[self.coursewareButton, self.teachingAidButton, self.cloudRecordingButton, self.userListButton, self.chatListButton] mutableCopy];
            if (self.room.featureConfig.cloudRecordType != BJLServerRecordingType_cloud) {
                [options removeObject:self.cloudRecordingButton];
            }
            [self remakePhone1to1ContainerViewForTeacherOrAssistantWithMediaButtons:mediaButtons optionButtons:options];
        }
        else {
            NSArray *options = @[self.cloudRecordingButton, self.userListButton, self.chatListButton];
            if (self.room.featureConfig.cloudRecordType != BJLServerRecordingType_cloud) {
                options = @[self.userListButton, self.chatListButton];
            }
            [self remakePad1to1ContainerViewForTeacherOrAssistantWithMediaButtons:mediaButtons optionButtons:options];
        }
    }
    else {
        if (iPhone) {
            [self remakePhoneUserVideoUpsideContainerViewForTeacherOrAssistantWithMediaButtons:mediaButtons optionButtons:optionButtons];
        }
        else {
            [self remakePadUserVideoUpsideContainerViewForTeacherOrAssistantWithMediaButtons:mediaButtons optionButtons:optionButtons];
        }
        // version 1
        if (!isAssistant) {
            // 老师显示布局切换按钮
            [self.containerView addSubview:self.gallerylayoutButton];
            self.gallerylayoutButton.hidden = YES;
            [self.gallerylayoutButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.blackboardLayoutButton);
            }];
        }
    }
}

- (NSArray *)mediaButtons {
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        return @[/*self.speakerButton,*/
                self.eyeProtectedButton,
                self.microphoneButton,
                self.cameraButton];
    }
    else {
        return @[/*self.speakerButton,*/
                self.microphoneButton,
                self.cameraButton,
                self.eyeProtectedButton];
    }
}

#pragma mark - student style

- (void)remakeContainerViewForStudent {
    [self clearToolbar];
    // 学生只有音视频按钮，举手和聊天单独布局
    NSArray *mediaButtons = [self mediaButtons];
    NSArray *optionButtons = @[self.chatListButton];
    
    if (self.room.featureConfig.enableHomework) {
        optionButtons = @[self.chatListButton, self.homeworkButton];
    }
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        if (iPhone) {
            [self remakePhone1to1ContainerViewForStudentWithMediaButtons:mediaButtons optionButtons:optionButtons];
        }
        else {
            [self remakePad1to1ContainerViewForStudentWithMediaButtons:mediaButtons optionButtons:optionButtons];
        }
    }
    else {
        if (iPhone) {
            if (self.room.featureConfig.enableHomework) {// 这里为了处理UI上的顺序
                optionButtons = @[self.homeworkButton, self.chatListButton];
            }
            [self remakePhoneUserVideoUpsideContainerViewForStudentWithMediaButtons:mediaButtons optionButtons:optionButtons];
        }
        else {
            [self remakePadUserVideoUpsideContainerViewForStudentWithMediaButtons:mediaButtons optionButtons:optionButtons];
        }
    }
}

#pragma mark - clear

- (void)clearToolbar {
    NSArray *toolbarArray = @[
                              self.mediaBackgroundView ?: [NSNull null],
                              self.menuBackgroundView ?: [NSNull null],
                              self.containerView ?: [NSNull null],
                              self.teacherMediaInfoContainerView ?: [NSNull null],
                              self.backgroundView ?: [NSNull null],
                              self.exitButton ?: [NSNull null],
                              self.menuButton ?: [NSNull null],
                              self.microphoneButton ?: [NSNull null],
                              self.cameraButton ?: [NSNull null],
                              self.eyeProtectedButton ?: [NSNull null],
                              self.singleLine ?: [NSNull null],
                              self.blackboardLayoutButton ?: [NSNull null],
                              self.gallerylayoutButton ?: [NSNull null],
                              self.cloudRecordingButton ?: [NSNull null],
                              self.unmuteAllMicrophoneButton ?: [NSNull null],
                              self.muteAllMicrophoneButton ?: [NSNull null],
                              self.forbidSpeakRequestButton ?: [NSNull null],
                              self.speakRequestButton ?: [NSNull null],
                              self.speakRequestProgressView ?: [NSNull null],
                              self.userListButton ?: [NSNull null],
                              self.chatListButton ?: [NSNull null],
                              self.homeworkButton ?: [NSNull null],
                              self.coursewareButton ?: [NSNull null],
                              self.teachingAidButton ?: [NSNull null],
                              self.userListRedDot ?: [NSNull null],
                              self.chatListRedDot ?: [NSNull null],
                              self.menuRedDot ?: [NSNull null]];
    for (UIView *view in toolbarArray) {
        if ([view respondsToSelector:@selector(removeFromSuperview)]) {
            [view removeFromSuperview];
        }
    }
}

#pragma mark - observers

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, recordingAudio)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        self.microphoneButton.selected = now.boolValue;
        self.speakRequestButton.enabled = !now.boolValue && !self.room.speakingRequestVM.forbidSpeakingRequest;
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, recordingVideo)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        self.cameraButton.selected = now.boolValue;
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, forbidSpeakingRequest)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        // 老师
        self.forbidSpeakRequestButton.selected = now.boolValue;
        
        // 学生
        self.speakRequestButton.enabled = !self.room.recordingVM.recordingAudio && !now.boolValue;
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, speakingRequestTimeRemaining)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(NSNumber * _Nullable timeRemaining, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        return timeRemaining.doubleValue != old.doubleValue;
    }
         observer:^BOOL(NSNumber * _Nullable timeRemaining, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (timeRemaining.doubleValue <= 0.0) {
            self.speakRequestProgressView.progress = 0.0;
            self.speakRequestButton.selected = NO;
        }
        else {
            CGFloat progress = timeRemaining.doubleValue / self.room.speakingRequestVM.speakingRequestTimeoutInterval; // 1.0 ~ 0.0
            self.speakRequestProgressView.progress = progress;
        }
        return YES;
    }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self, needSpeakRequestBackground),
                         BJLMakeProperty(self.speakRequestButton, selected),
                         BJLMakeProperty(self.speakRequestButton, enabled)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        // 举手操作属于禁用状态时不展示背景圆,更加突出不可操作
        if (self.speakRequestButton.selected || (self.needSpeakRequestBackground && self.speakRequestButton.enabled)) {
            [self.speakRequestButton bjlic_drawCircleBackgroundViewWithColor:[UIColor bjl_colorWithHex:0X9FA8B5 alpha:0.3] hidden:NO];
        }
        else {
            [self.speakRequestButton bjlic_drawCircleBackgroundViewWithColor:[UIColor clearColor] hidden:YES];
        }
    }];
    
    if (self.room.serverRecordingVM && self.room.loginUser.isTeacherOrAssistant && self.room.featureConfig.cloudRecordType == BJLServerRecordingType_cloud) {
        [self bjl_kvo:BJLMakeProperty(self.room.serverRecordingVM, serverRecording)
             observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            self.cloudRecordingButton.selected = now.boolValue;
            if (now.boolValue && !self.isCloudRecordingInitialized) {
                self.isCloudRecordingInitialized = YES;
                [self tryToShowCloudRecordingTipView];
            }
            return YES;
        }];
    }
    
    [self bjl_kvo:BJLMakeProperty(self.userListRedDot, hidden) observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.userListRedDot.hidden) {
            [self.speakingRequeatTipViewController dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            [self showSpeakingRequestTip];
        }
        return YES;
    }];
}

#pragma mark - actions

- (void)tryToShowCloudRecordingTipView {
    if (!self.shouldShowCloudRecordingTipView || !self.isCloudRecordingInitialized) {
        self.shouldShowCloudRecordingTipView = YES;
        return;
    }
    if (!self.room.serverRecordingVM.serverRecording) {
        return;
    }
    self.shouldShowCloudRecordingTipView = NO;
    self.cloudRecordingTipViewController = ({
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view.backgroundColor = [UIColor clearColor];
        viewController.modalPresentationStyle = UIModalPresentationPopover;
        viewController.preferredContentSize = CGSizeMake(360.0, 117.0);
        viewController.popoverPresentationController.backgroundColor = BJLIcTheme.toolboxBackgroundColor;
        viewController.popoverPresentationController.delegate = self;
        viewController.popoverPresentationController.sourceView = self.cloudRecordingButton;
        viewController.popoverPresentationController.sourceRect = self.cloudRecordingButton.bounds;
        viewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
        viewController;
    });
    UILabel *tipLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.backgroundColor = [UIColor clearColor];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 14.0;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentLeft;
        NSDictionary *attributedDic = @{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                        NSForegroundColorAttributeName : BJLIcTheme.toolButtonTitleColor,
                                        NSParagraphStyleAttributeName : paragraphStyle};
        label.attributedText = [[NSAttributedString alloc] initWithString:@"云端录制已开启 \n云端录制直接在云端服务器录课，本地不保存录\n课文件，课程结束后10分钟自动生成课程回放" attributes:attributedDic];
        label;
    });
    [self.cloudRecordingTipViewController.view addSubview:tipLabel];
    [tipLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.cloudRecordingTipViewController.view.bjl_safeAreaLayoutGuide ?: self.cloudRecordingTipViewController.view).insets(UIEdgeInsetsMake(10.0, 20.0, 0.0, 20.0));
    }];
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:self.cloudRecordingTipViewController animated:YES completion:nil];
}

- (void)showSpeakingRequestTip {
    
    BJLButton *handupTipButton = ({
        BJLButton *button = [BJLButton buttonWithType:UIButtonTypeCustom];
        button.midSpace = 6.0;
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_speakrequest_tip"] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
        // 当只有1个人的时候, 显示 xxx正在举手; 当有多个人举手的时候, 显示 N名学生正在举手
        NSInteger count = self.room.speakingRequestVM.speakingRequestUsers.count;
        NSString *countOrNameString = @"";
        NSString *tipString = @"";
        if (count == 1) {
            countOrNameString = self.room.speakingRequestVM.speakingRequestUsers.firstObject.displayName;
            tipString = [NSString stringWithFormat:@"%@正在举手",countOrNameString];
        }
        else if (count > 1){
            countOrNameString = [NSString stringWithFormat:@"%td",count];
            tipString = [NSString stringWithFormat:@"%@名学生正在举手",countOrNameString];
        }
        NSMutableAttributedString *tipAttributedString = [[NSMutableAttributedString alloc] initWithString:tipString];
        [tipAttributedString addAttributes:@{NSForegroundColorAttributeName : [UIColor bjl_colorWithHexString:@"#FFAE00"]} range:NSMakeRange(0, countOrNameString.length)];
        [tipAttributedString addAttributes:@{NSForegroundColorAttributeName : BJLIcTheme.viewSubTextColor} range:NSMakeRange(countOrNameString.length, tipString.length - countOrNameString.length)];
        [button setAttributedTitle:tipAttributedString forState:UIControlStateNormal];
        bjl_return button;
    });
    
    CGSize labelZize = [self bjlic_suitableSizeWithText:nil attributedText:handupTipButton.titleLabel.attributedText maxWidth:300];
    self.speakingRequeatTipViewController = ({
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view.backgroundColor = [UIColor clearColor];
        viewController.modalPresentationStyle = UIModalPresentationPopover;
        viewController.preferredContentSize = CGSizeMake(labelZize.width + 80.0, 45.0);
        viewController.popoverPresentationController.backgroundColor = [BJLIcTheme toolboxBackgroundColor];
        viewController.popoverPresentationController.delegate = self;
        viewController.popoverPresentationController.sourceView = self.userListButton;
        viewController.popoverPresentationController.sourceRect = self.userListButton.bounds;
        viewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
        viewController;
    });
    [self.speakingRequeatTipViewController.view addSubview:handupTipButton];
    [handupTipButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.speakingRequeatTipViewController.view.bjl_safeAreaLayoutGuide ?: self.speakingRequeatTipViewController.view).insets(UIEdgeInsetsMake(5.0, 10.0, 5.0, 10.0));
    }];
    
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:self.speakingRequeatTipViewController animated:YES completion:nil];
    bjl_weakify(self);
    [handupTipButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.handupTipCallback) {
            self.handupTipCallback();
        }
        
    }];
}

- (void)hideCloudRecordingViewController {
    [self.cloudRecordingViewController bjl_dismissAnimated:YES completion:nil];
}

- (void)showTeachingAid {
    if (self.chatListButton.selected) {
        [self.chatListButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    
    if (self.userListButton.selected) {
        [self.userListButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }

    self.teachingAidButton.selected = !self.teachingAidButton.selected;
    self.teachingAidSelectView.hidden = !self.teachingAidButton.selected;
}

- (void)hideTeachingAid {
    self.teachingAidButton.selected = NO;
    self.teachingAidSelectView.hidden = YES;
}

#if DEBUG
- (void)makeDebugSubviewsAndConstraints {
    self->_widgetButton = [self makeButtonWithTitle:@"hide widget"
                                      selectedTitle:@"show widget"
                                              image:nil
                                      selectedImage:nil
                                 accessibilityLabel:BJLKeypath(self, widgetButton)];
    self->_settingsButton = [self makeButtonWithTitle:@"hide settings"
                                        selectedTitle:@"show settings"
                                                image:nil
                                        selectedImage:nil
                                   accessibilityLabel:BJLKeypath(self, settingsButton)];
    self->_fullscreenButton = [self makeButtonWithTitle:@"hide fullscreen"
                                          selectedTitle:@"show fullscreen"
                                                  image:nil
                                          selectedImage:nil
                                     accessibilityLabel:BJLKeypath(self, fullscreenButton)];
    self->_popoversButton = [self makeButtonWithTitle:@"hide popovers"
                                        selectedTitle:@"show popovers"
                                                image:nil
                                        selectedImage:nil
                                   accessibilityLabel:BJLKeypath(self, popoversButton)];
//    UIButton *last = nil;
//    for (UIButton *button in @[self.widgetButton,
//                               self.settingsButton,
//                               self.fullscreenButton,
//                               self.popoversButton]) {
//        [self.view addSubview:button];
//        [button bjl_makeConstraints:^(BJLConstraintMaker *make) {
//            make.top.equalTo(last.bjl_bottom ?: self.view);
//            make.right.equalTo(self.view).inset(5.0);
//            if (last) make.width.height.equalTo(last);
//        }];
//        last = button;
//    }
//    [last bjl_makeConstraints:^(BJLConstraintMaker *make) {
//        make.bottom.equalTo(self.view);
//    }];
}

#endif

#pragma mark - wheel

- (UIButton *)makeImageButton:(nullable UIImage *)image
                selectedImage:(nullable UIImage *)selectedImage
           accessibilityLabel:(nullable NSString *)accessibilityLabel {
    UIButton *button = [BJLImageButton new];
    button.accessibilityLabel = accessibilityLabel;
    button.layer.masksToBounds = YES;
    CGFloat inset = BJLIcAppearance.toolbarButtonImageInset;
    button.imageEdgeInsets = UIEdgeInsetsMake(inset, inset, inset, inset);
    if (image) {
        [button setImage:image forState:UIControlStateNormal];
    }
    if (selectedImage) {
        [button setImage:selectedImage forState:UIControlStateSelected];
        [button setImage:selectedImage forState:UIControlStateHighlighted];
        [button setImage:selectedImage forState:UIControlStateSelected | UIControlStateHighlighted];
    }
    return button;
}

- (UIButton *)makeButtonWithTitle:(nullable NSString *)title selectedTitle:(nullable NSString *)selectedTitle
                            image:(nullable UIImage *)image selectedImage:(nullable UIImage *)selectedImage
               accessibilityLabel:(nullable NSString *)accessibilityLabel {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    BOOL needTitle = !iPhone && BJLIcTemplateType_1v1 != self.room.roomInfo.interactiveClassTemplateType;
    UIButton *button = needTitle ? [BJLVerticalButton new] : [BJLImageButton new];
    button.layer.masksToBounds = YES;
    button.accessibilityLabel = accessibilityLabel;
    button.titleLabel.font = [UIFont systemFontOfSize:14.0];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    // !!!: 仅 ipad 非 1v1 小班课有标题，要注意在外部修改标题的时候判断是否是 iphone
    if (title && needTitle) {
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:BJLIcTheme.toolButtonTitleColor forState:UIControlStateNormal];
    }
    if (selectedTitle && needTitle) {
        [button setTitle:selectedTitle forState:UIControlStateSelected];
        [button setTitle:selectedTitle forState:UIControlStateHighlighted];
        [button setTitle:selectedTitle forState:UIControlStateHighlighted | UIControlStateSelected];
        [button setTitleColor:[BJLIcTheme brandColor] forState:UIControlStateSelected];
        [button setTitleColor:[BJLIcTheme brandColor] forState:UIControlStateHighlighted];
        [button setTitleColor:[BJLIcTheme brandColor] forState:UIControlStateHighlighted | UIControlStateSelected];
    }
    if (!needTitle) {
        CGFloat inset = BJLIcAppearance.toolbarButtonImageInset;
        button.imageEdgeInsets = UIEdgeInsetsMake(inset, inset, inset, inset);
    }
    if (image) {
        [button setImage:image forState:UIControlStateNormal];
    }
    if (selectedImage) {
        [button setImage:selectedImage forState:UIControlStateSelected];
        [button setImage:selectedImage forState:UIControlStateHighlighted];
        [button setImage:selectedImage forState:UIControlStateHighlighted | UIControlStateSelected];
    }
    return button;
}

- (UILabel *)makeRedDotWithSize:(CGFloat)size {
    CGFloat fontSize = size / 2.0;
    UILabel *view = [UILabel new];
    view.hidden = YES;
    view.layer.masksToBounds = YES;
    view.layer.cornerRadius = fontSize;
    view.backgroundColor = BJLIcTheme.warningColor;
    view.textColor = fontSize < BJLIcAppearance.toolbarRedDotSize ? [UIColor clearColor] : [UIColor whiteColor];
    view.textAlignment = NSTextAlignmentCenter;
    view.adjustsFontSizeToFitWidth = YES;
    view.font = [UIFont systemFontOfSize:fontSize];
    return view;
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

@end

NS_ASSUME_NONNULL_END
