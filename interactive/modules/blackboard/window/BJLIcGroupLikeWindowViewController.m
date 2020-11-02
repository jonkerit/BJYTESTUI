//
//  BJLIcGroupLikeWindowViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/7/20.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcGroupLikeWindowViewController.h"
#import "BJLIcWindowViewController+protected.h"
#import "BJLIcAppearance.h"

@interface BJLIcGroupLikeWindowViewController ()

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) BJLUserGroup *groupInfo;
@property (nonatomic, copy) NSDictionary *groupCountDic;

@property (nonatomic) UIImageView *awardImageView;
@property (nonatomic) UILabel *awardCountLabel;

@property (nonatomic) UIView *groupAwardView, *groupColorView;
@property (nonatomic) UIButton *groupNameButton, *groupAwardCountButton, *groupUserCountButton, *groupRankButton;

@end

@implementation BJLIcGroupLikeWindowViewController

- (instancetype)initWithRoom:(BJLRoom *)room
                   groupInfo:(BJLUserGroup *)group {
    self = [super init];
    if (self) {
        self->_room = room;
        self.groupInfo = group;
        self.groupCountDic = room.onlineUsersVM.groupCountDic;
        [self prepareToOpen];
    }
    return self;
}

- (void)prepareToOpen {
    self.minWindowHeight = 65.0f;
    self.minWindowWidth = 72.0;
    self.fixedAspectRatio = self.minWindowWidth/self.minWindowHeight;

    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);

    CGFloat relativeWidth = self.minWindowWidth / (self.view.superview.frame.size.width ?: (!iPhone ? 1024 : 600.0)) ;
    CGFloat relativeHeight = self.minWindowHeight / (self.view.superview.frame.size.height ?: (!iPhone ? 512 : 300.0)) ;
    self.relativeRect = [self rectInBounds:CGRectMake(0, 0, relativeWidth, relativeHeight)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.topBar.hidden = YES;
    self.bottomBar.hidden = YES;
    self.doubleTapToMaximize = NO;
    self.backgroundView.backgroundColor = [UIColor clearColor];
    [self makeConstraints];
    [self makeObserving];
}

- (void)makeConstraints {
    
    self.awardImageView = ({
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage bjlic_imageNamed:@"bjl_ic_groupAward"]];
        imageView.accessibilityLabel = BJLKeypath(self, awardImageView);
        imageView;
    });
    
    self.awardCountLabel = ({
        UILabel *label = [UILabel new];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentCenter;
        label;
    });
    
    self.groupAwardView = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = BJLIcTheme.windowBackgroundColor;
        view.accessibilityLabel = BJLKeypath(self, groupAwardView);
        view.layer.cornerRadius = BJLIcAppearance.toolboxCornerRadius;
        view.layer.borderWidth = 1.0;
        view.layer.borderColor = [UIColor bjl_colorWithHex:0XDDDDDD alpha:0.1].CGColor;
        view.layer.shadowRadius = BJLIcAppearance.toolboxCornerRadius;
        view.layer.shadowColor = BJLIcTheme.windowShadowColor.CGColor;
        view.layer.shadowOffset = CGSizeMake(0, 0);
        view.layer.shadowOpacity = 0.5;
        view.hidden = YES;
        view;
    });
    
    self.groupColorView = ({
        UIView *colorView = [BJLHitTestView new];
        colorView.accessibilityLabel = BJLKeypath(self, groupColorView);
        colorView.backgroundColor = [UIColor bjl_colorWithHexString:self.groupInfo.color] ?: BJLIcTheme.brandColor;
        colorView.layer.cornerRadius = 6.0;
        colorView.layer.masksToBounds = YES;
        colorView;
    });
    
    self.groupNameButton = [self makeButtonWithImage:nil title:@"--" accessibilityLabel:BJLKeypath(self, groupNameButton)];
    self.groupAwardCountButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_ic_groupAwardCount"] title:self.awardCountLabel.text accessibilityLabel:BJLKeypath(self, groupAwardCountButton)];
    [self.groupAwardCountButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 4, 0, 0)];
    self.groupUserCountButton = [self makeButtonWithImage:nil title:@"小组成员:--" accessibilityLabel:BJLKeypath(self, groupUserCountButton)];
    self.groupRankButton = [self makeButtonWithImage:nil title:@"小组排名:--" accessibilityLabel:BJLKeypath(self, groupRankButton)];
    
    [self.view addSubview:self.awardImageView];
    [self.view addSubview:self.awardCountLabel];
    [self.view addSubview:self.groupAwardView];
    [self.groupAwardView addSubview:self.groupColorView];
    [self.groupAwardView addSubview:self.groupNameButton];
    [self.groupAwardView addSubview:self.groupAwardCountButton];
    [self.groupAwardView addSubview:self.groupUserCountButton];
    [self.groupAwardView addSubview:self.groupRankButton];
    
    CGFloat awardImageViewHeight = 65.0;
    CGFloat awardImageViewWidth = 72.0;
    [self.awardImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.horizontal.vertical.hugging.compressionResistance.required();
        make.center.equalTo(self.view);
        make.width.equalTo(@(awardImageViewWidth));
        make.height.equalTo(@(awardImageViewHeight));
    }];
    
    CGFloat bottomOffset = awardImageViewHeight * 0.09;
    CGFloat height = awardImageViewHeight * (13.0 / 180.0);
    [self.awardCountLabel bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.awardImageView);
        make.width.lessThanOrEqualTo(self.awardImageView.bjl_width).multipliedBy(0.4);
        make.bottom.equalTo(self.awardImageView).offset(-bottomOffset);
        make.height.greaterThanOrEqualTo(@(height));
    }];
    
    [self.groupAwardView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.awardImageView.bjl_right).offset(10);
        make.top.equalTo(self.awardImageView);
        make.width.lessThanOrEqualTo(@(120));
    }];
    
    [self.groupColorView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.groupNameButton);
        make.left.equalTo(self.groupAwardView).offset(10.0);
        make.height.equalTo(@(12.0));
        make.width.lessThanOrEqualTo(@(12.0));
        make.width.equalTo(@(12.0)).priorityHigh();
    }];
    [self.groupNameButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.groupAwardView);
        make.right.equalTo(self.groupAwardView).offset(-5);
        make.height.equalTo(@(24));
        make.left.equalTo(self.groupColorView.bjl_right).offset(5);
    }];
    [self makeConstraintsWithButtons:@[self.groupAwardCountButton, self.groupUserCountButton, self.groupRankButton]];
    
    [self updateGroupInfo];
    [self updateGroupUserCount];
    [self updateRankWithgroupAwardInfo:self.room.roomVM.grouplikeList];
    
    bjl_weakify(self);
    [self setSingleTapGestureCallback:^(CGPoint point) {
        bjl_strongify(self);
        if (self.groupAwardView.hidden) {
            [self updateGroupAwardView];
        }
        self.groupAwardView.hidden = !self.groupAwardView.hidden;
    }];
    
    [self setWindowUpdateCallback:^(NSString * _Nonnull action, CGRect relativeRect) {
        bjl_strongify(self);
        if (self.groupAwardView.hidden) {
            return;
        }

        CGRect groupAwardFrame = [self.windowedSuperview convertRect:self.groupAwardView.frame fromView:self.view];
        if(!CGRectContainsRect(self.windowedSuperview.bounds, groupAwardFrame)) {
            [self updateGroupAwardView];
        }
    }];
}

- (void)updateGroupAwardView {
    CGRect groupAwardFrame = [self.windowedSuperview convertRect:self.groupAwardView.frame fromView:self.view];
    CGRect awardImageFrame = [self.windowedSuperview convertRect:self.awardImageView.frame fromView:self.view];
    BOOL overRightBoundsX = CGRectGetMaxX(groupAwardFrame) >= CGRectGetMaxX(self.windowedSuperview.bounds) || (CGRectGetMaxX(awardImageFrame) + 10 + groupAwardFrame.size.width) >= CGRectGetMaxX(self.windowedSuperview.bounds);
    BOOL overLeftBoundsX = CGRectGetMinX(groupAwardFrame) <= CGRectGetMinX(self.windowedSuperview.bounds);
    BOOL overBottomBoundsY = CGRectGetMaxY(groupAwardFrame) >= CGRectGetMaxY(self.windowedSuperview.bounds) || (CGRectGetMaxY(awardImageFrame) + 10 + groupAwardFrame.size.height) >= CGRectGetMaxY(self.windowedSuperview.bounds);
    BOOL overTopBoundsY =  CGRectGetMinY(groupAwardFrame) <= CGRectGetMinY(self.windowedSuperview.bounds);
    
    if (!overRightBoundsX && !overLeftBoundsX && !overBottomBoundsY && !overTopBoundsY ) {
        return;
    }
    [self.groupAwardView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        if (overBottomBoundsY) {
            make.bottom.equalTo(self.awardImageView);
        }
        else {
            make.top.equalTo(self.awardImageView);
        }
        if (overRightBoundsX) {
            make.right.equalTo(self.awardImageView.bjl_left).offset(-10);
        }
        else {
            make.left.equalTo(self.awardImageView.bjl_right).offset(10);
        }
        make.width.lessThanOrEqualTo(@(120));
    }];
}

- (void)makeObserving {
    bjl_weakify(self);
    
    // 实时接收分组点赞信息
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveLikeForGroupID:groupName:) observer:^BOOL(NSInteger groupID, NSString *groupName) {
        bjl_strongify(self);
        // 收到当前分组的点赞需要更新自己的分组信息. 收到他组点赞需要更新排名
        if (groupID == self.groupInfo.groupID) {
            [self updateGroupInfo];
        }
        [self updateRankWithgroupAwardInfo:self.room.roomVM.grouplikeList];
        return YES;
    }];
    
    // 覆盖更新点赞数排名
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, likeRecordsDidOverwriteWithGoupLikeInfos:) observer:^BOOL(NSDictionary<NSNumber *, NSNumber *> *groupLikeList) {
        bjl_strongify(self);
        [self updateRankWithgroupAwardInfo:groupLikeList];
        return YES;
    }];
    
    // 实时更新分组内学生数量
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, onlineUserGroupCountDidChange:) observer:^BOOL(NSDictionary *groupCountDic) {
        bjl_strongify(self);
        self.groupCountDic = groupCountDic;
        [self updateGroupUserCount];
        return YES;
    }];
    
    // 实时更新用户所在分组信息
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, onlineUserGroupInfoDidChangeWithUserNumbers:groupInfo:)
             observer:^BOOL(NSArray<NSString *> *userNumbers, BJLUserGroup * _Nullable groupInfo) {
        bjl_strongify(self);
        if ([userNumbers containsObject:self.room.loginUser.number]) {
            if (groupInfo) {
                // 分组人数是由服务端广播的, 可能在收到分组变化时, 人数信息还拿不到, 故提前更新下人数信息+1
                if (self.groupInfo.groupID != groupInfo.groupID) {
                    NSMutableDictionary *groupCountDic = [self.groupCountDic mutableCopy];
                    NSInteger count = [self.groupCountDic bjl_integerForKey:@(groupInfo.groupID).stringValue];
                    [groupCountDic bjl_setObject:@(count + 1) forKey:@(groupInfo.groupID).stringValue];
                    self.groupCountDic = [groupCountDic copy];
                }

                self.groupInfo = groupInfo;
                [self updateGroupInfo];
                [self updateGroupUserCount];
                [self updateRankWithgroupAwardInfo:self.room.roomVM.grouplikeList];
            }
        }
        return YES;
    }];
    
    // 分组信息变更, eg:分组名
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, groupList)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        __block BJLUserGroup *groupInfo = nil;
        [self.room.onlineUsersVM.groupList enumerateObjectsUsingBlock:^(BJLUserGroup * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            bjl_strongify(self);
            if (obj.groupID == self.groupInfo.groupID) {
                groupInfo = obj;
                *stop = YES;
            }
        }];
        self.groupInfo = groupInfo;
        [self updateGroupInfo];
        return YES;
    }];
}

- (void)updateGroupInfo {
    NSInteger likeCount = [self.room.roomVM.grouplikeList bjl_integerForKey:@(self.groupInfo.groupID)];
    self.awardCountLabel.text = [NSString stringWithFormat:@"%td", likeCount];
    [self.groupAwardCountButton setTitle:self.awardCountLabel.text forState:UIControlStateNormal];
    self.groupColorView.backgroundColor = [UIColor bjl_colorWithHexString:self.groupInfo.color] ?: BJLIcTheme.brandColor;
    [self.groupNameButton setTitle:self.groupInfo.name forState:UIControlStateNormal];
}

- (void)updateGroupUserCount {
    NSString *groupIDString = @(self.groupInfo.groupID).stringValue;
    NSInteger count = [self.groupCountDic bjl_integerForKey:groupIDString];
    [self.groupUserCountButton setTitle:[NSString stringWithFormat:@"小组成员: %td人", count] forState:UIControlStateNormal];
}

- (void)updateRankWithgroupAwardInfo:(NSDictionary<NSNumber *, NSNumber *> *)groupInfo {
    if (!groupInfo) {
        return;
    }

    NSMutableArray<NSNumber *> *allGroupIDArray = [[groupInfo allKeys] mutableCopy];
    [allGroupIDArray sortUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        NSNumber *value1 = [groupInfo bjl_numberForKey:obj1];
        NSNumber *value2 = [groupInfo bjl_numberForKey:obj2];
        
        NSComparisonResult result = [value2 compare:value1];
        return result;
    }];
    
    __block NSMutableArray<NSNumber *> *allGroupAwardCountArray = [NSMutableArray new];
    [allGroupIDArray enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *value = [groupInfo bjl_numberForKey:obj];
        [allGroupAwardCountArray addObject:value];
    }];
    NSInteger groupID = self.groupInfo.groupID;
    NSString *rankString = nil;
    
    NSInteger groupIndex = [allGroupIDArray indexOfObject:@(groupID)];
    if (groupIndex == NSNotFound) {
        rankString = @"小组排名: --";
    }
    else {
        NSNumber *groupAwardCount = [groupInfo bjl_numberForKey:@(groupID)];
        NSInteger firtGroupIndex = [allGroupAwardCountArray indexOfObject:groupAwardCount];
        if (firtGroupIndex != groupIndex) {
            groupIndex = firtGroupIndex;
        }
        rankString = [NSString stringWithFormat:@"小组排名: %td", groupIndex +1];
    }
    
    [self.groupRankButton setTitle:rankString forState:UIControlStateNormal];
}

- (void)makeConstraintsWithButtons:(NSArray <UIButton *> *)buttons {
    if (![buttons count]) {
        return;
    }
    
    UIButton *lasetButton = nil;
    for (UIButton *button in buttons) {
        [button bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            if (lasetButton) {
                make.height.width.centerX.equalTo(lasetButton);
                make.top.equalTo(lasetButton.bjl_bottom);
            }
            else {
                make.right.equalTo(self.groupAwardView).offset(-10);
                make.left.equalTo(self.groupAwardView).offset(10);
                make.top.equalTo(self.groupNameButton.bjl_bottom);
                make.height.equalTo(@(24));
            }
            
            if (button == buttons.lastObject) {
                make.bottom.equalTo(self.groupAwardView);
            }
        }];
        lasetButton = button;
        UIView *gapLine = [UIView bjlic_createSeparateLine];
        [self.groupAwardView addSubview:gapLine];
        [gapLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.right.equalTo(self.groupAwardView);
            make.bottom.equalTo(button.bjl_top);
            make.height.equalTo(@1.0);
        }];
    }
}

- (UIButton *)makeButtonWithImage:(nullable UIImage *)image title:(NSString *)title accessibilityLabel:(NSString *)accessibilityLabel {
    UIButton *button = [UIButton new];
    if (image) {
        [button setImage:image forState:UIControlStateNormal];
    }
    if (title) {
        [button setTitle:title forState:UIControlStateNormal];
    }
    [button.titleLabel setFont:[UIFont systemFontOfSize:12]];
    button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [button setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateNormal];
    button.accessibilityLabel = accessibilityLabel;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.contentVerticalAlignment = UIControlContentHorizontalAlignmentCenter;
    button.userInteractionEnabled = NO;
    return button;
}

@end
