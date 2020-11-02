//
//  BJLIcUserViewController+action.h
//  BJLiveUI
//
//  Created by 辛亚鹏 on 2020/6/11.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcUserViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserViewController (action)

// update date
- (void)reloadAllTableViewData;

- (void)updateGroupList;
- (void)updateOnStageUserList;
- (void)updateDownStageUserList;
- (void)updateUserListWithRemovedUser:(BJLUser *)removedUser;
- (void)updateUserListTitle;

// action
- (void)freeAllBlockedUser;
- (void)showSwitchStageTipView;
- (void)switchToOnStageTableView;
- (void)hide;
- (void)switchToSpeakRequestView;
- (void)switchToOnlineUserView;

- (void)showOnStageList;
- (void)showDownStageList;
- (void)showBlockedList;
- (void)updateOnStageTableViewHidden:(BOOL)hidden;
- (void)updateDownStageTableViewHidden:(BOOL)hidden;
- (void)updateBlockTableViewHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
