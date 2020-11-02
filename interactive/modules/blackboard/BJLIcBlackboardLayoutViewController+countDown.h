//
//  BJLIcBlackboardLayoutViewController+countDown.h
//  BJLiveUI
//
//  Created by xijia dai on 2020/6/2.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcBlackboardLayoutViewController (countDown)

- (void)makeObeservingForCountDown;

/** 打开计时器 */
- (void)openCountDownTimer;

/** 撤回计时器 */
- (void)closeCountDownController;

@end

NS_ASSUME_NONNULL_END
