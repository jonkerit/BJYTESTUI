//
//  BJLScStickyMessageView.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/4/2.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLScStickyMessageView.h"
#import "BJLScAppearance.h"
#import "BJLScStickyCell.h"

@interface BJLScStickyMessageView () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) NSArray <BJLMessage *> *messageList;

@property (nonatomic) UILabel *attributeLabel, *stickyCountLabel;
@property (nonatomic) UIButton *gatherButton;

@property (nonatomic) UIView *gapLine;
@property (nonatomic) UITableView *tableView;

@end

@implementation BJLScStickyMessageView

- (instancetype)initWithMessageList:(nullable NSArray <BJLMessage *> *)messageList room:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
        self.messageList = messageList;
        self.showCompleteMessage = NO;
        [self makeSubviewsAndConstraints];
        [self updateMessageContent];
        [self updateSubviews];
    }
    return self;
}

//更新view
- (void)updateStickyMessageList:(nullable NSArray <BJLMessage *> *)messageList {
    self.messageList = messageList;
    self.stickyCountLabel.text = [NSString stringWithFormat:@"%td", messageList.count];
    self.stickyCountLabel.hidden = self.showCompleteMessage || messageList.count < 2;

    [self updateMessageContent];
    [self updateSubviews];
}

#pragma mark -

- (void)makeSubviewsAndConstraints {
    self.accessibilityLabel = @"BJLScStickyMessageView";
    
    self.tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tableView.accessibilityLabel = BJLKeypath(self, tableView);
        tableView.delegate = self;
        tableView.dataSource = self;
        [tableView registerClass:[BJLScStickyCell class] forCellReuseIdentifier:BJLScStudentStickyCellIdentifier];
        [tableView registerClass:[BJLScStickyCell class] forCellReuseIdentifier:BJLScTeacherStickyCellIdentifier];
        tableView.allowsSelection = NO;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.estimatedRowHeight = 50.0;
        tableView;
    });
    
    self.attributeLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, attributeLabel);
        label.numberOfLines = 2;
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        label.backgroundColor = [UIColor clearColor];
        label;
    });
    
    self.stickyCountLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, stickyCountLabel);
        label.hidden = YES;
        label.numberOfLines = 1;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor whiteColor];
        label.layer.cornerRadius = 6.0;
        label.layer.masksToBounds = YES;
        label.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF1F49"];
        label;
    });

    self.gatherButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, gatherButton);
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_gatherSticky"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(gatherView) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    
    self.gapLine = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, gapLine);
        view.backgroundColor = [UIColor bjl_colorWithHex:0XD9D9D9];
        view;
    });
    
    [self addSubview:self.attributeLabel];
    [self addSubview:self.gapLine];
    [self addSubview:self.tableView];
    [self addSubview:self.stickyCountLabel];

    [self.attributeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.vertical.compressionResistance.hugging.required();
        make.top.equalTo(self).with.inset(BJLScViewSpaceS);
        make.left.equalTo(self).offset(10);
        make.right.equalTo(self).offset(-10);
        make.bottom.equalTo(self).offset(-BJLScViewSpaceS);
    }];
    
    [self.stickyCountLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.bjl_top).offset(6.0);
        make.width.height.equalTo(@12);
        make.left.equalTo(self).offset(20);
    }];

    [self.gapLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(self);
        make.height.equalTo(@(BJLScOnePixel));
    }];

    bjl_weakify(self);
    UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        CGPoint point = [gesture locationInView:self];
        [self handleTapGesture:point];
    }];
    [self addGestureRecognizer:tapGesture];
}

// 根据视图状态更新文本
- (void)updateMessageContent {
    if (!self.messageList.count) {
        return;
    }
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    UIImage *image = [UIImage bjlsc_imageNamed:@"bjl_sc_chat_sticky"];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = image;
    attachment.bounds = CGRectMake(0, -2, 16, 16);
    NSAttributedString *imageAttriString = [NSAttributedString attributedStringWithAttachment:attachment];
    [string appendAttributedString:imageAttriString];
    
    // 合起来的时候
    if (!self.showCompleteMessage) {
        if (self.messageList.firstObject.type != BJLMessageType_image) {
            self.attributeLabel.numberOfLines = 2;
            NSAttributedString *spaceText = [[NSAttributedString alloc] initWithString:@" "];
            NSAttributedString *messageText = [self.messageList.firstObject attributedEmoticonStringWithEmoticonSize:16.0 attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12.0], NSForegroundColorAttributeName:[UIColor bjl_colorWithHex:0X545454]} cached:YES cachedKey:@"cache"];
            [string appendAttributedString:spaceText];
            if (messageText) {
                [string appendAttributedString:messageText];
            }
        }
        else {
            self.attributeLabel.numberOfLines = 1;
            NSAttributedString *spaceText = [[NSAttributedString alloc] initWithString:@" "];
            NSAttributedString *nameText = [[NSAttributedString alloc] initWithString:@"置顶消息 [图片]" attributes:@{
                NSFontAttributeName: [UIFont systemFontOfSize:12],
                NSForegroundColorAttributeName: [UIColor bjl_colorWithHex:0X545454],
            }];
            [string appendAttributedString:spaceText];
            [string appendAttributedString:nameText];
        }
    }
    self.attributeLabel.attributedText = string;
}

// 根据视图状态更新视图
- (void)updateSubviews {
    [self.gatherButton removeFromSuperview];
    [self.tableView removeFromSuperview];
    [self.attributeLabel bjl_uninstallConstraints];
    [self.tableView bjl_uninstallConstraints];

    if (!self.messageList.count) {
        return;
    }
    
    if (self.showCompleteMessage) {
        
        [self addSubview:self.gatherButton];
        [self addSubview:self.tableView];
        
        [self.gatherButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.tableView.bjl_bottom);
            make.centerX.bottom.equalTo(self);
            make.height.equalTo(@(24));
            make.left.equalTo(self).offset(10);
            make.right.equalTo(self).offset(-10);
        }];
        [self.tableView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.left.right.equalTo(self);
            make.bottom.equalTo(self.gatherButton.bjl_top);
            // 撑满 当前的view
            make.height.equalTo(@([UIScreen mainScreen].bounds.size.height)).priorityHigh();
        }];
        [self.tableView reloadData];
    }
    else {
        [self.attributeLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self).with.inset(BJLScViewSpaceS);
            make.left.equalTo(self).offset(10);
            make.right.equalTo(self).offset(-10);
            make.bottom.equalTo(self).offset(-BJLScViewSpaceS);
        }];
    }
    if (self.updateConstraintsCallback) {
        self.updateConstraintsCallback(self.showCompleteMessage);
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - action

- (void)handleTapGesture:(CGPoint)point {
    if (self.showCompleteMessage) {
        return;
    }
    
    self.showCompleteMessage = YES;
    self.stickyCountLabel.hidden = YES;
    [self updateMessageContent];
    [self updateSubviews];
}

// 收起
- (void)gatherView {
    [self resetStickyMessageView];
}

// 重置view
- (void)resetStickyMessageView {
    self.showCompleteMessage = NO;
    // self.messageList 只有1条信息时候, 隐藏self.stickyCountLabel
    self.stickyCountLabel.hidden = self.messageList.count < 2;
    self.stickyCountLabel.text = [NSString stringWithFormat:@"%td", self.messageList.count];
    
    [self updateMessageContent];
    [self updateSubviews];
}

#pragma mark -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messageList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLScStickyCell *cell = [tableView dequeueReusableCellWithIdentifier:self.room.loginUser.isTeacherOrAssistant ? BJLScTeacherStickyCellIdentifier : BJLScStudentStickyCellIdentifier];
    BJLMessage *message = [self.messageList bjl_objectAtIndex:indexPath.row];
    [cell updateWithMessage:message customString:[self customStringWithRole:message.fromUser.role]];
    bjl_weakify(self, cell);
    [cell setLinkURLCallback:^BOOL(NSURL * _Nonnull url) {
        bjl_strongify(self);
        if (self.linkURLCallback) {
            return self.linkURLCallback(url);
        }
        return NO;
    }];
    
    [cell setCancelStickyCallback:^{
        bjl_strongify(self, cell);
        if (self.cancelStickyCallback) {
            self.cancelStickyCallback(cell.message);
        }
    }];
    
    [cell setImageTapCallback:^(BJLMessage * _Nullable message) {
        bjl_strongify(self, cell);
        if (message.type == BJLMessageType_image) {
            if (self.imageSelectCallback) {
                self.imageSelectCallback(cell.message);
            }
        }
    }];
    return cell;
}

#pragma mark - UITextViewDelegate

// 文本链接跳转
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if (self.linkURLCallback) {
        return self.linkURLCallback(URL);
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (nullable NSString *)customStringWithRole:(BJLUserRole)role {
    switch (role) {
        case BJLUserRole_teacher:
            return self.room.featureConfig.teacherLabel ?: @"老师";
            
        case BJLUserRole_assistant:
            return self.room.featureConfig.assistantLabel ?: @"助教";
            
        default:
            return nil;
    }
}

@end
