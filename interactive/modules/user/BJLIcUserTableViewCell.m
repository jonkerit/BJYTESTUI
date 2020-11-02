//
//  BJLIcUserTableViewCell.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/10/25.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcUserTableViewCell.h"
#import "BJLIcAppearance.h"
#import "BJLMutableAwardsView.h"

NS_ASSUME_NONNULL_BEGIN

NSString
* const BJLIcOnStageTableViewCellReuseIdentifier = @"kIcOnStageTableViewCellReuseIdentifier",
* const BJLIcDownStageTableViewCellReuseIdentifier = @"kIcDownStageTableViewCellReuseIdentifier",
* const BJLIcBlockedUserTableViewCellReuseIdentifier = @"kIcBlockedUserTableViewCellReuseIdentifier",
* const BJLIcOnlineUserTableViewCellReuseIdentifier = @"kIcOnlineUserTableViewCellReuseIdentifier",
* const BJLIcSpeakRequestUserTableViewCellReuseIdentifier = @"kIcSpeakRequestUserTableViewCellReuseIdentifier";

@interface BJLIcUserTableViewCell () <UIPopoverPresentationControllerDelegate>

@property (nonatomic) BJLUser *user;
@property (nonatomic) UILabel *userNameLabel, *roleLabel;
@property (nonatomic) UIStackView *stackView;
@property (nonatomic) UIView *lineView;

@property (nonatomic) UILabel *groupColorLabel, *groupNameLabel;

@property (nonatomic) BJLButton
*rewardButton,             // 奖励按钮
*cameraButton,             // 摄像头操作按钮
*micButton,                // 麦克风操作按钮
*drawButton,               // 授权画笔按钮
*pptButton,                // 授权ppt按钮
*forbidChatButton,         // 禁止/允许发言
*screenShareButton,        // 屏幕分享
*goOnStageButton,          // 上台
*goDownStageButton,        // 下台
*blockUserButton,          // 拉黑
   
*freeBlockedUserButton,    // 解除黑名单

*allowSpeakRequestButton,  // 允许发言
*refuseSpeakRequestButton; // 拒绝发言

@property (nonatomic) UIViewController *awardsViewController;
@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic, weak) UIViewController *parentViewController;

@end

@implementation BJLIcUserTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self hideAwardsViewController];
}

- (void)updateRoom:(BJLRoom *)room parentViewController:(__kindof UIViewController *)parentViewController {
    self.room = room;
    self.parentViewController = parentViewController;
    if (self.awardsViewController) {
        [self hideAwardsViewController];
    }
}

#pragma mark - update

- (void)updateWithUser:(BJLUser *)user isPresenter:(BOOL)isPresenter groupInfo:(nullable BJLUserGroup *)groupInfo {
    self.user = user;
    self.userNameLabel.text = user.displayName;
    
    // 下台列表显示上台按钮
    BOOL downStageCell = [self.reuseIdentifier isEqualToString:BJLIcDownStageTableViewCellReuseIdentifier];
    // 上台列表显示下台按钮
    BOOL onStageCell = [self.reuseIdentifier isEqualToString:BJLIcOnStageTableViewCellReuseIdentifier];
    // 举手列表显示同意和拒绝，不显示禁言和踢出教室
    BOOL handUpCell = [self.reuseIdentifier isEqualToString:BJLIcSpeakRequestUserTableViewCellReuseIdentifier];
    // 黑名单仅显示取消踢出用户
    BOOL blockUserCell = [self.reuseIdentifier isEqualToString:BJLIcBlockedUserTableViewCellReuseIdentifier];

    for (UIButton *button in self.stackView.arrangedSubviews.copy) {
        [self.stackView removeArrangedSubview:button];
    }
    
    if (blockUserCell) {
        [self remakeConstraintsWithButtons:@[self.freeBlockedUserButton]];
    }
    else if (handUpCell) {
        [self remakeConstraintsWithButtons:@[self.allowSpeakRequestButton, self.refuseSpeakRequestButton]];
    }
    else if (onStageCell) {
        [self createStackView:[self stageSubViewsArray:YES]];
    }
    else if (downStageCell) {
        [self createStackView:[self stageSubViewsArray:NO]];
    }
    
    // 老师不显示 stackView
    if (user.isTeacher) {
        self.stackView.hidden = YES;
    }
    // 助教: 显示角色label && stackView里 只显示点赞 和上下台
    if (user.isAssistant) {
        self.roleLabel.hidden = NO;
        self.roleLabel.text = @"助教";
        self.roleLabel.backgroundColor = [BJLIcTheme userCellRoleAssistantColor];
        [self reCreateStackViewButtonsForAssistant];
        [self makeNameLabelConstraintsWithRoleLabelHidden:NO];
    }
    // 主讲: 显示主讲角色
    else if (isPresenter) {
        self.roleLabel.hidden = NO;
        self.roleLabel.text = @"主讲";
        self.roleLabel.backgroundColor = [BJLIcTheme userCellRolePresenterColor];
        [self makeNameLabelConstraintsWithRoleLabelHidden:NO];
    }
    else {
        self.roleLabel.hidden = YES;
        [self makeNameLabelConstraintsWithRoleLabelHidden:YES];
        for (UIButton *button in self.stackView.arrangedSubviews) {
            button.userInteractionEnabled = YES;
        }
    }
    
    if (handUpCell) {
        [self.userNameLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.contentView).offset(BJLIcAppearance.userViewMaxSpace);
            make.centerY.equalTo(self.contentView);
            make.right.equalTo(self.groupColorLabel).offset(-BJLIcAppearance.userViewLargeSpace);
        }];
    }
    
    self.groupColorLabel.hidden = !handUpCell;
    self.groupNameLabel.hidden = !handUpCell;
    if (groupInfo.color.length) {
        self.groupColorLabel.backgroundColor = [UIColor bjl_colorWithHexString:groupInfo.color];
    }
    else {
        self.groupColorLabel.backgroundColor = [UIColor clearColor];
    }

    self.groupNameLabel.text = groupInfo.name;
}

#pragma mark - subviews

- (void)makeSubviewsAndConstraints {
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.userNameLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 1;
        label.textColor = BJLIcTheme.viewTextColor;
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self.contentView addSubview:self.userNameLabel];
    
    self.roleLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 1;
        label.hidden = YES;
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:10.0];
        label.layer.cornerRadius = 2.0;
        label.layer.masksToBounds = YES;
        label;
    });
    [self.contentView addSubview:self.roleLabel];
    [self makeNameLabelConstraintsWithRoleLabelHidden:YES];
    
    self.groupColorLabel = ({
        UILabel *label = [UILabel new];
        label.layer.cornerRadius = 6.0;
        label.layer.masksToBounds = YES;
        label.hidden = YES;
        label.accessibilityLabel = BJLKeypath(self, groupColorLabel);
        bjl_return label;
    });
    [self.contentView addSubview:self.groupColorLabel];
    [self.groupColorLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.contentView).offset(-BJLIcAppearance.chatViewSmallSpace);
        make.centerY.equalTo(self.contentView);
        make.size.equal.sizeOffset(CGSizeMake(12.0, 12.0));
    }];

    self.groupNameLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"--";
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = BJLIcTheme.viewTextColor;
        label.hidden = YES;
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, groupNameLabel);
        bjl_return label;
    });
    [self.contentView addSubview:self.groupNameLabel];
    [self.groupNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.groupColorLabel.bjl_right).offset(BJLIcAppearance.chatViewSmallSpace);
        make.centerY.equalTo(self.contentView);
        make.right.equalTo(self.contentView).offset(-BJLIcAppearance.chatViewLargeSpace);
    }];
    
    // line view
    self.lineView = [UIView bjlic_createSeparateLine];
    [self.contentView addSubview:self.lineView];
    [self.lineView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.contentView).offset(BJLIcAppearance.chatViewMediumSpace);
        make.right.equalTo(self.contentView).offset(-BJLIcAppearance.chatViewMediumSpace);
        make.bottom.equalTo(self.contentView);
        make.height.equalTo(@0.5);
    }];
    
    // 创建stackview上的button
    [self createStackViewButtons];
    
    self.freeBlockedUserButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_lock"] selectedImage:nil disableImage:nil];
    
    self.allowSpeakRequestButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_allow"] selectedImage:nil disableImage:nil];
    
    self.refuseSpeakRequestButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_refuse"] selectedImage:nil disableImage:nil];
                
    NSArray *array;
    if ([self.reuseIdentifier isEqualToString:BJLIcSpeakRequestUserTableViewCellReuseIdentifier]) {
         array = @[self.allowSpeakRequestButton, self.refuseSpeakRequestButton];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcBlockedUserTableViewCellReuseIdentifier]) {
        array = @[self.freeBlockedUserButton];
    }
    
    for (UIButton *button in array) {
        [self.contentView addSubview:button];
    }
    [self remakeConstraintsWithButtons:array];
}


- (NSArray <UIButton *> *)stageSubViewsArray:(BOOL)isOnStage {
    NSArray *array;
    [self createStackViewButtons];
    if (isOnStage) {
        array = @[self.rewardButton, self.cameraButton, self.micButton, self.drawButton, self.pptButton, self.forbidChatButton, self.screenShareButton, self.goDownStageButton, self.blockUserButton];
    }
    else {
        array = @[self.rewardButton, self.drawButton, self.pptButton, self.forbidChatButton, self.screenShareButton, self.goOnStageButton, self.blockUserButton];
    }
    return array;
}

- (void)makeNameLabelConstraintsWithRoleLabelHidden:(BOOL)isHidden {
    if (isHidden) {
        [self.userNameLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.contentView).offset(BJLIcAppearance.userViewMaxSpace);
            make.centerY.equalTo(self.contentView);
            make.width.equalTo(@(BJLIcAppearance.userHeaderTitleWidth));
        }];
    }
    else {
        [self.userNameLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.contentView).offset(BJLIcAppearance.userViewMaxSpace);
            make.top.equalTo(self.contentView);
            make.bottom.equalTo(self.contentView.bjl_centerY);
            make.width.equalTo(@(BJLIcAppearance.userHeaderTitleWidth));
        }];
        
        [self.roleLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.userNameLabel);
            make.top.equalTo(self.contentView.bjl_centerY);
            make.bottom.equalTo(self.contentView).offset(-6);
            make.width.equalTo(@36);
        }];
    }
}

- (void)createStackView:(NSArray *)array {
    if (self.stackView) {
        [self.stackView removeFromSuperview];
    }
    self.stackView = ({
        UIStackView *view = [[UIStackView alloc] initWithArrangedSubviews:array];
        view.axis = UILayoutConstraintAxisHorizontal;
        view.distribution = UIStackViewDistributionFillEqually;
        view.alignment = UIStackViewAlignmentCenter;
        view;
    });
    [self.contentView addSubview:self.stackView];
    [self.stackView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.userNameLabel.bjl_right).offset(BJLIcAppearance.userViewMaxSpace);
        make.top.bottom.right.equalTo(self.contentView);
    }];
}

- (void)createStackViewButtons {
    if ([BJLAward allAwards].count > 1) {
        self.rewardButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_award"]
                                        selectedImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_award"]
                                         disableImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_award_disable"]];
    }
    else {
        self.rewardButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_reward_normal"]
                                        selectedImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_reward_normal"]
                                         disableImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_reward_normal_disable"]];
    }

    self.rewardButton.midSpace = 3;
    
    [self.rewardButton setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateNormal];
    self.rewardButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
    
    self.cameraButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_camera_noraml"]
                                     selectedImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_camera_selected"]
                                     disableImage:nil];
    
    self.micButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_mic_noraml"]
                                 selectedImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_mic_selected"]
                                  disableImage:nil];
    
    self.drawButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_draw_noramal"]
                                  selectedImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_draw_selected"]
                                   disableImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_draw_disable"]];
    
    self.pptButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_ppt_normal"]
                                 selectedImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_ppt_selected"]
                                  disableImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_ppt_disable"]];
    
    self.forbidChatButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_forbid_normal"]
                                        selectedImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_forbid_selected"]
                                         disableImage:nil];
    
    self.screenShareButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_screen_normal"]
                                         selectedImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_screen_selected"]
                                          disableImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_screen_disable"]];
    
    self.goOnStageButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_onstage_selected"]
                                       selectedImage:nil
                                        disableImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_onstage_disable"]];
    
    self.goDownStageButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_downstage_selected"]
                                         selectedImage:nil disableImage:nil];
    
    self.blockUserButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_cell_blocked"]
                                       selectedImage:nil disableImage:nil];
    
    // h5端进入的用户, 以下按钮不可用
    BOOL enabled = (self.user.clientType != BJLClientType_MobileWeb);
    
    self.rewardButton.enabled      = enabled;
    self.drawButton.enabled        = enabled;
    self.pptButton.enabled         = enabled;
    self.screenShareButton.enabled = enabled;
    self.goOnStageButton.enabled   = enabled;
}

- (void)reCreateStackViewButtonsForAssistant {
    for (UIButton *button in self.stackView.subviews) {
        if ([button isEqual:self.cameraButton] || [button isEqual:self.micButton] || [button isEqual:self.goOnStageButton] || [button isEqual:self.goDownStageButton]) {
            // 只保留 cameraButton micButton goOnStageButton goDownStageButton
        }
        else {
            [button setImage:nil forState:UIControlStateNormal];
            [button setImage:nil forState:UIControlStateSelected];
            [button setImage:nil forState:UIControlStateHighlighted];
            [button setImage:nil forState:UIControlStateDisabled];
            button.userInteractionEnabled = NO;
        }
    }
}

#pragma mark - public method

- (void)updateLikeCount:(NSInteger)likeCount {
//    老师助教不被点赞
    if (self.user.isTeacherOrAssistant) {
        return;
    }
    
    NSString *count = [NSString stringWithFormat:@"%ld", (long)likeCount];
    for (UIButton *button in self.stackView.arrangedSubviews) {
        if ([button isEqual:self.rewardButton]) {
            [button setTitle:count forState:UIControlStateNormal];
            
            // H5端用户, 颜色设置为9FA8B5
            if (BJLClientType_MobileWeb == self.user.clientType) {
                [button setTitleColor:BJLIcTheme.separateLineColor forState:UIControlStateNormal];
            }
            else {
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            }
            break;
        }
    }
}

- (void)updateCamera:(BOOL)isOn {
    if (self.cameraButton.enabled) {        
        self.cameraButton.selected = !isOn;
    }
}

- (void)updateMic:(BOOL)isOn {
    if (self.micButton.enabled) {
        self.micButton.selected = !isOn;
    }
}

- (void)updateDraw:(BOOL)isGranted {
    if (self.drawButton.enabled) {
        self.drawButton.selected = !isGranted;
    }
}

- (void)updatePPT:(BOOL)isAuthorized {
    if (self.pptButton.enabled) {
        self.pptButton.selected = !isAuthorized;
    }
}

- (void)updateChat:(BOOL)isAllow {
    if (self.forbidChatButton.enabled) {
        self.forbidChatButton.selected = !isAllow;
    }
}

- (void)updateScreen:(BOOL)isShared {
    if (self.screenShareButton.enabled) {
        self.screenShareButton.selected = !isShared;
    }
}

#pragma mark - actions

- (void)cellAction:(UIButton *)button {
    if (!self.cellActionCallback) {
        return;
    }
    
    // 从 normal -> selected,需要执行关闭的操作
    // 从 selected -> normal, 需要执行开启的操作
    BOOL boolValueOff = button.selected;
    
    if ([button isEqual:self.rewardButton]) {
        if ([BJLAward allAwards].count > 1) {
            [self showMutableAwards];
        }
        else {
            self.cellActionCallback(BJLIcUserCellActionTypeReward, self.user, NO);
        }
    }
    else if ([button isEqual:self.cameraButton]) {
        if (self.user.isTeacher) {
            return;
        }
        self.cellActionCallback(BJLIcUserCellActionTypeCamera, self.user, boolValueOff);
    }
    else if ([button isEqual:self.micButton]) {
        if (self.user.isTeacher) {
            return;
        }
        self.cellActionCallback(BJLIcUserCellActionTypeMic, self.user, boolValueOff);
    }
    else if ([button isEqual:self.drawButton]) {
        if (self.user.isTeacher) {
            return;
        }
        self.cellActionCallback(BJLIcUserCellActionTypeDraw, self.user, boolValueOff);
    }
    else if ([button isEqual:self.pptButton]) {
        if (self.user.isTeacher) {
            return;
        }
        self.cellActionCallback(BJLIcUserCellActionTypePPT, self.user, boolValueOff);
    }
    else if ([button isEqual:self.forbidChatButton]) {
        if (self.user.isTeacher) {
            return;
        }
        self.cellActionCallback(BJLIcUserCellActionTypeForbidChat, self.user, boolValueOff);
    }
    else if ([button isEqual:self.screenShareButton]) {
        if (self.user.isTeacher) {
            return;
        }
        self.cellActionCallback(BJLIcUserCellActionTypeScreenShare, self.user, boolValueOff);
    }
    else if ([button isEqual:self.goOnStageButton]) {
        self.cellActionCallback(BJLIcUserCellActionTypeGoOnStage, self.user, NO);
    }
    else if ([button isEqual:self.goDownStageButton]) {
        self.cellActionCallback(BJLIcUserCellActionTypeGoDownStage, self.user, NO);
    }
    else if ([button isEqual:self.blockUserButton]) {
        self.cellActionCallback(BJLIcUserCellActionTypeBlocked, self.user, NO);
    }
    else if ([button isEqual:self.freeBlockedUserButton]) {
        self.cellActionCallback(BJLIcUserCellActionTypeFreeBlocked, self.user, NO);
    }
    else if ([button isEqual:self.allowSpeakRequestButton]) {
        self.cellActionCallback(BJLIcUserCellActionTypeAllowSpeak, self.user, NO);
    }
    else if ([button isEqual:self.refuseSpeakRequestButton]) {
        self.cellActionCallback(BJLIcUserCellActionTypeRefuseSpeak, self.user, NO);
    }
}

- (void)blockUser {
    if (self.user.isTeacher) {
        return;
    }
    if (self.blockUserCallback) {
        self.blockUserCallback(self.user);
    }
}

- (void)freeBlockedUser {
    if (self.freeBlockedUserCallback) {
        self.freeBlockedUserCallback(self.user);
    }
}

- (void)showMutableAwards {
    BJLMutableAwardsView *mutableAwardsView = [[BJLMutableAwardsView alloc] initWithRoom:self.room user:self.user];
    
    self.awardsViewController = ({
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view.backgroundColor = [UIColor clearColor];
        viewController.modalPresentationStyle = UIModalPresentationPopover;
        viewController.preferredContentSize = mutableAwardsView.size;
        viewController.popoverPresentationController.backgroundColor = BJLIcTheme.toolboxBackgroundColor;
        viewController.popoverPresentationController.delegate = self;
        viewController.popoverPresentationController.sourceView = self;
        CGPoint rewardPoint = [self.stackView convertPoint:self.rewardButton.center toView:self.contentView];
        viewController.popoverPresentationController.sourceRect = CGRectMake(rewardPoint.x, rewardPoint.y, 1.0, 1.0);
        viewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionDown | UIPopoverArrowDirectionUp;
        viewController;
    });
    
    [self.awardsViewController.view addSubview:mutableAwardsView];
    [mutableAwardsView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.awardsViewController.view.bjl_safeAreaLayoutGuide ?: self.awardsViewController.view);
    }];
    
    bjl_weakify(self);
    [mutableAwardsView setAwardKeyCallback:^(NSString * _Nonnull key) {
        bjl_strongify(self);
        [self hideAwardsViewController];
        if (self.mutableAwardsCallback) {
            self.mutableAwardsCallback(self.user, key);
        }
    }];
    
    [self.parentViewController presentViewController:self.awardsViewController animated:YES completion:nil];
}

- (void)hideAwardsViewController {
    [self.awardsViewController bjl_dismissAnimated:YES completion:nil];
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

#pragma mark - wheel

- (BJLButton *)makeButtonWithImage:(UIImage *)image selectedImage:(nullable UIImage *)selectedImage disableImage:(nullable UIImage *)disableImage {
//    UIButton *button = [BJLImageButton new];
    BJLButton *button = [BJLButton buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:selectedImage forState:UIControlStateSelected];
    [button setImage:selectedImage forState:UIControlStateHighlighted];
    [button setImage:disableImage forState:UIControlStateDisabled];
    [button addTarget:self action:@selector(cellAction:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)remakeConstraintsWithButtons:(nullable NSArray<UIButton *> *)buttons {
    UIButton *last = nil;
    for (UIButton *button in [buttons reverseObjectEnumerator]) {
        if (button.hidden) {
            continue;
        }
        [button bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            if (last) {
                make.right.equalTo(last.bjl_left).offset(-2*BJLIcAppearance.userViewMaxSpace);
            }
            else {
                make.right.equalTo(self.contentView).offset(-2*BJLIcAppearance.userViewMaxSpace);
            }
            make.centerY.equalTo(self.contentView);
            make.width.height.equalTo(@(BJLIcAppearance.userCellButtonSize));
            
        }];
        last = button;
    }
}

@end

NS_ASSUME_NONNULL_END
