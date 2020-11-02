//
//  BJLIcRoomViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-07.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import "BJLIcRoomViewController.h"
#import "BJLIcRoomViewController+private.h"

#if DEBUG && __has_include(<BJLiveBase/BJLYYFPSLabel.h>)
#import <BJLiveBase/BJLYYFPSLabel.h>
#import "BJLViewImports.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcRoomViewController ()

@property (nonatomic, readwrite, nullable) BJLRoom *room;
@property (nonatomic, nullable) BJLProgressHUD *prevHUD;
@property (nonatomic) CGRect keyboardFrame;

@end

@implementation BJLIcRoomViewController {
    BOOL _entered;
}

#pragma mark - initialize

+ (__kindof instancetype)instanceWithSecret:(NSString *)roomSecret
                                   userName:(NSString *)userName
                                 userAvatar:(nullable NSString *)userAvatar {
    BJLRoom *room = [BJLRoom roomWithSecret:roomSecret userName:userName userAvatar:userAvatar];
    return [[self alloc] initWithRoom:room];
}


+ (__kindof instancetype)instanceWithID:(NSString *)roomID
                                apiSign:(NSString *)apiSign
                                   user:(BJLUser *)user {
    BJLRoom *room = [BJLRoom roomWithID:roomID apiSign:apiSign user:user];
    return [[self alloc] initWithRoom:room];
}


- (instancetype)initWithRoom:(BJLRoom *)room {
    NSParameterAssert(room);
    self = [super init];
    if (self) {
        self.room = room;
    }
    return self;
}

- (void)dealloc {
    [self.reachabilityManager stopMonitoring];
    self.reachabilityManager = nil;
    
    [self clean];
    [self bjl_stopAllKeyValueObserving];
    [self bjl_stopAllMethodParametersObserving];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    self.view.backgroundColor = [UIColor bjl_colorWithHex:0X161D28];
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    
    [self makeLoadingController];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!_entered) {
        _entered = YES;
        [self.room enterByValidatingConflict:YES];
    }
    
    NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
    [defaultCenter addObserver:self
                      selector:@selector(keyboardDidHideWithNotification:)
                          name:UIKeyboardDidHideNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(keyboardWillChangeFrameWithNotification:)
                          name:UIKeyboardWillChangeFrameNotification
                        object:nil];
    // WKWebView 弹出全屏播放器，返回后 UI 方向、样式出问题
    // 1. 强转：Left 教室，弹出播放器、转到 Portrait、Right、Portrait，退出全屏播放器，教室竖屏显示一部分
    bjl_weakify(self);
    [defaultCenter addObserverForName:UIWindowDidBecomeKeyNotification
                               object:nil
                                queue:nil
                           usingBlock:^(NSNotification * _Nonnull note) {
        bjl_strongify(self);
        if (self.view.window.isKeyWindow) {
            UIInterfaceOrientationMask supportedOrt = self.supportedInterfaceOrientations;
            UIInterfaceOrientation targetOrt = (UIInterfaceOrientation)UIDevice.currentDevice.orientation; // == visible.interfaceOrientation // DEPRECATED
            if (!(supportedOrt & (1 << targetOrt))) {
                if (@available(iOS 13.0, *)) targetOrt = self.view.window.windowScene.interfaceOrientation;
                else targetOrt = UIApplication.sharedApplication.statusBarOrientation;
            }
            if (!(supportedOrt & (1 << targetOrt))) {
                targetOrt = self.bjl_preferredInterfaceOrientation;
            }
            UIInterfaceOrientation tempOrt = (targetOrt != UIInterfaceOrientationPortrait ? UIInterfaceOrientationPortrait : UIInterfaceOrientationPortraitUpsideDown);
            // 2. 延时强转：Left 教室，弹出播放器，退出全屏播放器，教室竖屏显示一部分
            bjl_dispatch_async_main_queue(^{
                [UIDevice.currentDevice setValue:@(tempOrt) forKey:@"orientation"];
                [UIDevice.currentDevice setValue:@(targetOrt) forKey:@"orientation"];
            });
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
    [defaultCenter removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    [defaultCenter removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [defaultCenter removeObserver:self name:UIWindowDidBecomeKeyNotification object:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

// NOTE: call `[self setNeedsUpdateOfHomeIndicatorAutoHidden]` if return value changed
- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

#pragma mark - UIViewControllerRotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return self.bjl_preferredInterfaceOrientation;
}

- (UIModalPresentationStyle)modalPresentationStyle {
    return UIModalPresentationFullScreen;
}

#pragma mark -

- (void)makeLoadingController {
    [self makeRoomObservingBeforeEnterRoom];
    bjl_weakify(self);
    // 首先添加loading视图，loading界面无视设备情况，全屏显示
    [self.view addSubview:self.loadingLayer];
    [self.loadingLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    self->_loadingViewController = [[BJLIcLoadingViewController alloc] initWithRoom:self.room];
    [self bjl_addChildViewController:self.loadingViewController superview:self.loadingLayer];
    [self.loadingViewController setExitCallback:^{
        bjl_strongify(self);
        [self exit];
    }];
    [self.loadingViewController setLoadRoomInfoSucessCallback:^{
        bjl_strongify(self);
        [BJLIcTheme setupColorWithConfig:self.room.featureConfig.customColors];
        [BJLIcAppearance sharedAppearanceWithTemplateType:self.room.roomInfo.interactiveClassTemplateType
                                          videoDefinition:self.room.featureConfig.maxVideoDefinition];
        self.view.backgroundColor = BJLIcTheme.roomBackgroundColor;
        [self makeLayoutLayer];
        [self makeWidgetLayer];
        [self makeOtherLayers];
        
        [self makeViewControllers];
        
        [self makeActions];
#if DEBUG
        [self makeDebugActions];
#endif
        [self makeRoomObserving];
    }];
    [self.loadingViewController setHideCallback:^{
        bjl_strongify(self);
        [self.loadingLayer removeFromSuperview];
        [self.toolbarViewController tryToShowCloudRecordingTipView];
    }];
    [self.loadingViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.loadingLayer);
    }];
    
    [self.view insertSubview:self.eyeProtectedLayer aboveSubview:self.loadingLayer];
    [self.eyeProtectedLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)makeViewControllers {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    
    /* stausbar */
    self->_statusBarViewController = [[BJLIcStatusBarViewController alloc] initWithRoom:self.room];
    [self bjl_addChildViewController:self.statusBarViewController superview:self.statusBar];
    [self.statusBarViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.statusBar);
    }];
    
    /* blackboard */
    
    self->_blackboardLayoutViewController = [[BJLIcBlackboardLayoutViewController alloc] initWithRoom:self.room];
    [self.blackboardLayoutViewController setFullscreenParentViewController:self superview:self.fullscreenLayer];

    /* videogrid */
    
    self->_videosGridLayoutViewController = [[BJLIcVideosGridLayoutViewController alloc] initWithRoom:self.room];

    /* tools */
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        if (iPhone) {
            [self makePhone1to1ToolsViewController];
        }
        else {
            [self makePad1to1ToolsViewController];
        }
    }
    else {
        if (iPhone) {
            [self makePhoneUserVideoUpsideToolsViewController];
        }
        else {
            [self makePadUserVideoUpsideToolsViewController];
        }
    }
    
    /* chat */
    
    self->_chatViewController = [[BJLIcChatViewController alloc] initWithRoom:self.room];
    
    /* user */
    
    self->_userViewController = [[BJLIcUserViewController alloc] initWithRoom:self.room];
    
    /* prompt */
    
    self->_promptViewController = [[BJLIcPromptViewController alloc] init];
    [self bjl_addChildViewController:self.promptViewController superview:self.popoversLayer];
    [self.promptViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.widgetLayer);
        make.height.equalTo(@(BJLIcAppearance.promptViewHeight));
    }];
    
    /* document */
    
    self->_documentFileManagerViewController = [[BJLIcDocumentFileManagerViewController alloc] initWithRoom:self.room];

    /* 举手 */
    [self.view insertSubview:self.requestSpeakinFullScreenButton aboveSubview:self.fullscreenLayer];
    [self.requestSpeakinFullScreenButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.width.equalTo(@(BJLIcAppearance.speakRequestButtonWidth));
        make.right.equalTo(self.fullscreenLayer).offset(-30);
        make.bottom.equalTo(self.fullscreenLayer).offset(-50);
    }];
    [self.requestSpeakinFullScreenButton addSubview:self.speakRequestProgressView];
    [self.speakRequestProgressView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.requestSpeakinFullScreenButton);
    }];
        
    /* express */
    
    if (self.room.featureConfig.enableExpressExport) {
        self->_expressViewController = [[BJLIcExpressViewController alloc] initWithRoom:self.room];
    }
    
#if DEBUG && __has_include(<BJLiveBase/BJLYYFPSLabel.h>)
    BJLYYFPSLabel *fpsLabel = [BJLYYFPSLabel new];
    [self.view addSubview:fpsLabel];
    [fpsLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equal.to(self.layoutLayer).inset(5.0);
        if (bjl_iPhoneXSeries()) {
            make.right.equal.to(self.view.bjl_safeAreaLayoutGuide).inset(5.0);
        }
        else {
            make.right.equal.to(self.statusBarViewController.settingButton.bjl_left).constant(- 5.0);
        }
    }];
#endif
}

- (void)makePadUserVideoUpsideToolsViewController {
    self->_toolboxViewController = [[BJLIcToolboxViewController alloc] initWithRoom:self.room];
    [self bjl_addChildViewController:self.toolboxViewController superview:self.toolbox];
    [self.toolboxViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbox);
    }];
    
    self->_toolbarViewController = [[BJLIcToolbarViewController alloc] initWithRoom:self.room];
    [self bjl_addChildViewController:self.toolbarViewController superview:self.toolbar];
    [self.toolbarViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbar);
    }];
}

- (void)makePhoneUserVideoUpsideToolsViewController {
    // 对于 userVideoUpside 的 iphone 布局，toolbar 存在控件（如举手）在 toolbox 上并需要参考 toolbox 布局
    bjl_weakify(self);
    self->_toolboxViewController = [[BJLIcToolboxViewController alloc] initWithRoom:self.room];
    [self bjl_addChildViewController:self.toolboxViewController superview:self.toolbox];
    [self.toolboxViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbox);
    }];
    
    self->_toolbarViewController = [[BJLIcToolbarViewController alloc] initWithRoom:self.room];
    [self.toolbarViewController setRequestReferenceViewCallback:^UIView * _Nonnull {
        bjl_strongify(self);
        return self.toolbox;
    }];
    [self bjl_addChildViewController:self.toolbarViewController superview:self.toolbox];
    [self.toolbarViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.bottom.right.equalTo(self.toolbox);
        make.height.equalTo(self.layoutLayer).multipliedBy(BJLIcAppearance.toolbarHeightFraction);
    }];
}

- (void)makePhone1to1ToolsViewController {
    bjl_weakify(self);
    self->_toolbarViewController = [[BJLIcToolbarViewController alloc] initWithRoom:self.room];
    [self.toolbarViewController setRequestReferenceViewCallback:^UIView * _Nonnull{
        bjl_strongify(self);
        return self.toolbox;
    }];
    [self bjl_addChildViewController:self.toolbarViewController superview:self.toolbar];
    [self.toolbarViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbar);
    }];
    
    self->_toolboxViewController = [[BJLIcToolboxViewController alloc] initWithRoom:self.room];
    [self.toolboxViewController setRequestReferenceViewCallback:^UIView * _Nonnull{
        bjl_strongify(self);
        return self.toolbar;
    }];
    
    [self bjl_addChildViewController:self.toolboxViewController superview:self.toolbox];
    [self.toolboxViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbox);
    }];
}

- (void)makePad1to1ToolsViewController {
    bjl_weakify(self);
    UIView *toolboxBackgroundView = [UIView new];
    toolboxBackgroundView.backgroundColor = BJLIcTheme.statusBackgroungColor;
    [self.toolbox addSubview:toolboxBackgroundView];
    [toolboxBackgroundView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(self.toolbox);
        make.height.equalTo(self.layoutLayer).multipliedBy(BJLIcAppearance.toolboxHeightFraction);
    }];
    self->_toolboxViewController = [[BJLIcToolboxViewController alloc] initWithRoom:self.room];
    [self bjl_addChildViewController:self.toolboxViewController superview:self.toolbox];
    [self.toolboxViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbox);
    }];
    
    self->_toolbarViewController = [[BJLIcToolbarViewController alloc] initWithRoom:self.room];
    [self.toolbarViewController setRequestReferenceViewCallback:^UIView * _Nonnull{
        bjl_strongify(self);
        return self.toolbox;
    }];
    [self bjl_addChildViewController:self.toolbarViewController superview:self.toolbar];
    [self.toolbarViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbar);
    }];
}

#pragma mark -

- (void)updateOverlayViewWithKeyboardFrame:(CGRect)keyboardFrame overlayView:(UIView *)overlayView {
    BOOL showKeyboard = NO;
    if (CGRectGetMinY(keyboardFrame) < CGRectGetHeight([UIScreen mainScreen].bounds)) {
        showKeyboard = YES;
    }
    bjl_weakify(self);
    if (showKeyboard) {
        if (self.overlayView) {
            return;
        }
        self.overlayView = [UIView new];
        [overlayView addSubview:self.overlayView];
        [overlayView sendSubviewToBack:self.overlayView];
        [self.overlayView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(overlayView);
        }];
        UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
            bjl_strongify(self);
            [self.blackboardLayoutViewController tryToHideKeyboardView];
            [self.overlayView removeFromSuperview];
            self.overlayView = nil;
        }];
        [self.overlayView addGestureRecognizer:tapGesture];
    }
    else {
        [self.overlayView removeFromSuperview];
        self.overlayView = nil;
    }
}

- (void)showProgressHUDWithText:(NSString *)text {
    if (!text.length
        || [text isEqualToString:self.prevHUD.detailsLabel.text]) {
        return;
    }
    
    BJLProgressHUD *hud = [BJLProgressHUD bjl_hudForTextWithSuperview:self.view];
    [hud bjl_makeDetailsLabelWithLabelStyle];
    hud.detailsLabel.text = text;
    hud.minShowTime = 0.0; // !!!: MUST be 0.0
    bjl_weakify(self, hud);
    hud.completionBlock = ^{
        bjl_strongify(self, hud);
        if (hud == self.prevHUD) {
            self.prevHUD = nil;
        }
    };
    
    if (self.prevHUD) {
        [self.prevHUD hideAnimated:NO];
    }
    CGFloat minY = CGRectGetMinY(self.keyboardFrame);
    if (minY > CGFLOAT_MIN) {
        hud.offset = CGPointMake(0, - (CGRectGetHeight(self.view.frame) - minY) / 2);
    }
    [hud showAnimated:NO]; // YES?
    [hud hideAnimated:YES afterDelay:BJLProgressHUDTimeInterval];
    self.prevHUD = hud;
}

- (void)exit {
    [BJLIcAppearance destroy];
    [BJLIcTheme destroy];
    if (self.room) {
        [self.room exit];
        [self clean];
    }
    else {
        [self dismissWithError:nil];
    }
}

- (void)clean {
    self->_room = nil;
}

- (void)askToExit {
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:@"确定退出教室？"
                                message:nil
                                preferredStyle:UIAlertControllerStyleAlert];
    [alert bjl_addActionWithTitle:@"确定"
                            style:UIAlertActionStyleDestructive
                          handler:^(UIAlertAction * _Nonnull action) {
                              [self exit];
                          }];
    [alert bjl_addActionWithTitle:@"取消"
                            style:UIAlertActionStyleCancel
                          handler:nil];
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alert animated:NO completion:nil];
}

- (void)dismissWithError:(nullable BJLError *)error {
    [self classViewController:self willExitWithError:nil];
    
    void (^completion)(void) = ^{
        [self classViewController:self didExitWithError:error];
    };

    UINavigationController *navigation = [self.parentViewController bjl_as:[UINavigationController class]];
    BOOL isRoot = (navigation
                   && self == navigation.topViewController
                   && self == navigation.bjl_rootViewController);
    UIViewController *outermost = isRoot ? navigation : self;

    // pop
    if (navigation && !isRoot) {
        [navigation bjl_popViewControllerAnimated:YES completion:completion];
    }
    // dismiss
    else if (!outermost.parentViewController && outermost.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:completion];
    }
    // close in `roomViewController:didExitWithError:`
    else {
        completion();
    }
}

#pragma mark - keyboard notification

- (void)keyboardDidHideWithNotification:(NSNotification *)notification {
    self.keyboardFrame = CGRectZero;
}

- (void)keyboardWillChangeFrameWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo) {
        return;
    }
    
    self.keyboardFrame = bjl_as(userInfo[UIKeyboardFrameEndUserInfoKey], NSValue).CGRectValue;
}

#pragma mark - observable methods

- (BJLObservable)classViewControllerEnterRoomSuccess:(BJLIcRoomViewController *)classViewController {
    BJLMethodNotify((BJLIcRoomViewController *),
                    classViewController);
}

- (BJLObservable)classViewController:(BJLIcRoomViewController *)classViewController
          enterRoomFailureWithError:(BJLError *)error {
    BJLMethodNotify((BJLIcRoomViewController *, BJLError *),
                    classViewController, error);
}

- (BJLObservable)classViewController:(BJLIcRoomViewController *)classViewController
                  willExitWithError:(nullable BJLError *)error {
    BJLMethodNotify((BJLIcRoomViewController *, BJLError *),
                    classViewController, error);
}

- (BJLObservable)classViewController:(BJLIcRoomViewController *)classViewController
                   didExitWithError:(nullable BJLError *)error {
    BJLMethodNotify((BJLIcRoomViewController *, BJLError *),
                    classViewController, error);
}

#pragma mark - getters

@synthesize loadingLayer = _loadingLayer;
- (UIView *)loadingLayer {
    if (!_loadingLayer) {
        _loadingLayer = ({
            UIView *view = [UIView new];
            view.backgroundColor = [UIColor clearColor];
            view.accessibilityLabel = BJLKeypath(self, loadingLayer);
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _loadingLayer;
}

@synthesize eyeProtectedLayer = _eyeProtectedLayer;
- (UIView *)eyeProtectedLayer {
    if (!_eyeProtectedLayer) {
        _eyeProtectedLayer = ({
            UIView *view = [BJLHitTestView new];
            view.backgroundColor = [UIColor bjl_colorWithHex:0XFFB139 alpha:0.07];
            view.accessibilityLabel = BJLKeypath(self, eyeProtectedLayer);
            view.hidden = YES;
            bjl_return view;
        });
    }
    return _eyeProtectedLayer;
}

@synthesize backgroundImageView = _backgroundImageView;
- (UIImageView *)backgroundImageView {
    if(!_backgroundImageView) {
        _backgroundImageView = ({
            UIImageView *backgroundView = [UIImageView new];
            backgroundView.accessibilityLabel = BJLKeypath(self, backgroundImageView);
            [backgroundView setContentMode:UIViewContentModeScaleAspectFill];
            bjl_return backgroundView;
        });
    }
    return _backgroundImageView;
}

@synthesize layoutLayer = _layoutLayer;
- (UIView *)layoutLayer {
    if (!_layoutLayer) {
        _layoutLayer = ({
            UIView *view = [UIView new];
            view.accessibilityLabel = BJLKeypath(self, layoutLayer);
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _layoutLayer;
}

@synthesize statusBar = _statusBar;
- (UIView *)statusBar {
    if (!_statusBar) {
        _statusBar = ({
            UIView *view = [UIView new];
            view.accessibilityLabel = BJLKeypath(self, statusBar);
            bjl_return view;
        });
    }
    return _statusBar;
}

@synthesize toolbar = _toolbar;
- (UIView *)toolbar {
    if (!_toolbar) {
        _toolbar = ({
            UIView *view = [UIView new];
            view.accessibilityLabel = BJLKeypath(self, toolbar);
            bjl_return view;
        });
    }
    return _toolbar;
}

@synthesize layoutContainer = _layoutContainer;
- (UIView *)layoutContainer {
    if (!_layoutContainer) {
        _layoutContainer = ({
            UIView *view = [UIView new];
            view.accessibilityLabel = BJLKeypath(self, layoutContainer);
            bjl_return view;
        });
    }
    return _layoutContainer;
}

@synthesize blackboardLayer = _blackboardLayer;
- (UIView *)blackboardLayer {
    if (!_blackboardLayer) {
        _blackboardLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, blackboardLayer);
            view.clipsToBounds = YES;
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
            bjl_return view;
        });
    }
    return _videosLayer;
}

@synthesize widgetLayer = _widgetLayer;
- (UIView *)widgetLayer {
    if (!_widgetLayer) {
        _widgetLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, widgetLayer);
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _widgetLayer;
}

@synthesize widgetContainer = _widgetContainer;
- (UIView *)widgetContainer {
    if (!_widgetContainer) {
        _widgetContainer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, widgetContainer);
            bjl_return view;
        });
    }
    return _widgetContainer;
}

@synthesize toolbox = _toolbox;
- (UIView *)toolbox {
    if (!_toolbox) {
        _toolbox = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, toolbox);
            bjl_return view;
        });
    }
    return _toolbox;
}

@synthesize settingsLayer = _settingsLayer;
- (UIView *)settingsLayer {
    if (!_settingsLayer) {
        _settingsLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, settingsLayer);
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _settingsLayer;
}

@synthesize fullscreenToolboxLayer = _fullscreenToolboxLayer;
- (UIView *)fullscreenToolboxLayer {
    if (!_fullscreenToolboxLayer) {
        _fullscreenToolboxLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, fullscreenToolboxLayer);
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _fullscreenToolboxLayer;
}

@synthesize fullscreenLayer = _fullscreenLayer;
- (UIView *)fullscreenLayer {
    if (!_fullscreenLayer) {
        _fullscreenLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, fullscreenLayer);
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _fullscreenLayer;
}

@synthesize popoversLayer = _popoversLayer;
- (UIView *)popoversLayer {
    if (!_popoversLayer) {
        _popoversLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, popoversLayer);
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _popoversLayer;
}

@synthesize lampView = _lampView;
- (UIView *)lampView {
    if (!_lampView) {
        _lampView = [BJLHitTestView new];
        _lampView.accessibilityLabel = BJLKeypath(self, lampView);
        _lampView.clipsToBounds = YES;
    }
    return _lampView;
}

@synthesize requestSpeakinFullScreenButton = _requestSpeakinFullScreenButton;
- (UIButton *)requestSpeakinFullScreenButton {
    if (!_requestSpeakinFullScreenButton) {
        _requestSpeakinFullScreenButton = ({
            UIButton *button = [UIButton new];
            button.accessibilityLabel = BJLKeypath(self, requestSpeakinFullScreenButton);
            button.layer.masksToBounds = YES;
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_speakrequest_normal"] forState:UIControlStateNormal];
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_speakrequest_unable"] forState:UIControlStateDisabled];
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_speakrequest_selected"] forState:UIControlStateSelected];
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_speakrequest_selected"] forState:UIControlStateHighlighted];
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_speakrequest_selected"] forState:UIControlStateSelected | UIControlStateHighlighted];
            button.layer.cornerRadius = BJLIcAppearance.speakRequestButtonWidth / 2;
            button.layer.borderWidth = 1.0;
            button.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
            button.hidden = YES;
            bjl_return button;
        });
    }
    return _requestSpeakinFullScreenButton;
}

- (BJLAnnularProgressView *)speakRequestProgressView {
    if (!_speakRequestProgressView) {
        _speakRequestProgressView = ({
            BJLAnnularProgressView *progressView = [BJLAnnularProgressView new];
            progressView.size = BJLIcAppearance.speakRequestButtonWidth;
            progressView.annularWidth = 2.0;
            progressView.color = [BJLIcTheme brandColor];
            progressView.userInteractionEnabled = NO;
            progressView;
        });
    }
    return _speakRequestProgressView;
}

@end

NS_ASSUME_NONNULL_END
