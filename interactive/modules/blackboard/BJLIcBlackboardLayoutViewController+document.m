//
//  BJLIcBlackboardLayoutViewController+document.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/28.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+document.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcBlackboardLayoutViewController (document)

#pragma mark - observing

- (void)makeObserversForDocument {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self, documentWindowDisplayInfos)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BJLIcDocumentWindowViewController *topDocumentViewController;
             BOOL hasFullScreenWindow = NO;
             for (BJLWindowDisplayInfo *displayInfo in [self.documentWindowDisplayInfos copy]) {
                 if (displayInfo.isFullScreen
                     || (!hasFullScreenWindow && displayInfo.isMaximized)) {
                     BJLIcDocumentWindowViewController *tempWindow = [self.displayingDocumentWindows bjl_objectForKey:displayInfo.ID
                                                                                                                class:[BJLIcDocumentWindowViewController class]];
                     if (!tempWindow) {
                         tempWindow = [self displayDocumentWindowWithID:displayInfo.ID requestUpdate:NO];
                     }
                     topDocumentViewController = tempWindow;
                     hasFullScreenWindow = displayInfo.isFullScreen;
                     // !!! no break
                 }
             }
             self.topDocumentWindowController = topDocumentViewController;
             
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self, topDocumentWindowController)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (old
                 && [old respondsToSelector:@selector(stopObserverForLaserPointView)]) {
                 // 停止上次监听
                 [old stopObserverForLaserPointView];
             }
             
             // 激光笔视图布局
             UIView *superView = now? self.topDocumentWindowController.view : self.view;
             UIView *constrantView = now? self.topDocumentWindowController.view : self.documentWindowsView;
             if (self.laserPointView.superview != superView) {
                 [self.laserPointView removeFromSuperview];
                 [superView addSubview:self.laserPointView];
             }
             
             if (now) {
                 // !!!: 前端需要 documentID 和 pageIndex
                 self.laserPointView.documentID = self.topDocumentWindowController.documentID;
                 [self bjl_kvo:BJLMakeProperty(self.topDocumentWindowController, pageIndex)
                        filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                            return now.integerValue != old.integerValue;
                        }
                      observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                          bjl_strongify(self);
                          self.laserPointView.pageIndex = now.integerValue;
                          return YES;
                      }];
                 
                 // 添加监听
                 [self.topDocumentWindowController startObserverForLaserPointView:self.laserPointView];
             }
             else {
                 self.laserPointView.documentID = BJLBlackboardID;
                 self.laserPointView.pageIndex = 0;
                 [self.laserPointView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                     make.edges.equalTo(constrantView);
                 }];
                 [self.laserPointView updateShapeShowSize:CGSizeZero];
             }
             
             return YES;
         }];
    
    // 黑板页码
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM.blackboardViewController, localPageIndex)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateBlackboardPageNumber:now.bjl_floatValue + 1];
             return YES;
         }];
    
    // 文档窗口位置更新
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didUpdateDocumentWindowWithModel:shouldReset:)
             observer:(BJLMethodObserver)^BOOL(BJLWindowUpdateModel *updateModel, BOOL shouldReset) {
                 bjl_strongify(self);
                 if (shouldReset) {
                     [self resetDocumentWindowsWithModel:updateModel];
                 }
                 else {
                     [self updateDocumentWindowWithModel:updateModel];
                 }
                 return YES;
             }];
  
}

#pragma mark - blackboard page number

- (void)updateBlackboardPageNumber:(CGFloat)pageNumber {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hidePageNumberLabel) object:nil];
    self.pageNumberLabel.hidden = NO;
    NSString *text = @"";
    if (fabs(pageNumber - round(pageNumber))  < 0.1) {
        text = [NSString stringWithFormat:@"%.0f / %.0f", round(pageNumber), (CGFloat)self.room.documentVM.blackboardContentPages];
    }
    else {
        text = [NSString stringWithFormat:@"%.1f / %.1f", pageNumber, (CGFloat)self.room.documentVM.blackboardContentPages];
    }
    if (fabs(pageNumber - 1) < 0.1 || fabs(pageNumber - self.room.documentVM.blackboardContentPages) < 0.1) {
        self.pageNumberLabel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    }
    else {
        self.pageNumberLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    }
    self.pageNumberLabel.text = text;
    [self performSelector:@selector(hidePageNumberLabel) withObject:nil afterDelay:0.5];
}

- (void)hidePageNumberLabel {
    self.pageNumberLabel.hidden = YES;
}

#pragma mark - document window

- (void)resetDocumentWindowsWithModel:(BJLWindowUpdateModel *)updateModel {
    [self closeDisplayingDocumentWindowsWithRequestUpdate:NO];
    self.documentWindowDisplayInfos = [NSArray array];
    self.mutableDocumentWindowDisplayInfos = [NSMutableArray array];
    
    BOOL foundStick = NO;
    for (BJLWindowDisplayInfo *displayInfo in updateModel.displayInfos) {
        NSString *documentID = displayInfo.ID;
        //reset窗口的时候，不应该直接使用action，应该把每一个displayinfo都展示成窗口, 区分窗口和最大化，全屏
        NSString *action = BJLWindowsUpdateAction_open;
        if(displayInfo.isFullScreen) {
            action = BJLWindowsUpdateAction_fullScreen;
        }
        else if(displayInfo.isMaximized) {
            action = BJLWindowsUpdateAction_maximize;
        }
        if(action == BJLWindowsUpdateAction_open && foundStick == NO) {
            //第一个窗户是stick
            action = BJLWindowsUpdateAction_stick;
            foundStick = YES;
        }

        [self setupDocumentWindowWithID:documentID action:action displayInfo:displayInfo];
    }
}

- (void)updateDocumentWindowWithModel:(BJLWindowUpdateModel *)updateModel {
    NSString *documentID = updateModel.ID;
    if (!documentID.length) {
        return;
    }
    
    BJLWindowDisplayInfo *newDisplayInfo;
    for (BJLWindowDisplayInfo *displayInfo in updateModel.displayInfos) {
        if ([displayInfo.ID isEqualToString:documentID]) {
            newDisplayInfo = displayInfo;
            break;
        }
    }
    
    BJLWindowDisplayInfo *oldDisplayInfo;
    for (BJLWindowDisplayInfo *displayInfo in [self.documentWindowDisplayInfos copy]) {
        if ([displayInfo.ID isEqualToString:documentID]) {
            oldDisplayInfo = displayInfo;
            break;
        }
    }
    if (oldDisplayInfo) {
        [self.mutableDocumentWindowDisplayInfos removeObject:oldDisplayInfo];
    }
    
    [self setupDocumentWindowWithID:documentID action:updateModel.action displayInfo:newDisplayInfo];
}

- (void)setupDocumentWindowWithID:(NSString *)documentID action:(NSString *)action displayInfo:(nullable BJLWindowDisplayInfo *)displayInfo {
    // 关闭
    if ([action isEqualToString:BJLWindowsUpdateAction_close]) {
        [self closeDisplayingDocumentWindowWithID:documentID requestUpdate:NO];
        self.documentWindowDisplayInfos = self.mutableDocumentWindowDisplayInfos;
        return;
    }
    
    BOOL documentExist = NO;
    for (BJLDocument *document in self.room.documentVM.allDocuments) {
        if ([document.documentID isEqualToString:documentID]) {
            documentExist = YES;
            break;
        }
    }
    if (!documentExist) {
        return;
    }
    
    BJLIcDocumentWindowViewController *window = [self.displayingDocumentWindows bjl_objectForKey:documentID
                                                                                           class:[BJLIcDocumentWindowViewController class]];
    // 打开
    if ([action isEqualToString:BJLWindowsUpdateAction_open]
        || !window) {
        window = (BJLIcDocumentWindowViewController *)[self displayDocumentWindowWithID:documentID requestUpdate:NO];
        if (displayInfo.isMaximized) {
            [window maximizeWithoutRequest];
        }
        if (displayInfo.isFullScreen) {
            [window fullScreenWithoutRequest];
        }
    }
    
    // 全屏 !!!: no else if
    if ([action isEqualToString:BJLWindowsUpdateAction_fullScreen]) {
        [window fullScreenWithoutRequest];
    }
    // 最大化
    else if ([action isEqualToString:BJLWindowsUpdateAction_maximize]) {
        [window maximizeWithoutRequest];
    }
    // 还原
    else if ([action isEqualToString:BJLWindowsUpdateAction_restore]) {
        if (displayInfo) {
            [window updateWithRelativeRect:CGRectMake(displayInfo.x, displayInfo.y, displayInfo.width, displayInfo.height)];
        }
        [window restoreWithoutRequest];
    }
    else {
        [window updateWithRelativeRect:CGRectMake(displayInfo.x, displayInfo.y, displayInfo.width, displayInfo.height)];
    }
    [window bringToFrontWithoutRequest];
    if (displayInfo) {
        [self.mutableDocumentWindowDisplayInfos bjl_addObject:displayInfo];
    }
    self.documentWindowDisplayInfos = self.mutableDocumentWindowDisplayInfos;
}

#pragma mark - display action

- (BJLIcDocumentWindowViewController *)displayDocumentWindowWithID:(NSString *)documentID requestUpdate:(BOOL)requestUpdate {
    BJLIcDocumentWindowViewController *documentWindow = [self.displayingDocumentWindows bjl_objectForKey:documentID
                                                                                                   class:[BJLIcDocumentWindowViewController class]];
    if (documentWindow) {
        // 已存在, 置顶
        [documentWindow bringToFront];
        return documentWindow;
    }
    
    // !!!: 防止同时打开多个文档时重叠, 每打开一个, x方向相对于屏幕宽度增加24
    if (self.displayingDocumentWindows.count) {
        self.documentWindowRelativeX += 24.0 / [UIScreen mainScreen].bounds.size.width;
    }
    else {
        self.documentWindowRelativeX = 0.0;
    }
    
    // open
    documentWindow = [[BJLIcDocumentWindowViewController alloc] initWithRoom:self.room documentID:documentID relativeX:self.documentWindowRelativeX];
    [documentWindow setWindowedParentViewController:self superview:self.documentWindowsView];
    [documentWindow setFullscreenParentViewController:self.fullscreenParentViewController
                                            superview:self.fullscreenSuperview];
    
    bjl_weakify(self, documentWindow);
    
    // 切换静态课件回调
    [documentWindow setSwitchToNativePPTCallback:^(UIViewController<BJLSlideshowUI> * _Nullable viewController, void (^ _Nonnull callback)(BOOL)) {
        bjl_strongify(self);
        if (self.switchToNativePPTCallback) {
            self.switchToNativePPTCallback(viewController, callback);
        }
    }];
    // 关闭窗口，移除窗口相关数据
    [documentWindow setDocumentWindowCloseCallback:^(NSString * _Nonnull documentID) {
        bjl_strongify(self);
        [self.displayingDocumentWindows removeObjectForKey:documentID];
        for (BJLWindowDisplayInfo *displayInfo in [self.mutableDocumentWindowDisplayInfos copy]) {
            if ([displayInfo.ID isEqualToString:documentID]) {
                [self.mutableDocumentWindowDisplayInfos removeObject:displayInfo];
            }
        }
        self.documentWindowDisplayInfos = self.mutableDocumentWindowDisplayInfos;
    }];
    
    // 窗口位置更新
    [documentWindow setWindowUpdateCallback:^(NSString * _Nonnull action, CGRect relativeRect) {
        bjl_strongify(self);
        BJLWindowDisplayInfo *oldDisplayInfo;
        for (BJLWindowDisplayInfo *displayInfo in [self.mutableDocumentWindowDisplayInfos copy]) {
            if ([displayInfo.ID isEqualToString:documentID]) {
                oldDisplayInfo = displayInfo;
                [self.mutableDocumentWindowDisplayInfos removeObject:displayInfo];
                break;
            }
        }
        if (![action isEqualToString:BJLWindowsUpdateAction_close]) {
            BOOL shouldKeepFullScreen = (![action isEqualToString:BJLWindowsUpdateAction_restore]
                                           && ![action isEqualToString:BJLWindowsUpdateAction_maximize]);
            BOOL shouldCKeepMaximize = (![action isEqualToString:BJLWindowsUpdateAction_restore]
                                         && ![action isEqualToString:BJLWindowsUpdateAction_fullScreen]);
            BJLWindowDisplayInfo *newDisplayInfo = ({
                BJLWindowDisplayInfo *info = [[BJLWindowDisplayInfo alloc] init];
                info.ID = documentID;
                info.x = CGRectGetMinX(relativeRect);
                info.y = CGRectGetMinY(relativeRect);
                info.width = CGRectGetWidth(relativeRect);
                info.height = CGRectGetHeight(relativeRect);
                info.isFullScreen = ([action isEqualToString:BJLWindowsUpdateAction_fullScreen]
                                     || (oldDisplayInfo.isFullScreen && shouldKeepFullScreen));
                info.isMaximized = ([action isEqualToString:BJLWindowsUpdateAction_maximize]
                                    || (oldDisplayInfo.isMaximized && shouldCKeepMaximize));
                info;
            });
            [self.mutableDocumentWindowDisplayInfos bjl_addObject:newDisplayInfo];
        }
        self.documentWindowDisplayInfos = self.mutableDocumentWindowDisplayInfos;
        
        if (self.room.loginUser.isTeacherOrAssistant) {
            [self.room.documentVM updateDocumentWindowWithID:documentID
                                                      action:action
                                                displayInfos:self.documentWindowDisplayInfos];
        }
    }];
    
    [self bjl_observe:BJLMakeMethod(self, setFullscreenParentViewController:superview:)
             observer:^BOOL{
                 bjl_strongify(self, documentWindow);
                 [documentWindow setFullscreenParentViewController:self.fullscreenParentViewController
                                                         superview:self.fullscreenSuperview];
                 return YES;
             }];
    
    if (requestUpdate) {
        [documentWindow open];
    }
    else {
        [documentWindow openWithoutRequest];
    }
    [self.displayingDocumentWindows bjl_setObject:documentWindow forKey:documentID];
    return documentWindow;
}

- (void)changeDocumentWithDocumentID:(NSString *)documentID pageIndex:(NSInteger)pageIndex {
    [self.room.documentVM requestTurnToDocumentID:documentID pageIndex:pageIndex];
}

- (void)switchFullScreenDocumentWindowWithID:(NSString *)documentID {
    [self restoreFullScreenAndMaximizedDocumentWindows];
    BJLIcWindowViewController *documentWindow = [self.displayingDocumentWindows bjl_objectForKey:documentID];
    [documentWindow bringToFront];
    [documentWindow fullscreen];
}

- (void)switchMaximizedDocumentWindowWithID:(NSString *)documentID {
    [self restoreFullScreenAndMaximizedDocumentWindows];
    BJLIcWindowViewController *documentWindow = [self.displayingDocumentWindows bjl_objectForKey:documentID];
    [documentWindow bringToFront];
    [documentWindow maximize];
}

- (void)restoreFullScreenAndMaximizedDocumentWindows {
    // 普通文档
    for (BJLWindowDisplayInfo *displayInfo in [self.documentWindowDisplayInfos copy]) {
        if (displayInfo.isFullScreen || displayInfo.isMaximized) {
            BJLIcDocumentWindowViewController *window = [self.displayingDocumentWindows bjl_objectForKey:displayInfo.ID
                                                                                                   class:[BJLIcDocumentWindowViewController class]];
            [window restore];
        }
    }
}

- (void)getMainMaximizedDisplayInfo:(BJLWindowDisplayInfo * _Nullable * _Nullable)mainMaximizedDisplayInfo
          mainFullScreenDisplayInfo:(BJLWindowDisplayInfo * _Nullable * _Nullable)mainFullScreenDisplayInfo {
    if (!self.documentWindowDisplayInfos.count
        || !mainMaximizedDisplayInfo
        || !mainFullScreenDisplayInfo) {
        return;
    }
    // 数组逆序遍历的第一个全屏或者最大化的窗口是当前窗口
    for (BJLWindowDisplayInfo *windowDisplayInfo in [self.documentWindowDisplayInfos reverseObjectEnumerator]) {
        // 存在全屏
        if (windowDisplayInfo.isFullScreen && !*mainMaximizedDisplayInfo) {
            *mainFullScreenDisplayInfo = windowDisplayInfo;
            break;
        }
        // 存在最大化
        if (windowDisplayInfo.isMaximized && !*mainFullScreenDisplayInfo) {
            *mainMaximizedDisplayInfo = windowDisplayInfo;
            break;
        }
    }
}

- (void)closeDisplayingDocumentWindowsWithRequestUpdate:(BOOL)requestUpdate {
    [[self.displayingDocumentWindows copy] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        BJLIcDocumentWindowViewController *window = bjl_as(obj, BJLIcDocumentWindowViewController);
        if (requestUpdate) {
            [window close];
        }
        else {
            [window closeWithoutRequest];
        }
    }];
}

- (void)closeDisplayingDocumentWindowWithID:(NSString *)documentID requestUpdate:(BOOL)requestUpdate {
    BJLIcDocumentWindowViewController *window = bjl_as([self.displayingDocumentWindows objectForKey:documentID], BJLIcDocumentWindowViewController);
    if (requestUpdate) {
        [window close];
    }
    else {
        [window closeWithoutRequest];
    }
}

- (void)addImageShapeToBlackboardWithURL:(NSString *)imageURL
                               imageSize:(CGSize)imageSize {
    [self.room.drawingVM addImageShapeWithURL:imageURL
                                relativeFrame:[self relativeFrameForImageWithSize:imageSize]
                                 toDocumentID:BJLBlackboardID
                                    pageIndex:0
                               isWritingBoard:NO];
}

- (CGRect)relativeFrameForImageWithSize:(CGSize)imageSize {
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    if (width <= 0.0
        || height <= 0.0) {
        return CGRectZero;
    }
    
    CGSize blackboardSize = bjl_set(self.blackboardView.bounds.size, {
        set.height *= self.room.documentVM.blackboardContentPages;
    });
    if (blackboardSize.width <= 0.0
        || blackboardSize.height <= 0.0) {
        return CGRectZero;
    }
    
    CGSize layoutSize = bjl_set(blackboardSize, {
        set.width -= 24.0;
        set.height -= 24.0;
    });
    
    CGFloat ratio = width / height;
    if (width > layoutSize.width) {
        width = layoutSize.width;
        height = width / ratio;
    }
    if (height > layoutSize.height) {
        height = layoutSize.width;
        width = height *ratio;
    }
    
    CGFloat y = self.room.documentVM.blackboardViewController.localPageIndex / self.room.documentVM.blackboardContentPages * blackboardSize.height + 12.0;
    
    // 防止图片显示不全
    if ((y + height) > blackboardSize.height) {
        y = blackboardSize.height - height;
    }

    CGRect rect = CGRectMake(12.0 / blackboardSize.width,
                             y / blackboardSize.height,
                             width / blackboardSize.width,
                             height / blackboardSize.height);
    return rect;
}

@end

NS_ASSUME_NONNULL_END
