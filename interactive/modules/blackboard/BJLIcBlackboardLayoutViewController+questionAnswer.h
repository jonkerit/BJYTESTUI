//
//  BJLIcBlackboardLayoutViewController+questionAnswer.h
//  BJLiveUI
//
//  Created by xijia dai on 2020/6/2.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcBlackboardLayoutViewController (questionAnswer)

- (void)makeObeservingForQuestionAnswer;

/** 打开答题器 */
- (void)openQuestionAnswer;

/** 关闭答题器 */
- (void)closeQuestionAnswerController;

@end

NS_ASSUME_NONNULL_END
