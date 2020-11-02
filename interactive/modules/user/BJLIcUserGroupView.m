//
//  BJLIcUserGroupView.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/12/28.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcUserGroupView.h"
#import "BJLIcAppearance.h"

@interface BJLIcUserGroupView ()

@property (nonatomic) UIButton *showListButton;
@property (nonatomic, readwrite) UIButton *openButton;
@property (nonatomic, readwrite) UILabel *groupNameLabel;
@property (nonatomic, readwrite) UILabel *colorLabel;
@property (nonatomic, readwrite) UIButton *groupLikeButton;

@end

@implementation BJLIcUserGroupView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self makesubviews];
    }
    return self;
}

- (void)makesubviews {
    [self addSubview:self.showListButton];
    [self addSubview:self.openButton];
    [self addSubview:self.groupNameLabel];
    [self addSubview:self.colorLabel];
    [self addSubview:self.groupLikeButton];

    [self.showListButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    [self.openButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self).offset(8.0);
        make.centerY.equalTo(self);
        make.size.equal.sizeOffset(CGSizeMake(24, 24));
    }];
    [self.colorLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.openButton.bjl_right);
        make.size.equal.sizeOffset(CGSizeMake(12.0, 12.0));
        make.centerY.equalTo(self);
    }];
    [self.groupNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.colorLabel.bjl_right).offset(5);
        make.centerY.equalTo(self);
    }];
    
    [self.groupLikeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.bjl_right).offset(-10);
        make.centerY.equalTo(self);
        make.height.equalTo(@(24));
        make.width.equalTo(@(80));
    }];

    UIView *line = [UIView new];
    line.backgroundColor = BJLIcTheme.separateLineColor;
    [self addSubview:line];
    [line bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.openButton);
        make.right.equalTo(self).offset(-10);
        make.bottom.equalTo(self);
        make.height.equalTo(@(1));
    }];
}

- (void)show {
    if (self.clickCallback) {
        self.clickCallback(!self.openButton.selected);
    }
}

- (void)updateWithGroupInfo:(BJLUserGroup *)groupInfo
                  userCount:(NSInteger)userCount
            groupAwardCount:(NSInteger)groupAwardCount
                shouldClose:(BOOL)shouldClose {
    self.groupNameLabel.text = [NSString stringWithFormat:@"%@(%td)", groupInfo.name, userCount];
    self.colorLabel.backgroundColor = [UIColor bjl_colorWithHexString:groupInfo.color];
    self.openButton.selected = !shouldClose;
    [self.groupLikeButton setTitle:[NSString stringWithFormat:@"%ld", (long)groupAwardCount] forState:UIControlStateNormal];
}

#pragma mark - get
- (UIButton *)showListButton {
    if (!_showListButton) {
        _showListButton = [UIButton new];
        [_showListButton addTarget:self action:@selector(show) forControlEvents:UIControlEventTouchUpInside];
    }
    return _showListButton;
}

- (UIButton *)openButton {
    if (!_openButton) {
        _openButton = [UIButton new];
        [_openButton setImage:[UIImage bjlic_imageNamed:@"bjl_userlist_group_fold"] forState:UIControlStateNormal];
        [_openButton setImage:[UIImage bjlic_imageNamed:@"bjl_userlist_group_expand"] forState:UIControlStateSelected];
    }
    return _openButton;
}

- (UILabel *)colorLabel {
    if (!_colorLabel) {
        _colorLabel = [UILabel new];
        _colorLabel.layer.cornerRadius = 6.0;
        _colorLabel.layer.masksToBounds = YES;
    }
    return _colorLabel;
}

- (UILabel *)groupNameLabel {
    if (!_groupNameLabel) {
        _groupNameLabel = [UILabel new];
        _groupNameLabel.textColor = BJLIcTheme.viewTextColor;
        _groupNameLabel.font = [UIFont systemFontOfSize:14];
        _groupNameLabel.textAlignment = NSTextAlignmentLeft;
        _groupNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _groupNameLabel;
}

- (UIButton *)groupLikeButton {
    if (!_groupLikeButton) {
        _groupLikeButton = [UIButton new];
        [_groupLikeButton setImage:[UIImage bjlic_imageNamed:@"bjl_ic_groupAwardCount"] forState:UIControlStateNormal];
        [_groupLikeButton setTitle:@"0" forState:UIControlStateNormal];
        [_groupLikeButton setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateNormal];
        _groupLikeButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _groupLikeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _groupLikeButton.contentVerticalAlignment = UIControlContentHorizontalAlignmentCenter;
    }
    return _groupLikeButton;
}
@end
