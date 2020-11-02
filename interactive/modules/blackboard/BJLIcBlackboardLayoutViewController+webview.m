//
//  BJLIcBlackboardLayoutViewController+webview.m
//  BJLiveUI
//
//  Created by xijia dai on 2020/6/2.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+webview.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"

@implementation BJLIcBlackboardLayoutViewController (webview)

- (void)makeObserversForWebPage {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didUpdateWebPageWithURLString:open:isCache:)
             observer:(BJLMethodObserver)^BOOL(NSString *urlString, BOOL open, BOOL isCache) {
                 bjl_strongify(self);
                 if (open) {
                     if (self.webViewWindowViewController) {
                         [self.webViewWindowViewController closeWithoutRequest];
                         self.webViewWindowViewController = nil;
                     }
                     // open 时无条件打开，仅老师有发布权限
                     if (self.room.loginUser.isTeacher) {
                         self.webViewWindowViewController = [self displayWebViewWindowWithURLString:urlString layout:BJLIcWebViewWindowLayout_publish];
                     }
                     else {
                         self.webViewWindowViewController = [self displayWebViewWindowWithURLString:urlString layout:BJLIcWebViewWindowLayout_normal];
                     }
                 }
                 else {
                     if (self.room.loginUser.isTeacher) {
                         // 关闭时，不存在网页页面时，收到的如果是缓存，不处理
                         if (!self.webViewWindowViewController) {
                             if (!isCache) {
                                 self.webViewWindowViewController = [self displayWebViewWindowWithURLString:urlString layout:BJLIcWebViewWindowLayout_unpublish];
                             }
                         }
                         else {
                             // 如果在存在窗口的时候收到了取消发布网页的请求，变成未发布状态
                             [self.webViewWindowViewController remakeConstraintsWithLayout:BJLIcWebViewWindowLayout_unpublish];
                         }
                     }
                     else {
                         // 学生和助教无条件关闭
                         if (self.webViewWindowViewController) {
                             [self.webViewWindowViewController closeWithoutRequest];
                             self.webViewWindowViewController = nil;
                         }
                     }
                 }
                 return YES;
             }];
}

- (BJLIcWebViewWindowViewController *)displayWebViewWindowWithURLString:(nullable NSString *)urlString layout:(BJLIcWebViewWindowLayout)layout {
    BJLIcWebViewWindowViewController *webviewWindow = [[BJLIcWebViewWindowViewController alloc] initWithURLString:urlString layout:layout];
    if (self.room.loginUser.isTeacherOrAssistant) {
        bjl_weakify(self);
        [webviewWindow setPublishWebViewCallback:^(NSString * _Nullable urlString, BOOL publish, BOOL close) {
            bjl_strongify(self);
            if (close) {
                self.webViewWindowViewController = nil;
            }
            [self.room.roomVM updateWebPageWithURLString:urlString open:publish];
        }];
    }
    if (self.webviewControllerKeyboardFrameChangeCallback) {
        bjl_weakify(self);
        [webviewWindow setKeyboardFrameChangeCallback:^(CGRect keyboardFrame) {
            bjl_strongify(self);
            self.webviewControllerKeyboardFrameChangeCallback(keyboardFrame, self.documentWindowsView);
        }];
    }
    if (self.closeWebviewControllerCallback) {
        bjl_weakify(self);
        [webviewWindow setCloseWebViewCallback:^{
            bjl_strongify(self);
            self.closeWebviewControllerCallback();
        }];
    }
    
    [webviewWindow setWindowedParentViewController:self superview:self.webviewWindowsView];
    [webviewWindow setFullscreenParentViewController:self.fullscreenParentViewController superview:self.fullscreenSuperview];
    [webviewWindow openWithoutRequest];
    return webviewWindow;
}

- (void)closeWebViewController {
    if (self.webViewWindowViewController) {
        [self.webViewWindowViewController closeWebView];
    }
}

- (void)openWebView {
    if (self.room.loginUser.isTeacher && !self.webViewWindowViewController) {
        self.webViewWindowViewController = [self displayWebViewWindowWithURLString:nil layout:BJLIcWebViewWindowLayout_unpublish];
    }
    else if (self.webViewWindowViewController) {
        [self.webViewWindowViewController bringToFront];
    }
}

@end
