//
//  BJLIcRoomViewController+actions.m
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import "BJLIcRoomViewController+actions.h"
#import "BJLIcRoomViewController+private.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcRoomViewController (actions)

- (void)makeActions {

    [self makeStatusBarViewControllerActions];
    
    [self makeBlackboardLayoutViewControllerActions];
    
    [self makeToolboxViewControllerActions];
    [self makeToolbarViewControllerActions];
    [self makeChatViewControllerActions];
    [self makeUserViewControllerActions];
    [self makeDocumentViewControllerActions];
    [self makeOtherActions];
    
    /* fire */
    
    [self switchToBlackboardLayout];
}

#pragma mark - status bar

- (void)makeStatusBarViewControllerActions {
    bjl_weakify(self);

    [self.statusBarViewController.exitButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self showExitPopoverViewController];
    }];
    
    [self.statusBarViewController.settingButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self showSettingViewController];
    }];
    
    [self.statusBarViewController setShowWeakNetworkTipCallback:^(NSInteger duration) {
        bjl_strongify(self);
        [self.promptViewController enqueueWithSpecialPrompt:@"当前网络状况差" duration:duration important:NO];
    }];
}

#pragma mark - black board

- (void)makeBlackboardLayoutViewControllerActions {
    bjl_weakify(self);
    [self.blackboardLayoutViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:message];
    }];
    [self.blackboardLayoutViewController setShowWritingBoardTimeInputViewControllerCallBack:^{
        bjl_strongify(self);
        BJLIcChatInputViewController *chatInputViewController = [[BJLIcChatInputViewController alloc] initWithText:@""];
        [self bjl_addChildViewController:chatInputViewController superview:self.popoversLayer];
        [chatInputViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.popoversLayer);
        }];
        [chatInputViewController setEditCallback:^(NSString * _Nonnull text) {
            bjl_strongify(self);
            [self.blackboardLayoutViewController setWritingBoardTime:text];
        }];
    }];
    [self.blackboardLayoutViewController setBlockUserCallback:^BOOL(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        return [self tryToBlockUser:user];
    }];
    [self.blackboardLayoutViewController setReceiveLikeCallback:^(BJLUser * _Nonnull user, UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self showLikeEffectViewController:BJLRoomLayout_blackboard user:user likeButton:button];
    }];
    [self.blackboardLayoutViewController setReceiveGroupLikeCallback:^(BOOL isGroup, NSString * groupName) {
        bjl_strongify(self);
        [self showLikeEffectViewController:BJLRoomLayout_blackboard
                              isGroupAward:isGroup
                               showMessage:groupName];
    }];
    [self.blackboardLayoutViewController setWebviewControllerKeyboardFrameChangeCallback:^(CGRect keyboardFrame, UIView * _Nonnull overlayView) {
        bjl_strongify(self);
        [self updateOverlayViewWithKeyboardFrame:keyboardFrame overlayView:overlayView];
    }];
    [self.blackboardLayoutViewController setCloseWebviewControllerCallback:^{
        bjl_strongify(self);
        [self askToCloseWebViewController];
    }];
    [self.blackboardLayoutViewController setCloseQuestionAnswerControllerCallback:^{
        bjl_strongify(self);
        [self askToCloseQuestionAnswerController];
    }];
    [self.blackboardLayoutViewController setCloseQuizControllerCallback:^{
        bjl_strongify(self);
        [self askToCloseQuizController];
    }];
    [self.blackboardLayoutViewController setCancelQuizControllerCallback:^{
        bjl_strongify(self);
        [self cancelPopoverWithType:BJLIcCloseQuiz];
    }];
    [self.blackboardLayoutViewController setSwitchToNativePPTCallback:^(UIViewController<BJLSlideshowUI> * _Nullable viewController, void (^ _Nonnull callback)(BOOL)) {
        bjl_strongify(self);
        [self showSwitchToNativePPTWithDocumentVieController:viewController callback:callback];
    }];
    [self.blackboardLayoutViewController setUserMediaInfoViewsDidUpdateCallback:^(NSArray<BJLIcUserMediaInfoView *> * _Nullable userMediaInfoViews) {
        bjl_strongify(self);
        [self.videosGridLayoutViewController updateWithUserMediaInfoViews:userMediaInfoViews];
    }];
}

#pragma mark - toolbox

- (void)makeToolboxViewControllerActions {
    bjl_weakify(self);
    [self.toolboxViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (message.length) {
            [self.promptViewController enqueueWithPrompt:message];
        }
    }];
    [self.toolboxViewController.coursewareButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self enterCoursewareMode];
    }];
        
    // 小黑板
    [self.toolboxViewController setClickWritingBoardCallback:^{
        bjl_strongify(self);
        [self requsetAddWritingBoard];
    }];
    // 打开网页
    [self.toolboxViewController setOpenWebViewCallback:^{
        bjl_strongify(self);
        [self openWebView];
    }];
    // 计时器
    [self.toolboxViewController setCountDownCallback:^{
        bjl_strongify(self);
        [self openCountDown];
    }];
    // 抢答器
    [self.toolboxViewController setQuestionResponderCallback:^{
        bjl_strongify(self);
        [self openQuestionResponder];
    }];
    // 答题器
    [self.toolboxViewController setQuestionAnswerCallback:^{
        bjl_strongify(self);
        [self openQuestionAnswer];
    }];

    [self.toolboxViewController setHideSelectViewsCallback:^{
        bjl_strongify(self);
        [self.toolbarViewController hideTeachingAid];
    }];
}

#pragma mark - toolbar

- (void)makeToolbarViewControllerActions {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    bjl_weakify(self);
    
    [self.toolbarViewController.exitButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self showExitPopoverViewController];
    }];
    
    [self.toolbarViewController.eyeProtectedButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        self.toolbarViewController.eyeProtectedButton.selected = !self.toolbarViewController.eyeProtectedButton.selected;
        self.eyeProtectedLayer.hidden = !self.toolbarViewController.eyeProtectedButton.selected;
    }];
    
    [self.toolbarViewController.microphoneButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        BOOL on = !button.isSelected;
        [button bjl_disableForSeconds:BJLIcAppearance.robotDelayM];
        if (!self.room.loginUser.isTeacher && on) {
            BOOL isActive = NO;
            for (BJLMediaUser *user in [self.room.playingVM.playingUsers copy]) {
                if ([self.room.loginUser.number isEqualToString:user.number]) {
                    isActive = YES;
                    break;
                }
            }
            if (!isActive) {
                [self.promptViewController enqueueWithPrompt:@"未上台用户不能打开麦克风"];
            }
            else if (on && BJLIcTemplateType_1v1 != self.room.roomInfo.interactiveClassTemplateType && !self.room.loginUser.isTeacherOrAssistant) {
                [self.promptViewController enqueueWithPrompt:@"举手才能打开麦克风"];
            }
            else {
                [self updateRecordingAudio:on];
                if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType
                    && self.room.speakingRequestVM.speakingRequestTimeRemaining > 0.0) {
                    [self updateSpeakRequest:NO];
                }
            }
        }
        else {
            [self updateRecordingAudio:on];
        }
    }];
    
    [self.toolbarViewController.cameraButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        BOOL on = !button.isSelected;
        [button bjl_disableForSeconds:BJLIcAppearance.robotDelayM];
        if (!self.room.loginUser.isTeacher && on) {
            BOOL isActive = NO;
            for (BJLMediaUser *user in [self.room.playingVM.playingUsers copy]) {
                if ([self.room.loginUser.number isEqualToString:user.number]) {
                    isActive = YES;
                    break;
                }
            }
            if (!isActive) {
                [self.promptViewController enqueueWithPrompt:@"未上台用户不能打开摄像头"];
            }
            else {
                [self updateRecordingVideo:on];
            }
        }
        else {
            [self updateRecordingVideo:on];
        }
    }];
    
    [self.toolbarViewController.blackboardLayoutButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        // !!!: 交互已改，切换到画廊布局不收回窗口
        [self switchToGalleryLayout];
        // request update
        [self.room.roomVM updateRoomLayout:BJLRoomLayout_gallary];
    }];
    
    [self.toolbarViewController.gallerylayoutButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self switchToBlackboardLayout];
        // request update
        [self.room.roomVM updateRoomLayout:BJLRoomLayout_blackboard];
    }];
    
    [self.toolbarViewController.cloudRecordingButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        BOOL isSelected = button.isSelected;
        if (isSelected) {
            [self updateCloudRecording:NO];
            self.toolbarViewController.cloudRecordingButton.selected = NO;
            if (!iPhone && BJLIcTemplateType_1v1 != self.room.roomInfo.interactiveClassTemplateType) {
                [self.toolbarViewController.cloudRecordingButton setTitle:@"录制中..." forState:UIControlStateSelected];
            }
            return;
        }
        [self startCloudRecordingAfterCheckState];
    }];
        
    [self.toolbarViewController.coursewareButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        button.selected = !button.isSelected;
        [self enterCoursewareMode];
    }];
    
    [self.toolbarViewController setOpenWebViewCallback:^{
        bjl_strongify(self);
        [self openWebView];
    }];
    
    [self.toolbarViewController setCountDownCallback:^{
        bjl_strongify(self);
        [self openCountDown];
    }];

    [self.toolbarViewController.muteAllMicrophoneButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self updateAllRecordingAudioMute:YES];
    }];
    
    [self.toolbarViewController.unmuteAllMicrophoneButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self updateAllRecordingAudioMute:NO];
    }];
    
    [self.toolbarViewController.speakRequestButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        BOOL isSelected = button.isSelected;
        button.selected = [self updateSpeakRequest:!isSelected] ? !isSelected : isSelected;
    }];
    
    [self.toolbarViewController.forbidSpeakRequestButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        BOOL isSelected = button.isSelected;
        button.selected = [self updateForbidSpeakRequest:!isSelected] ? !isSelected : isSelected;
    }];
    
    [self.toolbarViewController.userListButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        button.selected = !button.isSelected;
        [self updateUserListHidden:!button.isSelected];
    }];
    
    [self.toolbarViewController setHandupTipCallback:^{
        bjl_strongify(self);
        self.toolbarViewController.userListButton.selected = !self.toolbarViewController.userListButton.isSelected;
        [self updateUserListHidden:!self.toolbarViewController.userListButton.isSelected];
    }];
    [self.toolbarViewController setCloseCloudRecordingCallback:^{
        bjl_strongify(self);
        [self updateCloudRecording:NO];
    }];
    [self.toolbarViewController.chatListButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        button.selected = !button.isSelected;
        [self updateChatListHidden:!button.isSelected];
    }];
    [self.toolbarViewController.homeworkButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self enterCoursewareMode];
    }];
    [self.requestSpeakinFullScreenButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        BOOL isSelected = button.isSelected;
        button.selected = [self updateSpeakRequest:!isSelected] ? !isSelected : isSelected;
    }];
}

#pragma mark - chat

- (void)makeChatViewControllerActions {
    bjl_weakify(self);
    [self.chatViewController setForbidChatCallback:^BOOL(BOOL forbid) {
        bjl_strongify(self);
        NSError *error = [self.room.chatVM sendForbidAll:forbid];
        if (error) {
            [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
        }
        return !error;
    }];
    [self.chatViewController setReceiveUnreadMessageCallback:^(NSArray<BJLMessage *> * _Nonnull unreadMessage) {
        bjl_strongify(self);
        if (!self.toolbarViewController.chatListButton.selected) {
            self.toolbarViewController.chatListRedDot.hidden = NO;
        }
    }];
    [self.chatViewController setCloseCallback:^{
        bjl_strongify(self);
        self.toolbarViewController.chatListButton.selected = NO;
        [self.chatViewController bjl_removeFromParentViewControllerAndSuperiew];
    }];
}

#pragma mark - user

- (void)makeUserViewControllerActions {
    bjl_weakify(self);
    [self.userViewController setForbidSpeakRequestCallback:^(BOOL forbid) {
        bjl_strongify(self);
        return [self updateForbidSpeakRequest:forbid];
    }];
    [self.userViewController setReceiveSpeakingRequestCallback:^(BJLUser * _Nonnull user, BOOL finish, NSInteger count) {
        bjl_strongify(self);
        if (!self.toolbarViewController.userListButton.selected) {
            self.toolbarViewController.userListRedDot.text = count > 99 ? @"99" : [NSString stringWithFormat:@"%td", count];
            self.toolbarViewController.userListRedDot.hidden = !count;
        }
        if (!self.toolbarViewController.menuButton.isSelected) {
            // 菜单隐藏时，红点显示到菜单上
            self.toolbarViewController.menuRedDot.hidden = !count;
            self.toolbarViewController.menuRedDot.text = count > 99 ? @"99" : [NSString stringWithFormat:@"%td", count];
        }
    }];
    [self.userViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:message];
    }];
    [self.userViewController setBlockUserCallback:^(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        [self tryToBlockUser:user];
    }];
    [self.userViewController setShowSwitchStageTipViewCallback:^{
        bjl_strongify(self);
        [self showSwitchStageTipView];
    }];
    [self.userViewController setShowFreeAllBlockedUserCallback:^{
        bjl_strongify(self);
        [self showFreeAllBlockedUserView];
    }];
    [self.userViewController setCloseCallback:^{
        bjl_strongify(self);
        self.toolbarViewController.userListButton.selected = NO;
        for (UIViewController *viewController in self.userViewController.childViewControllers) {
            [viewController bjl_removeFromParentViewControllerAndSuperiew];
        }
        [self.userViewController bjl_removeFromParentViewControllerAndSuperiew];
    }];
    [self.userViewController setReceiveLikeCallback:^(BJLUser * _Nonnull user) {
        [self showLikeEffectViewController:BJLRoomLayout_blackboard user:user likeButton:[UIButton new]];
    }];
}

#pragma mark - document

- (void)makeDocumentViewControllerActions {
    bjl_weakify(self);
    [self.documentFileManagerViewController setHideCallback:^{
           bjl_strongify(self);
           if (self.toolbarViewController.coursewareButton.isSelected) {
               self.toolbarViewController.coursewareButton.selected = NO;
           }
           if (self.toolboxViewController.coursewareButton.isSelected) {
               [self.toolboxViewController cancelCurrentSelectedButton];
           }
       }];
       [self.documentFileManagerViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
           bjl_strongify(self);
           [self.promptViewController enqueueWithPrompt:message];
       }];
       [self.documentFileManagerViewController setSelectDocumentFileCallback:^(BJLDocumentFile * _Nonnull documentFile, UIImage * _Nullable image) {
           bjl_strongify(self);
           if ([self.childViewControllers containsObject:self.blackboardLayoutViewController]) {
               if (documentFile.type == BJLDocumentFileImage) {
//                   if (!image) {
//                       return;
//                   }
//                   // !!!: 图片通过修改图片数据的方式之外改变过方向的情况，需要更新 size 数据
//                   BOOL needSwap = (image.imageOrientation == UIImageOrientationLeft || image.imageOrientation == UIImageOrientationRight || image.imageOrientation == UIImageOrientationLeftMirrored || image.imageOrientation == UIImageOrientationRightMirrored);
                   CGSize imageSize = /*needSwap ? CGSizeMake(documentFile.remoteDocument.pageInfo.height, documentFile.remoteDocument.pageInfo.width) : */CGSizeMake(documentFile.remoteDocument.pageInfo.width, documentFile.remoteDocument.pageInfo.height);
                   [self.blackboardLayoutViewController addImageShapeToBlackboardWithURL:documentFile.remoteDocument.pageInfo.pageURLString imageSize:imageSize];
               }
               else {
                   [self.blackboardLayoutViewController displayDocumentWindowWithID:documentFile.remoteDocument.documentID requestUpdate:YES];
               }
               [self.promptViewController enqueueWithPrompt:@"文件已打开, 请在黑板区查看"];
           }
       }];
}

#pragma mark - other

- (void)makeOtherActions {
    if (!self.expressViewController) {
        return;
    }
    bjl_weakify(self);
    [self.expressViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:message];
    }];
    [self.expressViewController setShowExpressExportCallback:^{
        bjl_strongify(self);
        if (self.presentedViewController) {
            [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
        }
        [self bjl_presentFullScreenViewController:self.expressViewController animated:YES completion:nil];
    }];
    [self.expressViewController setCloseCallback:^{
        bjl_strongify(self);
        [self.expressViewController bjl_dismissAnimated:YES completion:nil];
    }];
    if (self.shareExpressExportCallback) {
        [self.expressViewController setShareCallback:^(NSString *contentURLString, NSString *firstExpressURLString, NSString *userName) {
            bjl_strongify(self);
            self.shareExpressExportCallback(contentURLString, firstExpressURLString, userName);
        }];
    }
}

#pragma mark - status bar

/* 显示退出的弹框
 老师文案:@"正在关闭教室, 是否结束授课?"
 学生/助教文案:@"正在关闭教室, 是否退出教室?"
 */
- (void)showExitPopoverViewController {
    bjl_weakify(self);
    NSString *message = nil;
    if (self.room.loginUser.isTeacher) {
        message = @"正在关闭教室, 是否结束授课?";
    }
    else {
        message = @"正在关闭教室, 是否退出教室?";
    }
    BJLIcPopoverViewType type = BJLIcExitViewNormal;
    if (self.room.featureConfig.enableExpressExport && self.room.loginUser.isTeacher && self.room.roomVM.liveStarted) {
        // 仅老师有是否生成表情报告提示
        type = BJLIcExitViewAppend;
    }
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:type message:message];
    [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.popoversLayer);
    }];
    [popoverViewController setConfirmCallback:^{
        bjl_strongify(self);
        [self exit];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [popoverViewController setAppendCallback:^{
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:@"请求表情报告中，请稍候"];
        [self.room.roomVM sendLiveStarted:NO];
    }];
}

- (void)showSettingViewController {
    bjl_weakify(self);
    self.statusBarViewController.settingButton.enabled = NO;
    BJLIcSettingView *settingViiew = [[BJLIcSettingView alloc] initWithRoom:self.room];
    [self.popoversLayer addSubview:settingViiew];
    
    [settingViiew bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.widgetLayer);
        make.height.equalTo(@230);
        BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
        if (iPhone) {
            make.width.equalTo(self.view.bjl_width).multipliedBy(0.66);
        }
        else {
            make.width.equalTo(self.view.bjl_width).multipliedBy(0.5);
        }
    }];
    
    settingViiew.switchMirrorModeCallback = ^(BOOL isOn) {
        bjl_strongify(self);
        
        // 镜像翻转开关, 以下逻辑在 updatePreviewMirrorModel 里面判断
        // 关闭时 isOn = NO, 前置摄像头本地预览翻转、推流不翻转; 后置摄像头本地、推流都不翻转
        // 开启时 isOn = YES, 前置摄像头本地预览翻转、推流翻转; 后置摄像头本地、推流都翻转
        [self.room.recordingVM sendEncoderMirrorMode:isOn];
    };
    settingViiew.closeCallback = ^{
        bjl_strongify(self);
        self.statusBarViewController.settingButton.enabled = YES;
    };
    settingViiew.pptQualityChangeCallback = ^(BOOL isOriginal, BJLIcSettingView *view) {
        bjl_strongify(self);
        NSError *error = [self.room.documentVM pptQualityChange:isOriginal];
        if (error) {
            [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
            [view updateButtonStateWhenError];
        }
    };
}

#pragma mark - black board

- (void)showLikeEffectViewController:(BJLRoomLayout)layout user:(BJLUser *)user likeButton:(UIButton *)button {
    CGRect frame = [self.fullscreenLayer convertRect:button.frame fromView:button.superview];
    NSString *picture = @"";
    if (self.room.roomVM.awardKey.length > 0) {
        for (BJLAward *award in [BJLAward allAwards]) {
            if ([award.key isEqualToString:self.room.roomVM.awardKey]) {
                picture = award.picture;
                break;
            }
        }
    }
    BJLLikeEffectViewController *likeEffectViewController = [[BJLLikeEffectViewController alloc] initForInteractiveClassWithName:user.displayName endPoint:frame.origin imageUrlString:picture interactiveType:BJLInteractiveTypePersonAward];
    [self bjl_addChildViewController:likeEffectViewController superview:self.fullscreenLayer];
    [likeEffectViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.fullscreenLayer);
    }];
}

- (void)showLikeEffectViewController:(BJLRoomLayout)layout
                        isGroupAward:(BOOL)isGroupAward
                         showMessage:(NSString *)showMessage {
    showMessage = isGroupAward ? showMessage : @"台上奖励";
    BJLInteractiveType interactiveType = isGroupAward ? BJLInteractiveTypeGroupAward : BJLInteractiveTypeClassAward;
    BJLLikeEffectViewController *likeEffectViewController = [[BJLLikeEffectViewController alloc] initForInteractiveClassWithName:showMessage endPoint:CGPointZero interactiveType:interactiveType];
    [self bjl_addChildViewController:likeEffectViewController superview:self.fullscreenLayer];
    [likeEffectViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.fullscreenLayer);
    }];
}

- (void)showSwitchStageTipView {
    bjl_weakify(self);
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcSwitchStage];
    BOOL fullScreen = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (fullScreen) {
        [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
        [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.popoversLayer);
        }];
    }
    else {
        [self.userViewController bjl_addChildViewController:popoverViewController superview:self.userViewController.view];
        [popoverViewController updateEffectHidden:YES];
        [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.userViewController.view);
        }];
    }
    [popoverViewController setConfirmCallback:^{
        bjl_strongify(self);
        [self.userViewController switchToOnStageListTableView];
    }];
}

- (void)showFreeAllBlockedUserView {
    bjl_weakify(self);
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcFreeBlockedUser];
    BOOL fullScreen = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (fullScreen) {
        [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
        [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.popoversLayer);
        }];
    }
    else {
        [self.userViewController bjl_addChildViewController:popoverViewController superview:self.userViewController.view];
        [popoverViewController updateEffectHidden:YES];
        [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.userViewController.view);
        }];
    }
    // 解禁按钮在下面，因此 cancel 是确认
    [popoverViewController setCancelCallback:^{
        bjl_strongify(self);
        [self.room.onlineUsersVM freeAllBlockedUsers];
    }];
}

- (void)askToCloseWebViewController {
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcCloseWebPage];
    [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.popoversLayer);
    }];
    bjl_weakify(self);
    [popoverViewController setCancelCallback:^{
        bjl_strongify(self);
        [self.blackboardLayoutViewController closeWebViewController];
    }];
}

- (void)askToCloseQuizController {
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcCloseQuiz];
    [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.popoversLayer);
    }];
    bjl_weakify(self);
    [popoverViewController setConfirmCallback:^{
        bjl_strongify(self);
        [self.blackboardLayoutViewController closeQuizController];
        self.popoverViewController = nil;
    }];
    self.popoverViewController = popoverViewController;
}

- (void)cancelPopoverWithType:(BJLIcPopoverViewType)type {
    if (self.popoverViewController.type == type) {
        [self.popoverViewController bjl_removeFromParentViewControllerAndSuperiew];
    }
}

- (void)askToCloseCountDownController {
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcCloseWebPage];
    [self.blackboardLayoutViewController.countDownViewController bjl_addChildViewController:popoverViewController superview:self.blackboardLayoutViewController.countDownViewController.view];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.blackboardLayoutViewController.countDownViewController.view);
    }];
    bjl_weakify(self);
    [popoverViewController setCancelCallback:^{
        bjl_strongify(self);
        [self.blackboardLayoutViewController closeCountDownController];
    }];
}

- (void)askToCloseQuestionResponderController {
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcCloseWebPage];
    [self.blackboardLayoutViewController.questionResponderViewController bjl_addChildViewController:popoverViewController superview:self.blackboardLayoutViewController.questionResponderViewController.view];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.blackboardLayoutViewController.questionResponderViewController.view);
    }];
    bjl_weakify(self);
    [popoverViewController setCancelCallback:^{
        bjl_strongify(self);
        [self.blackboardLayoutViewController closeQuestionResponderController];
    }];
}

- (void)askToCloseQuestionAnswerController {
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcCloseWebPage];
    [self.blackboardLayoutViewController.questionAnswerWindowViewController bjl_addChildViewController:popoverViewController superview:self.blackboardLayoutViewController.questionAnswerWindowViewController.view];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.blackboardLayoutViewController.questionAnswerWindowViewController.view);
    }];
    bjl_weakify(self);
    [popoverViewController setCancelCallback:^{
        bjl_strongify(self);
        [self.blackboardLayoutViewController closeQuestionAnswerController];
    }];
}

- (BOOL)tryToBlockUser:(BJLUser *)user {
    if (!self.room.loginUser.isTeacherOrAssistant) {
        return NO;
    }
    NSString *message = [NSString stringWithFormat:@"是否将 %@ 移出教室？ \n移出后将无法再次进入教室", user.displayName];
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcKickOutUser message:message];
    [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.popoversLayer);
    }];
    bjl_weakify(self);
    [popoverViewController setConfirmCallback:^{
        bjl_strongify(self);
        BJLError *error = [self.room.onlineUsersVM blockUserWithID:user.ID];
        if (error) {
            [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
        }
    }];
    return YES;
}

- (void)showSwitchToNativePPTWithDocumentVieController:(nullable UIViewController<BJLSlideshowUI> *)viewController callback:(void (^)(BOOL shouldSwitch))callback {
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcAnimatePPTTimeOut];
    [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.popoversLayer);
    }];
    [popoverViewController setCancelCallback:^{
        callback(YES);
    }];
    [popoverViewController setConfirmCallback:^{
        callback(NO);
    }];
    if (viewController) {
        bjl_weakify(popoverViewController);
        [popoverViewController bjl_kvo:BJLMakeProperty(viewController, webPPTLoadSuccess)
                              observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
            bjl_strongify(popoverViewController);
            if (viewController.webPPTLoadSuccess) {
                [popoverViewController bjl_removeFromParentViewControllerAndSuperiew];
                return NO;
            }
            return YES;
        }];
    }
}

#pragma mark - tool box

// 显示文档管理视图
- (void)enterCoursewareMode {
    [self bjl_addChildViewController:self.documentFileManagerViewController superview:self.fullscreenLayer];
    [self.documentFileManagerViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.fullscreenLayer);
    }];
}

// 小黑板
- (void)requsetAddWritingBoard {
    if (!self.room.loginUser.isTeacher) {
        [self.promptViewController enqueueWithPrompt:@"老师才能打开小黑板"];
        return;
    }
    if (!self.room.roomVM.liveStarted) {
        [self.promptViewController enqueueWithPrompt:@"上课状态才能打开小黑板"];
        return;
    }
    
    //每次添加小黑板时, 先pull一次当前小黑板状态
    [self.room.documentVM pullWritingBoard:BJLWritingboardID];
}

// 打开网页
- (void)openWebView {
    [self.blackboardLayoutViewController openWebView];
}

// 计时器
- (void)openCountDown {
    if (!self.room.loginUser.isTeacher) {
        [self.promptViewController enqueueWithPrompt:@"老师才能使用计时器"];
        return;
    }
    if (!self.room.roomVM.liveStarted) {
        [self.promptViewController enqueueWithPrompt:@"上课状态才能使用计时器"];
        return;
    }
    [self.blackboardLayoutViewController openCountDownTimer];
}

// 答题器
- (void)openQuestionAnswer {
    if (!self.room.loginUser.isTeacher) {
        [self.promptViewController enqueueWithPrompt:@"老师才能使用答题器"];
        return;
    }
    if (!self.room.roomVM.liveStarted) {
        [self.promptViewController enqueueWithPrompt:@"上课状态才能使用答题器"];
        return;
    }
    
    [self.blackboardLayoutViewController openQuestionAnswer];
}

// 抢答器
- (void)openQuestionResponder {
    if (!self.room.loginUser.isTeacher) {
        [self.promptViewController enqueueWithPrompt:@"老师才能使用抢答器"];
        return;
    }
    if (!self.room.roomVM.liveStarted) {
        [self.promptViewController enqueueWithPrompt:@"上课状态才能使用抢答器"];
        return;
    }
    
    [self.blackboardLayoutViewController openQuestionResponder];
}

- (void)remakeToolboxViewControllerWithCurrentDocumentDisplayInfo:(BOOL)force {
    // 如果存在最大化或者全屏的窗口，更新布局，force 参数用来忽略之前的状态，强制刷新，目前用于权限变化时候触发
    BJLWindowDisplayInfo *mainMaximizedDisplayInfo = nil;
    BJLWindowDisplayInfo *mainFullScreenDisplayInfo = nil;
    [self.blackboardLayoutViewController getMainMaximizedDisplayInfo:&mainMaximizedDisplayInfo mainFullScreenDisplayInfo:&mainFullScreenDisplayInfo];
    // 当前存在全屏窗口，但是 toolbox 不是全屏的布局，全屏窗口屏蔽最大化窗口，侧边栏的状态和 toolbox 一一对应，不另加判断
    if (mainFullScreenDisplayInfo
        && (force || self.toolboxViewController.type != BJLIcToolboxLayoutFullScreen)) {
        // 移动层级
        [self.toolboxViewController bjl_removeFromParentViewControllerAndSuperiew];
        [self bjl_addChildViewController:self.toolboxViewController superview:self.fullscreenToolboxLayer];
        [self.toolboxViewController.view bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.fullscreenToolboxLayer);
        }];
        // 重新布局
        [self.toolboxViewController remakeToolboxConstraintsWithLayoutType:BJLIcToolboxLayoutFullScreen];
    }
    // 当前存在最大化窗口，但是 toolbox 不是最大化的布局
    else if (mainMaximizedDisplayInfo
             && (force || self.toolboxViewController.type != BJLIcToolboxLayoutMaximized)) {
        // 移动层级
        [self.toolboxViewController bjl_removeFromParentViewControllerAndSuperiew];
        [self bjl_addChildViewController:self.toolboxViewController superview:self.toolbox];
        [self.toolboxViewController.view bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.toolbox);
        }];
        // 重新布局
        [self.toolboxViewController remakeToolboxConstraintsWithLayoutType:BJLIcToolboxLayoutMaximized];
    }
    // 当前不存在全屏窗口，最大化窗口，但是 toolbox 的状态不是 normal 布局
    else if (!mainMaximizedDisplayInfo
             && !mainFullScreenDisplayInfo
             && (force || self.toolboxViewController.type != BJLIcToolboxLayoutNormal)) {
        // 移动层级
        [self.toolboxViewController bjl_removeFromParentViewControllerAndSuperiew];
        [self bjl_addChildViewController:self.toolboxViewController superview:self.toolbox];
        [self.toolboxViewController.view bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.toolbox);
        }];
        // 重新布局
        [self.toolboxViewController remakeToolboxConstraintsWithLayoutType:BJLIcToolboxLayoutNormal];
    }
}

#pragma mark - tool bar

- (BOOL)updateRecordingAudio:(BOOL)on {
    return [self updateRecordingAudio:on recordingVideo:self.room.recordingVM.recordingVideo]; 
}
- (BOOL)updateRecordingVideo:(BOOL)on {
    return [self updateRecordingAudio:self.room.recordingVM.recordingAudio recordingVideo:on];
}

- (BOOL)updateRecordingAudio:(BOOL)audio recordingVideo:(BOOL)video {
    return [self updateRecordingAudio:audio recordingVideo:video internal:NO];
}

- (BOOL)updateRecordingAudio:(BOOL)audio recordingVideo:(BOOL)video internal:(BOOL)internal {
    if (self.room.recordingVM.recordingAudio == audio
        && self.room.recordingVM.recordingVideo == video) {
        return YES;
    }
    BOOL audioChange = self.room.recordingVM.recordingAudio != audio;
    BOOL videoChange = self.room.recordingVM.recordingVideo != video;
    BJLError *error = [self.room.recordingVM setRecordingAudio:audio recordingVideo:video];
    if (error) {
        if (!internal) {
            [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
        }
    }
    else {
        if (audioChange) {
            [self.promptViewController enqueueWithPrompt:(self.room.recordingVM.recordingAudio
                                                          ? @"麦克风已打开"
                                                          : @"麦克风已关闭")];
        }
        if (videoChange) {
            [self.promptViewController enqueueWithPrompt:(self.room.recordingVM.recordingVideo
                                                          ? @"摄像头已打开"
                                                          : @"摄像头已关闭")];
        }
    }
    return !error;
}

- (void)activeCurrentLoginUser {
    // 老师无条件开启音视频，1v1模板台上用户无条件开启音视频, 配置了默认打开音频的学生开启音频
    BOOL recordingAudio = self.room.loginUser.isTeacher
    || BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType
    || (self.room.loginUser.isStudent && self.room.featureConfig.shouleStudentOpenAudioDefault);
    BOOL success = [self updateRecordingAudio:recordingAudio recordingVideo:YES internal:YES];
    if (success) {
        self.hasReload = NO;
        self.needActiveLoginUser = NO;
    }
    else {
        self.needActiveLoginUser = YES;
    }
}

// 切换成画廊布局
- (void)switchToGalleryLayout {
    // 切换到画廊布局
    if ([self.childViewControllers containsObject:self.videosGridLayoutViewController]) {
        return;
    }
    self.toolbarViewController.blackboardLayoutButton.hidden = YES;
    self.toolbarViewController.gallerylayoutButton.hidden = NO;
    self.toolboxViewController.view.hidden = YES;
    [self.blackboardLayoutViewController updateActive:NO];
    [self.blackboardLayoutViewController bjl_removeFromParentViewControllerAndSuperiew];
    [self.videosGridLayoutViewController updateActive:YES];
    [self bjl_addChildViewController:self.videosGridLayoutViewController superview:self.layoutContainer];
    [self.videosGridLayoutViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.layoutContainer);
    }];
    self.currentRoomLayout = BJLRoomLayout_gallary;
}

// 切换成板书布局
- (void)switchToBlackboardLayout {
    // 切换到板书布局
    if ([self.childViewControllers containsObject:self.blackboardLayoutViewController]) {
        return;
    }
    self.toolbarViewController.blackboardLayoutButton.hidden = NO;
    self.toolbarViewController.gallerylayoutButton.hidden = YES;
    self.toolboxViewController.view.hidden = NO;
    [self.videosGridLayoutViewController updateActive:NO];
    [self.videosGridLayoutViewController bjl_removeFromParentViewControllerAndSuperiew];
    [self.blackboardLayoutViewController updateActive:YES];
    [self bjl_addChildViewController:self.blackboardLayoutViewController superview:self.layoutContainer];
    [self.blackboardLayoutViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.layoutContainer);
    }];
    [self.blackboardLayoutViewController.blackboardLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.blackboardLayer);
    }];
    [self.blackboardLayoutViewController.videosLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.videosLayer);
    }];
    self.currentRoomLayout = BJLRoomLayout_blackboard;
}

- (void)startCloudRecordingAfterCheckState {
    if (self.room.serverRecordingVM.serverRecording) {
        return;
    }
    bjl_weakify(self);
    [self.room.serverRecordingVM requestServerRecordingState:^{
        bjl_strongify(self);
        switch (self.room.serverRecordingVM.state) {
            case BJLServerRecordingState_ready:
            case BJLServerRecordingState_transcoding: {
                self.toolbarViewController.cloudRecordingButton.selected = [self updateCloudRecording:YES];
                break;
            }
                
            case BJLServerRecordingState_recording: {
                // 小班课没有重新开录制的逻辑, 所以直接调整为继续录制
                self.toolbarViewController.cloudRecordingButton.selected = [self updateCloudRecording:YES];
                break;
            }
                
            case BJLServerRecordingState_disable: {
                self.toolbarViewController.cloudRecordingButton.selected = NO;
                [self.promptViewController enqueueWithPrompt:@"云端录制不可用"];
                break;
            }
                
            default:
                break;
        }
    }];
}

// 开启云端录制
- (BOOL)updateCloudRecording:(BOOL)recording {
    if (!self.room.loginUser.isTeacherOrAssistant) {
        self.toolbarViewController.cloudRecordingButton.selected = NO;
        [self.promptViewController enqueueWithPrompt:@"当前用户无法录制"];
        return NO;
    }
    
    BJLError *error = [self.room.serverRecordingVM requestServerRecording:recording];
    if (error) {
        self.toolbarViewController.cloudRecordingButton.selected = NO;
        [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
    }
    return !error;
}

- (void)updateAllRecordingAudioMute:(BOOL)mute {
    BJLError *error = [self.room.recordingVM updateAllRecordingAudioMute:mute];
    if (error) {
        [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
    }
}

// 禁止举手
- (BOOL)updateForbidSpeakRequest:(BOOL)forbid {
    BJLError *error = [self.room.speakingRequestVM requestForbidSpeakingRequest:forbid];
    if (error) {
        [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
    }
    return !error;
}

// 用户列表
- (void)updateUserListHidden:(BOOL)isHidden {
    if (isHidden) {
        [self.userViewController bjl_removeFromParentViewControllerAndSuperiew];
    }
    else {
        if ([self.childViewControllers containsObject:self.userViewController]) {
            return;
        }
        
        self.toolbarViewController.userListRedDot.hidden = YES;
        self.toolbarViewController.menuRedDot.hidden = YES;
        [self.toolbarViewController hideTeachingAid];
        [self bjl_addChildViewController:self.userViewController superview:self.fullscreenLayer];
        [self.userViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.fullscreenLayer);
        }];
    }
}

// 聊天列表
- (void)updateChatListHidden:(BOOL)isHidden {
    if (isHidden) {
        [self.chatViewController bjl_removeFromParentViewControllerAndSuperiew];
    }
    else {
        if ([self.childViewControllers containsObject:self.chatViewController]) {
            return;
        }
        [self.userViewController bjl_removeFromParentViewControllerAndSuperiew];
        self.toolbarViewController.userListButton.selected = NO;
        self.toolbarViewController.chatListRedDot.hidden = YES;
        [self.toolbarViewController hideTeachingAid];
        [self bjl_addChildViewController:self.chatViewController superview:self.widgetContainer];
        [self.chatViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.widgetContainer);
        }];
        bjl_weakify(self);
        [self.chatViewController setShowChatInputViewCallback:^(NSString *text) {
            bjl_strongify(self);
            BJLIcChatInputViewController *chatInputViewController = [[BJLIcChatInputViewController alloc] initWithText:text];
            [self bjl_addChildViewController:chatInputViewController superview:self.popoversLayer];
            [chatInputViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
                make.edges.equalTo(self.popoversLayer);
            }];
            [chatInputViewController setEditCallback:^(NSString * _Nonnull text) {
                bjl_strongify(self);
                [self.chatViewController sendText:text];
            }];
        }];
        [self.chatViewController setShowChatDetailViewCallback:^(BJLMessage * _Nonnull message, NSArray<BJLMessage *> * _Nonnull imageMessages) {
            bjl_strongify(self);
            BJLIcChatDetailViewController *chatDetailViewController = [[BJLIcChatDetailViewController alloc] initWithMessage:message imageMessages:imageMessages];
            [self bjl_addChildViewController:chatDetailViewController superview:self.fullscreenLayer];
            [chatDetailViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
                make.edges.equalTo(self.fullscreenLayer);
            }];
        }];
        [self.chatViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
            bjl_strongify(self);
            [self.promptViewController enqueueWithPrompt:message];
        }];
    }
}

// 更新举手状态
- (BOOL)updateSpeakRequest:(BOOL)requestSpeak {
    if (requestSpeak) {
        if (self.room.loginUser.isTeacherOrAssistant) {
            return NO;
        }
        if (self.room.speakingRequestVM.forbidSpeakingRequest) {
            [self.promptViewController enqueueWithPrompt:@"老师设置了禁止举手"];
            return NO;
        }
        if (self.room.speakingRequestVM.speakingRequestTimeRemaining > 0.0) {
            [self.room.speakingRequestVM stopSpeakingRequest];
            return NO;
        }
        
        BJLError *error = [self.room.speakingRequestVM sendSpeakingRequest];
        if (error) {
            [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
        }
        else {
            [self.promptViewController enqueueWithPrompt:@"举手中，等待老师同意"];
        }
        return !error;
    }
    else {
        [self.room.speakingRequestVM stopSpeakingRequest];
        [self.promptViewController enqueueWithPrompt:@"已取消举手"];
    }
    return YES;
}

#pragma mark -

#if DEBUG
- (void)makeDebugActions {
    bjl_weakify(self);
    
    [self.toolbarViewController.widgetButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        button.selected = !button.isSelected;
        self.widgetLayer.hidden = button.selected;
    }];
    
    [self.toolbarViewController.settingsButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        button.selected = !button.isSelected;
        self.settingsLayer.hidden = button.selected;
    }];
    
    [self.toolbarViewController.fullscreenButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        button.selected = !button.isSelected;
        self.fullscreenLayer.hidden = button.selected;
    }];
    
    [self.toolbarViewController.popoversButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        button.selected = !button.isSelected;
        self.popoversLayer.hidden = button.selected;
    }];
    
    /* fire */
    
    { // TEST
        // [self.toolbarViewController.widgetButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        // [self.toolbarViewController.settingsButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        // [self.toolbarViewController.fullscreenButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        // [self.toolbarViewController.popoversButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}
#endif

@end

NS_ASSUME_NONNULL_END
