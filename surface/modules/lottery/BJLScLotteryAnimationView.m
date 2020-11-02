//
//  BJLScLotteryAnimationView.m
//  BJLiveUI
//
//  Created by xyp on 2020/8/26.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLScLotteryAnimationView.h"
#import "BJLScAppearance.h"

@interface BJLScLotteryAnimationView()

@property (nonatomic, nullable) UIImageView *eggDownImageView, *eggImageView;
@property (nonatomic, nullable) UILabel *countLabel;
@property (nonatomic) NSInteger count;

@end

CGFloat bottomSpace = 50.0;

@implementation BJLScLotteryAnimationView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self startEggDownAnimation];
    }
    return self;
}

// 每次都需要重新初始化以下views
- (void)startEggDownAnimation {
    self.count = 3.0;
    
    self.eggDownImageView = ({
         UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_lottery_down"]];
         imageView.accessibilityLabel = BJLKeypath(self, eggDownImageView);
         [self addSubview:imageView];
         imageView;
     });

    CGFloat width = self.eggDownImageView.image.size.width * 1.5;
    CGFloat height = self.eggDownImageView.image.size.height * 1.5;
    CGFloat x = self.center.x - (width / 2.0);
    CGFloat y = self.bounds.size.height - height - bottomSpace;
    
    self.eggDownImageView.frame = CGRectMake(x, -height, width, height);
    
    [UIView animateWithDuration:0.5 animations:^{
        self.eggDownImageView.frame = CGRectMake(x, y, width, height);
    } completion:^(BOOL finished) {
        [self makeEggTimeView];
        self.eggDownImageView.frame = CGRectMake(x, -height, width, height);
        [self.eggDownImageView removeFromSuperview];
        self.eggDownImageView = nil;
    }];
}

- (void)makeEggTimeView {
    self.eggImageView = [[UIImageView alloc] initWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_lottery_time"]];
    self.eggImageView.accessibilityLabel = BJLKeypath(self, eggImageView);
    [self addSubview:self.eggImageView];
    [self.eggImageView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self).offset(-bottomSpace);
        make.size.equal.sizeOffset(CGSizeMake(self.eggImageView.image.size.width * 1.5, self.eggImageView.image.size.height * 1.5));
    }];
    
    self.countLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, countLabel);
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor bjl_colorWithHexString:@"#F7D065"];
        label.font = [UIFont systemFontOfSize:20.0];
        label.text = [NSString stringWithFormat:@"%td", self.count];
        label;
    });
    
    [self addSubview:self.countLabel];
    [self.countLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.eggImageView);
        make.top.equalTo(self.eggImageView.bjl_centerY);
        make.height.equalTo(@20);
    }];
    
    [self countDownTimer];
    [UIView animateWithDuration:self.count animations:^{
        self.eggImageView.transform = CGAffineTransformScale(self.eggImageView.transform, 0.8, 0.8);
    } completion:^(BOOL finished) {
        self.eggImageView.transform = CGAffineTransformScale(self.eggImageView.transform, 0.9, 0.9);
    }];
}

- (void)countDownTimer {
    [self performSelector:@selector(countDown) withObject:nil afterDelay:1.0];
}

- (void)countDown {
    self.count--;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (self.count > 0) {
        self.countLabel.text = [NSString stringWithFormat:@"%td", self.count];
        [self countDownTimer];
    }
    else {
        [self.countLabel removeFromSuperview];
        self.eggImageView.image = [UIImage bjlsc_imageNamed:@"bjl_sc_lottery_boom"];
        [UIView animateWithDuration:0.2 animations:^{
            self.eggImageView.transform = CGAffineTransformScale(self.eggImageView.transform, 2.5, 2.5);
            self.eggImageView.alpha = 0.2;
        } completion:^(BOOL finished) {
            if (self.animationFinishCallback) {
                self.animationFinishCallback(self);
            }
            [self.eggImageView removeFromSuperview];
            self.eggImageView = nil;
        }];
    }
}

@end
