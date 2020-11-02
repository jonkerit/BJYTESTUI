//
//  BJLScTextOptionView.h
//  BJLiveUI
//
//  Created by xyp on 2020/8/24.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BJLScAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScTextOptionView : BJLHitTestView

@property (nonatomic, readonly) CGSize fitableSize;

- (instancetype)initWithRoom:(BJLRoom *)room;

- (void)remarkConstraintsWithPosition:(BJLScRectPosition)position;

- (instancetype)init NS_UNAVAILABLE;

- (CGSize)expectedSize;

- (CGSize)textOptionSize;


@end

NS_ASSUME_NONNULL_END
