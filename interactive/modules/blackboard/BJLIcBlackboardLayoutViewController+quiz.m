//
//  BJLIcBlackboardLayoutViewController+quiz.m
//  BJLiveUI
//
//  Created by xijia dai on 2020/6/2.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+quiz.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"

@implementation BJLIcBlackboardLayoutViewController (quiz)

- (void)makeObserversForQuiz {
    bjl_weakify(self);
    if (self.room.loginUser.isTeacher) {
        return;
    }
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveQuizMessage:)
             observer:^BOOL(NSDictionary<NSString *, id> *message) {
                 bjl_strongify(self);
        BJLIcQuizWindowViewController *window = [BJLIcQuizWindowViewController instanceWithRoom:self.room quizMessage:message];
        if (window) {
            if (self.quizViewController) {
                if   (self.cancelQuizControllerCallback) {
                    self.cancelQuizControllerCallback();
                }
                [self.quizViewController updateCloseButtonHidden:YES];
                [self.quizViewController closeWithoutRequest];
                self.quizViewController = nil;
            }
            self.quizViewController = window;
            self.quizViewController.closeWebViewCallback = ^{
                bjl_strongify(self);
                [self.quizViewController closeWithoutRequest];
                self.quizViewController = nil;
            };
            self.quizViewController.closeQuizCallback = ^{
                bjl_strongify(self);
                if (self.closeQuizControllerCallback) {
                    self.closeQuizControllerCallback();
                }
            };
            self.quizViewController.sendQuizMessageCallback = ^BJLError * _Nullable(NSDictionary<NSString *, id> * _Nonnull message) {
                bjl_strongify(self);
                return [self.room.roomVM sendQuizMessage:message];
            };
            [window setWindowedParentViewController:self superview:self.responderWindowView];
            [window openWithoutRequest];
        }
        else if(self.quizViewController) {
            [self.quizViewController didReceiveQuizMessage:message];
        }
        return YES;
    }];
        
    [self bjl_kvo:BJLMakeProperty(self.room, state)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (self.room.state == BJLRoomState_connected) {
                 if (self.quizViewController) {
                     [self.quizViewController closeWithoutRequest];
                 }
                 [self.room.roomVM sendQuizMessage:[BJLIcQuizWindowViewController quizReqMessageWithUserNumber:self.room.loginUser.number]];
             }
             return YES;
         }];
}

- (void)closeQuizController {
    if (self.quizViewController) {
        [self.quizViewController updateCloseButtonHidden:YES];
        [self.quizViewController closeWithoutRequest];
        self.quizViewController = nil;
    }
}

@end
