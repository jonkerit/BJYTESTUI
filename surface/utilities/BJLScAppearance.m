//
//  BJLScAppearance.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScAppearance.h"
#import "BJLScRoomViewController.h"

#pragma mark -

@implementation UIColor (BJLSurfaceClass)

+ (UIColor *)bjlsc_darkGrayBackgroundColor {
    return [UIColor bjl_colorWithHex:0x1D1D1E];
}

+ (instancetype)bjlsc_lightGrayBackgroundColor {
    return [UIColor bjl_colorWithHex:0xF8F8F8];
}

+ (UIColor *)bjlsc_darkGrayTextColor {
    return [UIColor bjl_colorWithHex:0x3D3D3E];
}

+ (instancetype)bjlsc_grayTextColor {
    return [UIColor bjl_colorWithHex:0x6D6D6E];
}

+ (instancetype)bjlsc_lightGrayTextColor {
    return [UIColor bjl_colorWithHex:0x9D9D9E];
}

+ (instancetype)bjlsc_grayBorderColor {
    return [UIColor bjl_colorWithHex:0xCDCDCE];
}

+ (instancetype)bjlsc_grayLineColor {
    return [UIColor bjl_colorWithHex:0xDDDDDE];
}

+ (instancetype)bjlsc_grayImagePlaceholderColor {
    return [UIColor bjl_colorWithHex:0xEDEDEE];
}

+ (instancetype)bjlsc_blueBrandColor {
    return [UIColor bjl_colorWithHex:0x37A4F5];
}

+ (instancetype)bjlsc_orangeBrandColor {
    return [UIColor bjl_colorWithHex:0xFF9100];
}

+ (instancetype)bjlsc_redColor {
    return [UIColor bjl_colorWithHex:0xFF5850];
}

#pragma mark -

+ (UIColor *)bjlsc_lightDimColor {
    return [UIColor colorWithWhite:0.0 alpha:0.2];
}

+ (instancetype)bjlsc_dimColor {
    return [UIColor colorWithWhite:0.0 alpha:0.5];
}

+ (instancetype)bjlsc_darkDimColor {
    return [UIColor colorWithWhite:0.0 alpha:0.6];
}

@end

#pragma mark -

@implementation NSObject (BJLSurfaceClass)

- (CGSize)bjlsc_suitableSizeWithText:(nullable NSString *)text attributedText:(nullable NSAttributedString *)attributedText maxWidth:(CGFloat)maxWidth {
    __block CGFloat messageLabelHeight = 0.0;
    __block CGFloat messageLabelWidth = 0.0;
    if (text) {
        [text enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
            CGRect rect = [line boundingRectWithSize:CGSizeMake(maxWidth, MAXFLOAT) options:NSStringDrawingUsesFontLeading |NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0]} context:nil];
            messageLabelHeight += rect.size.height;
            messageLabelWidth =  rect.size.width > messageLabelWidth ? rect.size.width : messageLabelWidth;
        }];
    }
    else if (attributedText) {
        CGRect rect = [attributedText boundingRectWithSize:CGSizeMake(maxWidth, MAXFLOAT) options:NSStringDrawingUsesFontLeading |NSStringDrawingUsesLineFragmentOrigin context:nil];
        messageLabelHeight = rect.size.height;
        messageLabelWidth = rect.size.width > messageLabelWidth ? rect.size.width : messageLabelWidth;
    }
    return CGSizeMake(ceil(messageLabelWidth), ceil(messageLabelHeight));
}

- (CGSize)bjlsc_oneRowSizeWithText:(nullable NSString *)text attributedText:(nullable NSAttributedString *)attributedText fontSize:(CGFloat)fontSize {
    __block CGFloat messageLabelHeight = 0.0;
    __block CGFloat messageLabelWidth = 0.0;
    if (text) {
        CGRect rect = [text boundingRectWithSize:CGSizeMake(MAXFLOAT, fontSize) options:NSStringDrawingUsesFontLeading |NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]} context:nil];
        messageLabelWidth = rect.size.width;
        messageLabelHeight = rect.size.height;
    }
    else if (attributedText) {
        CGRect rect = [attributedText boundingRectWithSize:CGSizeMake(MAXFLOAT, fontSize) options:NSStringDrawingUsesFontLeading |NSStringDrawingUsesLineFragmentOrigin context:nil];
        messageLabelWidth = rect.size.width;
        messageLabelHeight = rect.size.height;
    }
    return CGSizeMake(ceil(messageLabelWidth), ceil(messageLabelHeight));
}

@end

#pragma mark -

@implementation UIImage (BJLSurfaceClass)

+ (UIImage *)bjlsc_imageNamed:(NSString *)name {
    static NSString * const bundleName = @"BJLSurfaceClass", * const bundleType = @"bundle";
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *classBundle = [NSBundle bundleForClass:[BJLScRoomViewController class]];
        NSString *bundlePath = [classBundle pathForResource:bundleName ofType:bundleType];
        bundle = [NSBundle bundleWithPath:bundlePath];
    });
    return [self imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
}

@end


@implementation UIView (BJLSurfaceClass)

- (void)bjlsc_drawRectCorners:(UIRectCorner)coners radius:(CGFloat)radius backgroundColor:(UIColor *)color size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef contextRef =  UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(contextRef, 1.0);
    CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
    CGContextSetFillColorWithColor(contextRef, color.CGColor);
    
    CGFloat width = size.width;
    CGFloat height = size.height;
    
    CGContextMoveToPoint(contextRef, 0, 0);
    if (coners & UIRectCornerTopRight) {
        CGContextAddArcToPoint(contextRef, width, 0, width, height, radius);  // 右上角
    }
    else {
        CGContextAddLineToPoint(contextRef, width, 0);
    }
    if (coners & UIRectCornerBottomRight) {
        CGContextAddArcToPoint(contextRef, width, height, 0, height, radius); // 右下角
    }
    else {
        CGContextAddLineToPoint(contextRef, width, height);
    }
    if (coners & UIRectCornerBottomLeft) {
        CGContextAddArcToPoint(contextRef, 0, height, 0, 0, radius); // 左下角
    }
    else {
        CGContextAddLineToPoint(contextRef, 0, height);
    }
    if (coners & UIRectCornerTopLeft) {
        CGContextAddArcToPoint(contextRef, 0, 0, width, 0, radius); // 左上角
    }
    else {
        CGContextAddLineToPoint(contextRef, 0, 0);
    }
    CGContextDrawPath(contextRef, kCGPathFillStroke);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.layer.contents = (__bridge id _Nullable)(image.CGImage);
}

- (void)bjlsc_removeCorners {
    self.layer.contents = nil;
}

- (CAShapeLayer *)bjlsc_backgroundLayer {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setBjlsc_backgroundLayer:(nullable CAShapeLayer *)backgroundLayer {
    objc_setAssociatedObject(self, @selector(bjlsc_backgroundLayer), backgroundLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CAShapeLayer *)bjlsc_drawBackgroundViewWithColor:(nullable UIColor *)color rect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius hidden:(BOOL)hidden {
    if (hidden) {
        self.bjlsc_backgroundLayer.hidden = hidden;
        return self.bjlsc_backgroundLayer;
    }
    if (self.bjlsc_backgroundLayer && self.bjlsc_backgroundLayer.superlayer) {
        [self.bjlsc_backgroundLayer removeFromSuperlayer];
        self.bjlsc_backgroundLayer = nil;
    }
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
    shapeLayer.frame = self.bounds;
    shapeLayer.fillColor = color.CGColor;
    shapeLayer.path = path.CGPath;
    [self.layer insertSublayer:shapeLayer atIndex:0];
    self.bjlsc_backgroundLayer = shapeLayer;
    return shapeLayer;
}

- (void)bjlsc_drawRectCorners:(UIRectCorner)coners cornerRadii:(CGSize)cornerRadii {
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:coners cornerRadii:cornerRadii];
    shapeLayer.frame = self.bounds;
    shapeLayer.path = path.CGPath;
    self.layer.mask = shapeLayer;
}

@end

#pragma mark - button

@implementation BJLScImageButton

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    CGFloat xOffset = (self.bounds.size.width - self.backgroundSize.width) / 2.0;
    CGFloat yOffset = (self.bounds.size.height - self.backgroundSize.height) / 2.0;
    CGRect rect = CGRectMake(xOffset, yOffset, self.backgroundSize.width, self.backgroundSize.height);
    if (selected) {
        [self bjlsc_drawBackgroundViewWithColor:self.selectedColor rect:rect cornerRadius:self.backgroundCornerRadius hidden:self.selectedColor ? NO : YES];
    }
    if (!selected) {
        [self bjlsc_drawBackgroundViewWithColor:self.normalColor rect:rect cornerRadius:self.backgroundCornerRadius hidden:self.normalColor ? NO : YES];
    }
}
  
@end

#pragma mark -

@implementation UIButton (BJLButtons)

+ (instancetype)makeTextButtonDestructive:(BOOL)destructive {
    UIButton *button = [self new];
    UIColor *titleColor = destructive ? [UIColor bjlsc_redColor] : [UIColor bjlsc_blueBrandColor];
    [button setTitleColor:titleColor forState:UIControlStateNormal];
    [button setTitleColor:[titleColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    button.titleLabel.font = [UIFont systemFontOfSize:15.0];
    return button;
}

+ (instancetype)makeRoundedRectButtonHighlighted:(BOOL)highlighted {
    UIButton *button = [self new];
    button.titleLabel.font = [UIFont systemFontOfSize:14.0];
    if (highlighted) {
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor bjlsc_blueBrandColor];
    }
    else {
        [button setTitleColor:[UIColor bjlsc_grayTextColor] forState:UIControlStateNormal];
        button.layer.borderWidth = BJLScOnePixel;
        button.layer.borderColor = [UIColor bjlsc_grayBorderColor].CGColor;
    }
    button.layer.cornerRadius = BJLScButtonCornerRadius;
    button.layer.masksToBounds = YES;
    return button;
}

@end

