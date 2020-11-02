//
//  BJLScQuestionViewController+data.m
//  BJLiveUI
//
//  Created by xyp on 2020/9/28.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLScQuestionViewController+data.h"
#import "BJLScQuestionViewController+protected.h"

@implementation BJLScQuestionViewController (data)

- (void)firstRequestRefreshPage {
    BJLError *error;
    if (self.room.loginUser.isTeacherOrAssistant) {
        error = [self.unreplySource requestQuestionHistory];
        error = [self.unpublishSource requestQuestionHistory];
        error = [self.publishSource requestQuestionHistory];
    }
    else {
        error = [self.myQuestionSouece requestQuestionHistory];
        error = [self.publishSource requestQuestionHistory];
    }

    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
}

- (void)scrollToTheEndTableView {
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    [self updateUnreadMessagesTipButtonHidden:YES];
    
    if ([self atTheBottomOfTableView]) {
        // 已在最底部
        return;
    }
    
    NSInteger section = self.currentQuestionList.count - 1;
    NSInteger numberOfRows = [self.tableView numberOfRowsInSection:section];
    if (numberOfRows <= 0) {
        return;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:numberOfRows - 1
                                                inSection:section];
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:NO];
}

- (void)updateUnreadMessagesTipButtonHidden:(BOOL)hidden {
    self.unreadMessagesTipButton.hidden = hidden;
}

- (void)showUnreadMessagesTipButtonWithQuestion:(BJLQuestion *)question {
    if (self.room.loginUser.isTeacherOrAssistant) {
        [self updateUnreadMessagesTipButtonHidden:YES];
        return;
    }
    if (![self atTheBottomOfTableView]) {
        if (0 == self.segment.selectedIndex
            && [question.fromUser.number isEqualToString:self.room.loginUser.number]) {
            [self updateUnreadMessagesTipButtonHidden:NO];
        }
        else if (1 == self.segment.selectedIndex) {
            [self updateUnreadMessagesTipButtonHidden:NO];
        }
    }
}

- (BOOL)atTheBottomOfTableView {
    CGFloat contentOffsetY = self.tableView.contentOffset.y;
    CGFloat bottom = self.tableView.contentInset.bottom;
    CGFloat viewHeight = CGRectGetHeight(self.tableView.frame);
    CGFloat contentHeight = self.tableView.contentSize.height;
    CGFloat bottomOffset = contentOffsetY + viewHeight - bottom - contentHeight;
    CGFloat minCellHeight = 48.0;
    return bottomOffset >= 0.0 - minCellHeight;
}

#pragma mark - observing

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room, state)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.state == BJLRoomState_connected) {
            // 重置数据源
            if (self.room.loginUser.isTeacherOrAssistant) {
                self.unreplySource = [[BJLScQuestionDateSource alloc] initWithRoom:self.room state:BJLQuestionUnreplied isSelf:NO];
                self.unpublishSource = [[BJLScQuestionDateSource alloc] initWithRoom:self.room state:BJLQuestionUnpublished | BJLQuestionReplied isSelf:NO];
                self.publishSource = [[BJLScQuestionDateSource alloc] initWithRoom:self.room state:BJLQuestionPublished isSelf:NO];
            }
            else {
                self.myQuestionSouece = [[BJLScQuestionDateSource alloc] initWithRoom:self.room state:BJLQuestionAllState isSelf:YES];
                self.publishSource = [[BJLScQuestionDateSource alloc] initWithRoom:self.room state:BJLQuestionPublished isSelf:NO];
            }
            
            if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                return YES;
            }
            [self.tableView reloadData];
            [self updateListWithSegmentIndex:self.segment.selectedIndex];
            
            [self firstRequestRefreshPage];
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didLoadQuestionHistory:currentPage:questionCount:state:)
             observer:^BOOL(NSArray<BJLQuestion *> *history, NSInteger currentPage, BJLQuestionCount *questionCount, BJLQuestionState state) {
        bjl_strongify(self);

        /// !!!: 每个tab的请求在BJLScQuestionDateSource里面, 5个tab的请求都是一个接口, 返回的数据在这里按照state区分装填到对应的BJLScQuestionDateSource里面.
        NSInteger totalPage = 0;
        if (self.room.loginUser.isTeacherOrAssistant) {
            if (state == BJLQuestionUnreplied) {
                totalPage = (questionCount.totalCount - questionCount.replyCount) / perPageQuestionCount;
                if ((questionCount.totalCount - questionCount.replyCount) % perPageQuestionCount == 0 && totalPage > 0) {
                    totalPage --;
                }
                [self.unreplySource checkLoadLatestQuestionWithHistory:history currentPage:currentPage totalPage:totalPage];
            }
            else if (state == (BJLQuestionReplied | BJLQuestionUnpublished)) {
                totalPage = questionCount.replynopub / perPageQuestionCount;
                if (questionCount.replynopub % perPageQuestionCount == 0 && totalPage > 0) {
                    totalPage --;
                }
                [self.unpublishSource checkLoadLatestQuestionWithHistory:history currentPage:currentPage totalPage:totalPage];
            }
            else if (state == BJLQuestionPublished) {
                totalPage = questionCount.publishCount / perPageQuestionCount;
                if (questionCount.publishCount % perPageQuestionCount == 0 && totalPage > 0) {
                    totalPage --;
                }
                [self.publishSource checkLoadLatestQuestionWithHistory:history currentPage:currentPage totalPage:totalPage];
            }
        }
        else {
            if (state == BJLQuestionAllState) {
                totalPage = questionCount.totalCount / perPageQuestionCount;
                if (questionCount.totalCount % perPageQuestionCount == 0 && totalPage > 0) {
                    totalPage --;
                }
                [self.myQuestionSouece checkLoadLatestQuestionWithHistory:history currentPage:currentPage totalPage:totalPage];
            }
            else if (state == BJLQuestionPublished) {
                totalPage = questionCount.publishCount / perPageQuestionCount;;
                if (questionCount.publishCount % perPageQuestionCount == 0 && totalPage > 0) {
                    totalPage --;
                }
                [self.publishSource checkLoadLatestQuestionWithHistory:history currentPage:currentPage totalPage:totalPage];
            }
        }
        
        [self updateListWithSegmentIndex:self.segment.selectedIndex];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self.refreshControl endRefreshing];
        [self.tableView reloadData];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didSendQuestion:)
             observer:^BOOL(BJLQuestion *question) {
        bjl_strongify(self);
        [self updateSourceQuestionListWithQuestion:question];
        [self updateListWithSegmentIndex:self.segment.selectedIndex];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        // 登录用户为是学生, 发送提问的时候 不在 我的 tab, 需要切换到 我的 tab
        if (self.room.loginUser.isStudent
            && 0 != self.segment.selectedIndex) {
            self.segment.selectedIndex = 0;
        }
        [self.tableView reloadData];
        if (self.currentQuestionList.count > 1) {
            [self scrollToTheEndTableView];
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didPublishQuestion:)
             observer:^BOOL(BJLQuestion *question) {
        bjl_strongify(self);
        [self updateSourceQuestionListWithQuestion:question];
        [self updateListWithSegmentIndex:self.segment.selectedIndex];
        if (self.newMessageCallback) {
            self.newMessageCallback();
        }
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self.tableView reloadData];
        if (!self.room.loginUser.isTeacherOrAssistant) {
            // 发布页面显示红点
            [self.segment updateRedDotAtIndex:1 count:1 ignoreCount:YES];
            
            // 显示未读标致
            [self showUnreadMessagesTipButtonWithQuestion:question];
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didUnpublishQuestion:)
             observer:^BOOL(BJLQuestion *question) {
        bjl_strongify(self);
        // 取消发布问答
        [self updateSourceQuestionListWithQuestion:question];
        [self updateListWithSegmentIndex:self.segment.selectedIndex];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self.tableView reloadData];
        // 显示未读标致
        [self showUnreadMessagesTipButtonWithQuestion:question];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReplyQuestion:)
             observer:^BOOL(BJLQuestion *question) {
        bjl_strongify(self);
        // 回复问答
        [self updateSourceQuestionListWithQuestion:question];
        [self updateListWithSegmentIndex:self.segment.selectedIndex];
        if (self.newMessageCallback) {
            self.newMessageCallback();
        }
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self.tableView reloadData];
        if (!self.room.loginUser.isTeacherOrAssistant) {
            // 回复并发布,发布页面显示红点
            [self.segment updateRedDotAtIndex:1 count:1 ignoreCount:YES];
            // 显示未读标致
            [self showUnreadMessagesTipButtonWithQuestion:question];
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didSwitchQuestionForbidForUser:forbid:)
             observer:(BJLMethodFilter)^BOOL(BJLUser *user, BOOL forbid) {
        bjl_strongify(self);
        if (self.room.loginUser.isTeacherOrAssistant) {
            [self changeQuestionForbid:forbid source:self.unreplySource user:user];
            [self changeQuestionForbid:forbid source:self.unpublishSource user:user];
            [self changeQuestionForbid:forbid source:self.publishSource user:user];
        }
        else {
            [self changeQuestionForbid:forbid source:self.myQuestionSouece user:user];
            [self changeQuestionForbid:forbid source:self.publishSource user:user];
            
            if ([self.room.loginUser.number isEqualToString:user.number]) {
                self.questionButton.enabled = !forbid;
                self.questionButton.backgroundColor = forbid ? [UIColor bjl_colorWithHexString:@"#EEEEEE"] : [UIColor clearColor];
            }
        }
        
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self.tableView reloadData];
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, forbidQuestionList)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        BOOL forbidMe = [self.room.roomVM.forbidQuestionList containsObject:self.room.loginUser.number];
        self.questionButton.enabled = !forbidMe;
        self.questionButton.backgroundColor = forbidMe ? [UIColor bjl_colorWithHexString:@"#EEEEEE"] : [UIColor clearColor];
        return YES;
    }];
}

#pragma mark - method

- (void)updateSourceQuestionListWithQuestion:(BJLQuestion *)question {
    // 其他的source 先删除这个question
    if (self.room.loginUser.isTeacherOrAssistant) {
        [self _updateQuestionListWithSource:self.unreplySource question:question];
        [self _updateQuestionListWithSource:self.unpublishSource question:question];
        [self _updateQuestionListWithSource:self.publishSource question:question];
    }
    else {
        [self _updateQuestionListWithSource:self.myQuestionSouece question:question];
        [self _updateQuestionListWithSource:self.publishSource question:question];
    }
}

#pragma mark -

- (void)updateListWithSegmentIndex:(NSInteger)segmentIndex {
    // 助教或者老师
    if (self.room.loginUser.isTeacherOrAssistant) {
        switch (segmentIndex) {
            case 0:
                // 显示 未回复的, 无论是否发布
                self.currentQuestionList = self.unreplySource.questionList;
                break;
                
            case 1:
                // 显示 已回复 并且 未发布的, 需要特殊处理
                self.currentQuestionList = self.unpublishSource.questionList;
                break;
                
            case 2:
                // 显示 已发布的, 无论是否回复
                self.currentQuestionList = self.publishSource.questionList;
                break;
                
            default:
                break;
        }
    }
    // 学生
    else {
        switch (segmentIndex) {
            case 0:
                self.emptyLabel.text = @"没有提问哦~";
                self.currentQuestionList = self.myQuestionSouece.questionList;
                break;
                
            case 1:
                self.emptyLabel.text = @"没有公布的问答哦~";
                self.currentQuestionList = self.publishSource.questionList;
                break;
                
            default:
                break;
        }
    }
    [self updateQuestionEmptyViewHidden:self.currentQuestionList.count];
}

- (void)updateQuestionEmptyViewHidden:(BOOL)hidden {
    if (hidden) {
        if (self.emptyView || self.emptyLabel) {
            [self.emptyView removeFromSuperview];
            self.emptyView = nil;
            [self.emptyLabel removeFromSuperview];
            self.emptyLabel = nil;
        }
    }
    else {
        
        if (!self.emptyView || !self.emptyLabel) {
            self.emptyView = ({
                UIImageView *imageView = [UIImageView new];
                imageView.image = [UIImage bjlsc_imageNamed:@"bjl_sc_question_empty"];
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                imageView;
            });
            [self.containerView insertSubview:self.emptyView aboveSubview:self.tableView];
            [self.emptyView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.center.equalTo(self.containerView);
                make.width.equalTo(self.containerView).multipliedBy(0.4);
                make.height.equalTo(self.emptyView.bjl_width).multipliedBy(4.0/3.0);
            }];

            self.emptyLabel = ({
                UILabel *label = [UILabel new];
                label.textAlignment = NSTextAlignmentCenter;
                label.textColor = [UIColor bjl_colorWithHexString:@"#DDDEDF"];
                label.font = [UIFont systemFontOfSize:14.0];
                label;
            });
            [self.containerView insertSubview:self.emptyLabel aboveSubview:self.tableView];
            [self.emptyLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.centerX.equalTo(self.containerView);
                make.top.equalTo(self.emptyView.bjl_bottom).offset((-10.0));
            }];
            if (self.room.loginUser.isTeacherOrAssistant) {
                self.emptyLabel.text = @"还没有人提问哦~";
            }
            else {
                if (0 == self.segment.selectedIndex) {
                    self.emptyLabel.text = @"没有提问哦~";
                }
                else if (1 == self.segment.selectedIndex) {
                    self.emptyLabel.text = @"没有公布的问答哦~";
                }
            }
        }
    }
}

#pragma mark -

- (void)changeQuestionForbid:(BOOL)forbid source:(BJLScQuestionDateSource *)source user:(BJLUser *)user {
    for (BJLQuestion *question in source.questionList) {
        if ([question.fromUser.number isEqualToString:user.number]) {
            question.forbid = forbid;
        }
    }
}

- (void)_updateQuestionListWithSource:(BJLScQuestionDateSource *)source question:(BJLQuestion *)question {
    // 先把这个question从其他的souce删除, 在添加到对应state的source里面
    for (BJLQuestion *oldQuestion in [source.questionList copy]) {
        if ([oldQuestion.ID isEqualToString:question.ID]) {
            [source.questionList removeObject:oldQuestion];
            break;
        }
    }

    if (source.state == question.state || source.state == (source.state & question.state)) {
        [source updateQuestionListWithQuestion:question];
    }
    
    // 如果当前登录的是学生, 并且这个question.fromUser 是当前登录用户, 添加到myQuestionSource里面
    else if (!self.room.loginUser.isTeacherOrAssistant
        && [self.room.loginUser.number isEqualToString:question.fromUser.number]
        && [source isEqual:self.myQuestionSouece]) {
        [source updateQuestionListWithQuestion:question];
    }
}

@end
