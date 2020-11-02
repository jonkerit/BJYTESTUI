//
//  BJLIcBlackboardLayoutViewController+video.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/17.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+video.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcBlackboardLayoutViewController (video)

- (void)makeCallbacksForVideo {
    bjl_weakify(self);
    
    [self.videoListViewController setUserMediaInfoViewsDidUpdateCallback:^(NSArray<BJLIcUserMediaInfoView *> * _Nullable userMediaInfoViews) {
        bjl_strongify(self);
        if (self.userMediaInfoViewsDidUpdateCallback) {
            self.userMediaInfoViewsDidUpdateCallback(userMediaInfoViews);
        }
    }];
    
    [self.videoListViewController setSendBackVideoViewCallback:^(BJLMediaUser * _Nonnull user) {
        bjl_strongify(self);
        [self closeDisplayingVideoWindowWithMediaID:user.mediaID requestUpdate:YES];
    }];
    
    [self.videoListViewController setSendBackAllVideoViewCallback:^{
        bjl_strongify(self);
        [self closeDisplayingVideoWindowsWithRequestUpdate:YES ignoreAutoDiaplayMaxWindow:YES];
    }];
    
    [self.videoListViewController setReceiveLikeCallback:^(BJLUser * _Nonnull user, UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.receiveLikeCallback) {
            self.receiveLikeCallback(user, button);
        }        
    }];
    [self.videoListViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(message);
        }
    }];
    [self.videoListViewController setBlockUserCallback:^BOOL(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        if (self.blockUserCallback) {
            return self.blockUserCallback(user);
        }
        return NO;
    }];
}

- (void)makeObserversForVideo {
    bjl_weakify(self);
    
    // 刷新额外的媒体流的窗口显示
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, playingUsersDidOverwrite:extraPlayingUsers:)
             observer:^BOOL{
        bjl_strongify(self);
        [self autoDisplayVideoWindowsIfNeeded];
        return YES;
    }];
    
    // 更新窗口的用户数据变换
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, playingUserDidUpdate:old:)
             observer:^BOOL(BJLMediaUser *user, BJLMediaUser *oldUser) {
        bjl_strongify(self);
        if ([self needAutoCloseVideoWindowWithUser:user]) {
            [self closeDisplayingVideoWindowWithMediaID:oldUser.mediaID requestUpdate:NO];
            return YES;
        }

        BOOL needsMaximize = NO;
        if (![self needAutoDisplayVideoWindowWithUser:user maximize:&needsMaximize]) {
            return YES;
        }
       
        BJLIcVideoWindowViewController *videoWindow = [self videoWindowWithMediaUser:oldUser mediaID:nil];
        // 如果存在，替换视图，TODO:这里是不是在视频列表模块处理了？是否不需要过多处理？
        if (videoWindow) {
            [videoWindow.videoView updateContentWithUser:user combineVideoView:(BJLIcVideoPosition_blackboard == videoWindow.videoView.position)];
            return YES;
        }
        // 如果不存在，并且是非主摄像头的视频画面，打开视图窗口，然后根据是否是主讲的屏幕共享来决定是否最大化
        if (![self autoDisplayVideoWindowWithoutRequestForUser:user needsMaximize:needsMaximize]) {
            // 不能自动打开就关闭窗口
            [self closeDisplayingVideoWindowWithMediaID:user.mediaID requestUpdate:NO];
        }
        return YES;
    }];
    
    // 窗口位置变化
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, didUpdateVideoWindowWithModel:shouldReset:)
             observer:(BJLMethodObserver)^BOOL(BJLWindowUpdateModel *updateModel, BOOL shouldReset) {
        bjl_strongify(self);
        if (shouldReset) {
            [self resetVideoWindowsWithModel:updateModel];
        }
        else {
            [self updateVideoWindowWithModel:updateModel];
        }
        
        // 窗口位置更新的时候，应该不用再去查找用户中是否有需要打开的窗口
        // [self autoDisplayVideoWindowsIfNeeded];
        
        return YES;
    }];
    
    // !!!: 监听到用户下台、退出教室时，主讲负责发送关闭该用户窗口的通知
    [self bjl_observeMerge:@[BJLMakeMethod(self.room.playingVM, didRemoveActiveUser:),
                             BJLMakeMethod(self.room.onlineUsersVM, onlineUserDidExit:)]
                  observer:^(BJLUser *user) {
        bjl_strongify(self);
        [self closeDisplayingVideoWindowsForUser:user requestUpdate:[self.room.loginUser isSameUser:self.room.onlineUsersVM.currentPresenter]];
    }];
    
    // 兼容断网重连等情况连续触发进出教室的场景
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, onlineUserDidEnter:)
             observer:^BOOL(BJLUser *user){
        bjl_strongify(self);
        [self closeDisplayingVideoWindowsForUser:user requestUpdate:NO];
        return YES;
    }];
    
    // 显示播放 mp3 的图标
    [self bjl_kvo:BJLMakeProperty(self.room.playingVM, extraPlayingUsers)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        for (BJLMediaUser *user in self.room.playingVM.extraPlayingUsers) {
            if (!user.videoOn
                && user.audioOn
                && user.mediaSource == BJLMediaSource_mediaFile) {
                self.audioFileButton.hidden = NO;
                return YES;
            }
        }
        self.audioFileButton.hidden = YES;
        return YES;
    }];
}

#pragma mark - auto display

// 主讲人在推送主摄像头之外的视频流时自动展示窗口，根据需要最大化
- (void)autoDisplayVideoWindowsIfNeeded {
    // extraPlayingUsers 中寻找需要展示窗口的的视频流
    for (BJLMediaUser *extraUser in [self.room.playingVM.extraPlayingUsers copy]) {
        BJLIcVideoWindowViewController *videoWindow = [self videoWindowWithMediaUser:extraUser mediaID:nil];
        if (videoWindow) {
            [videoWindow.videoView updateContentWithUser:extraUser combineVideoView:(BJLIcVideoPosition_blackboard == videoWindow.videoView.position)];
        }
        else {
            BOOL needsMaximize = NO;
            if ([self needAutoDisplayVideoWindowWithUser:extraUser maximize:&needsMaximize]) {
                // 尝试自动最大化
                if (![self autoDisplayVideoWindowWithoutRequestForUser:extraUser needsMaximize:needsMaximize]) {
                    // 不能自动打开就关闭窗口
                    [self closeDisplayingVideoWindowWithMediaID:extraUser.mediaID requestUpdate:NO];
                }
            }
        }
    }
}

// 开启视频且非摄像头采集（屏幕共享 || 播放媒体文件），自动打开并最大化
- (BOOL)autoDisplayVideoWindowWithoutRequestForUser:(BJLMediaUser *)user needsMaximize:(BOOL)needsMaximize {
    if (!user
        || !user.videoOn
        || user.mediaSource == BJLMediaSource_mainCamera) {
        return NO;
    }
    
    // 最大化屏幕共享时，先收回对应主摄像头采集的窗口，主讲身份的人发信息收回窗口
    if (needsMaximize
        && (user.mediaSource == BJLMediaSource_screenShare
        || user.mediaSource == BJLMediaSource_extraScreenShare)) {
        [self closeDisplayingVideoWindowWithMediaID:user.ID requestUpdate:[self.room.loginUser isSameUser:self.room.onlineUsersVM.currentPresenter]];
    }
    
    // 获取到最后的 info
    BJLWindowDisplayInfo *displayInfo = nil;
    for (BJLWindowDisplayInfo *info in self.videoWindowDisplayInfos) {
        if ([info.ID isEqualToString:user.mediaID]) {
            displayInfo = info;
        }
    }
    
    // 如果不是最大化的窗口，也没有需要显示的窗口信息，不作处理
    if (!needsMaximize && !displayInfo) {
        return NO;
    }
    
    // 获取 window
    BJLIcVideoWindowViewController *window = [self videoWindowWithMediaUser:user mediaID:nil];
    if (!window) {
        // 获取视频列表的目标视图
        BJLIcUserMediaInfoView *mediaInfoView = [self.videoListViewController setUserLeaveSeatWithMediaID:user.mediaID];
        if (!mediaInfoView) {
            mediaInfoView = [[BJLIcUserMediaInfoView alloc] initWithUser:user room:self.room];
            mediaInfoView.position = BJLIcVideoPosition_blackboard;
            [mediaInfoView updateContentWithUser:user combineVideoView:YES];
        }
        if (mediaInfoView) {
            window = [self displayVideoWindowWithVideoView:mediaInfoView requestUpdate:NO];
        }
    }
    
    // 更新窗口状态
    if (window) {
        if (displayInfo) {
            if (displayInfo.isFullScreen) {
                [window fullScreenWithoutRequest];
            }
            else if (displayInfo.isMaximized) {
                [window maximizeWithoutRequest];
            }
            else if (window.state != BJLWindowState_maximized
                     && window.state != BJLWindowState_fullscreen) {
                [window updateWithRelativeRect:CGRectMake(displayInfo.x, displayInfo.y, displayInfo.width, displayInfo.height)];
            }
            else {
                [window restoreWithoutRequest];
            }
        }
        
        if (needsMaximize) {
            [window maximizeWithoutRequest];
            window.doubleTapToMaximize = NO;
            [window bringToFrontWithoutRequest];
        }
    }
    
    return YES;
}

- (BOOL)needAutoCloseVideoWindowWithUser:(nullable BJLMediaUser *)user {
    // 是否是主讲
    BOOL isPresenter = [user isSameUser:self.room.onlineUsersVM.currentPresenter];
    BOOL isAssistantPlayMedia = user.isTeacherOrAssistant && user.mediaSource == BJLMediaSource_mediaFile;
    // 用户掉线、被踢时关闭窗口，主讲人、播放媒体的助教或者非 1v1 的非主摄像头如果是关闭状态 --> 关闭窗口
    if (!user
        || ((isPresenter
             || isAssistantPlayMedia
             || self.room.roomInfo.interactiveClassTemplateType == BJLIcTemplateType_1v1)
            && !user.videoOn
            && user.mediaSource != BJLMediaSource_mainCamera)) {
        return YES;
    }
    return NO;
}

- (BOOL)needAutoDisplayVideoWindowWithUser:(nullable BJLMediaUser *)user maximize:(BOOL *)maximize {
    // 是否是主讲
    BOOL isPresenter = [user isSameUser:self.room.onlineUsersVM.currentPresenter];
    BOOL isAssistantPlayMedia = user.isTeacherOrAssistant && user.mediaSource == BJLMediaSource_mediaFile;
    // 如果不存在，或者不是非 1v1 教室的主讲人，非播放媒体的助教，或者未开启视频画面，或者是主摄像头的视频画面 --> 在视频列表处理，此处不处理
    if (!user
        || (!isPresenter && !isAssistantPlayMedia && self.room.roomInfo.interactiveClassTemplateType != BJLIcTemplateType_1v1)
        || !user.videoOn
        || user.mediaSource == BJLMediaSource_mainCamera) {
        return NO;
    }
    
    // 是否需要自动最大化
    *maximize = (isPresenter || self.room.roomInfo.interactiveClassTemplateType == BJLIcTemplateType_1v1)
                && (user.mediaSource == BJLMediaSource_screenShare || user.mediaSource == BJLMediaSource_extraScreenShare);
    return YES;
}

#pragma mark - setup

- (void)resetVideoWindowsWithModel:(BJLWindowUpdateModel *)updateModel {
    [self closeDisplayingVideoWindowsWithRequestUpdate:NO ignoreAutoDiaplayMaxWindow:YES];
    self.videoWindowDisplayInfos = [NSArray array];
    self.mutableVideoWindowDisplayInfos = [NSMutableArray array];
    
    for (BJLWindowDisplayInfo *displayInfo in updateModel.displayInfos) {
        NSString *mediaID = displayInfo.ID;
        //reset窗口的时候，不应该使用action，应该把all displayinfo都展示成窗口, 区分窗口和最大化，全屏
        NSString *action = BJLWindowsUpdateAction_open;
        if(displayInfo.isFullScreen) {
            action = BJLWindowsUpdateAction_fullScreen;
        }
        else if(displayInfo.isMaximized) {
            action = BJLWindowsUpdateAction_maximize;
        }
        [self setupVideoWindowWithMediaID:mediaID action:action displayInfo:displayInfo];
    }
}

- (void)updateVideoWindowWithModel:(BJLWindowUpdateModel *)updateModel {
    NSString *mediaID = updateModel.ID;
    if (!mediaID.length) {
        return;
    }
    
    BJLWindowDisplayInfo *newDisplayInfo = nil;
    for (BJLWindowDisplayInfo *displayInfo in updateModel.displayInfos) {
        if ([displayInfo.ID isEqualToString:mediaID]) {
            newDisplayInfo = displayInfo;
            break;
        }
    }
    
    BJLWindowDisplayInfo *oldDisplayInfo = nil;
    for (BJLWindowDisplayInfo *displayInfo in [self.videoWindowDisplayInfos copy]) {
        if ([displayInfo.ID isEqualToString:mediaID]) {
            oldDisplayInfo = displayInfo;
            break;
        }
    }
    [self.mutableVideoWindowDisplayInfos bjl_removeObject:oldDisplayInfo];
    [self setupVideoWindowWithMediaID:mediaID action:updateModel.action displayInfo:newDisplayInfo];
}

- (void)setupVideoWindowWithMediaID:(NSString *)mediaID action:(NSString *)action displayInfo:(nullable BJLWindowDisplayInfo *)displayInfo {
    // 关闭
    if ([action isEqualToString:BJLWindowsUpdateAction_close]) {
        [self closeDisplayingVideoWindowWithMediaID:mediaID requestUpdate:NO];
        self.videoWindowDisplayInfos = self.mutableVideoWindowDisplayInfos;
        return;
    }
    
    // 兼容处理player_view_update 拿到数据为:action为Stick或者reposition, 但同时all为空的情况(理论上不允许出现)
    if (!displayInfo) {
        self.videoWindowDisplayInfos = self.mutableVideoWindowDisplayInfos;
        return;
    }
    
    // 获取是否有打开的 window
    BJLIcVideoWindowViewController *window = [self videoWindowWithMediaUser:nil mediaID:mediaID];
    // 如果没有打开的窗口
    if (!window) {
        // 从座位中获取视图
        BJLIcUserMediaInfoView *videoView = [self.videoListViewController setUserLeaveSeatWithMediaID:mediaID];
        // 如果不存在，构建新的视图
        if (!videoView) {
            BJLMediaUser *user = [self.room.playingVM playingUserWithMediaID:mediaID];
            // 未打开摄像头的媒体流，认为在播放纯音频，不显示窗口，仅显示播放 mp3 的图标
            if (user && !(!user.videoOn && user.mediaSource == BJLMediaSource_mediaFile)) {
                videoView = [[BJLIcUserMediaInfoView alloc] initWithUser:user room:self.room];
                [videoView updateContentWithUser:user combineVideoView:YES];
            }
        }
        // 存在视频视图，打开
        if (videoView) {
            videoView.position = BJLIcVideoPosition_blackboard;
            window = [self displayVideoWindowWithVideoView:videoView requestUpdate:NO];
        }
        else {
            BOOL waitingForPlay = NO;
            for (BJLUser *onlineUser in [self.room.onlineUsersVM.onlineUsers copy]) {
                if ([onlineUser containsMediaWithID:mediaID]) {
                    waitingForPlay = YES;
                    break;
                }
            }
            // !!!:如果不存在视频视图，并且当前在线用户也不包含这个能匹配的媒体 ID，认为这个数据是无效的，直接返回，正常是不加入数组中的，直接返回
            if (!waitingForPlay) {
                self.videoWindowDisplayInfos = self.mutableVideoWindowDisplayInfos;
                return;
            }
        }
    }
    
    // 全屏 !!!: no else if
    if ([action isEqualToString:BJLWindowsUpdateAction_fullScreen]) {
        [window fullScreenWithoutRequest];
    }
    // 最大化
    else if ([action isEqualToString:BJLWindowsUpdateAction_maximize]) {
        [window maximizeWithoutRequest];
    }
    // 还原
    else if ([action isEqualToString:BJLWindowsUpdateAction_restore]) {
        if (displayInfo.isFullScreen) {
            [window fullScreenWithoutRequest];
        }
        else if (displayInfo.isMaximized) {
            [window maximizeWithoutRequest];
        }
        else if (window.state != BJLWindowState_maximized
                 && window.state != BJLWindowState_fullscreen) {
            [window updateWithRelativeRect:CGRectMake(displayInfo.x, displayInfo.y, displayInfo.width, displayInfo.height)];
        }
        else {
            if (displayInfo) {
                [window updateWithRelativeRect:CGRectMake(displayInfo.x, displayInfo.y, displayInfo.width, displayInfo.height)];
            }
            [window restoreWithoutRequest];
        }
    }
    else {
        [window updateWithRelativeRect:CGRectMake(displayInfo.x, displayInfo.y, displayInfo.width, displayInfo.height)];
    }
    [window bringToFrontWithoutRequest];
    [self.mutableVideoWindowDisplayInfos bjl_addObject:displayInfo];
    self.videoWindowDisplayInfos = self.mutableVideoWindowDisplayInfos;
}

#pragma mark - action

- (void)closeDisplayingVideoWindowsWithRequestUpdate:(BOOL)requestUpdate ignoreAutoDiaplayMaxWindow:(BOOL)ignoreAutoDiaplayMaxWindow  {
    for (BJLIcVideoWindowViewController *videoWindow in [self.displayingVideoWindows copy]) {
        BOOL maximize = NO;
        BOOL autoDisplay = [self needAutoDisplayVideoWindowWithUser:videoWindow.videoView.user maximize:&maximize];
        if (ignoreAutoDiaplayMaxWindow
            && autoDisplay
            && maximize) {
            break;
        }
        if (requestUpdate) {
            [videoWindow close];
        }
        else {
            [videoWindow closeWithoutRequest];
        }
    }
}

- (void)closeDisplayingVideoWindowWithMediaID:(NSString *)mediaID requestUpdate:(BOOL)requestUpdate {
    BJLIcVideoWindowViewController *videoWindow = [self videoWindowWithMediaUser:nil mediaID:mediaID];
    if (!videoWindow) {
        return;
    }
    if (requestUpdate) {
        [videoWindow close];
    }
    else {
        [videoWindow closeWithoutRequest];
    }
}

- (void)closeDisplayingVideoWindowsForUser:(BJLUser *)user requestUpdate:(BOOL)requestUpdate {
    for (BJLIcVideoWindowViewController *videoWindow in [self.displayingVideoWindows copy]) {
        if ([user containsMediaWithID:videoWindow.videoView.user.mediaID]) {
            if (requestUpdate) {
                [videoWindow close];
            }
            else {
                [videoWindow closeWithoutRequest];
            }
        }
    }
}

- (BJLIcVideoWindowViewController *)displayVideoWindowWithVideoView:(BJLIcUserMediaInfoView *)videoView
                                                      requestUpdate:(BOOL)requestUpdate  {
    BJLIcVideoWindowViewController *videoWindow = [self videoWindowWithMediaUser:videoView.user mediaID:nil];
    if (videoWindow) {
        // 已存在, 置顶
        videoView.position = BJLIcVideoPosition_blackboard;
        [videoWindow bringToFrontWithoutRequest];
        return videoWindow;
    }
    // 切换为大流
    if (BJLIcTemplateType_1v1 != self.room.roomInfo.interactiveClassTemplateType) {
        [self.room.playingVM switchVideoDefinitionWithUser:videoView.user useLowDefinition:NO];
    }
    
    
    videoWindow = [[BJLIcVideoWindowViewController alloc] initWithRoom:self.room];
    [videoWindow setWindowedParentViewController:self superview:self.videoWindowsView];
    [videoWindow setFullscreenParentViewController:self.fullscreenParentViewController
                                         superview:self.fullscreenSuperview];
    [videoWindow updateVideoView:videoView];
    videoView.position = BJLIcVideoPosition_blackboard;
    [videoView updateParentViewController:videoWindow];
    
    bjl_weakify(self, videoWindow, videoView);
    [videoWindow setSingleTapGestureCallback:^(CGPoint point) {
        bjl_strongify(videoView);
        [videoView handleSingleTapGesture:point];
    }];
    [videoWindow setVideoWindowCloseCallback:^(NSString *mediaID) {
        bjl_strongify(self, videoWindow);
        [self destroyVideoWindow:videoWindow];
    }];
    
    [videoWindow setWindowUpdateCallback:^(NSString * _Nonnull action, CGRect relativeRect) {
        bjl_strongify(self, videoWindow);
        BJLWindowDisplayInfo *oldDisplayInfo;
        for (BJLWindowDisplayInfo *displayInfo in [self.videoWindowDisplayInfos copy]) {
            if ([videoWindow.videoView isTargetMediaInfoViewWithMediaUser:nil mediaID:displayInfo.ID]) {
                oldDisplayInfo = displayInfo;
                break;
            }
        }
        [self.mutableVideoWindowDisplayInfos bjl_removeObject:oldDisplayInfo];
        if (![action isEqualToString:BJLWindowsUpdateAction_close]) {
            BOOL shouldKeepFullScreen = (![action isEqualToString:BJLWindowsUpdateAction_restore]
                                         && ![action isEqualToString:BJLWindowsUpdateAction_maximize]);
            BOOL shouldCKeepMaximize = (![action isEqualToString:BJLWindowsUpdateAction_restore]
                                        && ![action isEqualToString:BJLWindowsUpdateAction_fullScreen]);
            BJLWindowDisplayInfo *newDisplayInfo = ({
                BJLWindowDisplayInfo *info = [[BJLWindowDisplayInfo alloc] init];
                info.ID = videoWindow.videoView.user.mediaID;
                info.x = CGRectGetMinX(relativeRect);
                info.y = CGRectGetMinY(relativeRect);
                info.width = CGRectGetWidth(relativeRect);
                info.height = CGRectGetHeight(relativeRect);
                info.isFullScreen = ([action isEqualToString:BJLWindowsUpdateAction_fullScreen]
                                     || (oldDisplayInfo.isFullScreen && shouldKeepFullScreen));
                info.isMaximized = ([action isEqualToString:BJLWindowsUpdateAction_maximize]
                                    || (oldDisplayInfo.isMaximized && shouldCKeepMaximize));
                info;
            });
            [self.mutableVideoWindowDisplayInfos bjl_addObject:newDisplayInfo];
        }
        
        self.videoWindowDisplayInfos = self.mutableVideoWindowDisplayInfos;
        [self.room.playingVM updateVideoWindowWithMediaID:videoWindow.videoView.user.mediaID
                                                   action:action
                                             displayInfos:self.videoWindowDisplayInfos];
    }];
    
    [self bjl_observe:BJLMakeMethod(self, setFullscreenParentViewController:superview:)
             observer:^BOOL{
                 bjl_strongify(self, videoWindow);
                 [videoWindow setFullscreenParentViewController:self.fullscreenParentViewController
                                                      superview:self.fullscreenSuperview];
                 return YES;
             }];
    
    if (requestUpdate) {
        [videoWindow open];
    }
    else {
        [videoWindow openWithoutRequest];
    }
    [self.displayingVideoWindows bjl_addObject:videoWindow];
    return videoWindow;
}

- (void)destroyVideoWindow:(nullable BJLIcVideoWindowViewController *)videoWindow {
    [self.displayingVideoWindows bjl_removeObject:videoWindow];
    BJLIcUserMediaInfoView *mediaInfoView = [self.videoListViewController sendUserBackToSeatWithMediaID:videoWindow.videoView.user.mediaID];
    if (!mediaInfoView) {
        [videoWindow.videoView destroy];
        [videoWindow updateVideoView:nil];
        videoWindow = nil;
    }
}

#pragma mark - getter

- (nullable BJLIcVideoWindowViewController *)videoWindowWithMediaUser:(nullable BJLMediaUser *)mediaUser mediaID:(nullable NSString *)mediaID {
    for (BJLIcVideoWindowViewController *videoWindow in [self.displayingVideoWindows copy]) {
        if ([videoWindow.videoView isTargetMediaInfoViewWithMediaUser:mediaUser mediaID:mediaID]) {
            return videoWindow;
        }
    }
    return nil;
}

#pragma mark - touch move

- (void)setupTouchMoveGesture {
    bjl_weakify(self);
    __block BJLIcUserMediaInfoView *touchMovingVideoView;
    __block CGRect transformOriginFrame = CGRectZero;
    UIPanGestureRecognizer *panGesture = [UIPanGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        if (gesture.state == UIGestureRecognizerStateBegan) {
            BJLIcUserMediaInfoView *videoView = [self.videoListViewController mediaInfoViewWithPanGesture:gesture];
            if (videoView) {
                CGRect originFrame = [self.view convertRect:videoView.frame fromView:videoView.superview];
                [videoView removeFromSuperview];
                
                [self.view addSubview:videoView];
                // 视图放大为 1.1 倍，同时保持不超出边界
                CGFloat sizeScale = 1.1;
                transformOriginFrame = bjl_set(originFrame, {
                    set.origin.x -= set.size.width * (sizeScale - 1.0) / 2.0;
                    set.origin.y -= set.size.height * (sizeScale - 1.0) / 2.0;
                    set.size.width *= sizeScale;
                    set.size.height *= sizeScale;
                    
                    set.origin.x = MIN(MAX(0.0, set.origin.x), CGRectGetMaxX(self.view.bounds));
                    set.origin.y = MIN(MAX(0.0, set.origin.y), CGRectGetMaxY(self.view.bounds));
                });
                // !!!: 这里设置初始 frame 再添加自动布局，防止 UIGestureRecognizerStateChanged 触发过快（使用 Apple Pencil 点击）时，自动布局没有完成
                videoView.frame = transformOriginFrame;
                
                [videoView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                    make.left.equalTo(self.view).offset(videoView.frame.origin.x).priorityHigh();
                    make.top.equalTo(self.view).offset(videoView.frame.origin.y).priorityHigh();
                    make.size.equal.sizeOffset(videoView.frame.size);
                    // 边界限制
                    make.top.left.greaterThanOrEqualTo(self.view);
                    make.bottom.right.lessThanOrEqualTo(self.view);
                }];
                
                touchMovingVideoView = videoView;
            }
        }
        else if (gesture.state == UIGestureRecognizerStateChanged) {
            CGPoint translation = [gesture translationInView:gesture.view];
            
            // 更新偏移量
            CGFloat offsetX = transformOriginFrame.origin.x  + translation.x;
            CGFloat offsetY = transformOriginFrame.origin.y  + translation.y;
            
            // 修改当前 contentView 的位置
            if (touchMovingVideoView.superview == self.view) {
                [touchMovingVideoView bjl_updateConstraints:^(BJLConstraintMaker *make) {
                    make.left.equalTo(self.view).offset(offsetX).priorityHigh();
                    make.top.equalTo(self.view).offset(offsetY).priorityHigh();
                }];
            }
        }
        else if (gesture.state == UIGestureRecognizerStateEnded) {
            if (touchMovingVideoView) {
                CGPoint center = [self.view convertPoint:touchMovingVideoView.center toView:self.videoListViewController.view];
                if ([self.videoListViewController.view pointInside:center withEvent:nil]) {
                    // 拖动后视图中心点仍未超出列表范围，将视图放回原位置
                    [self.videoListViewController sendUserBackToSeatWithMediaID:touchMovingVideoView.user.mediaID];
                }
                else {
                    [self displayVideoWindowWithVideoView:touchMovingVideoView requestUpdate:YES];
                }
            }
            touchMovingVideoView = nil;
            transformOriginFrame = CGRectZero;
        }
        else if (gesture.state == UIGestureRecognizerStateCancelled) {
            [self.videoListViewController sendUserBackToSeatWithMediaID:touchMovingVideoView.user.mediaID];
            touchMovingVideoView = nil;
            transformOriginFrame = CGRectZero;
        }
    }];
    panGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:panGesture];
    self.touchMoveGesture = panGesture;
    // 只有老师才可以把学生视频窗口拖到黑板区
    self.touchMoveGesture.enabled = self.room.loginUser.isTeacher;
}

@end

NS_ASSUME_NONNULL_END
