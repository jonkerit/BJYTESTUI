//
//  BJLIcBlackboardLayoutViewController+award.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/7/28.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+award.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"

@implementation BJLIcBlackboardLayoutViewController (award)

- (void)makeObeservingForLikeAward {
    bjl_weakify(self);
    
    // 分组新增, 或者分组点赞数据变化,都需要从外层新加分组奖励UI或者关闭分组奖励UI
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.onlineUsersVM, groupList),
                         BJLMakeProperty(self.room.roomVM, grouplikeList)] observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.loginUser.groupID == 0
            || self.groupLikeWindowViewController
            || !self.room.loginUser.isStudent) {
            return ;
        }

        __block BJLUserGroup *groupInfo = nil;
        [self.room.onlineUsersVM.groupList enumerateObjectsUsingBlock:^(BJLUserGroup * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            bjl_strongify(self);
            if (obj.groupID == self.room.loginUser.groupID) {
                groupInfo = obj;
                *stop = YES;
            }
        }];
        
        NSInteger likeCount = [self.room.roomVM.grouplikeList bjl_integerForKey:@(groupInfo.groupID)];

        if (!likeCount || !groupInfo) {
            return ;
        }

        self.groupLikeWindowViewController = [self displayGroupLikeViewControllerWith:groupInfo];
    }];

    // 分组点赞监听展示动画 & icon
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveLikeForGroupID:groupName:) observer:^BOOL(NSInteger groupID, NSString *groupName) {
        bjl_strongify(self);
        BOOL isClassAward = (groupID == 0);
        if (self.receiveGroupLikeCallback) {
            self.receiveGroupLikeCallback(!isClassAward, groupName);
        }
        
        // 只有学生需要展示组奖励的UI
        if (self.groupLikeWindowViewController
            || isClassAward
            || self.room.loginUser.groupID != groupID) {
            return YES;
        }
        
        BJLUserGroup *groupInfo = nil;
        for (BJLUserGroup *group in self.room.onlineUsersVM.groupList) {
            if (group.groupID == groupID) {
                groupInfo = group;
                break;
            }
        }
        if (!groupInfo) {
            return YES;;
        }

        self.groupLikeWindowViewController = [self displayGroupLikeViewControllerWith:groupInfo];
        return YES;
    }];
        
    // 更新用户所在分组信息
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, onlineUserGroupInfoDidChangeWithUserNumbers:groupInfo:)
             observer:^BOOL(NSArray<NSString *> *userNumbers, BJLUserGroup * _Nullable groupInfo) {
        bjl_strongify(self);
        if (![userNumbers containsObject:self.room.loginUser.number]) {
            return YES;
        }
        
        // 有分组->无分组
        if (!groupInfo) {
            [self.groupLikeWindowViewController closeWithoutRequest];
            self.groupLikeWindowViewController = nil;
            return YES;
        }
        
        // 无分组->有分组
        NSInteger likeCount = [self.room.roomVM.grouplikeList bjl_integerForKey:@(groupInfo.groupID)];

        if (likeCount <= 0) {
            // 移动到没有奖励的分组,需要关闭奖励UI
            if (self.groupLikeWindowViewController) {
                [self.groupLikeWindowViewController closeWithoutRequest];
                self.groupLikeWindowViewController = nil;
            }
            return YES;
        }
        else {
            if (self.groupLikeWindowViewController) {
                return YES;
            }
        }
        
        self.groupLikeWindowViewController = [self displayGroupLikeViewControllerWith:groupInfo];
        return YES;
    }];
}

- (BJLIcGroupLikeWindowViewController *)displayGroupLikeViewControllerWith:(BJLUserGroup *)groupInfo {
    BJLIcGroupLikeWindowViewController *groupLikeWindowViewController = [[BJLIcGroupLikeWindowViewController alloc] initWithRoom:self.room groupInfo:groupInfo];
    self.groupLikeWindowViewController = groupLikeWindowViewController;
    [self.groupLikeWindowViewController setWindowedParentViewController:self superview:self.responderWindowView];
    [self.groupLikeWindowViewController openWithoutRequest];
    return groupLikeWindowViewController;
}

@end
