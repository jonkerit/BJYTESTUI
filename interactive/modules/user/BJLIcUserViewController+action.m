//
//  BJLIcUserViewController+action.m
//  BJLiveUI
//
//  Created by 辛亚鹏 on 2020/6/11.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcUserViewController+action.h"
#import "BJLIcUserViewController+private.h"
#import "BJLIcUserTableViewCell.h"

@implementation BJLIcUserViewController (action)

#pragma mark - data update

- (void)reloadAllTableViewData {
    if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
        return;
    }
    if (self.speakRequestTableView && !self.speakRequestTableView.hidden) {
        [self.speakRequestTableView reloadData];
    }
    if (self.onStageTableView && !self.onStageTableView.hidden) {
        for (BJLIcUserTableViewCell *cell in [self.speakRequestTableView visibleCells]) {
            [cell hideAwardsViewController];
        }
        [self.onStageTableView reloadData];
    }
    if (self.downStageTableView && !self.downStageTableView.hidden) {
        for (BJLIcUserTableViewCell *cell in [self.speakRequestTableView visibleCells]) {
            [cell hideAwardsViewController];
        }
        [self.downStageTableView reloadData];
    }
    if (self.blockedTableView && !self.blockedTableView.hidden) {
        [self.blockedTableView reloadData];
    }
}

- (void)updateGroupList {
    NSMutableArray <BJLUserGroup *> *groupList = [NSMutableArray new];
    for (BJLUserGroup *group in self.room.onlineUsersVM.groupList) {
        NSUInteger groupID = group.groupID;
        if (groupID == 0) {
            continue;
        }
        [groupList bjl_addObject:group];
    }
    self.groupList = [groupList copy];
}

- (void)updateOnStageUserList {
    NSMutableArray <BJLUser *> *onStageClassUser = [NSMutableArray new];
    NSMutableDictionary<NSNumber *, NSArray<BJLMediaUser *> *> *onStageGroupUserDic = [NSMutableDictionary new];
    
    for (BJLUserGroup *group in self.groupList) {
        NSUInteger groupID = group.groupID;
        if (groupID == 0) {
            continue;
        }
        NSMutableArray<BJLMediaUser *> *groupUserList = [NSMutableArray new];
        [onStageGroupUserDic bjl_setObject:groupUserList forKey:@(groupID)];
    }
    
    for (BJLMediaUser *user in self.onStageUserList) {
        NSUInteger groupID = user.groupID;
        if (groupID == 0) {
            [onStageClassUser bjl_addObject:user];
            continue;
        }
        
        NSMutableArray<BJLMediaUser *> *groupUserList = [[onStageGroupUserDic bjl_arrayForKey:@(groupID)] mutableCopy];
        if (!groupUserList) {
            groupUserList = [NSMutableArray new];
        }
        [groupUserList bjl_addObject:user];
        [onStageGroupUserDic bjl_setObject:groupUserList forKey:@(groupID)];
    }
    
    self.onStageGroupUserDic = [onStageGroupUserDic copy];
    self.onStageClassUser = [onStageClassUser copy];
}

- (void)updateDownStageUserList {
    NSMutableArray *list = [self.onlineUserList mutableCopy];
    for (BJLUser *onlineUser in [list copy]) {
        for (BJLUser *onStageUser in [self.onStageUserList copy]) {
            if ([onStageUser isSameUser:onlineUser]) {
                [list removeObject:onlineUser];
            }
        }
    }
    self.downStageUserList = list;
    
    NSMutableArray <BJLUser *> *downStageClassUser = [NSMutableArray new];
    NSMutableDictionary<NSNumber *, NSArray<BJLUser *> *> *downStageGroupUserDic = [NSMutableDictionary new];
    
    for (BJLUserGroup *group in self.groupList) {
        NSUInteger groupID = group.groupID;
        if (groupID == 0) {
            continue;
        }
        NSMutableArray<BJLUser *> *groupUserList = [NSMutableArray new];
        [downStageGroupUserDic bjl_setObject:groupUserList forKey:@(groupID)];
    }
    
    for (BJLUser *user in list) {
        NSUInteger groupID = user.groupID;
        if (groupID == 0) {
            [downStageClassUser bjl_addObject:user];
            continue;
        }
        
        NSMutableArray<BJLUser *> *groupUserList = [[downStageGroupUserDic bjl_arrayForKey:@(groupID)] mutableCopy];
        if (!groupUserList) {
            groupUserList = [NSMutableArray new];
        }
        [groupUserList bjl_addObject:user];
        [downStageGroupUserDic bjl_setObject:groupUserList forKey:@(groupID)];
    }
    self.downStageGroupUserDic = [downStageGroupUserDic copy];
    self.downStageClassUser = [downStageClassUser copy];
}

- (void)updateUserListWithRemovedUser:(BJLUser *)removedUser {
    // 清理成员列表
    for (BJLUser *user in [self.onlineUserList copy]) {
        if ([user.number isEqualToString:removedUser.number]) {
            [self.onlineUserList removeObject:user];
            break;
        }
    }
    for (BJLMediaUser *user in [self.onStageUserList copy]) {
        if ([user.number isEqualToString:removedUser.number]) {
            [self.onStageUserList removeObject:user];
            break;
        }
    }
    for (BJLUser *user in [self.downStageUserList copy]) {
        if ([user.number isEqualToString:removedUser.number]) {
            [self.downStageUserList removeObject:user];
            break;
        }
    }
}

- (void)updateUserListTitle {
    NSString *handUpTitle = self.speakRequestUserList.count > 0 ? [NSString stringWithFormat:@"举手(%ld)", (long)self.speakRequestUserList.count] : @"举手(0)";
    [self.handupButton setTitle:handUpTitle forState:UIControlStateNormal];
    NSString *onlineTitle = self.onlineUserList.count > 0 ? [NSString stringWithFormat:@"全部成员(%ld)", (long)self.room.onlineUsersVM.onlineUsersTotalCount] : @"用户";
    [self.allUsersButton setTitle:onlineTitle forState:UIControlStateNormal];
    NSString *onStageTitle = self.onStageUserList.count > 0 ? [NSString stringWithFormat:@"台上成员(%ld)", (long)self.onStageUserList.count] : @"台上成员(0)";
    self.onStageHeaderView.titleLabel.text = onStageTitle;
    NSString *downStageTitle = self.downStageUserList.count >  0 ? [NSString stringWithFormat:@"台下成员(%ld)", (long)self.downStageUserList.count] : @"台下成员(0)";
    self.downStageHeaderView.titleLabel.text = downStageTitle;
    NSString *blockedTitle = self.blockedUserList.count > 0 ? [NSString stringWithFormat:@"黑名单(%ld)", (long)self.blockedUserList.count] : @"黑名单(0)";
    self.blockedHeaderView.titleLabel.text = blockedTitle;
    if (self.blockedHeaderView.isExpand) {
        self.blockedHeaderView.freeBlockedUserButton.hidden = !self.blockedUserList.count;
    }
    else {
        self.blockedHeaderView.freeBlockedUserButton.hidden = YES;
    }
    
}

- (void)freeAllBlockedUser {
    if (!self.room.loginUser.isTeacherOrAssistant) {
        return;
    }
    if (self.showFreeAllBlockedUserCallback) {
        self.showFreeAllBlockedUserCallback();
    }
}

- (void)showSwitchStageTipView {
    if (!self.room.loginUser.isTeacherOrAssistant) {
        return;
    }
    if (self.showSwitchStageTipViewCallback) {
        self.showSwitchStageTipViewCallback();
    }
}

- (void)switchToOnStageTableView {
    [self.onStageHeaderView updateExpand:YES];
    [self.downStageHeaderView updateExpand:NO];
    [self.blockedHeaderView updateExpand:NO];
    
    [self switchToOnlineUserView];
    [self reloadAllTableViewData];
}

- (void)hide {
    if (self.closeCallback) {
        self.closeCallback();
    }
}

#pragma mark - speakrequest, onstage, downstage, blocked list switch

- (void)switchToSpeakRequestView {
    self.handupButton.layer.borderWidth = 0;
    self.handupButton.backgroundColor = [BJLIcTheme brandColor];
    self.handupButton.selected = YES;
    self.allUsersButton.layer.borderWidth = 1.0;
    self.allUsersButton.backgroundColor = [UIColor clearColor];
    self.allUsersButton.selected = NO;

    self.onStageHeaderView.hidden = YES;
    self.downStageHeaderView.hidden = YES;
    self.blockedHeaderView.hidden = YES;
    self.onStageTableView.hidden = YES;
    self.downStageTableView.hidden = YES;
    self.blockedTableView.hidden = YES;
    self.handupRedDot.hidden = YES;
    
    self.speakRequestTableView.hidden = NO;
    [self reloadAllTableViewData];
}

- (void)switchToOnlineUserView {
    self.handupButton.selected = NO;
    self.handupButton.layer.borderWidth = 1.0;
    self.handupButton.backgroundColor = [UIColor clearColor];
    self.allUsersButton.layer.borderWidth = 0;
    self.allUsersButton.backgroundColor = [BJLIcTheme brandColor];
    self.allUsersButton.selected = YES;

    self.speakRequestTableView.hidden = YES;
    self.onStageHeaderView.hidden = NO;
    self.downStageHeaderView.hidden = NO;
    self.blockedHeaderView.hidden = NO;
    if (self.blockedHeaderView.isExpand) {
        [self showBlockedList];
    }
    else if (self.downStageHeaderView.isExpand) {
        [self showDownStageList];
    }
    else {
        [self showOnStageList];
    }
}

- (void)showOnStageList {
    [self.onStageHeaderView updateExpand:YES];
    [self.downStageHeaderView updateExpand:NO];
    [self.blockedHeaderView updateExpand:NO];
    
    [self updateOnStageTableViewHidden:NO];
    [self updateDownStageTableViewHidden:YES];
    [self updateBlockTableViewHidden:YES];
    [self reloadAllTableViewData];
}

- (void)showDownStageList {
    [self.onStageHeaderView updateExpand:NO];
    [self.downStageHeaderView updateExpand:YES];
    [self.blockedHeaderView updateExpand:NO];
    
    [self updateOnStageTableViewHidden:YES];
    [self updateDownStageTableViewHidden:NO];
    [self updateBlockTableViewHidden:YES];
    [self reloadAllTableViewData];
}

- (void)showBlockedList {
    [self.onStageHeaderView updateExpand:NO];
    [self.downStageHeaderView updateExpand:NO];
    [self.blockedHeaderView updateExpand:YES];
    
    self.blockedHeaderView.freeBlockedUserButton.hidden = !self.blockedUserList.count;
    
    [self updateOnStageTableViewHidden:YES];
    [self updateDownStageTableViewHidden:YES];
    [self updateBlockTableViewHidden:NO];
    [self reloadAllTableViewData];
}

- (void)updateOnStageTableViewHidden:(BOOL)hidden {
    self.onStageTableView.hidden = hidden;
    if (hidden) {
        // 隐藏时将上台列表高度置为0
        [self.onStageTableView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.onStageTableView.bjl_top).priorityHigh();
            make.bottom.equalTo(self.contentView.bjl_bottom).offset(-BJLIcAppearance.userOptionViewHeight * 2).priorityMedium();
        }];
    }
    else {
        // 显示时将上台列表底部等于整个列表的底部偏移下台列表按钮的高度
        [self.onStageTableView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.contentView.bjl_bottom).offset(-BJLIcAppearance.userOptionViewHeight * 2).priorityHigh();
            make.bottom.equalTo(self.onStageTableView.bjl_top).priorityMedium();
        }];
    }
}

- (void)updateDownStageTableViewHidden:(BOOL)hidden {
    self.downStageTableView.hidden = hidden;
    if (hidden) {
        // 隐藏时将下台列表高度置为0
        [self.downStageTableView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.downStageTableView.bjl_top).priorityHigh();
            make.bottom.equalTo(self.contentView.bjl_bottom).offset(-BJLIcAppearance.userOptionViewHeight).priorityMedium();
        }];
    }
    else {
        // 显示时将下台列表的底部等于整个列表的底部
        [self.downStageTableView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.contentView.bjl_bottom).offset(-BJLIcAppearance.userOptionViewHeight).priorityHigh();
            make.bottom.equalTo(self.downStageTableView.bjl_top).priorityMedium();
        }];
    }
}

- (void)updateBlockTableViewHidden:(BOOL)hidden {
    self.blockedTableView.hidden = hidden;
    if (hidden) {
        // 隐藏时将黑名单列表高度置为0
        [self.blockedTableView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.blockedTableView.bjl_top).priorityHigh();
            make.bottom.equalTo(self.contentView.bjl_bottom).priorityMedium();
        }];
    }
    else {
        // 显示时将黑名单列表的底部等于整个列表的底部
        [self.blockedTableView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.contentView.bjl_bottom).priorityHigh();
            make.bottom.equalTo(self.blockedTableView.bjl_top).priorityMedium();
        }];
    }
}

@end

