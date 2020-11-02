//
//  BJLIcBlackboardLayoutViewController+questionResponder.h
//  BJLiveUI
//
//  Created by xijia dai on 2020/6/2.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcBlackboardLayoutViewController (questionResponder)

- (void)makeObeservingForQuestionResponder;

/** 打开抢答器 */
- (void)openQuestionResponder;

/** 撤回抢答器 */
- (void)closeQuestionResponderController;

@end

NS_ASSUME_NONNULL_END
