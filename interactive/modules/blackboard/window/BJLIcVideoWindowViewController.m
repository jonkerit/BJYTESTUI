//
//  BJLIcVideoWindowViewController.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/21.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcVideoWindowViewController.h"
#import "BJLIcWindowViewController+protected.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcVideoWindowViewController ()

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic, nullable, readwrite) BJLIcUserMediaInfoView *videoView;

@end

@implementation BJLIcVideoWindowViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self->_room = room;
        [self prepareToOpen];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.shadowColor = BJLIcTheme.windowShadowColor.CGColor;
    self.view.layer.shadowOffset = CGSizeMake(0, 0);
    self.view.layer.shadowRadius = 4.0;
    self.view.layer.shadowOpacity = 0.8;
    
    [self setupObservers];
    [self setupSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 视图切换回来（比如从画廊布局切到黑板布局）时，需要将视频视图从画廊布局里重新抢回来布局
    [self updateVideoView:self.videoView];
    [self.videoView updateVideoViewConstranints];
}

#pragma mark - subviews

- (void)setupSubviews {
    if (!self
        || !self.videoView
        || !self.windowedSuperview) {
        return;
    }
    
    [self updateSubviewsLayout];
}

- (void)updateSubviewsLayout {
    [self.videoView removeFromSuperview];
    [self setContentViewController:nil contentView:self.videoView];
    
    // top bar
    [self.topBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@(0));
    }];
    
    // bottom bar
    [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@(BJLIcAppearance.userWindowDefaultBarHeight));
    }];
}

#pragma mark - observers

- (void)setupObservers {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room, loginUser)
           filter:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return !!now;
           }
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             // 权限
             BOOL isTeacherOrAssistant = self.room.loginUser.isTeacherOrAssistant;
             [self setWindowInterfaceEnabled:isTeacherOrAssistant];
             [self setWindowInterfaceEnabled:self.room.loginUser.isTeacherOrAssistant];
             return YES;
         }];
}

#pragma mark - override

- (void)close {
    if (self.videoWindowCloseCallback) {
        self.videoWindowCloseCallback(self.videoView.user.mediaID);
    }
    [super close];
}

- (void)closeWithoutRequest {
    if (self.videoWindowCloseCallback) {
        self.videoWindowCloseCallback(self.videoView.user.mediaID);
    }
    [super closeWithoutRequest];
}

- (void)setWindowedParentViewController:(UIViewController *)parentViewController superview:(nullable UIView *)superview {
    [super setWindowedParentViewController:parentViewController superview:superview];
    [self setupSubviews];
}

#pragma mark - videoview

- (void)updateVideoView:(nullable BJLIcUserMediaInfoView *)videoView {
    if (self.videoView == videoView
        && self.videoView.superview == self.view) {
        return;
    }
    [self.videoView removeFromSuperview];
    if (self.videoView != videoView) {
        self.videoView = videoView;
        self.relativeRect = [self windowRelativeRect];
    }
    [self setupSubviews];
}

- (CGRect)windowRelativeRect {
    CGSize windowAreaSize = self.windowedSuperview.bounds.size;
    if (CGSizeEqualToSize(windowAreaSize, CGSizeZero)) {
        return CGRectZero;
    }
    
    CGRect originRelativeRect = [self.windowedSuperview convertRect:self.videoView.frame fromView:self.videoView.superview];
    if (CGSizeEqualToSize(originRelativeRect.size, CGSizeZero)) {
        return CGRectZero;
    }
    
    CGFloat relativeWidth = originRelativeRect.size.width * 2.0 / windowAreaSize.width;
    CGFloat relativeHeight = [self relativeHeightWithRelativeWidth:relativeWidth width:originRelativeRect.size.width height:originRelativeRect.size.height];
    CGFloat centerX = CGRectGetMidX(originRelativeRect) / windowAreaSize.width;
    CGFloat centerY = CGRectGetMidY(originRelativeRect) / windowAreaSize.height;
    CGFloat relativeX = MIN(MAX(centerX - relativeWidth / 2.0, 0.0), 1.0 - relativeWidth);
    CGFloat relativeY = MIN(MAX(centerY - relativeHeight / 2.0, 0.0), 1.0 -  relativeHeight);
    return CGRectMake(relativeX, relativeY, relativeWidth, relativeHeight);
}

#pragma mark - private

- (void)prepareToOpen {
    self.caption = nil;
    
    self.relativeRect = ({
        CGFloat videoWidth = 1.0 / BJLIcAppearance.fullSizedVideosCount;
        // 弹出后放大 2 倍显示
        CGFloat relativeWidth = videoWidth * 2, relativeHeight = [self relativeHeightWithRelativeWidth:relativeWidth aspectRatio:BJLIcAppearance.videoAspectRatio];
        bjl_return CGRectMake(0.0, 0.0, relativeWidth, relativeHeight);
    });
    self.fixedAspectRatio = 0.0;
    
    self.topBarBackgroundViewHidden = YES;
    self.bottomBarBackgroundViewHidden = YES;
    self.resizeHandleImageViewHidden = YES;
    
    self.maximizeButtonHidden = YES;
    self.fullscreenButtonHidden = YES;
    self.closeButtonHidden = YES;
    
    self.doubleTapToMaximize = YES;
}

@end

NS_ASSUME_NONNULL_END
