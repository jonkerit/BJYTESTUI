//
//  BJLIcUserViewController.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/10/10.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcUserViewController.h"
#import "BJLIcUserTableViewCell.h"
#import "BJLIcUserGroupView.h"

#import "BJLIcUserViewController+private.h"
#import "BJLIcUserViewController+observe.h"
#import "BJLIcUserViewController+action.h"
#import "BJLIcUserViewController+cellAction.h"

NS_ASSUME_NONNULL_BEGIN

/**
 用户列表包括举手列表，上台用户列表，下台用户，黑名单列表，对应四个 tableview
 在线用户列表不会显示，显示的是台上和台下，以及黑名单的用户列表，这个列表为了随时处理用户列表相关的事件而保存
 目前的设计四个列表只能同时显示一个，通过按钮的选中状态来决定显示或隐藏，不支持同时显示多个
 */
@interface BJLIcUserViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation BJLIcUserViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
        self.autoAddActiveUserBlackList = [NSMutableSet new];
        self.speakRequestUserList = [NSMutableArray new];
        self.onlineUserList = [NSMutableArray new];
        self.onStageUserList = [NSMutableArray new];
        self.downStageUserList = [NSMutableArray new];
        self.blockedUserList = [NSMutableArray new];
        self.forbidChatUsers = [NSMutableDictionary new];
        self.onStageClassUser = [NSMutableArray new];
        self.downStageClassUser = [NSMutableArray new];
        self.onStageGroupUserDic = [NSMutableDictionary new];
        self.downStageGroupUserDic = [NSMutableDictionary new];
        self.onStageSelectedGroupID = 0;
        self.downStageSelectedGroupID = 0;
        [self makeObserving];
    }
    return self;
}

- (void)dealloc {
    self.speakRequestTableView.delegate = nil;
    self.speakRequestTableView.dataSource = nil;
    self.onStageTableView.delegate = nil;
    self.onStageTableView.dataSource = nil;
    self.downStageTableView.delegate = nil;
    self.downStageTableView.dataSource = nil;
    self.blockedTableView.delegate = nil;
    self.blockedTableView.dataSource = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self makeSubviewsAndConstraints];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.backgroundView bjlic_drawRectCorners:UIRectCornerTopRight | UIRectCornerBottomRight cornerRadii:CGSizeMake(5.0, 5.0)];
    [self.backgroundView bjlic_drawBorderWidth:1.0 borderColor:[UIColor colorWithWhite:1.0 alpha:0.05] corners:UIRectCornerTopRight | UIRectCornerBottomRight cornerRadii:CGSizeMake(5.0, 5.0)];
    [self reloadAllTableViewData];
    [self updateUserListTitle];
    
    if (self.speakRequestUserList.count > 0) {
        [self switchToSpeakRequestView];
    }
}

#pragma mark - subviews

- (void)makeSubviewsAndConstraints {
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    // contentView 的shadow效果
    self.backgroundView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, backgroundView);
        view.backgroundColor = [UIColor clearColor];
        view.layer.masksToBounds = NO;
        view.layer.shadowOpacity = 0.2;
        view.layer.shadowColor = [UIColor blackColor].CGColor;
        view.layer.shadowOffset = CGSizeMake(0.0, 4.0);
        view.layer.shadowRadius = 10.0;
        view;
    });
    [self.view addSubview:self.backgroundView];
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        BOOL isIphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
        if (isIphone) {
            make.top.left.equalTo(self.view).offset(BJLIcAppearance.userViewMediumSpace);
            make.bottom.right.equalTo(self.view).offset(-BJLIcAppearance.userViewMediumSpace);
        }
        else {
            CGFloat width = [UIScreen mainScreen].bounds.size.width * BJLIcAppearance.userViewIpadWidthFraction;
            CGFloat height = [UIScreen mainScreen].bounds.size.height * BJLIcAppearance.userViewIpadHeightFraction;
            make.center.equalTo(self.view);
            make.size.equal.sizeOffset(CGSizeMake(width, height));
        }
    }];
    
    self.contentView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, contentView);
        view.backgroundColor = BJLIcTheme.windowBackgroundColor;
        view.layer.cornerRadius = 4.0;
        view.layer.masksToBounds = YES;
        view;
    });
    [self.backgroundView addSubview:self.contentView];
    [self.contentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.backgroundView);
    }];
    
    // shadow line
    UIView *firstSingleLine = [UIView bjlic_createSeparateLine];
    firstSingleLine.accessibilityLabel = @"firstSingleLine";
    [self.contentView addSubview:firstSingleLine];
    // 因为设置了不裁切, 所以左右在设置约束的时候减少 1.0, 使得显示时不会到达边界
    [firstSingleLine bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(1.0);
        make.right.equalTo(self.contentView).offset(-1.0);
        make.top.equalTo(self.contentView).offset(BJLIcAppearance.userCellButtonSize);
        make.height.equalTo(@(0.5));
    }];
    
    // title
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"用户列表";
        label.accessibilityLabel = BJLKeypath(self, titleLabel);
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = BJLIcTheme.viewTextColor;
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self.contentView addSubview:self.titleLabel];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(BJLIcAppearance.userViewLargeSpace);
        make.top.equalTo(self.contentView);
        make.bottom.equalTo(firstSingleLine);
    }];
    // close
    UIButton *closeButton = ({
        UIButton *button = [BJLImageButton new];
        button.accessibilityLabel = @"closeButton";
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"window_close"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.contentView addSubview:closeButton];
    [closeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.contentView).offset(-10);
        make.centerY.equalTo(self.titleLabel);
        make.height.equalTo(@(24));
        make.width.equalTo(closeButton.bjl_height);
    }];
    
    // shadow line
    UIView *secondSingleLine = [UIView bjlic_createSeparateLine];
    [self.contentView addSubview:secondSingleLine];
    secondSingleLine.accessibilityLabel = @"secondSingleLine";
    // 因为设置了不裁切, 所以左右在设置约束的时候减少 1.0, 使得显示时不会到达边界
    [secondSingleLine bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(1.0);
        make.right.equalTo(self.contentView).offset(-1.0);
        make.top.equalTo(firstSingleLine.bjl_bottom).offset(36.0);
        make.height.equalTo(@(0.5));
    }];
    
    // all users
    self.allUsersButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.accessibilityLabel = BJLKeypath(self, allUsersButton);
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 12.0;
        [button setTitle:@"全部成员" forState:UIControlStateNormal];
        [button setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [button.titleLabel setFont:[UIFont systemFontOfSize:12.0]];
        button.layer.borderColor = BJLIcTheme.buttonBorderColor.CGColor;
        button.layer.borderWidth = 1.0;
        [button addTarget:self action:@selector(switchToOnlineUserView) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.contentView addSubview:self.allUsersButton];
    [self.allUsersButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.contentView).offset(BJLIcAppearance.userViewLargeSpace);
        make.top.equalTo(firstSingleLine.bjl_bottom).offset(BJLIcAppearance.userViewSmallSpace);
        make.bottom.equalTo(secondSingleLine.bjl_top).offset(-BJLIcAppearance.userViewSmallSpace);
        make.width.equalTo(@96);
    }];
    
    // hand up
    self.handupButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.accessibilityLabel = BJLKeypath(self, handupButton);
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 12.0;
        [button setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [button setTitle:@"举手" forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont systemFontOfSize:12.0]];
        button.layer.borderColor = BJLIcTheme.buttonBorderColor.CGColor;
        button.layer.borderWidth = 1.0;
        [button addTarget:self action:@selector(switchToSpeakRequestView) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.contentView addSubview:self.handupButton];
    [self.handupButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.allUsersButton.bjl_right).offset(BJLIcAppearance.userViewLargeSpace);
        make.top.bottom.width.equalTo(self.allUsersButton);
    }];
    
    self.handupRedDot = ({
        UILabel *view = [UILabel new];
        view.hidden = YES;
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = 4.0;
        view.backgroundColor = BJLIcTheme.warningColor;
        view.textColor = [UIColor whiteColor];
        view.textAlignment = NSTextAlignmentCenter;
        view.adjustsFontSizeToFitWidth = YES;
        view.font = [UIFont systemFontOfSize:8.0];
        view;
    });
    [self.handupButton addSubview:self.handupRedDot];
    [self.handupRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.handupButton.titleLabel.bjl_top).offset(2);
        make.left.equalTo(self.handupButton.titleLabel.bjl_right);
        make.height.width.equalTo(@8.0);
    }];
    
    // handUp table view
    self.speakRequestTableView = ({
        UITableView *tableView = [UITableView new];
        tableView.accessibilityLabel = BJLKeypath(self, speakRequestTableView);
        tableView.rowHeight = BJLIcAppearance.userTableViewCellHeight;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        tableView.backgroundColor = [UIColor clearColor];
        [tableView registerClass:[BJLIcUserTableViewCell class] forCellReuseIdentifier:BJLIcSpeakRequestUserTableViewCellReuseIdentifier];
        tableView;
    });
    [self.contentView addSubview:self.speakRequestTableView];
    [self.speakRequestTableView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(secondSingleLine.bjl_bottom);
        make.left.right.bottom.equalTo(self.contentView);
    }];
    
    // onStage User Button
    self.onStageHeaderView = ({
        BJLIcUserHeaderView *view = [[BJLIcUserHeaderView alloc] initWithHeaderTppe:BJLIcUserHeaderTypeOnStage];
        view.accessibilityLabel = BJLKeypath(self, onStageHeaderView);
        view.titleLabel.text = @"台上成员";
        bjl_weakify(self);
        [view setExpandCallback:^{
            bjl_strongify(self);
            [self showOnStageList];
        }];
        view;
    });
    [self.contentView addSubview:self.onStageHeaderView];
    [self.onStageHeaderView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.contentView);
        make.top.equalTo(secondSingleLine.bjl_bottom);
        make.height.equalTo(@(BJLIcAppearance.userOptionViewHeight));
    }];
    // onStage table view
    self.onStageTableView = ({
        UITableView *tableView = [UITableView new];
        tableView.accessibilityLabel = BJLKeypath(self, onStageTableView);
        tableView.rowHeight = BJLIcAppearance.userTableViewCellHeight;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        tableView.backgroundColor = [UIColor clearColor];
        [tableView registerClass:[BJLIcUserTableViewCell class] forCellReuseIdentifier:BJLIcOnStageTableViewCellReuseIdentifier];
        tableView;
    });
    [self.contentView addSubview:self.onStageTableView];
    [self.onStageTableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.onStageHeaderView.bjl_bottom);
        make.left.right.equalTo(self.contentView);
        make.bottom.lessThanOrEqualTo(self.contentView.bjl_bottom).offset(-BJLIcAppearance.userOptionViewHeight * 2);
    }];
    // downStage User Button
    self.downStageHeaderView = ({
        BJLIcUserHeaderView *view = [[BJLIcUserHeaderView alloc] initWithHeaderTppe:BJLIcUserHeaderTypeDownStage];
        view.titleLabel.text = @"台下成员";
        view.accessibilityLabel = BJLKeypath(self, downStageHeaderView);
        bjl_weakify(self);
        [view setExpandCallback:^{
            bjl_strongify(self);
            [self showDownStageList];
        }];
        view;
    });
    [self.contentView addSubview:self.downStageHeaderView];
    [self.downStageHeaderView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.contentView);
        make.top.equalTo(self.onStageTableView.bjl_bottom);
        make.height.equalTo(@(BJLIcAppearance.userOptionViewHeight));
    }];
    // downStage table view
    self.downStageTableView = ({
        UITableView *tableView = [UITableView new];
        tableView.accessibilityLabel = BJLKeypath(self, downStageTableView);
        tableView.rowHeight = BJLIcAppearance.userTableViewCellHeight;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        tableView.backgroundColor = [UIColor clearColor];
        [tableView registerClass:[BJLIcUserTableViewCell class] forCellReuseIdentifier:BJLIcDownStageTableViewCellReuseIdentifier];
        tableView;
    });
    [self.contentView addSubview:self.downStageTableView];
    [self.downStageTableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.downStageHeaderView.bjl_bottom);
        make.left.right.equalTo(self.contentView);
        make.bottom.lessThanOrEqualTo(self.contentView.bjl_bottom).offset(-BJLIcAppearance.userOptionViewHeight);;
    }];
    // blocked user button
    self.blockedHeaderView = ({
        BJLIcUserHeaderView *view = [[BJLIcUserHeaderView alloc] initWithHeaderTppe:BJLIcUserHeaderTypeBlockedUser];
        view.accessibilityLabel = BJLKeypath(self, blockedHeaderView);
        view.titleLabel.text = @"黑名单";
        bjl_weakify(self);
        [view setExpandCallback:^{
            bjl_strongify(self);
            [self showBlockedList];
        }];
        [view setFreeBlockedCallback:^{
            bjl_strongify(self);
            [self freeAllBlockedUser];
        }];
        view;
    });
    [self.contentView addSubview:self.blockedHeaderView];
    [self.blockedHeaderView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.contentView);
        make.top.equalTo(self.downStageTableView.bjl_bottom);
        make.height.equalTo(@(BJLIcAppearance.userOptionViewHeight));
    }];
    // blocked table view
    self.blockedTableView = ({
        UITableView *tableView = [UITableView new];
        tableView.accessibilityLabel = BJLKeypath(self, blockedTableView);
        tableView.rowHeight = BJLIcAppearance.userTableViewCellHeight;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        tableView.backgroundColor = [UIColor clearColor];
        [tableView registerClass:[BJLIcUserTableViewCell class] forCellReuseIdentifier:BJLIcBlockedUserTableViewCellReuseIdentifier];
        tableView;
    });
    [self.contentView addSubview:self.blockedTableView];
    [self.blockedTableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.blockedHeaderView.bjl_bottom);
        make.left.right.equalTo(self.contentView);
        make.bottom.lessThanOrEqualTo(self.contentView.bjl_bottom);
    }];
    
    // fire
    [self switchToOnlineUserView];
    [self.onStageHeaderView updateExpand:YES];
}

- (void)switchToOnStageListTableView {
    [self switchToOnStageTableView];
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSString *identifier = [self identifierWithTableView:tableView];
    return [self numberOfSectionsWithIdentifier:identifier];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *identifier = [self identifierWithTableView:tableView];
    return [self groupUserListWithIdentifier:identifier section:section useForUserCount:NO].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = [self identifierWithTableView:tableView];
    BJLIcUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    return cell;
}

#pragma mark - table view delegate

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *identifier = [self identifierWithTableView:tableView];
    return [self viewForHeaderWithIdentifier:identifier section:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *identifier = [self identifierWithTableView:tableView];
    return [self heightForHeaderWithIdentifier:identifier Section:section];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = [self identifierWithTableView:tableView];
    BJLUser *user = [[self groupUserListWithIdentifier:identifier section:indexPath.section useForUserCount:NO] bjl_objectAtIndex:indexPath.row];
    BJLIcUserTableViewCell *userCell = bjl_as(cell, BJLIcUserTableViewCell);
    [userCell updateRoom:self.room parentViewController:self];
    
    BJLUserGroup *groupInfo = nil;
    for (BJLUserGroup *group in self.room.onlineUsersVM.groupList) {
        if (group.groupID == user.groupID) {
            groupInfo = [group copy];
            break;
        }
    }
    
    [userCell updateWithUser:user isPresenter:[self.room.onlineUsersVM.currentPresenter isSameUser:user] groupInfo:groupInfo];
    // !!!:目前学生禁言只能保留在老师本地，服务端没有处理，因此如果老师退出教室，而学生如果没有退出教室，老师重新进入时学生的禁言状态会是错误的
    BOOL forbid = [self.forbidChatUsers bjl_boolForKey:user.number defaultValue:NO];
    [userCell updateChat:!forbid];
    
    if ([user isKindOfClass:[BJLMediaUser class]]) {
        BJLMediaUser *mediaUser = (BJLMediaUser *)user;
        [userCell updateCamera:mediaUser.videoOn];
        [userCell updateMic:mediaUser.audioOn];
    }
    [userCell updateLikeCount:[self.room.roomVM.likeList bjl_integerForKey:user.number]];
    [userCell updateDraw:[self.room.drawingVM.drawingGrantedUserNumbers containsObject:user.number]];
    [userCell updatePPT:[self.room.documentVM.authorizedPPTUserNumbers containsObject:user.number]];
    [userCell updateScreen:[self.room.recordingVM.authorizedScreenShareUserNumbers containsObject:user.number]];
    
    bjl_weakify(self);
    [userCell setCellActionCallback:^(BJLIcUserCellActionType type, BJLUser * _Nonnull user, BOOL boolValue) {
        bjl_strongify(self);
        [self cellActionType:type user:user boolValue:boolValue];
    }];
    [userCell setMutableAwardsCallback:^(BJLUser * _Nonnull user, NSString * _Nonnull key) {
        bjl_strongify(self);
        [self cellActionMutableAwards:user awardKey:key];
    }];
}

#pragma mark - load more user

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.dragging && !scrollView.decelerating) {
        return;
    }
    // 只有台下用户列表会存在更多用户的情况
    if (self.room.onlineUsersVM.hasMoreOnlineUsers
        && [self atTheBottomOfTableView]
        && !self.downStageTableView.hidden) {
        [self.room.onlineUsersVM loadMoreOnlineUsersWithCount:20];
    }
}

- (BOOL)atTheBottomOfTableView {
    UITableView *tableView = self.speakRequestTableView;
    if (!self.onStageTableView.hidden) {
        tableView = self.onStageTableView;
    }
    else if (!self.downStageTableView.hidden) {
        tableView = self.downStageTableView;
    }
    else if (!self.blockedTableView.hidden) {
        tableView = self.blockedTableView;
    }
    CGFloat contentOffsetY = tableView.contentOffset.y;
    CGFloat bottom = tableView.contentInset.bottom;
    CGFloat viewHeight = CGRectGetHeight(tableView.frame);
    CGFloat contentHeight = tableView.contentSize.height;
    CGFloat bottomOffset = contentOffsetY + viewHeight - bottom - contentHeight;
    return bottomOffset >= 0.0 - BJLIcAppearance.userTableViewCellHeight;
}

#pragma mark - wheel

- (nullable NSString *)identifierWithTableView:(UITableView *)tableView {
    if (tableView == self.speakRequestTableView) {
        return BJLIcSpeakRequestUserTableViewCellReuseIdentifier;
    }
    else if (tableView == self.onStageTableView) {
        return BJLIcOnStageTableViewCellReuseIdentifier;
    }
    else if (tableView == self.downStageTableView) {
        return BJLIcDownStageTableViewCellReuseIdentifier;
    }
    else if (tableView == self.blockedTableView) {
        return BJLIcBlockedUserTableViewCellReuseIdentifier;
    }
    else {
        return nil;
    }
}

- (NSUInteger)numberOfSectionsWithIdentifier:(nullable NSString *)identifier {
    NSUInteger number = 0;
    if ([identifier isEqualToString:BJLIcSpeakRequestUserTableViewCellReuseIdentifier]) {
        number = 1;
    }
    else if ([identifier isEqualToString:BJLIcOnStageTableViewCellReuseIdentifier]) {
        number = 1 + [self.groupList count];
    }
    else if ([identifier isEqualToString:BJLIcDownStageTableViewCellReuseIdentifier]) {
        number = 1 + [self.groupList count];
    }
    else if ([identifier isEqualToString:BJLIcOnlineUserTableViewCellReuseIdentifier]) {
        number = 1;
    }
    else if ([identifier isEqualToString:BJLIcBlockedUserTableViewCellReuseIdentifier]) {
        number = 1;
    }
    return number;
}

- (NSArray<BJLUser *> *)userListWithIdentifier:(nullable NSString *)identifier {
    NSArray *array = [NSArray new];
    if ([identifier isEqualToString:BJLIcSpeakRequestUserTableViewCellReuseIdentifier]) {
        array = [self.speakRequestUserList copy];
    }
    else if ([identifier isEqualToString:BJLIcOnStageTableViewCellReuseIdentifier]) {
        array = [self.onStageUserList copy];
    }
    else if ([identifier isEqualToString:BJLIcDownStageTableViewCellReuseIdentifier]) {
        array = [self.downStageUserList copy];
    }
    else if ([identifier isEqualToString:BJLIcOnlineUserTableViewCellReuseIdentifier]) {
        array = [self.onlineUserList copy];
    }
    else if ([identifier isEqualToString:BJLIcBlockedUserTableViewCellReuseIdentifier]) {
        array = [self.blockedUserList copy];
    }
    return array;
}

/*
 useForUserCount 是为了区分 是否为获取这个分组的真实人数， 更新headerView的分组人数信息
 */
- (NSArray<BJLUser *> *)groupUserListWithIdentifier:(nullable NSString *)identifier section:(NSInteger)section useForUserCount:(BOOL)useForUserCount {
    NSArray *array = [NSArray new];
    if ([identifier isEqualToString:BJLIcSpeakRequestUserTableViewCellReuseIdentifier]) {
        array = [self.speakRequestUserList copy];
    }
    else if ([identifier isEqualToString:BJLIcOnStageTableViewCellReuseIdentifier]) {
        if (section == 0) {
            array = [self.onStageClassUser copy];
        }
        else {
            BJLUserGroup *group = [self.groupList bjl_objectAtIndex:section - 1];
            if (self.onStageSelectedGroupID == group.groupID || useForUserCount) {
                array = [[self.onStageGroupUserDic bjl_arrayForKey:@(group.groupID)] copy];
            }
        }
    }
    else if ([identifier isEqualToString:BJLIcDownStageTableViewCellReuseIdentifier]) {
        if (section == 0) {
            array = [self.downStageClassUser copy];
        }
        else {
            BJLUserGroup *group = [self.groupList bjl_objectAtIndex:section - 1];
            if (self.downStageSelectedGroupID == group.groupID || useForUserCount) {
                array = [[self.downStageGroupUserDic bjl_arrayForKey:@(group.groupID)] copy];
            }
        }
    }
    else if ([identifier isEqualToString:BJLIcOnlineUserTableViewCellReuseIdentifier]) {
        array = [self.onlineUserList copy];
    }
    else if ([identifier isEqualToString:BJLIcBlockedUserTableViewCellReuseIdentifier]) {
        array = [self.blockedUserList copy];
    }
    return array;
}

- (CGFloat)heightForHeaderWithIdentifier:(nullable NSString *)identifier Section:(NSInteger)section {
    CGFloat height = 0;
    if ([identifier isEqualToString:BJLIcOnStageTableViewCellReuseIdentifier]) {
        if (section != 0) {
            BJLUserGroup *group = [self.groupList bjl_objectAtIndex:section - 1];
            NSArray *userList = [[self.onStageGroupUserDic bjl_arrayForKey:@(group.groupID)] copy];
            if (userList.count) {
                height = 36;
            }
        }
    }
    else if ([identifier isEqualToString:BJLIcDownStageTableViewCellReuseIdentifier]) {
        if (section != 0) {
            BJLUserGroup *group = [self.groupList bjl_objectAtIndex:section - 1];
            NSArray *userList = [[self.downStageGroupUserDic bjl_arrayForKey:@(group.groupID)] copy];
            if (userList.count) {
                height = 36;
            }
        }
    }
    return height;
}

- (UIView *)viewForHeaderWithIdentifier:(nullable NSString *)identifier section:(NSInteger)section {
    if ([identifier isEqualToString:BJLIcOnStageTableViewCellReuseIdentifier]) {
        if (section != 0) {
            BJLIcUserGroupView *groupView = [BJLIcUserGroupView new];
            BJLUserGroup *group = [self.groupList bjl_objectAtIndex:section - 1];
            NSInteger userCount = [self groupUserListWithIdentifier:identifier section:section useForUserCount:YES].count;
            NSInteger groupAwardCount = [self.room.roomVM.grouplikeList bjl_integerForKey:@(group.groupID)];
            [groupView updateWithGroupInfo:group
                                 userCount:userCount
                           groupAwardCount:groupAwardCount
                               shouldClose:(group.groupID != self.onStageSelectedGroupID)];
            bjl_weakify(self);
            [groupView setClickCallback:^(BOOL show) {
                bjl_strongify(self);
                if (show) {
                    self.onStageSelectedGroupID = group.groupID;
                }
                else {
                    self.onStageSelectedGroupID = 0;
                }
                [self reloadAllTableViewData];
            }];
            return groupView;
        }
    }
    else if ([identifier isEqualToString:BJLIcDownStageTableViewCellReuseIdentifier]) {
        if (section != 0) {
            BJLIcUserGroupView *groupView = [BJLIcUserGroupView new];
            BJLUserGroup *group = [self.groupList bjl_objectAtIndex:section - 1];
            NSInteger count = [self groupUserListWithIdentifier:identifier section:section useForUserCount:YES].count;
            NSInteger groupAwardCount = [self.room.roomVM.grouplikeList bjl_integerForKey:@(group.groupID)];
            [groupView updateWithGroupInfo:group
                                 userCount:count
                           groupAwardCount:groupAwardCount
                               shouldClose:(group.groupID != self.downStageSelectedGroupID)];
            bjl_weakify(self);
            [groupView setClickCallback:^(BOOL show) {
                bjl_strongify(self);
                if (show) {
                    self.downStageSelectedGroupID = group.groupID;
                }
                else {
                    self.downStageSelectedGroupID = 0;
                }
                [self reloadAllTableViewData];
            }];
            return groupView;
        }
    }
    return [UIView new];
}

@end

NS_ASSUME_NONNULL_END

