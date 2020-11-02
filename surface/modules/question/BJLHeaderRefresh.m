//
//  BJLHeaderRefresh.m
//  BJLiveUI
//
//  Created by 辛亚鹏 on 2020/3/14.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLHeaderRefresh.h"

static NSString *BJL_Refresh_normal_title  = @"↓ 下拉刷新";
static NSString *BJL_Refresh_pulling_title  = @"↑ 释放刷新";
static NSString *BJL_Refresh_Refreshing_title  = @"正在刷新";

typedef NS_ENUM(NSInteger, BJLRefreshState) {
    BJLRefreshStateNormal = 0,     /** 普通状态 */
    BJLRefreshStatePulling,        /** 释放刷新状态 */
    BJLRefreshStateRefreshing,     /** 正在刷新 */
};

@interface BJLHeaderRefresh()

@property (nonatomic, strong) UIView  *backgroundView;
@property (nonatomic, strong) UIScrollView *superScrollView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, assign) BJLRefreshState refreshState;
@property (assign, nonatomic) id refreshTarget;
@property (nonatomic, assign) SEL refreshAction;

// 控件的高度, 即下拉多大距离后释放触发刷新
@property (nonatomic, assign) CGFloat refreshHeight;

@end

@implementation BJLHeaderRefresh

- (instancetype)initWithTargrt:(id)target action:(SEL)action {
    return [self initWithTargrt:target action:action height:0];
}

- (instancetype)initWithTargrt:(id)target action:(SEL)action height:(CGFloat)height {
    self = [super init];
    if (self) {
        self.refreshTarget = target;
        self.refreshAction = action;
        // 小于30, 默认30
        if (height < 30.0) {
            self.refreshHeight = 30.0;
        }
        // 小于60, 默认60
        else if (height > 60.0) {
            self.refreshHeight = 60.0;
        }
        else {
            self.refreshHeight = height;
        }
        [self setupUI];
        [self updateState:BJLRefreshStateNormal];
    }
    return self;
}

- (void)dealloc {
    [self removeObservers];
}

#pragma makr - View
- (void)setupUI {
    self.tintColor = [UIColor grayColor];
//    self.tintColor = [UIColor redColor];
    
    self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.refreshHeight)];
    [self addSubview:self.backgroundView];
    
    self.label = [[UILabel alloc] init];
    self.label.textColor = [UIColor darkGrayColor];
    self.label.font = [UIFont systemFontOfSize:16];
    self.label.text = BJL_Refresh_normal_title;
    [self.label sizeToFit];
    [self.backgroundView addSubview:self.label];
    
    CGFloat labelH = self.label.bounds.size.height;
    CGFloat labelW = self.label.bounds.size.width;
    CGFloat labelX = (self.frame.size.width - labelW) / 2;
    CGFloat labelY = (self.frame.size.width - labelH) / 2;
    self.label.frame = CGRectMake(labelX, labelY, labelW, labelH);
}

#pragma mark - KVO
- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    
    // 如果不是UIScrollView，不做任何事情
    if (newSuperview && ![newSuperview isKindOfClass:[UIScrollView class]]) return;
    
    // 旧的父控件移除监听
    [self removeObservers];
    
    if ([newSuperview isKindOfClass:[UIScrollView class]]) {
        self.superScrollView = (UIScrollView *)newSuperview;
        self.superScrollView.alwaysBounceVertical = YES;
        [self.superScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)removeObservers {
    [self.superScrollView removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    CGFloat h = -self.superScrollView.contentInset.top - self.superScrollView.contentOffset.y;
    if (self.superScrollView.isDragging){
        if (self.refreshState == BJLRefreshStateNormal && (h > self.refreshHeight)) {
            [self updateState:BJLRefreshStatePulling];
        }
        else if(self.refreshState == BJLRefreshStatePulling && (h <= self.refreshHeight)) {
            [self updateState:BJLRefreshStateNormal];
        }
    }
    else {
        if (self.refreshState == BJLRefreshStatePulling) {
            [self updateState:BJLRefreshStateRefreshing];
        }
    }
    
    CGFloat pullDistance = -self.frame.origin.y;
    self.backgroundView.frame = CGRectMake(0, 0, self.frame.size.width, pullDistance);
    
    CGFloat labelH = self.label.bounds.size.height;
    CGFloat labelW = self.label.bounds.size.width;
    CGFloat labelX = (self.frame.size.width - labelW) / 2;
    self.label.frame = CGRectMake(labelX, -self.refreshHeight + pullDistance + (self.refreshHeight - labelH)/2, labelW, labelH);
}

- (void)updateState:(BJLRefreshState)refreshState {
    self.refreshState = refreshState;
    switch (refreshState) {
         case BJLRefreshStateNormal:
            self.label.hidden = NO;
            self.label.text = BJL_Refresh_normal_title;
            [self.label sizeToFit];
            break;
            
         case BJLRefreshStatePulling:
            self.label.text = BJL_Refresh_pulling_title;
            [self.label sizeToFit];
            break;
            
         case BJLRefreshStateRefreshing:
//            self.label.text = BJL_Refresh_Refreshing_title;
            self.label.hidden = YES;
            [self.label sizeToFit];
            [self beginRefreshing];
            [self doRefreshAction];
            break;
     }
}

#pragma mark - action

- (void)doRefreshAction {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (self.refreshTarget && [self.refreshTarget respondsToSelector:self.refreshAction])
        [self.refreshTarget performSelector:self.refreshAction];
#pragma clang diagnostic pop
    
}

- (void)beginRefreshing {
    [super beginRefreshing];
}

- (void)endRefreshing {
    [super endRefreshing];
    if (self.refreshState != BJLRefreshStateRefreshing) {
        return;
    }
    
    [self updateState:BJLRefreshStateNormal];
}

@end
