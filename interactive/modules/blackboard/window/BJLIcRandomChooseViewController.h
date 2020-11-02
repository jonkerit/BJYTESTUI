//
//  BJLIcRandomChooseViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/7/15.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcWindowViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcRandomChooseViewController : BJLIcWindowViewController

- (instancetype)initWithRoom:(BJLRoom *)room
                  candidates:(NSArray<NSString *> *)candidates
                 choosenUser:(BJLUser *)user;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

