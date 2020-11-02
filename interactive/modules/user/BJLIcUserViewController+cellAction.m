//
//  BJLIcUserViewController+cellAction.m
//  BJLiveUI
//
//  Created by 辛亚鹏 on 2020/6/12.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcUserViewController+cellAction.h"
#import "BJLIcUserViewController+action.h"
#import "BJLIcUserViewController+private.h"

@implementation BJLIcUserViewController (cellAction)

//BJLIcUserCellActionTypeReward      = 10,  // 奖励
//BJLIcUserCellActionTypeCamera      = 11,  // 摄像头
//BJLIcUserCellActionTypeMic         = 12,  // 麦克风
//BJLIcUserCellActionTypeDraw        = 13,  // 画笔
//BJLIcUserCellActionTypePPT         = 14,  // ppt
//BJLIcUserCellActionTypeForbidChat  = 15,  // 聊天禁言
//BJLIcUserCellActionTypeScreenShare = 16,  // 屏幕分享
//BJLIcUserCellActionTypeGoOnStage   = 17,  // 上台
//BJLIcUserCellActionTypeGoDownStage = 18,  // 上台
//BJLIcUserCellActionTypeBlocked     = 19,  // 拉黑
//
//BJLIcUserCellActionTypeFreeBlocked = 30,  // 解除黑名单
//
//BJLIcUserCellActionTypeAllowSpeak  = 40,  // 同意发言
//BJLIcUserCellActionTypeRefuseSpeak = 41,  // 拒绝发言

#pragma mark - cell action, cell的点击事件

- (void)cellActionType:(BJLIcUserCellActionType)type user:(BJLUser *)user boolValue:(BOOL)boolValue {
    switch (type) {
        case BJLIcUserCellActionTypeReward:
            [self rewardWithUser:user];
            break;
            
        case BJLIcUserCellActionTypeCamera:
            [self updateCameraWithUser:(BJLMediaUser *)user isOn:boolValue];
            break;
            
        case BJLIcUserCellActionTypeMic:
            [self updateMicWithUser:(BJLMediaUser *)user isOn:boolValue];
            break;
            
        case BJLIcUserCellActionTypeDraw:
            [self updateDrawWithUser:user isOn:boolValue];
            break;
            
        case BJLIcUserCellActionTypePPT:
            [self updatePPTWithUser:user isOn:boolValue];
            break;
            
        case BJLIcUserCellActionTypeForbidChat:
            [self updateChatWithUser:user isForbid:boolValue];
            break;
            
        case BJLIcUserCellActionTypeScreenShare:
            [self updateScreenWithUser:user isShare:boolValue];
            break;
            
        case BJLIcUserCellActionTypeGoOnStage:
            [self onStageWithUser:user];
            break;
            
        case BJLIcUserCellActionTypeGoDownStage:
            [self downStageWithUser:user];
            break;
            
        case BJLIcUserCellActionTypeBlocked:
            [self blockedWithUser:user];
            break;
            
        case BJLIcUserCellActionTypeFreeBlocked:
            [self freeBlockedWithUser:user];
            break;
            
        case BJLIcUserCellActionTypeAllowSpeak:
            [self allowSpeakRequestWithUser:user];
            break;
            
        case BJLIcUserCellActionTypeRefuseSpeak:
            [self refuseSpeakRequestWithUser:user];
            break;
            
        default:
            break;
    }
}

- (void)cellActionMutableAwards:(BJLUser *)user awardKey:(NSString *)key {
    BJLError *error = [self.room.roomVM sendLikeForUserNumber:user.number key:key];
    [self showError:error];
}

#pragma mark -

- (void)rewardWithUser:(BJLUser *)user {
    BJLError *error = [self.room.roomVM sendLikeForUserNumber:user.number];
    [self showError:error];
}

- (void)updateCameraWithUser:(BJLMediaUser *)user isOn:(BOOL)isOn {
    BJLError *error = [self.room.recordingVM remoteChangeRecordingWithUser:user audioOn:user.audioOn videoOn:isOn];
    [self showError:error];
}

- (void)updateMicWithUser:(BJLMediaUser *)user isOn:(BOOL)isOn {
    BJLError *error = [self.room.recordingVM remoteChangeRecordingWithUser:user audioOn:isOn videoOn:user.videoOn];
    [self showError:error];
}

- (void)updateDrawWithUser:(BJLUser *)user isOn:(BOOL)isOn {
    BJLError *error = [self.room.drawingVM updateDrawingGranted:isOn userNumber:user.number color:nil];
    [self showError:error];
}

- (void)updatePPTWithUser:(BJLUser *)user isOn:(BOOL)isOn {
    BJLError *error = [self.room.documentVM updateStudentPPTAuthorized:isOn userNumber:user.number];
    [self showError:error];
}

- (void)updateChatWithUser:(BJLUser *)user isForbid:(BOOL)isForbid {
    // 禁言某人，目前是禁言一天
    CGFloat duration = !isForbid ? 60 * 60 * 24 : 0.0;
    BJLError *error = [self.room.chatVM sendForbidUser:user duration:duration];
    [self showError:error];
}

- (void)updateScreenWithUser:(BJLUser *)user isShare:(BOOL)isShare {
    BJLError *error = [self.room.recordingVM updateStudentScreenShareAuthorized:isShare userNumber:user.number];
    [self showError:error];
}

- (void)onStageWithUser:(BJLUser *)user {
    NSInteger count = self.room.featureConfig.maxActiveUserCount;
    if (self.room.onlineUsersVM.onlineTeacher) {
        // 老师在线的时候，最大上麦数要除去老师
        count++;
    }
    // 1v1 最多二人
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        count = 2;
    }
    // 直接操作上下台的时候不可能将上台的用户再次上台，不需要处理是否在台上的判断
    if (self.room.playingVM.playingUsers.count >= count) {
        [self showSwitchStageTipView];
    }
    else {
        if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType && self.room.loginUser.isAssistant) {
            for (BJLMediaUser *user in [self.room.playingVM.playingUsers copy]) {
                if (user.isStudent) {
                    if (self.showErrorMessageCallback) {
                        self.showErrorMessageCallback(@"学生在台上时助教不能上台");
                    }
                    return;
                }
            }
        }
        // 上台, 开启视频，等待SDK刷新移除用户
        BJLError *error = [self.room.playingVM requestAddActiveUser:user];
        if (error) {
            [self showError:error];
        }
        else {
            // 移出自动上台黑名单
            [self.autoAddActiveUserBlackList removeObject:user.ID];
        }
    }
}

- (void)downStageWithUser:(BJLUser *)user {
    // 下台, 关闭音视频，等待SDK刷新移除用户
    BJLError *error = [self.room.playingVM requestRemoveActiveUser:user];
    if (error) {
        [self showError:error];
    }
    else {
        // 加入自动上台黑名单
        [self.autoAddActiveUserBlackList addObject:user.ID];
        // 移除PPT权限
        if ([self.room.documentVM.authorizedPPTUserNumbers containsObject:user.number]) {
            [self.room.documentVM updateStudentPPTAuthorized:NO userNumber:user.number];
        }
        // 移除画笔权限
        if ([self.room.drawingVM.drawingGrantedUserNumbers containsObject:user.number]) {
            [self.room.drawingVM updateDrawingGranted:NO userNumber:user.number color:nil];
        }
    }
}

- (void)blockedWithUser:(BJLUser *)user {
    if (self.blockUserCallback) {
        self.blockUserCallback(user);
    }
}

- (void)freeBlockedWithUser:(BJLUser *)user {
    [self.room.onlineUsersVM freeBlockedUserWithNumber:user.number];
}

- (void)allowSpeakRequestWithUser:(BJLUser *)user {
    // 同意举手，立即刷新
    NSInteger count = self.room.featureConfig.maxActiveUserCount;
    if (self.room.onlineUsersVM.onlineTeacher) {
        // 老师在线的时候，最大上麦数要除去老师
        count++;
    }
    // 如果上台的用户举手的时候，是不用下台其他用户的
    BOOL isActive = NO;
    for (BJLUser *activeUser in [self.room.playingVM.playingUsers copy]) {
        if ([user.ID isEqualToString:activeUser.ID]) {
            isActive = YES;
            break;
        }
    }
    // 1v1 最多二人
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        count = 2;
    }
    // 非上台的用户举手，并且上台人数超过限制，提示
    if (!isActive && self.room.playingVM.playingUsers.count >= count) {
        [self showSwitchStageTipView];
    }
    else {
        BJLError *error = [self.room.speakingRequestVM replySpeakingRequestToUserID:user.ID allowed:YES];
        if (error) {
            [self showError:error];
        }
        else {
            [self.speakRequestUserList removeObject:user];
            [self reloadAllTableViewData];
            [self updateUserListTitle];
        }
    }
}

- (void)refuseSpeakRequestWithUser:(BJLUser *)user {
    // 拒绝举手，立即刷新
    BJLError *error = [self.room.speakingRequestVM replySpeakingRequestToUserID:user.ID allowed:NO];
    if (error) {
        [self showError:error];
    }
    else {
        [self.speakRequestUserList removeObject:user];
        [self reloadAllTableViewData];
        [self updateUserListTitle];
    }
}

#pragma mark -

- (void)showError:(BJLError *)error {
    if (error) {
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
        }
    }
}

@end
