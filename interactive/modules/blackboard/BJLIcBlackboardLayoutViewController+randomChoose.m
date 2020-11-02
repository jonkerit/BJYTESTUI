//
//  BJLIcBlackboardLayoutViewController+randomChoose.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/7/15.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+randomChoose.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"

@implementation BJLIcBlackboardLayoutViewController (randomChoose)

- (void)makeObeservingForRandomChoose {
    bjl_weakify(self);
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveRandomSelectCandidateList:choosenUser:) observer:^BOOL(NSArray <NSString *> *candidateList, BJLUser *user) {
        bjl_strongify(self);
        
        if (self.randomChooseViewController) {
            return YES;
        }
        
        BJLIcRandomChooseViewController *randomChooseViewController = [[BJLIcRandomChooseViewController alloc] initWithRoom:self.room candidates:candidateList choosenUser:user];
        if (randomChooseViewController) {
            self.randomChooseViewController = randomChooseViewController;
        }
        
        [self.randomChooseViewController setWindowedParentViewController:self superview:self.responderWindowView];
        [self.randomChooseViewController openWithoutRequest];
        return YES;
    }];
}

@end
