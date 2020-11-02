//
//  BJLIcRoomViewController+room.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/20.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLIcRoomViewController+room.h"
#import "BJLIcRoomViewController+private.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcRoomViewController (room)

#pragma mark - room observers

- (void)makeRoomObservingBeforeEnterRoom {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room, enterRoomSuccess)
             observer:^BOOL{
                 bjl_strongify(self);
                 [self setupReachabilityManager];
                 [self classViewControllerEnterRoomSuccess:self];
                 [self.promptViewController enqueueWithPrompt:@"进入教室成功"];
                 
#if ! defined(__LP64__) || ! __LP64__ // #see CGFloat
                 [self.promptViewController enqueueWithPrompt:@"您的设备性能不足，可能无法正常上课，建议更换高性能设备以获得更好的体验"
                                                     duration:BJLIcAppearance.promptDuration
                                                    important:YES];
#endif
                 
                 // 进入教室成功才设置 block
                 [self.room setReloadingBlock:^(BJLLoadingVM * _Nonnull reloadingVM, void (^ _Nonnull callback)(BOOL)) {
                     bjl_strongify(self);
                     self.hasReload = YES;
                     [self.promptViewController enqueueWithPrompt:@"网络中断！正在尝试重新连接..." duration:0 important:YES];
                     [self makeObservingForLoadingVM:reloadingVM];
                     
//                     网络断开时，直接关闭计时器， 抢答器
                     [self.blackboardLayoutViewController destroyCountDownAndResponder];
                     callback(YES);
                 }];
                 
                 // VMs 配置项
                 self.room.drawingVM.showBrushOwnerNameWhenSelected = YES;
                 
                 [self makeObservingForLossRate];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room, enterRoomFailureWithError:)
             observer:^BOOL(BJLError *error) {
                 bjl_strongify(self);
                 [self classViewController:self enterRoomFailureWithError:error];
                 [self.promptViewController enqueueWithPrompt:[NSString stringWithFormat:@"进入教室失败:%td-%@", error.code, error.localizedDescription ?: error.localizedFailureReason]];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room, roomWillExitWithError:)
             observer:^BOOL(BJLError *error) {
                 bjl_strongify(self);
                 [self stopLossRateObservingTimer];

                 if (self.room.loginUser.isTeacher
                     && error.code != BJLErrorCode_exitRoom_loginConflict) {
                     if (self.room.serverRecordingVM.serverRecording) {
                         [self.room.serverRecordingVM requestServerRecording:NO]; // 退出教室停止录课
                     }
                     if (self.room.roomVM.liveStarted) {
                         [self.room.roomVM sendLiveStarted:NO]; // 退出教室下课
                         NSError *error = [self.room.chatVM sendForbidAll:NO];   // 解除禁言
                         if (error) {
                             [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
                         }
                         
                         [self.blackboardLayoutViewController closeWritingBoardWithGatherRequest]; //收回作答中的小黑板
                     }
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room, roomDidExitWithError:)
             observer:^BOOL(BJLError *error) {
                 bjl_strongify(self);
                 [self clean];
                 [self roomDidExitWithError:error];
                 return YES;
             }];
    
    [self bjl_kvo:BJLMakeProperty(self.room, reloading)
           filter:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        return [value boolValue] != [oldValue boolValue];
    }
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.reloading) {
            [self.promptViewController enqueueWithPrompt:@"本房间已切换线路，即将重新进入房间" duration:0 important:YES];
        }
        else {
            [self.promptViewController enqueueWithPrompt:@"重新连接成功"];
        }
        return YES;
    }];
}

- (void)makeRoomObserving {
    [self makeObserving];
    [self makeDocumentDisplayObserving];
}

- (void)makeObservingForLoadingVM:(BJLLoadingVM *)loadingVM {
    self.recordingAudioBeforeReload = self.room.recordingVM.recordingAudio;
    self.recordingVideoBeforeReload = self.room.recordingVM.recordingVideo;
    bjl_weakify(self);
    loadingVM.suspendBlock = ^(BJLLoadingStep step,
                               BJLLoadingSuspendReason reason,
                               BJLError *error,
                               void (^continueCallback)(BOOL isContinue)) {
        bjl_strongify(self);
        // 成功
        if (reason != BJLLoadingSuspendReason_errorOccurred) {
            continueCallback(YES);
            return;
        }
        
        NSInteger progress = 1;
        switch (step) {
            case BJLLoadingStep_checkNetwork:
                progress = 1;
                break;
                
            case BJLLoadingStep_loadRoomInfo:
                progress = 2;
                break;
                
            case BJLLoadingStep_connectRoomServer:
                progress = 3;
                break;
            
            case BJLLoadingStep_connectMasterServer:
                progress = 4;
                break;
                
            default:
                break;
        }
        
        if (error.code == BJLErrorCode_enterRoom_timeExpire) {
            BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcExitViewTimeOut message:[NSString stringWithFormat:@"教室已过期"]];
            [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
            [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.popoversLayer);
            }];
            [popoverViewController setConfirmCallback:^{
                bjl_strongify(self);
                continueCallback(NO);
                [self exit];
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        }
        else {
            BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcExitViewConnectFail message:[NSString stringWithFormat:@"网络连接失败（进度%ld/4），您可以退出或继续连接", (long)progress]];
            [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
            [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.popoversLayer);
            }];
            [popoverViewController setCancelCallback:^{
                bjl_strongify(self);
                continueCallback(NO);
                [self exit];
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
            [popoverViewController setConfirmCallback:^{
                continueCallback(YES);
            }];
        }
    };
    
    [self bjl_observe:BJLMakeMethod(loadingVM, loadingSuccess)
             observer:^BOOL() {
                 bjl_strongify(self);
                 [self.promptViewController enqueueWithPrompt:@"重新连接成功"];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(loadingVM, loadingFailureWithError:)
             observer:^BOOL(BJLError *error) {
                 bjl_strongify(self);
                 [self.promptViewController enqueueWithPrompt:@"连接失败"];
                 return YES;
             }];
}

- (void)makeObserving {
    bjl_weakify(self);
    
    /* 录课 */
    
    if (self.room.loginUser.isTeacherOrAssistant) {
        __block BOOL isInitial = YES;
        [self bjl_observe:BJLMakeMethod(self.room.serverRecordingVM, didReceiveServerRecording:fromUser:)
                 observer:(BJLMethodObserver)^BOOL(BOOL serverRecording, BJLUser *fromUser) {
            bjl_strongify(self);
            NSString *message = nil;
            switch (self.room.loginUser.role) {
                case BJLUserRole_teacher:
                    switch (fromUser.role) {
                        case BJLUserRole_teacher:
                            message = serverRecording ? @"已开启云端录制" : @"已停止录制";
                            break;
                            
                        case BJLUserRole_assistant:
                            message = serverRecording ? @"助教已开启云端录制" : @"助教已停止云端录制";
                            break;
                            
                        default:
                            break;
                    }
                    break;
                    
                case BJLUserRole_assistant:
                    switch (fromUser.role) {
                        case BJLUserRole_teacher:
                            message = serverRecording ? @"老师已开启云端录制" : @"老师已停止云端录制";
                            break;
                            
                        case BJLUserRole_assistant:
                            message = serverRecording ? @"已开启云端录制" : @"已停止录制";
                            break;
                            
                        default:
                            break;
                    }
                    break;
                    
                default:
                    break;
            }
            if (message.length && (!isInitial || serverRecording)) {
                [self.promptViewController enqueueWithPrompt:message];
            }
            isInitial = NO;
            return YES;
        }];
        [self bjl_observe:BJLMakeMethod(self.room.serverRecordingVM, requestServerRecordingDidFailed:)
                 observer:^BOOL(NSString *message) {
            bjl_strongify(self);
            [self.promptViewController enqueueWithPrompt:message];
            self.toolbarViewController.cloudRecordingButton.selected = NO;
            return YES;
        }];
        
        [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, speakingRequestDidReplyToUserID:allowed:success:)
                   filter:(BJLMethodObserver)^BOOL(NSString *userID, BOOL allowed, BOOL success) {
            // bjl_strongify(self);
            return allowed && !success;
        }
                 observer:(BJLMethodObserver)^BOOL(NSString *userID, BOOL allowed, BOOL success) {
            bjl_strongify(self);
            [self.promptViewController enqueueWithPrompt:@"坐席已满，请设置下台后继续操作"];
            return YES;
        }];
    }
    
    /* 上课 */
    
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, liveStarted)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        for (UIView *view in self.popoversLayer.subviews) {
            if ([view isKindOfClass:[BJLIcLiveStartView class]]) {
                [view removeFromSuperview];
            }
        }
        if (!self.room.roomVM.liveStarted
            && (self.room.loginUser.isTeacher || (self.room.loginUser.isAssistant && self.room.roomVM.getAssistantaAuthorityWithClassStartEnd))) {
            BJLIcLiveStartView *liveStartView = [[BJLIcLiveStartView alloc] init];
            [self.popoversLayer addSubview:liveStartView];
            [self.popoversLayer sendSubviewToBack:liveStartView];
            [liveStartView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.center.equalTo(self.widgetLayer);
                make.height.equalTo(@(BJLIcAppearance.liveStartButtonHeight));
                make.width.equalTo(@(BJLIcAppearance.liveStartButtonWidth));
            }];
            bjl_weakify(self);
            [liveStartView setLiveStartCallback:^BOOL{
                bjl_strongify(self);
                BJLError *error = [self.room.roomVM sendLiveStarted:YES];
                if (error) {
                    [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
                }
                return !error;
            }];
        }
        if ([old boolValue] != [now boolValue]) {
            [self.promptViewController enqueueWithPrompt:now.boolValue ? @"上课啦" : @"下课啦"];
        }
        return YES;
    }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.roomVM, liveStarted),
                         BJLMakeProperty(self.room.onlineUsersVM, activeUsersSynced)]
                filter:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        return self.room.onlineUsersVM.activeUsersSynced && self.room.roomVM.liveStarted;
    }
              observer:^(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.loginUser.isAssistant) {
            return;
        }
        BOOL isActive = NO;
        for (BJLUser *playingUser in self.room.playingVM.playingUsers) {
            if ([playingUser.ID isEqualToString:self.room.loginUser.ID]) {
                isActive = YES;
            }
        }
        // 上课并且加入了直播频道之后，如果在自己在上台用户中，开启音视频
        if (isActive || self.needActiveLoginUser) {
            if (self.hasReload) {
                // 重连的情况下读取断线前的状态
                BOOL success = [self updateRecordingAudio:self.recordingAudioBeforeReload recordingVideo:self.recordingVideoBeforeReload internal:YES];
                // 重新设置音视频状态成功后，重置标记
                if (success) {
                    self.hasReload = NO;
                    self.needActiveLoginUser = NO;
                }
            }
            else {
                [self activeCurrentLoginUser];
            }
        }
    }];
    
    /* 麦克风和摄像头权限 */
    __block UIAlertController *alertController = nil;
    [self.room.recordingVM setCheckMicrophoneAndCameraAccessCallback:^(BOOL microphone, BOOL camera, BOOL granted, UIAlertController * _Nullable alert) {
        bjl_strongify(self);
        if (granted) {
            return;
        }
        // 未授权时重置当前的 UI 状态
        if (microphone) {
            self.toolbarViewController.microphoneButton.selected = NO;
        }
        if (camera) {
            self.toolbarViewController.cameraButton.selected = NO;
        }
        if (alert) {
            if (self.presentedViewController) {
                if (self.presentedViewController == alertController && alert != alertController) {
                    [self.room.recordingVM setCheckMicrophoneAndCameraAccessActionCompletion:^{
                        bjl_strongify(self);
                        self.room.recordingVM.checkMicrophoneAndCameraAccessActionCompletion = nil;
                        alertController = alert;
                        if (self.presentedViewController) {
                            [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                        }
                        [self presentViewController:alert animated:YES completion:nil];
                    }];
                }
                else {
                    alertController = alert;
                    [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            }
            else {
                alertController = alert;
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
    }];
    
    /* 通用监听 */
    
    [self bjl_observe:BJLMakeMethod(self.room.recordingVM, recordingDidRemoteChangedRecordingAudio:recordingVideo:recordingAudioChanged:recordingVideoChanged:)
             observer:(BJLMethodObserver)^BOOL(BOOL recordingAudio, BOOL recordingVideo, BOOL recordingAudioChanged, BOOL recordingVideoChanged) {
        bjl_strongify(self);
        NSString *message = @"";
        if (recordingAudioChanged) {
            message = recordingAudio ? @"老师开启了你的麦克风" : @"老师关闭了你的麦克风";
        }
        else if (recordingVideoChanged) {
            message = recordingVideo ? @"老师开启了你的摄像头" : @"老师关闭了你的摄像头";
        }
        if (message.length) {
            [self.promptViewController enqueueWithPrompt:message];
        }
        return YES;
    }];
    [self bjl_kvo:BJLMakeProperty(self.room.chatVM, forbidAll)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        return now.boolValue != old.boolValue;
    }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:now.boolValue ? @"老师禁止聊天" : @"老师允许聊天"];
        return YES;
    }];
    [self bjl_kvo:BJLMakeProperty(self.room.chatVM, forbidMe)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        return now.boolValue != old.boolValue;
    }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:now.boolValue ? @"你已被禁言":@"你已被解除禁言"];
        return YES;
    }];
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, forbidSpeakingRequest)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        return now.boolValue != old.boolValue;
    }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:now.boolValue?@"老师禁止举手":@"老师允许举手"];
        self.requestSpeakinFullScreenButton.enabled = !self.room.speakingRequestVM.forbidSpeakingRequest && !self.room.recordingVM.recordingAudio;
        return YES;
    }];
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didUpdateWebPageWithURLString:open:isCache:)
             observer:(BJLMethodObserver)^BOOL(NSString *urlString, BOOL open, BOOL isCache) {
        bjl_strongify(self);
        if (!open && !isCache) {
            [self.promptViewController enqueueWithPrompt:@"网页已被收回"];
        }
        return YES;
    }];
    [self bjl_observe:BJLMakeMethod(self.room.recordingVM, didUpadateAllRecordingAudioMute:)
             observer:(BJLMethodObserver)^BOOL(BOOL mute) {
        bjl_strongify(self);
        if (mute) {
            [self.promptViewController enqueueWithPrompt:@"老师已关闭全体学生的麦克风"];
        }
        else {
            [self.promptViewController enqueueWithPrompt:@"老师已开启全体学生的麦克风"];
        }
        return YES;
    }];
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, didBlockUser:)
             observer:^BOOL(BJLUser *blockedUser) {
        bjl_strongify(self);
        if (self.room.loginUser.isTeacherOrAssistant) {
            [self.promptViewController enqueueWithPrompt:[NSString stringWithFormat:@"%@ 已被移出", blockedUser.displayName]];
        }
        return YES;
    }];
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, speakingRequestDidReplyEnabled:isUserCancelled:user:)
             observer:(BJLMethodObserver)^BOOL(BOOL speakingEnabled, BOOL isUserCancelled, BJLUser *user) {
        bjl_strongify(self);
        if ([user.ID isEqualToString:self.room.loginUser.ID] && !isUserCancelled) {
            if (speakingEnabled) {
                // 举手同意时，如果上台了，就打开音频，如果没上台，就打开音频和视频
                if ([self.room.playingVM playingUserWithID:self.room.loginUser.ID
                                                    number:self.room.loginUser.number
                                               mediaSource:BJLMediaSource_mainCamera]) {
                    [self updateRecordingAudio:YES];
                }
                else {
                    [self updateRecordingAudio:YES recordingVideo:YES];
                }
                [self.promptViewController enqueueWithPrompt:@"老师同意发言，已进入发言状态"];
            }
            else {
                [self updateRecordingAudio:NO];
                [self.promptViewController enqueueWithPrompt:@"稍等一下，一会请你回答"];
            }
        }
        return YES;
    }];
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didUpdateRoomLayout:)
             observer:(BJLMethodObserver)^BOOL(BJLRoomLayout roomLayout) {
        bjl_strongify(self);
        if (roomLayout == BJLRoomLayout_gallary) {
            // !!!: 交互已改，切换到画廊布局不收回窗口
            [self switchToGalleryLayout];
        }
        else if (roomLayout == BJLRoomLayout_blackboard) {
            [self switchToBlackboardLayout];
        }
        return YES;
    }];
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, didAddActiveUser:)
               filter:^BOOL(BJLUser *user) {
        bjl_strongify(self);
        return ![user.ID isEqualToString:self.room.loginUser.ID];
    }
             observer:^BOOL(BJLUser *user) {
        bjl_strongify(self);
        if (self.room.featureConfig.maxBackupUserCount > 0) {
            [self.promptViewController enqueueWithPrompt:[NSString stringWithFormat:@"%@ 已上台", user.displayName]];
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, didRemoveActiveUser:)
               filter:^BOOL(BJLUser *user) {
        bjl_strongify(self);
        return ![user.ID isEqualToString:self.room.loginUser.ID];
    }
             observer:^BOOL(BJLUser *user) {
        bjl_strongify(self);
        self.needActiveLoginUser = NO;
        if (self.room.featureConfig.maxBackupUserCount > 0) {
            [self.promptViewController enqueueWithPrompt:[NSString stringWithFormat:@"%@ 已下台", user.displayName]];
        }
        return YES;
    }];
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, didAddActiveUserDeny:responseCode:)
             observer:^BOOL(BJLUser *user, NSInteger responseCode) {
        bjl_strongify(self);
        NSString *message = (responseCode == 2) ? @"该学生已离开教室" : @"上台人数已满";
        [self.promptViewController enqueueWithPrompt:message];
        return YES;
    }];
    // 上麦失败的提示
    [self bjl_observe:BJLMakeMethod(self.room.recordingVM, recordingDidDeny)
             observer:^BOOL {
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:@"服务器拒绝发布音视频，音视频并发已达上限"];
        return YES;
    }];
    
    // webRTC 进入直播频道失败
    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, enterLiveChannelFailed)
             observer:^BOOL{
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:@"进入直播频道失败，请重试" duration:BJLIcAppearance.promptDuration important:YES];
        return YES;
    }];
    
    // webRTC 直播频道断开提示
    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, didLiveChannelDisconnectWithError:)
             observer:^BOOL(NSError *error){
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:@"直播频道已断开，请重试" duration:BJLIcAppearance.promptDuration important:YES];
        return YES;
    }];
    
    // webRTC 推流重试提示
    [self bjl_observe:BJLMakeMethod(self.room.recordingVM, republishing)
             observer:^BOOL {
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:@"音视频推送失败，自动重试中" duration:BJLIcAppearance.promptDuration important:YES];
        return YES;
    }];
    
    // webRTC 推流重试提示
    [self bjl_observe:BJLMakeMethod(self.room.recordingVM, publishFailed)
             observer:^BOOL {
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:@"音视频推送失败，请重试" duration:BJLIcAppearance.promptDuration important:YES];
        return YES;
    }];
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveAttentionWarning:)
             observer:^BOOL(NSString *content) {
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:content];
        return YES;
    }];
    
    /** 助教 */
    if (self.room.loginUser.isAssistant) {
        [self bjl_observe:BJLMakeMethod(self.room.playingVM, didAddActiveUser:)
                   filter:^BOOL(BJLUser *user) {
            bjl_strongify(self);
            return [user.ID isEqualToString:self.room.loginUser.ID];
        }
                 observer:^BOOL(BJLUser *user) {
            // 上台后开启视频
            bjl_strongify(self);
            if (self.room.roomVM.liveStarted) {
                [self updateRecordingVideo:YES];
            }
            return YES;
        }];
    }
    
    [self bjl_kvo:BJLMakeProperty(self.room, featureConfig)
           filter:^BOOL(NSString *_Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        return  !!value;
    }
         observer:^BOOL(id _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if(self.room.featureConfig.backgroundURLString.length) {
            [self.backgroundImageView bjl_setImageWithURL:[NSURL URLWithString:self.room.featureConfig.backgroundURLString] placeholder:nil completion:nil];
        }
        return YES;
    }];
    
    //    全屏下的举手按钮
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, didReceiveSpeakingRequestFromUser:)
             observer:^BOOL(BJLUser *user) {
        bjl_strongify(self);
        // 收到举手提示
        [self.promptViewController enqueueWithSpecialPrompt:@"教室内有学生举手" duration:BJLIcAppearance.promptDuration important:NO];
        return YES;
    }];
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, recordingAudio)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        self.requestSpeakinFullScreenButton.enabled = !now.boolValue && !self.room.speakingRequestVM.forbidSpeakingRequest;
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
            self.requestSpeakinFullScreenButton.selected = NO;
        }
        else {
            CGFloat progress = timeRemaining.doubleValue / self.room.speakingRequestVM.speakingRequestTimeoutInterval; // 1.0 ~ 0.0
            self.speakRequestProgressView.progress = progress;
        }
        return YES;
    }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.requestSpeakinFullScreenButton, selected),
                         BJLMakeProperty(self.requestSpeakinFullScreenButton, enabled)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        // 举手操作属于禁用状态时不展示背景圆,更加突出不可操作
        if (self.requestSpeakinFullScreenButton.selected || self.requestSpeakinFullScreenButton.enabled) {
            [self.requestSpeakinFullScreenButton bjlic_drawCircleBackgroundViewWithColor:[UIColor bjl_colorWithHex:0X9FA8B5 alpha:0.3] hidden:NO];
            self.requestSpeakinFullScreenButton.layer.borderWidth = 1.0;
        }
        else {
            [self.requestSpeakinFullScreenButton bjlic_drawCircleBackgroundViewWithColor:[UIColor clearColor] hidden:YES];
            self.requestSpeakinFullScreenButton.layer.borderWidth = 0;
        }
    }];
    
    if (self.room.loginUser.isStudent) {
        [self makeObservingForLamp];
        [self makeObservingForEvaluation];
    }
}

- (void)makeDocumentDisplayObserving {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.blackboardLayoutViewController, documentWindowDisplayInfos)
         observer:^BOOL(NSArray<BJLWindowDisplayInfo *> * _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        // 没有画笔权限的用户不需要处理
        BOOL enable = self.room.drawingVM.drawingGranted || self.room.drawingVM.writingBoardEnabled || self.room.documentVM.authorizedPPT;
        if (!self.room.loginUser.isTeacherOrAssistant && !enable) {
            return YES;
        }
        [self remakeToolboxViewControllerWithCurrentDocumentDisplayInfo:NO];
        return YES;
    }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.blackboardLayoutViewController, videoWindowDisplayInfos),
                         BJLMakeProperty(self.blackboardLayoutViewController, documentWindowDisplayInfos),
                         BJLMakeProperty(self.blackboardLayoutViewController, webDocumentWindowDisplayInfos)]
                filter:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        return !self.room.loginUser.isTeacherOrAssistant;
    }
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        // 如果存在全屏的窗口，更新全屏下的举手按钮
        NSArray *allDisplayInfos = [NSArray arrayWithArray:self.blackboardLayoutViewController.documentWindowDisplayInfos];
        allDisplayInfos = [allDisplayInfos arrayByAddingObjectsFromArray:self.blackboardLayoutViewController.webDocumentWindowDisplayInfos];
        allDisplayInfos = [allDisplayInfos arrayByAddingObjectsFromArray:self.blackboardLayoutViewController.videoWindowDisplayInfos];
        BOOL existFullScreenWindow = NO;
        for (BJLWindowDisplayInfo *displayInfo in allDisplayInfos) {
            if (displayInfo.isFullScreen) {
                existFullScreenWindow = YES;
                break;
            }
        }
        self.requestSpeakinFullScreenButton.hidden = !existFullScreenWindow;
        self.requestSpeakinFullScreenButton.enabled = !self.room.speakingRequestVM.forbidSpeakingRequest && !self.room.recordingVM.recordingAudio;
    }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.drawingVM, drawingGranted),
                         BJLMakeProperty(self.room.drawingVM, writingBoardEnabled),
                         BJLMakeProperty(self.room.documentVM, authorizedPPT)]
                filter:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        return !self.room.loginUser.isTeacherOrAssistant;
    }
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        BOOL enable = self.room.drawingVM.drawingGranted || self.room.drawingVM.writingBoardEnabled || self.room.documentVM.authorizedPPT;
        if (!enable) {
            // 取消授权时清理选中状态，重新布局
            [self.toolboxViewController cancelCurrentSelectedButton];
        }
        [self remakeToolboxViewControllerWithCurrentDocumentDisplayInfo:YES];
    }];
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, didAddActiveUser:)
               filter:^BOOL(BJLUser *user) {
        bjl_strongify(self);
        return [user.ID isEqualToString:self.room.loginUser.ID];
    }
             observer:^BOOL(BJLUser *user) {
        // 上台后开启视频
        bjl_strongify(self);
        [self activeCurrentLoginUser];
        return YES;
    }];
}

- (void)roomDidExitWithError:(BJLError *)error {
    // !error: 主动退出
    // BJLErrorCode_exitRoom_disconnected: self.loadingViewController 已处理
    if (!error || error.code == BJLErrorCode_exitRoom_disconnected) {
        [self dismissWithError:error];
        return;
    }
    
    NSString *message = [NSString stringWithFormat:@"%@: %@(%td)",
                         error.localizedDescription,
                         error.localizedFailureReason ?: @"",
                         error.code];
    if (error.code == BJLErrorCode_exitRoom_kickout) {
        message = @"您已被移出教室";
    }
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcExitViewKickOut message:message];
    [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.popoversLayer);
    }];
    bjl_weakify(self);
    [popoverViewController setConfirmCallback:^{
        bjl_strongify(self);
        [self exit];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

#pragma mark - lamp

- (void)makeObservingForLamp {
    // 使用 Initial 会导致开始监听时触发两次
    bjl_weakify(self);
    [self bjl_kvoMerge:@[BJLMakeProperty(self, customLampContent),
                         BJLMakeProperty(self.room.roomVM, lamp)]
               options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
              observer:^(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  [self updateLamp];
              }];
    // 第一次手动触发
    [self updateLamp];
}

- (void)updateLamp {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
    
    BJLLamp *lamp = self.room.roomVM.lamp;
    NSString *lampContent = self.customLampContent ?: lamp.content;
    if (!lampContent.length || lamp.alpha == 0) {
        return;
    }
    
    // lampLabel
    UILabel *lampLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = [[UIColor bjl_colorWithHexString:@"#090300" alpha:0.3] colorWithAlphaComponent:lamp.alpha];
        label.layer.masksToBounds = YES;
        label.layer.cornerRadius = 1.0;
        label.font = [UIFont systemFontOfSize:lamp.fontSize];
        label.textColor = [UIColor bjl_colorWithHexString:lamp.color alpha:lamp.alpha];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = lampContent;
        label.numberOfLines = 1;
        [label sizeToFit];
        label.userInteractionEnabled = NO;
        label;
    });
    
    // 文字边距
    CGSize labelSize = CGSizeMake(lampLabel.bounds.size.width + 20.0, lampLabel.bounds.size.height + 10.0);
    // 垂直方向位置比例，产生从 垂直方向最小比例（精确到小数点后 3 位） 到 1 之间的一个随机比例，确定跑马灯的垂直方向的位置
    CGFloat containerViewWidth = self.view.bounds.size.width;
    CGFloat containerViewHeight = self.view.bounds.size.height;
    CGFloat minVerticalRatio = 0;
    if  (containerViewHeight > 0) {
        minVerticalRatio = labelSize.height / (containerViewHeight);
    }
    NSInteger temp = ceil(minVerticalRatio * 1000);
    CGFloat verticalRatio = ((arc4random() % (1000 - temp)) + temp) / 1000.0;
    
    [self.lampView addSubview:lampLabel];
    [lampLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.lampView.bjl_left).offset(labelSize.width + containerViewWidth);
        make.bottom.equalTo(self.lampView).multipliedBy(verticalRatio);
        make.size.equal.sizeOffset(labelSize);
    }];
    [self.lampView layoutIfNeeded];
    
    // animation
    CGFloat speed = 30.0; // 跑马灯速度
    NSTimeInterval duration = (labelSize.width + containerViewWidth) / speed;
    bjl_weakify(self);
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         bjl_strongify(self);
                         // 设置动画结束后的最终位置
                         [lampLabel bjl_updateConstraints:^(BJLConstraintMaker *make) {
                             make.right.equalTo(self.lampView.bjl_left);
                         }];
                         [self.lampView layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         [lampLabel removeFromSuperview];
                     }];
    // 显示间隔
    [self performSelector:_cmd withObject:nil afterDelay:(duration + 60)];
}

#pragma mark - evaluation

- (void)makeObservingForEvaluation {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, liveStarted)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        return old.boolValue != now.boolValue;
    }
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition || now.boolValue) {
            return YES;
        }
        if (!self.room.featureConfig.enableEvaluation || !self.room.featureConfig.evaluationSwitch) {
            return YES;
        }

        BJLIcEvaluationViewController *evaluationVC = [[BJLIcEvaluationViewController alloc] initWithRoom:self.room];
        [self bjl_addChildViewController:evaluationVC superview:self.fullscreenLayer];
        [evaluationVC.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
            BOOL iphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
            if (iphone) {
                make.edges.equalTo(self.fullscreenLayer).insets(UIEdgeInsetsMake(20.0, 16.0, 20.0, 16.0));
            }
            else {
                make.center.equalTo(self.fullscreenLayer);
                make.width.equalTo(@540.0).priorityHigh();
                make.height.equalTo(@600.0).priorityHigh();
            }
        }];
        return YES;
    }];
}

#pragma mark - reachability

- (void)setupReachabilityManager {
    self.reachabilityManager = ({
        __block BOOL isFirstTime = YES;
        bjl_weakify(self);
        BJLAFNetworkReachabilityManager *manager = [BJLAFNetworkReachabilityManager manager];
        [manager setReachabilityStatusChangeBlock:^(BJLAFNetworkReachabilityStatus status) {
            bjl_strongify(self);
            if (status != BJLAFNetworkReachabilityStatusReachableViaWWAN) {
                return;
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (status != BJLAFNetworkReachabilityStatusReachableViaWWAN) {
                    return;
                }
                if (isFirstTime) {
                    isFirstTime = NO;
                    UIAlertController *alert = [UIAlertController
                                                bjl_lightAlertControllerWithTitle:@"正在使用3G/4G网络，可手动关闭视频以减少流量消耗"
                                                message:nil
                                                preferredStyle:UIAlertControllerStyleAlert];
                    [alert bjl_addActionWithTitle:@"知道了"
                                            style:UIAlertActionStyleCancel
                                          handler:nil];
                    if (self.presentedViewController) {
                        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                    }
                    [self presentViewController:alert animated:YES completion:nil];
                }
                else {
                    [self showProgressHUDWithText:@"正在使用3G/4G网络"];
                }
            });
        }];
        [manager startMonitoring];
        manager;
    });
}

#pragma mark - lossRate

- (void)makeObservingForLossRate {
    self.lossRateDictionary = [NSMutableDictionary new];
    [self restartLossRateObservingTimer];
    
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, mediaLossRateDidUpdateWithUser:videoLossRate:audioLossRate:)
             observer:(BJLMethodObserver)^BOOL(BJLMediaUser *user, CGFloat videoLossRate, CGFloat audioLossRate){
        bjl_strongify(self);
        // 目前只统计所有用户主摄流的丢包
        if(user.mediaSource != BJLMediaSource_mainCamera) {
            return YES;
        }
        
        CGFloat packageLossRate = MIN(MAX(0.0, videoLossRate), 100.0);
        // 尝试舍弃丢包100%的情况, 防止正常网络下偶现丢包100%, 导致app弹框强提示. 如果网络实际丢包持续到达100%, 那么上层信令服务器应该已经断开了
        if(packageLossRate == 100) {
            return YES;
        }
        
        NSString *userKey = [self userLossRateKeyWithUserID:user.ID mediaSource:user.mediaSource];
        NSMutableArray<NSDictionary *> *lossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
        if (!lossRateArray) {
            lossRateArray = [NSMutableArray new];
        }
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
        NSDictionary<NSNumber *, NSNumber *> *lossRateDic = [NSDictionary dictionaryWithObject:@(packageLossRate) forKey:@(timeInterval)];
        [lossRateArray bjl_addObject:lossRateDic];
        [self.lossRateDictionary bjl_setObject:lossRateArray forKey:userKey];
        return YES;
    }];
}

- (void)restartLossRateObservingTimer {
    [self stopLossRateObservingTimer];
    bjl_weakify(self);
    self.lossRateObservingTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify_ifNil(self) {
            [timer invalidate];
            return;
        }
        /* 弱网提示
         每个用户单独计算M秒内平均丢包率;
         自己上行有丢包时, 在自己的界面提示/直播间界面提示;
         自己下行有丢包时, ((有上行丢包&&下行丢包低于上行2倍) || 无上行)->提示自己网络差, (有上行&&上行无丢包 || 下行丢包高于上行两倍)-> 对方网络差
         */
        
        NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];
        
        /** 计算当前登录用户的丢包率 */
        CGFloat loginUserLossRate = 0.0f;
        NSString *loginUserKey = [self userLossRateKeyWithUserID:self.room.loginUser.ID mediaSource:BJLMediaSource_mainCamera];
        NSMutableArray<NSDictionary *> *loginUserLossRateArray = [[self.lossRateDictionary bjl_arrayForKey:loginUserKey] mutableCopy];
        NSInteger loginUserLossRateArrayCount = [loginUserLossRateArray count];
        if (loginUserLossRateArrayCount) {
            CGFloat totalLossRate = 0.0f;
            for (NSDictionary<NSNumber *, NSNumber *> *lossRateDic in [loginUserLossRateArray copy]) {
                // 读取用户丢包率数据中的时间，去掉 lossRateObservingTimeInterval 之外的时间
                for (NSNumber *timeInterval in [lossRateDic.allKeys copy]) {
                    if (nowTimeInterval - [timeInterval bjl_doubleValue] > self.room.featureConfig.lossRateRetainTime) {
                        // 大于 lossRateRetainTime 的数据移除
                        [loginUserLossRateArray removeObject:lossRateDic];
                    }
                    else {
                        // 否则加入计算
                        totalLossRate += [lossRateDic bjl_floatForKey:timeInterval];
                    }
                }
            }
            loginUserLossRate = (loginUserLossRateArray.count > 0) ? totalLossRate / loginUserLossRateArray.count : 0.0f;
            // 更新丢包率的字典
            [self.lossRateDictionary bjl_setObject:loginUserLossRateArray forKey:loginUserKey];
        }
        BJLNetworkStatus loginUserLossRateStatus = [self netWorkStatusWithLossRate:loginUserLossRate];
        // 自己是否有上行
        BOOL hasUpPackage = self.room.recordingVM.recordingVideo || self.room.recordingVM.recordingAudio;
        // 自己上行是否丢包
        BOOL hasUpPackageLoss = hasUpPackage && loginUserLossRateStatus != BJLNetworkStatus_normal;
        BOOL shouldLoginUserShowWeakNetWork = hasUpPackageLoss;
        
        /** 计算下行的丢包率，取的是所有用户下行丢包率的均值 */
        CGFloat downloadLossRate = 0.0f;
        for (NSString *userKey in [self.lossRateDictionary.allKeys copy]) {
            NSString *userID = [self userIDForUserLossRateKey:userKey];
            if([userID isEqualToString:self.room.loginUser.ID]) {
                continue;
            }
            NSMutableArray<NSDictionary *> *lossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
            NSInteger count = lossRateArray.count;
            if (count <= 0) {
                continue;
            }
            CGFloat totalLossRate = 0.0;
            for (NSDictionary<NSNumber *, NSNumber *> *lossRateDic in [lossRateArray copy]) {
                // 读取用户丢包率数据中的时间，去掉 lossRateObservingTimeInterval 之外的时间
                for (NSNumber *timeInterval in [lossRateDic.allKeys copy]) {
                    if (nowTimeInterval - [timeInterval bjl_doubleValue] > self.room.featureConfig.lossRateRetainTime) {
                        // 大于 lossRateObservingTimeInterval 的数据移除
                        [lossRateArray removeObject:lossRateDic];
                    }
                    else {
                        // 否则加入计算
                        totalLossRate += [lossRateDic bjl_floatForKey:timeInterval];
                    }
                }
            }
            // 更新丢包率的字典
            [self.lossRateDictionary bjl_setObject:lossRateArray forKey:userKey];
            CGFloat lossRate = (lossRateArray.count > 0) ? totalLossRate / lossRateArray.count : 0.0f;
            BJLNetworkStatus status = [self netWorkStatusWithLossRate:lossRate];
            downloadLossRate += lossRate;
            
            /** 显示弱网逻辑 */
            // (自己无上行&&有下行丢包) || (上行丢包&&下行低于上行两倍丢包)
            if((status != BJLNetworkStatus_normal
                     && !hasUpPackage)
                    || (hasUpPackageLoss && lossRate <= loginUserLossRate * 2
                        && status != BJLNetworkStatus_normal)) {
                // 直接自己窗口展示弱网
                shouldLoginUserShowWeakNetWork = YES;
                loginUserLossRateStatus = hasUpPackageLoss ? loginUserLossRateStatus : status;
            }
        } // 遍历所有丢包率数组结束
        
        // 计算下行丢包率
        NSInteger downUserCount = (self.lossRateDictionary.allKeys.count - (loginUserLossRate > 0.0 ? 1 : 0 ));
        if(downUserCount > 0) {
            downloadLossRate = downloadLossRate / (self.lossRateDictionary.allKeys.count - (loginUserLossRate > 0.0 ? 1 : 0 ));
        }
        else {
            downloadLossRate = 0.0f;
        }
        BJLNetworkStatus downloadLossStatus = [self netWorkStatusWithLossRate:downloadLossRate];
        
        // 刷新状态栏丢包率 UI
        [self.statusBarViewController updateUploadPackageLossRate:loginUserLossRate networkStatus:loginUserLossRateStatus];
        [self.statusBarViewController updateDownloadPackageLossRate:downloadLossRate networkStatus:downloadLossStatus];
        // 更新弱网提示
        if(shouldLoginUserShowWeakNetWork) {
            [self updateNetWorkStatus:loginUserLossRateStatus];
        }
    }];
}

- (NSString *)userLossRateKeyWithUserID:(NSString *)userID mediaSource:(BJLMediaSource)mediaSource {
    return [NSString stringWithFormat:@"%@-%td", userID, mediaSource];
}

- (BJLMediaSource)mediaSourceForUserLossRateKey:(NSString *)key{
    NSString *separator = @"-";
    BJLMediaSource mediaSource = BJLMediaSource_mainCamera;
    NSRange separatorRange = [key rangeOfString:separator];
    if (separatorRange.location != NSNotFound) {
        mediaSource = [key substringFromIndex:separatorRange.location + separatorRange.length].integerValue;
    }
    return mediaSource;
}
- (nullable NSString *)userIDForUserLossRateKey:(NSString *)key{
    NSString *separator = @"-";
    NSString *userID = nil;
    NSRange separatorRange = [key rangeOfString:separator];
    if (separatorRange.location != NSNotFound) {
        userID = [key substringToIndex:separatorRange.location];
    }
    return userID;
}

- (void)stopLossRateObservingTimer {
    if (self.lossRateObservingTimer || [self.lossRateObservingTimer isValid]) {
        [self.lossRateObservingTimer invalidate];
        self.lossRateObservingTimer = nil;
    }
}

- (BJLNetworkStatus)netWorkStatusWithLossRate:(CGFloat)lossRate {
    NSMutableArray *lossRateArray = [self.room.featureConfig.lossRateLevelArray copy];
    
    BJLNetworkStatus preLossRateLevel = BJLNetworkStatus_normal;
    BJLNetworkStatus currentLossRateLevel = BJLNetworkStatus_normal;
    for (NSInteger index = 0 ; index < [lossRateArray count]; index++) {
        NSNumber *nmber = [lossRateArray objectAtIndex:index];
        CGFloat lossRateLevel = nmber.floatValue;
        if(preLossRateLevel == BJLNetworkStatus_normal && lossRateLevel > 0 && lossRateLevel <= 100) {
            preLossRateLevel = (BJLNetworkStatus)index;
        }
        
        if(lossRateLevel <= 0 || lossRateLevel > 100) {
            continue;
        }
        
        if(lossRateLevel <= lossRate) {
            preLossRateLevel = (BJLNetworkStatus)index;
            continue;
        }
        
        if(lossRateLevel > lossRate) {
            currentLossRateLevel = (BJLNetworkStatus)index;
            break;
        }
    }
    
    if(currentLossRateLevel == BJLNetworkStatus_normal && preLossRateLevel == BJLNetworkStatus_normal) {
        return BJLNetworkStatus_normal;
    }
    
    if(currentLossRateLevel == BJLNetworkStatus_normal) {
        currentLossRateLevel = (preLossRateLevel + 1 <= BJLNetworkStatus_Bad_level5) ? (preLossRateLevel + 1) : BJLNetworkStatus_Bad_level5;
    }
    else {
        currentLossRateLevel = (currentLossRateLevel <= BJLNetworkStatus_Bad_level5) ? currentLossRateLevel : BJLNetworkStatus_Bad_level5;
    }
    return currentLossRateLevel;
}

- (void)updateNetWorkStatus:(BJLNetworkStatus)status {
    if(status == BJLNetworkStatus_Bad_level4 || status == BJLNetworkStatus_Bad_level5) {
        [self.promptViewController enqueueWithSpecialPrompt:@"您的网络情况极差" duration:BJLIcAppearance.promptDuration important:NO];
    }

    /*
     由于目前丢包率不稳定, 容易瞬时达到峰值, 暂时先注释掉弹框提示
    if(status == BJLNetworkStatus_Bad_level5 && !self.hasShowVeryBadAlert) {
        self.hasShowVeryBadAlert = YES;
        BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcHighLoassRate message:@"哎呀，您的网络开小差了，检测网络后重新进入教室"];
        [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
        bjl_weakify(self);
        [popoverViewController setConfirmCallback:^{
            bjl_strongify(self);
            self.hasShowVeryBadAlert = NO;
            [self exit];
            [self dismissViewControllerAnimated:YES completion:nil];

        }];
        [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.popoversLayer);
        }];
    }
     */
}
@end

NS_ASSUME_NONNULL_END
