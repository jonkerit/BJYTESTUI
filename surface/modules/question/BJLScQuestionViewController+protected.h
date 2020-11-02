//
//  BJLScQuestionViewController+protected.h
//  BJLiveUI
//
//  Created by xyp on 2020/9/28.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLScQuestionViewController.h"

#import "BJLScAppearance.h"
#import "BJLScQuestionCell.h"
#import "BJLScQuestionOptionView.h"
#import "BJLScSegment.h"
#import "BJLHeaderRefresh.h"
#import "BJLScQuestionDateSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScQuestionViewController ()

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) NSMutableArray<BJLQuestion *> *currentQuestionList;

// 我的问题
@property (nonatomic) BJLScQuestionDateSource *myQuestionSouece;
// 待回复, 待发布, 已发布(已公布问答)
@property (nonatomic) BJLScQuestionDateSource *unreplySource, *unpublishSource, *publishSource;

@property (nonatomic) UIButton *unreadMessagesTipButton;
@property (nonatomic, nullable) BJLQuestion *replyQuestion; // nil 代表提出新问答
@property (nonatomic) BOOL loadLatestQuestion; // UI 展示最后一页问答数据

@property (nonatomic) UIPanGestureRecognizer *gesture;
@property (nonatomic, nullable) UIView *overlayView;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UIButton *questionButton;
@property (nonatomic, nullable) UIView *emptyView;
@property (nonatomic, nullable) UILabel *emptyLabel;
@property (nonatomic) BJLScSegment *segment;
@property (nonatomic, nullable) UIViewController *optionViewController;

@end

NS_ASSUME_NONNULL_END
