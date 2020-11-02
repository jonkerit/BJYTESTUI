//
//  BJLScLotteryViewController.m
//  BJLiveUI
//
//  Created by xyp on 2020/8/26.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLScLotteryViewController.h"
#import "BJLScAppearance.h"
#import "BJLScLotteryAnimationView.h"

#import "BJLScLotteryView.h"

@interface BJLScLotteryViewController ()

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) BJLLottery *lottery;

@property (nonatomic) BJLScLotteryAnimationView *animationView;
@property (nonatomic) BJLScBeyondBoundsView *containerView;
@property (nonatomic) BJLScLotteryView *submitView, *fillView, *loseView, *doneView;
@property (nonatomic) BOOL hasSubmitInfo;

@end

@implementation BJLScLotteryViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    self.view.hidden = YES;
    
    [self makeSubviews];
    [self makeCallback];
    [self hideLotteryViews];
    [self makeObservering];
    self.hasSubmitInfo = NO;
    
    bjl_weakify(self);
    UITapGestureRecognizer *tap = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        [self.view endEditing:YES];
    }];
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

#pragma mark -

- (void)makeSubviews {
    self.containerView = ({
        BJLScBeyondBoundsView *view = [BJLScBeyondBoundsView new];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self.view addSubview:self.containerView];
    
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.greaterThanOrEqualTo(self.view).offset(20).priorityHigh();;
        make.right.greaterThanOrEqualTo(self.view).offset(-20).priorityHigh();;
        make.bottom.lessThanOrEqualTo(self.view);
        make.top.greaterThanOrEqualTo(self.view);
        make.center.equalTo(self.view);
        make.height.equalTo(@358);
        make.width.equalTo(@370);
    }];
    
    self.submitView = [BJLScLotteryView new];
    self.fillView = [BJLScLotteryView new];
    self.loseView = [BJLScLotteryView new];
    self.doneView = [BJLScLotteryView new];
    
    [self.containerView addSubview:self.submitView];
    [self.containerView addSubview:self.fillView];
    [self.containerView addSubview:self.loseView];
    [self.containerView addSubview:self.doneView];
    
    [self.submitView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
    [self.fillView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
    [self.loseView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
    [self.doneView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
}

- (void)makeCallback {
    bjl_weakify(self);
    // 提交的view
    [self.submitView setButtonClickCallback:^(BJLScLotteryView * _Nonnull lotteryView) {
        bjl_strongify(self);
        [self submitAction];
    }];
    [self.submitView setListButtonCallback:^{
        bjl_strongify(self);
        self.submitView.hidden = YES;
        [self updateLotteryViewStatus:BJLScLotteryViewStatus_Fill];
    }];
    [self.submitView setCloseCallback:^{
        bjl_strongify(self);
        [self closeConfirm];
    }];
    
    // 填写信息的view
    [self.fillView setButtonClickCallback:^(BJLScLotteryView * _Nonnull lotteryView) {
        bjl_strongify(self);
        lotteryView.hidden = YES;
        [self updateLotteryViewStatus:BJLScLotteryViewStatus_Submit];
    }];
    [self.fillView setCloseCallback:^{
        bjl_strongify(self);
        [self closeConfirm];
    }];
    
    // 未中奖的view
    [self.loseView setButtonClickCallback:^(BJLScLotteryView * _Nonnull lotteryView) {
        bjl_strongify(self);
        lotteryView.hidden = YES;
        [self updateLotteryViewStatus:BJLScLotteryViewStatus_Done];
    }];
    [self.loseView setCloseCallback:^{
        bjl_strongify(self);
        [self hideLotteryViews];
    }];
    
    // 完成 view
    [self.doneView setButtonClickCallback:^(BJLScLotteryView * _Nonnull lotteryView) {
        bjl_strongify(self);
        [self hideLotteryViews];
    }];
    [self.doneView setCloseCallback:^{
        bjl_strongify(self);
        [self hideLotteryViews];
    }];
}

#pragma mark - makeObservering

- (void)makeObservering {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveLotteryResult:) observer:^BOOL(BJLLottery *lottery){
        bjl_strongify(self);
        self.lottery = lottery;
        self.view.hidden = NO;
        BJLScLotteryAnimationView *animationView = [[BJLScLotteryAnimationView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:animationView];
        [animationView setAnimationFinishCallback:^(BJLScLotteryAnimationView * _Nonnull aView) {
            bjl_strongify(self);
            BOOL isWin = NO;
            for (BJLLotteryUser *user in self.lottery.userList) {
                if ([user.userNumber isEqualToString:self.room.loginUser.number]) {
                    isWin = YES;
                    break;
                }
            }
            
            if (isWin) {
                self.hasSubmitInfo = NO;
                [self updateLotteryViewStatus:BJLScLotteryViewStatus_Submit];
            }
            else {
                self.hasSubmitInfo = YES;
                [self updateLotteryViewStatus:BJLScLotteryViewStatus_Lose];
            }
            [aView removeFromSuperview];
        }];
        return YES;
    }];
}

#pragma mark -

- (void)submitAction {
    NSString *name = self.submitView.nameTextField.text;
    NSString *mobile = self.submitView.phoneTextField.text;
    if (!name.length) {
        [self.submitView.nameTextField updateTip:@"请输入名字"];
    }
    if (!mobile.length) {
        [self.submitView.phoneTextField updateTip:@"请输入手机号"];
        return;
    }

    NSString *format = @"^1\\d{2}\\d{4}\\d{4}$";
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", format];
    if (![phoneTest evaluateWithObject:mobile]) {
        [self.submitView.phoneTextField updateTip:@"输入有误"];
        return;
    }
    
    [BJLProgressHUD bjl_showHUDForLoadingWithSuperview:self.view animated:YES];
    bjl_weakify(self);
    [self.room.roomVM submitLotteryUserName:name mobile:mobile beginTime:self.lottery.beginTime completion:^(BOOL success) {
        bjl_strongify(self);
        [BJLProgressHUD hideHUDForView:self.view animated:YES];
        self.hasSubmitInfo = YES;
        self.submitView.hidden = YES;
        self.submitView.nameTextField.text = @"";
        self.submitView.phoneTextField.text = @"";
        [self updateLotteryViewStatus:BJLScLotteryViewStatus_Done];
    }];
}

- (void)closeConfirm {
    // 已经提交信息则直接隐藏
    if (self.hasSubmitInfo) {
        [self hideLotteryViews];
        return;
    }
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:@"你还没有提交信息，确认关闭吗" preferredStyle:UIAlertControllerStyleAlert];
    bjl_weakify(self);
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        bjl_strongify(self);
        [self hideLotteryViews];
    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertVC addAction:action1];
    [alertVC addAction:action2];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)hideLotteryViews {
    self.submitView.hidden    = YES;
    self.fillView.hidden      = YES;
    self.doneView.hidden      = YES;
    self.loseView.hidden      = YES;
    
    self.view.hidden          = YES;
}

- (void)updateLotteryViewStatus:(BJLScLotteryViewStatus)status {
    
    BJLScLotteryView *lotteryView;
    
    switch (status) {
        case BJLScLotteryViewStatus_Submit:
            self.fillView.hidden    = YES;
            self.doneView.hidden    = YES;
            self.loseView.hidden    = YES;
            self.submitView.hidden  = NO;
            lotteryView = self.submitView;
            break;
        
        case BJLScLotteryViewStatus_Fill:
            self.submitView.hidden = YES;
            self.doneView.hidden   = YES;
            self.loseView.hidden   = YES;
            self.fillView.hidden   = NO;
            lotteryView = self.fillView;
            break;
            
        case BJLScLotteryViewStatus_Lose:
            self.submitView.hidden = YES;
            self.fillView.hidden   = YES;
            self.doneView.hidden   = YES;
            self.loseView.hidden   = NO;
            lotteryView = self.loseView;
            break;
            
        case BJLScLotteryViewStatus_Done:
            self.submitView.hidden = YES;
            self.fillView.hidden   = YES;
            self.loseView.hidden   = YES;
            self.doneView.hidden   = NO;
            lotteryView = self.doneView;
            break;
            
        default:
            break;
    }
    [lotteryView updateViewWithLottery:self.lottery status:status];
}

#pragma mark - keyboard observer

- (void)keyboardWillShow:(NSNotification *)notification {
    if (![self.submitView.nameTextField isFirstResponder]
        && ![self.submitView.phoneTextField isFirstResponder]) {
        [self keyboardWillHide:nil];
        return;
    }
    
    CGRect rect = CGRectZero;
    
    if ([self.submitView.nameTextField isFirstResponder]) {
        rect = [self.submitView.nameTextField convertRect:self.submitView.nameTextField.bounds toView:self.view];
    }
    else if ([self.submitView.phoneTextField isFirstResponder]) {
        rect = [self.submitView.phoneTextField convertRect:self.submitView.phoneTextField.bounds toView:self.view];
    }
    
    NSDictionary *userInfo = [notification userInfo];
    NSValue *Value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [Value CGRectValue];
    CGFloat height = keyboardRect.size.height;
    CGFloat bottomMargin = self.view.bounds.size.height - rect.origin.y - rect.size.height;
    CGFloat offset = 0;
    if (bottomMargin < height) {
        offset = height - bottomMargin + 10.0;
    }
    else {
        offset = 10.0;
    }
        
    [self.submitView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.top.left.right.equalTo(self.containerView);
        make.bottom.equalTo(self.containerView).offset(-offset);
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self.submitView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
}


@end
