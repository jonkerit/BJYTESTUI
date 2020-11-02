//
//  BJLIcBlackboardLayoutViewController+questionAnswer.m
//  BJLiveUI
//
//  Created by xijia dai on 2020/6/2.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+questionAnswer.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"

@implementation BJLIcBlackboardLayoutViewController (questionAnswer)

- (void)makeObeservingForQuestionAnswer {
    bjl_weakify(self);
    // 答题器
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveQuestionAnswerSheet:) observer:^BOOL(BJLAnswerSheet * answerSheet) {
        bjl_strongify(self);
        if (self.room.loginUser.isTeacherOrAssistant) {
            if (!self.questionAnswerWindowViewController) {
                self.questionAnswerWindowViewController = [self displayQuestionAnswerWindowWithAnswerSheet:answerSheet layout:BJLIcQuestionAnswerWindowLayout_publish];
            }
        }
        else if (self.room.loginUser.isStudent && !self.room.loginUser.isAudition) {
            if(self.studentQuestionAnswerWindowViewController) {
                [self.studentQuestionAnswerWindowViewController closeWithoutRequest];
                self.studentQuestionAnswerWindowViewController = nil;
            }
            
            self.studentQuestionAnswerWindowViewController = [self displayQuestionAnswerWindowWithAnswerSheet:answerSheet];
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveCloseQuestionAnswer) observer:^BOOL {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        
        if(self.questionAnswerWindowViewController) {
            [self.questionAnswerWindowViewController closeWithoutRequest];
            self.questionAnswerWindowViewController = nil;
        }
        
        if(self.studentQuestionAnswerWindowViewController) {
            [self.studentQuestionAnswerWindowViewController closeWithoutRequest];
            self.studentQuestionAnswerWindowViewController = nil;
            
            if (self.room.loginUser.isStudent) {
                self.showErrorMessageCallback(@"答题器已被收回");
            }
        }
        
        return YES;
    }];
    
}

- (void)openQuestionAnswer {
    if (self.room.loginUser.isTeacher && !self.questionAnswerWindowViewController) {
        BJLAnswerSheet *answerSheet = [[BJLAnswerSheet alloc] initWithAnswerType:BJLAnswerSheetType_Choosen];
        self.questionAnswerWindowViewController = [self displayQuestionAnswerWindowWithAnswerSheet:answerSheet layout:BJLIcQuestionAnswerWindowLayout_normal];
    }
    else if (self.questionAnswerWindowViewController) {
        [self.questionAnswerWindowViewController bringToFront];
    }
}

- (void)closeQuestionAnswerController {
    if (self.questionAnswerWindowViewController) {
        [self.questionAnswerWindowViewController closeQuestionAnswer];
    }
}

- (__kindof UIViewController *)displayQuestionAnswerWindowWithAnswerSheet:(BJLAnswerSheet *)answerSheet
                                                                   layout:(BJLIcQuestionAnswerWindowLayout)layout {
    BJLIcQuestionAnswerViewController *questionAnswerWindow = [[BJLIcQuestionAnswerViewController alloc] initWithRoom:self.room
                                                                                                          answerSheet:answerSheet
                                                                                                               layout:layout];
    
    bjl_weakify(self);
    [questionAnswerWindow setPublishQuestionAnswerCallback:^(BJLAnswerSheet *answerSheet) {
        bjl_strongify(self);
        [self.room.roomVM requestPublishQuestionAnswerSheet:answerSheet];
    }];
    
    [questionAnswerWindow setEndQuestionAnswerCallback:^(BOOL close){
        bjl_strongify(self);
        [self.room.roomVM requestEndQuestionAnswerWithShouldSyncCloseWindow:close];
        
        if (close) {
            self.questionAnswerWindowViewController = nil;
        }
    }];

    [questionAnswerWindow setRevokeQuestionAnswerCallback:^{
        bjl_strongify(self);
        [self.room.roomVM requestRevokeQuestionAnswer];
    }];

    [questionAnswerWindow setCloseQuestionAnswerCallback:^{
        bjl_strongify(self);
        if (self.closeQuestionAnswerControllerCallback) {
            self.closeQuestionAnswerControllerCallback();
        }
    }];

    [questionAnswerWindow setRequestQuestionDetailCallback:^BOOL(NSString * _Nonnull ID) {
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM requestQuestionAnswerDetailInfoWithAnswerSheetID:ID];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            return NO;
        }
        return YES;
    }];
    
    [questionAnswerWindow setCloseCallback:^{
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM requestCloseQuestionAnswer];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
        }
    }];

    [questionAnswerWindow setErrorCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(message);
        }
    }];
    
    [questionAnswerWindow setKeyboardFrameChangeCallback:^(CGRect keyboardFrame) {
        bjl_strongify(self);
        if (self.webviewControllerKeyboardFrameChangeCallback) {
            self.webviewControllerKeyboardFrameChangeCallback(keyboardFrame, self.responderWindowView);
        }
    }];
    
    [questionAnswerWindow setWindowedParentViewController:self superview:self.responderWindowView];
    [questionAnswerWindow openWithoutRequest];
    return questionAnswerWindow;
}

- (__kindof UIViewController *)displayQuestionAnswerWindowWithAnswerSheet:(BJLAnswerSheet *)anwserSheet {
    BJLIcStudentQuestionAnswerWindowViewController *studentQuestionAnswerWindow = [[BJLIcStudentQuestionAnswerWindowViewController alloc] initWithRoom:self.room answerSheet:anwserSheet];
    
    bjl_weakify(self);
    [studentQuestionAnswerWindow setErrorCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(message);
        }
    }];

    [studentQuestionAnswerWindow setSubmitCallback:^BOOL(BJLAnswerSheet * _Nonnull answerSheet) {
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM submitQuestionAnswer:answerSheet];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            return NO;
        }
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(@"提交成功");
        }
        return YES;
    }];
    
    [studentQuestionAnswerWindow setWindowedParentViewController:self superview:self.responderWindowView];
    [studentQuestionAnswerWindow openWithoutRequest];
    return studentQuestionAnswerWindow;
}

@end
