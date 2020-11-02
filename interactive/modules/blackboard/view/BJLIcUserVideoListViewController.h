//
//  BJLIcUserVideoListViewController.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/28.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcUserMediaInfoView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserVideoListViewController : UIViewController

// 视频列表管理的媒体信息视图变化回调
@property (nonatomic, nullable) void (^userMediaInfoViewsDidUpdateCallback)(NSArray<BJLIcUserMediaInfoView *> * _Nullable userMediaInfoViews);
// 显示错误信息
@property (nonatomic, nullable) void (^showErrorMessageCallback)(NSString *message);
// 用于将视频放回视频列表的事件
@property (nonatomic, nullable) void (^sendBackVideoViewCallback)(BJLMediaUser *user);
// 所有视频放回视频列表
@property (nonatomic, nullable) void (^sendBackAllVideoViewCallback)(void);
// 收到点赞
@property (nonatomic, nullable) void (^receiveLikeCallback)(BJLUser *user, UIButton *button);
// 踢出用户，存在强提示，回调给 root
@property (nonatomic, nullable) BOOL (^blockUserCallback)(BJLUser *user);

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

// 设置当前视频列表处于活跃状态
- (void)updateActive:(BOOL)active;
// 获取点击事件对应的视频窗口
- (nullable BJLIcUserMediaInfoView *)mediaInfoViewWithPanGesture:(UIPanGestureRecognizer *)panGesture;
// 将用户拖离视频列表区
- (nullable BJLIcUserMediaInfoView *)setUserLeaveSeatWithMediaID:(NSString *)mediaID;
// 将用户放回视频列表区，如果成功放回将返回放回的视图，否则返回空
- (nullable BJLIcUserMediaInfoView *)sendUserBackToSeatWithMediaID:(NSString *)mediaID;

@end

NS_ASSUME_NONNULL_END
