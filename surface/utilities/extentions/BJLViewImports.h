//
//  BJLViewImports.h
//  BJLiveUI
//
//  Created by MingLQ on 2017-02-15.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

// fix error: definition of * must be imported from module BJLiveCore.BJLiveCore before it is required
#import <BJLiveCore/BJLiveCore.h>

#import <BJLiveBase/BJLiveBase.h>


NS_ASSUME_NONNULL_BEGIN

// isNotchScreen
static inline BOOL bjl_iPhoneXSeries() {
    if (@available(iOS 11.0, *)) {
        static const CGFloat insetsLimit = 20.0;
        UIEdgeInsets insets = UIWindow.bjl_keyWindow.safeAreaInsets;
        return (insets.top > insetsLimit
                || insets.left > insetsLimit
                || insets.right > insetsLimit
                || insets.bottom > insetsLimit);
    }
    return NO;
}

NS_ASSUME_NONNULL_END
