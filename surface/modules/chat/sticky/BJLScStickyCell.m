//
//  BJLScStickyCell.m
//  BJLiveUI
//
//  Created by xyp on 2020/8/12.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLScStickyCell.h"
#import "BJLScAppearance.h"
#import "BJLScLabel.h"

NSString
* const BJLScStudentStickyCellIdentifier = @"BJLScStudentStickyCellIdentifier",
* const BJLScTeacherStickyCellIdentifier = @"BJLScTeacherStickyCellIdentifier";

@interface BJLScStickyCell() <UITextViewDelegate>
@property (nonatomic) BJLMessage *message;
@property (nonatomic) BJLScLabel *nameLabel;
@property (nonatomic, nullable) UIButton *cancelStickyButton;
@property (nonatomic) UIView *messageContentView;
@property (nonatomic) UITextView *textView;
//避免个系统属性重名
@property (nonatomic) UIImageView *imgView;
@property (nonatomic) UIImageView *stickyImageView;

@end

@implementation BJLScStickyCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self makeSubviewsAndConstraints];
        [self prepareForReuse];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imgView.image = nil;
    [self.nameLabel updateText:nil styleText:nil];
    self.textView.text = @"";
}

- (void)updateWithMessage:(BJLMessage *)message
             customString:(NSString *)customString {
    self.message = message;
    NSString *name = message.fromUser.displayName.length ? message.fromUser.displayName : @"";
    [self.nameLabel updateText:name styleText:customString.length ? [NSString stringWithFormat:@"%@", customString] : nil];
    [self.messageContentView bjl_uninstallConstraints];
    [self.imgView bjl_uninstallConstraints];
    [self.textView bjl_uninstallConstraints];
    
    if (message.type != BJLMessageType_image) {
        NSAttributedString *messageText = [message attributedEmoticonStringWithEmoticonSize:16.0 attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12.0], NSForegroundColorAttributeName:[UIColor bjl_colorWithHex:0X545454]} cached:YES cachedKey:@"cache"];
        
        self.textView.attributedText = messageText ;
        self.textView.dataDetectorTypes = (message.fromUser.isTeacherOrAssistant
                                           ? UIDataDetectorTypeLink
                                           : UIDataDetectorTypeNone);
        
        [self.textView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.bottom.left.right.equalTo(self.messageContentView).insets(UIEdgeInsetsMake(BJLScViewSpaceS, BJLScViewSpaceM, BJLScViewSpaceS, BJLScViewSpaceM));
        }];
        
        [self.messageContentView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.nameLabel.bjl_bottom).offset(1.0);
            make.right.equalTo(self.contentView).offset(-BJLScViewSpaceS);
            make.bottom.equalTo(self.contentView).offset(-BJLScViewSpaceM);
            make.left.equalTo(self.contentView).offset(BJLScViewSpaceS);
        }];
    }
    else {
        [self.imgView bjl_setImageWithURL:[NSURL URLWithString:message.imageURLString]];
        CGFloat imageWidth = message.imageWidth ?: self.imgView.image.size.width;
        CGFloat imageHeight = message.imageHeight ?: self.imgView.image.size.height;
        CGFloat contentViewWidth = self.contentView.frame.size.width;
        CGFloat width = imageWidth;
        CGFloat height = imageHeight;
        if (imageWidth > contentViewWidth) {
            height = self.contentView.frame.size.width * imageHeight / imageWidth;
            width = contentViewWidth;
        }
        
        [self.imgView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.equalTo(@(height));
            make.width.equalTo(@(width));
            make.top.bottom.left.right.equalTo(self.messageContentView).insets(UIEdgeInsetsMake(BJLScViewSpaceS, BJLScViewSpaceS, BJLScViewSpaceS, BJLScViewSpaceS));
        }];
        
        [self.messageContentView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.nameLabel.bjl_bottom).offset(1.0);
            make.left.equalTo(self.contentView).offset(BJLScViewSpaceS);
            make.right.bottom.lessThanOrEqualTo(self.contentView).offset(-BJLScViewSpaceS);
            make.size.equal.sizeOffset(CGSizeMake(width, height)).priorityHigh();
        }];
    }
}

- (void)makeSubviewsAndConstraints {
    self.stickyImageView = [[UIImageView alloc] initWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_chat_sticky"]];
    
    self.nameLabel = ({
        BJLScLabel *label = [[BJLScLabel alloc] initWitMinHeadCount:2 headStyle:@" [" tailStyle:@"]" fontSize:14.0];
        label.accessibilityLabel = BJLKeypath(self, nameLabel);
        label.textColor = [UIColor bjl_colorWithHex:0X333333];
        label;
    });
    
    self.messageContentView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, messageContentView);
        view.backgroundColor = [UIColor bjl_colorWithHex:0XF1F1F1];
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = 4.0;
        view.accessibilityLabel = BJLKeypath(self, messageContentView);
        view;
    });
    
    self.textView = ({
        UITextView *textView = [UITextView new];
        textView.accessibilityLabel = BJLKeypath(self, messageContentView);
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
    
    if ([self.reuseIdentifier isEqualToString:BJLScTeacherStickyCellIdentifier]) {
        self.cancelStickyButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.accessibilityLabel = BJLKeypath(self, cancelStickyButton);
            button.titleLabel.textAlignment = NSTextAlignmentRight;
            [button setTitle:@"取消置顶" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor bjl_colorWithHexString:@"#949494"] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor bjl_colorWithHexString:@"#FF1F49"] forState:UIControlStateHighlighted];
            button.titleLabel.font = [UIFont systemFontOfSize:12.0];
            [button addTarget:self action:@selector(cancelStickyAction:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
    }
    
    self.imgView = [[UIImageView alloc] init];
    self.imgView.accessibilityLabel = BJLKeypath(self, imgView);
    self.imgView.userInteractionEnabled = YES;
    [self.messageContentView addSubview:self.imgView];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageViewAction:)];
    [self.imgView addGestureRecognizer:tap];
    
    [self.contentView addSubview:self.stickyImageView];
    [self.contentView addSubview:self.nameLabel];
    if (self.cancelStickyButton) {
        [self.contentView addSubview:self.cancelStickyButton];
    }
    [self.contentView addSubview:self.messageContentView];
    
    [self.stickyImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.contentView).offset(BJLScViewSpaceM);
        make.height.width.equalTo(@16);
        make.top.equalTo(self.contentView).offset(BJLScViewSpaceS);
    }];
    [self.nameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.stickyImageView.bjl_right).offset(BJLScViewSpaceM);
        make.right.equalTo(self.cancelStickyButton ? self.cancelStickyButton.bjl_left : self.contentView).offset(-BJLScViewSpaceS);;
        make.height.equalTo(@20);
        make.centerY.equalTo(self.stickyImageView);
    }];
    
    if (self.cancelStickyButton) {
        [self.cancelStickyButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.contentView).offset(-BJLScViewSpaceS);
            make.centerY.equalTo(self.stickyImageView);
            make.height.equalTo(@18);
            make.hugging.compressionResistance.required();
        }];
    }
}

#pragma mark -

- (void)cancelStickyAction:(UIButton *)button {
    if (self.cancelStickyCallback) {
        self.cancelStickyCallback();
    }
}

- (void)tapImageViewAction:(UITapGestureRecognizer *)tap {
    if (self.imageTapCallback) {
        self.imageTapCallback(self.message);
    }
}

#pragma mark -

// 文本链接跳转
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if (self.linkURLCallback) {
        return self.linkURLCallback(URL);
    }
    return NO;
}

@end
