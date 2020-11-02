//
//  BJLIcUserViewController+observe.m
//  BJLiveUI
//
//  Created by 辛亚鹏 on 2020/6/11.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcUserViewController+observe.h"
#import "BJLIcUserViewController+private.h"
#import "BJLIcUserViewController+action.h"

@implementation BJLIcUserViewController (observe)

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room, state)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.state == BJLRoomState_connected) {
            [self.room.onlineUsersVM loadBlockedUserList];
        }
        return YES;
    }];
    
    /* 举手 */
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, speakingRequestUsers)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        self.speakRequestUserList = [self.room.speakingRequestVM.speakingRequestUsers mutableCopy];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        self.handupRedDot.hidden = !self.speakRequestUserList.count || self.handupButton.isSelected;
        [self reloadAllTableViewData];
        [self updateUserListTitle];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, didReceiveSpeakingRequestFromUser:)
             observer:^BOOL(BJLUser *user) {
        bjl_strongify(self);
        if (self.receiveSpeakingRequestCallback) {
            self.receiveSpeakingRequestCallback(user, NO, self.room.speakingRequestVM.speakingRequestUsers.count);
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, speakingRequestDidReplyEnabled:isUserCancelled:user:)
             observer:(BJLMethodObserver)^BOOL(BOOL speakingEnabled, BOOL isUserCancelled, BJLUser *user) {
        bjl_strongify(self);
        if (self.receiveSpeakingRequestCallback) {
            self.receiveSpeakingRequestCallback(user, YES, self.room.speakingRequestVM.speakingRequestUsers.count);
        }
        return YES;
    }];
    
    /* 在线用户 */
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, onlineUsers)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        self.onlineUserList = [self.room.onlineUsersVM.onlineUsers mutableCopy];
        [self updateOnStageUserList];
        [self updateDownStageUserList];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self reloadAllTableViewData];
        [self updateUserListTitle];
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, onlineUsersTotalCount)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self updateUserListTitle];
        return YES;
    }];
    
    /* 黑名单 */
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, didReceiveBlockedUserList:)
             observer:^BOOL(NSArray<BJLUser *> *userList) {
        bjl_strongify(self);
        [self.blockedUserList removeAllObjects];
        self.blockedUserList = [userList mutableCopy];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self reloadAllTableViewData];
        [self updateUserListTitle];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, didBlockUser:)
             observer:^BOOL(BJLUser *blockedUser) {
        bjl_strongify(self);
        [self updateUserListWithRemovedUser:blockedUser];
        [self.blockedUserList bjl_addObject:blockedUser];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self reloadAllTableViewData];
        [self updateUserListTitle];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, didFreeBlockedUserWithNumber:)
             observer:^BOOL(NSString *userNumber) {
        bjl_strongify(self);
        for (BJLUser *user in [self.blockedUserList copy]) {
            if ([user.number isEqualToString:userNumber]) {
                [self.blockedUserList bjl_removeObject:user];
            }
        }
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self reloadAllTableViewData];
        [self updateUserListTitle];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, didFreeAllBlockedUsers)
             observer:^BOOL {
        bjl_strongify(self);
        [self.blockedUserList removeAllObjects];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self reloadAllTableViewData];
        [self updateUserListTitle];
        return YES;
    }];
    
    /* 上下台 */
    [self bjl_kvo:BJLMakeProperty(self.room, loginUser)
           filter:^BOOL(BJLUser * _Nullable now, BJLUser * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        return !!now;
    }
         observer:^BOOL(BJLUser * _Nullable now, BJLUser * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self makeObservingAfterLoginUserAvailable];
        return NO;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.playingVM, playingUsers)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        self.onStageUserList = [self reSortOnStageUsers:self.room.playingVM.playingUsers];
        [self updateOnStageUserList];
        [self updateDownStageUserList];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self reloadAllTableViewData];
        [self updateUserListTitle];
        return YES;
    }];
    
    /* 禁言 */
    [self bjl_observe:BJLMakeMethod(self.room.chatVM, didReceiveForbidUser:fromUser:duration:)
             observer:(BJLMethodObserver)^BOOL(BJLUser *user, BJLUser *fromUser, NSTimeInterval duration) {
        bjl_strongify(self);
        // !!!:不进行禁言时间的倒计时，只要禁言就认为一直禁言，除非被解除
        BOOL forbid = duration > 0;
        [self.forbidChatUsers bjl_setObject:@(forbid) forKey:user.number];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self reloadAllTableViewData];
        return BJLKeepObserving;
    }];
    
    
    [self bjl_observe:BJLMakeMethod(self.room.chatVM, didReceiveForbidUserList:) observer:^BOOL(NSDictionary <NSString *, NSNumber *> * _Nullable forbidUserList) {
        bjl_strongify(self);
        [self.forbidChatUsers removeAllObjects];
        if (!forbidUserList || ![forbidUserList.allKeys count]) {
            return YES;
        }
        
        [forbidUserList enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
            NSInteger duration = obj.integerValue;
            BOOL forbid = duration > 0;
            [self.forbidChatUsers bjl_setObject:@(forbid) forKey:key];
        }];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        
        [self reloadAllTableViewData];
        return BJLKeepObserving;
    }];
    
    /* 用户分组信息 */
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, groupList) observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateGroupList];
        [self updateOnStageUserList];
        [self updateDownStageUserList];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        
        [self reloadAllTableViewData];
        return BJLKeepObserving;
    }];
    
    /* 画笔 权限 */
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, drawingGrantedUserNumbers) observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        
        [self reloadAllTableViewData];
        return BJLKeepObserving;
    }];
    
    /* ppt 权限 */
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM, authorizedPPTUserNumbers) observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        
        [self reloadAllTableViewData];
        return BJLKeepObserving;
    }];
    
    /* 屏幕分享 权限*/
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, authorizedScreenShareUserNumbers) observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        
        [self reloadAllTableViewData];
        return BJLKeepObserving;
    }];
    
    /* 点赞 **/
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveLikeForUserNumber:records:)
             observer:^BOOL(NSString *userNumber, NSDictionary<NSString *, NSNumber *> *records) {
        bjl_strongify(self);
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        
        for (BJLUser *user in self.room.onlineUsersVM.onlineUsers) {
            if ([user.number isEqualToString:userNumber]) {
                if (self.receiveLikeCallback) {
                    self.receiveLikeCallback(user);
                }
                break;
            }
        }
        
        
        [self reloadAllTableViewData];
        return BJLKeepObserving;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveLikeForGroupID:groupName:)
             observer:^BOOL {
        bjl_strongify(self);
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        
        [self reloadAllTableViewData];
        return BJLKeepObserving;
    }];
}

- (void)makeObservingAfterLoginUserAvailable {
    bjl_weakify(self);
    
    if (self.room.loginUser.isTeacher) {
        // 自动上台，老师和助教在服务端会自动上台，但是老师也需要发上台信令通知在老师前进教室的用户
        [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, onlineUserWillAdd:)
                 observer:^BOOL(BJLUser * user) {
            bjl_strongify(self);
            // 老师上台需要信令通知其他用户
            if (user.isTeacher) {
                [self.room.playingVM requestAddActiveUser:user];
                return YES;
            }
            // 如果是1 V N V M 的教室，并且没有配置自动上台时，不自动上台
            if (self.room.featureConfig.maxBackupUserCount > 0 && !self.room.featureConfig.autoGoOnStage) {
                return YES;
            }
            
            NSInteger count = self.room.featureConfig.maxActiveUserCount;
            if (self.room.onlineUsersVM.onlineTeacher) {
                // 老师在线的时候，最大上麦数要除去老师
                count++;
            }
            
            // 超出上台人数限制
            if (self.room.playingVM.playingUsers.count >= count) {
                return YES;
            }
            
            if (user.isAssistant) {
                // 助教不自动上台
                return YES;
            }
            
            // 查找用户是否已经在台上了
            BOOL isActive = NO;
            for (BJLUser *playingUser in [self.room.playingVM.playingUsers copy]) {
                if ([playingUser.ID isEqualToString:user.ID]) {
                    isActive = YES;
                    break;
                }
            }
            
            // 用户在台上，或者在自动上台的黑名单内，不自动上台，这里是基于仅老师控制自动上下台来处理的
            if (isActive || [self.autoAddActiveUserBlackList containsObject:user.ID]) {
                return YES;
            }
            
            // 请求上台
            if (user.onlineState == BJLOnlineState_visible) {
                [self.room.playingVM requestAddActiveUser:user];
            }
            return YES;
        }];
    }
    else if (self.room.loginUser.isAssistant) {
        // 助教在进入房间后将自己从台上用户移出
        [self bjl_kvoMerge:@[BJLMakeProperty(self.room, state),
                             BJLMakeProperty(self.room.onlineUsersVM, activeUsersSynced)]
                    filter:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            return self.room.onlineUsersVM.activeUsersSynced && [value bjl_integerValue] != [oldValue bjl_integerValue];
        }
                  observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            if (self.room.state == BJLRoomState_connected) {
                [self.room.playingVM requestRemoveActiveUser:self.room.loginUser];
            }
        }];
    }
}

#pragma mark - unity

// 重排台上用户顺序, 主讲-助教-学生
- (NSMutableArray <BJLMediaUser *> *)reSortOnStageUsers:(NSArray <BJLMediaUser *> *)array {
    NSMutableArray *arrM = [NSMutableArray array];
    
    for (BJLMediaUser *user in array) {
        if ([self.room.onlineUsersVM.currentPresenter isSameUser:user]) {
            [arrM insertObject:user atIndex:0];
            continue;
        }
        if (user.isStudent && ![arrM containsObject:user]) {
            [arrM addObject:user];
        }
    }
    
    int i = 0;
    if ([self.room.onlineUsersVM.currentPresenter isSameUser:arrM.firstObject]) {
        i = 1;
    }
    
    for (BJLMediaUser *user in array) {
        if (user.isAssistant && ![arrM containsObject:user]) {
            [arrM insertObject:user atIndex:i];
            i++;
        }
    }
    
    return arrM;
}

@end

