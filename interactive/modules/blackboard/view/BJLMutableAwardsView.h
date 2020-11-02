//
//  BJLMutableAwardsView.h
//  BJLiveUI
//
//  Created by xyp on 2020/7/31.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//  多种奖励方式的view

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLMutableAwardsView : UIView

- (instancetype)initWithRoom:(BJLRoom *)room user:(__kindof BJLUser *)user;

@property (nonatomic, readonly) CGSize size;
@property (nonatomic, nullable) void (^awardKeyCallback)(NSString *key);

@end

NS_ASSUME_NONNULL_END
