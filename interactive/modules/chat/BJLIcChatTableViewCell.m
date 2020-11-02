//
//  BJLIcChatTableViewCell.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/10/11.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLConstants.h>

#import "BJLIcChatTableViewCell.h"
#import "BJLIcAppearance.h"

NSString
* const BJLIcReceiveTextCellReuseIdentifier = @"kIcReceiveTextCellReuseIdentifier",
* const BJLIcReceiveTextAndTranslationCellReuseIdentifier = @"kIcReceiveTextAndTranslationCellReuseIdentifier",
* const BJLIcReceiveImageCellReuseIdentifier = @"kIcReceiveImageCellReuseIdentifier",
* const BJLIcReceiveEmoticonCellReuseIdentifier = @"kIcReceiveEmoticonCellReuseIdentifier",
* const BJLIcSendTextCellReuseIdentifier = @"kIcSendTextCellReuseIdentifier",
* const BJLIcSendTextAndTranslationCellReuseIdentifier = @"kIcSendTextAndTranslationCellReuseIdentifier",
* const BJLIcSendImageCellReuseIdentifier = @"kIcSendImageCellReuseIdentifier",
* const BJLIcSendEmoticonCellReuseIdentifier = @"kIcSendEmoticonCellReuseIdentifier";

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcChatTableViewCell () <UITextViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) BJLMessage *message;
@property (nonatomic) BOOL isSender;
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UILabel *timeLabel;
@property (nonatomic) UIView *messageBackgroundView;
@property (nonatomic) UITextView *messageTextView;
@property (nonatomic) UIView *detailMessageButtonShadowView;
@property (nonatomic) UIButton *detailMessageButton;
@property (nonatomic) UIImageView *messageImageView;
@property (nonatomic) UIImageView *emoticonImageView;

/** 翻译 */
@property (nonatomic) UIView *translationSepratorline;
@property (nonatomic) UITextView *translationTextView;

/** 消息引用 */
@property (nonatomic, nullable) UILabel *referenceLabel;
@property (nonatomic, nullable) UIImageView *referenceEmoticonImageView;
@property (nonatomic, nullable) UIView *referenceSepratorline;
@property (nonatomic) NSInteger limitLine, currentLineNumber;

@end

@implementation BJLIcChatTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.limitLine = 3;
        self.currentLineNumber = 3.0;
        [self makeSubviewsAndConstraints];
        [self makeObserving];
    }
    return self;
}

#pragma mark - update

/**
 当前用户聊天气泡底色为主题色;
 非老师角色的远端消息气泡底色为subButtonBackgroundColor;
 老师的聊天消息气泡底色为主题色
 */
- (void)updateMessageBackgroundColor {
    if (self.isSender) {
        self.messageBackgroundView.backgroundColor = BJLIcTheme.brandColor;
        self.messageTextView.textColor = BJLIcTheme.buttonTextColor;
        self.translationTextView.textColor = BJLIcTheme.buttonTextColor;
        self.translationSepratorline.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    }
    else {
        self.messageBackgroundView.backgroundColor = BJLIcTheme.subButtonBackgroundColor;
        self.messageTextView.textColor = BJLIcTheme.subButtonTextColor;
        self.translationTextView.textColor = BJLIcTheme.subButtonTextColor;
        self.translationSepratorline.backgroundColor = BJLIcTheme.separateLineColor;
    }
    
    if (self.message.reference) {
        self.messageBackgroundView.backgroundColor = BJLIcTheme.subButtonBackgroundColor;
        self.messageTextView.textColor = BJLIcTheme.subButtonTextColor;
        self.translationTextView.textColor = BJLIcTheme.subButtonTextColor;
        self.translationSepratorline.backgroundColor = BJLIcTheme.separateLineColor;
    }
}

- (void)updateWithMessage:(BJLMessage *)message cellWidth:(CGFloat)cellWidth {
    if (self.message == message) {
        return;
    }
    self.message = message;
    self.nameLabel.text = message.fromUser.displayName;
    self.timeLabel.text = [self timeStringWithTimeInterval:message.timeInterval];
    // 清空
    self.messageTextView.hidden = YES;
    self.detailMessageButtonShadowView.hidden = YES;
    self.detailMessageButton.hidden = YES;
    self.messageImageView.hidden = YES;
    self.emoticonImageView.hidden = YES;
    self.messageTextView.text = nil;
    self.messageTextView.attributedText = nil;
    self.messageImageView.image = nil;
    self.emoticonImageView.image = nil;
    self.referenceLabel.text = nil;
    self.referenceLabel.attributedText = nil;
    self.referenceEmoticonImageView.image = nil;
    
    [self updateMessageBackgroundColor];
    if (!message.reference) {
        [self.referenceSepratorline removeFromSuperview];
        [self.referenceLabel removeFromSuperview];
        [self.referenceEmoticonImageView removeFromSuperview];
        self.referenceSepratorline = nil;
        self.referenceLabel = nil;
        self.referenceEmoticonImageView = nil;
    }
    // 显示
    switch (message.type) {
        case BJLMessageType_text: {
            self.messageTextView.hidden = NO;
            [self updateMessageLabelWithMessage:message cellWidth:cellWidth translation:message.translation];
            break;
        }
            
        case BJLMessageType_image: {
            self.messageImageView.hidden = NO;
            [self updateMessageImageViewConstraintsWithCellWidth:cellWidth];
            break;
        }
            
        case BJLMessageType_emoticon:
            self.emoticonImageView.hidden = NO;
            [self updateEmoticonImageViewConstraints];
            break;
            
        default:
            break;
    }
}

- (void)updatReferenceLabelLineNumber:(NSInteger)number {
    self.currentLineNumber = number;
}

#pragma mark - subviews

- (void)makeSubviewsAndConstraints {
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    if ([self.reuseIdentifier isEqualToString:BJLIcSendTextCellReuseIdentifier]) {
        self.isSender = YES;
        [self makeMessageLabelAndConstraints];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcSendImageCellReuseIdentifier]) {
        self.isSender = YES;
        [self makeMessageImageViewAndConstraints];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcSendEmoticonCellReuseIdentifier]) {
        self.isSender = YES;
        [self makeEmoticonImageViewAndConstraints];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcSendTextAndTranslationCellReuseIdentifier]) {
        self.isSender = YES;
        [self makeTranslationMessageLabelAndConstraints];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcReceiveTextCellReuseIdentifier]) {
        self.isSender = NO;
        [self makeMessageLabelAndConstraints];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcReceiveImageCellReuseIdentifier]) {
        self.isSender = NO;
        [self makeMessageImageViewAndConstraints];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcReceiveEmoticonCellReuseIdentifier]) {
        self.isSender = NO;
        [self makeEmoticonImageViewAndConstraints];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcReceiveTextAndTranslationCellReuseIdentifier]) {
        self.isSender = NO;
        [self makeTranslationMessageLabelAndConstraints];
    }
    // gesture
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture)];
    singleTapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:singleTapGesture];
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    longPressGesture.delegate = self; // 所有长按手势可以通过实现手势 delegate 来保证同时触发所有支持长按手势的控件
    [self addGestureRecognizer:longPressGesture];
    [singleTapGesture requireGestureRecognizerToFail:longPressGesture];
}

- (void)makeCommonViewsAndConstraints {
    self.nameLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, nameLabel);
        label.userInteractionEnabled = NO;
        label.numberOfLines = 1;
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = BJLIcTheme.viewTextColor;
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self.contentView addSubview:self.nameLabel];
    [self.nameLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        if (self.isSender) {
            make.right.equalTo(self.contentView).offset(-BJLIcAppearance.chatViewLargeSpace);
        }
        else {
            make.left.equalTo(self.contentView).offset(BJLIcAppearance.chatViewLargeSpace);
        }
        make.top.equalTo(self.contentView).offset(BJLIcAppearance.chatViewSmallSpace);
    }];
    self.timeLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, timeLabel);
        label.userInteractionEnabled = NO;
        label.numberOfLines = 1;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = BJLIcTheme.viewSubTextColor;
        label.font = [UIFont systemFontOfSize:12.0];
        label;
    });
    [self.contentView addSubview:self.timeLabel];
    [self.timeLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.horizontal.hugging.compressionResistance.required();
        if (self.isSender) {
            make.right.equalTo(self.nameLabel.bjl_left).offset(-BJLIcAppearance.chatViewMediumSpace);
            make.left.greaterThanOrEqualTo(self.contentView).offset(BJLIcAppearance.chatViewLargeSpace);
        }
        else {
            make.left.equalTo(self.nameLabel.bjl_right).offset(BJLIcAppearance.chatViewMediumSpace);
            make.right.lessThanOrEqualTo(self.contentView).offset(-BJLIcAppearance.chatViewLargeSpace);
        }
        make.bottom.equalTo(self.nameLabel);
    }];
    // message label shadow and layout
    UIView *messageView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = @"messageView";
        view;
    });
    [self.contentView addSubview:messageView];
    [messageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        if (self.isSender) {
            make.right.equalTo(self.contentView).offset(-BJLIcAppearance.chatViewLargeSpace);
        }
        else {
            make.left.equalTo(self.contentView).offset(BJLIcAppearance.chatViewLargeSpace);
        }
        make.bottom.equalTo(self.contentView).offset(-BJLIcAppearance.chatViewSmallSpace);
        make.top.equalTo(self.nameLabel.bjl_bottom).offset(BJLIcAppearance.chatViewSmallSpace);
        make.width.lessThanOrEqualTo(self).multipliedBy(0.7);
        make.width.lessThanOrEqualTo(@(BJLIcAppearance.chatCellMaxWidth)).priorityHigh();
        make.width.greaterThanOrEqualTo(@(BJLIcAppearance.chatCellMinTextWidth));
        make.height.greaterThanOrEqualTo(@(BJLIcAppearance.chatCellMinTextHeight)).priorityHigh();
    }];
    // message label insets and background color
    self.messageBackgroundView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, messageBackgroundView);
        if (self.isSender) {
            view.backgroundColor = [BJLIcTheme brandColor];
        }
        else {
            view.backgroundColor = [BJLIcTheme subButtonBackgroundColor];
        }
        view;
    });
    [messageView addSubview:self.messageBackgroundView];
    [self.messageBackgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(messageView);
    }];
}

- (void)makeMessageLabelAndConstraints {
    [self makeCommonViewsAndConstraints];
    // message label
    self.messageTextView = ({
        UITextView *textView = [UITextView new];
        textView.accessibilityLabel = BJLKeypath(self, messageTextView);
        textView.font = [UIFont systemFontOfSize:14.0];
        textView.hidden = YES;
        textView.selectable = YES;
        textView.userInteractionEnabled = YES;
        textView.editable = NO;
        textView.scrollEnabled = NO;
        textView.delegate = self;
        textView.textContainerInset = UIEdgeInsetsZero;
        textView.textContainer.lineFragmentPadding = 0;
        textView.backgroundColor = [UIColor clearColor];
        textView.textAlignment = NSTextAlignmentLeft;
        if (self.isSender) {
            textView.textColor = BJLIcTheme.buttonTextColor;
        }
        else {
            textView.textColor = BJLIcTheme.subButtonTextColor;
        }
        textView.dataDetectorTypes = UIDataDetectorTypeLink;
        textView.linkTextAttributes = @{NSForegroundColorAttributeName: textView.textColor};
        textView.font = [UIFont systemFontOfSize:14.0];
        textView;
    });
    [self.messageBackgroundView addSubview:self.messageTextView];
    [self.messageTextView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.bottom.equalTo(self.messageBackgroundView).offset(-BJLIcAppearance.chatViewMediumSpace);
        make.left.top.equalTo(self.messageBackgroundView).offset(BJLIcAppearance.chatViewMediumSpace);
    }];
    // detail message button
    self.detailMessageButtonShadowView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, detailMessageButtonShadowView);
        view.backgroundColor = [UIColor whiteColor];
        view.userInteractionEnabled = NO;
        view.hidden = YES;
        view.layer.masksToBounds = NO;
        view.layer.shadowOpacity = 1;
        view.layer.shadowColor = BJLIcTheme.windowShadowColor.CGColor;
        view.layer.shadowOffset = CGSizeMake(0.0, -5.0);
        view.layer.shadowRadius = 10.0;
        view;
    });
    [self.messageBackgroundView addSubview:self.detailMessageButtonShadowView];
    [self.detailMessageButtonShadowView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.messageBackgroundView);
        make.height.equalTo(@24.0);
    }];
    self.detailMessageButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.accessibilityLabel = BJLKeypath(self, detailMessageButton);
        button.backgroundColor = [UIColor bjl_colorWithHex:0XF4F4F4];
        button.hidden = YES;
        button.layer.masksToBounds = YES;
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        [button setTitle:@"查看全部" forState:UIControlStateNormal];
        [button setTitleColor:[BJLIcTheme brandColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showDetail) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.messageBackgroundView addSubview:self.detailMessageButton];
    [self.detailMessageButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.detailMessageButtonShadowView);
    }];
}

- (void)makeTranslationMessageLabelAndConstraints {
    [self makeCommonViewsAndConstraints];
    // message label
    self.messageTextView = ({
        UITextView *textView = [UITextView new];
        textView.accessibilityLabel = BJLKeypath(self, messageTextView);
        textView.font = [UIFont systemFontOfSize:14.0];
        textView.hidden = YES;
        textView.userInteractionEnabled = YES;
        textView.selectable = YES;
        textView.editable = NO;
        textView.scrollEnabled = NO;
        textView.delegate = self; // 所有长按手势可以通过实现手势 delegate 来保证同时触发所有支持长按手势的控件
        textView.textContainerInset = UIEdgeInsetsZero;
        textView.textContainer.lineFragmentPadding = 0;
        textView.backgroundColor = [UIColor clearColor];
        textView.textAlignment = NSTextAlignmentLeft;
        if (self.isSender) {
            textView.textColor = BJLIcTheme.buttonTextColor;
        }
        else {
            textView.textColor = BJLIcTheme.subButtonTextColor;
        }
        textView.dataDetectorTypes = UIDataDetectorTypeLink;
        textView.linkTextAttributes = @{NSForegroundColorAttributeName: textView.textColor};
        textView.font = [UIFont systemFontOfSize:14.0];
        textView;
    });
    [self.messageBackgroundView addSubview:self.messageTextView];
    [self.messageTextView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.messageBackgroundView).offset(-BJLIcAppearance.chatViewMediumSpace);
        make.left.top.equalTo(self.messageBackgroundView).offset(BJLIcAppearance.chatViewMediumSpace);
    }];
    
    self.translationSepratorline = ({
        UIView *view = [UIView new];
        view.backgroundColor = BJLIcTheme.separateLineColor;
        view.accessibilityLabel = BJLKeypath(self, translationSepratorline);
        [self.messageBackgroundView addSubview:view];
        view;
    });
    [self.translationSepratorline bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.messageTextView);
        make.height.equalTo(@(1.0));
        make.top.equalTo(self.messageTextView.bjl_bottom).with.offset(BJLIcAppearance.chatViewMediumSpace);
    }];
    
    self.translationTextView = ({
        UITextView *textView = [UITextView new];
        textView.accessibilityLabel = BJLKeypath(self, translationTextView);
        textView.textAlignment = NSTextAlignmentLeft;
        textView.textContainerInset = UIEdgeInsetsZero;
        textView.textContainer.lineFragmentPadding = 0;
        textView.font = [UIFont systemFontOfSize:14];
        textView.backgroundColor = [UIColor clearColor];
        if (self.isSender) {
            textView.textColor = BJLIcTheme.buttonTextColor;
        }
        else {
            textView.textColor = BJLIcTheme.subButtonTextColor;
        }
        textView.dataDetectorTypes = UIDataDetectorTypeLink;
        textView.linkTextAttributes = @{NSForegroundColorAttributeName: textView.textColor};
        textView.selectable = YES;
        textView.editable = NO;
        textView.scrollEnabled = NO;
        textView.userInteractionEnabled = YES;
        textView.delegate = self;
        [self.messageBackgroundView addSubview:textView];
        textView;
    });
    [self.translationTextView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.messageTextView);
        make.top.equalTo(self.translationSepratorline.bjl_bottom).with.offset(BJLIcAppearance.chatViewMediumSpace);
        make.bottom.equalTo(self.messageBackgroundView).with.offset(- BJLIcAppearance.chatViewMediumSpace);
    }];
    
    // detail message button
    self.detailMessageButtonShadowView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, detailMessageButtonShadowView);
        view.backgroundColor = [UIColor whiteColor];
        view.hidden = YES;
        view.layer.masksToBounds = NO;
        view.layer.shadowOpacity = 1;
        view.layer.shadowColor = BJLIcTheme.windowShadowColor.CGColor;
        view.layer.shadowOffset = CGSizeMake(0.0, -5.0);
        view.layer.shadowRadius = 10.0;
        view;
    });
    [self.messageBackgroundView addSubview:self.detailMessageButtonShadowView];
    [self.detailMessageButtonShadowView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.messageBackgroundView);
        make.height.equalTo(@24.0);
    }];
    self.detailMessageButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.accessibilityLabel = BJLKeypath(self, detailMessageButton);
        button.backgroundColor = [UIColor bjl_colorWithHex:0XF4F4F4];
        button.hidden = YES;
        button.layer.masksToBounds = YES;
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        [button setTitle:@"查看全部" forState:UIControlStateNormal];
        [button setTitleColor:[BJLIcTheme brandColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showDetail) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.messageBackgroundView addSubview:self.detailMessageButton];
    [self.detailMessageButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.detailMessageButtonShadowView);
    }];
}

- (void)makeMessageImageViewAndConstraints {
    [self makeCommonViewsAndConstraints];
    // image
    self.messageImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.accessibilityLabel = BJLKeypath(self, messageImageView);
        imageView.hidden = YES;
        imageView.userInteractionEnabled = YES;
        imageView.layer.masksToBounds = YES;
        imageView.layer.cornerRadius = 12.0;
        imageView.layer.borderWidth = 1.0;
        imageView.layer.borderColor = [UIColor whiteColor].CGColor;
        imageView;
    });
    [self.messageBackgroundView addSubview:self.messageImageView];
}

- (void)makeEmoticonImageViewAndConstraints {
    [self makeCommonViewsAndConstraints];
    // emoticon
    self.emoticonImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.accessibilityLabel = BJLKeypath(self, emoticonImageView);
        imageView.hidden = YES;
        imageView.userInteractionEnabled = YES;
        imageView.layer.masksToBounds = YES;
        imageView.layer.cornerRadius = 12.0;
        imageView.layer.borderColor = [UIColor whiteColor].CGColor;
        imageView;
    });
    [self.messageBackgroundView addSubview:self.emoticonImageView];
}

- (void)updateMessageLabelWithMessage:(BJLMessage *)message cellWidth:(CGFloat)cellWidth translation:(NSString *)translation {
    // 计算文本展示高度来决定显示效果，一般使用自适应约束
    UIColor *color = (!message.reference && self.isSender) ? BJLIcTheme.buttonTextColor: BJLIcTheme.subButtonTextColor;
    NSAttributedString *text = [message attributedEmoticonStringWithEmoticonSize:18.0
                                                                      attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14.0], NSForegroundColorAttributeName: color}
                                                                          cached:YES
                                                                       cachedKey:(self.isSender ? @"send" : @"receive")];
    
    if (cellWidth <= 0 || cellWidth > BJLIcAppearance.chatCellMaxWidth) {
        cellWidth = BJLIcAppearance.chatCellMaxWidth;
    }
    CGFloat maxLabelWidth = (BJLIcAppearance.chatCellMaxWidth < cellWidth * 0.7 ? BJLIcAppearance.chatCellMaxWidth : cellWidth * 0.7) - 2 * BJLIcAppearance.chatViewSmallSpace;
    CGFloat maxLabelHeight = BJLIcAppearance.chatCellMaxTextHeight - 2 * BJLIcAppearance.chatViewLargeSpace;
    CGFloat minLabelHeight = BJLIcAppearance.chatCellMinTextHeight - 2 * BJLIcAppearance.chatViewLargeSpace;
    CGSize suitableSize = [self bjlic_suitableSizeWithText:nil attributedText:text maxWidth:maxLabelWidth];

    BOOL needDetailButton = (suitableSize.height > maxLabelHeight - 20);
    // 高度变化不是连续的，因此减去一个偏差值，超过最大高度时设置为最大高度
    if (needDetailButton) {
        suitableSize.height = maxLabelHeight;
        self.detailMessageButtonShadowView.hidden = NO;
        self.detailMessageButton.hidden = NO;
    }
    else {
        self.detailMessageButtonShadowView.hidden = YES;
        self.detailMessageButton.hidden = YES;
    }
    BOOL singleRow = suitableSize.height <= minLabelHeight;
    // 单行文本居中，多行文本宽度为最大宽度
    if (singleRow) {
        self.messageTextView.textAlignment = NSTextAlignmentCenter;
    }
    else {
        suitableSize.width = maxLabelWidth;
        self.messageTextView.textAlignment = NSTextAlignmentLeft;
    }
    self.messageTextView.attributedText = text;

    self.translationTextView.text = translation;
    self.translationSepratorline.hidden = !translation.length;
    self.translationTextView.hidden = !translation.length;
    
    if (message.reference) {
        [self makeReferenceViewWithReferenceMessage:message.reference];
        [self.messageTextView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            if (!translation) {
                make.bottom.equalTo(self.messageBackgroundView).offset(-BJLIcAppearance.chatViewMediumSpace);
            }
            make.top.equalTo(self.referenceSepratorline).offset(BJLIcAppearance.chatViewMediumSpace);
            make.right.equalTo(self.messageBackgroundView).offset(-BJLIcAppearance.chatViewMediumSpace);
            make.left.equalTo(self.messageBackgroundView).offset(BJLIcAppearance.chatViewMediumSpace);
        }];
    }
    else {
        // 当限制为最大高度的时候，强制设置为最大高度和宽度，否则使用自动计算的高度
        if (needDetailButton) {
            [self.messageTextView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.right.bottom.equalTo(self.messageBackgroundView).offset(-BJLIcAppearance.chatViewMediumSpace);
                make.left.top.equalTo(self.messageBackgroundView).offset(BJLIcAppearance.chatViewMediumSpace);
                make.width.equalTo(@(maxLabelHeight)).priorityHigh();
                make.height.equalTo(@(maxLabelWidth)).priorityHigh();
            }];
        }
        else {
            [self.messageTextView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                if (!translation) {
                    make.bottom.equalTo(self.messageBackgroundView).offset(-BJLIcAppearance.chatViewMediumSpace);
                }
                make.right.equalTo(self.messageBackgroundView).offset(-BJLIcAppearance.chatViewMediumSpace);
                make.left.top.equalTo(self.messageBackgroundView).offset(BJLIcAppearance.chatViewMediumSpace);
            }];
        }
    }
}

- (void)updateMessageImageViewConstraintsWithCellWidth:(CGFloat)cellWidth {
    // 更新图片约束
    if (self.message.type != BJLMessageType_image) {
        return;
    }
    CGSize suitableSize = CGSizeZero;
    if (cellWidth <= 0 || cellWidth > BJLIcAppearance.chatCellMaxWidth) {
        cellWidth = BJLIcAppearance.chatCellMaxWidth;
    }
    CGFloat maxImageWidth = (BJLIcAppearance.chatCellMaxWidth < cellWidth * 0.7 ? BJLIcAppearance.chatCellMaxWidth : cellWidth * 0.7) - 2 * BJLIcAppearance.chatViewSmallSpace;
    CGFloat maxImageHeight = BJLIcAppearance.chatCellMaxImageHeight - 2 * BJLIcAppearance.chatViewSmallSpace;
    suitableSize = [self suitableSizeWithImageSize:CGSizeMake(self.message.imageWidth, self.message.imageHeight) maxSize:CGSizeMake(maxImageWidth, maxImageHeight)];
    if (suitableSize.width > 0 && suitableSize.height > 0) {
        NSString *urlString = BJLAliIMG_aspectFit(CGSizeMake(suitableSize.width, suitableSize.height),
                                                  0.0,
                                                  self.message.imageURLString,
                                                  nil);
        [self.messageImageView bjl_setImageWithURL:[NSURL URLWithString:urlString]];
        // 添加约束
        [self.messageImageView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.messageBackgroundView).insets(UIEdgeInsetsMake(BJLIcAppearance.chatViewSmallSpace, BJLIcAppearance.chatViewSmallSpace, BJLIcAppearance.chatViewSmallSpace, BJLIcAppearance.chatViewSmallSpace)).priorityHigh();
            make.height.equalTo(@(suitableSize.height));
            make.width.equalTo(@(suitableSize.width));
        }];
    }
    else {
        bjl_weakify(self);
        [self.messageImageView bjl_setImageWithURL:[NSURL URLWithString:self.message.imageURLString] placeholder:nil completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
            bjl_strongify(self);
            if (image) {
                CGSize suitableSize = [self suitableSizeWithImageSize:CGSizeMake(image.size.width, image.size.height) maxSize:CGSizeMake(maxImageWidth, maxImageHeight)];
                // 添加约束
                [self.messageImageView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                    make.edges.equalTo(self.messageBackgroundView).insets(UIEdgeInsetsMake(BJLIcAppearance.chatViewSmallSpace, BJLIcAppearance.chatViewSmallSpace, BJLIcAppearance.chatViewSmallSpace, BJLIcAppearance.chatViewSmallSpace)).priorityHigh();
                    make.height.equalTo(@(suitableSize.height));
                    make.width.equalTo(@(suitableSize.width));
                }];
                if (self.updateConstraintsCallback && !error) self.updateConstraintsCallback(self);
            }
        }];
    }
}

- (void)updateEmoticonImageViewConstraints {
    // 更新表情约束，仅用于纯表情cell
    if (self.message.type != BJLMessageType_emoticon) {
        return;
    }
    if (self.message.emoticon.cachedImage) {
        self.emoticonImageView.image = self.message.emoticon.cachedImage;
    }
    else {
        NSString *urlString = BJLAliIMG_aspectFit(CGSizeMake(32.0, 32.0),
                                                  0.0,
                                                  self.message.emoticon.urlString,
                                                  nil);
        bjl_weakify(self);
        [self.emoticonImageView bjl_setImageWithURL:[NSURL URLWithString:urlString]
                                        placeholder:nil
                                         completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
                                             bjl_strongify(self);
                                             if (image) {
                                                 self.message.emoticon.cachedImage = image;
                                             }
                                         }];
    }
    if (self.message.reference) {
        [self makeReferenceViewWithReferenceMessage:self.message.reference];
        [self.emoticonImageView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.top.equalTo(self.referenceSepratorline).offset(BJLIcAppearance.chatViewSmallSpace).priorityHigh();
            make.left.equalTo(self.messageBackgroundView).offset(BJLIcAppearance.chatViewSmallSpace).priorityHigh();
            make.bottom.equalTo(self.messageBackgroundView).offset(-BJLIcAppearance.chatViewSmallSpace).priorityHigh();
//            make.right.equalTo(self.messageBackgroundView).offset(BJLIcAppearance.chatViewSmallSpace).priorityHigh();
            make.height.equalTo(@32.0);
            make.width.equalTo(@32.0);
        }];
    }
    else {
        [self.emoticonImageView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.messageBackgroundView).insets(UIEdgeInsetsMake(BJLIcAppearance.chatViewSmallSpace, BJLIcAppearance.chatViewSmallSpace, BJLIcAppearance.chatViewSmallSpace, BJLIcAppearance.chatViewSmallSpace)).priorityHigh();
            make.height.equalTo(@32.0);
            make.width.equalTo(@32.0);
        }];
    }
}

- (void)makeReferenceViewWithReferenceMessage:(BJLMessage *)referenceMessage {
    self.referenceSepratorline = self.referenceSepratorline ?: ({
        UIView *line = [UIView new];
        line.backgroundColor = BJLIcTheme.separateLineColor;
        line.accessibilityLabel = BJLKeypath(self, referenceSepratorline);
        [self.messageBackgroundView addSubview:line];
        line;
    });
    
    [self.referenceSepratorline bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.messageBackgroundView).offset(BJLIcAppearance.chatViewMediumSpace);
        make.right.equalTo(self.messageBackgroundView).offset(-BJLIcAppearance.chatViewMediumSpace);
        make.height.equalTo(@1);
    }];
    if (BJLMessageType_text == referenceMessage.type) {
        self.referenceLabel = self.referenceLabel ?: ({
            UILabel *label = [UILabel new];
            label.textAlignment = NSTextAlignmentLeft;
            label.font = [UIFont systemFontOfSize:14];
            label.textColor = [UIColor bjl_colorWithHexString:@"#666666" alpha:0.5];
            label.backgroundColor = [UIColor clearColor];
            label.userInteractionEnabled = YES;
            label.accessibilityLabel = BJLKeypath(self, referenceLabel);
            [self.messageBackgroundView addSubview:label];
            label;
        });
        // 至少显示3行
        self.referenceLabel.numberOfLines = self.currentLineNumber < self.limitLine ? self.limitLine : self.currentLineNumber;
        if (referenceMessage.text.length) {
            self.referenceLabel.attributedText = [referenceMessage attributedEmoticonStringWithEmoticonSize:18.0
                                                                                                 attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14.0], NSForegroundColorAttributeName: [UIColor bjl_colorWithHexString:@"#666666" alpha:0.5]}
                                                                                                     cached:YES
                                                                                                  cachedKey:(self.isSender ? @"send" : @"receive")];
            
            bjl_weakify(self);
            UITapGestureRecognizer *tap = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
                bjl_strongify(self);
                CGFloat totalHeight = [self bjlic_suitableSizeWithText:nil attributedText:self.referenceLabel.attributedText maxWidth:self.referenceLabel.bounds.size.width].height;
                NSInteger line = totalHeight / self.referenceLabel.font.lineHeight;
                if (line > self.limitLine
                    && self.reloadCellCallback) {
                    self.reloadCellCallback(self, self.currentLineNumber < line ? line: self.limitLine);
                }
            }];
            [self.referenceLabel addGestureRecognizer:tap];
        }
        [self.referenceLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.top.equalTo(self.messageBackgroundView).offset(BJLIcAppearance.chatViewMediumSpace);
            make.right.equalTo(self.messageBackgroundView).offset(-BJLIcAppearance.chatViewMediumSpace);
            make.bottom.equalTo(self.referenceSepratorline).offset(-BJLIcAppearance.chatViewMediumSpace);
        }];
    }
    else if (BJLMessageType_emoticon == referenceMessage.type) {
        self.referenceEmoticonImageView = self.referenceEmoticonImageView ?: ({
            UIImageView *imageView = [UIImageView new];
            imageView.clipsToBounds = YES;
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [self.messageBackgroundView addSubview:imageView];
            imageView.accessibilityLabel = BJLKeypath(self, referenceEmoticonImageView);
            imageView;
        });
        
        [self.referenceEmoticonImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.messageBackgroundView).offset(BJLIcAppearance.chatViewSmallSpace).priorityHigh();
            make.left.equalTo(self.messageBackgroundView).offset(BJLIcAppearance.chatViewSmallSpace).priorityHigh();
            make.bottom.equalTo(self.referenceSepratorline).offset(-BJLIcAppearance.chatViewSmallSpace).priorityHigh();
//            make.right.equalTo(self.messageBackgroundView).offset(BJLIcAppearance.chatViewSmallSpace).priorityHigh();
            make.height.equalTo(@32.0);
            make.width.equalTo(@32.0);
        }];
        
        if (referenceMessage.emoticon.cachedImage) {
            self.referenceEmoticonImageView.image = referenceMessage.emoticon.cachedImage;
        }
        else {
            NSString *urlString = BJLAliIMG_aspectFit(CGSizeMake(32.0, 32.0),
                                                      0.0,
                                                      referenceMessage.emoticon.urlString,
                                                      nil);
            [self.referenceEmoticonImageView bjl_setImageWithURL:[NSURL URLWithString:urlString]
                                            placeholder:nil
                                             completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
                                                 if (image) {
                                                     referenceMessage.emoticon.cachedImage = image;
                                                 }
                                             }];
        }

    }
}

#pragma mark - actions

- (void)showDetail {
    if (self.message.type == BJLMessageType_emoticon) {
        return;
    }
    if (self.showChatDetailCallback) {
        self.showChatDetailCallback(self.message);
    }
}

#pragma mark - gesture

- (void)handleTapGesture {
    if (self.singleTapCallback) {
        self.singleTapCallback(self.message);
    }
    else {
        if (self.message.type == BJLMessageType_image) {
            [self showDetail];
        }
    }
}

- (void)handleLongPressGesture:(UIGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan && self.longPressCallback) {
         self.longPressCallback(self.message, (self.message.type == BJLMessageType_emoticon) ? self.emoticonImageView.image : self.messageImageView.image, [gesture locationInView:self]);
    }
}

#pragma mark - kvo

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_kvoMerge:@[BJLMakeProperty(self.messageBackgroundView, bounds),
                         BJLMakeProperty(self.messageBackgroundView, hidden)]
              observer:^(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.messageBackgroundView.hidden || self.messageBackgroundView.bounds.size.height <= 0) {
            return;
        }
        // 绘制三个方向的圆角
        if (self.isSender) {
            [self.messageBackgroundView bjlic_drawRectCorners:UIRectCornerTopLeft | UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(16.0, 16.0)];
        }
        else {
            [self.messageBackgroundView bjlic_drawRectCorners:UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(16.0, 16.0)];
        }
    }];
}

#pragma mark - text view delegate

- (void)textViewDidChangeSelection:(UITextView *)textView {
    textView.selectedTextRange = nil;
}

// 文本链接跳转
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if (self.linkURLCallback) {
        return self.linkURLCallback(self, URL);
    }
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction  API_AVAILABLE(ios(10.0)){
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange {
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - wheel

// 根据最大size以及图片的原始大小来获取正确尺寸
- (CGSize)suitableSizeWithImageSize:(CGSize)imageSize maxSize:(CGSize)maxSize {
    if (CGSizeEqualToSize(imageSize, CGSizeZero) || CGSizeEqualToSize(maxSize, CGSizeZero)) {
        return CGSizeZero;
    }
    CGSize suitableSize = CGSizeZero;
    CGFloat imageWidth = imageSize.width;
    CGFloat imageHeight = imageSize.height;
    CGFloat maxImageWidth = maxSize.width;
    CGFloat maxImageHeight = maxSize.height;
    // 长图
    if (imageHeight / imageWidth > maxImageHeight / maxImageWidth) {
        suitableSize.height = MIN(imageHeight, maxImageHeight);
        suitableSize.width = suitableSize.height * (imageWidth / imageHeight);
    }
    // 宽图
    else {
        suitableSize.width = MIN(imageWidth, maxImageWidth);
        suitableSize.height = suitableSize.width * (imageHeight / imageWidth);
    }
    return suitableSize;
}

// 格式化时间
- (NSString *)timeStringWithTimeInterval:(NSTimeInterval)timeInterval {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

+ (NSArray<NSString *> *)allCellIdentifiers {
    return @[BJLIcReceiveTextCellReuseIdentifier,                       // 收到的聊天文本cell
             BJLIcReceiveTextAndTranslationCellReuseIdentifier,         // 收到的聊天和翻译文本cell
             BJLIcReceiveImageCellReuseIdentifier,                      // 收到的聊天图片cell
             BJLIcReceiveEmoticonCellReuseIdentifier,                   // 收到的聊天表情cell
             BJLIcSendTextCellReuseIdentifier,                          // 发送聊天文本cell
             BJLIcSendTextAndTranslationCellReuseIdentifier,            // 发送聊天文本和翻译cell
             BJLIcSendImageCellReuseIdentifier,                         // 发送聊天图片cell
             BJLIcSendEmoticonCellReuseIdentifier];                     // 发送聊天表情cell
}

@end

NS_ASSUME_NONNULL_END
