//
//  BJLMutableAwardsView.m
//  BJLiveUI
//
//  Created by xyp on 2020/7/31.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLMutableAwardsView.h"

@interface BJLMutableAwardsView()

@property (nonatomic) NSArray<BJLAward *> *awards;
@property (nonatomic) NSMutableArray<UIButton *> *buttons;
@property (nonatomic) NSDictionary *mutableAwardsInfo;
@property (nonatomic) __kindof BJLUser *user;
@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) CGSize size;

@end

@implementation BJLMutableAwardsView

CGFloat itemH = 24.0;
CGFloat margin = 6.0;

- (instancetype)initWithRoom:(BJLRoom *)room user:(__kindof BJLUser *)user {
    self = [super init];
    if (self) {
        self.room = room;
        self.user = user;
        self.awards = [BJLAward allAwards];
        self.mutableAwardsInfo = self.room.roomVM.mutableAwardsInfo;
        self.buttons = [NSMutableArray new];
        CGFloat width = 60.0;
        CGFloat height = self.awards.count * (itemH + margin) + margin;
        self.size = CGSizeMake(width, height);
        [self setupUI];
        [self setupObserving];
    }
    return self;
}

- (void)setupUI {
    for (int i = 0; i < self.awards.count; i++) {
        BJLAward *award = [self.awards bjl_objectAtIndex:i];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.accessibilityLabel = award.key;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        button.enabled = self.room.loginUser.isTeacherOrAssistant;
        button.contentEdgeInsets = UIEdgeInsetsMake(0.0, 4.0, 0.0, 0.0);
        button.imageEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 20.0);
        [button bjl_setImageWithURL:[NSURL URLWithString:award.logo] forState:UIControlStateNormal];
        [button bjl_setImageWithURL:[NSURL URLWithString:award.logo] forState:UIControlStateDisabled];
        [button bjl_setImageWithURL:[NSURL URLWithString:award.logo] forState:UIControlStateNormal | UIControlStateDisabled];
        [button bjl_setImageWithURL:[NSURL URLWithString:award.logo] forState:UIControlStateNormal | UIControlStateHighlighted];
        
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#F7E123"] forState:UIControlStateNormal];
        [self updateButton:button awardKey:award.key];
        
        [button addTarget:self action:@selector(likeAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self).offset(margin + i * (itemH + margin));
            make.left.equalTo(self).offset(margin);
            make.right.equalTo(self).offset(-margin);
            make.height.equalTo(@(itemH));
        }];
        [self.buttons bjl_addObject:button];
    }
}

- (void)setupObserving {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, mutableAwardsInfo)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        self.mutableAwardsInfo = self.room.roomVM.mutableAwardsInfo;
        [self reloadAwardsInfo];
        return YES;
    }];
}

- (void)reloadAwardsInfo {
    for (int i = 0; i < self.awards.count; i++) {
        BJLAward *award = [self.awards bjl_objectAtIndex:i];
        UIButton *button = [self.buttons bjl_objectAtIndex:i];
        [self updateButton:button awardKey:award.key];
    }
}

- (void)updateButton:(UIButton *)button awardKey:(NSString *)awardKey  {
    NSNumber *count = [[self.mutableAwardsInfo bjl_dictionaryForKey:self.user.number] bjl_objectForKey:awardKey];
    NSString *countString = [NSString stringWithFormat:@"%@", count ?: @0];
    [button setTitle:countString forState:UIControlStateNormal];
}

- (void)likeAction:(UIButton *)button {
    NSString *key = button.accessibilityLabel;
    if (self.awardKeyCallback) {
        self.awardKeyCallback(key);
    }
}

@end
