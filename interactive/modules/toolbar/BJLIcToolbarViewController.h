//
//  BJLIcToolbarViewController.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcUserMediaInfoView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcToolbarViewController : UIViewController

/**
  UserVideoUpside iphone 模板，处理超出范围的按钮，userVideoDownside 模板，处理老师视频窗口位置
 */
@property (nonatomic, nullable) UIView *(^requestReferenceViewCallback)(void);

// 打开网页
@property (nonatomic) void(^openWebViewCallback)(void);

// 计时器
@property (nonatomic) void(^countDownCallback)(void);

- (void)hideTeachingAid;

@property (nonatomic, readonly) UIButton
*exitButton,                    // 退出教室
*menuButton,                    // 菜单
*speakerButton,                 // 扬声器
*microphoneButton,              // 麦克风
*cameraButton,                  // 摄像头
*eyeProtectedButton,            // 护眼模式
*gallerylayoutButton,           // 画廊布局
*blackboardLayoutButton,        // 板书布局
*cloudRecordingButton,          // 云端录制
*unmuteAllMicrophoneButton,     // 一键开麦
*muteAllMicrophoneButton,       // 一键关麦
*speakRequestButton,            // 申请发言
*forbidSpeakRequestButton,      // 禁止发言
*userListButton,                // 用户列表
*chatListButton,                // 聊天列表
*homeworkButton,                // 作业区
*coursewareButton,              // 课件
*teachingAidButton;             // 教具
@property (nonatomic, readonly, nullable) UILabel *chatListRedDot, *userListRedDot, *menuRedDot;

@property (nonatomic) void (^handupTipCallback)(void);
@property (nonatomic) void (^closeCloudRecordingCallback)(void);

#if DEBUG
@property (nonatomic, readonly) UIButton
*widgetButton,
*settingsButton,
*fullscreenButton,
*popoversButton;
#endif

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

/**
 loading 完成，尝试弹出云端录制提示
 */
- (void)tryToShowCloudRecordingTipView;

@end

NS_ASSUME_NONNULL_END
