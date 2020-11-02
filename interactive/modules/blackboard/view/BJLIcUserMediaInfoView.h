//
//  BJLIcUserMediaInfoView.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/10/8.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserMediaInfoView : UIView

@property (nonatomic) BJLIcVideoPosition position;
@property (nonatomic, weak) UIView *videoView;
@property (nonatomic, readonly) BJLMediaUser *user;
@property (nonatomic, readonly) BJLButton *likeButton;
@property (nonatomic, nullable) void (^showErrorMessageCallback)(NSString *message);
@property (nonatomic, nullable) void (^updateVideoCallback)(BJLMediaUser *user, BOOL on);
@property (nonatomic, nullable) void (^updatePositionCallback)(BJLIcVideoPosition position);
@property (nonatomic, nullable) BOOL (^blockUserCallback)(BJLUser *user);

/**
 初始化视图

 #param user 用户
 #param room 房间实例
 #return 视图实例
 */
- (instancetype)initWithUser:(BJLMediaUser *)user room:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

/**
 主动销毁
 */
- (void)destroy;

/**
 还原位置
 */
- (void)restorePositon;

/**
 设置父控制器

 #param parentViewController parentViewController
 */
- (void)updateParentViewController:(UIViewController *)parentViewController;

/**
 更新视图
 目前主要用于多个 user 对应一个视图的情况 以及 部分功能实现不统一生成了多个视图对应一个 user 对象的现象
 #param user user
 #param combineVideoView 是否需要重置 video view，重置视频画面代表可能将视频画面从其他位置获取回来
 */
- (void)updateContentWithUser:(BJLMediaUser *)user
             combineVideoView:(BOOL)combineVideoView;

/**
 单击手势处理
 当手势被拦截的时候，可以调用此方法来处理单击事件
 #param point point
 */
- (void)handleSingleTapGesture:(CGPoint)point;

/**
 父视图变化时，调用此方法更新布局
 */
- (void)updateVideoViewConstranints;

/**
 更新点赞数
 */
- (void)updateLikeCount;

/** 更新是否播放视频 */
- (void)updatePlayVideo:(BOOL)playVideo;

/**
 更新动态课件授权标志

 #param authorized 是否被授权
 */
- (void)updateWebPPTAuthorized:(BOOL)authorized;

/**
 更新画笔授权标志

 #param drawingGranted 是否被授权
 */
- (void)updateDrawingGranted:(BOOL)drawingGranted;

/**
 更新举手视图

 #param hidden 是否隐藏举手视图
 */
- (void)updateSpeakRequestViewHidden:(BOOL)hidden;

/**
 更新音视频，名字，网络状态

 #param referenceView 参考视图，如果这些信息不跟随 self，需要提供 referenceView，目前仅用于 1v1 的设计
 */
- (void)updateInfoGroupViewWithReferenceView:(UIView *)referenceView;

/**
 判断当前的视图是否是 mediaUser 或者 mediaID 对应的视图，用于兼容需要多个媒体类型共用一个窗口的问题
 */
- (BOOL)isTargetMediaInfoViewWithMediaUser:(nullable BJLMediaUser *)mediaUser mediaID:(nullable NSString *)mediaID;
    
@end

NS_ASSUME_NONNULL_END
