//
//  BJLIcBlackboardLayoutViewController+protected.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/28.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcBlackboardLayoutViewController.h"
#import "BJLIcBlackboardLayoutViewController+document.h"
#import "BJLIcBlackboardLayoutViewController+pad1to1.h"
#import "BJLIcBlackboardLayoutViewController+padUserVideoUpside.h"
#import "BJLIcBlackboardLayoutViewController+quiz.h"
#import "BJLIcBlackboardLayoutViewController+video.h"
#import "BJLIcBlackboardLayoutViewController+webview.h"
#import "BJLIcBlackboardLayoutViewController+WritingBoard.h"
#import "BJLIcBlackboardLayoutViewController+countDown.h"
#import "BJLIcBlackboardLayoutViewController+questionAnswer.h"
#import "BJLIcBlackboardLayoutViewController+questionResponder.h"
#import "BJLIcBlackboardLayoutViewController+randomChoose.h"
#import "BJLIcBlackboardLayoutViewController+award.h"
#import "BJLIcWindowViewController+protected.h"

#import "BJLIcAppearance.h"
#import "BJLIcLaserPointView.h"
#import "BJLIcUserVideoListViewController.h"
#import "BJLIcVideoWindowViewController.h"
#import "BJLIcDocumentWindowViewController.h"
#import "BJLIcWebViewWindowViewController.h"
#import "BJLIcQuizWindowViewController.h"
#import "BJLIcCountDownEditWindowViewController.h"
#import "BJLIcQuestionResponderWindowViewController.h"
#import "BJLIcStudentQuestionResponderViewController.h"
#import "BJLIcQuestionAnswerViewController.h"
#import "BJLIcStudentQuestionAnswerWindowViewController.h"
#import "BJLIcWritingBoradWindowViewController.h"
#import "BJLIcWritingBoradWindowViewController+protected.h"
#import "BJLIcRandomChooseViewController.h"
#import "BJLIcGroupLikeWindowViewController.h"
#import "BJLIcCountDownViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcBlackboardLayoutViewController () <UIScrollViewDelegate>

@property (nonatomic, readonly, weak) BJLRoom *room;

@property (nonatomic, readonly) UIView *blackboardLayer, *videosLayer;
@property (nonatomic, readwrite) UIView *blackboardView;
@property (nonatomic) UIView *responderWindowView;
@property (nonatomic) UIButton *prevStepButton, *nextStepButton;
@property (nonatomic, weak) UIViewController *fullscreenParentViewController;
@property (nonatomic, weak) UIView *fullscreenSuperview;
@property (nonatomic) UIView *documentWindowsView;
@property (nonatomic) UIView *webDocumentWindowsView;
@property (nonatomic) UIView *webviewWindowsView;
@property (nonatomic) BJLIcLaserPointView *laserPointView;
@property (nonatomic) UIPanGestureRecognizer *touchMoveGesture;

#pragma mark - document

@property (nonatomic) UILabel *pageNumberLabel;
@property (nonatomic) NSMutableDictionary<NSString *, BJLIcDocumentWindowViewController *> *displayingDocumentWindows;
@property (nonatomic, readwrite) NSArray<BJLWindowDisplayInfo *> *documentWindowDisplayInfos;
@property (nonatomic) NSMutableArray<BJLWindowDisplayInfo *> *mutableDocumentWindowDisplayInfos;
@property (nonatomic, nullable) BJLIcDocumentWindowViewController *topDocumentWindowController; // 屏幕最表层的文档窗口，用于添加激光笔视图
@property (nonatomic, nullable) UIButton *pptRemarkInfoButton;

#pragma mark - video

@property (nonatomic) UIButton *audioFileButton;
@property (nonatomic) UIView *videoWindowsView;
@property (nonatomic) UIView *alwaysMaximizeVideoWindowsView;
@property (nonatomic) BJLIcUserVideoListViewController *videoListViewController;
@property (nonatomic) NSMutableArray<BJLIcVideoWindowViewController *> *displayingVideoWindows;
@property (nonatomic, readwrite) NSArray<BJLWindowDisplayInfo *> *videoWindowDisplayInfos;
@property (nonatomic) NSMutableArray<BJLWindowDisplayInfo *> *mutableVideoWindowDisplayInfos;

#pragma mark - writingBoard

@property (nonatomic) UIView *writingBoardWindowsView;
/** 用户自己的作答窗口, 或者老师的出题窗口, 由于信息不用共享, 所以此窗口信息不会被包含在下面的窗口信息array中 */
@property (nonatomic, nullable) BJLIcWritingBoradWindowViewController *writingBoardViewController;
@property (nonatomic) NSMutableDictionary<NSString *, BJLIcWritingBoradWindowViewController *> *displayingWritingBoardWindows;
@property (nonatomic) NSArray<BJLWindowDisplayInfo *> *writingBoardWindowDisplayInfos;
@property (nonatomic) NSMutableArray<BJLWindowDisplayInfo *> *mutableWritingBoardWindowDisplayInfos;

#pragma mark - webview

// 网页
@property (nonatomic, nullable, weak) BJLIcWebViewWindowViewController *webViewWindowViewController;

#pragma mark - quiz

// 测验
@property (nonatomic, nullable, weak) BJLIcQuizWindowViewController *quizViewController;

#pragma mark - count down

// 倒计时 老师/助教窗口
@property (nonatomic, nullable, weak) BJLIcCountDownEditWindowViewController *countDownViewController;

// 倒计时 学生窗口
@property (nonatomic, nullable, weak) BJLIcCountDownViewController *studenCountDownViewController;

#pragma mark - question responder

// 本次课节所有抢答记录
@property (nonatomic, nullable) NSArray<NSDictionary *> *questionResponderList;
// 老师和助教的抢答器窗口
@property (nonatomic, nullable, weak) BJLIcQuestionResponderWindowViewController *questionResponderViewController;
// 学生的抢答器窗口
@property (nonatomic, nullable, weak) BJLIcStudentQuestionResponderViewController *studentResponderViewController;

#pragma mark - question answer

// 老师和助教答题器窗口
@property (nonatomic, nullable, weak) BJLIcQuestionAnswerViewController *questionAnswerWindowViewController;
// 学生答题器窗口
@property (nonatomic, nullable, weak) BJLIcStudentQuestionAnswerWindowViewController *studentQuestionAnswerWindowViewController;
// 防止同时打开多个文档时重叠, 每打开一个, x方向相对于屏幕宽度增加24, 当documentWindowRelativeRectX > 屏幕宽度 * 0.5, 重置 documentWindowRelativeRectX 为 0
@property (nonatomic) CGFloat documentWindowRelativeX;

#pragma mark - 随机选人

@property (nonatomic, nullable, weak) BJLIcRandomChooseViewController *randomChooseViewController;

@property (nonatomic, nullable, weak) BJLIcGroupLikeWindowViewController *groupLikeWindowViewController;

@end

NS_ASSUME_NONNULL_END
