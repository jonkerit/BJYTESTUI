//
//  BJLScLotteryTextField.h
//  BJLiveUI
//
//  Created by xyp on 2020/8/27.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLTextField.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScLotteryTextField : BJLTextField

- (instancetype)initWithPlaceholder:(NSString *)placeholder;

- (void)updateTip:(NSString *)tip;

@end

NS_ASSUME_NONNULL_END
