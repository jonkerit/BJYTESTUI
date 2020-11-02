//
//  BJLLikeEffectViewController.h
//  BJLiveUI
//
//  Created by xijia dai on 2018/10/22.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 小班课互动点赞类型
typedef NS_ENUM(NSInteger, BJLInteractiveType) {
    BJLInteractiveTypePersonAward,  // 个人点赞
    BJLInteractiveTypeGroupAward,   // 分组点赞
    BJLInteractiveTypeClassAward    // 全员点赞
};


@interface BJLLikeEffectViewController : UIViewController

- (instancetype)initWithName:(NSString *)name;

//个人点赞行为
- (instancetype)initForInteractiveClassWithName:(NSString *)name endPoint:(CGPoint)endPoint interactiveType:(BJLInteractiveType)interactiveType;

/// 个人点赞行为-多种奖励方式, 展示对应的动画
- (instancetype)initForInteractiveClassWithName:(NSString *)name endPoint:(CGPoint)endPoint imageUrlString:(nullable NSString *)imageUrlString interactiveType:(BJLInteractiveType)interactiveType;

@end

NS_ASSUME_NONNULL_END
