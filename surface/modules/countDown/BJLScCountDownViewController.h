//
//  BJLScCountDownViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/10/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>
#import "BJLScWindowViewController.h"

NS_ASSUME_NONNULL_BEGIN

/** 三分屏直播间的倒计时 */
@interface BJLScCountDownViewController : BJLScWindowViewController

@property (nonatomic, readonly) BOOL isDecrease;
@property (nonatomic, readonly) BOOL shouldPause;
@property (nonatomic, readonly) NSInteger originCountDownTime;
@property (nonatomic, readonly) NSInteger currentCountDownTime;

- (instancetype)initWithRoom:(BJLRoom *)room;

- (void)updateTimerWithTotalTime:(NSInteger)time
            currentCountDownTime:(NSInteger)currentCountDownTime
                      isDecrease:(BOOL)isDecrease
                     shouldPause:(BOOL)shouldPause;

@end

NS_ASSUME_NONNULL_END
