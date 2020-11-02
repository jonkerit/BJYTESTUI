//
//  BJLScVideoPlaceholderView.h
//  BJLiveUI
//
//  Created by xijia dai on 2020/2/21.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveBase/BJLiveBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScVideoPlaceholderView : BJLHitTestView

- (instancetype)initWithImage:(UIImage *)image tip:(NSString *)tip;
- (void)updateImage:(nullable UIImage *)image;
- (void)updateTip:(nullable NSString *)tip font:(nullable UIFont *)font;
- (void)updateImageWithURLString:(NSString *)imageURLString placeholder:(nullable UIImage *)placeholderImage;

@end

NS_ASSUME_NONNULL_END
