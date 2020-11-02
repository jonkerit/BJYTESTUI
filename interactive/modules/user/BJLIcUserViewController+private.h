//
//  BJLIcUserViewController+private.h
//  BJLiveUI
//
//  Created by 辛亚鹏 on 2020/6/11.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcUserViewController.h"
#import "BJLIcAppearance.h"
#import "BJLIcTheme.h"
#import "BJLIcUserHeaderView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserViewController ()

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) NSMutableSet<NSString *> *autoAddActiveUserBlackList;
@property (nonatomic) NSMutableArray<BJLUser *> *speakRequestUserList;
@property (nonatomic) NSMutableArray<BJLUser *> *onlineUserList;
@property (nonatomic) NSMutableArray<BJLMediaUser *> *onStageUserList;
@property (nonatomic) NSMutableArray<BJLUser *> *downStageUserList;
@property (nonatomic) NSMutableArray<BJLUser *> *blockedUserList;
@property (nonatomic) NSMutableDictionary<NSString *, NSNumber *> *forbidChatUsers;

// 用户列表分区未分组的用户`StageClassUser`, 和分组的用户`StageGroupUserDic`
@property (nonatomic, nullable) NSArray <BJLMediaUser *> *onStageClassUser;
@property (nonatomic, nullable) NSArray <BJLUser *> *downStageClassUser;
@property (nonatomic, nullable) NSDictionary <NSNumber *, NSArray<BJLMediaUser *> *> *onStageGroupUserDic;
@property (nonatomic, nullable) NSDictionary <NSNumber *, NSArray<BJLUser *> *> *downStageGroupUserDic;
//教室内小组信息(不包含0分组信息)
@property (nonatomic, nullable) NSArray <BJLUserGroup *> *groupList;
@property (nonatomic) NSInteger onStageSelectedGroupID, downStageSelectedGroupID;

@property (nonatomic) UIView *contentView;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UITableView *speakRequestTableView;
@property (nonatomic) UIButton *allUsersButton, *handupButton;
@property (nonatomic) UILabel *handupRedDot;
@property (nonatomic) BJLIcUserHeaderView *onStageHeaderView;
@property (nonatomic) UITableView *onStageTableView;
@property (nonatomic) BJLIcUserHeaderView *downStageHeaderView;
@property (nonatomic) UITableView *downStageTableView;
@property (nonatomic) BJLIcUserHeaderView *blockedHeaderView;
@property (nonatomic) UITableView *blockedTableView;

@end

NS_ASSUME_NONNULL_END
