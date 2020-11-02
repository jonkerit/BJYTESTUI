//
//  BJLScQuestionViewController.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScQuestionViewController.h"

#import "BJLScQuestionViewController+protected.h"
#import "BJLScQuestionViewController+data.h"

@interface BJLScQuestionViewController () <UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate>

@end

@implementation BJLScQuestionViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self->_room = room;
        self.replyQuestion = nil;
        self.loadLatestQuestion = NO;
        [self makeObserving];
        if (room.loginUser.isTeacherOrAssistant) {
            self.unreplySource = [[BJLScQuestionDateSource alloc] initWithRoom:self.room state:BJLQuestionUnreplied isSelf:NO];
            self.unpublishSource = [[BJLScQuestionDateSource alloc] initWithRoom:self.room state:BJLQuestionUnpublished | BJLQuestionReplied isSelf:NO];
            self.publishSource = [[BJLScQuestionDateSource alloc] initWithRoom:self.room state:BJLQuestionPublished isSelf:NO];
        }
        else {
            self.myQuestionSouece = [[BJLScQuestionDateSource alloc] initWithRoom:self.room state:BJLQuestionAllState isSelf:YES];
            self.publishSource = [[BJLScQuestionDateSource alloc] initWithRoom:self.room state:BJLQuestionPublished isSelf:NO];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self makeSubviewsAndConstraints];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self firstRequestRefreshPage];
}

#pragma mark - public method

- (void)sendQuestion:(NSString *)content {
    // 如果是超过最大长度的文本，裁剪后发送，确保能够发送出去
    if (content.length > BJLTextMaxLength_chat) {
        content = [content substringToIndex:NSMaxRange([content rangeOfComposedCharacterSequenceAtIndex:BJLTextMaxLength_chat])];
    }
    else if (content.length <= 0 || [content stringByReplacingOccurrencesOfString:@" " withString:@""].length <= 0) {
        return;
    }
    BJLError *error;
    if (self.replyQuestion) {
        error = [self.room.roomVM replyQuestionWithID:self.replyQuestion.ID state:self.replyQuestion.state reply:content];
    }
    else {
        error = [self.room.roomVM sendQuestion:content];
    }
    self.replyQuestion = nil;
    if (error) {
        [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
    }
}

- (void)clearReplyQuestion {
    self.replyQuestion = nil;
}

// 问答回复
- (void)updateQuestion:(BJLQuestion *)question reply:(NSString *)reply {
    NSError *error = [self.room.roomVM replyQuestionWithID:question.ID state:question.state reply:reply];
    if (error) {
        [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
    }
    [self updateListWithSegmentIndex:self.segment.selectedIndex];
    if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
        return;
    }
//    [self.tableView reloadData];
}

- (void)showRedDotForStudentPublishSegment {
    // 学生发布的tab显示红点
    if (!self.room.loginUser.isTeacherOrAssistant) {
        [self.segment updateRedDotAtIndex:1 count:1 ignoreCount:YES];
    }
}

#pragma mark - subviews

- (void)makeSubviewsAndConstraints {
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.clipsToBounds = YES;
    
    self.containerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self.view addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        make.bottom.equalTo(self.view);
    }];
    
    UIView *topContainerView = [UIView new];
    UIImageView *imageView = [UIImageView new];
    [imageView setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_question_icon"]];
    [topContainerView addSubview:imageView];
    [imageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.height.equalTo(@(24));
        make.left.equalTo(topContainerView).offset(BJLScViewSpaceM);
        make.centerY.equalTo(topContainerView);
    }];
    
    UILabel *label = [UILabel new];
    label.text = @"问答";
    label.textColor = [UIColor bjl_colorWithHex:0x44A4A];
    label.textAlignment = NSTextAlignmentLeft;
    label.font = [UIFont systemFontOfSize:16];
    [topContainerView addSubview:label];
    [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(imageView.bjl_right).offset(5);
        make.centerY.equalTo(imageView);
        make.right.lessThanOrEqualTo(topContainerView);
    }];
    UIView *line = [UIView new];
    line.backgroundColor = [UIColor bjlsc_grayLineColor];
    [topContainerView addSubview:line];
    [line bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(topContainerView);
        make.height.equalTo(@(BJLScOnePixel));
    }];
    [self.containerView addSubview:topContainerView];
    [topContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.top.right.equalTo(self.containerView);
        make.height.equalTo(@(40));
    }];
    
    self.segment = ({
        NSArray *items = @[];
        if (self.room.loginUser.isTeacherOrAssistant) {
            items = @[@"待回复", @"待发布", @"已发布"];
        }
        else if (self.room.loginUser.isStudent) {
            items = @[@"我的", @"已发布问答"];
        }
        BJLScSegment *segment = [[BJLScSegment alloc] initWithItems:items width:0.0 fontSize:16.0 textColor:[UIColor bjl_colorWithHexString:@"#9B9B9B" alpha:1.0]];
        segment.accessibilityLabel = BJLKeypath(self, segment);
        segment.layer.masksToBounds = NO;
        segment.layer.shadowOpacity = 0.3;
        segment.layer.shadowColor = [UIColor blackColor].CGColor;
        segment.layer.shadowOffset = CGSizeMake(0.0, 2.0);
        segment.layer.shadowRadius = 2.0;
        segment.hidden = !items.count;    
        segment;
    });
    
    [self.tableView removeFromSuperview];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.backgroundColor = [UIColor whiteColor];
    for (NSString *identifier in [BJLScQuestionCell allCellIdentifiers]) {
        [self.tableView registerClass:[BJLScQuestionCell class] forCellReuseIdentifier:identifier];
    }
    
    [self.containerView addSubview:self.tableView];
    [self.containerView addSubview:self.segment];
    [self.segment bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(topContainerView.bjl_bottom);
        make.left.right.equalTo(self.containerView);
        make.height.equalTo(@32.0);
    }];
    [self.tableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.containerView);
        make.top.equalTo(self.segment.bjl_bottom);
    }];
    
    self.questionButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, questionButton);
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.layer.borderColor = [UIColor bjl_colorWithHexString:@"#D0D0D0" alpha:1.0].CGColor;
        button.layer.borderWidth = 1.0;
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        button.titleLabel.textAlignment = NSTextAlignmentLeft;
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [button setTitle: @"问点啥吧" forState:UIControlStateNormal];
        [button setTitle: @"已被老师禁止提问" forState:UIControlStateDisabled];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#9B9B9B" alpha:1.0] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#999999" alpha:1.0] forState:UIControlStateDisabled];
        button.titleEdgeInsets = UIEdgeInsetsMake(3.0, 5.0, 3.0, 5.0);
        [button addTarget:self action:@selector(showQuestionInputView) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    
    [self.containerView addSubview:self.questionButton];
    [self.questionButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.tableView.bjl_bottom).offset(5.0);
        make.left.equalTo(self.containerView).offset(8.0);
        make.bottom.right.equalTo(self.containerView).offset(-8.0);
        make.height.equalTo(@34.0);
    }];
    
    self.unreadMessagesTipButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, unreadMessagesTipButton);
        button.hidden = YES;
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [button setTitle:@"有新问答" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:0.9];
        button.layer.cornerRadius = 2.0;
        button;
    });

    [self.view insertSubview:self.unreadMessagesTipButton aboveSubview:self.tableView];
    [self.unreadMessagesTipButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-5.0);
        make.bottom.equalTo(self.questionButton.bjl_top).offset(-8.0);
        make.size.equal.sizeOffset(CGSizeMake(72.0, 24.0));
    }];
    
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (iPhone) {
        self.refreshControl = [[BJLHeaderRefresh alloc] initWithTargrt:self action:@selector(loadQuestionHistory)];
        self.refreshControl.backgroundColor = [UIColor clearColor];
    }
    else {
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(loadQuestionHistory) forControlEvents:UIControlEventValueChanged];
    }
    
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.segment, selectedIndex)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateListWithSegmentIndex:self.segment.selectedIndex];
        // 切换seg的时候, 隐藏未读tip
        [self updateUnreadMessagesTipButtonHidden:YES];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self.tableView reloadData];
        return YES;
    }];
    [self.unreadMessagesTipButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        self.unreadMessagesTipButton.hidden = YES;
        [self scrollToTheEndTableView];
    }];
}

#pragma mark -

- (void)showQuestionInputView {
    if (self.showQuestionInputViewCallback) {
        self.showQuestionInputViewCallback();
    }
}

- (void)loadQuestionHistory {
    BJLScQuestionDateSource *source;
    if (self.room.loginUser.isTeacherOrAssistant) {
        if (0 == self.segment.selectedIndex) {
            source = self.unreplySource;
        }
        else if(1 == self.segment.selectedIndex) {
            source = self.unpublishSource;
        }
        else if (2 == self.segment.selectedIndex) {
            source = self.publishSource;
        }
    }
    else {
        if (0 == self.segment.selectedIndex) {
            source = self.myQuestionSouece;
        }
        else if(1 == self.segment.selectedIndex) {
            source = self.publishSource;
        }
    }
    
    if (source.currentQuestionPage <= 0) {
        [self.refreshControl endRefreshing];
        return;
    }
    
    source.currentQuestionPage = MAX(0, --source.currentQuestionPage);
    NSError *error = [source requestQuestionHistory];
    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
}

#pragma mark - popoverPresentation

- (void)showOptionViewWithQuestion:(BJLQuestion *)question questionReply:(nullable BJLQuestionReply *)reply point:(CGPoint)point {
    if (self.optionViewController) {
        return;
    }
    BJLScQuestionOptionView *optionView = [[BJLScQuestionOptionView alloc] initWithRoom:self.room question:question reply:reply];
    bjl_weakify(self);
    [optionView setReplyCallback:^(BJLQuestion * _Nonnull question, BJLQuestionReply * _Nullable reply) {
        bjl_strongify(self);
        [self hideOptionViewController];
        self.replyQuestion = question;
        if (self.replyCallback) {
            self.replyCallback(question, reply);
        }
    }];
    // 发布时把所有暂存的回复发布
    [optionView setPublishCallback:^(BJLQuestion * _Nonnull question, BOOL publish) {
        bjl_strongify(self);
        [self hideOptionViewController];
        BJLError *error = nil;
        if (publish) {
            error = [self.room.roomVM publishQuestionWithQuestionID:question.ID];
            if (question.replies.count > 0) {
                for (BJLQuestionReply *reply in [question.replies copy]) {
                    if (!reply.publish) {
                        [self.room.roomVM replyQuestionWithID:question.ID state:question.state reply:reply.content];
                    }
                }
            }
        }
        else {
            error = [self.room.roomVM unpublishQuestionWithQuestionID:question.ID];
        }
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
    }];
    [optionView setCopyCallback:^(BJLQuestion * _Nonnull question) {
        bjl_strongify(self);
        [self hideOptionViewController];
        NSString *content = [NSString stringWithFormat:@"%@ 提问：%@", question.fromUser.displayName, question.content];
        for (BJLQuestionReply *reply in question.replies) {
            content = [content stringByAppendingString:[NSString stringWithFormat:@"\n%@ 回复：%@", reply.fromUser.displayName, reply.content]];
        }
        [[UIPasteboard generalPasteboard] setString:content];
        [self showProgressHUDWithText:@"内容已复制"];
    }];
    self.optionViewController = ({
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view.backgroundColor = [UIColor clearColor];
        viewController.modalPresentationStyle = UIModalPresentationPopover;
        viewController.preferredContentSize = optionView.viewSize;
        viewController.popoverPresentationController.backgroundColor = [UIColor whiteColor];
        viewController.popoverPresentationController.delegate = self;
        viewController.popoverPresentationController.sourceView = self.view;
        viewController.popoverPresentationController.sourceRect = CGRectMake(point.x, point.y, 1.0, 1.0);
        viewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
        viewController;
    });
    [self.optionViewController.view addSubview:optionView];
    [optionView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.optionViewController.view.bjl_safeAreaLayoutGuide ?: self.optionViewController.view);
    }];
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:self.optionViewController animated:YES completion:nil];
}

- (void)hideOptionViewController {
    [self.optionViewController dismissViewControllerAnimated:YES completion:nil];
    self.optionViewController = nil;
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.currentQuestionList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BJLQuestion *question = [self.currentQuestionList bjl_objectAtIndex:section];
    return question.replies.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLQuestion *question = [self.currentQuestionList bjl_objectAtIndex:indexPath.section];
    BJLScQuestionCell *cell = nil;
    if (indexPath.row > 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:BJLScQuestionReplyCellReuseIdentifier forIndexPath:indexPath];
        [cell updateWithQuestion:question questionReply:bjl_as([question.replies bjl_objectAtIndex:indexPath.row - 1], BJLQuestionReply)];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:BJLScQuestionCellReuseIdentifier forIndexPath:indexPath];
        [cell updateWithQuestion:question questionReply:nil];
    }
    if (self.room.loginUser.isTeacherOrAssistant) {
        bjl_weakify(self, cell);
        [cell setSingleTapCallback:^(BJLQuestion * _Nonnull question, BJLQuestionReply * _Nullable questionReply, CGPoint point) {
            bjl_strongify(self, cell);
            CGPoint targetPoint = [self.view convertPoint:point fromView:cell];
            [self showOptionViewWithQuestion:question questionReply:questionReply point:targetPoint];
        }];
    }
    return cell;
}

#pragma mark - table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLQuestion *question = [self.currentQuestionList bjl_objectAtIndex:indexPath.section];
    BJLQuestionReply *questionReply;
    NSString *key;
    NSString *identifier;
    if (indexPath.row > 0) {
        questionReply = bjl_as([question.replies bjl_objectAtIndex:indexPath.row - 1], BJLQuestionReply);
        key = [NSString stringWithFormat:@"kQuestionKey %ld %f", (long)question.ID, questionReply.createTime];
        identifier = BJLScQuestionReplyCellReuseIdentifier;
    }
    else {
        key = [NSString stringWithFormat:@"kQuestionKey %ld %f", (long)question.ID, question.createTime];
        identifier = BJLScQuestionCellReuseIdentifier;
    }
    
    CGFloat height = [tableView bjl_cellHeightWithKey:key identifier:identifier configuration:^(BJLScQuestionCell *cell) {
        //bjl_strongify(self);
        cell.bjl_autoSizing = YES;
        [cell updateWithQuestion:question questionReply:questionReply];
    }];
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 32.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 8.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor whiteColor];
        view;
    });
    UIView *view = [UIView new];
    view.clipsToBounds = YES;
    [view bjlsc_drawRectCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight radius:8.0 backgroundColor:[UIColor bjl_colorWithHexString:@"#F5F5F5" alpha:1.0] size:CGSizeMake(tableView.frame.size.width - 16.0, 8.0)];
    [footerView addSubview:view];
    [view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(footerView);
        make.left.right.equalTo(footerView).inset(8.0);
        make.height.equalTo(@4.0);
    }];
    return footerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor whiteColor];
        view;
    });
    
    BJLQuestion *question = [self.currentQuestionList bjl_objectAtIndex:section];
    
    UILabel *nameLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentLeft;
        label;
    });
    [headerView addSubview:nameLabel];
    
    // 学生 && 自己发的 && 已发布状态
    if (!self.room.loginUser.isTeacherOrAssistant
        && [self.room.loginUser isSameUser:question.fromUser]
        && (question.state & BJLQuestionPublished)
        && self.segment.selectedIndex == 1) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_question_me"]];
        [headerView addSubview:imageView];
        [imageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(headerView).offset(8.0);
            make.centerY.equalTo(headerView);
            make.height.width.equalTo(@16.0);
        }];
        
        [nameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(imageView.bjl_right).offset(2.0);
            make.centerY.equalTo(headerView);
            make.height.equalTo(@17.0);
        }];
    }
    else {
        [nameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(headerView).offset(8.0);
            make.centerY.equalTo(headerView);
            make.height.equalTo(@17.0);
        }];
    }

    UILabel *timeLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor bjl_colorWithHexString:@"#9B9B9B" alpha:1.0];
        label.textAlignment = NSTextAlignmentRight;
        label.font = [UIFont systemFontOfSize:12.0];
        label;
    });
    [headerView addSubview:timeLabel];
    [timeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(headerView).offset(-11.0);
        make.top.bottom.equalTo(nameLabel);
    }];
    UIView *view = [UIView new];
    view.clipsToBounds = YES;
    [view bjlsc_drawRectCorners:UIRectCornerTopLeft | UIRectCornerTopRight radius:8.0 backgroundColor:[UIColor bjl_colorWithHexString:@"#F5F5F5" alpha:1.0] size:CGSizeMake(tableView.frame.size.width - 16.0, 8.0)];
    [headerView addSubview:view];
    [view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(headerView).inset(8.0);
        make.bottom.equalTo(headerView);
        make.height.equalTo(@4.0);
    }];
    
    nameLabel.text = question.fromUser.displayName;
    timeLabel.text = [self timeStringWithTimeInterval:question.createTime];
    return headerView;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - wheel

- (NSString *)timeStringWithTimeInterval:(NSTimeInterval)timeInterval {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.dragging && !scrollView.decelerating) {
        return;
    }
    if ([self atTheBottomOfTableView]) {
        [self updateUnreadMessagesTipButtonHidden:YES];
    }
}

#pragma mark - UIPopoverPresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    self.optionViewController = nil;
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
    self.optionViewController = nil;
}

@end
