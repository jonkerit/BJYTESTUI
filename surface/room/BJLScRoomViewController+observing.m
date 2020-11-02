//
//  BJLScRoomViewController+observing.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScRoomViewController+observing.h"
#import "BJLScRoomViewController+private.h"
#import "BJLLikeEffectViewController.h"

@implementation BJLScRoomViewController (observing)

- (void)makeObservingBeforeEnterRoom {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room, enterRoomSuccess)
             observer:^BOOL {
        bjl_strongify(self);
        
        [self roomViewControllerEnterRoomSuccess:self];
        self.reachability = ({
            __block BOOL isFirstTime = YES;
            BJLAFNetworkReachabilityManager *reachability = [BJLAFNetworkReachabilityManager manager];
            [reachability setReachabilityStatusChangeBlock:^(BJLAFNetworkReachabilityStatus status) {
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
            [reachability startMonitoring];
            reachability;
        });
        
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room, enterRoomFailureWithError:)
             observer:^BOOL(BJLError *error) {
        bjl_strongify(self);
        [self roomViewController:self enterRoomFailureWithError:error];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room, roomWillExitWithError:)
             observer:^BOOL(BJLError *error) {
        bjl_strongify(self);
        if (self.room.loginUser.isTeacher
            && error.code != BJLErrorCode_exitRoom_loginConflict) {
            if (self.room.serverRecordingVM.serverRecording) {
                [self.room.serverRecordingVM requestServerRecording:NO]; // 退出教室停止录课
            }
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room, roomDidExitWithError:)
             observer:^BOOL(BJLError *error) {
        bjl_strongify(self);
        [self roomDidExitWithError:error];
        return YES;
    }];
}

- (void)makeObserving {
    bjl_weakify(self);
    
#pragma mark - common
    
    [self bjl_kvo:BJLMakeProperty(self.room, state)
           filter:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        return (BJLRoomState)[value integerValue] == BJLRoomState_connected;
    }
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self makeObservingWhenEnteredInRoom];
        return NO;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.recordingVM, recordingDidDeny)
             observer:^BOOL {
        bjl_strongify(self);
        [self showProgressHUDWithText:@"服务器拒绝发布音视频，音视频并发已达上限"];
        return YES;
    }];
    
#pragma mark - 上课状态
    
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, liveStarted)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        // 上课按钮
        if (self.room.loginUser.isTeacher
            || (self.room.loginUser.isAssistant && self.room.roomVM.getAssistantaAuthorityWithClassStartEnd)) {
            self.liveStartButton.hidden = now.boolValue;
        }
        if (now.boolValue != old.boolValue) {
            // 显示提示
            [self showProgressHUDWithText:now.boolValue ? @"上课啦" : @"下课啦"];
            // 上下课重置全屏状态
            if (self.fullscreenWindowType != BJLScWindowType_none) {
                [self restoreCurrentFullscreenWindow];
            }
        }
        // 上课开启采集
        if (self.room.roomVM.liveStarted) {
            [self autoStartRecordingAudioAndVideoForce:YES];
        }
        else {
            [self.room.recordingVM setRecordingAudio:NO recordingVideo:NO];
        }
        return YES;
    }];
    
#pragma mark - 视频列表
    
    if (!self.is1V1Class) {
        [self bjl_kvoMerge:@[BJLMakeProperty(self.room.recordingVM, recordingVideo),
                             BJLMakeProperty(self.room.mainPlayingAdapterVM, playingUsers),
                             BJLMakeProperty(self.room.extraPlayingAdapterVM, playingUsers)]
                  observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            [self updateVideosConstraintsWithCurrentPlayingUsers];
        }];
    }
    
#pragma mark - 主讲视频
    
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, currentPresenter)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.onlineUsersVM.currentPresenter) {
            [self updateTeacherVideoView];
        }
        else if (self.teacherMediaInfoView) {
            // 全屏区域，老师消失，复原全屏
            if (self.teacherMediaInfoView.isFullScreen) {
                [self restoreCurrentFullscreenWindow];
            }
            [self.teacherMediaInfoView removeFromSuperview];
            [self.teacherMediaInfoView destroy];
            self.teacherMediaInfoView = nil;
            [self updateTeacherVideoPlaceholderView];
        }
        [self updateVideosConstraintsWithCurrentPlayingUsers];
        return YES;
    }];
    
#pragma mark - 学生视频
    
    if (self.is1V1Class) {
        [self bjl_kvo:BJLMakeProperty(self.room.playingVM, playingUsers)
             observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            BJLMediaUser *targetUser = nil;
            for (BJLMediaUser *user in [self.room.playingVM.playingUsers copy]) {
                if (user.isStudent) {
                    targetUser = user;
                    break;
                }
            }
            if (self.room.loginUser.isTeacherOrAssistant) {
                if ([self.secondMinorMediaInfoView.mediaUser isSameUser:targetUser]) {
                    return YES;
                }
                [self updateSecondMinorContentViewWithUser:targetUser recording:NO];
            }
            else {
                if (!self.secondMinorMediaInfoView) {
                    // 有其他学生在，理论上不应存在
                    if (targetUser) {
                        [self updateSecondMinorContentViewWithUser:targetUser recording:NO];
                    }
                    else {
                        // 显示当前学生状态
                        [self updateSecondMinorContentViewWithUser:nil recording:YES];
                    }
                }
            }
            return YES;
        }];
    }
    
#pragma mark - majorWindowType, minorWindowType
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self, majorWindowType),
                         BJLMakeProperty(self, fullscreenWindowType)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updatePPTUserInteractionEnable];
    }];
    
#pragma mark - ppt 页码
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.documentVM, allDocuments),
                         BJLMakeProperty(self.room.slideshowViewController, viewType),
                         BJLMakeProperty(self.room.documentVM, currentSlidePage),
                         BJLMakeProperty(self.room.slideshowViewController, pageIndex)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        NSInteger pageIndex = self.room.slideshowViewController.pageIndex;
        BJLDocument *whiteboardDocument = [self.room.documentVM documentWithID:BJLBlackboardID];
        NSInteger whiteboardPageCount = MAX(whiteboardDocument.pageInfo.pageCount, 1);
        if (pageIndex + 1 <= whiteboardPageCount) {
            [self.room.slideshowViewController.pageControlButton setTitle:(whiteboardPageCount > 1 ? [NSString stringWithFormat:@"白板%td", pageIndex + 1] : @"白板") forState:UIControlStateNormal];
        }
        else {
            [self.room.slideshowViewController.pageControlButton setTitle:[NSString stringWithFormat:@"%td/%td", pageIndex - whiteboardPageCount + 1, self.room.documentVM.totalPageCount - whiteboardPageCount] forState:UIControlStateNormal];
        }
    }];
    
#pragma mark - 跑马灯
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self, customLampContent),
                         BJLMakeProperty(self.room.roomVM, lamp)]
               options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
              observer:^(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateLamp];
    }];
    // 第一次手动触发
    [self updateLamp];
    
#pragma mark - 公告
    
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, notice)
           filter:^BOOL(BJLNotice * _Nullable now, BJLNotice * _Nullable old, BJLPropertyChange * _Nullable change) {
        if (now.noticeText.length || now.linkURL) {
            return YES;
        }
        
        BOOL hasChange = NO;
        for (BJLNoticeModel *notice in now.groupNoticeList) {
            if (notice.noticeText.length || notice.linkURL) {
                hasChange = YES;
                break;
            }
        }
        return hasChange;
    }
         observer:^BOOL(BJLNotice * _Nullable notice, id _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self.overlayViewController showWithContentViewController:self.noticeViewController contentView:nil];
        [self.noticeViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.right.bottom.equalTo(self.overlayViewController.view);
            make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
        }];
        return YES;
    }];
    
#pragma mark - webrtc
    
    if (self.room.featureConfig.isWebRTC) {
        // webRTC 进入直播频道失败
        [self bjl_observe:BJLMakeMethod(self.room.mediaVM, enterLiveChannelFailed)
                 observer:^BOOL{
            bjl_strongify(self);
            [self showProgressHUDWithText:@"进入直播频道失败，请重试"];
            return YES;
        }];
        
        // webRTC 直播频道断开提示
        [self bjl_observe:BJLMakeMethod(self.room.mediaVM, didLiveChannelDisconnectWithError:)
                 observer:^BOOL(NSError *error){
            bjl_strongify(self);
            [self showProgressHUDWithText:@"直播频道已断开，请重试"];
            return YES;
        }];
        
        // webRTC 推流重试提示
        [self bjl_observe:BJLMakeMethod(self.room.recordingVM, republishing)
                 observer:^BOOL{
            bjl_strongify(self);
            [self showProgressHUDWithText:@"音视频推送失败，自动重试中"];
            return YES;
        }];
        
        // webRTC 推流重试提示
        [self bjl_observe:BJLMakeMethod(self.room.recordingVM, publishFailed)
                 observer:^BOOL{
            bjl_strongify(self);
            [self showProgressHUDWithText:@"音视频推送失败，请重试"];
            return YES;
        }];
    }
    
#pragma mark - 音视频采集状态
    
    BJLPropertyFilter ifIntegerChanged = ^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        return now.integerValue != old.integerValue;
    };
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, recordingAudio)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:ifIntegerChanged
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        self.audioButton.selected = self.room.recordingVM.recordingAudio;
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, recordingVideo)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:ifIntegerChanged
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        self.videoButton.selected = self.room.recordingVM.recordingVideo;
        return YES;
    }];
    
#pragma mark - 举手
    
    [self bjl_kvo:BJLMakeProperty(self.handUpButton, hidden)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self.handUpButton bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.width.height.equalTo(self.handUpButton.hidden ? @0.0 : @(BJLScControlSize));
        }];
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.videoButton, hidden)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self.videoButton bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.width.height.equalTo(self.videoButton.hidden ? @0.0 : @(BJLScControlSize));
        }];
        return YES;
    }];
    
#pragma mark - 工具显示
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self, controlsHidden),
                         BJLMakeProperty(self, teacherExtraMediaInfoView),
                         BJLMakeProperty(self.toolViewController, expectedHidden),
                         BJLMakeProperty(self, majorWindowType),
                         BJLMakeProperty(self, fullscreenWindowType)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        // 当前是全屏状态    
        if (self.fullscreenWindowType != BJLScWindowType_none) {
            // 存在全屏课件时，根据是否有权限来显示画笔，忽略掉其他控件是否显示的状态
            if (self.fullscreenWindowType == BJLScWindowType_ppt
                && !self.teacherExtraMediaInfoView) {
                self.toolHidden = self.toolViewController.expectedHidden;
            }
            // 否则始终隐藏
            else {
                self.toolHidden = YES;
            }
        }
        // 当前不是全屏状态
        else {
            // 存在大屏课件时
            if (self.majorWindowType == BJLScWindowType_ppt
                && !self.teacherExtraMediaInfoView) {
                // 如果隐藏了其他控件
                if (self.controlsHidden) {
                    // 如果当前正在使用画笔中，根据视图的自预期效果控制
                    if (self.room.drawingVM.drawingGranted
                        && self.room.drawingVM.drawingEnabled) {
                        self.toolHidden = self.toolViewController.expectedHidden;
                    }
                    // 不在使用画笔中就和其他控件效果保持一致
                    else {
                        self.toolHidden = self.controlsHidden;
                    }
                }
                // 如果没隐藏其他控件，视图的自预期效果控制
                else {
                    self.toolHidden = self.toolViewController.expectedHidden;
                }
            }
            // 否则始终隐藏
            else {
                self.toolHidden = YES;
            }
        }
    }];
    
    [self bjl_kvo:BJLMakeProperty(self, toolHidden)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self.toolViewController updateToolViewHidden:self.toolHidden];
        return YES;
    }];
    
#pragma mark - button
    
    [self updateButtonStates];
}

#pragma mark - makeObservingWhenEnteredInRoom

- (void)makeObservingWhenEnteredInRoom {
    if (self.room.loginUser.isTeacher) {
        [self makeObservingForTeacherOrAssistant];
    }
    else if (self.room.loginUser.isAssistant) {
        [self makeObservingForSpeaking];
        [self makeObservingForAssistant];
        [self makeObservingForTeacherOrAssistant];
    }
    else {
        [self makeObservingForSpeaking];
        [self makeObservingForRollcall];
        [self makeObservingForAnswerSheet];
        [self makeObservingForEvaluation];
        [self makeObservingForQuiz];
        [self makeObservingForCustomWebView];
    }
    
    [self makeObservingForVideoPosition];
    [self makeObservingForPPTAndDrawing];
    [self makeObservingForProgressHUD];
    [self makeObservingForEnvelope];
    [self makeObservingForLikeEffect];
    [self makeObservingForCountDownTimer];
    [self makeObservingForQuestion];
    
    [self updateButtonStates];
}

- (void)makeObservingForTeacherOrAssistant {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, speakingRequestUsers)
           filter:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        return (self.room.loginUser.isTeacherOrAssistant && self.room.loginUser.groupID == 0);
    } observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        NSInteger count = [self.room.speakingRequestVM.speakingRequestUsers count];
        self.handUpButton.hidden = (count <= 0);
        self.speakRequestRedDot.hidden = (count <= 0);
        self.speakRequestRedDot.text = count > 99 ? @"···" : [NSString stringWithFormat:@"%td", count];
        if (self.fullscreenWindowType != BJLScWindowType_none) {
            self.fullHandUpButton.hidden = (count <= 0);
            self.fullSpeakRequestRedDot.hidden = (count <= 0);
            self.fullSpeakRequestRedDot.text = count > 99 ? @"···" : [NSString stringWithFormat:@"%td", count];
        }
        return YES;
    }];
    
}

#pragma mark - assistant

- (void)makeObservingForAssistant {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveAssistantaAuthorityChanged) observer:^BOOL{
        bjl_strongify(self);
        [self showProgressHUDWithText:@"权限已变更"];
        
        // 如果助教被收回画笔权限，此时也要更新画笔权限，防止此时助教正在使用画笔而没有被收回权限
        if (![self.room.roomVM getAssistantaAuthorityWithPainter]) {
            [self.room.drawingVM updateDrawingEnabled:NO];
        }
        
        // 助教上下课权限更改
        if (self.room.loginUser.isTeacher || (self.room.loginUser.isAssistant && self.room.roomVM.getAssistantaAuthorityWithClassStartEnd)) {
            self.liveStartButton.hidden = self.room.roomVM.liveStarted;
        }
        else {
            self.liveStartButton.hidden = YES;
        }
        return YES;
    }];
}

#pragma mark - student

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
    CGFloat containerViewWidth = self.view.bounds.size.width - BJLScSegmentWidth;
    CGFloat containerViewHeight = self.view.bounds.size.height - BJLScTopBarHeight - self.videosView.bounds.size.height;
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

- (void)makeObservingForVideoPosition {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didVideoExchangePositonWithPPT:)
             observer:(BJLMethodObserver)^BOOL(BOOL videoInMainPosition) {
        bjl_strongify(self);
        if ((videoInMainPosition && self.majorWindowType == BJLScWindowType_teacherVideo && self.minorWindowType == BJLScWindowType_ppt && self.secondMinorWindowType == BJLScWindowType_userVideo)
            || (!videoInMainPosition && self.majorWindowType == BJLScWindowType_ppt && self.minorWindowType == BJLScWindowType_teacherVideo && self.secondMinorWindowType == BJLScWindowType_userVideo)) {
            return YES;
        }
        // 同步切换位置时，全屏复原
        if (self.fullscreenWindowType != BJLScWindowType_none) {
            [self restoreCurrentFullscreenWindow];
        }
        // 视频列表复原
        if (self.videosViewController) {
            [self.videosViewController resetVideo];
        }
        // 1v1 复原
        if (self.secondMinorMediaInfoView) {
            [self replaceSecondMinorContentViewWithSecondMinorMediaInfoView];
        }
        // 替换
        if (videoInMainPosition) {
            [self replaceMajorContentViewWithTeacherMediaInfoView];
            [self replaceMinorContentViewWithPPTView];
        }
        else {
            [self replaceMinorContentViewWithTeacherMediaInfoView];
            [self replaceMajorContentViewWithPPTView];
        }
        return YES;
    }];
}

- (void)makeObservingForSpeaking {
    __block UIAlertController *alert = nil;
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, didReceiveSpeakingInvite:)
             observer:(BJLMethodObserver)^BOOL(BOOL invite) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        // 已经弹出 && 取消邀请
        if (alert && !invite) {
            [alert dismissViewControllerAnimated:NO completion:nil];
            alert = nil;
        }
        // 已经弹出 && 已经邀请， 避免收到重复的邀请信令
        if (alert && invite) {
            return YES;
        }
        if (invite) {
            alert = [UIAlertController
                     bjl_lightAlertControllerWithTitle:@"老师邀请你上麦发言"
                     message:nil
                     preferredStyle:UIAlertControllerStyleAlert];
            [alert bjl_addActionWithTitle:@"同意"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                alert = nil;
                [self.room.speakingRequestVM responseSpeakingInvite:YES];
                BJLError *error = [self.room.recordingVM setRecordingAudio:YES recordingVideo:YES];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
                else {
                    [self showProgressHUDWithText:(self.room.recordingVM.recordingAudio
                                                   ? @"麦克风已打开"
                                                   : @"麦克风已关闭")];
                }
            }];
            [alert bjl_addActionWithTitle:@"拒绝"
                                    style:UIAlertActionStyleDestructive
                                  handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                alert = nil;
                [self.room.speakingRequestVM responseSpeakingInvite:NO];
                [self.room.recordingVM setRecordingAudio:NO recordingVideo:NO];
                
            }];
            if (self.presentedViewController) {
                [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
            }
            [self presentViewController:alert animated:YES completion:nil];
        }
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
            self.handProgressView.progress = 0.0;
            if (self.fullscreenWindowType != BJLScWindowType_none) {
                self.fullHandProgressView.progress = 0.0;
            }
        }
        else {
            CGFloat progress = timeRemaining.doubleValue / self.room.speakingRequestVM.speakingRequestTimeoutInterval; // 1.0 ~ 0.0
            self.handProgressView.progress = progress;
            if (self.fullscreenWindowType != BJLScWindowType_none) {
                self.fullHandProgressView.progress = progress;
            }
        }
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, speakingEnabled)
           filter:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        return self.room.loginUser.isStudent;
    } observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateButtonStates];
        if (self.room.speakingRequestVM.speakingEnabled
            && self.fullscreenWindowType != BJLScWindowType_none) {
            // 上麦时全屏复原
            [self restoreCurrentFullscreenWindow];
        }
        // 1 V N
        if (self.room.roomInfo.roomType == BJLRoomType_1vNClass) {
            if (self.room.speakingRequestVM.speakingEnabled) {
                if (!self.room.recordingVM.recordingAudio
                    && !self.room.recordingVM.recordingVideo) {
                    [self autoStartRecordingAudioAndVideoForce:NO];
                }
            }
            else {
                [self.room.recordingVM setRecordingAudio:NO recordingVideo:NO];
                if (self.room.slideshowViewController.drawingEnabled) {
                    [self.room.drawingVM updateDrawingEnabled:NO];
                }
            }
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, speakingRequestDidReplyEnabled:isUserCancelled:user:)
             observer:(BJLMethodObserver)^BOOL(BOOL speakingEnabled, BOOL isUserCancelled, BJLUser *user) {
        bjl_strongify(self);
        if ([user.ID isEqualToString:self.room.loginUser.ID]
            && !isUserCancelled) {
            [self showProgressHUDWithText:(speakingEnabled
                                           ? @"老师同意发言，已进入发言状态"
                                           : @"稍等一下，一会请你回答")];
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.recordingVM, recordingDidRemoteChangedRecordingAudio:recordingVideo:recordingAudioChanged:recordingVideoChanged:)
             observer:(BJLMethodObserver)^BOOL(BOOL recordingAudio, BOOL recordingVideo, BOOL recordingAudioChanged, BOOL recordingVideoChanged) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        NSString *actionMessage = nil;
        if (recordingAudioChanged && recordingVideoChanged) {
            if (recordingAudio == recordingVideo) {
                actionMessage = recordingAudio ? @"老师开启了你的麦克风和摄像头" : @"老师结束了你的发言"/* @"老师关闭了你的麦克风和摄像头" */;
            }
            else {
                actionMessage = recordingAudio ? @"老师开启了你的麦克风" : @"老师开启了你的摄像头"; // 同时关闭了你的摄像头/麦克风
            }
        }
        else if (recordingAudioChanged) {
            actionMessage = recordingAudio ? @"老师开启了你的麦克风" : @"老师关闭了你的麦克风";
        }
        else if (recordingVideoChanged) {
            actionMessage = recordingVideo ? @"老师开启了你的摄像头" : @"老师关闭了你的摄像头";
        }
        BOOL wasSpeakingEnabled = (recordingAudioChanged ? !recordingAudio : recordingAudio
                                   || recordingVideoChanged ? !recordingVideo : recordingVideo);
        BOOL isSpeakingEnabled = (recordingAudio || recordingVideo);
        if (!wasSpeakingEnabled && isSpeakingEnabled) {
            UIAlertController *alert = [UIAlertController
                                        bjl_lightAlertControllerWithTitle:[NSString stringWithFormat:@"%@，现在可以发言了", actionMessage]
                                        message:nil
                                        preferredStyle:UIAlertControllerStyleAlert];
            [alert bjl_addActionWithTitle:@"知道了"
                                    style:UIAlertActionStyleCancel
                                  handler:nil];
            if (self.presentedViewController) {
                [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
            }
            [self presentViewController:alert
                               animated:YES
                             completion:nil];
        }
        else if (actionMessage) {
            [self showProgressHUDWithText:actionMessage];
            if (wasSpeakingEnabled && !isSpeakingEnabled) {
                [self.room.drawingVM updateDrawingEnabled:NO];
            }
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveHitCommandLottery:) observer:^BOOL{
        bjl_strongify(self);
        // 发送口令信息成功后, 给一个提示
        [self showProgressHUDWithText:@"您已参与抽奖，等待开奖吧～"];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveBeginCommandLottery:) observer:^BOOL{
        bjl_strongify(self);
        [self showProgressHUDWithText:@"老师发起了口令抽奖～"];
       return YES;
    }];
}

- (void)makeObservingForRollcall {
    bjl_weakify(self);
    
    NSString * const rollcallTitleFormat = @"老师要求你在%.0f秒内响应点名";
    __block UIAlertController *rollcallAlert = nil;
    __block id<BJLObservation> observation = nil;
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveRollcallWithTimeout:)
             observer:^BOOL(NSTimeInterval timeout) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        if (rollcallAlert) {
            [rollcallAlert dismissViewControllerAnimated:NO completion:nil];
        }
        
        rollcallAlert = [UIAlertController bjl_lightAlertControllerWithTitle:@"点名"
                                                                     message:[NSString stringWithFormat:rollcallTitleFormat, timeout]
                                                              preferredStyle:UIAlertControllerStyleAlert];
        [rollcallAlert bjl_addActionWithTitle:@"答到"
                                        style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction * _Nonnull action) {
            bjl_strongify(self);
            rollcallAlert = nil;
            [observation stopObserving];
            observation = nil;
            [self.room.roomVM answerToRollcall];
        }];
        if (self.presentedViewController) {
            [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
        }
        [self presentViewController:rollcallAlert animated:YES completion:nil];
        
        observation = [self bjl_kvo:BJLMakeProperty(self.room.roomVM, rollcallTimeRemaining)
                           observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            rollcallAlert.message = [NSString stringWithFormat:rollcallTitleFormat, self.room.roomVM.rollcallTimeRemaining];
            return YES;
        }];
        return YES;
    }];
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, rollcallDidFinish)
             observer:^BOOL {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        [observation stopObserving];
        observation = nil;
        [rollcallAlert dismissViewControllerAnimated:YES completion:nil];
        rollcallAlert = nil;
        return YES;
    }];
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveAttentionWarning:)
             observer:^BOOL(NSString *content) {
        bjl_strongify(self);
        [self showProgressHUDWithText:content];
        return YES;
    }];
}

#pragma mark - common

- (void)makeObservingForProgressHUD {
    bjl_weakify(self);
    
    /* 麦克风和摄像头权限 */
    __block UIAlertController *alertController = nil;
    [self.room.recordingVM setCheckMicrophoneAndCameraAccessCallback:^(BOOL microphone, BOOL camera, BOOL granted, UIAlertController * _Nullable alert) {
        bjl_strongify(self);
        if (granted) {
            return;
        }
        // 未授权时重置当前的 UI 状态
        if (microphone) {
            self.audioButton.selected = NO;
            self.settingsViewController.micSwitch.on = NO;
        }
        if (camera) {
            self.videoButton.selected = NO;
            self.settingsViewController.cameraSwitch.on = NO;
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
    
    // 切换主讲
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, currentPresenter)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(BJLUser * _Nullable now, BJLUser * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        return (old // 默认主讲不提示
                && now // 老师掉线不提示
                && old != now
                && ![now isSameUser:old]);
    }
         observer:^BOOL(BJLUser * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        NSString *name = self.room.loginUserIsPresenter ? @"你" : now.displayName;
        [self showProgressHUDWithText:[NSString stringWithFormat:@"%@成为了主讲", name]];
        return YES;
    }];
    
    if (self.room.loginUser.isTeacherOrAssistant
        && self.room.loginUser.noGroup) {
        [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, speakingRequestDidReplyToUserID:allowed:success:)
                   filter:(BJLMethodObserver)^BOOL(NSString *userID, BOOL allowed, BOOL success) {
            // bjl_strongify(self);
            return allowed && !success;
        }
                 observer:(BJLMethodObserver)^BOOL(NSString *userID, BOOL allowed, BOOL success) {
            bjl_strongify(self);
            [self showProgressHUDWithText:@"发言人数已满，请先关闭其他人音视频"];
            return YES;
        }];
    }
    
    if (!self.room.loginUser.isTeacher) {
        [self bjl_kvo:BJLMakeProperty(self.room, switchingRoom)
               filter:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
            // bjl_strongify(self);
            return now.boolValue;
        }
             observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            if (self.room.switchingRoom) {
                [self showProgressHUDWithText:@"切换教室中..."];
                [self.overlayViewController hide];
            }
            return YES;
        }];
        
        [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, activeUsersSynced)
               filter:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
            // bjl_strongify(self);
            return now.boolValue;
        }
             observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            if (!self.room.onlineUsersVM.onlineTeacher) {
                [self showProgressHUDWithText:@"老师未在教室"];
            }
            return YES;
        }];
        
        [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, onlineTeacher)
              options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
               filter:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            // activeUsersSynced 为 NO 时的变化无意义
            return self.room.onlineUsersVM.activeUsersSynced && !!old != !!now;
        }
             observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            [self showProgressHUDWithText:now ? @"老师进入教室" : @"老师离开教室"];
            return YES;
        }];
        
        [self bjl_observe:BJLMakeMethod(self.room.playingVM, playingUserDidUpdate:old:)
                 observer:(BJLMethodFilter)^BOOL(BJLMediaUser * _Nullable now, BJLMediaUser * _Nullable old) {
            bjl_strongify(self);
            if (now.isTeacher) {
                BOOL audioChanged = (now.audioOn != old.audioOn
                                     && now.mediaSource == BJLMediaSource_mainCamera);
                BOOL videoChanged = (now.videoOn != old.videoOn);
                
                NSString *videoTitle = BJLVideoTitleWithMediaSource(now.mediaSource);
                if (audioChanged && videoChanged) {
                    if (now.audioOn && now.videoOn) {
                        [self showProgressHUDWithText:[NSString stringWithFormat:@"老师开启了麦克风和%@", videoTitle]];
                    }
                    else if (now.audioOn) {
                        [self showProgressHUDWithText:@"老师开启了麦克风"];
                    }
                    else if (now.videoOn) {
                        [self showProgressHUDWithText:[NSString stringWithFormat:@"老师开启了%@", videoTitle]];
                    }
                    else {
                        [self showProgressHUDWithText:[NSString stringWithFormat:@"老师关闭了麦克风和%@", videoTitle]];
                    }
                }
                else if (audioChanged) {
                    if (now.audioOn) {
                        [self showProgressHUDWithText:@"老师开启了麦克风"];
                    }
                    else {
                        [self showProgressHUDWithText:@"老师关闭了麦克风"];
                    }
                }
                else { // videoChanged
                    if (now.videoOn
                        || (now.mediaSource == BJLMediaSource_mediaFile
                            && old.mediaSource != BJLMediaSource_mediaFile)) {
                        [self showProgressHUDWithText:[NSString stringWithFormat:@"老师开启了%@", videoTitle]];
                    }
                    else {
                        [self showProgressHUDWithText:[NSString stringWithFormat:@"老师关闭了%@", videoTitle]];
                    }
                }
            }
            return YES;
        }];
        
        [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, forbidAllRecordingAudio)
               filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
            // bjl_strongify(self);
            return now.boolValue != old.boolValue;
        }
             observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            [self showProgressHUDWithText:now.boolValue ? @"老师禁止打开麦克风" : @"老师允许打开麦克风"];
            return YES;
        }];
        
        [self bjl_kvo:BJLMakeProperty(self.room.chatVM, forbidMe)
               filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
            // bjl_strongify(self);
            return now.boolValue != old.boolValue;
        }
             observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            [self showProgressHUDWithText:(now.boolValue
                                           ? @"你已被禁言"
                                           : @"你已被解除禁言")];
            return YES;
        }];
        
        [self bjl_kvo:BJLMakeProperty(self.room.chatVM, forbidAll)
               filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
            // bjl_strongify(self);
            return now.boolValue != old.boolValue;
        }
             observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            [self showProgressHUDWithText:(now.boolValue
                                           ? @"老师开启了全体禁言"
                                           : @"老师关闭了全体禁言")];
            return YES;
        }];
    }
    
    // 老师强制上麦失败的提示
    if (self.room.loginUser.isTeacher) {
        [self bjl_observe:BJLMakeMethod(self.room.recordingVM, remoteChangeRecordingDidDenyForUser:)
                 observer:^BOOL(BJLUser *user) {
            bjl_strongify(self);
            [self showProgressHUDWithText:[NSString stringWithFormat:@"服务器拒绝强制 %@ 发言，音视频并发已达上限", user.displayName]];
            return YES;
        }];
    }
    
    if (!self.room.loginUser.isTeacherOrAssistant
        && !self.room.featureConfig.disableGrantDrawing) {
        [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, drawingGranted)
         // options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
               filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
            // bjl_strongify(self);
            return now.boolValue != old.boolValue;
        }
             observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            [self showProgressHUDWithText:(now.boolValue
                                           ? @"老师开启了你的画笔权限"
                                           : @"老师取消了你的画笔权限")];
            return YES;
        }];
    }
    
}

#pragma mark - 红包雨

- (void)makeObservingForEnvelope {
    
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didStartEnvelopRainWithID:duration:)
             observer:^BOOL(NSInteger envelopID, NSInteger duration){
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        if (self.rainEffectViewController) {
            // 只存在一个
            [self.rainEffectViewController bjl_removeFromParentViewControllerAndSuperiew];
            self.rainEffectViewController = nil;
        }
        
        [self.view endEditing:YES];
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        CGFloat width = screenWidth > screenHeight ? screenWidth : screenHeight;
        CGSize size = CGSizeMake(width, width);
        NSInteger rainCount = 10;
        BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
        CGSize rainSize = iPad ? CGSizeMake(88.0, 176.0) : CGSizeMake(64.0, 128.0);
        self.rainEffectViewController = [[BJLRainEffectViewController alloc] initWithRoom:self.room envelopeID:envelopID duration:duration];
        [self.rainEffectViewController setupRainEffectSize:size rainImageName:nil rainCount:rainCount rainSize:rainSize];
        [self.rainEffectViewController setOpenEnvelopeImageName:nil emptyImageName:nil size:rainSize emptySize:rainSize];
        [self bjl_addChildViewController:self.rainEffectViewController superview:self.teachAidLayer];
        [self.rainEffectViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.teachAidLayer);
        }];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didFinishEnvelopRainWithID:)
             observer:^BOOL(NSInteger envelopID) {
        bjl_strongify(self);
        if (self.rainEffectViewController.envelopeID == envelopID) {
            [self.rainEffectViewController removeRainScene];
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveRankingList:)
             observer:^BOOL(NSArray<BJLEnvelopeRank *> *rankList) {
        bjl_strongify(self);
        [self.rainEffectViewController didReceiveRankList:rankList];
        return YES;
    }];
}

#pragma mark - 答题器

- (void)makeObservingForAnswerSheet {
    // 老师/助教身份 不监听答题器事件
    if (self.room.loginUser.isTeacherOrAssistant) {
        return;
    }
    
    bjl_weakify(self);
    // 答题开始
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveQuestionAnswerSheet:)
             observer:^BOOL(BJLAnswerSheet *answerSheet) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        [self clearAnswerSheet];
        self.lastAnswerSheet = [answerSheet copy];
        self.answerSheetViewController = [[BJLScAnswerSheetViewController alloc] initWithAnswerSheet:answerSheet];
        
        // 答题结束回调：return YES 表示提交成功，答题器将自动关闭
        [self.answerSheetViewController setSubmitCallback:^BOOL(BJLAnswerSheet * _Nullable result) {
            bjl_strongify(self);
            if (!result) {
                return NO;
            }
            
            BJLError *error = [self.room.roomVM submitQuestionAnswer:result];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                return NO;
            }
            self.lastAnswerSheet = result;
            return YES;
        }];
        
        // 答题器关闭回调
        [self.answerSheetViewController setCloseCallback:^{
            bjl_strongify(self);
            [self clearAnswerSheet];
        }];
        
        [self showProgressHUDWithText:@"答题开始"];
        [self showAnswerSheet];
        return YES;
    }];
    
    // 答题结束
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveEndQuestionAnswerWithEndTime:)
             observer:(BJLMethodObserver)^BOOL(NSTimeInterval endTimeInterval) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        [self showProgressHUDWithText:@"答题已结束"];
        [self clearAnswerSheet];
        
        if (self.lastAnswerSheet && self.lastAnswerSheet.shouldShowCorrectAnswer) {
            self.answerSheetResultViewController = [[BJLScAnswerSheetResultViewController alloc] initWithAnswerSheet:self.lastAnswerSheet];
            [self.answerSheetResultViewController setWindowedParentViewController:self superview:self.teachAidLayer];
            // 答题器结果关闭回调
            [self.answerSheetResultViewController setCloseCallback:^{
                bjl_strongify(self);
                [self clearAnswerSheetResult];
            }];
            [self showAnswerSheetResult];
        }
        return YES;
    }];
    
    // 兼容撤回信令
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveRevokeQuestionAnswerWithEndTime:)
             observer:(BJLMethodObserver)^BOOL(NSTimeInterval endTimeInterval) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        [self showProgressHUDWithText:@"答题已结束"];
        [self clearAnswerSheet];
        [self clearAnswerSheetResult];
        return YES;
    }];
    
    // 监听到老师不在教室，关闭答题
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, onlineTeacher)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        if (!now) {
            [self clearAnswerSheet];
        }
        return YES;
    }];
}

- (void)showAnswerSheet {
    if (!self.answerSheetViewController) {
        return;
    }
    
    [self.answerSheetViewController setWindowedParentViewController:self superview:self.teachAidLayer];
    [self.answerSheetViewController openWithoutRequest];
}

- (void)clearAnswerSheet {
    [self clearAnswerSheetResult];
    if (!self.answerSheetViewController) {
        return;
    }
    
    [self.answerSheetViewController closeWithoutRequest];
    self.answerSheetViewController = nil;
}

- (void)showAnswerSheetResult {
    if (!self.answerSheetResultViewController) {
        return;
    }
    [self.answerSheetResultViewController setWindowedParentViewController:self superview:self.teachAidLayer];
    [self.answerSheetResultViewController openWithoutRequest];
}

- (void)clearAnswerSheetResult {
    if (!self.answerSheetResultViewController) {
        return;
    }
    
    [self.answerSheetResultViewController closeWithoutRequest];
    self.answerSheetResultViewController = nil;
    self.lastAnswerSheet = nil;
}

#pragma mark - 小测

- (void)makeObservingForQuiz {
    bjl_weakify(self);
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveQuizMessage:)
             observer:^BOOL(NSDictionary<NSString *, id> *message) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        
        BJLScQuizWebViewController *quizWebViewController = [BJLScQuizWebViewController
                                                             instanceWithQuizMessage:message
                                                             roomVM:self.room.roomVM];
        if (quizWebViewController) {
            quizWebViewController.closeWebViewCallback = ^{
                bjl_strongify(self);
                [self.overlayViewController hide];
                self.quizWebViewController = nil;
            };
            quizWebViewController.sendQuizMessageCallback = ^BJLError * _Nullable(NSDictionary<NSString *, id> * _Nonnull message) {
                bjl_strongify(self);
                return [self.room.roomVM sendQuizMessage:message];
            };
            
            if (self.quizWebViewController) {
                [self.overlayViewController hide];
                self.quizWebViewController = nil;
            }
            
            self.quizWebViewController = quizWebViewController;
            [self.overlayViewController showWithContentViewController:quizWebViewController contentView:nil];
            [quizWebViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.overlayViewController.view);
            }];
        }
        else if (self.quizWebViewController) {
            [self.quizWebViewController didReceiveQuizMessage:message];
        }
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room, state)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        if (self.room.state == BJLRoomState_connected) {
            if (self.quizWebViewController) {
                [self.overlayViewController hide];
            }
            [self.room.roomVM sendQuizMessage:[BJLScQuizWebViewController quizReqMessageWithUserNumber:self.room.loginUser.number]];
        }
        return YES;
    }];
}

- (void)makeObservingForCustomWebView {
    bjl_weakify(self);
    
    NSString * const customWebpage = @"custom_webpage";
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveCustomizedBroadcast:value:isCache:)
               filter:(BJLMethodFilter)^BOOL(NSString *key, id _Nullable _value, BOOL isCache) {
        // bjl_strongify(self);
        return [key isEqualToString:customWebpage];
    }
             observer:(BJLMethodObserver)^BOOL(NSString *key, id _Nullable _value, BOOL isCache) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        
        NSDictionary *value = bjl_as(_value, NSDictionary);
        NSString *action = [value bjl_stringForKey:@"action"];
        
        if ([action isEqualToString:@"student_open_webpage"]) {
            NSString *urlString = [value bjl_stringForKey:@"url"];
            NSURLRequest *request = [BJLNetworking.bjl_manager.requestSerializer
                                     requestWithMethod:@"GET"
                                     URLString:urlString
                                     parameters:@{@"class_id":      self.room.roomInfo.ID ?: @"",
                                                  @"user_number":   self.room.loginUser.number ?: @"",
                                                  @"user_name":     self.room.loginUser.name ?: @""}
                                     error:nil];
            BJLCustomWebViewController *customWebViewController = [[BJLCustomWebViewController alloc] initWithRequest:request];;
            if (customWebViewController) {
                customWebViewController.closeWebViewCallback = ^{
                    bjl_strongify(self);
                    [self.overlayViewController hide];
                    self.customWebViewController = nil;
                };
                
                if (self.customWebViewController) {
                    [self.overlayViewController hide];
                    self.customWebViewController = nil;
                }
                
                self.customWebViewController = customWebViewController;
                [self.overlayViewController showWithContentViewController:customWebViewController contentView:nil];
                [customWebViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                    make.edges.equalTo(self.overlayViewController.view);
                }];
            }
        }
        else if ([action isEqualToString:@"student_close_webpage"]) {
            [self.overlayViewController hide];
            self.customWebViewController = nil;
        }
        
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room, state)
           filter:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        return (BJLRoomState)[value integerValue] == BJLRoomState_connected;
    }
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self.room.roomVM requestCustomizedBroadcastCache:customWebpage];
        return YES;
    }];
}

#pragma mark - 计时器

- (void)makeObservingForCountDownTimer {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveStopTimer)
             observer:^BOOL{
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        if (!self.countDownViewController) {
            return YES;
        }
        
        [self.countDownViewController bjl_removeFromParentViewControllerAndSuperiew];
        [self.countDownViewController closeWithoutRequest];
        self.countDownViewController = nil;
        
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveTimerWithTotalTime:countDownTime:isDecrease:)
             observer:(BJLMethodObserver)^BOOL (NSInteger totalTime, NSInteger countDownTime, BOOL isDecrease){
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        
        BOOL noEditViewController = self.room.loginUser.isTeacher && !self.countDownEditViewController;
        BOOL noCountDownViewController = !self.countDownViewController;
        if (noCountDownViewController || noEditViewController) {
            [self makeCountDownViewController];
        }
        
        if (noEditViewController) {
            [self.countDownEditViewController updateTimerWithTotalTime:totalTime currentCountDownTime:countDownTime isDecrease:isDecrease shouldPause:NO];
        }
        
        if (noCountDownViewController || self.countDownViewController.state == BJLSWindowState_closed) {
            [self.countDownViewController setWindowedParentViewController:self
                                                                superview:self.timerLayer];
            [self.countDownViewController updateTimerWithTotalTime:totalTime currentCountDownTime:countDownTime isDecrease:isDecrease shouldPause:NO];
            [self.countDownViewController openWithoutRequest];
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceivePauseTimerWithTotalTime:leftCountDownTime:isDecrease:)
             observer:(BJLMethodObserver)^BOOL(NSInteger totalTime, NSInteger countDownTime, BOOL isDecrease) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        
        BOOL noEditViewController = self.room.loginUser.isTeacher && !self.countDownEditViewController;
        BOOL noCountDownViewController = !self.countDownViewController;
        if (noCountDownViewController || noEditViewController) {
            [self makeCountDownViewController];
        }
        
        if (noEditViewController) {
            [self.countDownEditViewController updateTimerWithTotalTime:totalTime currentCountDownTime:countDownTime isDecrease:isDecrease shouldPause:YES];
        }
        
        if (self.countDownViewController.state == BJLSWindowState_closed) {
            [self.countDownViewController setWindowedParentViewController:self
                                                                superview:self.timerLayer];
            [self.countDownViewController updateTimerWithTotalTime:totalTime currentCountDownTime:countDownTime isDecrease:isDecrease shouldPause:YES];
            [self.countDownViewController openWithoutRequest];
        }
        return YES;
    }];
}

#pragma mark - 问答

- (void)makeObservingForQuestion {
    bjl_weakify(self);
    [self bjl_observeMerge:@[BJLMakeMethod(self.room.roomVM, didPublishQuestion:),
                             BJLMakeMethod(self.room.roomVM, didReplyQuestion:),
                             BJLMakeMethod(self.room.roomVM, didSendQuestion:),
                             BJLMakeMethod(self.room.roomVM, didUnpublishQuestion:)]
                  observer:^(BJLQuestion *question){
        bjl_strongify(self);
        NSString *liveTabs = self.room.loginUser.isStudent ? self.room.featureConfig.liveTabsOfStudent : self.room.featureConfig.liveTabs;
        BOOL enableQuestion = [liveTabs containsString:@"answer"] && self.room.featureConfig.enableQuestion;
        if (enableQuestion) {
            // 收到新发布的问答时，没有加载过问答界面，问答界面不在主窗口，问答界面被隐藏的时候，显示红点
            BOOL hidden = (self.questionViewController.isViewLoaded && self.questionViewController.view.window && !self.questionViewController.view.hidden);
            
            // 当前登录用户是学生, 问答被回复且未发布, state是已回复|未发布, 且该question不是当前学生提出来的, hidden = YES
            if (!self.room.loginUser.isTeacherOrAssistant
                && (question.state == 6)
                && ![question.fromUser.number isEqualToString:self.room.loginUser.number]) {
                hidden = YES;
            }
            [self updateQuestionRedDotHidden:hidden];
            
            // 当前是学生, 显示redDot, 且该question是已发布的状态
            if (!hidden
                && !self.room.loginUser.isTeacherOrAssistant
                && ((question.state & BJLQuestionPublished) == BJLQuestionPublished)) {
                [self.questionViewController showRedDotForStudentPublishSegment];
            }
        }
    }];
}

#pragma mark - 课后评价

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
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        if (!self.room.featureConfig.enableEvaluation) {
            return YES;
        }
        if (now.boolValue) {
            return YES;
        }
        BJLScEvaluationViewController *vc = [[BJLScEvaluationViewController alloc] initWithRoom:self.room];
        [vc setCloseEvaluationCallback:^{
            bjl_strongify(self);
            [self.overlayViewController hide];
        }];
        
        [self.overlayViewController showWithContentViewController:vc contentView:nil];
        [vc.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.center.equalTo(self.overlayViewController.view);
            make.width.equalTo(@540.0).priorityHigh();
            make.top.equalTo(self.overlayViewController.view).offset(BJLScViewSpaceM);
            make.bottom.equalTo(self.overlayViewController.view).offset(-BJLScViewSpaceM);
        }];
        return YES;
    }];
}

#pragma mark - 点赞

- (void)makeObservingForLikeEffect {
    bjl_weakify(self);
    // 收到点赞
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveLikeForUserNumber:records:)
             observer:^BOOL(NSString *userNumber, NSDictionary<NSString *, NSNumber *> *records) {
        bjl_strongify(self);
        NSString *name = @"";
        for (BJLUser *user in self.room.onlineUsersVM.onlineUsers) {
            if ([user.number isEqualToString:userNumber]) {
                name = user.displayName;
                break;
            }
        }
        if (name.length) {
            BJLLikeEffectViewController *vc = [[BJLLikeEffectViewController alloc] initWithName:name];
            [self bjl_addChildViewController:vc];
        }
        return YES;
    }];
}

#pragma mark - drawing

- (void)makeObservingForPPTAndDrawing {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.slideshowViewController, drawingEnabled)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        return now.integerValue != old.integerValue;
    }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self setControlsHidden:now.boolValue animated:NO];
        return YES;
    }];
}

@end
