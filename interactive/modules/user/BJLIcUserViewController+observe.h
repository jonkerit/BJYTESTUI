//
//  BJLIcUserViewController+observe.h
//  BJLiveUI
//
//  Created by 辛亚鹏 on 2020/6/11.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcUserViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserViewController (observe)

- (void)makeObserving;
- (void)makeObservingAfterLoginUserAvailable;

@end

NS_ASSUME_NONNULL_END
