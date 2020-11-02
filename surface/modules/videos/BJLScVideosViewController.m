//
//  BJLScVideosViewController.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScVideosViewController.h"

typedef NS_ENUM(NSInteger, BJLScVideoSection) {
    BJLScVideoSection_PPT,
    BJLScVideoSection_recording,
    BJLScVideoSection_playing,
    _BJLScVideoSection_count
};

static NSString * const cellReuseIdentifier = @"userSeatCell";

@interface BJLScVideoCell : UICollectionViewCell

@end

@implementation BJLScVideoCell

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
}

@end

/** 视频列表管理除了 PPT 和老师 以外的所有视频，视频的具体位置根据每个视频自己的信息判断 */
@interface BJLScVideosViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic, nullable) BJLScMediaInfoView *recordingMediaInfoView; // 采集媒体视图
@property (nonatomic, nullable, weak) BJLScMediaInfoView *teacherExtraMediaInfoView; // 老师的辅助摄像头，目前如果存在，将不显示课件视图
@property (nonatomic) NSMutableArray<BJLMediaUser *> *videoUsers; // 除老师外的媒体用户，老师的视频显示在其他位置
@property (nonatomic) NSMutableDictionary<NSString *, BJLScMediaInfoView *> *mainUserMediaInfoViews; // key -> userID
@property (nonatomic) NSMutableDictionary<NSString *, BJLScMediaInfoView *> *extraUserMediaInfoViews; // key -> userID
@property (nonatomic) NSArray<BJLScMediaInfoView *> *currentMediaInfoViews;

/** 区分大屏视图和当前视频列表的状态的数据，如果还需要添加新的可以封装成 model */
@property (nonatomic, readwrite) NSInteger majorWindowIndex; // -1 表示当前无大屏视频
@property (nonatomic, nullable) BJLMediaUser *majorMediaUser; // 大屏区域的媒体用户，majorWindowIndex 为 -1 时为空，大屏为采集时视图为空
@property (nonatomic, nullable, weak, readwrite) BJLScMediaInfoView *majorMediaInfoView; // 大屏区域的媒体视图， majorWindowIndex 为 -1 时为空，可以为采集视图

@end

@implementation BJLScVideosViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super init]) {
        self.room = room;
        self.majorWindowIndex = -1;
        self.videoUsers = [NSMutableArray new];
        self.mainUserMediaInfoViews = [NSMutableDictionary new];
        self.extraUserMediaInfoViews = [NSMutableDictionary new];
        self.currentMediaInfoViews = [NSArray new];
        [self makeObserving];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self makeSubviewsAndConstraints];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadCollectionView];
}

#pragma mark - subview

- (void)makeSubviewsAndConstraints {
    self.view.backgroundColor = [UIColor bjl_colorWithHexString:@"#BDC6CF" alpha:1.0];
    self.collectionView = ({
        // layout: 不要设置 itemSize，触发 UICollectionViewDelegateFlowlayout
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = BJLScOnePixel;
        layout.minimumLineSpacing = BJLScOnePixel;
        layout.sectionInset = UIEdgeInsetsZero;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.accessibilityLabel = BJLKeypath(self, collectionView);
        collectionView.backgroundColor = [UIColor clearColor];
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.bounces = YES;
        collectionView.alwaysBounceHorizontal = YES;
        collectionView.pagingEnabled = NO;
        collectionView.scrollEnabled = YES;
        collectionView.dataSource = self;
        collectionView.delegate = self;
        if (@available(iOS 11.0, *)) {
            collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [collectionView registerClass:[BJLScVideoCell class] forCellWithReuseIdentifier:cellReuseIdentifier];
        collectionView;
    });
    [self.view addSubview:self.collectionView];
    [self.collectionView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
}

#pragma mark - observing

- (void)makeObserving {
    bjl_weakify(self);
    
    // 播放 TODO:删除 adaptervm 的使用
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.mainPlayingAdapterVM, playingUsers),
                         BJLMakeProperty(self.room.extraPlayingAdapterVM, playingUsers)]
              observer:(BJLPropertiesObserver)^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateVideoUsersWithMainAndExtraPlayingUsers];
        return YES;
    }];
    
    // 采集
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.recordingVM, recordingAudio),
                         BJLMakeProperty(self.room.recordingVM, recordingVideo)]
                filter:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        return [value bjl_boolValue] != [oldValue bjl_boolValue];
    }
              observer:(BJLPropertiesObserver)^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateRecordingMediaInfoView];
    }];
    
    // 主讲人切换，可能将当前用户切换成主讲人，这时当前用户的采集会由 root 管理，同样的，当前用户不作为主讲人时，归还给视频列表管理
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, currentPresenter)
           filter:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        return value != oldValue;
    }
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateRecordingMediaInfoView];
        [self updateVideoUsersWithMainAndExtraPlayingUsers];
        return YES;
    }];
}

#pragma mark - update

// 清理大屏的用户视图，更新视频列表数据
- (void)resetVideo {
    self.majorWindowIndex = -1;
    self.majorMediaUser = nil;
    if (self.majorMediaInfoView) {
        // 全屏或者大屏区域的视频改变位置类型，触发 restoreFullscreenOrMajorWindowCallback 回调处理
        self.majorMediaInfoView.positionType = BJLScPositionType_videoList;
        [self.majorMediaInfoView removeFromSuperview];
        self.majorMediaInfoView = nil;
    }
    [self updateCurrentMediaInfoViews];
}

// 更新老师的辅助流
- (void)reloadVideoWithTeacherExtraMediaInfoView:(nullable BJLScMediaInfoView *)teacherExtraMediaInfoView {
    self.teacherExtraMediaInfoView = teacherExtraMediaInfoView;
    [self reloadCollectionView];
}

// 更新采集视图
- (void)updateRecordingMediaInfoView {
    if (!self.room.loginUserIsPresenter
        && (self.room.recordingVM.recordingAudio || self.room.recordingVM.recordingVideo)) {
        if (!self.recordingMediaInfoView) {
            self.recordingMediaInfoView = [[BJLScMediaInfoView alloc] initWithRoom:self.room user:self.room.loginUser];
            self.recordingMediaInfoView.positionType = BJLScPositionType_videoList;
        }
        [self reloadCollectionView];
    }
    else if (self.recordingMediaInfoView) {
        [self.recordingMediaInfoView removeFromSuperview];
        if (self.replaceMajorWindowCallback) {
            // 由于当视频列表中数据只有一个时，可能是因为视频列表隐藏，触发了 reset，导致不会还原全屏视图，因此此处需要同时判断视频是否在全屏区域或者非视频列表区域
            if (self.recordingMediaInfoView.positionType != BJLScPositionType_videoList
                || self.recordingMediaInfoView.isFullScreen) {
                self.restoreFullscreenOrMajorWindowCallback();
            }
        }
        [self.recordingMediaInfoView destroy];
        self.recordingMediaInfoView = nil;
        [self reloadCollectionView];
    }
}

// 所有 user 数据将不因为位置改变而改变，因此只需要在用户增加或者减少时更新即可
- (void)updateVideoUsersWithMainAndExtraPlayingUsers {
    NSMutableArray<BJLMediaUser *> *videoUsers = [self.room.mainPlayingAdapterVM.playingUsers mutableCopy];
    NSMutableArray<BJLMediaUser *> *extraVideoUsers = [self.room.extraPlayingAdapterVM.playingUsers mutableCopy];
    
    // main playing user
    for (BJLMediaUser *user in [videoUsers copy]) {
        if ([user isSameUser:self.room.onlineUsersVM.currentPresenter]) {
            // 移除主讲
            [videoUsers bjl_removeObject:user];
        }
    }
    
    // extra playing user
    for (BJLMediaUser *user in [extraVideoUsers copy]) {
        // 添加不是主讲的辅助摄像头视图
        if (![user isSameUser:self.room.onlineUsersVM.currentPresenter]) {
            [videoUsers bjl_addObject:user];
        }
    }
    
    // 下麦用户的 mediaInfoView 主动 destroy TODO:不使用 CollectionView 来彻底解决复用持有导致的不会自动 dealloc 的情况
    NSMutableArray <BJLMediaUser *> *prevUsers = [self.videoUsers mutableCopy];
    for (BJLMediaUser *user in prevUsers) {
        // 避免将改变了音视频状态，但是仍在播放播放列表的用户移除
        BJLScMediaInfoView *mediaInfoView = [self.mainUserMediaInfoViews bjl_objectForKey:user.ID class:[BJLScMediaInfoView class]];
        BJLScMediaInfoView *extraMediaInfoView = [self.extraUserMediaInfoViews bjl_objectForKey:user.ID class:[BJLScMediaInfoView class]];
        if (mediaInfoView) {
            if (![self mediaUserWithMediaInfoView:mediaInfoView users:videoUsers]) {
                [self.mainUserMediaInfoViews bjl_removeObjectForKey:user.ID];
                [mediaInfoView removeFromSuperview];
                [mediaInfoView destroy];
            }
        }
        if(extraMediaInfoView) {
            if (![self mediaUserWithMediaInfoView:extraMediaInfoView users:extraVideoUsers]) {
                [self.extraUserMediaInfoViews bjl_removeObjectForKey:user.ID];
                [extraMediaInfoView removeFromSuperview];
                [extraMediaInfoView destroy];
            }
        }
    }
    
    self.videoUsers = videoUsers;
    // 如果存在大屏区域视图，并且用户数据里面不包含这个用户了，请求复原
    if (self.majorMediaInfoView
        && ![self.videoUsers containsObject:self.majorMediaInfoView.mediaUser]
        && self.restoreFullscreenOrMajorWindowCallback) {
        self.restoreFullscreenOrMajorWindowCallback();
    }
    [self updateUserMediaInfoViewsWithVideoUsers];
}

// 更新播放视图
- (void)updateUserMediaInfoViewsWithVideoUsers {
    NSMutableDictionary<NSString *, BJLScMediaInfoView *> *mainUserMediaInfoViews = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, BJLScMediaInfoView *> *extraUserMediaInfoViews = [NSMutableDictionary new];
    for (BJLMediaUser *user in [self.videoUsers copy]) {
        BJLScMediaInfoView *mediaInfoView = nil;
        if (user.cameraType == BJLCameraType_main) {
            mediaInfoView = [self.mainUserMediaInfoViews bjl_objectForKey:user.ID class:[BJLScMediaInfoView class]];
            // 如果是新的用户，添加数据到新的字典中
            if (!mediaInfoView) {
                mediaInfoView = [[BJLScMediaInfoView alloc] initWithRoom:self.room user:user];
                mediaInfoView.positionType = BJLScPositionType_videoList;
            }
            [mainUserMediaInfoViews bjl_setObject:mediaInfoView forKey:user.ID];
        }
        else if (user.cameraType == BJLCameraType_extra) {
            mediaInfoView = [self.extraUserMediaInfoViews bjl_objectForKey:user.ID class:[BJLScMediaInfoView class]];
            if (!mediaInfoView) {
                mediaInfoView = [[BJLScMediaInfoView alloc] initWithRoom:self.room user:user];
                mediaInfoView.positionType = BJLScPositionType_videoList;
            }
            // 添加数据到新的字典中
            [extraUserMediaInfoViews bjl_setObject:mediaInfoView forKey:user.ID];
        }
    }
    self.mainUserMediaInfoViews = mainUserMediaInfoViews;
    self.extraUserMediaInfoViews = extraUserMediaInfoViews;
    [self updateCurrentMediaInfoViews];
}

// 更新当前视频列表应显示的视频数据
- (void)updateCurrentMediaInfoViews {
    NSMutableArray<BJLScMediaInfoView *> *currentMediaInfoViews = [NSMutableArray new];
    for (BJLScMediaInfoView *mediaInfoView in self.mainUserMediaInfoViews.allValues) {
        if (mediaInfoView.positionType == BJLScPositionType_videoList
            && !mediaInfoView.isFullScreen) {
            [currentMediaInfoViews bjl_addObject:mediaInfoView];
        }
    }
    for (BJLScMediaInfoView *mediaInfoView in self.extraUserMediaInfoViews.allValues) {
        if (mediaInfoView.positionType == BJLScPositionType_videoList
            && !mediaInfoView.isFullScreen) {
            [currentMediaInfoViews bjl_addObject:mediaInfoView];
        }
    }
    self.currentMediaInfoViews = [currentMediaInfoViews copy];
    [self reloadCollectionView];
}

#pragma mark - replace

- (void)replaceMajorContentViewAtIndex:(NSInteger)index recording:(BOOL)recording teacherExtraMediaInfoView:(nullable BJLScMediaInfoView *)teacherExtraMediaInfoView {
    self.majorWindowIndex = index;
    self.majorMediaUser = nil;
    if (self.majorMediaInfoView) {
        self.majorMediaInfoView.positionType = BJLScPositionType_videoList;
        [self.majorMediaInfoView removeFromSuperview];
        self.majorMediaInfoView = nil;
    }
    self.teacherExtraMediaInfoView = teacherExtraMediaInfoView;
    // 大屏要替换成采集或 PPT
    if (index == -1) {
        // 采集
        if (recording) {
            self.majorMediaUser = nil;
            self.majorMediaInfoView =  self.recordingMediaInfoView;
        }
        // PPT
        else {
            self.majorMediaUser = nil;
            self.majorMediaInfoView = nil;
        }
    }
    // 大屏将要替换新的视频列表的非采集视频
    else {
        self.majorMediaInfoView = [self mediaInfoViewWithIndex:index];
        self.majorMediaUser = self.majorMediaInfoView.mediaUser;
    }
    // 更新视图的位置信息
    if (self.majorMediaInfoView) {
        self.majorMediaInfoView.positionType = BJLScPositionType_major;
    }
    [self updateCurrentMediaInfoViews];
    [self reloadCollectionView];
}

- (void)reloadCollectionView {
    if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
        return;
    }
    [self.collectionView reloadData];
}

#pragma mark - getter

- (CGSize)itemSize {    
    CGFloat itemWidth = 0.0;
    CGFloat itemHeight = self.collectionView.bounds.size.height;
    itemWidth = itemHeight * 16.9 / 9.0;
    
    // 根据屏幕 scale 丢弃部分 itemWidth 精度，保证计算值与屏幕实际渲染效果一致
    CGFloat screenScale = [UIScreen mainScreen].scale;
    itemWidth = floor(itemWidth * screenScale) / screenScale;
    
    return CGSizeMake(itemWidth, itemHeight);
}

- (BJLScMediaInfoView *)mediaInfoViewWithIndex:(NSInteger)index {
    BJLScMediaInfoView *mediaInfoView = [self.currentMediaInfoViews bjl_objectAtIndex:index];
    return mediaInfoView;
}

- (nullable BJLMediaUser *)mediaUserWithMediaInfoView:(nullable BJLScMediaInfoView *)mediaInfoView users:(nullable NSArray<BJLMediaUser *> *)users {
    if (!mediaInfoView || !users.count) {
        return nil;
    }
    for (BJLMediaUser *user in users) {
        if ([mediaInfoView.user isSameUser:user]) {
            return user;
        }
    }
    return nil;
}

- (BOOL)isVideoPlayingUser:(BJLMediaUser *)mediaUser {
    for (BJLMediaUser *user in [self.room.playingVM.videoPlayingUsers copy]) {
        if ([user isSameMediaUser:mediaUser]) {
            return YES;
        }
    }
    return NO;
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
    NSInteger totalItems = (self.majorMediaInfoView ? 1 : 0) + ((self.recordingMediaInfoView && self.majorMediaInfoView != self.recordingMediaInfoView) ? 1 : 0) + self.currentMediaInfoViews.count;
    CGFloat combinedItemWidth = (totalItems * itemSize.width) + ((totalItems - 1) * BJLScOnePixel);
    CGFloat padding = (collectionView.bounds.size.width - combinedItemWidth) / 2;
    padding = padding > 0.0 ? padding : 0.0;
    CGFloat screenScale = [UIScreen mainScreen].scale;
    padding = floor(padding * screenScale) / screenScale;
    switch (section) {
        case BJLScVideoSection_PPT:
            return UIEdgeInsetsMake(0.0, padding, 0.0, 0.0);
            
        case BJLScVideoSection_recording:
            return UIEdgeInsetsZero;
            
        case BJLScVideoSection_playing:
            return UIEdgeInsetsMake(0.0, 0.0, 0.0, padding);

        default:
            return UIEdgeInsetsZero;
    }
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    NSInteger count = _BJLScVideoSection_count;
    return count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger count = 0;
    switch (section) {
        case BJLScVideoSection_PPT:
            // ppt 只要大屏区域存在用户视频，将显示 PPT
            count = self.majorMediaInfoView ? 1 : 0;
            break;
            
        case BJLScVideoSection_recording:
            // recording
            count = (self.recordingMediaInfoView && self.majorMediaInfoView != self.recordingMediaInfoView) ? 1 : 0;
            break;
            
        case BJLScVideoSection_playing:
            // playing
            count = self.currentMediaInfoViews.count;
            break;
            
        default:
            break;
    }
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLScVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    switch (indexPath.section) {
        case BJLScVideoSection_PPT: {
             [self.room.slideshowViewController bjl_removeFromParentViewControllerAndSuperiew];
             [self bjl_addChildViewController:self.room.slideshowViewController superview:cell];
             [self.room.slideshowViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                 make.edges.equalTo(cell);
             }];
            if (self.teacherExtraMediaInfoView) {
                self.teacherExtraMediaInfoView.positionType = BJLScPositionType_videoList;
                [self.teacherExtraMediaInfoView removeFromSuperview];
                [cell addSubview:self.teacherExtraMediaInfoView];
                [self.teacherExtraMediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                    make.edges.equalTo(cell);
                }];
            }
            break;
        }
             
        case BJLScVideoSection_recording: {
            if (self.recordingMediaInfoView) {
                [self.recordingMediaInfoView removeFromSuperview];
                [cell addSubview:self.recordingMediaInfoView];
                [self.recordingMediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                    make.edges.equalTo(cell);
                }];
            }
            break;
        }
            
        case BJLScVideoSection_playing: {
            BJLScMediaInfoView *mediaInfoView = [self mediaInfoViewWithIndex:indexPath.row];
            if (mediaInfoView) {
                [mediaInfoView removeFromSuperview];
                [cell addSubview:mediaInfoView];
                [mediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                    make.edges.equalTo(cell);
                }];
            }
            break;
        }
            
        default:
            break;
    }
    return cell;
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    bjl_weakify(self);
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:indexPath.section == BJLScVideoSection_PPT ? (self.teacherExtraMediaInfoView ? @"白板/课件" : @"视频") : @"视频"
                                message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];
    [alert bjl_addActionWithTitle:@"放大窗口" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        bjl_strongify(self);
        NSInteger index = -1;
        BJLScWindowType windowType = BJLScWindowType_ppt;
        BJLScMediaInfoView *mediaInfoView = nil;
        BOOL recording = NO;
        if (self.replaceMajorWindowCallback) {
            switch (indexPath.section) {
                case BJLScVideoSection_PPT: {
                    windowType = BJLScWindowType_ppt;
                    mediaInfoView = self.teacherExtraMediaInfoView;
                    break;
                }
                    
                case BJLScVideoSection_recording: {
                    recording = YES;
                    windowType = BJLScWindowType_userVideo;
                    mediaInfoView = self.recordingMediaInfoView;
                    break;
                }
                    
                case BJLScVideoSection_playing: {
                    index = indexPath.row;
                    windowType = BJLScWindowType_userVideo;
                    mediaInfoView = [self mediaInfoViewWithIndex:indexPath.row];
                    break;
                }
                    
                default:
                    break;
            }
            self.replaceMajorWindowCallback(mediaInfoView, index, windowType, recording);
        }
    }];
    if (indexPath.section == BJLScVideoSection_recording) {
        
        // 当前登录是老师可以切换主讲
        if (self.room.loginUser.isTeacher
            && !self.room.loginUserIsPresenter
            && self.room.featureConfig.canChangePresenter) {
            [alert bjl_addActionWithTitle:@"设为主讲"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                BJLError *error = [self.room.onlineUsersVM requestChangePresenterWithUserID:self.room.loginUser.ID];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
            }];
        }
        
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
            }
        }];
    }
    else if (indexPath.section == BJLScVideoSection_playing) {
        BJLMediaUser *playingUser = [self mediaInfoViewWithIndex:indexPath.row].mediaUser;
        
        if (playingUser.videoOn) {
            BOOL playingVideo = [self isVideoPlayingUser:playingUser];
            [alert bjl_addActionWithTitle:playingVideo ? @"关闭视频" : @"开启视频"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                BJLError *error = [self.room.playingVM updatePlayingUserWithID:playingUser.ID videoOn:!playingVideo mediaSource:playingUser.mediaSource];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
                else {
                    BJLScMediaInfoView *view = [self mediaInfoViewWithIndex:indexPath.row];
                    [view updateCloseVideoPlaceholderHidden:!playingVideo];
                    if (self.updateVideoCallback) {
                        self.updateVideoCallback(playingUser, playingVideo);
                    }
                }
            }];
        }
        
        if (!self.room.featureConfig.disableGrantDrawing
            && self.room.loginUser.isTeacherOrAssistant
            && self.room.loginUser.noGroup
            && !playingUser.isTeacherOrAssistant) {
            BOOL wasGranted = [self.room.drawingVM.drawingGrantedUserNumbers containsObject:playingUser.number];
            [alert bjl_addActionWithTitle:wasGranted ? @"收回画笔" : @"授权画笔"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                BJLError *error =
                [self.room.drawingVM updateDrawingGranted:!wasGranted
                                               userNumber:playingUser.number
                                                    color:nil];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
            }];
        }
        
        if (self.room.loginUser.isTeacher
            && playingUser.isAssistant
            && self.room.featureConfig.canChangePresenter) {
            if ([playingUser isSameUser:self.room.onlineUsersVM.currentPresenter]) {
                [alert bjl_addActionWithTitle:@"收回主讲"
                                        style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction * _Nonnull action) {
                    bjl_strongify(self);
                    [self.room.onlineUsersVM requestChangePresenterWithUserID:self.room.loginUser.ID];
                }];
            }
            else {
                [alert bjl_addActionWithTitle:@"设为主讲"
                                        style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction * _Nonnull action) {
                    bjl_strongify(self);
                    BJLError *error = [self.room.onlineUsersVM requestChangePresenterWithUserID:playingUser.ID];
                    if (error) {
                        [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                    }
                }];
            }
        }
        
        if (self.room.loginUser.isTeacherOrAssistant
            && self.room.loginUser.noGroup
            && playingUser.isStudent) {
            [alert bjl_addActionWithTitle:@"奖励"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                BJLError *error = [self.room.roomVM sendLikeForUserNumber:playingUser.number];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
            }];
        }
        
        if (self.room.loginUser.isTeacherOrAssistant
            && self.room.loginUser.noGroup
            && self.room.roomInfo.roomType == BJLRoomType_1vNClass
            && !playingUser.isTeacher) {
            [alert bjl_addActionWithTitle:@"结束发言"
                                    style:UIAlertActionStyleDestructive
                                  handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                BJLError *error = [self.room.recordingVM remoteChangeRecordingWithUser:playingUser
                                                                               audioOn:NO
                                                                               videoOn:NO];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
            }];
        }
        
    }
    
    [alert bjl_addActionWithTitle:@"取消"
                            style:UIAlertActionStyleCancel
                          handler:nil];
    
    UIView *sourceView = cell;
    alert.popoverPresentationController.sourceView = sourceView;
    alert.popoverPresentationController.sourceRect = ({
        CGRect rect = sourceView.bounds;
        rect.origin.y = CGRectGetMaxY(rect) - 1.0;
        rect.size.height = 1.0;
        rect;
    });
    alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alert animated:YES completion:nil];
}

@end
