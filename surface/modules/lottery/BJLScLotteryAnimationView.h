//
//  BJLScLotteryAnimationView.h
//  BJLiveUI
//
//  Created by xyp on 2020/8/26.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScLotteryAnimationView : UIView

@property (nonatomic) void(^animationFinishCallback)(BJLScLotteryAnimationView *animationView);

@end

NS_ASSUME_NONNULL_END
