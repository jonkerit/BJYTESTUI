//
//  BJLIcBlackboardLayoutViewController.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcUserMediaInfoView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcBlackboardLayoutViewController : UIViewController

@property (nonatomic, readonly) NSArray<BJLWindowDisplayInfo *> *documentWindowDisplayInfos;
@property (nonatomic, readonly) NSArray<BJLWindowDisplayInfo *> *webDocumentWindowDisplayInfos;
@property (nonatomic, readonly) NSArray<BJLWindowDisplayInfo *> *videoWindowDisplayInfos;
@property (nonatomic, nullable) void (^userMediaInfoViewsDidUpdateCallback)(NSArray<BJLIcUserMediaInfoView *> * _Nullable userMediaInfoViews);
@property (nonatomic, nullable) void (^receiveLikeCallback)(BJLUser *user, UIButton *button);
@property (nonatomic, nullable) void(^receiveGroupLikeCallback)(BOOL isGroup,  NSString * _Nullable groupName);
@property (nonatomic, nullable) void (^showErrorMessageCallback)(NSString *message);
@property (nonatomic, nullable) BOOL (^blockUserCallback)(BJLUser *user);
@property (nonatomic, nullable) void (^switchToNativePPTCallback)(UIViewController<BJLSlideshowUI> * _Nullable viewController, void (^callback)(BOOL shouldSwitch));
@property (nonatomic, nullable) void (^webviewControllerKeyboardFrameChangeCallback)(CGRect keyboardFrame, UIView *overlayView);
// 关闭网页
@property (nonatomic, nullable) void (^closeWebviewControllerCallback)(void);
// 关闭测验
@property (nonatomic, nullable) void (^closeQuizControllerCallback)(void);
@property (nonatomic, nullable) void (^cancelQuizControllerCallback)(void);
// 小黑板输入时间回调
@property (nonatomic, nullable) void (^showWritingBoardTimeInputViewControllerCallBack)(void);
// 关闭发布中的答题器二次确认回调
@property (nonatomic, nullable) void (^closeQuestionAnswerControllerCallback)(void);
// 抢答器成功抢答的动画回调
@property (nonatomic, nullable) void (^responderSuccessCallback)(BJLUser *user, UIButton *button);

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

- (void)setFullscreenParentViewController:(UIViewController *)parentViewController
                                superview:(nullable UIView *)superview;

- (void)tryToHideKeyboardView;

// 断网时，销毁学生的计时器和抢答器
- (void)destroyCountDownAndResponder;

// 设置当前视图为 active 状态
- (void)updateActive:(BOOL)active;

@end

NS_ASSUME_NONNULL_END
