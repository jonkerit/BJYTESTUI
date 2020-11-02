//
//  BJLIcCountDownViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/7/23.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcCountDownViewController.h"
#import "BJLIcWindowViewController+protected.h"
#import "BJLIcAppearance.h"

#define hightCountDownTime 60

@interface BJLIcCountDownViewController ()

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) NSTimer *countDownTimer;

// 初始倒计时时间为1分钟及以上时, 倒计时从1分钟开始要变色, 否则不变色.
@property (nonatomic) BOOL isStartTimeShouldHighlight;
@property (nonatomic) NSTimeInterval countDownTime;

@property (nonatomic) UIView *containerView;
@property (nonatomic) UILabel *timeLabel;

@end

@implementation BJLIcCountDownViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self->_room = room;
        [self prepareToOpen];
    }
    return self;
}

- (void)prepareToOpen {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    self.minWindowHeight = iPhone ? 24.0f : 44.0f;
    self.minWindowWidth = iPhone ? 72.0f : 120.0f;
    self.fixedAspectRatio = self.minWindowWidth/self.minWindowHeight;
}

- (void)dealloc {
    [self stopCountDownTimer];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.layer.shadowColor = BJLIcTheme.windowShadowColor.CGColor;
    self.view.layer.shadowOffset = CGSizeMake(0, 0);
    self.view.layer.shadowRadius = BJLIcAppearance.toolboxCornerRadius;
    self.view.layer.shadowOpacity = 0.3;

    self.maximizeButtonHidden = YES;
    self.fullscreenButtonHidden = YES;
    self.doubleTapToMaximize = NO;
    self.closeButtonHidden = YES;
    self.bottomBar.hidden = YES;
    self.topBar.hidden = YES;
    self.panToResize = NO;
    self.resizeHandleImageViewHidden = YES;
    self.topBarBackgroundViewHidden = YES;
    self.backgroundView.hidden = YES;
    [self makeSubviews];
}

- (void)makeSubviews {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);

    self.containerView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view.backgroundColor = BJLIcTheme.windowBackgroundColor;
        view.layer.cornerRadius = BJLIcAppearance.toolboxCornerRadius;
        bjl_return view;
    });
        
    self.timeLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, timeLabel);
        label.textColor = BJLIcTheme.viewTextColor;
        label.font = [UIFont systemFontOfSize:iPhone ? 14 : 24];
        label.textAlignment = NSTextAlignmentCenter;
        bjl_return label;
    });

    [self.containerView addSubview:self.timeLabel];
    [self.timeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.height.equalTo(self.containerView);
    }];

    [self initialCountDownTime];
    [self startCountDownTimer];
    [self setContentViewController:nil contentView:self.containerView];
}

- (void)initialCountDownTime {
    [self updateShowTimeColor];
    [self updateShowTime];
}

#pragma mark - timer

- (void)stopCountDownTimer {
    if (self.countDownTimer || [self.countDownTimer isValid]) {
        [self.countDownTimer invalidate];
        self.countDownTimer = nil;
    }
}

- (void)startCountDownTimer {
    [self stopCountDownTimer];
    
    bjl_weakify(self);
    self.countDownTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self) {
            [timer invalidate];
            return;
        }

        // 倒计时结束
        if (self.countDownTime <= 0) {
            [timer invalidate];
            self.isStartTimeShouldHighlight = NO;
            [self initialCountDownTime];
            // 计时结束时,更新到高亮状态
            self.containerView.backgroundColor = BJLIcTheme.warningColor;
            self.timeLabel.textColor = [UIColor whiteColor];
            return;
        }
        
        self.countDownTime --;
        [self updateShowTimeColor];
        [self updateShowTime];
    }];
    [[NSRunLoop currentRunLoop] addTimer:self.countDownTimer forMode:NSRunLoopCommonModes];
}

- (void)updateShowTimeColor {
    BOOL shouldHight = self.countDownTime <= hightCountDownTime && self.isStartTimeShouldHighlight;
    UIColor *backgroundColor = shouldHight ? BJLIcTheme.warningColor : BJLIcTheme.windowBackgroundColor;
    self.containerView.backgroundColor = backgroundColor;
    UIColor *textColor = shouldHight ? [UIColor whiteColor] : BJLIcTheme.viewTextColor;
    self.timeLabel.textColor = textColor;
}

- (void)updateShowTime {
    int minutes = ((int)self.countDownTime) / 60;
    int second = ((int)self.countDownTime) % 60;
    NSString *minuteString = (minutes < 10) ? [NSString stringWithFormat:@"%02i", minutes] : [NSString stringWithFormat:@"%i", minutes];
    NSString *secondString = (second < 10) ? [NSString stringWithFormat:@"%02i", second] : [NSString stringWithFormat:@"%i", second];
    self.timeLabel.text = [NSString stringWithFormat:@"%@ : %@", minuteString, secondString];
}

#pragma mark - override

- (void)close {
    [self closeWithoutRequest];
}

- (void)closeWithoutRequest {
    [self stopCountDownTimer];
    [super closeWithoutRequest];
}

- (void)updateWithTime:(NSInteger)time {
    self.countDownTime = time;
    self.isStartTimeShouldHighlight = (time >= hightCountDownTime);
    CGSize windowAreaSize = self.windowedSuperview.bounds.size;
    if (CGSizeEqualToSize(windowAreaSize, CGSizeZero)) {
        return;
    }

    CGFloat relativeWidth = self.minWindowWidth / (windowAreaSize.width) ;
    CGFloat relativeHeight = self.minWindowHeight / (windowAreaSize.height) ;
    self.relativeRect = [self rectInBounds:CGRectMake(0.04, 0.08, relativeWidth, relativeHeight)];
}

@end

