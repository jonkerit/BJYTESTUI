//
//  BJLScLotteryView.h
//  BJLiveUI
//
//  Created by xyp on 2020/8/27.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>
#import "BJLScLotteryTextField.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLScLotteryViewStatus) {
    BJLScLotteryViewStatus_None,
    BJLScLotteryViewStatus_Submit,
    BJLScLotteryViewStatus_Fill,
    BJLScLotteryViewStatus_Lose,
    BJLScLotteryViewStatus_Done,
};

// 响应超出此view边界的事件
@interface BJLScBeyondBoundsView : UIView
@end

@interface BJLScLotteryView : BJLScBeyondBoundsView

//- (instancetype)initWithViewStatus:(BJLScLotteryViewStatus)status;

@property (nonatomic, copy) void(^buttonClickCallback)(BJLScLotteryView *lotteryView);
@property (nonatomic, copy) void(^closeCallback)(void);
@property (nonatomic, copy) void(^listButtonCallback)(void);

@property (nonatomic, readonly) BJLScLotteryTextField *nameTextField, *phoneTextField;

- (void)updateViewWithLottery:(BJLLottery *)lottery status:(BJLScLotteryViewStatus)status;

@end

NS_ASSUME_NONNULL_END
