//
//  BJLIcWritingBoradWindowViewController+toolbar.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveBase/BJLAuthorization.h>
#import <Photos/Photos.h>

#import "BJLIcWritingBoradWindowViewController+toolbar.h"
#import "BJLIcWritingBoradWindowViewController+protected.h"
#import "BJLIcWindowViewController+protected.h"

//#import "BJL_iCloudLoading.h"
//#import "BJLDocumentFile.h"

@implementation BJLIcWritingBoradWindowViewController (toolbar)

- (void)addGestureForToolBar {
    NSMutableArray *viewArray = [NSMutableArray arrayWithCapacity:2];
    if(self.topBar.backgroundView) {
        [viewArray addObject:self.topBar.backgroundView];
    }
    if(self.bottomBar.backgroundView) {
        [viewArray addObject:self.bottomBar.backgroundView];
    }
}

- (void)setupBoardToolBar {
    [self bjl_addChildViewController:self.bottomToolBarViewController superview:self.bottomBar];
    [self.bottomToolBarViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.bottomBar);
    }];
    
    bjl_weakify(self);
    [self.bottomToolBarViewController.publishButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [button bjl_disableForSeconds:1];
        NSString *durationString = [self.bottomToolBarViewController restrictTime];
        [self publishWithOperate:BJLWritingBoardPublishOperate_begin restrictionTimeString:durationString];
    }];
    
    self.bottomToolBarViewController.screenShotCallback = ^() {
        bjl_strongify(self);
        [self takeSnapShot];
    };
        
    self.bottomToolBarViewController.shareBoardCallback = ^() {
        bjl_strongify(self);
        [self share];
    };

    [self.bottomToolBarViewController.clearButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self askToClearWritingBoard];
    }];
    
    [self.bottomToolBarViewController.nextPageButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self nextPage];
    }];
    
    [self.bottomToolBarViewController.prevPageButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self prevPage];
    }];
    
    [self.bottomToolBarViewController.revokeButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self askToRevokeWritingBoard];
    }];
    
    [self.bottomToolBarViewController.gatherButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [button bjl_disableForSeconds:1];
        [self publishWithOperate:BJLWritingBoardPublishOperate_end restrictionTimeString:@"0"];
    }];
    
    [self.bottomToolBarViewController.submitButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self submitBoard];
    }];
    
    //分享窗口的底部关闭按钮
    [self.bottomToolBarViewController.closeButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self closeWritingBoard];
    }];
    
    [self.bottomToolBarViewController.reEditButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self reedit];
    }];

    [self.bottomToolBarViewController.rePublishButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [button bjl_disableForSeconds:1];
        [self publishWithOperate:BJLWritingBoardPublishOperate_begin restrictionTimeString:@"0"];
    }];
    
    [self.bottomToolBarViewController.restrictTimeButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if(self.showTimeInputCallBack) {
            self.showTimeInputCallBack();
        }
    }];

    [self.bottomToolBarViewController.showNickNameButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        self.bottomToolBarViewController.showNickNameButton.selected = !self.bottomToolBarViewController.showNickNameButton.selected;
        
        BOOL selected = self.bottomToolBarViewController.showNickNameButton.selected;
        
        BJLUser *currentUser = nil;
        BJLUserGroup *group = nil;
        if(selected) {
            if([self.userNumber isEqualToString:BJLWritingboardUserNumberForTeacher]) {
                //说明当前被分享的是老师
                currentUser = self.room.onlineUsersVM.onlineTeacher;
            }
            else {
                for(BJLUser *user in self.room.documentVM.allWritingBoardParticipatedUsers) {
                    if([user.number isEqualToString:self.userNumber]) {
                        currentUser = user;
                    }
                }
            }
            
            NSInteger groupID = 0;
            if (currentUser) {
                for (BJLUser *user in self.room.onlineUsersVM.onlineUsers) {
                    if ([user.number isEqualToString:currentUser.number]) {
                        groupID = user.groupID;
                        break;
                    }
                }
                for (BJLUserGroup *groupItem in self.room.onlineUsersVM.groupList) {
                    if (groupID == groupItem.groupID) {
                        group = groupItem;
                        break;
                    }
                }
            }
        }

        NSString *name = selected ? currentUser.displayName : nil;
        self.writingBoard.userName = name;
        [self updateCaptionWithName:name groupInfo:group];
        
        if(self.teacherwillRenameWritingBoardCallback) {
            self.teacherwillRenameWritingBoardCallback(self.writingBoard, self.userNumber, name, self.relativeRect);
        }
    }];
}

#pragma mark - action
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *message = error ? [NSString stringWithFormat:@"保存图片出错: %@", [error localizedDescription]] : @"图片已保存";
    [self.promptViewController enqueueWithPrompt:message];
}

- (void)takeSnapShot {
    [BJLAuthorization checkPhotosAccessAndRequest:YES callback:^(BOOL granted, UIAlertController * _Nullable alert) {
        if (granted) {
            UIGraphicsBeginImageContextWithOptions(self.collectionView.bounds.size, NO, [UIScreen mainScreen].scale);
            [self.collectionView drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
            UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            UIImageWriteToSavedPhotosAlbum(snapshotImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }
        else if (alert) {
            if (self.presentedViewController) {
                [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
            }
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)prevPage {
    if(![self isValidStatusForUserListAndToolBar]) {
        return;
    }
    
    if (self.currentIndexPath.section == BJLIcWritingboradUserlistSection_loginUser) {
        return;
    }
    else if (self.currentIndexPath.section == BJLIcWritingboradUserlistSection_activeUser) {
        NSIndexPath *preIndexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row - 1 inSection:self.currentIndexPath.section];
        if(![self isValidIndexPathInCollectionView:preIndexPath]) {
            NSIndexPath *preSectionIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_loginUser];
            if(![self isValidIndexPathInCollectionView:preSectionIndexPath]) {
                return;
            }
            else {
                self.currentIndexPath = preSectionIndexPath;
            }
        }
        else {
            self.currentIndexPath = preIndexPath;
        }
    }
    else if (self.currentIndexPath.section == BJLIcWritingboradUserlistSection_normal) {
        NSIndexPath *preIndexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row - 1 inSection:self.currentIndexPath.section];
        if(![self isValidIndexPathInCollectionView:preIndexPath]) {
            NSIndexPath *preSectionIndexPath = [NSIndexPath indexPathForRow:[self.activeParticipatedUsers count] - 1 inSection:BJLIcWritingboradUserlistSection_activeUser];
            if(![self isValidIndexPathInCollectionView:preSectionIndexPath]) {
                NSIndexPath *loginUserSectionIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_loginUser];
                if(![self isValidIndexPathInCollectionView:loginUserSectionIndexPath]) {
                    return;
                }
                else {
                    self.currentIndexPath = loginUserSectionIndexPath;
                }
            }
            else {
                self.currentIndexPath = preSectionIndexPath;
            }
        }
        else {
            self.currentIndexPath = preIndexPath;
        }
    }
    else {
        return ;
    }
        
    BJLUser *user = [self getUserForIndexPath:self.currentIndexPath];
    BOOL hasChecked = NO;
    for(BJLUser *checkedUsers in self.mutaCheckedUsers) {
        if([user.number isEqualToString:checkedUsers.number]) {
            hasChecked = YES;
            break;
        }
    }
    if(!hasChecked && user) {
        [self.mutaCheckedUsers addObject:user];
        self.checkedUsers = self.mutaCheckedUsers;
    }

    if([user.number isEqualToString:self.room.loginUser.number]) {
        self.currentShowUser = self.room.loginUser;
        self.currentLayer = BJLWritingboardUserNumberForTeacher;
    }
    else {
        self.currentShowUser = user;
        self.currentLayer = user.number;
    }
}

- (void)nextPage {
    if(![self isValidStatusForUserListAndToolBar]) {
        return;
    }

    if (self.currentIndexPath.section == BJLIcWritingboradUserlistSection_loginUser) {
        NSIndexPath *activeUserSectionIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_activeUser];
        if ([self isValidIndexPathInCollectionView:activeUserSectionIndexPath]) {
            self.currentIndexPath = activeUserSectionIndexPath;
        }
        else {
            NSIndexPath *normalSectionIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_normal];
            if ([self isValidIndexPathInCollectionView:normalSectionIndexPath]) {
                self.currentIndexPath = normalSectionIndexPath;
            }
            else {
                return;
            }
        }
    }
    else if (self.currentIndexPath.section == BJLIcWritingboradUserlistSection_activeUser) {
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row + 1 inSection:BJLIcWritingboradUserlistSection_activeUser];
        if ([self isValidIndexPathInCollectionView:nextIndexPath]) {
            self.currentIndexPath = nextIndexPath;
        }
        else {
            NSIndexPath *normalSectionIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_normal];
            if ([self isValidIndexPathInCollectionView:normalSectionIndexPath]) {
                self.currentIndexPath = normalSectionIndexPath;
            }
            else {
                return;
            }
        }
    }
    else if (self.currentIndexPath.section == BJLIcWritingboradUserlistSection_normal) {
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row + 1 inSection:BJLIcWritingboradUserlistSection_normal];
        if ([self isValidIndexPathInCollectionView:nextIndexPath]) {
            self.currentIndexPath = nextIndexPath;
        }
        else {
            return;
        }
    }
    else {
        return ;
    }

    BJLUser *user = [self getUserForIndexPath:self.currentIndexPath];
    BOOL hasChecked = NO;
    for(BJLUser *checkedUsers in self.mutaCheckedUsers) {
        if([user.number isEqualToString:checkedUsers.number]) {
            hasChecked = YES;
            break;
        }
    }
    if(!hasChecked && user) {
        [self.mutaCheckedUsers addObject:user];
        self.checkedUsers = self.mutaCheckedUsers;
    }

    if([user.number isEqualToString:self.room.loginUser.number]) {
        self.currentShowUser = self.room.loginUser;
        self.currentLayer = BJLWritingboardUserNumberForTeacher;
    }
    else {
        self.currentShowUser = user;
        self.currentLayer = user.number;
    }
}

@end
