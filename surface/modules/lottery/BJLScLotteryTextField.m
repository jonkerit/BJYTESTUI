//
//  BJLScLotteryTextField.m
//  BJLiveUI
//
//  Created by xyp on 2020/8/27.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLScLotteryTextField.h"

#import "BJLScAppearance.h"

@interface BJLScLotteryTextField() <UITextFieldDelegate>

@property (nonatomic) UILabel *tipLabel;

@end

@implementation BJLScLotteryTextField

- (instancetype)initWithPlaceholder:(NSString *)placeholder {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self makeSubviews];
        self.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.placeholder = placeholder;
        self.textColor = [UIColor bjl_colorWithHexString:@"#AE6008"];

        self.delegate = self;
    }
    return self;
}

- (void)makeSubviews {
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 4.0;
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = [UIColor bjl_colorWithHexString:@"#F7C16D"].CGColor;
    self.leftViewMode = UITextFieldViewModeAlways;
    self.backgroundColor = [UIColor bjl_colorWithHexString:@"#FDD892"];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 0)];
    label.textColor = [UIColor bjl_colorWithHexString:@"#AE6008"];
    label.textAlignment = NSTextAlignmentRight;
    label.font = [UIFont systemFontOfSize:14.0];
    label.text = @"      ";
    self.leftView = label;
    
    self.tipLabel = [UILabel new];
    self.tipLabel.textAlignment = NSTextAlignmentRight;
    self.tipLabel.font = [UIFont systemFontOfSize:14.0];
    self.tipLabel.textColor = [UIColor bjl_colorWithHexString:@"#FF615A"];
    self.tipLabel.hidden = YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (!self.tipLabel.hidden) {    
        self.tipLabel.hidden = YES;
        [self.tipLabel removeFromSuperview];
    }
    return YES;
}

// 重写此方法
-(void)drawPlaceholderInRect:(CGRect)rect {
    // 计算占位文字的 Size
    CGSize placeholderSize = [self.placeholder sizeWithAttributes: @{NSFontAttributeName : [UIFont systemFontOfSize:12.0]}];

    [self.placeholder drawInRect:CGRectMake(0, (rect.size.height - placeholderSize.height) / 2, rect.size.width, rect.size.height)
                  withAttributes:@{NSForegroundColorAttributeName : [UIColor bjl_colorWithHexString:@"#AE6008" alpha:0.4],
                                   NSFontAttributeName            : [UIFont systemFontOfSize:14.0]}];
}

- (void)updateTip:(NSString *)tip {
    self.tipLabel.text = tip;
    self.tipLabel.hidden = NO;
    [self addSubview:self.tipLabel];
    [self.tipLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self);
        make.right.equalTo(self).offset(-10);
        make.top.bottom.equalTo(self);
    }];
}

@end
