//
//  BJLScLabel.h
//  BJLiveUI
//
//  Created by xijia dai on 2020/8/28.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScLabel : UIView

@property(nullable, nonatomic) UIColor *textColor; // default is systemGrayColor
@property (nonatomic) BOOL canLayout;

/**
 特殊格式标签
 #discussion 目前标签支持 主文本必须可见区域 主文本可选可见区域(优先级较低) 特殊格式前缀 特殊格式可选可见内容(优先级较高) 特殊格式后缀
 #discussion 当无法满足上述格式或者可以全部可见时，和普通的 label 实现的功能一致
 @param minHeadCount 主文本最小可见区域
 @param headStyle 特殊格式前缀
 @param tailStyle 特殊格式后缀
 @param fontSize 文本字体大小
 */
- (instancetype)initWitMinHeadCount:(NSInteger)minHeadCount
                          headStyle:(nullable NSString *)headStyle
                          tailStyle:(nullable NSString *)tailStyle
                           fontSize:(CGFloat)fontSize;

/** text 支持 minHeadCount，styleText 支持 headStyle 和 tailStyle，其他情况需要扩展 */
- (void)updateText:(nullable NSString *)text styleText:(nullable NSString *)styleText;

@end

NS_ASSUME_NONNULL_END
