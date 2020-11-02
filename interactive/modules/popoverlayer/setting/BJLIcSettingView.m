//
//  BJLIcSettingView.m
//  BJLiveUI
//
//  Created by 辛亚鹏 on 2020/4/23.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcSettingView.h"
#import "BJLIcAppearance.h"

@interface BJLIcSettingView()

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) UILabel *settingLabel;
@property (nonatomic) UILabel *roomControlLabel, *switchMirrorLabel;
@property (nonatomic) UISwitch *modeSwitch;
@property (nonatomic) UILabel *pptLabel, *pptDeslabel;
@property (nonatomic) UIButton *closeButton;
@property (nonatomic) BJLButton *pptHighQualityButton, *pptLowQualityButton;
@property (nonatomic) UIView *lineView;

@end

@implementation BJLIcSettingView

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.room = room;
        [self makeCommonSubview];
        if (room.loginUser.isTeacherOrAssistant) {
            [self makeModeSwitch:self.room.recordingVM.isOnEncoderMirrorMode];
            [self makePPTQualitySubView];
        }
        else {
            [self makePPTQualitySubView];
        }
        [self makeConstraints];
    }
    return self;
}

- (void)updateButtonStateWhenError {
    self.pptHighQualityButton.selected = [self.room.documentVM pptQualityIsOriginal];
    self.pptLowQualityButton.selected = ![self.room.documentVM pptQualityIsOriginal];
    
    self.pptHighQualityButton.userInteractionEnabled = !self.pptHighQualityButton.selected;
    self.pptLowQualityButton.userInteractionEnabled = !self.pptLowQualityButton.selected;
}

- (void)makeCommonSubview {
    self.backgroundColor = BJLIcTheme.windowBackgroundColor;
    self.layer.cornerRadius = BJLIcAppearance.toolboxCornerRadius;
    self.layer.shadowColor = BJLIcTheme.windowShadowColor.CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.layer.shadowOpacity = 0.3;
    
    self.settingLabel = ({
        UILabel *titleLabel = [UILabel new];
        titleLabel.text = @"设置";
        titleLabel.textColor = BJLIcTheme.viewTextColor;
        titleLabel.font = [UIFont systemFontOfSize:14.0];
        titleLabel.accessibilityLabel = BJLKeypath(self, settingLabel);
        titleLabel;
    });
    [self addSubview:self.settingLabel];
    
    self.closeButton = ({
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setImage:[UIImage bjlic_imageNamed:@"window_close"] forState:UIControlStateNormal];
        btn.accessibilityLabel = BJLKeypath(self, closeButton);
        [btn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
        btn;
    });
    [self addSubview:self.closeButton];
    
    self.lineView = [UIView new];
    self.lineView.backgroundColor = BJLIcTheme.separateLineColor;
    [self addSubview:self.lineView];
    
    [self.settingLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self).offset(BJLIcAppearance.liveStartViewSpace);
        make.top.equalTo(self).offset(BJLIcAppearance.toolbarSmallSpace);
        make.height.equalTo(@(BJLIcAppearance.liveStartViewSpace));
    }];
    [self.closeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self).offset(-BJLIcAppearance.liveStartViewSpace);
        make.centerY.equalTo(self.settingLabel);
        make.height.width.equalTo(@(BJLIcAppearance.userWindowDefaultBarHeight));
    }];
    [self.lineView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.settingLabel.bjl_bottom).offset(BJLIcAppearance.toolbarSmallSpace);
        make.height.equalTo(@1);
        make.left.right.equalTo(self);
    }];
}

- (void)makeModeSwitch:(BOOL)isOn {
    self.roomControlLabel = ({
        UILabel *l = [UILabel new];
        l.text = @"房间控制";
        l.textColor = BJLIcTheme.viewTextColor;
        l.accessibilityLabel = BJLKeypath(self, roomControlLabel);
        l.font = [UIFont systemFontOfSize:14.0];
        l;
    });
    [self addSubview:self.roomControlLabel];
    
    self.switchMirrorLabel = ({
        UILabel *l = [UILabel new];
        l.accessibilityLabel = BJLKeypath(self, switchMirrorLabel);
        l.text = @"全体镜像翻转";
        l.textColor = BJLIcTheme.viewTextColor;
        l.font = [UIFont systemFontOfSize:14.0];
        l;
    });
    [self addSubview:self.switchMirrorLabel];
    
    self.modeSwitch = ({
        UISwitch *modeSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        modeSwitch.accessibilityLabel = BJLKeypath(self, modeSwitch);
        modeSwitch.on = isOn;
        modeSwitch.backgroundColor = [UIColor bjl_colorWithHexString:@"#999999"];
        modeSwitch.thumbTintColor = [UIColor whiteColor];
        modeSwitch.layer.cornerRadius = modeSwitch.bounds.size.height / 2.0;
        modeSwitch.layer.masksToBounds = YES;
        [modeSwitch addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
        modeSwitch;
    });
    [self addSubview:self.modeSwitch];
}

- (void)makePPTQualitySubView {
    self.pptLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"课件品质";
        label.textColor = BJLIcTheme.viewTextColor;
        label.font = [UIFont systemFontOfSize:14.0];
        label.accessibilityLabel = BJLKeypath(self, pptLabel);
        label;
    });
    [self addSubview:self.pptLabel];
    
    self.pptHighQualityButton = ({
        BJLButton *button = [BJLButton buttonWithType:UIButtonTypeCustom];
        [button bjl_setImage:[UIImage bjlic_imageNamed:@"bjl_setting_pptQuality_normal"] forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_setting_pptQuality_selected"] forState:UIControlStateSelected];
        [button bjl_setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
        [button bjl_setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateSelected optionalStates:UIControlStateHighlighted];
        [button setTitle:@"原图" forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        button.selected = [self.room.documentVM pptQualityIsOriginal];
        button.userInteractionEnabled = !button.selected;
        [button addTarget:self action:@selector(pptChangeQualityAction:) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self addSubview:self.pptHighQualityButton];
    
    self.pptLowQualityButton = ({
        BJLButton *button = [BJLButton buttonWithType:UIButtonTypeCustom];
        [button bjl_setImage:[UIImage bjlic_imageNamed:@"bjl_setting_pptQuality_normal"] forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_setting_pptQuality_selected"] forState:UIControlStateSelected];
        [button bjl_setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
        [button bjl_setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateSelected optionalStates:UIControlStateHighlighted];
        [button setTitle:@"流畅" forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        button.selected = ![self.room.documentVM pptQualityIsOriginal];
        button.userInteractionEnabled = !button.selected;
        [button addTarget:self action:@selector(pptChangeQualityAction:) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self addSubview:self.pptLowQualityButton];
    
    self.pptDeslabel = ({
        UILabel *label = [UILabel new];
        label.text = @"原图：课件清晰，但容易出现卡顿情况。流畅：使用压缩课件，翻页较快。 仅对普通课件生效。";
        label.textColor = BJLIcTheme.viewSubTextColor;
        label.numberOfLines = 0;
        label.font = [UIFont systemFontOfSize:12.0];
        label.accessibilityLabel = BJLKeypath(self, pptLabel);
        label;
    });
    [self addSubview:self.pptDeslabel];
}

- (void)makeConstraints {
    CGFloat left = 60.0 / 1024.0 * [UIScreen mainScreen].bounds.size.width;
    CGFloat minSpace = 12.0;
    CGFloat midSpace = 20.0;
    CGFloat space = 30.0;
    CGFloat width = 60.0;

    if (self.room.loginUser.isTeacherOrAssistant) {
        [self.roomControlLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.bjl_centerY).offset(-midSpace);
            make.left.equalTo(self).offset(left);
        }];
        [self.modeSwitch bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.equalTo(self.roomControlLabel);
            make.right.equalTo(self).offset(-left);
        }];
        [self.switchMirrorLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.modeSwitch.bjl_left).offset(-minSpace);
            make.centerY.equalTo(self.roomControlLabel);
        }];
        
        [self.pptLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.bjl_centerY).offset(midSpace);
            make.left.equalTo(self.roomControlLabel);
        }];
        [self.pptLowQualityButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.modeSwitch);
            make.centerY.height.equalTo(self.pptLabel);
            make.width.equalTo(@(width));
        }];
        [self.pptHighQualityButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.pptLowQualityButton.bjl_left).offset(-space);
            make.height.width.centerY.equalTo(self.pptLowQualityButton);
        }];
        [self.pptDeslabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.pptLabel.bjl_bottom).offset(minSpace);
            make.left.right.equalTo(self.pptLabel);
            make.right.equalTo(self.modeSwitch);
        }];
    }
    else {
        [self.pptDeslabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.bjl_centerY);
            make.left.equalTo(self).offset(left);
            make.right.equalTo(self).offset(-left);
        }];
        [self.pptLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.right.equalTo(self.pptDeslabel);
            make.bottom.equalTo(self.pptDeslabel.bjl_top).offset(-minSpace);
        }];
        [self.pptLowQualityButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.pptDeslabel);
            make.centerY.height.equalTo(self.pptLabel);
            make.width.equalTo(@(width));
        }];
        [self.pptHighQualityButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.pptLowQualityButton.bjl_left).offset(-space);
            make.height.width.bottom.equalTo(self.pptLowQualityButton);
        }];
    }
}

#pragma mark -

- (void)closeAction {
    if (self.closeCallback) {
        self.closeCallback();
    }
    [self removeFromSuperview];
}

- (void)switchAction:(UISwitch *)modeSwitch {
    if (self.switchMirrorModeCallback) {
        self.switchMirrorModeCallback(modeSwitch.on);
    }
}

- (void)pptChangeQualityAction:(UIButton *)button {
    self.pptHighQualityButton.selected = !self.pptHighQualityButton.selected;
    self.pptLowQualityButton.selected = !self.pptLowQualityButton.selected;
    
    self.pptHighQualityButton.userInteractionEnabled = !self.pptHighQualityButton.selected;
    self.pptLowQualityButton.userInteractionEnabled = !self.pptLowQualityButton.selected;
    
    if (self.pptHighQualityButton.selected) {
        if (self.pptQualityChangeCallback) {
            self.pptQualityChangeCallback(YES, self);
        }
    }
    else if (self.pptLowQualityButton.selected) {
        if (self.pptQualityChangeCallback) {
            self.pptQualityChangeCallback(NO, self);
        }
    }
}

@end
