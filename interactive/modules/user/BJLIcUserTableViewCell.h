//
//  BJLIcUserTableViewCell.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/10/25.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString
* const BJLIcOnStageTableViewCellReuseIdentifier,
* const BJLIcDownStageTableViewCellReuseIdentifier,
* const BJLIcBlockedUserTableViewCellReuseIdentifier,
* const BJLIcOnlineUserTableViewCellReuseIdentifier,
* const BJLIcSpeakRequestUserTableViewCellReuseIdentifier;

typedef NS_ENUM(NSInteger, BJLIcUserCellActionType) {
    BJLIcUserCellActionTypeReward      = 10,  // 奖励
    BJLIcUserCellActionTypeCamera      = 11,  // 摄像头
    BJLIcUserCellActionTypeMic         = 12,  // 麦克风
    BJLIcUserCellActionTypeDraw        = 13,  // 画笔
    BJLIcUserCellActionTypePPT         = 14,  // ppt
    BJLIcUserCellActionTypeForbidChat  = 15,  // 聊天禁言
    BJLIcUserCellActionTypeScreenShare = 16,  // 屏幕分享
    BJLIcUserCellActionTypeGoOnStage   = 17,  // 上台
    BJLIcUserCellActionTypeGoDownStage = 18,  // 上台
    BJLIcUserCellActionTypeBlocked     = 19,  // 拉黑
     
    BJLIcUserCellActionTypeFreeBlocked = 30,  // 解除黑名单
    
    BJLIcUserCellActionTypeAllowSpeak  = 40,  // 同意发言
    BJLIcUserCellActionTypeRefuseSpeak = 41,  // 拒绝发言
};

@interface BJLIcUserTableViewCell : UITableViewCell

/// 更新cell绑定的数据
/// #param user user description
/// #param isPresenter 是否为主讲
/// #param groupInfo 分组信息
- (void)updateWithUser:(BJLUser *)user isPresenter:(BOOL)isPresenter groupInfo:(nullable BJLUserGroup *)groupInfo;

/// 操作cell的一些回调
@property (nonatomic, nullable) void (^cellActionCallback)(BJLIcUserCellActionType type, BJLUser *user, BOOL boolValue);

/// 多种奖励方式的回调
@property (nonatomic, nullable) void (^mutableAwardsCallback)(BJLUser *user, NSString *key);

/// 更新点赞数
- (void)updateLikeCount:(NSInteger)likeCount;

/// 摄像头是否打开
- (void)updateCamera:(BOOL)isOn;

/// 麦克风是否打开
- (void)updateMic:(BOOL)isOn;

/// 是否被授权画笔
- (void)updateDraw:(BOOL)isGranted;

/// 是否被授权ppt
- (void)updatePPT:(BOOL)isAuthorized;

/// 是否允许聊天
- (void)updateChat:(BOOL)isAllow;

/// 是否分享屏幕
- (void)updateScreen:(BOOL)isShared;

/// 接受举手, 打开音视频
@property (nonatomic, nullable) void (^allowSpeakRequestCallback)(BJLUser *user);

/// 拒绝举手，关闭音视频
@property (nonatomic, nullable) void (^refuseSpeakRequestCallback)(BJLUser *user);

/// 上台, 允许视频区显示该用户的视频或者占位图
@property (nonatomic, nullable) void (^goOnStageCallback)(BJLUser *user);

/// 下台, 移除视频区该用户的视频或占位图
@property (nonatomic, nullable) void (^goDownStageCallback)(BJLUser *user);

/// 禁止聊天
@property (nonatomic, nullable) void (^forbidChatCallback)(BJLUser *user, BOOL forbid);

/// 踢出教室
@property (nonatomic, nullable) void (^blockUserCallback)(BJLUser *user);

/// 解除黑名单
@property (nonatomic, nullable) void (^freeBlockedUserCallback)(BJLUser *user);

#pragma mark -

- (void)updateRoom:(BJLRoom *)room parentViewController:(__kindof UIViewController *)parentViewController;

- (void)hideAwardsViewController;

@end

NS_ASSUME_NONNULL_END
