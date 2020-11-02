//
//  BJLScCommandLotteryView.h
//  BJLiveUI
//
//  Created by xyp on 2020/8/28.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScCommandLotteryView : UIView

- (instancetype)initWithCommand:(NSString *)command;

@property (nonatomic, readonly) CGSize expectSize;

@end

@interface BJLScCommandCountDownView : UIView

- (instancetype)initWithDuration:(NSInteger)duration;
- (void)destory;

/// 倒计时结束的回调
@property (nonatomic, copy) void (^countOverCallback)(void);

@end

NS_ASSUME_NONNULL_END
