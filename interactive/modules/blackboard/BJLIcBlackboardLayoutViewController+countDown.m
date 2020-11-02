//
//  BJLIcBlackboardLayoutViewController+countDown.m
//  BJLiveUI
//
//  Created by xijia dai on 2020/6/2.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+countDown.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"

@implementation BJLIcBlackboardLayoutViewController (countDown)

- (void)makeObeservingForCountDown {
    bjl_weakify(self);
    // 计时器
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didUpdateCountDownTimerWithTime:open:)
             observer:(BJLMethodObserver)^BOOL(NSTimeInterval time, BOOL open) {
                 bjl_strongify(self);
                 if (!open) {// 关闭, 助教和老师可以相互收到对方的关闭信令, 所有用户都关闭
                     if (self.countDownViewController) {
                         [self.countDownViewController closeWithoutRequest];
                         self.countDownViewController = nil;
                     }
                 }
                 else {// 打开
                     if (self.countDownViewController) {
                         [self.countDownViewController closeWithoutRequest];
                         self.countDownViewController = nil;
                     }

                     if (self.room.loginUser.isTeacher) {
                         self.countDownViewController = [self displayCountDownWindowWithTime:time layout:BJLIcCountDownWindowLayout_publish];
                     }
                     // 助教
                     else if (self.room.loginUser.isAssistant) {
                         self.countDownViewController = [self displayCountDownWindowWithTime:time layout:BJLIcCountDownWindowLayout_publish];
                     }
                     else {
                         if (self.studenCountDownViewController) {
                             [self.studenCountDownViewController closeWithoutRequest];
                             self.studenCountDownViewController = nil;
                         }
                         self.studenCountDownViewController = [self displayCountDownWindowWithTime:time layout:BJLIcCountDownWindowLayout_normal];
                     }
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveRevokeCountDownTimer) observer:^BOOL{
        bjl_strongify(self);
        if (self.room.loginUser.isStudent) {
            if (self.studenCountDownViewController) {
                [self.studenCountDownViewController closeWithoutRequest];
                self.studenCountDownViewController = nil;
            }
        }
        return YES;
    }];
}

- (void)openCountDownTimer {
    if (self.room.loginUser.isTeacher && !self.countDownViewController) {
        self.countDownViewController = [self displayCountDownWindowWithTime:0 layout:BJLIcCountDownWindowLayout_unpublish];
    }
    else if (self.countDownViewController) {
        [self.countDownViewController bringToFront];
    }
}

- (void)closeCountDownController {
    if (self.countDownViewController) {
        [self.countDownViewController closeCountDown];
    }
}

- (__kindof UIViewController *)displayCountDownWindowWithTime:(NSTimeInterval)time
                                                       layout:(BJLIcCountDownWindowLayout)layout {
    // 学生
    if (layout == BJLIcCountDownWindowLayout_normal) {
        BJLIcCountDownViewController *countDownViewController = [[BJLIcCountDownViewController alloc] initWithRoom:self.room];
        [countDownViewController setWindowedParentViewController:self superview:self.responderWindowView];
        [countDownViewController updateWithTime:time];
        [countDownViewController openWithoutRequest];
        return countDownViewController;
    }
    
    // 老师助教
    BJLIcCountDownEditWindowViewController *countDownViewController = [[BJLIcCountDownEditWindowViewController alloc] initWithRoom:self.room countDownTime:time layout:layout];
    
    if (self.room.loginUser.isTeacherOrAssistant) {
        bjl_weakify(self);
        [countDownViewController setPublishCountDownTimerCallback:^BOOL(NSTimeInterval time, BOOL publish, BOOL close) {
            bjl_strongify(self);
            BJLError *error = [self.room.roomVM requestUpdateCountDownTimerWithTime:time open:publish];
            
            if (error) {
                self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
                return NO;
            }

            if (close) {
                self.countDownViewController = nil;
            }
            return YES;
        }];
        
        [countDownViewController setRevokeCountDownTimerCallback:^BOOL{
            bjl_strongify(self);
            BJLError *error = [self.room.roomVM requestRevokeCountDownTimer];
            if (error) {
                self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
                return NO;
            }
            return YES;
        }];
        
        [countDownViewController setCloseCountDownTimerCallback:^{
            bjl_strongify(self);
            [self closeCountDownController];
        }];
        
        [countDownViewController setErrorCallback:^(NSString *message){
            bjl_strongify(self);
            if (self.showErrorMessageCallback) {
                self.showErrorMessageCallback(message);
            }
        }];
        
        [countDownViewController setKeyboardFrameChangeCallback:^(CGRect keyboardFrame) {
            bjl_strongify(self);
            self.webviewControllerKeyboardFrameChangeCallback(keyboardFrame, self.responderWindowView);
        }];
    }
    
    [countDownViewController setWindowedParentViewController:self superview:self.responderWindowView];
    [countDownViewController openWithoutRequest];
    return countDownViewController;
}

@end
