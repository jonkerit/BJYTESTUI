//
//  BJLIcUserMediaInfoView.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/10/8.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLIcUserMediaInfoView.h"
#import "BJLIcUserMediaInfoView+private.h"
#import "BJLIcUserMediaInfoView+padUserVideoUpside.h"
#import "BJLIcUserMediaInfoView+pad1to1.h"
#import "BJLMutableAwardsView.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcUserMediaInfoView

- (instancetype)initWithUser:(BJLMediaUser *)user room:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
        self.user = user;
        self.isRecording = [user.ID isEqualToString:self.room.loginUser.ID];
        [self updateDataWithCurrentPresenter];
        self.videoView = self.isRecording ? self.room.recordingView : [self.room.playingVM playingViewForUserWithID:user.ID mediaSource:user.mediaSource];
        self.position = BJLIcVideoPosition_none;
        self.imageURLString = user.cameraCover;
        self.clipsToBounds = YES;
        self.needStopAnimation = YES;
        self.isNetworkMessageShowing = NO;
        
        self.lossRateDictionary = [NSMutableDictionary new];
        [self makeSubviews];
        [self makeObserving];
        
        bjl_weakify(self);
        UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
            bjl_strongify(self);
            CGPoint point = [gesture locationInView:self];
            if (!self.likeButton.hidden && CGRectContainsPoint(self.likeButton.frame, point)) {
                // 点击点赞按钮
                [self sendLikeForCurrentUser];
            }
            else {
                [self showUserOperateView:point];
            }
        }];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)dealloc {
    [self destroy];
}

- (void)destroy {
    [self stopLossRateObservingTimer];
    [self stopLoadingAnimation];
    [self bjl_stopAllKeyValueObserving];
    [self bjl_stopAllMethodParametersObserving];
    
    // 由于业务逻辑(1V1的班型,用户名字等信息未添加在当前界面上),销毁时,需要remove
    if (self.infoGroupView && self.infoGroupView.superview && self.infoGroupView.superview != self) {
        [self.infoGroupView removeFromSuperview];
    }
    
    if (self.optionViewController) {
        [self hideOptionViewController];
    }
    
    if (self.awardsViewController) {
        [self hideAwardsViewController];
    }
    
    if (self.videoView) {
        if (self.videoView.superview == self) {
            [self.videoView removeFromSuperview];
        }
        self.videoView = nil;
    }
}

 - (void)setBounds:(CGRect)bounds {
     [super setBounds:bounds];
     if ([self expectedContentMode] == BJLVideoContentMode_aspectFill) {
         [self updateWatermarkConstranints];
     }
 }

#pragma mark - subviews

- (void)makeSubviews {
    BJLIcTemplateType templateType = self.room.roomInfo.interactiveClassTemplateType;
    
    // 视频容器
    self.containerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_colorWithHex:0X313847];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view;
    });
    [self addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    
    // 视频加载占位图
    self.videoLoadingView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        view.hidden = YES;
        view;
    });
    [self addSubview:self.videoLoadingView];
    [self.videoLoadingView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    self.videoLoadingImageView = ({
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage bjlic_imageNamed:@"bjl_ic_user_loading"]];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView;
    });
    [self.videoLoadingView addSubview:self.videoLoadingImageView];
    [self.videoLoadingImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.videoLoadingView);
        make.height.equalTo(self.videoLoadingView).multipliedBy(0.5);
        make.width.equalTo(self.videoLoadingImageView.bjl_height);
        make.height.width.lessThanOrEqualTo(@(480.0)).priorityHigh();
        make.height.width.greaterThanOrEqualTo(@(32.0)).priorityHigh();
    }];
    
    // 视频关闭占位图,远端用户是否没有推视频流
    self.placeholderImageLayer = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, placeholderImageLayer);
        view.hidden = YES;
        view;
    });
    [self addSubview:self.placeholderImageLayer];
    [self.placeholderImageLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];

    self.placeholderImageView = ({
        UIImageView *imageView = [self imageViewWithName:@"bjl_ic_user_video_off"];
        imageView.accessibilityLabel = BJLKeypath(self, placeholderImageView);
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView;
    });
    [self.placeholderImageLayer addSubview:self.placeholderImageView];
    [self.placeholderImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.center.equalTo(self.placeholderImageLayer);
        make.height.equalTo(self.placeholderImageLayer).multipliedBy(0.5);
        make.width.equalTo(self.placeholderImageView.bjl_height);
        make.height.width.lessThanOrEqualTo(@(BJLIcAppearance.userVideoPlaceholderImageMaxWidth)).priorityHigh();
        make.height.width.greaterThanOrEqualTo(@(BJLIcAppearance.userVideoPlaceholderImageMinWidth)).priorityHigh();
    }];
    
    // 纯音频占位图,本地用户可以手动不看某个用户的视频
    self.urlImageLayer = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, urlImageLayer);
        view.hidden = YES;
        view;
    });
    [self addSubview:self.urlImageLayer];
    [self.urlImageLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];

    self.urlImageView = ({
        UIImageView *imageView = [self imageViewWithName:@"bjl_ic_user_placeholder"];
        imageView.accessibilityLabel = BJLKeypath(self, urlImageView);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [imageView bjl_setImageWithURL:[NSURL URLWithString:self.user.avatar] placeholder:[UIImage bjlic_imageNamed:@"bjl_ic_user_placeholder"] completion:nil];
        imageView;
    });
    [self.urlImageLayer addSubview:self.urlImageView];
    [self.urlImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.urlImageLayer);
    }];

    if (BJLIcTemplateType_1v1 == templateType) {
        [self makePad1to1Subviews];
    }
    else {
        [self makePadUserVideoUpsideSubviews];
    }
    
    // 初始化时根据 user 状态设置音频状态
    self.audioLevelView.image = [self imageWithUserAudioState];
    // 隐藏非 1v1 主讲人外的非主摄像头的信息视图
    BOOL isPresenter = [self.user isSameUser:self.room.onlineUsersVM.currentPresenter];
    BOOL isAssistantPlayMedia = self.user.isTeacherOrAssistant && self.user.mediaSource == BJLMediaSource_mediaFile;
    if ((isPresenter
         || isAssistantPlayMedia
         || self.room.roomInfo.interactiveClassTemplateType == BJLIcTemplateType_1v1)
        && self.user.mediaSource != BJLMediaSource_mainCamera) {
        self.infoGroupView.hidden = YES;
    }
}

- (void)updateVideoViewConstranints {
    if (!self.videoView || self.videoView.superview != self) {
        return;
    }
    CGFloat videoRatio = (self.isRecording
                          ? self.room.recordingVM.inputVideoAspectRatio
                          : [self.room.playingVM playingViewAspectRatioForUserWithID:self.user.ID mediaSource:self.user.mediaSource]);
    BJLVideoContentMode contentMode = [self expectedContentMode];
    switch (contentMode) {
        case BJLVideoContentMode_aspectFit: {
            [self.videoView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                make.edges.equalTo(self.containerView);
            }];
            break;
        }
            
        case BJLVideoContentMode_aspectFill: {
            [self.videoView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                make.edges.equalTo(self.containerView).priorityHigh();
                make.center.equalTo(self.containerView);
                make.top.left.lessThanOrEqualTo(self.containerView);
                make.bottom.right.greaterThanOrEqualTo(self.containerView);
                make.width.equalTo(self.videoView.bjl_height).multipliedBy(videoRatio);
            }];
            break;
        }
            
        default:
            break;
    }
    [self updateWatermarkConstranints];
}

- (void)updateWatermarkConstranints {
    BJLVideoContentMode contentMode = [self expectedContentMode];
    CGFloat videoRatio = (self.isRecording
                          ? self.room.recordingVM.inputVideoAspectRatio
                          : [self.room.playingVM playingViewAspectRatioForUserWithID:self.user.ID mediaSource:self.user.mediaSource]);
    switch (contentMode) {
        case BJLVideoContentMode_aspectFit:
            [self.room.playingVM updateWatermarkWithUser:self.user size:CGSizeMake(videoRatio, 1.0) videoContentMode:BJLVideoContentMode_aspectFit];
            break;
            
        case BJLVideoContentMode_aspectFill:
            [self.room.playingVM updateWatermarkWithUser:self.user size:self.bounds.size videoContentMode:BJLVideoContentMode_aspectFill];
            break;
            
        default:
            break;
    }
}

- (BJLVideoContentMode)expectedContentMode {
    if (self.user.mediaSource == BJLMediaSource_mediaFile
        || self.user.mediaSource == BJLMediaSource_screenShare
        || self.user.mediaSource == BJLMediaSource_extraScreenShare) {
        return BJLVideoContentMode_aspectFit;
    }
    return BJLVideoContentMode_aspectFill;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateLikeCount];
}

#pragma mark - observers

- (void)makeObserving {
    bjl_weakify(self);
    
    if (self.isRecording) {
        // 采集的声音状态
        [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, recordingAudio)
             observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            self.audioLevelView.image = [self imageWithUserAudioState];
            return YES;
        }];
    }
    else {
        // loading 状态
        [self bjl_kvo:BJLMakeProperty(self, user)
             observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            if (self.user) {
                [self remakeObservingForUser:self.user];
            }
            return YES;
        }];
    }
    
    // 更新水印
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, playingViewAspectRatioChanged:forUser:)
             observer:(BJLMethodObserver)^BOOL(CGFloat ratio, BJLMediaUser *user) {
        bjl_strongify(self);
        if ([user.mediaID isEqualToString:self.user.mediaID]) {
            [self.room.playingVM updateWatermarkWithUser:user size:CGSizeMake(ratio, 1.0) videoContentMode:BJLVideoContentMode_aspectFit];
        }
        return YES;
    }];
    
    // 更新占位图状态
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, playingUserDidUpdate:old:)
             observer:(BJLMethodFilter)^(BJLMediaUser * _Nullable user, BJLMediaUser * _Nullable old) {
        bjl_strongify(self);
        [self updateCurrentUser];
        if ([user.mediaID isEqualToString:self.user.mediaID]) {
            // 开音频的时候默认最小音量的图标
            self.audioLevelView.image = [self imageWithUserAudioState];
            // 更新 用户的视频占位背景图
            self.imageURLString = user.cameraCover;
            [self updatePlaceholderImageView];
        }
        return YES;
    }];
    
    // 主讲人
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, currentPresenter)
           filter:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now != old;
           }
         observer:^BOOL(__kindof BJLUser * _Nullable user, __kindof BJLUser * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        BOOL wasPresenter = self.user && old && [self.user isSameUser:old];
        BOOL isPresenter = self.user && user && [self.user isSameUser:user];
        if (wasPresenter != isPresenter) {
            [self updateDataWithCurrentPresenter];
        }
        return YES;
    }];
    
    // 更新音量
    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, volumeDidUpdateWithUser:volume:)
             observer:(BJLMethodObserver)^BOOL(BJLMediaUser *user, CGFloat volume){
        bjl_strongify(self);
        if (user.mediaSource == BJLMediaSource_mainCamera
            && [user.mediaID isEqualToString:self.user.mediaID]
            && self.user.audioOn) {
            self.audioLevelView.image = [self imageWithAudioVolume:volume];
        }
        return YES;
    }];
    
    // 网络状态信息
    [self restartLossRateObservingTimer];
    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, mediaLossRateDidUpdateWithUser:videoLossRate:audioLossRate:)
             observer:(BJLMethodObserver)^BOOL(BJLMediaUser *user, CGFloat videoLossRate, CGFloat audioLossRate) {
        bjl_strongify(self);
        // 目前只统计所有用户主摄流的丢包
        if(user.mediaSource != BJLMediaSource_mainCamera) {
            return YES;
        }
        CGFloat packageLossRate = MIN(MAX(0.0, videoLossRate), 100.0);
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
    
    // 根据分组显示边框
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, onlineUserGroupInfoDidChangeWithUserNumbers:groupInfo:)
             observer:^BOOL(NSArray<NSString *> *userNumbers, BJLUserGroup * _Nullable groupInfo) {
        bjl_strongify(self);
        if (self.user.number.length && [userNumbers containsObject:self.user.number]) {
            [self updateCurrentUser];
            [self updateGroupColorWithGroupInfo:groupInfo];
        }
        return YES;
    }];
    
    // 由于无法保证 grouplist 信息在拿到 userlist 之前获取到,所以需要监听 groupList 的变化
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, groupList)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateGroupColorWithGroupInfo:nil];
        return YES;
    }];
    
    // 更新占位图
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, didRecieveUserCameraCover:userNumber:)
             observer:^BOOL(NSString *imageURLString, NSString *userNumber) {
        bjl_strongify(self);
        // 目前限制只有老师助教背景可以修改
        if ([userNumber isEqualToString:self.user.number] && self.user.isTeacherOrAssistant) {
            self.imageURLString = imageURLString;
            [self updatePlaceholderImageView];
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, didRecieveUserStateUpdateWithUserNumber:audioState:videoState:) observer:^BOOL(NSString *userNumber, BJLUserMediaState audioState, BJLUserMediaState videoState) {
        bjl_strongify(self);
        if ([userNumber isEqualToString:self.user.number]) {
            [self updatePlaceholderImageView];
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveLikeForGroupID:groupName:) observer:^BOOL(NSInteger groupID, NSString *groupName) {
        bjl_strongify(self);
        if (groupID == 0) {
            [self updateLikeCount];
        }
        return YES;
    }];
}

- (void)remakeObservingForUser:(BJLMediaUser *)mediaUser {
    [self.mediaUserObservation stopObserving];
    self.mediaUserObservation = nil;
    bjl_weakify(self);
    // loading 显示与隐藏
    self.mediaUserObservation = [self bjl_kvo:BJLMakeProperty(self.user, isLoading)
                                     observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateLoadingViewHidden:!self.user.isLoading];
        return YES;
    }];
}

#pragma mark - public

- (void)setPosition:(BJLIcVideoPosition)position {
    if (position != _position) {
        self.prevPosition = _position;
        _position = position;
        if (self.updatePositionCallback) {
            self.updatePositionCallback(position);
        }
    }
}

- (void)restorePositon {
    if (self.prevPosition != self.position
        && self.prevPosition != BJLIcVideoPosition_none) {
        self.position = self.prevPosition;
    }
    else if (self.prevPosition == BJLIcVideoPosition_none) {
        self.position = BJLIcVideoPosition_videoList;
    }
}

- (void)updateParentViewController:(UIViewController *)parentViewController {
    self.parentViewController = parentViewController;
    if (self.optionViewController) {
        [self hideOptionViewController];
    }
    if (self.awardsViewController) {
        [self hideAwardsViewController];
    }
}

- (void)updateContentWithUser:(BJLMediaUser *)user
             combineVideoView:(BOOL)combineVideoView {
    // 如果当前的视图应该处理的用户对象不包含参数中的对象，返回
    if (![self.availableMediaID containsObject:user.mediaID]) {
        return;
    }
    // 如果更新了，重置 videoView
    if (![self.user.mediaID isEqualToString:user.mediaID]) {
        [self.videoView removeFromSuperview];
        self.videoView = self.isRecording ? self.room.recordingView : [self.room.playingVM playingViewForUserWithID:user.ID mediaSource:user.mediaSource];
    }
    self.user = user;
    
    // 用户名
    self.userNameLabel.text = user.displayName;
    // 占位图需要在更新视频的显示和隐藏前设置
    [self updatePlaceholderImageView];
        
    // 视频开关
    BOOL videoOn = user.videoOn;
    if (videoOn && combineVideoView && self.videoView) {
        if (self.videoView.superview) {
            [self.videoView removeFromSuperview];
        }
        self.videoView.userInteractionEnabled = NO;
        [self insertSubview:self.videoView belowSubview:self.videoLoadingView];
        [self updateVideoViewConstranints];
    }
    
    self.videoView.hidden = !videoOn || !self.placeholderImageLayer.hidden || !self.urlImageLayer.hidden;

    // 音频状态
    self.audioLevelView.image = [self imageWithUserAudioState];
    // 分组颜色
    [self updateGroupColorWithGroupInfo:nil];
}

- (void)handleSingleTapGesture:(CGPoint)point {
    if (!self.likeButton.hidden && CGRectContainsPoint(self.likeButton.frame, point)) {
        // 点击点赞按钮
        [self sendLikeForCurrentUser];
    }
    else if (!self.speakRequestControlView.hidden && CGRectContainsPoint(self.allowSpeakRequestButton.frame, point)) {
        // 点击允许举手
        [self allowSpeakRequest];
    }
    else if (!self.speakRequestControlView.hidden && CGRectContainsPoint(self.refuseSpeakRequestButton.frame, point)) {
        // 点击拒绝举手
        [self refuseSpeakRequest];
    }
    else if (!self.speakRequestButton.hidden && CGRectContainsPoint(self.speakRequestButton.frame, point)) {
        // 举手按钮
        [self showSpeakRequestControlView];
    }
    else {
        // 显示菜单
        [self showUserOperateView:point];
    }
}


// 音视频用户更新点赞数, 学生点赞数为0时不显示, 能给别人点赞的人一直显示, 助教和老师自己不显示
- (void)updateWithLikeCount:(NSInteger)count {
    [self.likeButton setTitle:count ? [NSString stringWithFormat:@"%ld", (long)count] : nil forState:UIControlStateNormal];
    BOOL hideLikeButton = !self.user || self.user.isTeacherOrAssistant || (self.room.loginUser.isStudent && !count);
    self.likeButton.hidden = hideLikeButton;
    // fire
    BOOL drawingGranted = [self.room.drawingVM.drawingGrantedUserNumbers containsObject:self.user.number];
    BOOL webPPTAuthorized = [self.room.documentVM.authorizedPPTUserNumbers containsObject:self.user.number];
    [self updateDrawingGranted:drawingGranted webPPTAuthorized:webPPTAuthorized];
}

// 暂时不叠加分组点赞的数据
- (void)updateLikeCount {
    /* 1、老师助教隐藏点赞按钮，
       2、登录用户是学生，视频是学生视频，并且点赞数为0，隐藏点赞按钮 */
    NSInteger likeCount = [self.room.roomVM.likeList bjl_integerForKey:self.user.number];
    [self updateWithLikeCount:likeCount];
}

// 更新动态课件授权标志
- (void)updateWebPPTAuthorized:(BOOL)webPPTAuthorized {
    BOOL drawingGranted = [self.room.drawingVM.drawingGrantedUserNumbers containsObject:self.user.number];
    [self updateDrawingGranted:drawingGranted webPPTAuthorized:webPPTAuthorized];
}

// 更新画笔授权标志
- (void)updateDrawingGranted:(BOOL)drawingGranted {
    BOOL webPPTAuthorized = [self.room.documentVM.authorizedPPTUserNumbers containsObject:self.user.number];
    [self updateDrawingGranted:drawingGranted webPPTAuthorized:webPPTAuthorized];
}

- (void)updateDrawingGranted:(BOOL)drawingGranted webPPTAuthorized:(BOOL)webPPTAuthorized {
    self.webPPTAuthorizedView.hidden = !webPPTAuthorized;
    self.drawingGrantedView.hidden = !drawingGranted;
    
    [self.likeButton bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.equalTo(self.likeButton.hidden ? @0.0 : @(self.likeButton.intrinsicContentSize.width));
        make.left.equalTo(self).offset(self.likeButton.hidden ? 0.0 : 4.0);
    }];
    
    [self.webPPTAuthorizedView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.height.equalTo(@(webPPTAuthorized ? 12.0 : 0.0)); // 隐藏或显示，一直偏移
        make.left.equalTo(self.likeButton.bjl_right).offset(webPPTAuthorized ? 4.0 : 0.0); // 隐藏时不偏移
    }];
    
    [self.drawingGrantedView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.height.equalTo(@(drawingGranted ? 12.0 : 0.0)); // 隐藏或显示
        make.left.equalTo(self.webPPTAuthorizedView.bjl_right).offset(drawingGranted ? 4.0 : 0.0); // 隐藏时不偏移
    }];
}

- (void)updateSpeakRequestViewHidden:(BOOL)hidden {
    if (hidden) {
        self.speakRequestButton.hidden = YES;
        self.speakRequestControlView.hidden = YES;
    }
    else {
        self.speakRequestButton.hidden = NO;
        self.speakRequestControlView.hidden = YES;
    }
}

- (void)updateInfoGroupViewWithReferenceView:(UIView *)referenceView {
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        [self updatePad1to1InfoGroupViewWithReferenceView:referenceView];
    }
}

- (BOOL)isTargetMediaInfoViewWithMediaUser:(nullable BJLMediaUser *)mediaUser mediaID:(nullable NSString *)mediaID {
    BOOL isTargetMediaInfoView = NO;
    NSString *targetMediaID = mediaUser ? mediaUser.mediaID : mediaID;
    if ([self.availableMediaID containsObject:targetMediaID]) {
        isTargetMediaInfoView = YES;
    }
    return isTargetMediaInfoView;
}

#pragma mark - mediaID

// 更新主讲人身份变更会影响的事件
- (void)updateDataWithCurrentPresenter {
    self.availableMediaID = [self availableMediaIDWithCurrentUser];
}

// 兼容对于不同的媒体源使用了任意的 mediaID，导致无法定位到正确的视图
- (NSArray<NSString *> *)availableMediaIDWithCurrentUser {
    NSString *userID = self.user.ID;
    if (!userID.length) {
        return @[];
    }
    BOOL isPresenter = [self.user isSameUser:self.room.onlineUsersVM.currentPresenter];
    if (isPresenter
        || self.room.roomInfo.interactiveClassTemplateType == BJLIcTemplateType_1v1) {
        return @[self.user.mediaID ?: userID];
    }
    
    NSInteger userIDIntegerValue = [userID bjl_integerValue];
    NSString *mainCamera = [NSString stringWithFormat:@"%td", userIDIntegerValue + BJLMediaSource_mainCamera];
    NSString *screenShare = [NSString stringWithFormat:@"%td", userIDIntegerValue + BJLMediaSource_screenShare];
    NSString *mediaFile = [NSString stringWithFormat:@"%td", userIDIntegerValue + BJLMediaSource_mediaFile];
    NSString *extraCamera = [NSString stringWithFormat:@"%td", userIDIntegerValue + BJLMediaSource_extraCamera];
    NSString *extraScreenShare = [NSString stringWithFormat:@"%td", userIDIntegerValue + BJLMediaSource_extraScreenShare];
    
    // 播放媒体的助教作为单独的一路流
    BOOL isAssistant = self.user.isTeacherOrAssistant;
    if (isAssistant) {
        if (self.user.mediaSource == BJLMediaSource_mediaFile) {
            return @[mediaFile];
        }
        else if (self.user.cameraType == BJLCameraType_main) {
            return @[mainCamera, screenShare];
        }
        else {
            return @[extraCamera, extraScreenShare];
        }
    }
    // 学生的目前 UI 设计上最多只有二路流
    if (self.user.cameraType == BJLCameraType_main) {
        return @[mainCamera, screenShare, mediaFile];
    }
    else {
        return @[extraCamera, extraScreenShare];
    }
}

#pragma mark - group

- (void)updateGroupColorWithGroupInfo:(nullable BJLUserGroup *)groupInfo {
    if (groupInfo) {
        self.groupColorView.backgroundColor = [UIColor bjl_colorWithHexString:groupInfo.color] ?: [UIColor clearColor];
        return;
    }
    NSUInteger groupID = self.user.groupID;
    if (!groupID) {
        self.groupColorView.backgroundColor = [UIColor clearColor];
        return;
    }
    for (BJLUserGroup *group in [self.room.onlineUsersVM.groupList copy]) {
        if (group.groupID == groupID) {
            self.groupColorView.backgroundColor = [UIColor bjl_colorWithHexString:group.color] ?: [UIColor clearColor];
            return;
        }
    }
    self.groupColorView.backgroundColor = [UIColor clearColor];
}

#pragma mark - placeholder

/* 有使用png的占位图和使用url的布局不一致, 调整UI为:
 1. 需要使用本地png的统一使用placeholderImageView展示;
    1) 用户未推视频流,且未设置背景图片;
    2) 当前用户对视频流用户操作关闭画面, 如果avatar属性为空则展示占位图
    3) 用户视频处于不可用状态
 2. 需要网络请求的使用urlImageView展示
    1) 用户未推视频流,且设置了背景图片;
    2) 当前用户对视频流用户操作关闭画面, 展示avatar所示的图片
*/
- (void)updatePlaceholderImageView {
    BOOL videoOn = self.user.videoOn;
    BOOL isVideoPlayingUser = [self isVideoPlayingUser];
    
    // 远端用户关闭了视频需要展示 : 音视频不可用 > 背景图 > 默认占位图
    BOOL showVideOffPlaceholder = self.user && !videoOn;

    // 采集不显示，无 user 显示，显示了 videoOffImageView 不显示，播放视频不显示 :头像 > 占位图
    BOOL showAudioOnlyPlaceholder = (!self.isRecording && (!self.user || (!showVideOffPlaceholder && !isVideoPlayingUser)));
    
    self.placeholderImageLayer.hidden = !((showVideOffPlaceholder && !self.imageURLString.length) || (showAudioOnlyPlaceholder && !self.user.avatar.length));
    self.urlImageLayer.hidden = !((showVideOffPlaceholder && self.imageURLString.length) || (showAudioOnlyPlaceholder && self.user.avatar.length));
    
    NSString *imageName = @"bjl_ic_user_seat";
    if (showVideOffPlaceholder) {
        if (self.user.videoState == BJLUserMediaState_backstage) {
            imageName = @"bjl_ic_user_enterbackground";
        }
        else if (self.user.videoState != BJLUserMediaState_available) {
            imageName = @"bjl_ic_user_mediaState_unavaliable";
        }
        else {
            imageName = @"bjl_ic_user_video_off";
        }
    }
    else if (showAudioOnlyPlaceholder) {
        imageName = @"bjl_ic_user_placeholder";
    }
    [self.placeholderImageView setImage:[UIImage bjlic_imageNamed:imageName]];
    
    NSString *imageUrlString = self.imageURLString;
    if (showAudioOnlyPlaceholder) {
        imageUrlString = self.user.avatar;
    }
    [self.urlImageView bjl_setImageWithURL:[NSURL URLWithString:imageUrlString] placeholder:[UIImage bjlic_imageNamed:@"bjl_ic_user_seat"] completion:nil];
}

- (void)updatePlayVideo:(BOOL)playVideo {
    if (self.isRecording) {
        return;
    }
    
    if (!self.user.videoOn) {
        return;
    }
    
    BOOL isVideoPlayingUser = [self isVideoPlayingUser];
    if (playVideo == isVideoPlayingUser) {
        return;
    }
    
    [self updateVideoForCurrentUser:playVideo disableAutoPlay:NO];
}

#pragma mark - actions

- (void)showUserOperateView:(CGPoint)point {
    if (!self.room.roomVM.liveStarted) {
        return;
    }
    if (!self.speakRequestButton.hidden || !self.speakRequestControlView.hidden) {
        return;
    }
    
    // 主讲人的其他媒体流不处理
    BOOL isPresenter = [self.user isSameUser:self.room.onlineUsersVM.currentPresenter];
    BOOL isAssistantPlayMedia = self.user.isTeacherOrAssistant && self.user.mediaSource == BJLMediaSource_mediaFile;
    if ((isPresenter
         || isAssistantPlayMedia
         || self.room.roomInfo.interactiveClassTemplateType == BJLIcTemplateType_1v1)
        && self.user.mediaSource != BJLMediaSource_mainCamera) {
        return;
    }
    
    BJLIcUserOperateViewType operateViewType = BJLIcUserOperateViewStudent;
    if ([self.user.ID isEqualToString:self.room.loginUser.ID]) {
        operateViewType = BJLIcUserOperateViewSelf;
    }
    else {
        operateViewType = (self.room.loginUser.isTeacherOrAssistant
                           ? BJLIcUserOperateViewTeacher
                           : BJLIcUserOperateViewStudent);
    }
    
    // optionView
    BJLIcUserOperateView *optionView = [[BJLIcUserOperateView alloc] initWithType:operateViewType];
    // 更新当前user
    [self updateCurrentUser];
    BOOL enableStudentExtraCameraAndScreenShare = self.room.roomInfo.interactiveClassTemplateType == BJLIcTemplateType_1v1
                                                   &&  (self.user.clientType == BJLClientType_PCWeb
                                                   || self.user.clientType == BJLClientType_PCApp
                                                   || self.user.clientType == BJLClientType_MacApp);
    // 更新状态
    optionView.videoOn = [self isVideoPlayingUser];
    optionView.cameraOn = self.user.videoOn;
    optionView.microphoneOn = self.user.audioOn;
    optionView.drawingGranted =  [self.room.drawingVM.drawingGrantedUserNumbers containsObject:self.user.number];
    optionView.webPPTAuthorized =  [self.room.documentVM.authorizedPPTUserNumbers containsObject:self.user.number];
    optionView.extraCameraAuthorized = [self.room.recordingVM.authorizedExtraCameraUserNumbers containsObject:self.user.number];
    optionView.screenShareAuthorized = [self.room.recordingVM.authorizedScreenShareUserNumbers containsObject:self.user.number];
    optionView.isPresenter = isPresenter;
    optionView.isAssistant = self.user.isAssistant;
    optionView.enableStudentExtraCameraAndScreenShare = enableStudentExtraCameraAndScreenShare;
    optionView.maxVideoDefinition = self.room.featureConfig.maxVideoDefinition;
    optionView.currentVideoDefinition = self.room.recordingVM.videoDefinition;
    // 更新菜单布局
    [optionView updateButtonConstraints];
    // 菜单，修改操作权限时需要同步修改视图的 UI
    NSInteger count = [optionView expectedOperateCount];
    // 如果操作项没有了，不显示菜单
    if (count <= 0) {
        return;
    }
    CGFloat height = BJLIcAppearance.userOptionViewHeight * count + 16.0;
    CGFloat width = 120.0;
    self.optionViewController = ({
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view.backgroundColor = [UIColor clearColor];
        viewController.modalPresentationStyle = UIModalPresentationPopover;
        viewController.preferredContentSize = CGSizeMake(width, height);
        viewController.popoverPresentationController.backgroundColor = BJLIcTheme.toolboxBackgroundColor;
        viewController.popoverPresentationController.delegate = self;
        viewController.popoverPresentationController.sourceView = self;
        viewController.popoverPresentationController.sourceRect = CGRectMake(point.x, point.y, 1.0, 1.0);
        viewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
        viewController;
    });
    [self.optionViewController.view addSubview:optionView];
    [optionView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.optionViewController.view.bjl_safeAreaLayoutGuide ?: self.optionViewController.view);
    }];
    bjl_weakify(self);
    [optionView setUpdateDefinitionCallback:^(BJLVideoDefinition definition) {
        bjl_strongify(self);
        [self hideOptionViewController];
        [self.room.recordingVM updateVideoDefinition:definition];
    }];
    [optionView setUpdateVideoCallback:^(BOOL on) {
        bjl_strongify(self);
        [self updateVideoForCurrentUser:on disableAutoPlay:YES];
        [self hideOptionViewController];
    }];
    [optionView setSwitchCameraCallback:^{
        bjl_strongify(self);
        [self.room.recordingVM updateUsingRearCamera:!self.room.recordingVM.usingRearCamera];
        [self hideOptionViewController];
    }];
    [optionView setOpenCameraCallback:^{
        bjl_strongify(self);
        [self.room.recordingVM setRecordingAudio:self.room.recordingVM.recordingAudio recordingVideo:YES];
        [self hideOptionViewController];
    }];
    [optionView setUpdateCameraCallback:^(BOOL on) {
        bjl_strongify(self);
        [self updateCameraForCurrentUser:on];
        [self hideOptionViewController];
    }];
    [optionView setUpdateMicrophoneCallback:^(BOOL on) {
        bjl_strongify(self);
        [self updateMicrophoneForCurrentUser:on];
        [self hideOptionViewController];
    }];
    [optionView setGrantDrawingCallback:^(BOOL grant) {
        bjl_strongify(self);
        [self updateDrawingGrantedForCurrentUser:grant];
        [self hideOptionViewController];
    }];
    [optionView setAuthorizeWebPPTCallback:^(BOOL authorized) {
        bjl_strongify(self);
        [self updateWebPPTAuthorizedForCurrentUser:authorized];
        [self hideOptionViewController];
    }];
    [optionView setAuthorizeExtraCameraCallback:^(BOOL authorized) {
        bjl_strongify(self);
        [self updateExtraCameraAuthorizedForCurrentUser:authorized];
        [self hideOptionViewController];
    }];
    [optionView setAuthorizeScreenShareCallback:^(BOOL authorized) {
        bjl_strongify(self);
        [self updateScreenShareAuthorizedForCurrentUser:authorized];
        [self hideOptionViewController];
    }];
//    [optionView setSendLikeCallback:^{
//        bjl_strongify(self);
//        [self sendLikeForCurrentUser];
//        [self hideOptionViewController];
//    }];
    [optionView setBlockUserCallback:^{
        bjl_strongify(self);
        [self blockCurrentUser];
        [self hideOptionViewController];
    }];
    if (self.parentViewController.presentedViewController) {
        [self.parentViewController.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self.parentViewController presentViewController:self.optionViewController animated:YES completion:nil];
}

- (BOOL)updateVideoForCurrentUser:(BOOL)on disableAutoPlay:(BOOL)disableAutoPlay {
    BJLError *error = [self.room.playingVM updatePlayingUserWithID:self.user.ID videoOn:on mediaSource:self.user.mediaSource];
    if (!error) {
        if (disableAutoPlay && self.updateVideoCallback) {
            self.updateVideoCallback(self.user, on);
        }
        [self updatePlaceholderImageView];
        self.videoView.hidden = !self.user.videoOn || !self.placeholderImageLayer.hidden || !self.urlImageLayer.hidden;
    }
    [self throwError:error];
    return !error;
}

- (BOOL)updateCameraForCurrentUser:(BOOL)on {
    BJLError *error = [self.room.recordingVM remoteChangeRecordingWithUser:self.user audioOn:self.user.audioOn videoOn:on];
    [self throwError:error];
    return !error;
}
  
- (BOOL)updateMicrophoneForCurrentUser:(BOOL)on {
    BJLError *error = [self.room.recordingVM remoteChangeRecordingWithUser:self.user audioOn:on videoOn:self.user.videoOn];
    [self throwError:error];
    return !error;
}

- (BOOL)updateDrawingGrantedForCurrentUser:(BOOL)granted {
    NSString *color = nil;
    bjl_weakify(self);
    if(self.user.number) {
        __block NSString *savedColor = nil;
        [self.room.drawingVM.drawingGrantedColors enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            bjl_strongify(self);
            if(obj && [obj isEqualToString:self.user.number]) {
                savedColor = key;
                *stop = YES;
            }
        }];
        color = savedColor;
    }
    
    if(!color && granted) {
        NSArray *allUserNumbers = [self.room.drawingVM.drawingGrantedColors allKeys];

        NSMutableArray *colorsArray = [[self strokeColors] mutableCopy];
        [self.room.drawingVM.drawingGrantedColors enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            bjl_strongify(self);
            if([[self strokeColors] containsObject:key]) {
                [colorsArray removeObject:key];
            }
        }];
        
        if([colorsArray count]) {
            color = [colorsArray lastObject];
        }
        else {
            __block NSString *removedNumber = nil;
            for(int i = 0; i < [allUserNumbers count]; i++) {
                NSString *number = [allUserNumbers objectAtIndex:i];
                if(number && ![self.room.drawingVM.drawingGrantedUserNumbers containsObject:number]) {
                    removedNumber = number;
                    break;
                }
            }
            if(removedNumber) {
                [self.room.drawingVM deleteColorRecordWithUserNumber:removedNumber];
                color = [self.room.drawingVM.drawingGrantedColors bjl_stringForKey:removedNumber];
            }
        }
    }
    
    BJLError *error = [self.room.drawingVM updateDrawingGranted:granted userNumber:self.user.number color:color];
    [self throwError:error];
    return !error;
}

- (BOOL)updateWebPPTAuthorizedForCurrentUser:(BOOL)authorized {
    BJLError *error = [self.room.documentVM updateStudentPPTAuthorized:authorized userNumber:self.user.number];
    [self throwError:error];
    return !error;
}

- (BOOL)updateExtraCameraAuthorizedForCurrentUser:(BOOL)authorized {
    BJLError *error = [self.room.recordingVM updateStudentExtraCameraAuthorized:authorized userNumber:self.user.number];
    [self throwError:error];
    return !error;
}

- (BOOL)updateScreenShareAuthorizedForCurrentUser:(BOOL)authorized {
    BJLError *error = [self.room.recordingVM updateStudentScreenShareAuthorized:authorized userNumber:self.user.number];
    [self throwError:error];
    return !error;
}

- (void)sendLikeForCurrentUser {
    if (!self.room.roomVM.liveStarted) {
        return;
    }
    
    // !!!: [BJLAward allAwards]里面至少有一个, 当大于1的时候, 把图标换成钻石, 点击显示多种奖励
    if ([BJLAward allAwards].count > 1) {
        
        BJLMutableAwardsView *mutableAwardsView = [[BJLMutableAwardsView alloc] initWithRoom:self.room user:self.user];
        self.awardsViewController = ({
            UIViewController *viewController = [[UIViewController alloc] init];
            viewController.view.backgroundColor = [UIColor clearColor];
            viewController.modalPresentationStyle = UIModalPresentationPopover;
            viewController.preferredContentSize = mutableAwardsView.size;
            viewController.popoverPresentationController.backgroundColor = BJLIcTheme.toolboxBackgroundColor;
            viewController.popoverPresentationController.delegate = self;
            viewController.popoverPresentationController.sourceView = self;
            viewController.popoverPresentationController.sourceRect = CGRectMake(self.likeButton.center.x, self.likeButton.center.y, 1.0, 1.0);
            viewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
            viewController;
        });
        
        [self.awardsViewController.view addSubview:mutableAwardsView];
        [mutableAwardsView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.awardsViewController.view.bjl_safeAreaLayoutGuide ?: self.awardsViewController.view);
        }];
        
        bjl_weakify(self);
        [mutableAwardsView setAwardKeyCallback:^(NSString * _Nonnull key) {
            bjl_strongify(self);
            BJLError *error = [self.room.roomVM sendLikeForUserNumber:self.user.number key:key];
            [self throwError:error];
            [self hideAwardsViewController];
        }];
        
        [self.parentViewController presentViewController:self.awardsViewController animated:YES completion:nil];
        
    }
    else {
        BJLError *error = [self.room.roomVM sendLikeForUserNumber:self.user.number];
        [self throwError:error];
    }
}

- (BOOL)blockCurrentUser {
    if (self.blockUserCallback) {
       return self.blockUserCallback(self.user);
    }
    return NO;
}

- (void)hideOptionViewController {
    [self.optionViewController bjl_dismissAnimated:YES completion:nil];
}

- (void)hideAwardsViewController {
    [self.awardsViewController bjl_dismissAnimated:YES completion:nil];
}

- (void)showSpeakRequestControlView {
    self.speakRequestButton.hidden = YES;
    self.speakRequestControlView.hidden = NO;
}

- (void)allowSpeakRequest {
    [self.room.speakingRequestVM replySpeakingRequestToUserID:self.user.ID allowed:YES];
    self.speakRequestControlView.hidden = YES;
}

- (void)refuseSpeakRequest {
    [self.room.speakingRequestVM replySpeakingRequestToUserID:self.user.ID allowed:NO];
    self.speakRequestControlView.hidden = YES;
}

#pragma mark - wheel

- (BOOL)isVideoPlayingUser {
    for (BJLMediaUser *user in [self.room.playingVM.videoPlayingUsers copy]) {
        if ([user isSameMediaUser:self.user]) {
            return YES;
        }
    }
    return NO;
}

- (void)updateCurrentUser {
    BJLMediaUser *oldUser = self.user;
    BJLMediaUser *newUser = [self.room.playingVM playingUserWithID:oldUser.ID number:oldUser.number mediaSource:oldUser.mediaSource];
    if (newUser) {
        self.user = newUser;
    }
    
    if (self.animating
        && (!newUser
            || ![self.room.playingVM.videoPlayingUsers containsObject:newUser])) {
        // 不再播放对方视频, 停止 loading 动画
        [self updateLoadingViewHidden:YES];
    }
}

// loss rate 0 - 100
- (UIImage *)imageWithLossRate:(CGFloat)rate {
    UIImage *image;
    if (rate <= 1.0) {
        image = [UIImage bjlic_imageNamed:@"bjl_ic_signal_level_3"];
    }
    else if (rate > 1.0 && rate <= 10.0) {
        image = [UIImage bjlic_imageNamed:@"bjl_ic_signal_level_2"];
    }
    else {
        image = [UIImage bjlic_imageNamed:@"bjl_ic_signal_level_1"];
    }
    return image;
}

// 未回调音量或者初始化时设置音量图片的方法
- (UIImage *)imageWithUserAudioState {
    UIImage *image = self.user.audioOn ? [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_0"] : [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_off"];
    if (self.user.audioState == BJLUserMediaState_unavailable) {
        image = [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_unavailable"];
    }
    return image;
}

// volume 0 - 255
- (UIImage *)imageWithAudioVolume:(CGFloat)volume {
    UIImage *image;
    if (volume <= 5) {
        image = [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_0"];
    }
    else if (volume > 5 && volume <= 20) {
        image = [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_1"];
    }
    else if (volume > 20 && volume <= 60) {
        image = [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_2"];
    }
    else {
        image = [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_3"];
    }
    return image;
}

- (NSArray *)strokeColors {
    return @[@"#F44336", @"#E91E63", @"#D500F9", @"#3D5AFE",
             @"#03A9F4", @"#00BCD4", @"#4CAF50", @"#8BC34A",
             @"#FFEB3B", @"#FFC107", @"#FF9800", @"#FF5722",
             @"#795548", @"#212121", @"#9E9E9E", @"#FFFFFF"];
}

- (void)throwError:(nullable NSError *)error {
    if (error && self.showErrorMessageCallback) {
        NSString *message = error.localizedFailureReason ?: error.localizedDescription;
        self.showErrorMessageCallback(message);
    }
}

- (UIImageView *)imageViewWithName:(NSString *)imageName {
    UIImage *image = [UIImage bjlic_imageNamed:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    return imageView;
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

#pragma mark - video loading

// 用户视频加载占位图
- (void)updateLoadingViewHidden:(BOOL)hidden {
    if (!self.videoLoadingView) {
        return;
    }
    if (self.videoLoadingView.hidden == hidden) {
        return;
    }
    self.videoLoadingView.hidden = hidden;
    if (hidden) {
        self.animating = NO;
        self.needStopAnimation = YES;
        [self stopLoadingAnimation];
    }
    else {
        if (self.animating || !self.needStopAnimation) {
            return;
        }
        self.needStopAnimation = NO;
        bjl_weakify(self);
        [self startLoadingAnimationWithAngle:0 completion:^{
            bjl_strongify(self);
            if (!self.needStopAnimation) {
                self.animating = YES;
            }
        }];
    }
}

- (void)startLoadingAnimationWithAngle:(NSInteger)angle completion:(void (^ __nullable)(void))completion {
    NSInteger nextAngle = angle + 20;
    if (nextAngle > 360) {
        nextAngle = 0;
    }
    CGAffineTransform endAngle = CGAffineTransformMakeRotation(angle * (M_PI / 180.0f));
    // 预期不会出现顺序调用，后调用的先回调 completion
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.videoLoadingImageView.transform = endAngle;
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
        if (self.animating && finished) {
            [self startLoadingAnimationWithAngle:nextAngle completion:nil];
        }
        else {
            [self stopLoadingAnimation];
        }
    }];
}

- (void)stopLoadingAnimation {
    self.videoLoadingView.hidden = YES;
    [self.videoLoadingView.layer removeAllAnimations];
    [self.videoLoadingImageView.layer removeAllAnimations];
    self.videoLoadingImageView.transform = CGAffineTransformIdentity;
}

#pragma mark - weak network

- (NSString *)userLossRateKeyWithUserID:(NSString *)userID mediaSource:(BJLMediaSource)mediaSource {
    return [NSString stringWithFormat:@"%@-%td", userID, mediaSource];
}

- (BJLMediaSource)mediaSourceForUserLossRateKey:(NSString *)key {
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

        NSString *userKey = [self userLossRateKeyWithUserID:self.room.loginUser.ID mediaSource:BJLMediaSource_mainCamera];
        NSMutableArray<NSDictionary *> *loginUserLossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
        NSInteger loginUserLossRateArrayCount = [loginUserLossRateArray count];
        CGFloat loginUserLossRate = 0.0f;
        if(loginUserLossRateArrayCount) {
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
            [self.lossRateDictionary bjl_setObject:loginUserLossRateArray forKey:userKey];
        }
        BJLNetworkStatus loginUserLossRateStatus = [self netWorkStatusWithLossRate:loginUserLossRate];
        
        BOOL isloginUser = [self.user.ID isEqualToString:self.room.loginUser.ID];
        CGFloat currentUserLossRate = 0;
        BJLNetworkStatus currentUserLossRateStatus = BJLNetworkStatus_normal;
        if(!isloginUser) {
            // 当前窗口下行的丢包率
            userKey = [self userLossRateKeyWithUserID:self.user.ID mediaSource:self.user.mediaSource];
            NSMutableArray<NSDictionary *> *currentUserLossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
            NSInteger currentUserLossRateArrayCount = [currentUserLossRateArray count];
            if(currentUserLossRateArrayCount) {
                CGFloat totalLossRate = 0.0;
                for (NSDictionary<NSNumber *, NSNumber *> *lossRateDic in [currentUserLossRateArray copy]) {
                    // 读取用户丢包率数据中的时间，去掉 lossRateObservingTimeInterval 之外的时间
                    for (NSNumber *timeInterval in [lossRateDic.allKeys copy]) {
                        if (nowTimeInterval - [timeInterval bjl_doubleValue] > self.room.featureConfig.lossRateRetainTime) {
                            // 大于 lossRateRetainTime 的数据移除
                            [currentUserLossRateArray removeObject:lossRateDic];
                        }
                        else {
                            // 否则加入计算
                            totalLossRate += [lossRateDic bjl_floatForKey:timeInterval];
                        }
                    }
                }
                currentUserLossRate = (currentUserLossRateArray.count > 0) ? totalLossRate / currentUserLossRateArray.count : 0.0f;
                // 更新丢包率的字典
                [self.lossRateDictionary bjl_setObject:currentUserLossRateArray forKey:userKey];
            }
        }
        else {
            currentUserLossRate = loginUserLossRate;
        }
        currentUserLossRateStatus = [self netWorkStatusWithLossRate:currentUserLossRate];
        
        // 自己是否有上行
        BOOL hasUpPackage = self.room.recordingVM.recordingVideo || self.room.recordingVM.recordingAudio;
        // 自己上行是否丢包
        BOOL hasUpPackageLoss = hasUpPackage && loginUserLossRateStatus != BJLNetworkStatus_normal;
        BOOL shouldLoginUserShowWeakNetWork = hasUpPackageLoss;
        // 如果当前窗口为登录用户
        if(isloginUser) {
            for (NSString *userKey in [self.lossRateDictionary.allKeys copy]) {
                NSString *userID = [self userIDForUserLossRateKey:userKey];
//                BJLMediaSource mediaSourcce = [self mediaSourceForUserLossRateKey:userKey];
                // 读取每个用户的丢包率数据 ,除了当前登录用户和当前窗口用户
                if([userID isEqualToString:self.room.loginUser.ID]) {
                    continue;
                }

                NSMutableArray<NSDictionary *> *lossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
                NSInteger count = lossRateArray.count;

                if (count > 0) {
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

                    // (下行丢包&&自己无上行推流) || (自己的视频窗口有丢包&&下行窗口低于上行两倍)
                    if((status != BJLNetworkStatus_normal && !hasUpPackage)
                       || (hasUpPackageLoss && lossRate <= loginUserLossRate * 2 && status != BJLNetworkStatus_normal)) {
                        // 自己窗口展示弱网
                        shouldLoginUserShowWeakNetWork = YES;
                        loginUserLossRateStatus = hasUpPackageLoss ? loginUserLossRateStatus : status;
                        break;
                    }
                }
            }
        }
#if DEBUG

        if(isloginUser) {
            [self showLossRateLabel:[NSString stringWithFormat:@"%.1f", loginUserLossRate]];
        }
        else {
            [self showLossRateLabel:[NSString stringWithFormat:@"%.1f/%.1f", currentUserLossRate, loginUserLossRate]];
        }
#endif
        if(isloginUser && shouldLoginUserShowWeakNetWork) {
            [self updateNetWorkStatus:loginUserLossRateStatus];
        }
        else if(!isloginUser) {
            // (非自己视频窗口有丢包 && 自己有上行无丢包) || (上下行均丢包&&当前窗口下行高于上行两倍)
            if(BJLNetworkStatus_normal != currentUserLossRateStatus
               && ((BJLNetworkStatus_normal == loginUserLossRateStatus && hasUpPackage)
                   || (BJLNetworkStatus_normal != loginUserLossRateStatus && currentUserLossRate > loginUserLossRate * 2))) {
                [self updateNetWorkStatus:currentUserLossRateStatus];
            }
        }
    }];
}

- (void)stopLossRateObservingTimer {
    if (self.lossRateObservingTimer || [self.lossRateObservingTimer isValid]) {
        [self.lossRateObservingTimer invalidate];
        self.lossRateObservingTimer = nil;
    }
}

- (void)updateNetWorkStatus:(BJLNetworkStatus)status {
    if(self.isNetworkMessageShowing || self.user.mediaSource != BJLMediaSource_mainCamera)
        return;
    
    BOOL show = status != BJLNetworkStatus_normal;
    
    [self.networkMessageLabel setHidden:!show];
    if(!show) {
        [self.signalLevelView setImage:[UIImage bjlic_imageNamed:@"bjl_ic_signal_level_3"]];
        return;
    }
    
    BOOL highlighted = BJLNetworkStatus_Bad_level3 == status || BJLNetworkStatus_Bad_level4 == status || BJLNetworkStatus_Bad_level5 == status;
    NSString *message = (BJLNetworkStatus_Bad_level1 == status) ? @"网络较差" : ((BJLNetworkStatus_Bad_level2 == status) ? @"网络差" : @"网络极差");
    
    [self.networkMessageLabel setText:message];
    if(highlighted) {
        [self.networkMessageLabel setTextColor:[UIColor bjl_ic_extremelyBadNetColor]];
        [self.signalLevelView setImage:[UIImage bjlic_imageNamed:@"bjl_ic_signal_level_extremelyBad"]];
    }
    else {
        [self.networkMessageLabel setTextColor:[UIColor bjl_ic_quiteBadNetColor]];
        [self.signalLevelView setImage:[UIImage bjlic_imageNamed:@"bjl_ic_signal_level_quiteBad"]];
    }
    
    if(show) {
        self.isNetworkMessageShowing = YES;
        if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
            [self.networkMessageLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.right.equalTo(self.bjl_right).offset(- 5.0);
                make.bottom.equalTo(self.bjl_bottom).offset(- 2.0);
                make.left.greaterThanOrEqualTo(self.bjl_left);
            }];
        }
        else {
            [self.networkMessageLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.right.equalTo(self.bjl_right).offset(- 5.0);
                make.bottom.equalTo(self.userNameLabel.bjl_top).offset(- 5.0);
                make.left.greaterThanOrEqualTo(self.bjl_left);
            }];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.networkMessageLabel setHidden:YES];
            [self.signalLevelView setImage:[UIImage bjlic_imageNamed:@"bjl_ic_signal_level_3"]];
            self.isNetworkMessageShowing = NO;
        });
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

#if DEBUG
- (void)showLossRateLabel:(NSString *)text {
    self.lossRateLabel.text = text;
    [self.lossRateLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.bjl_left).offset(5.0);
        make.right.equalTo(self.bjl_right).offset(-5.0);
        make.bottom.equalTo(self.bjl_bottom).offset(- 25.0);
    }];
}
#endif

@end

NS_ASSUME_NONNULL_END
