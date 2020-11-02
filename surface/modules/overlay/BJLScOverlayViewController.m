//
//  BJLScOverlayViewController.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScOverlayViewController.h"
#import "BJLScMediaInfoView.h"

@interface BJLScOverlayViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic, weak, readwrite) UIView *contentView;
@property (nonatomic, weak, readwrite) UIViewController *viewController;
@property (nonatomic) BJLConstraint *contentViewWidthConstraint;

@end

@implementation BJLScOverlayViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super init]) {
        self.room = room;
        self.tapToHide = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    bjl_weakify(self);
    [self bjl_kvoMerge:@[BJLMakeProperty(self, contentView),
                         BJLMakeProperty(self, viewController)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (!self.contentView && !self.viewController) {
            [self hide];
        }
        return;
    }];
}

- (void)showWithContentViewController:(nullable UIViewController *)viewController contentView:(nullable UIView *)view {
    self.tapToHide = YES;
    [self removeContentViewAndViewController];
    self.viewController = viewController;
    self.contentView = view;
    if (self.viewController) {
        [self bjl_addChildViewController:self.viewController superview:self.view];
    }
    if (self.contentView) {
        [self.view addSubview:self.contentView];
    }
    if (self.showCallback) {
        self.showCallback();
    }
}

- (void)showFillContentViewController:(nullable UIViewController *)viewController contentView:(nullable BJLScMediaInfoView *)view ratio:(CGFloat)ratio {
    self.tapToHide = NO;
    [self removeContentViewAndViewController];
    self.viewController = viewController;
    self.contentView = view;
    if (self.viewController) {
        [self bjl_addChildViewController:self.viewController superview:self.view];
        [self.viewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.view);
        }];
    }
    if (self.contentView) {
        [self.view addSubview:self.contentView];
        if ([self.contentView isKindOfClass:[BJLScMediaInfoView class]]) {
            [self.contentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.view);
            }];
        }
        else {
            [self.contentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.center.equalTo(self.view);
                make.edges.equalTo(self.view).priorityHigh();
                self.contentViewWidthConstraint =  make.width.equalTo(self.contentView.bjl_height).multipliedBy(ratio).constraint;
                make.width.height.greaterThanOrEqualTo(self.view);
            }];
        }
    }
    if (self.showCallback) {
        self.showCallback();
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer *)tapGesture {
    if (self.tapToHide) {
        [self hide];
    }
    else {
        if (self.tapCallback) {
            self.tapCallback();
        }
    }
}

- (void)hide {
    [self removeContentViewAndViewController];
    [self bjl_removeFromParentViewControllerAndSuperiew];
    if (self.hideCallback) {
        self.hideCallback();
    }
}

- (void)removeContentViewAndViewController {
    if (self.viewController) {
        [self.viewController bjl_removeFromParentViewControllerAndSuperiew];
        self.viewController = nil;
    }
    if (self.contentView) {
        [self.contentView removeFromSuperview];
        self.contentView = nil;
    }
    if (self.contentViewWidthConstraint) {
        [self.contentViewWidthConstraint uninstall];
        self.contentViewWidthConstraint = nil;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (!self.tapToHide && self.tapCallback && self.contentView) {
        // 有自定义的点击事件时，并且不是点击隐藏，并且添加了 contentView，直接响应
        return YES;
    }
    if (self.tapToHide && touch.view == self.view) {
        // 点击隐藏，并且点击的视图是当前视图而不是子视图时，响应
        return YES;
    }
    // 点击不隐藏，并且没有自定义点击事件，认为在子视图处理，不响应，点击隐藏，但是点击了其他位置，不响应
    return NO;
}

@end
