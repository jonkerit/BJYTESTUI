//
//  BJLScLotteryView.m
//  BJLiveUI
//
//  Created by xyp on 2020/8/27.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLScLotteryView.h"

#import "BJLScAppearance.h"
#import "BJLScLotteryUserCell.h"

static NSString *kLotteryUserCellIdentifier = @"kLotteryUserCellIdentifier";

@implementation BJLScBeyondBoundsView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    if (!self.isUserInteractionEnabled || self.isHidden || self.alpha <= 0.01) {
        return nil;
    }
    
    for (UIView *subview in self.subviews) {
        CGPoint convertedPoint = [subview convertPoint:point fromView:self];
        UIView *hitTestView = [subview hitTest:convertedPoint withEvent:event];
        if (hitTestView) {
            return hitTestView;
        }
    }
    return nil;
}

@end

@interface BJLScLotteryView () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic) BJLLottery *lottery;

@property (nonatomic) UIView *backgroundView, *contentView;
@property (nonatomic) UIImageView *titleImageView, *loseImageView;
@property (nonatomic) UILabel *winDescribeLabel, *loseDescribeLabel, *noLotteryLabel;
@property (nonatomic, readwrite) BJLScLotteryTextField *nameTextField, *phoneTextField;
// 中奖名单按钮
@property (nonatomic) UIButton *listButton, *closeButton;
// 提交 填写信息 完成按钮
@property (nonatomic) UIButton *submitButton, *fillButton, *doneButton, *watchResultButton;

@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIView *tableHeaderView; //需要固定 不能随tableView滑动

@property (nonatomic) BJLScLotteryViewStatus status;

@end

@implementation BJLScLotteryView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self makeCommonSubviews];
        [self makeOtherSubviews];
        [self makeConstraints];
    }
    return self;
}

- (void)updateViewWithLottery:(BJLLottery *)lottery status:(BJLScLotteryViewStatus)status {
    self.lottery = lottery;
    self.status = status;
    
    switch (status) {
        case BJLScLotteryViewStatus_None:
            break;
            
        case BJLScLotteryViewStatus_Submit:
            self.titleImageView.image    = [UIImage bjlsc_imageNamed:@"bjl_sc_lottery_win"];
            self.winDescribeLabel.text   = @"请在下方输入联系方式方便工作人员与您取得联系～";
            self.winDescribeLabel.hidden = NO;
            self.nameTextField.hidden    = NO;
            self.phoneTextField.hidden   = NO;
            self.listButton.hidden       = NO;
            self.submitButton.hidden     = NO;
            break;
            
        case BJLScLotteryViewStatus_Fill:
            self.titleImageView.image    = [UIImage bjlsc_imageNamed:@"bjl_sc_lottery_result_img"];
            self.winDescribeLabel.text   = @"恭喜以下用户获得了幸运抽奖礼品～";
            self.winDescribeLabel.hidden = NO;
            self.fillButton.hidden       = NO;
            
            if (self.lottery.userList.count > 0) {
                self.noLotteryLabel.hidden   = YES;
                self.tableView.hidden        = NO;
                self.tableHeaderView.hidden  = NO;
            }
            else {
                self.tableView.hidden        = YES;
                self.tableHeaderView.hidden  = YES;
                self.noLotteryLabel.hidden   = NO;
            }
            break;
            
        case BJLScLotteryViewStatus_Lose:
            self.titleImageView.image     = [UIImage bjlsc_imageNamed:@"bjl_sc_lottery_lose"];
            self.watchResultButton.hidden = NO;
            self.loseDescribeLabel.hidden = NO;
            self.loseImageView.hidden     = NO;
            break;
            
        case BJLScLotteryViewStatus_Done:
            self.titleImageView.image    = [UIImage bjlsc_imageNamed:@"bjl_sc_lottery_result_img"];
            self.winDescribeLabel.text   = @"恭喜以下用户获得了幸运抽奖礼品～";
            self.winDescribeLabel.hidden = NO;
            self.doneButton.hidden       = NO;
            
            if (self.lottery.userList.count > 0) {
                self.noLotteryLabel.hidden   = YES;
                self.tableView.hidden        = NO;
                self.tableHeaderView.hidden  = NO;
            }
            else {
                self.tableView.hidden        = YES;
                self.tableHeaderView.hidden  = YES;
                self.noLotteryLabel.hidden   = NO;
            }
            
            break;
            
        default:
            break;
    }
    if (!self.tableView.hidden) {
        [self.tableView reloadData];
    }
}

- (BOOL)textFieldIsFirstResponder {
    if ([self.nameTextField isFirstResponder]
        || [self.phoneTextField isFirstResponder]
        
        ) {
        return YES;
    }
    return NO;
}


- (void)makeCommonSubviews {
    bjl_weakify(self);
    UITapGestureRecognizer *tap = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        [self endEditing:YES];
    }];
    [self addGestureRecognizer:tap];
    
    self.backgroundView = ({
        UIView *view = [UIView new];
        view.layer.cornerRadius = 14.0;
        view.layer.masksToBounds = YES;
        view.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF5147"];
        [self addSubview:view];
        view;
    });
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(self);
        make.height.equalTo(@300).priorityHigh();
    }];
    
    self.titleImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.accessibilityLabel = BJLKeypath(self, titleImageView);
        [self insertSubview:imageView aboveSubview:self.backgroundView];
        imageView;
    });
    [self.titleImageView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self);
        make.centerY.equalTo(self.backgroundView.bjl_top).offset(-10.0);
        make.height.equalTo(@96).priorityHigh();
    }];
    
    self.closeButton = ({
        BJLImageButton *button = [BJLImageButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_lottery_close_normal"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_lottery_close_select"] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(closeAction:) forControlEvents:UIControlEventTouchUpInside];
        button.accessibilityLabel = BJLKeypath(self, closeButton);
        [self insertSubview:button aboveSubview:self.titleImageView];
        button;
    });
    
    [self.closeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.backgroundView.bjl_right);
        make.centerY.equalTo(self.backgroundView.bjl_top);
        make.width.equalTo(@35);
        make.height.equalTo(@35);
    }];
    
    self.contentView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, contentView);
        view.backgroundColor = [UIColor bjl_colorWithHexString:@"#FFF8EC"];
        view.layer.cornerRadius = 14.0;
        view.layer.masksToBounds = YES;
        [self.backgroundView addSubview:view];
        view;
    });
    [self.contentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.backgroundView).offset(10.0);
        make.right.equalTo(self.backgroundView).offset(-10.0);
        make.top.equalTo(self.backgroundView).offset(35.0);
        make.bottom.equalTo(self.backgroundView).offset(-40.0);
    }];
}

- (void)makeOtherSubviews {
    self.winDescribeLabel = ({
        UILabel *label = [UILabel new];
        label.hidden = YES;
        label.textColor = [UIColor bjl_colorWithHexString:@"#AE6008"];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:label];
        label;
    });
    
    self.loseDescribeLabel = ({
        UILabel *label = [UILabel new];
        label.hidden = YES;
        label.textColor = [UIColor bjl_colorWithHexString:@"#AE6008"];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"非常遗憾，本次没有中奖 ～";
        [self.contentView addSubview:label];
        label;
    });
    
    self.noLotteryLabel = ({
        UILabel *label = [UILabel new];
        label.hidden = YES;
        label.textColor = [UIColor bjl_colorWithHexString:@"#AE6008"];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"暂无中奖记录";
        [self.contentView addSubview:label];
        label;
    });
    
    self.doneButton = [self makeButtonWithImageName:@"bjl_sc_lottery_done" isWidth1_4:YES accessibilityLabel:BJLKeypath(self, doneButton)];
    self.submitButton = [self makeButtonWithImageName:@"bjl_sc_lottery_submit" isWidth1_4:YES accessibilityLabel:BJLKeypath(self, submitButton)];
    self.fillButton = [self makeButtonWithImageName:@"bjl_sc_lottery_fill" isWidth1_4:NO accessibilityLabel:BJLKeypath(self, fillButton)];
    self.watchResultButton = [self makeButtonWithImageName:@"bjl_sc_lottery_result_icon" isWidth1_4:NO accessibilityLabel:BJLKeypath(self, watchResultButton)];
    
    [self.backgroundView insertSubview:self.doneButton aboveSubview:self.contentView];
    [self.backgroundView insertSubview:self.submitButton aboveSubview:self.contentView];
    [self.backgroundView insertSubview:self.fillButton aboveSubview:self.contentView];
    [self.backgroundView insertSubview:self.watchResultButton aboveSubview:self.contentView];
    
    self.nameTextField = ({
        BJLScLotteryTextField *textField = [[BJLScLotteryTextField alloc] initWithPlaceholder:@"姓名："];
        textField.returnKeyType = UIReturnKeyNext;
        textField.hidden = YES;
        textField.delegate = self;
        [self.contentView addSubview:textField];
        textField;
    });
    
    self.phoneTextField = ({
        BJLScLotteryTextField *textField = [[BJLScLotteryTextField alloc] initWithPlaceholder:@"手机号："];
        textField.returnKeyType = UIReturnKeyDone;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.delegate = self;
        textField.hidden = YES;
        [self.contentView addSubview:textField];
        textField;
    });

    self.listButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.hidden = YES;
        [button setTitle:@"中奖名单" forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#AE6008"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(listButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:button];
        button;
    });
    
    self.tableHeaderView = [self makeTableHeaderView];
    self.tableHeaderView.hidden = YES;
    [self.contentView addSubview:self.tableHeaderView];
    
    self.tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tableView.hidden = YES;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.delegate = self;
        tableView.dataSource = self;
        [tableView registerClass:[BJLScLotteryUserCell class] forCellReuseIdentifier:kLotteryUserCellIdentifier];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.showsVerticalScrollIndicator = NO;
        tableView.rowHeight = 32.0;
        [self.contentView addSubview:tableView];
        tableView;
    });
    
    self.loseImageView = [[UIImageView alloc] initWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_lottery_lose_emoji"]];
    self.loseImageView.hidden = YES;
    [self.contentView addSubview:self.loseImageView];
}

- (void)makeConstraints {
    [self.winDescribeLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.contentView).offset(25);
        make.height.equalTo(@20);
        make.centerX.equalTo(self.contentView);
    }];
    
    [self.nameTextField bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.contentView);
        make.width.equalTo(@296);
        make.height.equalTo(@42);
        make.top.equalTo(self.winDescribeLabel.bjl_bottom).offset(22);
    }];
    
    [self.phoneTextField bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.contentView);
        make.width.height.equalTo(self.nameTextField);
        make.top.equalTo(self.nameTextField.bjl_bottom).offset(17);
    }];
    
    [self.listButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.nameTextField);
        make.top.equalTo(self.phoneTextField.bjl_bottom).offset(10);
        make.height.equalTo(@20);
        make.width.equalTo(@60);
    }];
    
    // button
    [self.submitButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.contentView.bjl_bottom);
        make.centerX.equalTo(self.backgroundView);
        make.height.equalTo(@50);
        make.width.equalTo(@196);
    }];
    [self.fillButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.submitButton);
    }];
    [self.doneButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.submitButton);
    }];
    [self.watchResultButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.submitButton);
    }];
    
    [self.tableHeaderView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.contentView).offset(25);
        make.right.equalTo(self.contentView).offset(-30);
        make.top.equalTo(self.winDescribeLabel.bjl_bottom).offset(15);
        make.height.equalTo(@32);
    }];
    
    [self.tableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.tableHeaderView);
        make.top.equalTo(self.tableHeaderView.bjl_bottom);
        make.bottom.equalTo(self.doneButton.bjl_top).offset(-5);
    }];

    // 未中奖的view
    [self.loseDescribeLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.contentView);
        make.height.equalTo(@20);
        make.top.equalTo(self.loseImageView.bjl_bottom).offset(10);
    }];
    
    [self.loseImageView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.loseDescribeLabel);
        make.centerY.equalTo(self.contentView).offset(-10);
        make.width.height.equalTo(@84);
    }];
    
    // 暂无中奖纪录
    [self.noLotteryLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.contentView);
        make.height.equalTo(@20);
    }];
}

#pragma mark - tableview datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.lottery.userList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLScLotteryUserCell *cell = [tableView dequeueReusableCellWithIdentifier:kLotteryUserCellIdentifier];
    BJLLotteryUser *user = self.lottery.userList[indexPath.row];
    [cell updateWithUserName:user.userName prizeName:self.lottery.lotteryName];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark - action

- (void)closeAction:(UIButton *)button {
    if (self.closeCallback) {
        self.closeCallback();
    }
}

- (void)listButtonAction:(UIButton *)button {
    // 只有 BJLScLotteryViewStatus_Submit 的view 才有这个按钮
    if (self.listButtonCallback
        && self.status == BJLScLotteryViewStatus_Submit) {
        self.listButtonCallback();
    }
}

- (void)buttonClickAction:(UIButton *)button {
    if (self.buttonClickCallback) {
        self.buttonClickCallback(self);
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.nameTextField) {
        [UIView animateWithDuration:0.2 animations:^{
            [self.nameTextField resignFirstResponder];
        } completion:^(BOOL finished) {
            if (finished) {
                [self.phoneTextField becomeFirstResponder];
            }
        }];
    }
    else if (textField == self.phoneTextField) {
        [self endEditing:YES];
        if (self.buttonClickCallback) {
            self.buttonClickCallback(self);
        }
    }
    return NO;
}

#pragma mark - utily

- (UIButton *)makeButtonWithImageName:(NSString *)imageName isWidth1_4:(BOOL)isWidth1_4 accessibilityLabel:(NSString *)accessibilityLabel {
    BJLImageButton *button = [BJLImageButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_lottery_normal"] forState:UIControlStateNormal];
    [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_lottery_select"] forState:UIControlStateHighlighted];
    button.hidden = YES;
    button.accessibilityLabel = accessibilityLabel;
    [button addTarget:self action:@selector(buttonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage bjlsc_imageNamed:imageName]];
    [button addSubview:imageView];
    [imageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(button);
        make.height.equalTo(button).multipliedBy(0.5);
        make.width.equalTo(button).multipliedBy(isWidth1_4 ? 0.25 : 0.5);
    }];
    return button;
}

- (UILabel *)makeLabel:(NSString  *)content alignment:(NSTextAlignment)alignment {
    UILabel *label = [UILabel new];
    label.textColor = [UIColor bjl_colorWithHexString:@"#AE6008"];
    label.font = [UIFont systemFontOfSize:14.0];
    label.textAlignment = alignment;
    label.text = content;
    return label;
}

- (UIView *)makeTableHeaderView {
    UIView *view = [UIView new];
    UILabel *nameLabel = [self makeLabel:@"昵称" alignment:NSTextAlignmentLeft];
    UILabel *prizeLabel = [self makeLabel:@"奖品名称" alignment:NSTextAlignmentRight];
    
    UIView *line = ({
        UIView *line = [UIView new];
        line.backgroundColor = [UIColor bjl_colorWithHexString:@"#AE6008" alpha:0.1];
        line;
    });
    
    [view addSubview:nameLabel];
    [view addSubview:prizeLabel];
    [view addSubview:line];
    
    [nameLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(view).offset(2);
        make.top.bottom.equalTo(view);
        make.right.equalTo(view.bjl_centerX);
    }];
    [prizeLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(view).offset(-2);
        make.top.bottom.equalTo(view);
        make.left.equalTo(view.bjl_centerX);
    }];
    [line bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(view);
        make.height.equalTo(@1);
    }];
    
    return view;
}

@end

