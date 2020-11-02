//
//  BJLScVideoPlaceholderView.m
//  BJLiveUI
//
//  Created by xijia dai on 2020/2/21.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLScVideoPlaceholderView.h"
#import "BJLScAppearance.h"

@interface BJLScVideoPlaceholderView ()

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *label;

@end

@implementation BJLScVideoPlaceholderView

- (instancetype)initWithImage:(UIImage *)image tip:(NSString *)tip {
    if (self = [super initWithFrame:CGRectZero]) {
        [self makeSubviewAndConstraintsWithImage:image tip:tip];
    }
    return self;
}

- (void)makeSubviewAndConstraintsWithImage:(UIImage *)image tip:(NSString *)tip {
    //BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);

    self.backgroundColor = [UIColor bjl_colorWithHex:0X424242];
    
    self.imageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.backgroundColor = [UIColor clearColor];
        imageView.image = image;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.clipsToBounds = YES;
        [self addSubview:imageView];
        [imageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(self);
            make.centerY.equalTo(self).offset(-BJLScViewSpaceM);
            make.height.equalTo(self).multipliedBy(0.5);
            make.width.equalTo(imageView.bjl_height);
            make.height.width.lessThanOrEqualTo(@(BJLScOverlayImageMaxSize)).priorityHigh();
            make.height.width.greaterThanOrEqualTo(@(BJLScOverlayImageMinSize)).priorityHigh();
        }];
        bjl_return imageView;
    });
    
    self.label = ({
        UILabel *label = [UILabel new];
        label.text = tip;
        label.textColor = [UIColor bjl_colorWithHex:0X979797];
        label.font = [UIFont systemFontOfSize:12];
        [self addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.imageView.bjl_bottom);
            make.centerX.equalTo(self.imageView);
        }];
        bjl_return label;
    });
}

- (void)updateTip:(NSString *)tip font:(UIFont *)font {
    if (tip) {
        self.label.text = tip;
    }
    if (font) {
        self.label.font = font;
    }
}

- (void)updateImage:(UIImage *)image{
    if (image) {
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.image = image;
    }
}

- (void)updateImageWithURLString:(NSString *)imageURLString placeholder:(nullable UIImage *)placeholderImage {
    if (imageURLString.length) {
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        bjl_weakify(self);
        [self.imageView bjl_setImageWithURL:[NSURL URLWithString:imageURLString] placeholder:placeholderImage completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
            bjl_strongify(self);
            if (error) {
                [self updateImage:placeholderImage];
            }
            else {
                [self.imageView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                    make.edges.equalTo(self);
                }];
            }
        }];
    }
}

@end
