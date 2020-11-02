//
//  BJLIcCountDownViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/7/23.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <BJLiveCore/BJLiveCore.h>
#import "BJLIcWindowViewController.h"

NS_ASSUME_NONNULL_BEGIN

// 倒计时学生端
@interface BJLIcCountDownViewController : BJLIcWindowViewController

- (instancetype)initWithRoom:(BJLRoom *)room;

- (void)updateWithTime:(NSInteger)time;

@end

NS_ASSUME_NONNULL_END
