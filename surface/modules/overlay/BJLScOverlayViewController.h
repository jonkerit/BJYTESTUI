//
//  BJLScOverlayViewController.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScOverlayViewController : UIViewController

- (instancetype)initWithRoom:(BJLRoom *)room;

// 基本等同于 bjl_addChildViewController:superview:, 将设置 tapToHide 为 YES, 具体布局需要在外部处理
- (void)showWithContentViewController:(nullable UIViewController *)viewController contentView:(nullable UIView *)view;
// view 将铺满显示，将设置 tapToHide 为 NO, 布局内部处理
- (void)showFillContentViewController:(nullable UIViewController *)viewController contentView:(nullable UIView *)view ratio:(CGFloat)ratio;

- (void)hide;

@property (nonatomic) BOOL tapToHide; // if YES not call tapCallback()
@property (nonatomic, nullable) void (^showCallback)(void);
@property (nonatomic, nullable) void (^hideCallback)(void);
@property (nonatomic, nullable) void (^tapCallback)(void);
@property (nonatomic, weak, readonly) UIView *contentView;
@property (nonatomic, weak, readonly) UIViewController *viewController;

@end

NS_ASSUME_NONNULL_END
