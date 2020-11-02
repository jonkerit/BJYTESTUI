//
//  BJLIcCountDownEditWindowViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/5/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcCountDownEditWindowViewController.h"
#import "BJLIcWindowViewController+protected.h"
#import "BJLIcAppearance.h"

#define onePixel (1.0 / [UIScreen mainScreen].scale)

#define hightCountDownTime 60
#define defaultCountDownTime 300

@interface BJLIcCountDownEditWindowViewController ()<UITextFieldDelegate>

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) BJLIcCountDownWindowLayout layout;
@property (nonatomic) NSTimeInterval countDownTime;

// 老师/助教发布计时器之后，点击撤回返回到初始设置值
@property (nonatomic) NSTimeInterval preCountDownTime;

// 初始倒计时时间为1分钟及以上时, 倒计时从1分钟开始要变色, 否则不变色.
@property (nonatomic) BOOL isStartTimeShouldHighlight;
@property (nonatomic) NSTimer *timer;

@property (nonatomic) UIButton *publishButton;
@property (nonatomic) UIView *bottomGapLine;
@property (nonatomic) UIView *topGapLine;

@property (nonatomic) UIView *containerView, *overlayView;
@property (nonatomic) UITextField *minusInTensDigitTextField;// 分钟的十位数字
@property (nonatomic) UITextField *minusInUnitsDigitTextField;// 分钟的个位数字
@property (nonatomic) UITextField *secondsInTensDigitTextField;// 秒的十位数字
@property (nonatomic) UITextField *secondsInUnitsDigitTextField;// 秒的个位数字
@property (nonatomic) UILabel *gapView;

@end

@implementation BJLIcCountDownEditWindowViewController

- (instancetype)initWithRoom:(BJLRoom *)room
               countDownTime:(NSTimeInterval)time
                      layout:(BJLIcCountDownWindowLayout)layout {
    self = [super init];
    if (self) {
        self.layout = layout;
        self->_room = room;
        self.countDownTime = (layout == BJLIcCountDownWindowLayout_unpublish) ? defaultCountDownTime : time;
        self.preCountDownTime = self.countDownTime;
        self.isStartTimeShouldHighlight = (layout == BJLIcCountDownWindowLayout_unpublish) ? NO : (time >= hightCountDownTime);
        [self prepareToOpen];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.layer.shadowColor = BJLIcTheme.windowShadowColor.CGColor;
    self.view.layer.shadowOffset = CGSizeMake(0, 0);
    self.view.layer.shadowRadius = BJLIcAppearance.toolboxCornerRadius;
    self.view.layer.shadowOpacity = 0.3;

    [self setWindowInterfaceEnabled:YES];
    [self setWindowGesturesEnabled:YES];
    self.forgroundView.userInteractionEnabled = NO;
    self.topBar.hidden = NO;
    
    self.maximizeButtonHidden = YES;
    self.fullscreenButtonHidden = YES;
    self.closeButtonHidden = (self.layout == BJLIcCountDownWindowLayout_normal);
    self.doubleTapToMaximize = NO;
    self.panToResize = NO;
    self.resizeHandleImageViewHidden = YES;
    self.backgroundView.backgroundColor = [BJLIcTheme windowBackgroundColor];
    self.topBar.backgroundView.hidden = YES;
    self.bottomBar.backgroundView.hidden = YES;
    [self makeConstraints];
    [self remakeConstraintsWithLayout:self.layout];
    [self updateShowTime];
    
    [self makeObservering];
    if (self.layout != BJLIcCountDownWindowLayout_unpublish) {
        [self updateShowTimeColor];
        [self startCountTimer];
    }
}

- (void)dealloc {
    [self stopCountDownTimer];
    self.minusInTensDigitTextField.delegate = nil;
    self.minusInUnitsDigitTextField.delegate = nil;
    self.secondsInTensDigitTextField.delegate = nil;
    self.secondsInUnitsDigitTextField.delegate = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 仅用于通知上一层是否也要显示一个 overlay 来隐藏键盘，无论上层有没有，控制器内始终会显示一个 overlay
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardChangeFrameWithNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardChangeFrameWithNotification:)
                                                 name:UIKeyboardDidChangeFrameNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self hideKeyboardView];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidChangeFrameNotification
                                                  object:nil];
}

#pragma mark - private
- (void)keyboardChangeFrameWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo) {
        return;
    }
    CGRect keyboardFrame = bjl_as(userInfo[UIKeyboardFrameEndUserInfoKey], NSValue).CGRectValue;
    if (self.keyboardFrameChangeCallback) {
        self.keyboardFrameChangeCallback(keyboardFrame);
    }
}

- (void)prepareToOpen {
    self.caption = @"计时器";
    self.fixedAspectRatio = 2/1;
    self.minWindowHeight = 150.0f;
    self.minWindowWidth = 260.0f;
    
    CGFloat relativeWidth = self.minWindowWidth / (self.view.superview.frame.size.width ?: 600.0) ;
    CGFloat relativeHeight = self.minWindowHeight / (self.view.superview.frame.size.height ?: 300.0) ;
    CGFloat relativeX = (1 - relativeWidth) / 2.0;
    self.relativeRect = [self rectInBounds:CGRectMake(relativeX, (1 - relativeHeight) / 4.0, relativeWidth, relativeHeight)];
}

- (void)makeObservering {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveRevokeCountDownTimer) filter:^BOOL{
        bjl_strongify(self);
        return !self.room.loginUser.isStudent && self.layout == BJLIcCountDownWindowLayout_publish;
    } observer:^BOOL{
        bjl_strongify(self);
        if (self.layout != BJLIcCountDownWindowLayout_publish) {
            return YES;
        }
        [self updatePublishButtonSelected:NO];
        self.countDownTime = self.preCountDownTime >= 0 ? self.preCountDownTime : defaultCountDownTime;
        self.isStartTimeShouldHighlight = NO;
        [self stopCountDownTimer];
        [self updateShowTimeColor];
        [self updateShowTime];
        [self remakeConstraintsWithLayout:BJLIcCountDownWindowLayout_unpublish];
        return YES;
    }];
}

- (void)makeConstraints {
    self.view.backgroundColor = [UIColor clearColor];
    UIView *view = [BJLHitTestView new];
    view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.05];
    [self.view addSubview:view];
    [view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.topBar.bjl_bottom);
        make.bottom.equalTo(self.bottomBar.bjl_top);
    }];

    // top bar
    self.topGapLine = ({
        UIView *view = [UIView bjlic_createSeparateLine];
        view.accessibilityLabel = BJLKeypath(self, topGapLine);
        bjl_return view;
    });
    [self.topBar addSubview:self.topGapLine];
    [self.topGapLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.left.right.equalTo(self.topBar);
        make.height.equalTo(@(onePixel));
    }];

    if (self.layout != BJLIcCountDownWindowLayout_normal) {
        // bottom bar
        [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.equalTo(@(40.0));
        }];
        
        self.bottomGapLine = ({
            UIView *view = [UIView bjlic_createSeparateLine];
            view.accessibilityLabel = BJLKeypath(self, bottomGapLine);
            bjl_return view;
        });
        [self.bottomBar addSubview:self.bottomGapLine];
        [self.bottomGapLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.left.right.equalTo(self.bottomBar);
            make.height.equalTo(@(onePixel));
        }];
        
        self.publishButton = ({
            UIButton *button = [UIButton new];
            button.layer.cornerRadius = BJLIcAppearance.toolboxCornerRadius;
            button.layer.masksToBounds = YES;
            button.accessibilityLabel = BJLKeypath(self, publishButton);
            button.backgroundColor = [BJLIcTheme brandColor];
            button.titleLabel.font = [UIFont systemFontOfSize:14.0];
            [button setTitle:@"开始" forState:UIControlStateNormal];
            [button setTitleColor:BJLIcTheme.buttonTextColor forState:UIControlStateNormal];
            [button setTitle:@"撤回" forState:UIControlStateSelected];
            [button setTitleColor:[BJLIcTheme subButtonBackgroundColor] forState:UIControlStateSelected];
            [button setTitleColor:BJLIcTheme.subButtonTextColor forState:UIControlStateSelected];
            [button addTarget:self action:@selector(updateCountDownPublish) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        [self.bottomBar addSubview:self.publishButton];
        [self.publishButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.center.equalTo(self.bottomBar);
            make.top.bottom.equalTo(self.bottomBar).inset(8.0);
            make.width.equalTo(@80.0);
        }];
    }
    
    // comtent view
    self.containerView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view.backgroundColor = [UIColor clearColor];
        bjl_return view;
    });
    [self setContentViewController:nil contentView:self.containerView];
    
    UITapGestureRecognizer *tapGesture = ({
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboardView)];
        tapGesture.numberOfTapsRequired = 1;
        tapGesture;
    });
    // overlay
    self.overlayView = ({
        UIView *view = [UIView new];
        view.userInteractionEnabled = YES;
        view.backgroundColor = [UIColor clearColor];
        [view addGestureRecognizer:tapGesture];
        view.accessibilityLabel = BJLKeypath(self, overlayView);
        view;
    });

    self.gapView = ({
        UILabel *view = [UILabel new];
        view.accessibilityLabel = BJLKeypath(self, gapView);
        view.text = @":";
        view.font = [UIFont systemFontOfSize:40];
        view.textColor = BJLIcTheme.viewTextColor;
        bjl_return view;
    });
    [self.containerView addSubview:self.gapView];
    
    self.minusInTensDigitTextField = [self _createtextFieldWithAccessibilityLabel:BJLKeypath(self, minusInUnitsDigitTextField)];
    [self.containerView addSubview:self.minusInTensDigitTextField];
    
    self.minusInUnitsDigitTextField= [self _createtextFieldWithAccessibilityLabel:BJLKeypath(self, minusInUnitsDigitTextField)];
    [self.containerView addSubview:self.minusInUnitsDigitTextField];

    self.secondsInTensDigitTextField = [self _createtextFieldWithAccessibilityLabel:BJLKeypath(self, secondsInTensDigitTextField)];
    [self.containerView addSubview:self.secondsInTensDigitTextField];

    self.secondsInUnitsDigitTextField = [self _createtextFieldWithAccessibilityLabel:BJLKeypath(self, secondsInUnitsDigitTextField)];
    [self.containerView addSubview:self.secondsInUnitsDigitTextField];
    
    CGFloat digitWidth = 44.0f;
    CGFloat digitHeight = 54.0f;
    [self.gapView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.containerView);
        make.width.equalTo(@(10));
        make.height.equalTo(@(digitHeight));
    }];
    
    [self.minusInTensDigitTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containerView.bjl_centerY);
        make.width.equalTo(@(digitWidth));
        make.height.equalTo(@(digitHeight));
        make.top.greaterThanOrEqualTo(self.topBar.bjl_bottom);
        make.bottom.lessThanOrEqualTo(self.bottomBar.bjl_top);
        make.left.greaterThanOrEqualTo(self.containerView);
    }];
    [self.minusInUnitsDigitTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.minusInTensDigitTextField.bjl_centerY);
        make.left.equalTo(self.minusInTensDigitTextField.bjl_right).offset(10);
        make.size.equalTo(self.minusInTensDigitTextField);
        make.right.equalTo(self.gapView.bjl_left).offset(-10);
    }];
    [self.secondsInTensDigitTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.minusInTensDigitTextField.bjl_centerY);
        make.left.equalTo(self.gapView.bjl_right).offset(10);
        make.size.equalTo(self.minusInTensDigitTextField);
    }];
    [self.secondsInUnitsDigitTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.minusInTensDigitTextField.bjl_centerY);
        make.left.equalTo(self.secondsInTensDigitTextField.bjl_right).offset(10);
        make.size.equalTo(self.minusInTensDigitTextField);
        make.right.lessThanOrEqualTo(self.containerView);
    }];
}

- (void)remakeConstraintsWithLayout:(BJLIcCountDownWindowLayout)layout {
    self.layout = layout;
    
    // hidden keyboard
    [self.minusInTensDigitTextField resignFirstResponder];
    [self.minusInUnitsDigitTextField resignFirstResponder];
    [self.secondsInUnitsDigitTextField resignFirstResponder];
    [self.secondsInTensDigitTextField resignFirstResponder];
    
    BOOL userInteractionEnabled = (self.layout == BJLIcCountDownWindowLayout_unpublish) && !self.room.loginUser.isStudent;
    [self.minusInTensDigitTextField setUserInteractionEnabled:userInteractionEnabled];
    [self.minusInUnitsDigitTextField setUserInteractionEnabled:userInteractionEnabled];
    [self.secondsInUnitsDigitTextField setUserInteractionEnabled:userInteractionEnabled];
    [self.secondsInTensDigitTextField setUserInteractionEnabled:userInteractionEnabled];
    
    self.bottomBar.hidden = (self.layout == BJLIcCountDownWindowLayout_normal);
    [self updatePublishButtonSelected:(self.layout == BJLIcCountDownWindowLayout_publish)];
}

- (void)updatePublishButtonSelected:(BOOL)selected {
    self.publishButton.selected = selected;
    if (selected) {
        // 文案：撤回
        self.publishButton.backgroundColor = [BJLIcTheme subButtonBackgroundColor];
    }
    else {
        // 文案：发布
        self.publishButton.backgroundColor = [BJLIcTheme brandColor];
    }
}

#pragma mark - publish

- (void)closeCountDown {
    if (self.publishCountDownTimerCallback) {
        if (!self.publishCountDownTimerCallback(0, NO, YES)) {
            return;
        }
    }
    [self stopCountDownTimer];
    [self closeWithoutRequest];
}

- (void)hideKeyboardView {
    [self.minusInTensDigitTextField resignFirstResponder];
    [self.minusInUnitsDigitTextField resignFirstResponder];
    [self.secondsInUnitsDigitTextField resignFirstResponder];
    [self.secondsInTensDigitTextField resignFirstResponder];
    
    if ([self.overlayView respondsToSelector:@selector(removeFromSuperview)]) {
        [self.overlayView removeFromSuperview];
    }
}

#pragma mark - overrite
- (void)open {
    [self openWithoutRequest];
}

// 点击右上角x时, 如果已发布,则需要调用callback->弹框->发布撤回计时器的广播, 否则直接关闭即可
- (void)close {
    BOOL isPulish = self.publishButton.isSelected;
    if (isPulish) {
        if (self.closeCountDownTimerCallback) {
            self.closeCountDownTimerCallback();
        }
    }
    else {
        if (self.publishCountDownTimerCallback) {
            self.publishCountDownTimerCallback(0, NO, YES);
        }
        [self closeWithoutRequest];
    }
}

#pragma mark - action
// 点击发布/撤回
- (void)updateCountDownPublish {
    NSInteger minusInTensDigit = self.minusInTensDigitTextField.text.integerValue;
    NSInteger minusInUnitsDigit = self.minusInUnitsDigitTextField.text.integerValue;
    
    NSInteger secondsInTensDigit = self.secondsInTensDigitTextField.text.integerValue;
    NSInteger secondsInUnitsDigit = self.secondsInUnitsDigitTextField.text.integerValue;
    
    NSTimeInterval time = (minusInTensDigit * 10 + minusInUnitsDigit) * 60 + (secondsInTensDigit * 10 + secondsInUnitsDigit);
    BOOL isPublish = !self.publishButton.isSelected;
    if (time <= 0 && isPublish) {
        self.errorCallback(@"倒计时时间不可为0");
        return;
    }

    if (isPublish) {
        if (self.publishCountDownTimerCallback) {
            if (!self.publishCountDownTimerCallback(time, YES, NO)) {
                return;
            }
        }
    }
    else {
        if (self.revokeCountDownTimerCallback) {
            if (!self.revokeCountDownTimerCallback()) {
                return;
            }
        }
    }

    [self updatePublishButtonSelected:isPublish];
    
    if (isPublish) {
        self.countDownTime = time;
        self.preCountDownTime = time;
        self.isStartTimeShouldHighlight = (time >= hightCountDownTime);
        [self remakeConstraintsWithLayout:BJLIcCountDownWindowLayout_publish];
        [self startCountTimer];
    }
    else {
        self.countDownTime = self.preCountDownTime >= 0 ? self.preCountDownTime : defaultCountDownTime;
        self.isStartTimeShouldHighlight = NO;
        [self stopCountDownTimer];
        [self updateShowTimeColor];
        [self updateShowTime];
        [self remakeConstraintsWithLayout:BJLIcCountDownWindowLayout_unpublish];
    }
}

// 开始倒计时
- (void)startCountTimer {
    [self stopCountDownTimer];
    
    bjl_weakify(self);
    self.timer = [NSTimer bjl_scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self) {
            [timer invalidate];
            return;
        }
        
        // 倒计时结束
        if (self.countDownTime <= 0) {
            [timer invalidate];
            self.isStartTimeShouldHighlight = NO;
            [self remakeConstraintsWithLayout:BJLIcCountDownWindowLayout_unpublish];
            return;
        }

        self.countDownTime --;
        [self updateShowTimeColor];
        [self updateShowTime];
    }];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

// 销毁倒计时
- (void)stopCountDownTimer {
    if (self.timer || [self.timer isValid]) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

// 更新倒计时文案的颜色
- (void)updateShowTimeColor {
    BOOL shouldHight = (self.countDownTime <= hightCountDownTime
                        && ((self.publishButton.isSelected && self.layout == BJLIcCountDownWindowLayout_publish) || self.layout == BJLIcCountDownWindowLayout_normal)
                        && self.isStartTimeShouldHighlight);
    
    UIColor *textColor = shouldHight ? BJLIcTheme.warningColor : BJLIcTheme.viewTextColor;
    self.gapView.textColor = textColor;
    self.minusInUnitsDigitTextField.textColor = textColor;
    self.minusInTensDigitTextField.textColor = textColor;
    self.secondsInTensDigitTextField.textColor = textColor;
    self.secondsInUnitsDigitTextField.textColor = textColor;
}

// 更新倒计时
- (void)updateShowTime {
    int minutes = ((int)self.countDownTime) / 60;
    int second = ((int)self.countDownTime) % 60;
    
    int minusInTensDigit = minutes / 10;
    int minusInUnitsDigit = minutes % 10;
    
    int secondsInTensDigit = second / 10;
    int secondsInUnitsDigit = second % 10;

    self.minusInUnitsDigitTextField.text = [NSString stringWithFormat:@"%i", minusInUnitsDigit];
    self.minusInTensDigitTextField.text = [NSString stringWithFormat:@"%i", minusInTensDigit];
    self.secondsInTensDigitTextField.text = [NSString stringWithFormat:@"%i", secondsInTensDigit];
    self.secondsInUnitsDigitTextField.text = [NSString stringWithFormat:@"%i", secondsInUnitsDigit];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.minusInTensDigitTextField
        || textField == self.minusInUnitsDigitTextField
        || textField == self.secondsInTensDigitTextField
        || textField == self.secondsInUnitsDigitTextField) {
        [self.view insertSubview:self.overlayView aboveSubview:self.forgroundView];
        [self.overlayView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.view);
        }];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.minusInTensDigitTextField) {
        [self.minusInUnitsDigitTextField becomeFirstResponder];
    }
    else if (textField == self.minusInUnitsDigitTextField) {
        [self.secondsInTensDigitTextField becomeFirstResponder];
    }
    else if (textField == self.secondsInTensDigitTextField) {
        [self.secondsInUnitsDigitTextField becomeFirstResponder];
    }
    else if (textField == self.secondsInUnitsDigitTextField) {
        [self.secondsInUnitsDigitTextField resignFirstResponder];
    }
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSString *text = textField.text;
    int number = text.intValue;
    if (number >= 0 && number < 10) {
        textField.text = [NSString stringWithFormat:@"%i", number];
    }
    else {
        textField.text = @"0";
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (![self isValidDuration:newString]) {
        return NO;
    }
    int number = newString.intValue;
    if (number >= 0 && number < 10) {
        return YES;
    }
    return NO;
}

- (BOOL)isValidDuration:(NSString *)durationString {
    NSString *regex = @"[0-9]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    if ([pred evaluateWithObject:durationString]) {
        return YES;
    }
    return NO;
}

#pragma mark - wheel

- (UITextField *)_createtextFieldWithAccessibilityLabel:(NSString *)field {
    UITextField *textField = [UITextField new];
    textField.textColor = BJLIcTheme.viewTextColor;
    textField.accessibilityLabel = field;
    textField.layer.cornerRadius = BJLIcAppearance.toolboxCornerRadius;
    textField.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
    textField.font = [UIFont systemFontOfSize:36];
    textField.textAlignment = NSTextAlignmentCenter;
    textField.delegate = self;
    return textField;
}

@end
