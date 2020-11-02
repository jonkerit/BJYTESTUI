//
//  BJLIcBlackboardLayoutViewController+pad1to1.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/7/24.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+pad1to1.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"

@implementation BJLIcBlackboardLayoutViewController (pad1to1)

- (void)makePad1to1Subviews {
    self.blackboardView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, blackboardView);
        view.clipsToBounds = NO;
        [self.blackboardLayer addSubview:view];
        bjl_return view;
    });
    
    [self bjl_addChildViewController:self.videoListViewController superview:self.view];
    
    self.documentWindowsView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, documentWindowsView);
        [self.blackboardLayer addSubview:view];
        bjl_return view;
    });
    
    self.webDocumentWindowsView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, webDocumentWindowsView);
        [self.blackboardLayer addSubview:view];
        bjl_return view;
    });
    
    self.webviewWindowsView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, webviewWindowsView);
        [self.view addSubview:view];
        bjl_return view;
    });
    
    self.writingBoardWindowsView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, writingBoardWindowsView);
        [self.blackboardLayer addSubview:view];
        bjl_return view;
    });
    
    self.laserPointView = ({
        BJLIcLaserPointView *view = [[BJLIcLaserPointView alloc] initWithRoom:self.room];
        view.accessibilityLabel = BJLKeypath(self, laserPointView);
        [self.blackboardLayer addSubview:view];
        bjl_return view;
    });
    
    self.videoWindowsView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, videoWindowsView);
        [self.blackboardLayer addSubview:view];
        bjl_return view;
    });
    
    self.responderWindowView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, responderWindowView);
        [self.blackboardLayer addSubview:view];
        bjl_return view;
    });
    
    // page number
    self.pageNumberLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        label.hidden = YES;
        label.layer.masksToBounds = YES;
        label.layer.cornerRadius = 16.0;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14.0];
        label.accessibilityLabel = BJLKeypath(self, pageNumberLabel);
        [self.view addSubview:label];
        bjl_return label;
    });
    
    self.audioFileButton = ({
        UIButton *button = [UIButton new];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_blackboard_audiofile"]
                forState:UIControlStateNormal];
        button.userInteractionEnabled = NO;
        button.hidden = YES;
        [self.view addSubview:button];
        bjl_return button;
    });
}

- (void)remakePad1to1ContainerViewConstraints {
    // 视频窗口
    [self.videoListViewController.view bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.videosLayer);
    }];
    
    // 黑板
    [self.blackboardView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardLayer);
    }];
    
    // 文档窗口
    [self.documentWindowsView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardView);
    }];
    
    // web 文档窗口
    [self.webDocumentWindowsView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.blackboardView);
    }];
    
    // 网页窗口
    [self.webviewWindowsView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardView);
    }];
    
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    // 小黑板窗口
    [self.writingBoardWindowsView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.blackboardView);
        make.right.equalTo(self.blackboardView).offset(iPhone ? -BJLIcAppearance.toolboxWidth : 0);
    }];
    
    // 激光笔视图
    [self.laserPointView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.documentWindowsView);
    }];
    
    // 视频窗口
    [self.videoWindowsView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardView);
    }];
    
    // 答题器抢答器计时器等窗口
    [self.responderWindowView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardView);
    }];
    
    // 页码
    [self.pageNumberLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.blackboardView).offset(0.0);
        make.top.equalTo(self.blackboardView.bjl_top).offset(24.0);
        make.height.equalTo(@32.0);
        make.width.equalTo(@120.0);
    }];
    
    // 音频文件图标
    [self.audioFileButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.videoListViewController.view.bjl_top).offset(10.0);
        make.right.equalTo(self.videoListViewController.view.bjl_left).offset(-10.0);
        make.size.equal.sizeOffset(CGSizeMake(40.0, 40.0));
    }];
}

- (void)setupPad1to1BlackboardView {
    UIViewController *blackboardViewController = self.room.documentVM.blackboardViewController;
    [self bjl_addChildViewController:blackboardViewController superview:self.blackboardView];
    [blackboardViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardView);
    }];
    
    self.room.documentVM.blackboardImage = [UIImage bjl_imageWithColor:BJLIcTheme.blackboardColor];
    //小黑板默认使用新版配色值
    self.room.documentVM.writingBoardImage = [UIImage bjl_imageWithColor:BJLIcTheme.windowBackgroundColor];
}

@end
