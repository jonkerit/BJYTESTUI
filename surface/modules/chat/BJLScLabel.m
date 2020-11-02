//
//  BJLScLabel.m
//  BJLiveUI
//
//  Created by xijia dai on 2020/8/28.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLScLabel.h"
#import "BJLScAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScLabel ()

@property (nonatomic, nullable) NSString *text, *styleText;
@property (nonatomic) NSInteger minHeadCount;
@property (nonatomic, nullable) NSString *headStyle;
@property (nonatomic, nullable) NSString *tailStyle;
@property (nonatomic) CGFloat fontSize;

@property (nonatomic) UILabel *normalLabel, *subLabel, *headLabel, *midLabel, *tailLabel;
@property (nonatomic, nullable) BJLConstraint *normalLabelConstraint, *subLabelConstraint, *headLabelConstraint, *midLabelConstraint, *tailLabelConstraint;

@end

@implementation BJLScLabel

static CGFloat omitWidth = 0.0;

- (instancetype)initWitMinHeadCount:(NSInteger)minHeadCount
                          headStyle:(nullable NSString *)headStyle
                          tailStyle:(nullable NSString *)tailStyle
                           fontSize:(CGFloat)fontSize {
    if (self = [super initWithFrame:CGRectZero]) {
        self.minHeadCount = minHeadCount;
        self.headStyle = headStyle ?: @"";
        self.tailStyle = tailStyle ?: @"";
        self.textColor = [UIColor systemGrayColor];
        self.fontSize = fontSize;
        [self makeSubviewAndConstraints];
    }
    return self;
}

- (void)makeSubviewAndConstraints {
    self.normalLabel = [self makeLabelWithAccessibilityLabel:BJLKeypath(self, normalLabel)];
    self.subLabel = [self makeLabelWithAccessibilityLabel:BJLKeypath(self, subLabel)];
    self.headLabel = [self makeLabelWithAccessibilityLabel:BJLKeypath(self, headLabel)];
    self.midLabel = [self makeLabelWithAccessibilityLabel:BJLKeypath(self, midLabel)];
    self.midLabel.textAlignment = NSTextAlignmentCenter;
    self.tailLabel = [self makeLabelWithAccessibilityLabel:BJLKeypath(self, tailLabel)];
    self.tailLabel.textAlignment = NSTextAlignmentRight;
    
    [self.normalLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.centerY.height.equalTo(self);
    }];

    [self.subLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.normalLabel.bjl_right);
        make.centerY.height.equalTo(self);
    }];
    
    [self.headLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.subLabel.bjl_right);
        make.centerY.height.equalTo(self);
    }];
    
    [self.tailLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.centerY.height.equalTo(self);
    }];
    
    [self.midLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.headLabel.bjl_right);
        make.right.equalTo(self.tailLabel.bjl_left);
        make.centerY.height.equalTo(self);
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.canLayout = YES;
    [self updateText:self.text styleText:self.styleText];
}

- (void)updateText:(nullable NSString *)text styleText:(nullable NSString *)styleText {
    text = text ?: @"";
    styleText = styleText ?: @"";
    self.text = text;
    self.styleText = styleText;
    // 在 layout 之前不处理
    if (!self.canLayout) {
        return;
    }
    // 清空内容
    self.normalLabel.text = nil;
    self.subLabel.text = nil;
    self.headLabel.text = nil;
    self.midLabel.text = nil;
    self.tailLabel.text = nil;
    // 重置约束
    [self removeLabelConstraints];
    // 如果传的字符为空，重置视图
    if (!text.length && !styleText.length) {
        return;
    }
    // 如果不需要支持最小前缀或者字符大小小于最小前缀，直接将字符设置到首个 label
    if (self.minHeadCount <= 0 || text.length <= self.minHeadCount) {
        self.normalLabel.text = text;
    }
    // 如果字符大小大于最小前缀，裁剪为二个标签
    else if (text.length > self.minHeadCount) {
        self.normalLabel.text = [NSString stringWithFormat:@"%@", [text substringToIndex:self.minHeadCount]];
        self.subLabel.text = [NSString stringWithFormat:@"%@", [text substringFromIndex:self.minHeadCount]];
    }
    // 设置字符样式
    if (styleText.length) {
        self.headLabel.text = self.headStyle;
        self.midLabel.text = styleText;
        self.tailLabel.text = self.tailStyle;
    }
    
    // 计算字符预期大小
    CGFloat normalLabelWidth = [self normalLabelWidth];
    CGFloat headLabelWidth = [self headLabelWidth];
    CGFloat tailLabelWidth = [self tailLabelWidth];
    CGFloat subLabelWidth = [self subLabelWidth];
    CGFloat midLabelWidth = [self midLabelWidth];
    CGFloat minSize = normalLabelWidth + headLabelWidth + tailLabelWidth;
    CGFloat size = minSize + subLabelWidth + midLabelWidth;
    CGFloat maxWidth = CGRectGetWidth(self.bounds);
    
    // 如果最小尺寸都大于视图允许的最大尺寸，作为普通单个 label 使用
    if (minSize + 2.0 > maxWidth) {
        [self resetToSingleLabel];
        return;
    }
    // 如果期望尺寸小于等于视图允许的最大尺寸，重置为普通的 label 使用
    if (size <= maxWidth) {
        [self resetToSingleLabel];
        return;
    }
    // 如果视图的期望尺寸大于允许的最大尺寸
    CGFloat omitWidth = [self omitWidth];
    CGFloat remainSubWidth = maxWidth - minSize - midLabelWidth;
    // 如果字符后者能够完整显示，并且字符前者大于 ... 需要的尺寸，设置
    if (remainSubWidth > omitWidth) {
        [self setMinSizeExpectedLayout:normalLabelWidth headLabelWidth:headLabelWidth tailLabelWidth:tailLabelWidth];
        [self setSubAndMidLayout:remainSubWidth midLabelWidth:midLabelWidth];
    }
    // 如果字符后者在字符前者设置为 ... 的情况下都不能完整显示
    else {
        CGFloat remainMidSize = maxWidth - minSize - omitWidth;
        // 如果字符前者不足以使用 ... ，重置视图为单个 label 的显示效果
        if (omitWidth + 2.0 > remainMidSize) {
            [self resetToSingleLabel];
        }
        // 否则，前者字符使用 ... ，后者使用剩余部分
        else {
            self.subLabel.text = @"...";
            [self setMinSizeExpectedLayout:normalLabelWidth headLabelWidth:headLabelWidth tailLabelWidth:tailLabelWidth];
            [self setSubAndMidLayout:omitWidth midLabelWidth:remainMidSize];
        }
    }
}

- (void)setMinSizeExpectedLayout:(CGFloat)normalLabelWidth
                  headLabelWidth:(CGFloat)headLabelWidth
                  tailLabelWidth:(CGFloat)tailLabelWidth {
    // 布局需要的最小尺寸的视图
    [self.normalLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        self.normalLabelConstraint = make.width.equalTo(@(normalLabelWidth)).constraint;
    }];
    [self.headLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        self.headLabelConstraint = make.width.equalTo(@(headLabelWidth)).constraint;
    }];
    [self.tailLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        self.tailLabelConstraint = make.width.equalTo(@(tailLabelWidth)).constraint;
    }];
}

- (void)setSubAndMidLayout:(CGFloat)subLabelWidth
             midLabelWidth:(CGFloat)midLabelWidth {
    [self.subLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        self.subLabelConstraint = make.width.equalTo(@(subLabelWidth)).constraint;
    }];
    [self.midLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        self.midLabelConstraint = make.width.equalTo(@(midLabelWidth)).constraint;
    }];
}

- (void)resetToSingleLabel {
    CGFloat maxWidth = CGRectGetWidth(self.bounds);
    if (self.styleText.length) {
        self.normalLabel.text = [NSString stringWithFormat:@"%@%@%@%@", self.text, self.headStyle, self.styleText, self.tailStyle];
    }
    else {
        self.normalLabel.text = self.text;
    }
    [self setMinSizeExpectedLayout:maxWidth headLabelWidth:0.0 tailLabelWidth:0.0];
    [self setSubAndMidLayout:0.0 midLabelWidth:0.0];
}

- (void)removeLabelConstraints {
    if (self.normalLabelConstraint) {
        [self.normalLabelConstraint uninstall];
        self.normalLabelConstraint = nil;
    }
    if (self.headLabelConstraint) {
        [self.headLabelConstraint uninstall];
        self.headLabelConstraint = nil;
    }
    if (self.tailLabelConstraint) {
        [self.tailLabelConstraint uninstall];
        self.tailLabelConstraint = nil;
    }
    if (self.subLabelConstraint) {
        [self.subLabelConstraint uninstall];
        self.subLabelConstraint = nil;
    }
    if (self.midLabelConstraint) {
        [self.midLabelConstraint uninstall];
        self.midLabelConstraint = nil;
    }
}

#pragma mark -

- (CGFloat)subLabelWidth {
    CGFloat subLabelWidth = [self bjlsc_oneRowSizeWithText:self.subLabel.text attributedText:nil fontSize:self.fontSize].width;
    return ceil(subLabelWidth);
}

- (CGFloat)midLabelWidth {
    CGFloat midLabelWidth = [self bjlsc_oneRowSizeWithText:self.midLabel.text attributedText:nil fontSize:self.fontSize].width;
    return ceil(midLabelWidth);
}

- (CGFloat)omitWidth {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        omitWidth = [self bjlsc_oneRowSizeWithText:@"..." attributedText:nil fontSize:self.fontSize].width;
        omitWidth = ceil(omitWidth);
    });
    return omitWidth;
}

- (CGFloat)normalLabelWidth {
    CGFloat normalLabelWidth = [self bjlsc_oneRowSizeWithText:self.normalLabel.text attributedText:nil fontSize:self.fontSize].width;
    return ceil(normalLabelWidth);
}

- (CGFloat)headLabelWidth {
    CGFloat headLabelWidth = [self bjlsc_oneRowSizeWithText:self.headLabel.text attributedText:nil fontSize:self.fontSize].width;
    return ceil(headLabelWidth);
}

- (CGFloat)tailLabelWidth {
    CGFloat tailLabelWidth = [self bjlsc_oneRowSizeWithText:self.tailLabel.text attributedText:nil fontSize:self.fontSize].width;
    return ceil(tailLabelWidth);
}

#pragma mark -

- (UILabel *)makeLabelWithAccessibilityLabel:(NSString *)accessibilityLabel {
    UILabel *label = [UILabel new];
    label.accessibilityLabel = accessibilityLabel;
    label.numberOfLines = 1;
    label.textAlignment = NSTextAlignmentLeft;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.textColor = self.textColor;
    label.font = [UIFont systemFontOfSize:self.fontSize];
    [self addSubview:label];
    return label;
}

@end

NS_ASSUME_NONNULL_END
