//
//  BJLIcUserViewController+cellAction.h
//  BJLiveUI
//
//  Created by 辛亚鹏 on 2020/6/12.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcUserViewController.h"
#import "BJLIcUserTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserViewController (cellAction)

/// cell的点击事件处理
- (void)cellActionType:(BJLIcUserCellActionType)type user:(BJLUser *)user boolValue:(BOOL)boolValue;

/// 多种奖励方式的回调
- (void)cellActionMutableAwards:(BJLUser *)user awardKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
