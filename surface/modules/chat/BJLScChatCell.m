//
//  BJLScChatCell.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScChatCell.h"
#import "BJLScAppearance.h"
#import "BJLScLabel.h"

NSString
* const BJLScTextCellReuseIdentifier = @"kScReceiveTextCellReuseIdentifier",
* const BJLScTextAndTranslationCellReuseIdentifier = @"kScReceiveTextAndTranslationCellReuseIdentifier",
* const BJLScImageCellReuseIdentifier = @"kScReceiveImageCellReuseIdentifier",
* const BJLScEmoticonCellReuseIdentifier = @"kScReceiveEmoticonCellReuseIdentifier",
* const BJLScMessageUploadingImageIdentifier = @"kScUploadingImageIdentifier";

static const CGFloat verMargins = (10.0 + 5.0 + 10.0) + 5.0; // last 5.0: bgView.top+bottom

static const CGFloat fontSize = 12.0;
static const CGFloat oneLineMessageCellHeight = fontSize + verMargins;

static const CGFloat avtarIconSize = 24.0;
static const CGFloat deviceIconSize = 13.0;

static const CGFloat imageMinWidth = 50.0, imageMinHeight = 50.0;
static const CGFloat imageMaxWidth = 100.0, imageMaxHeight = 100.0;
static const CGFloat imageMessageCellMinHeight = imageMinHeight + verMargins;

static const CGFloat emoticonSize = 32.0;
static const CGFloat emoticonMessageCellHeight = emoticonSize + verMargins;

@interface BJLScChatCell ()<UITextViewDelegate>

@property (nonatomic) BJLMessage *message;

@property (nonatomic) UIView *bgView, *messageContentView;;
@property (nonatomic) UILabel *timeLabel;
@property (nonatomic) BJLScLabel *nameLabel;
@property (nonatomic, readwrite) UIImageView *iconImageView, *deviceImageView;
@property (nonatomic) UIImageView *emoticonImageView, *messageImageView;
@property (nonatomic) UITextView *textView;

@property (nonatomic) UIView *imgProgressView;
@property (nonatomic) BJLConstraint *imgProgressViewHeightConstraint;
@property (nonatomic) UIButton *failedBadgeButton;

/** 英汉互译*/
@property (nonatomic) UIView *translationSepratorline;
@property (nonatomic) UITextView *translationTextView;

@property (nonatomic) BJLChatStatus chatStatus;

/** 消息引用*/
@property (nonatomic, nullable) UIImageView *referenceEmoticonImageView, *referenceMessageImageView;
@property (nonatomic, nullable) UILabel *referenceLabel;
@property (nonatomic, nullable) UIView *lineView;
@property (nonatomic) NSInteger limitLine, currentLineNumber;

@end

@implementation BJLScChatCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.limitLine = 3;
        self.currentLineNumber = 3;
        [self setUpSubviews];
        [self prepareForReuse];
    }
    return self;
}

- (void)setUpSubviews {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if ([self.reuseIdentifier isEqualToString:BJLScTextCellReuseIdentifier]) {
        [self makeMessageLabelAndConstraints];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLScImageCellReuseIdentifier]) {
        [self makeMessageImageViewAndConstraints];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLScEmoticonCellReuseIdentifier]) {
        [self makeEmoticonImageViewAndConstraints];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLScTextAndTranslationCellReuseIdentifier]) {
        [self makeTranslationMessageLabelAndConstraints];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLScMessageUploadingImageIdentifier]) {
        [self makeUploadingImageMessageLabelAndConstraints];
    }

    bjl_weakify(self);
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    singleTapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:singleTapGesture];

    UILongPressGestureRecognizer *longPressGesture = [UILongPressGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        if (self.longPressCallback && gesture.state == UIGestureRecognizerStateBegan) {
            self.longPressCallback(self.message, (self.message.type == BJLMessageType_emoticon) ? self.emoticonImageView.image : self.messageImageView.image, [gesture locationInView:self]);
        }
    }];
    longPressGesture.delegate = self;
    [self addGestureRecognizer:longPressGesture];
    [singleTapGesture requireGestureRecognizerToFail:longPressGesture];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.textView.text = nil;
    self.textView.attributedText = nil;
    [self.nameLabel updateText:nil styleText:nil];
    self.timeLabel.text = nil;
    self.iconImageView.image = nil;
    self.deviceImageView.image = nil;
    self.emoticonImageView.image = nil;
    self.translationTextView.text = nil;
    self.messageImageView.image = nil;
    self.failedBadgeButton.hidden = YES;
    
    [self.referenceLabel removeFromSuperview];
    [self.referenceMessageImageView removeFromSuperview];
    [self.referenceEmoticonImageView removeFromSuperview];
    [self.lineView removeFromSuperview];
    self.referenceLabel = nil;
    self.referenceMessageImageView = nil;
    self.referenceEmoticonImageView = nil;
    self.lineView = nil;
}

- (void)makeCommonViewsAndConstraints {
    self.bgView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, bgView);
        [self.contentView addSubview:view];
        view;
    });

    self.timeLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, timeLabel);
        label.numberOfLines = 1;
        label.textAlignment = NSTextAlignmentRight;
        label.lineBreakMode = NSLineBreakByCharWrapping;
        label.textColor = [UIColor bjl_colorWithHex:0X9B9B9B];
        label.font = [UIFont systemFontOfSize:12];
        [self.bgView addSubview:label];
        bjl_return label;
    });
    
    self.nameLabel = ({
        BJLScLabel *label = [[BJLScLabel alloc] initWitMinHeadCount:2 headStyle:@" [" tailStyle:@"]" fontSize:12.0];
        label.accessibilityLabel = BJLKeypath(self, nameLabel);
        label.textColor = [UIColor bjl_colorWithHex:0X4A4A4A];
        [self.bgView addSubview:label];
        label;
    });
    
    self.iconImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.accessibilityLabel = BJLKeypath(self, iconImageView);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.cornerRadius = avtarIconSize/2;
        imageView.layer.masksToBounds = YES;
        imageView.backgroundColor = [UIColor bjlsc_grayLineColor];
        [self.bgView addSubview:imageView];
        bjl_return imageView;
    });
    
    self.deviceImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.accessibilityLabel = BJLKeypath(self, deviceImageView);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.backgroundColor = [UIColor clearColor];
        imageView.layer.masksToBounds = YES;
        [self.bgView addSubview:imageView];
        bjl_return imageView;
    });
    
    self.messageContentView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_colorWithHex:0XF5F5F5];
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = 8.0;
        view.accessibilityLabel = BJLKeypath(self, messageContentView);
        [self.bgView addSubview:view];
        view;
    });
    
    [self.bgView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        CGFloat spaceLeft = BJLScScrollIndicatorSize;
        make.left.top.bottom.equalTo(self.contentView).insets(UIEdgeInsetsMake(BJLScViewSpaceS, spaceLeft, BJLScViewSpaceM, 0));
        make.right.equalTo(self.contentView);
    }];
        
    [self.iconImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.equalTo(self.bgView);
        make.height.width.equalTo(@(avtarIconSize));
    }];

    [self.timeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.deviceImageView.bjl_left);
        make.top.equalTo(self.iconImageView);
        make.width.equalTo(@0.0);
    }];
    
    [self.nameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.equalTo(self.timeLabel);
        make.left.equalTo(self.iconImageView.bjl_right).offset(BJLScViewSpaceS);
        make.right.equalTo(self.timeLabel.bjl_left).offset(-BJLScViewSpaceS);
    }];

    [self.deviceImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.iconImageView);
        make.right.equalTo(self.bgView);
        make.width.height.equalTo(@(deviceIconSize));
    }];
    
    [self.messageContentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.iconImageView.bjl_right).offset(BJLScViewSpaceS);
        make.top.equalTo(self.timeLabel.bjl_bottom).offset(BJLScViewSpaceS);
        make.right.lessThanOrEqualTo(self.bgView);
        make.bottom.equalTo(self.bgView);
    }];
}

- (void)makeMessageLabelAndConstraints {
    [self makeCommonViewsAndConstraints];
    
    self.textView = ({
        UITextView *textView = [UITextView new];
        textView.textAlignment = NSTextAlignmentLeft;
        textView.font = [UIFont systemFontOfSize:12];
        textView.textColor = [UIColor bjl_colorWithHex:0X4A4A4A];
        textView.textContainerInset = UIEdgeInsetsZero;
        textView.textContainer.lineFragmentPadding = 0;
        textView.backgroundColor = [UIColor clearColor];
        textView.selectable = YES;
        textView.editable = NO;
        textView.scrollEnabled = NO;
        textView.userInteractionEnabled = YES;
        textView.delegate = self;
        textView.accessibilityLabel = BJLKeypath(self, textView);
        [self.messageContentView addSubview:textView];
        textView;
    });
    
    [self.textView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.left.right.equalTo(self.messageContentView).insets(UIEdgeInsetsMake(BJLScViewSpaceS, BJLScViewSpaceM, BJLScViewSpaceS, BJLScViewSpaceM));
        make.right.lessThanOrEqualTo(self.deviceImageView);
    }];
}

- (void)makeTranslationMessageLabelAndConstraints {
    [self makeCommonViewsAndConstraints];

    self.textView = ({
        UITextView *textView = [UITextView new];
        textView.textAlignment = NSTextAlignmentLeft;
        textView.font = [UIFont systemFontOfSize:12];
        textView.textColor = [UIColor bjl_colorWithHex:0X4A4A4A];
        textView.textContainerInset = UIEdgeInsetsZero;
        textView.textContainer.lineFragmentPadding = 0;
        textView.backgroundColor = [UIColor clearColor];
        textView.selectable = YES;
        textView.editable = NO;
        textView.scrollEnabled = NO;
        textView.userInteractionEnabled = YES;
        textView.delegate = self;
        [self.messageContentView addSubview:textView];
        textView.accessibilityLabel = BJLKeypath(self, textView);
        textView;
        });

    self.translationSepratorline = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_colorWithHex:0xD8D8D8];
        [self.messageContentView addSubview:view];
        view;
    });
    
    self.translationTextView = ({
        UITextView *textView = [UITextView new];
        textView.textAlignment = NSTextAlignmentLeft;
        textView.textContainerInset = UIEdgeInsetsZero;
        textView.textContainer.lineFragmentPadding = 0;
        textView.backgroundColor = [UIColor clearColor];
        textView.selectable = YES;
        textView.editable = NO;
        textView.scrollEnabled = NO;
        textView.userInteractionEnabled = YES;
        textView.accessibilityLabel = BJLKeypath(self, translationTextView);
        [self.messageContentView addSubview:textView];
        textView;
    });
    
    [self.textView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.messageContentView).insets(UIEdgeInsetsMake(BJLScViewSpaceS, BJLScViewSpaceM, 0, BJLScViewSpaceM));
    }];

    [self.translationSepratorline bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.textView);
        make.height.equalTo(@(1));
        make.top.equalTo(self.textView.bjl_bottom).with.offset(BJLScViewSpaceS);
    }];
    [self.translationTextView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.textView);
        make.top.equalTo(self.translationSepratorline.bjl_bottom).with.offset(BJLScViewSpaceS);
        make.bottom.equalTo(self.messageContentView).with.offset(- BJLScViewSpaceS);
    }];
}

- (void)makeMessageImageViewAndConstraints {
    [self makeCommonViewsAndConstraints];
    
    self.messageImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.clipsToBounds = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.messageContentView addSubview:imageView];
        imageView.accessibilityLabel = BJLKeypath(self, messageImageView);
        imageView;
    });
    
    [self.messageImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.messageContentView).insets(UIEdgeInsetsMake(BJLScViewSpaceS, BJLScViewSpaceM, BJLScViewSpaceS, BJLScViewSpaceM));
        make.width.equalTo(@(imageMinWidth));
        make.height.equalTo(@(imageMinHeight)).priorityHigh();
    }];
}

- (void)makeEmoticonImageViewAndConstraints {
    [self makeCommonViewsAndConstraints];
    self.emoticonImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.clipsToBounds = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.messageContentView addSubview:imageView];
        imageView.accessibilityLabel = BJLKeypath(self, emoticonImageView);
        imageView;
    });
    
    [self.emoticonImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.messageContentView).offset(BJLScViewSpaceM);
        make.top.equalTo(self.messageContentView).offset(BJLScViewSpaceM);
        make.bottom.equalTo(self.messageContentView).offset(-BJLScViewSpaceM);
        make.width.equalTo(@(emoticonSize));
        make.height.equalTo(@(emoticonSize)).priorityHigh();
        make.right.lessThanOrEqualTo(self.messageContentView).offset(-BJLScViewSpaceM).priorityHigh();
    }];
}

- (void)makeUploadingImageMessageLabelAndConstraints {
    [self makeCommonViewsAndConstraints];

    self.messageImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.clipsToBounds = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.messageContentView addSubview:imageView];
        imageView.accessibilityLabel = BJLKeypath(self, messageImageView);
        imageView;
    });
    self.imgProgressView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjlsc_darkDimColor];
        [self.messageContentView addSubview:view];
        view.accessibilityLabel = BJLKeypath(self, imgProgressView);
        view;
    });
    self.failedBadgeButton = ({
        UIButton *button = [UIButton new];
        [button setTitle:@"!" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor bjlsc_redColor];
        button.layer.cornerRadius = BJLScBadgeSize / 2;
        button.layer.masksToBounds = YES;
        [self.bgView addSubview:button];
        button.accessibilityLabel = BJLKeypath(self, failedBadgeButton);
        button;
    });
    bjl_weakify(self);
    [self.failedBadgeButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        if (self.retryUploadingCallback) self.retryUploadingCallback(self);
    }];

    [self.messageContentView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.lessThanOrEqualTo(self.bgView).offset(- (2*BJLScViewSpaceS + BJLScBadgeSize) );
    }];

    [self.messageImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.messageContentView).insets(UIEdgeInsetsMake(BJLScViewSpaceS, BJLScViewSpaceM, BJLScViewSpaceS, BJLScViewSpaceM));
        make.width.equalTo(@(imageMinWidth));
        make.height.equalTo(@(imageMinHeight)).priorityHigh();
    }];

    [self.imgProgressView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.messageImageView);
        self.imgProgressViewHeightConstraint = make.height.equalTo(@0.0).constraint;
    }];

    [self.failedBadgeButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.messageContentView.bjl_right).with.offset(BJLScViewSpaceS);
        make.right.lessThanOrEqualTo(self.bgView).offset(-BJLScViewSpaceS);
        make.centerY.equalTo(self.messageImageView);
        make.width.height.equalTo(@(BJLScBadgeSize));
    }];
}

#pragma mark - public

+ (NSArray<NSString *> *)allCellIdentifiers {
    return @[
        BJLScTextCellReuseIdentifier,
        BJLScTextAndTranslationCellReuseIdentifier,
        BJLScImageCellReuseIdentifier,
        BJLScEmoticonCellReuseIdentifier,
        BJLScMessageUploadingImageIdentifier
    ];
}

- (void)updatReferenceLabelLineNumber:(NSInteger)number {
    self.currentLineNumber = number;
}

- (void)updateWithMessage:(BJLMessage *)message
            fromLoginUser:(BOOL)fromLoginUser
             customString:(nullable NSString *)customString
               chatStatus:(BJLChatStatus)chatStatus
                 isSender:(BOOL)isSender {
    self.chatStatus = chatStatus;
    self.message = message;
    self.messageContentView.backgroundColor = isSender ? [UIColor bjl_colorWithHex:0XD5E9FF] : [UIColor bjl_colorWithHex:0XF5F5F5];
    NSString *urlString = BJLAliIMG_aspectFit(CGSizeMake(avtarIconSize, avtarIconSize),
                                              0.0,
                                              message.fromUser.avatar,
                                              nil);
    [self.iconImageView bjl_setImageWithURL:[NSURL URLWithString:urlString]];

    [self.deviceImageView setImage:[self deviceImageWith:message.fromUser.clientType]];
    self.timeLabel.text = [self timeStringWithTimeInterval:message.timeInterval];
    [self.timeLabel bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.equalTo(@(self.timeLabel.intrinsicContentSize.width));
    }];
    NSString *name = message.fromUser.displayName.length ? message.fromUser.displayName : @"";
    self.nameLabel.canLayout = NO;
    [self.nameLabel updateText:name styleText:customString.length ? [NSString stringWithFormat:@"%@", customString] : nil];

    switch (message.type) {
        case BJLMessageType_text:
        {
            if (message.text.length) {
                // 是否为私聊消息
                BOOL isWisperMessage = (message.toUser.ID.length > 0 && ![message.toUser.ID isEqualToString:@"-1"]);
                
                NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];

                if (isWisperMessage && self.chatStatus != BJLChatStatus_private) {
                    NSAttributedString *whisperTipString = [[NSMutableAttributedString alloc] initWithString:@"私聊"
                    attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12],
                                 NSForegroundColorAttributeName: [UIColor bjl_colorWithHex:0X4A4A4A]}];
                    [string appendAttributedString:whisperTipString];

                    NSString *toName = fromLoginUser ? ([NSString stringWithFormat:@" %@", message.toUser.displayName ?: @"-"]) : @" 我";
                    NSAttributedString *toUserName = [[NSMutableAttributedString alloc] initWithString:toName
                    attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12],
                                 NSForegroundColorAttributeName: [UIColor bjl_colorWithHex:0x1795FF]}];
                    [string appendAttributedString:toUserName];
                    
                    NSAttributedString *nextLine = [[NSMutableAttributedString alloc] initWithString:@"\n"];
                    [string appendAttributedString:nextLine];
                    
                    NSAttributedString *messageText = [message attributedEmoticonStringWithEmoticonSize:16.0 attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12.0],NSForegroundColorAttributeName:[UIColor bjl_colorWithHex:0X4A4A4A]} cached:YES cachedKey:@"cache"];
                    [string appendAttributedString:messageText];
                }
                else {
                    NSAttributedString *messageText = [message attributedEmoticonStringWithEmoticonSize:16.0 attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12.0],NSForegroundColorAttributeName:[UIColor bjl_colorWithHex:0X4A4A4A]} cached:YES cachedKey:@"cache"];
                    [string appendAttributedString:messageText];
                }
                
                self.textView.attributedText = string ;
                self.textView.dataDetectorTypes = (message.fromUser.isTeacherOrAssistant
                                                   ? UIDataDetectorTypeLink
                                                   : UIDataDetectorTypeNone);
                self.textView.linkTextAttributes = @{ NSForegroundColorAttributeName: (message.fromUser.isTeacherOrAssistant
                                                                                       ? [UIColor bjlsc_blueBrandColor]
                                                                                       : [UIColor bjlsc_lightGrayTextColor]) };
            }
            if (message.translation.length) {
                self.translationTextView.text = message.translation;
            }
            break;
        }
        case BJLMessageType_emoticon:
        {
            if (message.emoticon.cachedImage) {
                self.emoticonImageView.image = message.emoticon.cachedImage;
            }
            else {
                NSString *urlString = BJLAliIMG_aspectFit(CGSizeMake(emoticonSize, emoticonSize),
                                                          0.0,
                                                          message.emoticon.urlString,
                                                          nil);
                [self.emoticonImageView bjl_setImageWithURL:[NSURL URLWithString:urlString]
                                                placeholder:nil
                                                 completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
                                                     if (image) {
                                                         message.emoticon.cachedImage = image;
                                                     }
                                                 }];
            }
        }
        case BJLMessageType_image:
        {
            [self _updateImageViewWithImageURLString:message.imageURLString
                                                size:CGSizeMake(message.imageWidth, message.imageHeight)
                                         placeholder:nil];

        }
        default:
            break;
    }
    
    if (message.reference) {
        [self makeReferenceViewWithReferenceMessage:message.reference];
    }
    else {
        
        [self.referenceLabel removeFromSuperview];
        [self.referenceMessageImageView removeFromSuperview];
        [self.referenceEmoticonImageView removeFromSuperview];
        [self.lineView removeFromSuperview];
        self.referenceLabel = nil;
        self.referenceMessageImageView = nil;
        self.referenceEmoticonImageView = nil;
        self.lineView = nil;
        
        if ([self.reuseIdentifier isEqualToString:BJLScTextCellReuseIdentifier]) {
            [self.textView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.top.bottom.left.right.equalTo(self.messageContentView).insets(UIEdgeInsetsMake(BJLScViewSpaceS, BJLScViewSpaceM, BJLScViewSpaceS, BJLScViewSpaceM));
                make.right.lessThanOrEqualTo(self.deviceImageView);
            }];
        }
        else if ([self.reuseIdentifier isEqualToString:BJLScImageCellReuseIdentifier]) {
            [self.messageImageView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.messageContentView).insets(UIEdgeInsetsMake(BJLScViewSpaceS, BJLScViewSpaceM, BJLScViewSpaceS, BJLScViewSpaceM));
                make.width.equalTo(@(imageMinWidth));
                make.height.equalTo(@(imageMinHeight)).priorityHigh();
            }];
        }
        else if ([self.reuseIdentifier isEqualToString:BJLScEmoticonCellReuseIdentifier]) {
            [self.emoticonImageView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.messageContentView).insets(UIEdgeInsetsMake(BJLScViewSpaceS, BJLScViewSpaceM, BJLScViewSpaceS, BJLScViewSpaceM));
                make.width.equalTo(@(emoticonSize));
                make.height.equalTo(@(emoticonSize)).priorityHigh();
            }];
        }
        else if ([self.reuseIdentifier isEqualToString:BJLScTextAndTranslationCellReuseIdentifier]) {
            [self.textView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.top.left.right.equalTo(self.messageContentView).insets(UIEdgeInsetsMake(BJLScViewSpaceS, BJLScViewSpaceM, 0, BJLScViewSpaceM));
            }];

            [self.translationSepratorline bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.left.right.equalTo(self.textView);
                make.height.equalTo(@(1));
                make.top.equalTo(self.textView.bjl_bottom).with.offset(BJLScViewSpaceS);
            }];
            [self.translationTextView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.left.right.equalTo(self.textView);
                make.top.equalTo(self.translationSepratorline.bjl_bottom).with.offset(BJLScViewSpaceS);
                make.bottom.equalTo(self.messageContentView).with.offset(- BJLScViewSpaceS);
            }];
        }
        else if ([self.reuseIdentifier isEqualToString:BJLScMessageUploadingImageIdentifier]) {
            [self.messageImageView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.messageContentView).insets(UIEdgeInsetsMake(BJLScViewSpaceS, BJLScViewSpaceM, BJLScViewSpaceS, BJLScViewSpaceM));
                make.width.equalTo(@(imageMinWidth));
                make.height.equalTo(@(imageMinHeight)).priorityHigh();
            }];

            [self.imgProgressView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                make.left.right.bottom.equalTo(self.messageImageView);
                self.imgProgressViewHeightConstraint = make.height.equalTo(@0.0).constraint;
            }];

            [self.failedBadgeButton bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                make.left.equalTo(self.messageContentView.bjl_right).with.offset(BJLScViewSpaceS);
                make.right.lessThanOrEqualTo(self.bgView).offset(-BJLScViewSpaceS);
                make.centerY.equalTo(self.messageImageView);
                make.width.height.equalTo(@(BJLScBadgeSize));
            }];
        }
    }
}

- (void)makeReferenceViewWithReferenceMessage:(BJLMessage *)message {
    self.lineView = ({
        UIView *line = [UIView new];
        line.backgroundColor = [UIColor bjl_colorWithHexString:@"#9FA8B5" alpha:0.2];
        line.accessibilityLabel = BJLKeypath(self, lineView);
        [self.messageContentView addSubview:line];
        line;
    });
    
    [self.lineView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.messageContentView);
        make.height.equalTo(@1);
    }];
    
    if (BJLMessageType_text == message.type) {
        self.referenceLabel = ({
            UILabel *label = [UILabel new];
            label.textAlignment = NSTextAlignmentLeft;
            label.font = [UIFont systemFontOfSize:12];
            label.textColor = [UIColor bjl_colorWithHex:0X999999];
            label.backgroundColor = [UIColor clearColor];
            label.userInteractionEnabled = YES;
            // 至少显示3行
            label.numberOfLines = self.currentLineNumber < self.limitLine ? self.limitLine : self.currentLineNumber;
            label.accessibilityLabel = BJLKeypath(self, referenceLabel);
            [self.messageContentView addSubview:label];
            label;
        });
        
        if (message.text.length) {
            self.referenceLabel.attributedText = [message attributedEmoticonStringWithEmoticonSize:16.0 attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12.0],NSForegroundColorAttributeName:[UIColor bjl_colorWithHex:0X999999]} cached:YES cachedKey:@"cache"];
            
            bjl_weakify(self);
            UITapGestureRecognizer *tap = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
                bjl_strongify(self);
                CGFloat totalHeight = [self bjlsc_suitableSizeWithText:nil attributedText:self.referenceLabel.attributedText maxWidth:self.referenceLabel.bounds.size.width].height;
                NSInteger line = totalHeight / self.referenceLabel.font.lineHeight;
                if (line > self.limitLine
                    && self.reloadCellCallback) {
                    self.reloadCellCallback(self, self.currentLineNumber < line ? line: self.limitLine);
                }
            }];
            [self.referenceLabel addGestureRecognizer:tap];
        }

        [self.referenceLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.messageContentView).offset(BJLScViewSpaceM);
            make.right.equalTo(self.messageContentView).offset(-BJLScViewSpaceM);
            make.top.equalTo(self.messageContentView).offset(BJLScViewSpaceM);;
            make.bottom.equalTo(self.lineView).offset(-BJLScViewSpaceM);;
            make.right.lessThanOrEqualTo(self.deviceImageView);
        }];
    }
    else if (BJLMessageType_emoticon == message.type) {
        self.referenceEmoticonImageView = ({
            UIImageView *imageView = [UIImageView new];
            imageView.clipsToBounds = YES;
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [self.messageContentView addSubview:imageView];
            imageView.accessibilityLabel = BJLKeypath(self, referenceEmoticonImageView);
            imageView;
        });
        
        [self.referenceEmoticonImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.messageContentView).offset(BJLScViewSpaceM);
            make.top.equalTo(self.messageContentView).offset(BJLScViewSpaceS);
            make.bottom.equalTo(self.lineView).offset(-BJLScViewSpaceS);
            make.width.equalTo(@(emoticonSize));
            make.height.equalTo(@(emoticonSize)).priorityHigh();
        }];
        
        if (message.emoticon.cachedImage) {
            self.referenceEmoticonImageView.image = message.emoticon.cachedImage;
        }
        else {
            NSString *urlString = BJLAliIMG_aspectFit(CGSizeMake(emoticonSize, emoticonSize),
                                                      0.0,
                                                      message.emoticon.urlString,
                                                      nil);
            [self.referenceEmoticonImageView bjl_setImageWithURL:[NSURL URLWithString:urlString]
                                            placeholder:nil
                                             completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
                                                 if (image) {
                                                     message.emoticon.cachedImage = image;
                                                 }
                                             }];
        }
        
    }
    
    if ([self.reuseIdentifier isEqualToString:BJLScTextCellReuseIdentifier]) {
        [self.textView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.lineView.bjl_bottom).offset(BJLScViewSpaceS);
            make.left.equalTo(self.messageContentView).offset(BJLScViewSpaceM);
            make.bottom.equalTo(self.messageContentView).offset(-BJLScViewSpaceS);
            make.right.equalTo(self.messageContentView).offset(-BJLScViewSpaceM);
            make.right.lessThanOrEqualTo(self.deviceImageView);
        }];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLScEmoticonCellReuseIdentifier]) {
        [self.emoticonImageView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.lineView.bjl_bottom).offset(BJLScViewSpaceS);
            make.left.equalTo(self.messageContentView).offset(BJLScViewSpaceM);
            make.bottom.equalTo(self.messageContentView).offset(-BJLScViewSpaceS);
//            make.right.equalTo(self.messageContentView).offset(-BJLScViewSpaceM);
            make.right.lessThanOrEqualTo(self.deviceImageView);
            
            make.width.equalTo(@(emoticonSize));
            make.height.equalTo(@(emoticonSize)).priorityHigh();
        }];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLScTextAndTranslationCellReuseIdentifier]) {
        [self.textView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.lineView.bjl_bottom).offset(BJLScViewSpaceS);
            make.left.equalTo(self.messageContentView).offset(BJLScViewSpaceM);
            make.right.equalTo(self.messageContentView).offset(-BJLScViewSpaceM);
            make.right.lessThanOrEqualTo(self.deviceImageView);
        }];
        [self.translationSepratorline bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.right.equalTo(self.textView);
            make.height.equalTo(@(1));
            make.top.equalTo(self.textView.bjl_bottom).with.offset(BJLScViewSpaceS);
        }];
        [self.translationTextView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.right.equalTo(self.textView);
            make.top.equalTo(self.translationSepratorline.bjl_bottom).with.offset(BJLScViewSpaceS);
            make.bottom.equalTo(self.messageContentView).with.offset(- BJLScViewSpaceS);
        }];
    }
}

- (void)updateWithUploadingTask:(BJLChatUploadingTask *)task
                     chatStatus:(BJLChatStatus)chatStatus
                       fromUser:(BJLUser *)fromUser {
    self.chatStatus = chatStatus;
    self.messageContentView.backgroundColor = [UIColor bjl_colorWithHex:0XD5E9FF];

    [self.nameLabel updateText:fromUser.displayName.length ? fromUser.displayName : nil styleText:nil];
    NSString *urlString = BJLAliIMG_aspectFit(CGSizeMake(avtarIconSize, avtarIconSize),
                                              0.0,
                                              fromUser.avatar,
                                              nil);
    [self.iconImageView bjl_setImageWithURL:[NSURL URLWithString:urlString]];

    [self.deviceImageView setImage:[self deviceImageWith:fromUser.clientType]];
    self.timeLabel.text = [self timeStringWithTimeInterval:[[NSDate date] timeIntervalSince1970] ];

    [self _updateImageViewWithImageOrNil:task.thumbnail size:task.thumbnail.size];
    self.failedBadgeButton.hidden = !task.error;
    
    [self.imgProgressView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        [self.imgProgressViewHeightConstraint uninstall];
        self.imgProgressViewHeightConstraint = make.height.equalTo(self.messageImageView).multipliedBy(1.0 - task.progress * 0.9).constraint;
    }];
}

+ (CGFloat)estimatedRowHeightForMessageType:(BJLMessageType)type {
    switch (type) {
        case BJLMessageType_emoticon:
            return emoticonMessageCellHeight;
        case BJLMessageType_image:
            return imageMessageCellMinHeight;
        default:
            return oneLineMessageCellHeight;
    }
}

+ (NSString *)cellIdentifierForMessageType:(BJLMessageType)type hasTranslation:(BOOL)hasTranslation {
    switch (type) {
        case BJLMessageType_image:
            return BJLScImageCellReuseIdentifier;
        case BJLMessageType_emoticon:
            return BJLScEmoticonCellReuseIdentifier;
        default:
        {
            if (hasTranslation) {
                return BJLScTextAndTranslationCellReuseIdentifier;
            }
            else {
                return BJLScTextCellReuseIdentifier;
            }
        }
    }
}

+ (NSString *)cellIdentifierForUploadingImage {
    return BJLScMessageUploadingImageIdentifier;
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

#pragma mark - private

- (UIImage *)deviceImageWith:(BJLClientType)type {
    switch (type) {
        case BJLClientType_PCWeb:
            return [UIImage bjlsc_imageNamed:@"bjl_sc_device_web"];
            
        case BJLClientType_PCApp:
            return [UIImage bjlsc_imageNamed:@"bjl_sc_device_win"];
            
        case BJLClientType_iOSApp:
            return [UIImage bjlsc_imageNamed:@"bjl_sc_device_iphone"];
            
        case BJLClientType_AndroidApp:
            return [UIImage bjlsc_imageNamed:@"bjl_sc_device_andriod"];
            
        case BJLClientType_MacApp:
            return [UIImage bjlsc_imageNamed:@"bjl_sc_device_mac"];
            
        case BJLClientType_MobileWeb:
            return [UIImage bjlsc_imageNamed:@"bjl_sc_device_h5"];
            
        case BJLClientType_MiniProgram:
            return [UIImage bjlsc_imageNamed:@"bjl_sc_device_Applet"];
            
        default:
            return [UIImage bjlsc_imageNamed:@"bjl_sc_device_default"];
    }
}

- (NSString *)timeStringWithTimeInterval:(NSTimeInterval)timeInterval {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

- (void)_updateImageViewWithImageURLString:(NSString *)imageURLString
                                      size:(CGSize)size
                               placeholder:(UIImage *)placeholder {
    size = (CGSizeEqualToSize(size, CGSizeZero)
            ? CGSizeMake(imageMinWidth, imageMinHeight)
            : size);
    
    [self _updateImageViewWithImageOrNil:placeholder size:size];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat maxSize = MAX(screenSize.width, screenSize.height);
    NSString *aliURLString = BJLAliIMG_aspectFit(CGSizeMake(maxSize, maxSize),
                                                 0.0,
                                                 imageURLString,
                                                 nil);
    bjl_weakify(self);
    self.messageImageView.backgroundColor = [UIColor bjlsc_grayImagePlaceholderColor];
    [self.messageImageView bjl_setImageWithURL:[NSURL URLWithString:aliURLString]
                          placeholder:placeholder
                           completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
                               bjl_strongify(self);
                               if (image) {
                                   self.messageImageView.backgroundColor = [UIColor bjlsc_grayImagePlaceholderColor];
                               }
                               [self _updateImageViewWithImageOrNil:image size:image.size];
                               if (self.updateConstraintsCallback && !error) self.updateConstraintsCallback(self);
                           }];
}

- (void)_updateImageViewWithImageOrNil:(nullable UIImage *)image size:(CGSize)size {
    self.messageImageView.image = image;
    [self updateImgViewConstraintsWithSize:BJLImageViewSize(image ? image.size : size, CGSizeMake(imageMinWidth, imageMinHeight), ({
        CGSizeMake(imageMaxWidth, imageMaxHeight);
    }))];
}

- (void)updateImgViewConstraintsWithSize:(CGSize)size {
    [self.messageImageView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        make.width.equalTo(@(size.width));
        make.height.equalTo(@(size.height)).priorityHigh();
    }];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self];
    if (CGRectContainsPoint(self.iconImageView.frame, point)
        || CGRectContainsPoint(self.nameLabel.frame, point)) {
        if (self.userSelectCallback) {
            self.userSelectCallback(self);
        }
        return;
    }
    
    CGRect messageImageViewFrame = [self convertRect:self.messageImageView.frame fromView:self.messageContentView];
    if (CGRectContainsPoint(messageImageViewFrame, point)) {
        if (self.imageSelectCallback) {
            self.imageSelectCallback(self);
        }
    }
}

@end
