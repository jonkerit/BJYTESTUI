//
//  BJLIcBlackboardLayoutViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcBlackboardLayoutViewController.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcBlackboardLayoutViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self->_room = room;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    
    [self makeSubviews];
    [self makeObserving];
}

- (void)didMoveToParentViewController:(nullable UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    if (parent) {
        [self remakeConstraints];
    }
}

#pragma mark - subviews

- (void)makeSubviews {
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        [self makePad1to1Subviews];
        [self setupPad1to1BlackboardView];
    }
    else {
        [self makePadUserVideoUpsideSubviews];
        [self setupPadUserVideoUpsideBlackboardView];
    }
    [self setupTouchMoveGesture];
}

- (void)remakeConstraints {
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        [self remakePad1to1ContainerViewConstraints];
    }
    else {
        [self remakePadUserVideoUpsideContainerViewConstraints];
    }
}

#pragma mark - observers

- (void)makeObserving {
    [self makeCommonObservers];
    [self makeCallbacksForVideo];
    [self makeObserversForVideo];
    [self makeObserversForDocument];
    [self makeObserversForWritingBoard];
    [self makeObeservingForCountDown];
    [self makeObeservingForQuestionAnswer];
    [self makeObeservingForQuestionResponder];
    [self makeObserversForWebPage];
    [self makeObeservingForLikeAward];
    if (!self.room.loginUser.isTeacherOrAssistant) {
        [self makeObserversForQuiz];
    }
    if (!self.room.loginUser.isTeacher) {
        [self makeObeservingForRandomChoose];
    }
}

- (void)makeCommonObservers {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, onlineUserDidExit:)
             observer:^BOOL(BJLUser *user) {
        bjl_strongify(self);
        if (user.isTeacher && self.room.loginUser.isStudent) {
            [self destroyCountDownAndResponder];
        }
        return YES;;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, liveStarted)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               return (old.boolValue != now.boolValue);
           }
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (!self.room.roomVM.liveStarted) {
                 BOOL isTeacher = self.room.loginUser.isTeacher;
                 
                 // 下课时, 结束倒计时
                 if (self.countDownViewController) {
                     [self.countDownViewController closeWithoutRequest];
                 }
                 
                 // 老师下课时, 正在抢答时, 发送抢答结束信令
                 if (self.questionResponderViewController && isTeacher) {
                     [self.questionResponderViewController closeQuestionResponder];
                 }
                 else if (self.studentResponderViewController && self.room.loginUser.isStudent) {
                     [self.studentResponderViewController hide];
                 }
                 
                 // 答题器
                 if (self.questionAnswerWindowViewController && isTeacher) {
                     [self.questionAnswerWindowViewController closeQuestionAnswer];
                 }
             }
             return YES;
         }];
    
    // 只看老师和自己的提示
    [self bjl_kvo:BJLMakeProperty(self.room.playingVM, disableAutoPlayVideoExceptTeacherAndAssistant)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now.boolValue != old.boolValue;
           }
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (!self.room.loginUser.isTeacher) {
            NSString *tipMessage = self.room.playingVM.disableAutoPlayVideoExceptTeacherAndAssistant ? @"老师已开启不看其他学生" : @"老师已取消不看其他学生";
            if (self.showErrorMessageCallback) {
                self.showErrorMessageCallback(tipMessage);
            }
        }
        return YES;
    }];
}

- (BJLObservable)setFullscreenParentViewController:(UIViewController *)parentViewController
                                superview:(nullable UIView *)superview {
    self.fullscreenParentViewController = parentViewController;
    self.fullscreenSuperview = superview;
    BJLMethodNotify((UIViewController *, UIView *), parentViewController, superview);
}

#pragma mark -

- (void)tryToHideKeyboardView {
    if (self.webViewWindowViewController) {
        [self.webViewWindowViewController hideKeyboardView];
    }
    
    if (self.countDownViewController) {
        [self.countDownViewController hideKeyboardView];
    }
    
    if (self.questionResponderViewController) {
        [self.questionResponderViewController hideKeyboardView];
    }
    
    if (self.questionAnswerWindowViewController) {
        [self.questionAnswerWindowViewController hideKeyboardView];
    }
}

- (void)destroyCountDownAndResponder {
    if (!self.room.loginUser.isStudent) {
        return;
    }
    
    if (self.countDownViewController) {
        [self.countDownViewController closeWithoutRequest];
    }
    
    if (self.studentResponderViewController) {
        [self.studentResponderViewController hide];
    }
}

- (void)updateActive:(BOOL)active {
    [self.videoListViewController updateActive:active];
}

#pragma mark - getters

@synthesize blackboardLayer = _blackboardLayer;
- (UIView *)blackboardLayer {
    if (!_blackboardLayer) {
        _blackboardLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, blackboardLayer);
            view.clipsToBounds = YES;
            [self.view addSubview:view];
            bjl_return view;
        });
    }
    return _blackboardLayer;
}

@synthesize videosLayer = _videosLayer;
- (UIView *)videosLayer {
    if (!_videosLayer) {
        _videosLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, videosLayer);
            view.clipsToBounds = YES;
            [self.view addSubview:view];
            bjl_return view;
        });
    }
    return _videosLayer;
}

- (BJLIcUserVideoListViewController *)videoListViewController {
    if (!_videoListViewController) {
        _videoListViewController = ({
            BJLIcUserVideoListViewController *videoListViewController = [[BJLIcUserVideoListViewController alloc] initWithRoom:self.room];
            bjl_return videoListViewController;
        });
    }
    return _videoListViewController;
}

- (NSMutableArray<BJLIcVideoWindowViewController *> *)displayingVideoWindows {
    if (!_displayingVideoWindows) {
        _displayingVideoWindows = [NSMutableArray array];
    }
    return _displayingVideoWindows;
}

- (NSArray<BJLWindowDisplayInfo *> *)videoWindowDisplayInfos {
    if (!_videoWindowDisplayInfos) {
        _videoWindowDisplayInfos = [NSArray array];
    }
    return _videoWindowDisplayInfos;
}

- (NSMutableArray<BJLWindowDisplayInfo *> *)mutableVideoWindowDisplayInfos {
    if (!_mutableVideoWindowDisplayInfos) {
        _mutableVideoWindowDisplayInfos = [NSMutableArray array];
    }
    return _mutableVideoWindowDisplayInfos;
}

- (NSMutableDictionary<NSString *, BJLIcDocumentWindowViewController *> *)displayingDocumentWindows {
    if (!_displayingDocumentWindows) {
        _displayingDocumentWindows = [NSMutableDictionary dictionary];
    }
    return _displayingDocumentWindows;
}

- (NSArray<BJLWindowDisplayInfo *> *)documentWindowDisplayInfos {
    if (!_documentWindowDisplayInfos) {
        _documentWindowDisplayInfos = [NSArray array];
    }
    return _documentWindowDisplayInfos;
}

- (NSMutableArray<BJLWindowDisplayInfo *> *)mutableDocumentWindowDisplayInfos {
    if (!_mutableDocumentWindowDisplayInfos) {
        _mutableDocumentWindowDisplayInfos = [NSMutableArray array];
    }
    return _mutableDocumentWindowDisplayInfos;
}

- (NSMutableDictionary <NSString *, BJLIcWritingBoradWindowViewController *> *)displayingWritingBoardWindows {
    if (!_displayingWritingBoardWindows) {
        _displayingWritingBoardWindows = [NSMutableDictionary dictionary];
    }
    return _displayingWritingBoardWindows;
}

- (NSArray<BJLWindowDisplayInfo *> *)writingBoardWindowDisplayInfos {
    if (!_writingBoardWindowDisplayInfos) {
        _writingBoardWindowDisplayInfos = [NSArray array];
    }
    return _writingBoardWindowDisplayInfos;
}

- (NSMutableArray<BJLWindowDisplayInfo *> *)mutableWritingBoardWindowDisplayInfos {
    if (!_mutableWritingBoardWindowDisplayInfos) {
        _mutableWritingBoardWindowDisplayInfos = [NSMutableArray array];
    }
    return _mutableWritingBoardWindowDisplayInfos;
}

@end

NS_ASSUME_NONNULL_END
