//
//  BJLIcDocumentWindowViewController.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/20.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLIcWindowViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class BJLRoom;

@interface BJLIcDocumentWindowViewController : BJLIcWindowViewController

@property (nonatomic, readonly) NSString *documentID;
@property (nonatomic, readonly) NSInteger pageIndex;
@property (nonatomic, readonly) CGFloat relativeX;
@property (nonatomic, copy, nullable) void (^documentWindowCloseCallback)(NSString *documentID);
@property (nonatomic, nullable) void (^switchToNativePPTCallback)(UIViewController<BJLSlideshowUI> * _Nullable viewController, void (^callback)(BOOL shouldSwitch));

/// 初始化
/// #param room room
/// #param documentID documentID
/// #param relativeX 相对的x值, 用于确定窗口的起始x位置
- (instancetype)initWithRoom:(BJLRoom *)room documentID:(NSString *)documentID relativeX:(CGFloat)relativeX;

- (instancetype)init NS_UNAVAILABLE;

- (void)startObserverForLaserPointView:(UIView *)laserPointView;
- (void)stopObserverForLaserPointView;

@end

NS_ASSUME_NONNULL_END
