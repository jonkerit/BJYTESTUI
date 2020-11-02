//
//  BJLIcUserVideoListViewController.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/28.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLIcUserVideoListViewController.h"
#import "BJLIcUserVideoListViewController+private.h"
#import "BJLIcUserVideoListViewController+padUserVideoUpside.h"
#import "BJLIcUserVideoListViewController+pad1to1.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcUserVideoListViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self->_room = room;
        self.active = NO;
        self.autoPlayVideoBlacklist = [NSMutableSet set];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    [self makeSubviews];
    [self makeObserving];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 画廊布局切换到板书布局，如果画廊布局打开了的视频，在板书布局可能要更具配置了是否只看老师的情况来关闭，因此更新一下视图的状态。这样的表现是不实现白名单情况的逻辑
    [self updateCurrentUserMediaInfoViews];
    [self reloadCollectionView];
}

- (void)dealloc {
    self.videoCollectionView.dataSource = nil;
    self.videoCollectionView.delegate = nil;
}

#pragma mark - subviews

- (void)makeSubviews {
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        [self makePad1to1Subviews];
    }
    else {
        [self makePadUserVideoUpsideSubviews];
    }
}

#pragma mark - observers

- (void)makeObserving {
    bjl_weakify(self);
    
    // 视频播放
    self.room.playingVM.autoPlayVideoBlock = ^BJLAutoPlayVideo(BJLMediaUser *user, NSInteger cachedDefinitionIndex) {
        bjl_strongify(self);
        BOOL autoPlay = [self playVideoWithMediaInfoView:[self mediaInfoViewWithMediaUser:user mediaID:nil] mediaUser:user];
        NSInteger definitionIndex = cachedDefinitionIndex;
        if (autoPlay) {
            NSInteger maxDefinitionIndex = MAX(0, (NSInteger)user.definitions.count - 1);
            definitionIndex = (cachedDefinitionIndex <= maxDefinitionIndex
                               ? cachedDefinitionIndex : maxDefinitionIndex);
        }
        return BJLAutoPlayVideoMake(autoPlay, definitionIndex);
    };
    
    // 更新列表的数据，playingUsers 个数决定显示的窗口数，extraPlayingUsers 的数据决定显示是否要更新内容
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.playingVM, playingUsers),
                         BJLMakeProperty(self.room.playingVM, extraPlayingUsers)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateVideoUsersWithMainAndExtraPlayingUsers];
    }];
    
    // 用户退出或者下台时移除窗口
    [self bjl_observeMerge:@[BJLMakeMethod(self.room.playingVM, didRemoveActiveUser:),
                             BJLMakeMethod(self.room.onlineUsersVM, onlineUserDidExit:)]
                  observer:^(BJLUser *user) {
        bjl_strongify(self);
        // 用户下台、退出教室，清理所有的 mediaInfoView
        for (BJLIcUserMediaInfoView *mediaInfoView in [self.userMediaInfoViews copy]) {
            if ([user containsMediaWithID:mediaInfoView.user.mediaID]) {
                [self.userMediaInfoViews bjl_removeObject:mediaInfoView];
                [mediaInfoView removeFromSuperview];
                [mediaInfoView destroy];
            }
        }
        
        [self updateCurrentUserMediaInfoViews];
        if (self.userMediaInfoViewsDidUpdateCallback) {
            self.userMediaInfoViewsDidUpdateCallback(self.userMediaInfoViews);
        }
    }];
    
    // 只看老师和自己
    [self bjl_kvo:BJLMakeProperty(self.room.playingVM, disableAutoPlayVideoExceptTeacherAndAssistant)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateCurrentUserMediaInfoViews];
        if (self.userMediaInfoViewsDidUpdateCallback) {
            self.userMediaInfoViewsDidUpdateCallback(self.userMediaInfoViews);
        }
        [self reloadCollectionView];
        return YES;
    }];
    
    // 收到个人点赞
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveLikeForUserNumber:records:)
             observer:^BOOL(NSString *userNumber, NSDictionary<NSString *, NSNumber *> *records) {
        bjl_strongify(self);
        BJLIcUserMediaInfoView *mediaInfoView = [self mediaInfoViewWithUserNumber:userNumber];
        // 给台上用户点赞
        if (mediaInfoView) {
            [mediaInfoView updateLikeCount];
            if (self.receiveLikeCallback) {
                self.receiveLikeCallback(mediaInfoView.user, mediaInfoView.likeButton);
            }
        }
        else {
            // 给台下用户点赞
            for (BJLUser *user in self.room.onlineUsersVM.onlineUsers) {
                if ([user.number isEqualToString:userNumber]) {
                    if (self.receiveLikeCallback) {
                        self.receiveLikeCallback(user, mediaInfoView.likeButton);
                    }
                    break;
                }
            }
        }
        return YES;
    }];
    
    // 课件授权
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM, authorizedPPTUserNumbers)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        for (BJLIcUserMediaInfoView *mediaInfoView in [self.userMediaInfoViews copy]) {
            BOOL authorizedPPT = [self.room.documentVM.authorizedPPTUserNumbers containsObject:mediaInfoView.user.number];
            [mediaInfoView updateWebPPTAuthorized:authorizedPPT];
        }
        return YES;
    }];
    
    // 画笔授权
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, drawingGrantedUserNumbers)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        for (BJLIcUserMediaInfoView *mediaInfoView in [self.userMediaInfoViews copy]) {
            BOOL drawingGranted = [self.room.drawingVM.drawingGrantedUserNumbers containsObject:mediaInfoView.user.number];
            [mediaInfoView updateDrawingGranted:drawingGranted];
        }
        return YES;
    }];
    
    // 收到举手显示
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, didReceiveSpeakingRequestFromUser:)
             observer:^BOOL(BJLUser *user) {
        bjl_strongify(self);
        BJLIcUserMediaInfoView *mediaInfoView = [self mediaInfoViewWithMediaUser:nil mediaID:user.ID];
        [mediaInfoView updateSpeakRequestViewHidden:NO];
        return YES;
    }];
    
    // 举手被处理
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, speakingRequestDidReplyEnabled:isUserCancelled:user:)
             observer:(BJLMethodObserver)^BOOL(BOOL speakingEnabled, BOOL isUserCancelled, BJLUser *user) {
        bjl_strongify(self);
        BJLIcUserMediaInfoView *mediaInfoView = [self mediaInfoViewWithMediaUser:nil mediaID:user.ID];
        [mediaInfoView updateSpeakRequestViewHidden:YES];
        return YES;
    }];
    
    /**
     退出教室时，如果教室内方向和教室外方向不同，会触发 UICollectionView 的 layoutSubviews 方法，
     推测因为 UICollectionView 检测视图的数据时，有无法匹配的 rect 等情况，导致教室卡住，
     因此在教室将要退出时，置空数据源和代理
     */
    [self bjl_observe:BJLMakeMethod(self.room, roomWillExitWithError:)
             observer:^BOOL{
        bjl_strongify(self);
        self.videoCollectionView.delegate = nil;
        self.videoCollectionView.dataSource = nil;
        return YES;
    }];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger count = 0;
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        count = [self pad1to1CollectionView:collectionView numberOfItemsInSection:section];
    }
    else {
        count = [self padUserVideoUpsideCollectionView:collectionView numberOfItemsInSection:section];
    }
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLIcUserSeatCell *cell = nil;
    // 用户音视频信息视图，不能通过 cell 重用，需要单独处理
    BJLIcUserMediaInfoView *mediaInfoView = nil;
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifierFor1to1 forIndexPath:indexPath];
        mediaInfoView = [self pad1to1MediaInfoViewWithIndex:indexPath.row];
    }
    else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifier forIndexPath:indexPath];
        mediaInfoView = [self padUserVideoUpsideMediaInfoViewWithIndex:indexPath.row];
    }
    
    // 未获取到用户的时候显示为座位
    if (!mediaInfoView) {
        [cell updateContentWithUser:nil leavSeat:YES isTeacher:(indexPath.row == 0)];
        return cell;
    }
    
    BOOL leaveSeat = mediaInfoView.position != BJLIcVideoPosition_videoList;
    [cell updateContentWithUser:mediaInfoView.user leavSeat:leaveSeat isTeacher:(indexPath.row == 0)];
    
    // 切换大小流时仅处理未离开座位的用户的视频，防止因为在拖动过程中刷新视图而将拖动中的视图切换成了高清晰度的视频
    if (BJLIcTemplateType_1v1 != self.room.roomInfo.interactiveClassTemplateType
        && !leaveSeat) {
        [self.room.playingVM switchVideoDefinitionWithUser:mediaInfoView.user useLowDefinition:YES];
    }
    // 如果视图应该在座位列表上，将视图添加到 cell 上
    if (!leaveSeat) {
        [mediaInfoView removeFromSuperview];
        [cell.mediaInfoContainerView addSubview:mediaInfoView];
        [mediaInfoView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(cell.mediaInfoContainerView);
        }];
    }
    [mediaInfoView updateContentWithUser:mediaInfoView.user combineVideoView:!leaveSeat];
    [mediaInfoView updateParentViewController:self];
    [mediaInfoView updateInfoGroupViewWithReferenceView:cell];
    
    // 只有老师才可以收回学生视频窗口
    if (self.room.loginUser.isTeacher) {
        bjl_weakify(self);
        [cell setSingleTapCallback:^{
            bjl_strongify(self);
            if (leaveSeat) {                
                if (self.sendBackVideoViewCallback) {
                    self.sendBackVideoViewCallback(mediaInfoView.user);
                }
                [self reloadCollectionView];
            }
        }];
    }
    
    return cell;
}

#pragma mark - <UICollectionViewDelegateFlowlayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self itemSize];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewFlowLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    CGSize itemSize = [self itemSize];
    NSInteger numberOfItems = [self.videoCollectionView numberOfItemsInSection:0];
    if (numberOfItems <= 0) {
        return UIEdgeInsetsZero;
    }
    CGFloat combinedItemWidth = (numberOfItems * itemSize.width) + ((numberOfItems - 1) * itemSpacing);
    CGFloat padding = (collectionView.bounds.size.width - combinedItemWidth) / 2;
    padding = padding > 0.0 ? padding : 0.0;
    CGFloat screenScale = [UIScreen mainScreen].scale;
    padding = floor(padding * screenScale) / screenScale;
    return UIEdgeInsetsMake(0.0, padding, 0.0, padding);
}

- (CGSize)itemSize {
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        return [self pad1to1ItemSize];
    }
    else {
        return [self padUserVideoUpsideItemSize];
    }
}

#pragma mark - public

- (void)updateActive:(BOOL)active {
    self.active = active;
    if (active) {
        for (BJLIcUserMediaInfoView *view in [self.userMediaInfoViews copy]) {
            [view restorePositon];
        }
        [self reloadCollectionView];
    }
}

- (nullable BJLIcUserMediaInfoView *)mediaInfoViewWithPanGesture:(UIPanGestureRecognizer *)panGesture {
    for (BJLIcUserSeatCell *cell in self.videoCollectionView.visibleCells) {
        CGPoint location = [panGesture locationInView:cell];
        if ([cell pointInside:location withEvent:nil]) {
            NSInteger index = [self.videoCollectionView indexPathForCell:cell].row;
            BJLIcUserMediaInfoView *mediaInfoView = [self mediaInfoViewWithIndex:index forDisplay:NO];
            if (mediaInfoView.position != BJLIcVideoPosition_blackboard) {
                mediaInfoView.position = BJLIcVideoPosition_blackboard;
                [self reloadCollectionView];
                return mediaInfoView;
            }
            else {
                return nil;
            }
        }
    }
    return nil;
}

- (nullable BJLIcUserMediaInfoView *)setUserLeaveSeatWithMediaID:(NSString *)mediaID {
    BJLIcUserMediaInfoView *mediaInfoView = [self mediaInfoViewWithMediaUser:nil mediaID:mediaID];
    if (!mediaInfoView) {
        return  nil;
    }
    mediaInfoView.position = BJLIcVideoPosition_blackboard;
    [self reloadCollectionView];
    return mediaInfoView;
}

- (nullable BJLIcUserMediaInfoView *)sendUserBackToSeatWithMediaID:(NSString *)mediaID {
    BJLIcUserMediaInfoView *mediaInfoView = [self mediaInfoViewWithMediaUser:nil mediaID:mediaID];
    if (!mediaInfoView) {
        return nil;
    }
    mediaInfoView.position = BJLIcVideoPosition_videoList;
    [self reloadCollectionView];
    return mediaInfoView;
}

#pragma mark - getters

- (NSMutableArray<BJLMediaUser *> *)videoUsers {
    if (!_videoUsers) {
        _videoUsers = [NSMutableArray array];
    }
    return _videoUsers;
}

- (NSMutableArray<BJLIcUserMediaInfoView *> *)userMediaInfoViews {
    if (!_userMediaInfoViews) {
        _userMediaInfoViews = [NSMutableArray array];
    }
    return _userMediaInfoViews;
}

#pragma mark - update data

- (void)updateVideoUsersWithMainAndExtraPlayingUsers {
    // 下麦用户的 mediaInfoView 主动 destroy TODO:不使用 CollectionView 来彻底解决复用持有导致的不会自动 dealloc 的情况
    NSMutableArray <BJLMediaUser *> *preVideoUsers = [self.videoUsers copy];
    NSArray<BJLMediaUser *> *currentVideoUsers = [self.room.playingVM.playingUsers copy];
    for (BJLMediaUser *user in preVideoUsers) {
        BJLIcUserMediaInfoView *mediaInfoView = [self mediaInfoViewWithMediaUser:user mediaID:nil];
        // 避免将改变了音视频状态，但是仍在播放播放列表的用户移除
        if (![self mediaUserWithMediaInfoView:mediaInfoView users:currentVideoUsers]) {
            [self.userMediaInfoViews bjl_removeObject:mediaInfoView];
            [mediaInfoView removeFromSuperview];
            [mediaInfoView destroy];
        }
    }

    // 视频列表仅显示主摄像头的用户
    self.videoUsers = [self.room.playingVM.playingUsers mutableCopy];
    NSMutableArray<BJLIcUserMediaInfoView *> *userMediaInfoViews = [NSMutableArray array];

    // 更新 playinguser 对应的 mediaInfoView
    for (BJLMediaUser *user in [self.videoUsers copy]) {
        BJLIcUserMediaInfoView *mediaInfoView = [self mediaInfoViewWithMediaUser:user mediaID:nil];
        // 如果未找到，创建新的 view
        if (!mediaInfoView) {
            mediaInfoView = [[BJLIcUserMediaInfoView alloc] initWithUser:user room:self.room];
            mediaInfoView.position = self.active ? BJLIcVideoPosition_videoList : BJLIcVideoPosition_gallary;
            // 设置回调
            bjl_weakify(self, mediaInfoView);
            [mediaInfoView setShowErrorMessageCallback:^(NSString * _Nonnull message) {
                bjl_strongify(self);
                if (self.showErrorMessageCallback) {
                    self.showErrorMessageCallback(message);
                }
            }];
            [mediaInfoView setUpdateVideoCallback:^(BJLMediaUser * _Nonnull user, BOOL on) {
                bjl_strongify(self);
                [self updateAutoPlayVideoBlacklist:user add:!on];
            }];
            [mediaInfoView setBlockUserCallback:^BOOL(BJLUser * _Nonnull user) {
                bjl_strongify(self);
                if (self.blockUserCallback) {
                    return self.blockUserCallback(user);
                }
                return NO;
            }];
            [mediaInfoView setUpdatePositionCallback:^(BJLIcVideoPosition position) {
                bjl_strongify(self, mediaInfoView);
                [mediaInfoView updatePlayVideo:[self playVideoWithMediaInfoView:mediaInfoView mediaUser:nil]];
            }];
        }
        // 更新视图的 user 数据
        [mediaInfoView updateContentWithUser:user combineVideoView:YES];
        [userMediaInfoViews bjl_addObject:mediaInfoView];
    }
    self.userMediaInfoViews = userMediaInfoViews;
    
    // 按需更新窗口对应的 user 数据，目前老师所有媒体类型单独对应一个窗口，学生根据主摄像头和辅助摄像头对应二个窗口
    for (BJLMediaUser *user in [self.room.playingVM.extraPlayingUsers copy]) {
        [self updateVideoUserWithMediaUser:user];
    }
    
    // 回调
    [self updateCurrentUserMediaInfoViews];
    if (self.userMediaInfoViewsDidUpdateCallback) {
        self.userMediaInfoViewsDidUpdateCallback(self.userMediaInfoViews);
    }
    [self reloadCollectionView];
}

// 目前视频列表仅保持相机类型为主摄像头的用户数据，不处理辅助摄像头的数据，对于主讲，仅包含主摄像头的媒体类型，对于学生，还包括主屏幕共享和播放文件的媒体类型 业务调整:助教的媒体文件也使用新的媒体流，不替换主摄像头
- (BOOL)updateVideoUserWithMediaUser:(BJLMediaUser *)mediaUser {
    BOOL isPresenter = [mediaUser isSameUser:self.room.onlineUsersVM.currentPresenter];
    BOOL isAssistantPlayMedia = mediaUser.isTeacherOrAssistant && mediaUser.mediaSource == BJLMediaSource_mediaFile;
    if (isPresenter || isAssistantPlayMedia) {
        return NO;
    }
    BJLIcUserMediaInfoView *mediaInfoView = [self mediaInfoViewWithMediaUser:mediaUser mediaID:nil];
    if (!mediaInfoView) {
        return NO;
    }
    // 在此处更新非老师用户的用户数据，用于刷新列表
    BOOL replace = NO;
    for (NSUInteger index = 0; index < self.videoUsers.count; index++) {
        BJLMediaUser *user = [self.videoUsers bjl_objectAtIndex:index];
        if ([user isSameUser:mediaUser]) {
            replace = user.mediaSource != mediaUser.mediaSource;
            [self.videoUsers bjl_replaceObjectAtIndex:index withObject:mediaUser];
            break;
        }
    }
    // 如果发生了媒体类型的变更，更新视图内的播放画面
    if (replace) {
        [mediaInfoView updateContentWithUser:mediaUser combineVideoView:YES];
    }
    return replace;
}

- (void)updateCurrentUserMediaInfoViews {
    // 老师和助教将一直看到所有视图
    if (self.room.loginUser.isTeacherOrAssistant) {
        self.currentUserMediaInfoViews = self.userMediaInfoViews;
        return;
    }
    NSMutableArray *currentUserMediaInfoViews = [NSMutableArray array];
    for (BJLIcUserMediaInfoView *view in [self.userMediaInfoViews copy]) {
        // 老师和助教视图一直显示
        if (view.user.isTeacherOrAssistant) {
            [currentUserMediaInfoViews bjl_addObject:view];
        }
        // 登录用户一直显示，是否播放根据是否开摄像头决定，此处传的参数无效
        else if ([view.user isSameUser:self.room.loginUser]) {
            [currentUserMediaInfoViews bjl_addObject:view];
        }
        // 除自己和老师助教外的其他用户
        else {
            // 如果教室和后台都未配置只看老师和自己，显示视图
            if (!self.room.playingVM.disableAutoPlayVideoExceptTeacherAndAssistant
                && !self.room.featureConfig.enablePullAudioOnly) {
                [currentUserMediaInfoViews bjl_addObject:view];
            }
            // 如果后台配置了只看老师和自己，教室内未配置，显示视图
            else if (self.room.featureConfig.enablePullAudioOnly
                     && !self.room.playingVM.disableAutoPlayVideoExceptTeacherAndAssistant) {
                [currentUserMediaInfoViews bjl_addObject:view];
            }
        }
        // 更新播放状态
        BOOL playVideo = [self playVideoWithMediaInfoView:view mediaUser:nil];
        [view updatePlayVideo:playVideo];
    }
    self.currentUserMediaInfoViews = currentUserMediaInfoViews;
}

- (BOOL)playVideoWithMediaInfoView:(nullable BJLIcUserMediaInfoView *)mediaInfoView mediaUser:(nullable BJLMediaUser *)user {
    BJLMediaUser *mediaUser = mediaInfoView.user ?: user;
    if (!mediaUser) {
        return NO;
    }
    // 是否在不需要播放的黑名单里
    BOOL playVideo = ![self.autoPlayVideoBlacklist containsObject:[self videoListRetainKeyForUser:mediaUser]];
    // 老师和助教播放他人的视频直接根据黑名单决定
    if (self.room.loginUser.isTeacherOrAssistant) {
        return playVideo;
    }
    // 播放老师和助教是否播放根据黑名单决定
    if (mediaUser.isTeacherOrAssistant) {
        return playVideo;
    }
    // 登录用户是否播放根据是否开摄像头决定，此处传的参数无效
    if ([mediaUser isSameUser:self.room.loginUser]) {
        return YES;
    }
    // 如果教室或者后台配置只看老师和自己
    if (self.room.playingVM.disableAutoPlayVideoExceptTeacherAndAssistant
        || self.room.featureConfig.enablePullAudioOnly) {
        // 如果在非黑板区域不播放
        if (mediaInfoView
            && mediaInfoView.position != BJLIcVideoPosition_blackboard) {
            playVideo = NO;
        }
        // 在黑板区域根据黑名单决定
    }
    // 未配置只看老师和自己，根据黑名单决定
    return playVideo;
}

- (void)reloadCollectionView {
    if (!self || !self.isViewLoaded || !self.active) {
        return;
    }
    [self.videoCollectionView reloadData];
}

- (void)updateAutoPlayVideoBlacklist:(BJLMediaUser *)user add:(BOOL)add {
    NSString *retainKey = [self videoListRetainKeyForUser:user];
    if (add) {
        [self.autoPlayVideoBlacklist addObject:retainKey];
    }
    else {
        [self.autoPlayVideoBlacklist removeObject:retainKey];
    }
}

- (NSString *)videoListRetainKeyForUser:(BJLMediaUser *)user {
    return [NSString stringWithFormat:@"%@-%td", user.number, user.mediaSource];
}

#pragma mark - wheel

- (nullable BJLIcUserMediaInfoView *)mediaInfoViewWithMediaUser:(nullable BJLMediaUser *)mediaUser mediaID:(nullable NSString *)mediaID {
    for (BJLIcUserMediaInfoView *mediaInfoView in [self.userMediaInfoViews reverseObjectEnumerator]) {
        if ([mediaInfoView isTargetMediaInfoViewWithMediaUser:mediaUser mediaID:mediaID]) {
            return mediaInfoView;
        }
    }
    return nil;
}

- (nullable BJLMediaUser *)mediaUserWithMediaInfoView:(nullable BJLIcUserMediaInfoView *)mediaInfoView users:(NSArray<BJLMediaUser *> *)users {
    if (!mediaInfoView || !users.count) {
        return nil;
    }
    for (BJLMediaUser *user in users) {
        if ([mediaInfoView isTargetMediaInfoViewWithMediaUser:user mediaID:nil]) {
            return user;
        }
    }
    return nil;
}

- (nullable BJLIcUserMediaInfoView *)mediaInfoViewWithUserNumber:(NSString *)userNumber {
    for (BJLIcUserMediaInfoView *mediaInfoView in [self.userMediaInfoViews copy]) {
        if ([mediaInfoView.user.number isEqualToString:userNumber]  ) {
            return mediaInfoView;
        }
    }
    return nil;
}

- (nullable BJLIcUserMediaInfoView *)mediaInfoViewWithIndex:(NSInteger)index forDisplay:(BOOL)forDisplay {
    BJLIcUserMediaInfoView *mediaInfoView = nil;
    if (forDisplay) {
        mediaInfoView = [self.currentUserMediaInfoViews bjl_objectAtIndex:index];
        return mediaInfoView;
    }
    mediaInfoView = [self.userMediaInfoViews bjl_objectAtIndex:index];
    return mediaInfoView;
}

@end

NS_ASSUME_NONNULL_END
