//
//  BJLIcBlackboardLayoutViewController+questionResponder.m
//  BJLiveUI
//
//  Created by xijia dai on 2020/6/2.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+questionResponder.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"

@implementation BJLIcBlackboardLayoutViewController (questionResponder)

- (void)makeObeservingForQuestionResponder {
    bjl_weakify(self);
    // 抢答器
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveQuestionResponderWithTime:)
             observer:^BOOL(NSInteger time) {
        bjl_strongify(self);
        if (self.room.loginUser.isTeacherOrAssistant) {
            if (!self.questionResponderViewController) {
                self.questionResponderViewController = [self displayQuestionResponderWindowWithLayout:BJLIcQuestionResponderWindowLayout_publish];
            }
        }
        else if (self.room.loginUser.isStudent) {
            if (self.studentResponderViewController) {
                [self.studentResponderViewController hide];
                self.studentResponderViewController = nil;
            }
            
            self.studentResponderViewController = [self  displayQuestionResponderWindowWithCountDownTime:time];
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveCloseQuestionResponder) observer:^BOOL {
        bjl_strongify(self);
        if(self.questionResponderViewController) {
            [self.questionResponderViewController closeWithoutRequest];
            self.questionResponderViewController = nil;
        }
        
        if(self.studentResponderViewController) {
            [self.studentResponderViewController hide];
            self.studentResponderViewController = nil;
            
            if (self.room.loginUser.isStudent) {
                self.showErrorMessageCallback(@"抢答器已被收回");
            }
        }
        return YES;
    }];
    
    //    抢答器结果记录
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveEndQuestionResponderWithWinner:) observer:^BOOL(BJLUser *user) {
        bjl_strongify(self);
        if (!user) {
            return YES;
        }
        
        NSMutableArray<NSDictionary *> *list = [self.questionResponderList mutableCopy];
        if (!list) {
            list = [NSMutableArray new];
        }
        
        NSUInteger onlineUserCount = 0;
        for (BJLUser *user in self.room.onlineUsersVM.onlineUsers) {
            if (user.role == BJLUserRole_student) {
                onlineUserCount ++;
            }
        }
        
        NSDictionary *dictionary = @{
            kQuestionRecordUserKey : [[user bjlyy_modelToJSONObject] bjl_asDictionary] ?: @{},
            kQuestionRecordCountKey : @(onlineUserCount)
        };
        [list bjl_addObject:dictionary];
        self.questionResponderList = [list copy];
        return YES;
    }];
}

- (void)openQuestionResponder {
    if (self.room.loginUser.isTeacher && !self.questionResponderViewController) {
        self.questionResponderViewController = [self displayQuestionResponderWindowWithLayout:BJLIcQuestionResponderWindowLayout_normal];
    }
    else if (self.questionResponderViewController) {
        [self.questionResponderViewController bringToFront];
    }
}

- (void)closeQuestionResponderController {
    if (self.questionResponderViewController) {
        [self.questionResponderViewController closeQuestionResponder];
    }
}

- (nullable __kindof UIViewController * )displayQuestionResponderWindowWithLayout:(BJLIcQuestionResponderWindowLayout)layout {
    if (self.room.loginUser.isStudent) {
        return nil;
    }

    BJLIcQuestionResponderWindowViewController *questionResponderWindow = [[BJLIcQuestionResponderWindowViewController alloc] initWithRoom:self.room layout:layout historeQuestionList:self.questionResponderList];
    
    bjl_weakify(self);
    [questionResponderWindow setPublishQuestionResponderCallback:^BOOL(NSTimeInterval time) {
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM requestPublishQuestionResponderWithTime:time];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            return NO;
        }
        return YES;
    }];
    
    [questionResponderWindow setEndQuestionResponderCallback:^BOOL(BOOL close) {
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM endQuestionResponderWithShouldCloseWindow:close];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            return NO;
        }
        
        if (close) {
            self.questionResponderViewController = nil;
        }
        return YES;
    }];
    
    [questionResponderWindow setRevokeQuestionResponderCallback:^BOOL{
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM requestRevokeQuestionResponder];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            return NO;
        }
        return YES;
    }];
    
    [questionResponderWindow setCloseQuestionResponderCallback:^{
        bjl_strongify(self);
        [self closeQuestionResponderController];
    }];
    
    [questionResponderWindow setCloseCallback:^ {
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM requestCloseQuestionResponder];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
        }
    }];
    
    [questionResponderWindow setErrorCallback:^(NSString *message){
        bjl_strongify(self);
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(message);
        }
    }];
    
    [questionResponderWindow setKeyboardFrameChangeCallback:^(CGRect keyboardFrame) {
        bjl_strongify(self);
        if (self.webviewControllerKeyboardFrameChangeCallback) {
            self.webviewControllerKeyboardFrameChangeCallback(keyboardFrame, self.responderWindowView);
        }
    }];
    
    [questionResponderWindow setResponderSuccessCallback:^(BJLUser * _Nonnull user, UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.receiveLikeCallback) {
            self.receiveLikeCallback(user, button);
        }
    }];

    [questionResponderWindow setWindowedParentViewController:self superview:self.responderWindowView];
    [questionResponderWindow openWithoutRequest];
    return questionResponderWindow;
}

- (nullable __kindof UIViewController *)displayQuestionResponderWindowWithCountDownTime:(NSInteger)time {
    if (!self.room.loginUser.isStudent) {
        return nil;
    }
    BJLIcStudentQuestionResponderViewController *responderVC = [[BJLIcStudentQuestionResponderViewController alloc] initWithRoom:self.room countDownTime:time];
    
    bjl_weakify(self);
    [responderVC setErrorCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(message);
        }
    }];
    [responderVC setResponderCallback:^{
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM submitQuestionResponder];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            return NO;
        }
        return YES;
    }];
    [responderVC setResponderSuccessCallback:^(BJLUser * _Nonnull user, UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.receiveLikeCallback) {
            self.receiveLikeCallback(user, button);
        }
    }];
    
    [responderVC setHiddenCallback:^void {
        bjl_strongify(self);
        self.studentResponderViewController = nil;
    }];
    
    [self bjl_addChildViewController:responderVC superview:self.responderWindowView];
    [responderVC.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.responderWindowView);
    }];
    return responderVC;
}

@end
