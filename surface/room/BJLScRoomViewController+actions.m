//
//  BJLScRoomViewController+actions.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScRoomViewController+actions.h"
#import "BJLScRoomViewController+private.h"
#import "BJLScImageViewController.h"

@implementation BJLScRoomViewController (actions)

- (void)makeActionsOnViewDidLoad {
    bjl_weakify(self);

#pragma mark - topBar
    
    [self.topBarViewController setExitCallback:^{
        bjl_strongify(self);
        [self exit];
    }];

    [self.topBarViewController setShowSettingCallback:^{
        bjl_strongify(self);
        [self.overlayViewController showWithContentViewController:self.settingsViewController contentView:nil];
        [self.settingsViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.right.bottom.equalTo(self.overlayViewController.view);
            make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
        }];
    }];
    
#pragma mark - minorContentView
    
    UITapGestureRecognizer *minorContentViewGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        // 如果小窗为老师 & 老师在教室时，显示老师菜单
        if (self.teacherMediaInfoView && self.minorWindowType == BJLScWindowType_teacherVideo) {
            [self showMenuForTeacherVideoWithSourceView:self.minorContentView];
        }
        else if (self.minorWindowType == BJLScWindowType_ppt) {
            [self showMenuForPPTViewWithSourceView:self.minorContentView];
        }
    }];
    [self.minorContentView addGestureRecognizer:minorContentViewGesture];

#pragma mark - videosViewController
    
    if (self.videosViewController) {
        [self.videosViewController setReplaceMajorWindowCallback:^(BJLScMediaInfoView * _Nullable mediaInfoView, NSInteger index, BJLScWindowType majorWindowType, BOOL recording) {
            bjl_strongify(self);
            if (majorWindowType == BJLScWindowType_userVideo) {
                // 预期将大屏替换成用户视频
                switch (self.majorWindowType) {
                    case BJLScWindowType_ppt:
                        // 大屏为 PPT 或者老师辅助摄像头
                        [self.videosViewController replaceMajorContentViewAtIndex:index recording:recording teacherExtraMediaInfoView:self.teacherExtraMediaInfoView];
                        break;
                        
                    case BJLScWindowType_userVideo:
                        // 大屏为用户视频，此时 PPT 或者老师辅助摄像头在视频列表区域
                        [self.videosViewController replaceMajorContentViewAtIndex:index recording:recording teacherExtraMediaInfoView:self.teacherExtraMediaInfoView];
                        break;
                        
                    case BJLScWindowType_teacherVideo:
                        // 大屏为老师视频，先把老师替换到小屏，把小屏 PPT 或者老师辅助摄像头放到视频列表
                        [self replaceMinorContentViewWithTeacherMediaInfoView];
                        [self.videosViewController replaceMajorContentViewAtIndex:index recording:recording teacherExtraMediaInfoView:self.teacherExtraMediaInfoView];
                        break;
                        
                    default:
                        break;
                }
                [self replaceMajorContentViewWithUserMediaInfoView:mediaInfoView];
            }
            else if (majorWindowType == BJLScWindowType_ppt) {
                // 收回 PPT 或者老师辅助摄像头
                [self.videosViewController replaceMajorContentViewAtIndex:index recording:recording teacherExtraMediaInfoView:nil];
                [self replaceMajorContentViewWithPPTView];
            }
        }];
        
        [self.videosViewController setUpdateVideoCallback:^(BJLMediaUser * _Nonnull user, BOOL on) {
            bjl_strongify(self);
            [self updateAutoPlayVideoBlacklist:user add:on];
        }];
        
        // 由于视频消失，需要重置位置
        [self.videosViewController setRestoreFullscreenOrMajorWindowCallback:^{
            bjl_strongify(self);
            // 如果全屏区域是用户视频，复原全屏
            if (self.fullscreenWindowType == BJLScWindowType_userVideo) {
                [self restoreCurrentFullscreenWindow];
            }
            // 重置视频列表
            if (self.videosViewController) {
                [self.videosViewController resetVideo];
            }
            // 复原 1v1
            if (self.secondMinorMediaInfoView) {
                [self replaceSecondMinorContentViewWithSecondMinorMediaInfoView];
            }
            // 将白板换到大屏位置
            [self replaceMajorContentViewWithPPTView];
        }];
    }
    
#pragma mark - documentToolView
    
    [self.toolViewController setShowCoursewareCallback:^{
        bjl_strongify(self);
        [self.overlayViewController showWithContentViewController:self.pptManagerViewController contentView:nil];
        [self.pptManagerViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.right.bottom.equalTo(self.overlayViewController.view);
            make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
        }];
    }];
    
    [self.toolViewController setOpenCountDownCallback:^{
        bjl_strongify(self);
        if (!self.room.loginUser.isTeacher) {
            return ;
        }

        if (!self.countDownEditViewController) {
            [self makeCountDownViewController];
        }
        NSInteger totalTime = self.countDownViewController.originCountDownTime;
        BOOL isDecrease = self.countDownViewController.isDecrease;
        BOOL shouldPause = self.countDownViewController.shouldPause;
        NSInteger leftCountDownTime = isDecrease ? self.countDownViewController.currentCountDownTime : (totalTime - self.countDownViewController.currentCountDownTime);
        [self.countDownEditViewController updateTimerWithTotalTime:totalTime
                                              currentCountDownTime:leftCountDownTime
                                                        isDecrease:isDecrease
                                                       shouldPause:shouldPause];
        [self.overlayViewController showWithContentViewController:self.countDownEditViewController contentView:nil];
        [self.countDownEditViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.right.bottom.equalTo(self.overlayViewController.view);
            make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
        }];
    }];
    
#pragma mark - overlay
    
    [self.overlayViewController setShowCallback:^{
        bjl_strongify(self);
        [self bjl_addChildViewController:self.overlayViewController superview:self.overlayView];
        [self.overlayViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.overlayView);
        }];
    }];
    
    [self.fullscreenOverlayViewController setShowCallback:^{
        bjl_strongify(self);
        [self bjl_addChildViewController:self.fullscreenOverlayViewController superview:self.fullscreenLayer];
        [self.fullscreenOverlayViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.fullscreenLayer);
        }];
        [self setNeedsStatusBarAppearanceUpdate];
//        BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
        // special buttons
        [self.fullscreenLayer addSubview:self.restoreButton];
        [self.restoreButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.fullscreenButton);
        }];
        [self.fullscreenLayer addSubview:self.fullScreenEyeProtectedButton];
        [self.fullScreenEyeProtectedButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.size.centerY.equalTo(self.restoreButton);
            make.left.equalTo(self.restoreButton.bjl_right);
        }];
        
        [self.toolViewController removeFromView:self.toolView addToSuperView:self.fullscreenLayer shouldFullScreen:YES];
        
        if (!self.is1V1Class) {
            [self.fullscreenLayer addSubview:self.fullHandUpButton];
            self.fullHandProgressView.progress = self.handProgressView.progress;
            [self.fullHandUpButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.bottom.equalTo(self.fullscreenLayer).offset(-BJLScViewSpaceM);
                make.right.equalTo(self.fullscreenLayer.bjl_right).offset(-6.0);
                make.width.height.equalTo(@(BJLScControlSize));
            }];
            [self.fullscreenLayer addSubview:self.fullSpeakRequestRedDot];
            self.fullSpeakRequestRedDot.hidden = self.speakRequestRedDot.hidden;
            self.fullSpeakRequestRedDot.text = self.speakRequestRedDot.text;
            [self.fullSpeakRequestRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.top.equalTo(self.fullHandUpButton).offset(10.0);
                make.left.equalTo(self.fullHandUpButton.bjl_centerX).offset(10.0);
                make.height.width.equalTo(@(BJLScRedDotWidth));
            }];
        }
    }];
    
    [self.fullscreenOverlayViewController setHideCallback:^{
        bjl_strongify(self);
        [self setNeedsStatusBarAppearanceUpdate];
        [self.toolViewController removeFromView:self.fullscreenLayer addToSuperView:self.toolView shouldFullScreen:NO];
        [self.restoreButton removeFromSuperview];
        [self.fullScreenEyeProtectedButton removeFromSuperview];
        [self.fullHandUpButton removeFromSuperview];
        [self.fullSpeakRequestRedDot removeFromSuperview];
    }];
    
    [self.fullscreenOverlayViewController setTapCallback:^{
        bjl_strongify(self);
        switch (self.fullscreenWindowType) {
            case BJLScWindowType_ppt:
                [self showMenuForPPTViewWithSourceView:self.fullscreenLayer];
                break;
                
            case BJLScWindowType_teacherVideo:
                [self showMenuForTeacherVideoWithSourceView:self.fullscreenLayer];
                break;
                
            case BJLScWindowType_userVideo:
                [self showMenuForStudentVideoWithSourceView:self.fullscreenLayer mediaInfoView:self.fullscreenMediaInfoView];
                break;
                
            default:
                break;
        }
    }];
    
#pragma mark - segmentViewController

    [self.segmentViewController setShowChatInputViewCallback:^(BOOL whisperChatUserExpend, BJLCommandLotteryBegin * _Nullable commandLottery) {
        bjl_strongify(self);
        [self showChatInputViewWithWhisperChatUserExpend:whisperChatUserExpend commandLottery:commandLottery];
    }];
    [self.segmentViewController setTapCommandLotteryCallback:^(BJLCommandLotteryBegin * _Nonnull commandLottery) {
        bjl_strongify(self);
        [self.chatInputViewController setContentWithText:commandLottery.command];
    }];
    
    [self.segmentViewController setShowImageViewCallback:^(BJLMessage *currentImageMessage, NSArray<BJLMessage *> *imageMessages, BOOL isStickyMessage) {
        bjl_strongify(self);
        [self showFullImageWithMessage:currentImageMessage
                         imageMessages:imageMessages
                       isStickyMessage:isStickyMessage];
    }];
    
    [self.segmentViewController setChangeChatStatusCallback:^(BJLChatStatus chatStatus, BJLUser * _Nullable targetUser) {
        bjl_strongify(self);
        [self.chatInputViewController updateChatStatus:chatStatus withTargetUser:targetUser];
    }];
    
    [self.segmentViewController setShowQuestionInputViewCallback:^(BJLQuestion * _Nonnull question) {
        bjl_strongify(self);
        [self.questionInputViewController updateWithQuestion:question];
        [self.overlayViewController showWithContentViewController:self.questionInputViewController contentView:nil];
        [self.questionInputViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.right.bottom.equalTo(self.overlayViewController.view);
        }];
    }];

#pragma mark - handUpButton
    
    [self.handUpButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self touchHandUp];
    }];
    
#pragma mark - videoButton

    [self.videoButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [button bjl_disableForSeconds:BJLScRobotDelayM];
        BJLError *error = [self.room.recordingVM setRecordingAudio:self.room.recordingVM.recordingAudio
                                                    recordingVideo:!self.room.recordingVM.recordingVideo];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
        else {
            [self showProgressHUDWithText:(self.room.recordingVM.recordingVideo
                                           ? @"摄像头已打开"
                                           : @"摄像头已关闭")];
        }

    }];
    
#pragma mark - audioButton
    
    [self.audioButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [button bjl_disableForSeconds:BJLScRobotDelayM];
        BJLError *error = [self.room.recordingVM setRecordingAudio:!self.room.recordingVM.recordingAudio
                                                    recordingVideo:self.room.recordingVM.recordingVideo];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
        else {
            [self showProgressHUDWithText:(self.room.recordingVM.recordingAudio
                                           ? @"麦克风已打开"
                                           : @"麦克风已关闭")];
        }

    }];
    
#pragma mark - other buttons
    
    [self.noticeButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.room.loginUser.isTeacherOrAssistant) {
            [self.overlayViewController showWithContentViewController:self.noticeEditViewController contentView:nil];
            [self.noticeEditViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.top.right.bottom.equalTo(self.overlayViewController.view);
                make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
            }];
        }
        else {
            [self.overlayViewController showWithContentViewController:self.noticeViewController contentView:nil];
            [self.noticeViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.top.right.bottom.equalTo(self.overlayViewController.view);
                make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
            }];
        }
    }];
    
    [self.questionButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self showQuestionViewController];
    }];
    
    [self.fullscreenButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self fullscreenCurrentMajorWindow];
    }];
    
    [self.eyeProtectedButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        self.eyeProtectedButton.selected = !self.eyeProtectedButton.selected;
        self.fullScreenEyeProtectedButton.selected = !self.fullScreenEyeProtectedButton.selected;
        self.eyeProtectedLayer.hidden = !self.eyeProtectedButton.selected;
    }];

    [self.fullScreenEyeProtectedButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        self.eyeProtectedButton.selected = !self.eyeProtectedButton.selected;
        self.fullScreenEyeProtectedButton.selected = !self.fullScreenEyeProtectedButton.selected;
        self.eyeProtectedLayer.hidden = !self.eyeProtectedButton.selected;
    }];

#pragma mark - 1v1
    
    if (self.is1V1Class) {
        [self.chatViewController setShowImageViewCallback:^(BJLMessage *currentImageMessage, NSArray<BJLMessage *> *imageMessages, BOOL isStickyMessage) {
               bjl_strongify(self);
               [self showFullImageWithMessage:currentImageMessage
                                imageMessages:imageMessages
                              isStickyMessage:isStickyMessage];
        }];
        
        [self.chatViewController setShowChatInputViewCallback:^(BOOL whisperChatUserExpend, BJLCommandLotteryBegin * _Nullable commandLottery) {
            bjl_strongify(self);
            [self showChatInputViewWithWhisperChatUserExpend:whisperChatUserExpend commandLottery:commandLottery];
        }];
        
        [self.chatViewController setTapCommandLotteryCallback:^(BJLCommandLotteryBegin * _Nonnull commandLottery) {
            bjl_strongify(self);
            [self.chatInputViewController setContentWithText:commandLottery.command];
        }];
        
        [self.chatViewController setNewMessageCallback:^(NSInteger count) {
            bjl_strongify(self);
            if (self.chatButton) {
                self.chatRedDot.hidden = !count;
            }
        }];
        
        [self.chatButton bjl_addHandler:^(UIButton * _Nonnull button) {
            bjl_strongify(self);
            [self bjl_addChildViewController:self.chatViewController superview:self.segmentView];
            [self.chatViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.segmentView);
            }];
        }];
        
        [self.chatViewController setBackToVideoCallback:^{
            bjl_strongify(self);
            [self.chatViewController bjl_removeFromParentViewControllerAndSuperiew];
        }];
        UITapGestureRecognizer *secondMinorContentViewGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
            bjl_strongify(self);
            if (self.secondMinorMediaInfoView && self.secondMinorWindowType == BJLScWindowType_userVideo) {
                [self showMenuForStudentVideoWithSourceView:self.secondMinorContentView mediaInfoView:self.secondMinorMediaInfoView];
            }
            else if (self.secondMinorWindowType == BJLScWindowType_ppt) {
                [self showMenuForPPTViewWithSourceView:self.secondMinorContentView];
            }
        }];
        [self.secondMinorContentView addGestureRecognizer:secondMinorContentViewGesture];
    }
    
    // gesture
    [self makeGestureAction];
}

#pragma mark - Question

- (void)showQuestionViewController {
    [self.overlayViewController showWithContentViewController:self.questionViewController contentView:nil];
    [self.questionViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.right.bottom.equalTo(self.overlayViewController.view);
        make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
    }];
    [self updateQuestionRedDotHidden:YES];
}

- (void)updateQuestionRedDotHidden:(BOOL)hidden {
    self.questionRedDotHidden = hidden;
    self.questionRedDot.hidden = hidden || self.questionButton.hidden;
}

#pragma mark - gesture

- (void)makeGestureAction {
    bjl_weakify(self);
    [self.majorContentView addGestureRecognizer:[UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        if (self.room.drawingVM.drawingEnabled) {
            return ;
        }
        
        [self setControlsHidden:!self.controlsHidden animated:NO];
    }]];
}

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated {
    self.controlsHidden = hidden;
    
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);

    BOOL topBarViewHidden = hidden && !iPad && !self.is1V1Class;
    self.topBarView.hidden = topBarViewHidden;
    [self.topBarView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(topBarViewHidden ? @(0) : @(BJLScTopBarHeight));
    }];
    
    [self updateButtonStates];
}

#pragma mark - handup

- (void)touchHandUp {
    bjl_returnIfRobot(BJLScRobotDelayS);
    if (self.room.loginUser.isStudent) {
        if (self.room.speakingRequestVM.speakingEnabled
            || (self.room.speakingRequestVM.speakingRequestTimeRemaining > 0)) {
            [self.room.speakingRequestVM stopSpeakingRequest];
        }
        else {
            if (self.room.speakingRequestVM.forbidSpeakingRequest) {
                [self showProgressHUDWithText:@"老师设置了禁止举手"];
                return;
            }
            
            BJLError *error = [self.room.speakingRequestVM sendSpeakingRequest];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            }
            else {
                [self showProgressHUDWithText:@"举手中，等待老师同意"];
            }
        }
    }
    else {
        [self.overlayViewController showWithContentViewController:self.speakRequestUsersViewController contentView:nil];
        [self.speakRequestUsersViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.right.bottom.equalTo(self.overlayViewController.view);
            make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
        }];
    }
}

#pragma mark - chat

- (void)showFullImageWithMessage:(BJLMessage *)currentImageMessage imageMessages:(NSArray<BJLMessage *> *)imageMessages isStickyMessage:(BOOL)isStickyMessage{
    BJLScImageViewController *imageViewController = [[BJLScImageViewController alloc] initWithMessage:currentImageMessage imageMessages:imageMessages isStickyMessage:isStickyMessage && self.room.loginUser.isTeacherOrAssistant];
    bjl_weakify(self, imageViewController);
    [imageViewController setCancelStickyCallback:^(BJLMessage * _Nonnull message) {
        bjl_strongify(self, imageViewController);
        if (self.room.loginUser.isTeacherOrAssistant) {
            BJLError *error = [self.room.chatVM cancelStickyMessage:message];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            }
            else {
                [imageViewController hide];
            }
        }
    }];
    
    [self bjl_addChildViewController:imageViewController superview:self.imageViewLayer];
    [imageViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.imageViewLayer);
    }];
}

- (void)showChatInputViewWithWhisperChatUserExpend:(BOOL)whisperChatUserExpend commandLottery:(nullable BJLCommandLotteryBegin *)commandLottery {

    [self.chatInputViewController updateCommandLottery:commandLottery];
    if (!self.room.loginUser.isTeacherOrAssistant
        && (self.room.chatVM.forbidMe)) {
        [self showProgressHUDWithText:@"禁言状态不能发送消息"];
        return;
    }
    
    if (self.room.loginUser.isAudition) {
        [self showProgressHUDWithText:@"试听用户不能发送消息"];
        return;
    }

    if (whisperChatUserExpend) {
        [self.chatInputViewController showWhisperChatList];
    }
    
    [self.overlayViewController showWithContentViewController:self.chatInputViewController contentView:nil];
    [self.chatInputViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(self.overlayViewController.view);
    }];
}

#pragma mark - ppt

- (void)updatePPTUserInteractionEnable {
    self.room.slideshowViewController.view.userInteractionEnabled = (self.majorWindowType == BJLScWindowType_ppt) || (self.fullscreenWindowType == BJLScWindowType_ppt);
}

#pragma mark - fullscreen

// 把当前大屏视图全屏
- (void)fullscreenCurrentMajorWindow {
    if (self.majorWindowType == BJLScWindowType_ppt) {
        [self replaceFullscreenWithWindowType:BJLScWindowType_ppt mediaInfoView:self.teacherExtraMediaInfoView];
    }
    else if (self.majorWindowType == BJLScWindowType_teacherVideo) {
        [self replaceFullscreenWithWindowType:BJLScWindowType_teacherVideo mediaInfoView:self.teacherMediaInfoView];
    }
    else if (self.majorWindowType == BJLScWindowType_userVideo) {
        if (self.secondMinorMediaInfoView) {
            [self replaceFullscreenWithWindowType:BJLScWindowType_userVideo mediaInfoView:self.secondMinorMediaInfoView];
        }
        else {
            if (self.videosViewController.majorMediaInfoView) {
                [self replaceFullscreenWithWindowType:BJLScWindowType_userVideo mediaInfoView:self.videosViewController.majorMediaInfoView];
            }
        }
    }
}

// 全屏视图恢复原始位置
- (void)restoreCurrentFullscreenWindow {
    [self replaceFullscreenWithWindowType:BJLScWindowType_none mediaInfoView:nil];
}

#pragma mark - button state

- (void)updateButtonStates {
    if (self.is1V1Class) {
        [self update1V1ButtonStates];
        return;
    }
    self.videoButton.hidden = (self.room.loginUser.isStudent && (!self.room.speakingRequestVM.speakingEnabled || self.room.featureConfig.hideStudentCamera)) || self.controlsHidden || self.room.loginUser.isAudition;
    self.audioButton.hidden = (self.room.loginUser.isStudent && !self.room.speakingRequestVM.speakingEnabled) || self.controlsHidden || self.room.loginUser.isAudition;
    self.fullscreenButton.hidden = self.controlsHidden;
    
    self.videoButton.selected = (self.room.loginUser.isTeacherOrAssistant || (self.room.loginUser.isStudent && self.room.speakingRequestVM.speakingEnabled)) && self.room.recordingVM.recordingVideo;
    self.audioButton.selected = (self.room.loginUser.isTeacherOrAssistant || (self.room.loginUser.isStudent && self.room.speakingRequestVM.speakingEnabled)) && self.room.recordingVM.recordingAudio;
    // 学生显示，老师或者助教在举手列表人数大于 0 时显示
    self.handUpButton.hidden = !(self.room.loginUser.isStudent || (self.room.loginUser.isTeacherOrAssistant && [self.room.speakingRequestVM.speakingRequestUsers count] > 0)) || self.controlsHidden || self.room.loginUser.isAudition;
    self.fullHandUpButton.hidden = !(self.room.loginUser.isStudent || (self.room.loginUser.isTeacherOrAssistant && [self.room.speakingRequestVM.speakingRequestUsers count] > 0)) || self.room.loginUser.isAudition;
    
    if (self.room.loginUser.isStudent) {
        self.handUpButton.selected = self.room.speakingRequestVM.speakingEnabled;
        self.fullHandUpButton.selected = self.room.speakingRequestVM.speakingEnabled;
    }
    
    NSString *liveTabs = self.room.loginUser.isStudent ? self.room.featureConfig.liveTabsOfStudent : self.room.featureConfig.liveTabs;
    BOOL enableQuestion = [liveTabs containsString:@"answer"] && self.room.featureConfig.enableQuestion;
    self.noticeButton.hidden = self.controlsHidden;
    self.questionButton.hidden = self.controlsHidden || !enableQuestion;
    BOOL questionRedDotHidden = self.controlsHidden || !enableQuestion || self.questionRedDotHidden;
    self.questionRedDot.hidden = questionRedDotHidden;
    self.eyeProtectedButton.hidden = self.controlsHidden;
}

- (void)update1V1ButtonStates {
    self.videoButton.hidden = self.controlsHidden || self.room.loginUser.isAudition;
    self.audioButton.hidden = self.controlsHidden || self.room.loginUser.isAudition;
    self.fullscreenButton.hidden = self.controlsHidden;
    self.eyeProtectedButton.hidden = self.controlsHidden;
    
    self.videoButton.selected = self.room.recordingVM.recordingVideo;
    self.audioButton.selected = self.room.recordingVM.recordingAudio;
}

#pragma mark - replaceContentView

/**
 此处穷举了所有当前控制器需要处理的视图切换，注意任何情况下，老师辅助摄像头和PPT区域是重叠的
 包括 大屏的三种可能视图（PPT，老师，其他用户），小屏的二种可能视图（老师，PPT），以及 1v1 的第二个小屏的二种可能（PPT，其他用户）
 但是所有视频列表的替换需要根据实际单独处理
 */

// 替换大屏为PPT
- (void)replaceMajorContentViewWithPPTView {
    [self replaceWithPPTViewInContentView:self.majorContentView];
    if (self.teacherExtraMediaInfoView
        && self.teacherExtraMediaInfoView.positionType != BJLScPositionType_major) {
        self.teacherExtraMediaInfoView.positionType = BJLScPositionType_major;
    }
    if (self.majorWindowType != BJLScWindowType_ppt) {
        self.majorWindowType = BJLScWindowType_ppt;
    }
}

// 替换小屏为PPT
- (void)replaceMinorContentViewWithPPTView {
    [self replaceWithPPTViewInContentView:self.minorContentView];
    if (self.teacherExtraMediaInfoView
        && self.teacherExtraMediaInfoView.positionType != BJLScPositionType_minor) {
        self.teacherExtraMediaInfoView.positionType = BJLScPositionType_minor;
    }
    if (self.minorWindowType != BJLScWindowType_ppt) {
        self.minorWindowType = BJLScWindowType_ppt;
    }
}

// 替换 1v1 第二个小屏为PPT
- (void)replaceSecondMinorContentViewWithPPTView {
    [self replaceWithPPTViewInContentView:self.secondMinorContentView];
    if (self.teacherExtraMediaInfoView
        && self.teacherExtraMediaInfoView.positionType != BJLScPositionType_secondMinor) {
        self.teacherExtraMediaInfoView.positionType = BJLScPositionType_secondMinor;
    }
    if (self.secondMinorWindowType != BJLScWindowType_ppt) {
        self.secondMinorWindowType = BJLScWindowType_ppt;
    }
}

- (void)replaceWithPPTViewInContentView:(UIView *)contentView {
    if (contentView != self.fullscreenLayer
        && self.fullscreenWindowType == BJLScWindowType_ppt) {
        [self resetFullscreenWindowType];
    }
    
    if (self.room.slideshowViewController) {
        [self.room.slideshowViewController bjl_removeFromParentViewControllerAndSuperiew];
        if (contentView == self.fullscreenLayer) {
            [self.fullscreenOverlayViewController showFillContentViewController:self.room.slideshowViewController contentView:nil ratio:0.0];
        }
        else {
            [self bjl_addChildViewController:self.room.slideshowViewController superview:contentView];
            [self.room.slideshowViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(contentView);
            }];
        }
    }
    
    if (self.teacherExtraMediaInfoView) {
        // 存在老师辅助摄像头时，盖住白板
        [self.teacherExtraMediaInfoView removeFromSuperview];
        if (contentView == self.fullscreenLayer) {
            [self.fullscreenOverlayViewController showFillContentViewController:self.room.slideshowViewController contentView:self.teacherExtraMediaInfoView ratio:0.0];
        }
        else {
            [contentView addSubview:self.teacherExtraMediaInfoView];
            [self.teacherExtraMediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(contentView);
            }];
        }
    }
}

// 替换大屏为老师
- (void)replaceMajorContentViewWithTeacherMediaInfoView {
    [self replaceWithTeacherMediaInfoViewInContentView:self.majorContentView];
    if (self.teacherMediaInfoView.positionType != BJLScPositionType_major) {
        self.teacherMediaInfoView.positionType = BJLScPositionType_major;
    }
    if (self.majorWindowType != BJLScWindowType_teacherVideo) {
        self.majorWindowType = BJLScWindowType_teacherVideo;
    }
    [self updateTeacherVideoPlaceholderView];
}

// 替换小屏为老师
- (void)replaceMinorContentViewWithTeacherMediaInfoView {
    [self replaceWithTeacherMediaInfoViewInContentView:self.minorContentView];
    if (self.teacherMediaInfoView.positionType != BJLScPositionType_minor) {
        self.teacherMediaInfoView.positionType = BJLScPositionType_minor;
    }
    if (self.minorWindowType != BJLScWindowType_teacherVideo) {
        self.minorWindowType = BJLScWindowType_teacherVideo;
    }
    [self updateTeacherVideoPlaceholderView];
}

- (void)replaceWithTeacherMediaInfoViewInContentView:(UIView *)contentView {
    if (contentView != self.fullscreenLayer
        && self.fullscreenWindowType == BJLScWindowType_teacherVideo) {
        [self resetFullscreenWindowType];
    }
    
    if (self.teacherMediaInfoView) {
        [self.teacherMediaInfoView removeFromSuperview];
        if (contentView == self.fullscreenLayer) {
            [self.fullscreenOverlayViewController showFillContentViewController:nil contentView:self.teacherMediaInfoView ratio:0.0];
        }
        else {
            [contentView addSubview:self.teacherMediaInfoView];
            [self.teacherMediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(contentView);
            }];
        }
    }
}

// 替换大屏为某个用户
- (void)replaceMajorContentViewWithUserMediaInfoView:(BJLScMediaInfoView *)mediaInfoView {
    [self replaceContentView:self.majorContentView mediaInfoView:mediaInfoView];
    if (mediaInfoView.positionType != BJLScPositionType_major) {
        mediaInfoView.positionType = BJLScPositionType_major;
    }
    if (self.majorWindowType != BJLScWindowType_userVideo) {
        self.majorWindowType = BJLScWindowType_userVideo;
    }
}

// 替换 1v1 大屏为某个用户
- (void)replaceMajorContentViewWithSecondMinorMediaInfoView {
    [self replaceContentView:self.majorContentView mediaInfoView:self.secondMinorMediaInfoView];
    if (self.secondMinorMediaInfoView.positionType != BJLScPositionType_major) {
        self.secondMinorMediaInfoView.positionType = BJLScPositionType_major;
    }
    if (self.majorWindowType != BJLScWindowType_userVideo) {
        self.majorWindowType = BJLScWindowType_userVideo;
    }
    [self updateSecondMinorVideoPlaceholderView];
}

// 替换 1v1 第二个小屏为某个用户
- (void)replaceSecondMinorContentViewWithSecondMinorMediaInfoView {
    [self replaceContentView:self.secondMinorContentView mediaInfoView:self.secondMinorMediaInfoView];
    if (self.secondMinorMediaInfoView.positionType != BJLScPositionType_secondMinor) {
        self.secondMinorMediaInfoView.positionType = BJLScPositionType_secondMinor;
    }
    if (self.secondMinorWindowType != BJLScWindowType_userVideo) {
        self.secondMinorWindowType = BJLScWindowType_userVideo;
    }
    [self updateSecondMinorVideoPlaceholderView];
}

- (void)replaceContentView:(UIView *)contentView mediaInfoView:(BJLScMediaInfoView *)mediaInfoView {
    if (contentView != self.fullscreenLayer
        && self.fullscreenWindowType == BJLScWindowType_userVideo
        && self.fullscreenMediaInfoView == mediaInfoView) {
        [self resetFullscreenWindowType];
    }
    
    if (mediaInfoView) {
        [mediaInfoView removeFromSuperview];
        if (contentView == self.fullscreenLayer) {
            [self.fullscreenOverlayViewController showFillContentViewController:nil contentView:mediaInfoView ratio:0.0];
        }
        else {
            [contentView addSubview:mediaInfoView];
            [mediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(contentView);
            }];
        }
    }
}

// 替换全屏区域为某个视图，传空将归还当前全屏区域显示的视图，归还可能会因为其他位置归还，因此归还时将会重置状态，但是设置全屏视图必然通过此处调用，理想情况不会出现一次调用过程中发生全屏存在视图时，新的视图切换到全屏的情况
- (void)replaceFullscreenWithWindowType:(BJLScWindowType)windowType mediaInfoView:(nullable BJLScMediaInfoView *)mediaInfoView {
    // 如果当前全屏区域存在视图，归还当前的全屏视图
    if (self.majorWindowType == self.fullscreenWindowType) {
        // 归还大屏视图，可为任意情况
        switch (self.fullscreenWindowType) {
            case BJLScWindowType_ppt:
                [self replaceMajorContentViewWithPPTView];
                break;

            case BJLScWindowType_teacherVideo:
                [self replaceMajorContentViewWithTeacherMediaInfoView];
                break;

            case BJLScWindowType_userVideo:
                [self replaceMajorContentViewWithUserMediaInfoView:self.fullscreenMediaInfoView];
                break;

            default:
                break;
        }
    }
    else if (self.minorWindowType == self.fullscreenWindowType) {
        // 归还小屏视图，可为PPT和老师
        switch (self.fullscreenWindowType) {
            case BJLScWindowType_ppt:
                [self replaceMinorContentViewWithPPTView];
                break;

            case BJLScWindowType_teacherVideo:
                [self replaceMinorContentViewWithTeacherMediaInfoView];
                break;

            case BJLScWindowType_userVideo:
                // unsupported
                break;

            default:
                break;
        }
    }
    else if (self.secondMinorMediaInfoView && self.secondMinorWindowType == self.fullscreenWindowType) {
        // 归还 1v1 第二个小屏视图，可为学生和PPT，当前设计下与视频列表互斥，如果同时存在，不保证可用
        switch (self.fullscreenWindowType) {
            case BJLScWindowType_ppt:
                [self replaceSecondMinorContentViewWithPPTView];
                break;

            case BJLScWindowType_teacherVideo:
                // unsupported
                break;

            case BJLScWindowType_userVideo:
                [self replaceSecondMinorContentViewWithSecondMinorMediaInfoView];
                break;

            default:
                break;
        }
    }
    else if(self.fullscreenWindowType == BJLScWindowType_userVideo) {
        // 视频列表区域的视频
        [self resetFullscreenWindowType];
        [self.videosViewController updateCurrentMediaInfoViews];
    }
    // 如果需要设置新的全屏设置，设置新的全屏视图
    switch (windowType) {
        case BJLScWindowType_ppt:
            [self replaceWithPPTViewInContentView:self.fullscreenLayer];
            if (self.teacherExtraMediaInfoView) {
                self.teacherExtraMediaInfoView.isFullScreen = YES;
            }
            break;
            
        case BJLScWindowType_teacherVideo:
            [self replaceWithTeacherMediaInfoViewInContentView:self.fullscreenLayer];
            self.teacherMediaInfoView.isFullScreen = YES;
            break;
            
        case BJLScWindowType_userVideo:
            mediaInfoView.isFullScreen = YES;
            if (mediaInfoView.positionType == BJLScPositionType_videoList) {
                [self.videosViewController updateCurrentMediaInfoViews];
            }
            [self replaceContentView:self.fullscreenLayer mediaInfoView:mediaInfoView];
            break;

        default:
            break;
    }
    if (self.fullscreenWindowType != windowType) {
        self.fullscreenWindowType = windowType;
    }
    if (self.fullscreenMediaInfoView != mediaInfoView) {
        self.fullscreenMediaInfoView = mediaInfoView;
    }
}

- (void)resetFullscreenWindowType {
    self.fullscreenMediaInfoView.isFullScreen = NO;
    self.fullscreenWindowType = BJLScWindowType_none;
    [self.fullscreenOverlayViewController hide];
    self.fullscreenMediaInfoView = nil;
}

// 由于判断是否要同步切换时, 多次重复代码, 故此集中一个方法表示将老师窗口从小屏切换到PPT 大屏区域
- (void)switchTeacherViewFromMinorToMajorViewWithShouldSyncPPTVideoSwitch:(BOOL)shouldSyncPPTVideoSwitch {
    if (self.majorWindowType == BJLScWindowType_userVideo) {
        // 大屏是用户视频时，先把用户视频放回视频列表或者第二个小屏
        if (self.videosViewController) {
            [self.videosViewController resetVideo];
        }
        if (self.secondMinorMediaInfoView) {
            [self replaceSecondMinorContentViewWithSecondMinorMediaInfoView];
        }
    }
    [self replaceMinorContentViewWithPPTView];
    [self replaceMajorContentViewWithTeacherMediaInfoView];
    
    if (shouldSyncPPTVideoSwitch) {
        BJLError *error = [self.room.roomVM exchangeVideoPositonWithPPT:YES];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
    }
}

// 由于判断是否要同步切换时, 多次重复代码, 故此集中一个方法表示将ppt窗口从小屏切换到大屏区域
- (void)switchPPTViewFromMinorToMajorViewWithShouldSyncPPTVideoSwitch:(BOOL)shouldSyncPPTVideoSwitch {
    [self replaceMajorContentViewWithPPTView];
    [self replaceMinorContentViewWithTeacherMediaInfoView];

    if (shouldSyncPPTVideoSwitch) {
        BJLError *error = [self.room.roomVM exchangeVideoPositonWithPPT:NO];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
    }
}

#pragma mark - menu

- (void)showMenuForTeacherVideoWithSourceView:(nullable UIView *)sourceView {
    bjl_weakify(self);
    
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:@"视频"
                                message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];
    BOOL fullscreen = self.fullscreenWindowType == BJLScWindowType_teacherVideo;
    BJLMediaUser *mediaUser = self.teacherMediaInfoView.mediaUser;
    BOOL playingVideo = NO;
    if (self.room.loginUserIsPresenter) {
        playingVideo = self.room.recordingVM.recordingVideo;
    }
    else {
        if (!mediaUser.videoOn) {
            // 未打开摄像头的用户无菜单项
            return;
        }
        playingVideo = mediaUser.videoOn ? [self isVideoPlayingUser:mediaUser] : NO;
    }
    if (playingVideo) {
        // 在播放画面的用户可以全屏和放大
        [alert bjl_addActionWithTitle:fullscreen ? @"退出全屏" : @"全屏" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            bjl_strongify(self);
            if (fullscreen) {
                [self restoreCurrentFullscreenWindow];
            }
            else {
                [self replaceFullscreenWithWindowType:BJLScWindowType_teacherVideo mediaInfoView:self.teacherMediaInfoView];
            }
        }];
        if (!fullscreen) {
            // 不在全屏区域的用户可以放大
            [alert bjl_addActionWithTitle:@"放大窗口" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                if (self.room.loginUser.isTeacherOrAssistant && self.room.featureConfig.shouldSyncPPTVideoSwitch)  {
                    UIAlertController *alertViewController = [UIAlertController bjl_lightAlertControllerWithTitle:nil
                                                                                                          message:@"切换视频窗口与白板位置, 学生端是否同步切换?"
                                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                    [alertViewController bjl_addActionWithTitle:@"仅本地切换"
                                                          style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction * _Nonnull action) {
                        bjl_strongify(self);
                        [self switchTeacherViewFromMinorToMajorViewWithShouldSyncPPTVideoSwitch:NO];
                    }];
                    [alertViewController bjl_addActionWithTitle:@"同步切换"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                        bjl_strongify(self);
                        [self switchTeacherViewFromMinorToMajorViewWithShouldSyncPPTVideoSwitch:YES];
                    }];
                    if (self.presentedViewController) {
                        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                    }
                    [self presentViewController:alertViewController animated:YES completion:nil];
                }
                else {
                    [self switchTeacherViewFromMinorToMajorViewWithShouldSyncPPTVideoSwitch:NO];
                }
            }];
        }
    }
    
    if (self.room.loginUser.isTeacher
        && mediaUser.isAssistant
        && self.room.featureConfig.canChangePresenter) {
        if ([mediaUser isSameUser:self.room.onlineUsersVM.currentPresenter]) {
            [alert bjl_addActionWithTitle:@"收回主讲"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                [self.room.onlineUsersVM requestChangePresenterWithUserID:self.room.loginUser.ID];
            }];
        }
    }
    
    if (self.room.loginUserIsPresenter) {
        [alert bjl_addActionWithTitle:@"切换摄像头"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * _Nonnull action) {
            bjl_strongify(self);
            if (!self.room.recordingVM.recordingVideo) {
                return;
            }
            BJLError *error = [self.room.recordingVM updateUsingRearCamera:!self.room.recordingVM.usingRearCamera];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            }
        }];
        
        [alert bjl_addActionWithTitle:(self.room.recordingVM.videoBeautifyLevel == BJLVideoBeautifyLevel_off
                                       ? @"开启美颜" : @"关闭美颜")
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * _Nonnull action) {
            bjl_strongify(self);
            if (!self.room.recordingVM.recordingVideo) {
                return;
            }
            BJLError *error = [self.room.recordingVM updateVideoBeautifyLevel:(self.room.recordingVM.videoBeautifyLevel == BJLVideoBeautifyLevel_off
                                                                               ? BJLVideoBeautifyLevel_on : BJLVideoBeautifyLevel_off)];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            }
        }];
        
        [alert bjl_addActionWithTitle:self.room.recordingVM.recordingVideo ? @"关闭摄像头" : @"打开摄像头"
                                style:UIAlertActionStyleDestructive
                              handler:^(UIAlertAction * _Nonnull action) {
            bjl_strongify(self);
            BJLError *error = [self.room.recordingVM setRecordingAudio:self.room.recordingVM.recordingAudio
                                                        recordingVideo:!self.room.recordingVM.recordingVideo];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            }
            else {
                [self showProgressHUDWithText:(self.room.recordingVM.recordingVideo
                                               ? @"摄像头已打开"
                                               : @"摄像头已关闭")];
                if (fullscreen && !self.room.recordingVM.recordingVideo) {
                    // 关闭摄像头退出全屏
                    [self restoreCurrentFullscreenWindow];
                }
            }
        }];
    }
    else {
        if (mediaUser.videoOn) {
            // 用户开启了摄像头可以选择播放或者关闭画面
            [alert bjl_addActionWithTitle:playingVideo ? @"关闭视频" : @"开启视频"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                BJLError *error = [self.room.playingVM updatePlayingUserWithID:mediaUser.ID videoOn:!playingVideo mediaSource:mediaUser.mediaSource];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
                else {
                    // 主动关闭老师视频后不再自动打开
                    [self.teacherMediaInfoView updateCloseVideoPlaceholderHidden:!playingVideo];
                    [self updateAutoPlayVideoBlacklist:mediaUser add:playingVideo];
                    if (fullscreen && playingVideo) {
                        // 关闭画面退出全屏
                        [self restoreCurrentFullscreenWindow];
                    }
                }
            }];
        }
    }
    
    [alert bjl_addActionWithTitle:@"取消"
                            style:UIAlertActionStyleCancel
                          handler:nil];
    sourceView = sourceView ?: self.minorContentView;
    [self showAlertViewController:alert sourceView:sourceView];
}

- (void)showMenuForPPTViewWithSourceView:(nullable UIView *)sourceView {
    bjl_weakify(self);
    
    BJLMediaUser *mediaUser = self.teacherExtraMediaInfoView.mediaUser;
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:mediaUser ? @"视频" : @"白板/课件"
                                message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];
    BOOL fullscreen = self.fullscreenWindowType == BJLScWindowType_ppt;
    BOOL playingVideo = !mediaUser; // 无 mediaUser 即 PPT，此时是存在菜单项的
    if (mediaUser) {
        if (mediaUser.videoOn) {
            playingVideo = [self isVideoPlayingUser:mediaUser];
        }
        else {
            // 未打开摄像头的用户无菜单项
            return;
        }
    }
    if (playingVideo) {
        // PPT或者播放辅助摄像头可以全屏或放大
        [alert bjl_addActionWithTitle:fullscreen ? @"退出全屏" : @"全屏" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            bjl_strongify(self);
            if (fullscreen) {
                [self restoreCurrentFullscreenWindow];
            }
            else {
                [self replaceFullscreenWithWindowType:BJLScWindowType_ppt mediaInfoView:self.teacherExtraMediaInfoView];
            }
        }];
        if (!fullscreen) {
            // 不在全屏区域可以放大
            [alert bjl_addActionWithTitle:@"放大窗口" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                if (self.minorWindowType == BJLScWindowType_ppt) {
                    if (self.room.loginUser.isTeacherOrAssistant && self.room.featureConfig.shouldSyncPPTVideoSwitch)  {
                        bjl_strongify(self);
                        UIAlertController *alertViewController = [UIAlertController bjl_lightAlertControllerWithTitle:nil
                                                                                                              message:@"切换视频窗口与白板位置, 学生端是否同步切换?"
                                                                                                       preferredStyle:UIAlertControllerStyleAlert];
                        [alertViewController bjl_addActionWithTitle:@"仅本地切换"
                                                              style:UIAlertActionStyleCancel
                                                            handler:^(UIAlertAction * _Nonnull action) {
                            bjl_strongify(self);
                            [self switchPPTViewFromMinorToMajorViewWithShouldSyncPPTVideoSwitch:NO];
                        }];
                        [alertViewController bjl_addActionWithTitle:@"同步切换"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
                            bjl_strongify(self);
                            [self switchPPTViewFromMinorToMajorViewWithShouldSyncPPTVideoSwitch:YES];
                        }];
                        if (self.presentedViewController) {
                            [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                        }
                        [self presentViewController:alertViewController animated:YES completion:nil];
                    }
                    else {
                        [self switchPPTViewFromMinorToMajorViewWithShouldSyncPPTVideoSwitch:NO];
                    }
                }
                else if (self.secondMinorWindowType == BJLScWindowType_ppt) {
                    [self replaceMajorContentViewWithPPTView];
                    [self replaceSecondMinorContentViewWithSecondMinorMediaInfoView];
                }
            }];
        }
    }
    
    if (self.teacherExtraMediaInfoView) {
        if (mediaUser.videoOn) {
            // 开启的辅助摄像头可以播放或关闭
            [alert bjl_addActionWithTitle:playingVideo ? @"关闭视频" : @"开启视频"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                BJLError *error = [self.room.playingVM updatePlayingUserWithID:mediaUser.ID videoOn:!playingVideo mediaSource:mediaUser.mediaSource];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
                else {
                    // 主动关闭老师辅助摄像头后不再自动打开
                    [self.teacherExtraMediaInfoView updateCloseVideoPlaceholderHidden:!playingVideo];
                    [self updateAutoPlayVideoBlacklist:mediaUser add:playingVideo];
                    if (fullscreen && playingVideo) {
                        // 关闭画面退出全屏
                        [self restoreCurrentFullscreenWindow];
                    }
                }
            }];
        }
    }
    
    [alert bjl_addActionWithTitle:@"取消"
                            style:UIAlertActionStyleCancel
                          handler:nil];
    sourceView = sourceView ?: self.minorContentView;
    [self showAlertViewController:alert sourceView:sourceView];
}

- (void)showMenuForStudentVideoWithSourceView:(nullable UIView *)sourceView mediaInfoView:(BJLScMediaInfoView *)mediaInfoView {
    bjl_weakify(self);
    
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:@"视频"
                                message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];
    BOOL fullscreen = self.fullscreenWindowType == BJLScWindowType_userVideo && self.fullscreenMediaInfoView == mediaInfoView;
    BJLMediaUser *mediaUser = mediaInfoView.mediaUser;
    BOOL playingVideo = NO;
    if (!mediaUser && [self.room.loginUser isSameUser:mediaInfoView.user]) {
        playingVideo = self.room.recordingVM.recordingVideo;
    }
    else {
        if (mediaUser.videoOn) {
            playingVideo = [self isVideoPlayingUser:mediaUser];
        }
        else if(self.room.loginUser.isTeacherOrAssistant && self.room.loginUser.noGroup && mediaUser.isStudent) {
            // 未打开摄像头的用户根据当前登录用户的身份有点赞的操作，否则无菜单项
        }
        else {
            return;
        }
    }
    if (playingVideo) {
        // 在播放画面的用户可以全屏和放大
        [alert bjl_addActionWithTitle:fullscreen ? @"退出全屏" : @"全屏" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            bjl_strongify(self);
            if (fullscreen) {
                [self restoreCurrentFullscreenWindow];
            }
            else {
                [self replaceFullscreenWithWindowType:BJLScWindowType_userVideo mediaInfoView:mediaInfoView];
            }
        }];
        if (!fullscreen) {
            // 不在全屏区域可以放大
            [alert bjl_addActionWithTitle:@"放大窗口" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                if (self.majorWindowType == BJLScWindowType_teacherVideo) {
                    // 大屏是老师视频时，先把老师视频放回小屏
                    [self replaceMinorContentViewWithTeacherMediaInfoView];
                }
                [self replaceMajorContentViewWithUserMediaInfoView:mediaInfoView];
                [self replaceSecondMinorContentViewWithPPTView];
            }];
        }
        if (!self.room.featureConfig.disableGrantDrawing
            && self.room.loginUser.isTeacherOrAssistant
            && self.room.loginUser.noGroup
            && !mediaUser.isTeacherOrAssistant) {
            BOOL wasGranted = [self.room.drawingVM.drawingGrantedUserNumbers containsObject:mediaUser.number];
            [alert bjl_addActionWithTitle:wasGranted ? @"收回画笔" : @"授权画笔"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                BJLError *error =
                [self.room.drawingVM updateDrawingGranted:!wasGranted
                                               userNumber:mediaUser.number
                                                    color:nil];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
            }];
        }
    }
    
    if ([self.room.loginUser isSameUser:mediaInfoView.user]) {
        [alert bjl_addActionWithTitle:@"切换摄像头"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * _Nonnull action) {
            bjl_strongify(self);
            if (!self.room.recordingVM.recordingVideo) {
                return;
            }
            BJLError *error = [self.room.recordingVM updateUsingRearCamera:!self.room.recordingVM.usingRearCamera];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            }
        }];
        
        [alert bjl_addActionWithTitle:(self.room.recordingVM.videoBeautifyLevel == BJLVideoBeautifyLevel_off
                                       ? @"开启美颜" : @"关闭美颜")
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * _Nonnull action) {
            bjl_strongify(self);
            if (!self.room.recordingVM.recordingVideo) {
                return;
            }
            BJLError *error = [self.room.recordingVM updateVideoBeautifyLevel:(self.room.recordingVM.videoBeautifyLevel == BJLVideoBeautifyLevel_off
                                                                               ? BJLVideoBeautifyLevel_on : BJLVideoBeautifyLevel_off)];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            }
        }];
        
        [alert bjl_addActionWithTitle:self.room.recordingVM.recordingVideo ? @"关闭摄像头" : @"打开摄像头"
                                style:UIAlertActionStyleDestructive
                              handler:^(UIAlertAction * _Nonnull action) {
            bjl_strongify(self);
            BJLError *error = [self.room.recordingVM setRecordingAudio:self.room.recordingVM.recordingAudio
                                                        recordingVideo:!self.room.recordingVM.recordingVideo];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            }
            else {
                [self showProgressHUDWithText:(self.room.recordingVM.recordingVideo
                                               ? @"摄像头已打开"
                                               : @"摄像头已关闭")];
                if (fullscreen && !self.room.recordingVM.recordingVideo) {
                    // 关闭摄像头退出全屏
                    [self restoreCurrentFullscreenWindow];
                }
            }
        }];
    }
    else {
        if (mediaUser.videoOn) {
            // 用户开启了摄像头可以选择播放或者关闭画面
            [alert bjl_addActionWithTitle:playingVideo ? @"关闭视频" : @"开启视频"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                BJLError *error = [self.room.playingVM updatePlayingUserWithID:mediaUser.ID videoOn:!playingVideo mediaSource:mediaUser.mediaSource];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
                else {
                    // 主动关闭视频后不再自动打开
                    [mediaInfoView updateCloseVideoPlaceholderHidden:!playingVideo];
                    [self updateAutoPlayVideoBlacklist:mediaUser add:playingVideo];
                    if (fullscreen && playingVideo) {
                        // 关闭画面退出全屏
                        [self restoreCurrentFullscreenWindow];
                    }
                }
            }];
        }
        if (self.room.loginUser.isTeacherOrAssistant
            && self.room.loginUser.noGroup
            && mediaUser.isStudent) {
            // 当前是老师或者助教可以给用户点赞
            [alert bjl_addActionWithTitle:@"奖励"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                BJLError *error = [self.room.roomVM sendLikeForUserNumber:mediaUser.number];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
            }];
        }
    }
    
    [alert bjl_addActionWithTitle:@"取消"
                            style:UIAlertActionStyleCancel
                          handler:nil];
    sourceView = sourceView ?: self.secondMinorContentView;
    [self showAlertViewController:alert sourceView:sourceView];
}

- (void)showAlertViewController:(UIAlertController *)alertController sourceView:(UIView *)sourceView {
    if (alertController.preferredStyle == UIAlertControllerStyleActionSheet) {
        alertController.popoverPresentationController.sourceView = sourceView;
        alertController.popoverPresentationController.sourceRect = ({
            CGRect rect = sourceView.bounds;
            rect.origin.y = CGRectGetMaxY(rect) - 1.0;
            rect.size.height = 1.0;
            rect;
        });
        alertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
    }
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)updateAutoPlayVideoBlacklist:(BJLMediaUser *)user add:(BOOL)add {
    if (add) {
        [self.autoPlayVideoBlacklist addObject:[self videoKeyForUser:user]];
    }
    else {
        [self.autoPlayVideoBlacklist removeObject:[self videoKeyForUser:user]];
    }
}

- (BOOL)isVideoPlayingUser:(BJLMediaUser *)mediaUser {
    for (BJLMediaUser *user in [self.room.playingVM.videoPlayingUsers copy]) {
        if ([user isSameMediaUser:mediaUser]) {
            return YES;
        }
    }
    return NO;
}

@end
