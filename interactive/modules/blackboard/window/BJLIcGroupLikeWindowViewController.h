//
//  BJLIcGroupLikeWindowViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/7/20.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcWindowViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcGroupLikeWindowViewController : BJLIcWindowViewController

- (instancetype)initWithRoom:(BJLRoom *)room
                   groupInfo:(BJLUserGroup *)group;
@end

NS_ASSUME_NONNULL_END
