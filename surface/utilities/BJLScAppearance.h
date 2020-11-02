//
//  BJLScAppearance.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLViewControllerImports.h"

NS_ASSUME_NONNULL_BEGIN

#define BJLScOnePixel ({ \
static CGFloat _BJLScOnePixel; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_BJLScOnePixel = 1.0 / [UIScreen mainScreen].scale; \
}); \
_BJLScOnePixel; \
})

#define BJLScViewSpaceS   5.0
#define BJLScViewSpaceM   10.0
#define BJLScViewSpaceL   15.0

#define BJLScControlSize  44.0

#define BJLScButtonSizeS  30.0
#define BJLScButtonSizeM  36.0
#define BJLScButtonSizeL  46.0
#define BJLScButtonCornerRadius 3.0
#define BJLScRedDotWidth 18.0
#define BJLScMessageOperatorButtonSize 32.0

#define BJLScBadgeSize    20.0
#define BJLScScrollIndicatorSize 8.5 // 8.5 = 2.5 + 3.0 * 2

#define BJLScAnimateDurationS 0.2
#define BJLScAnimateDurationM 0.4
#define BJLScRobotDelayS  1.0
#define BJLScRobotDelayM  2.0
#define BJLScRainDelay 3.0

#define BJLScTopBarHeight 32.0
#define BJLScSegmentWidth 240.0

#define BJLScOverlayImageMinSize 32.0
#define BJLScOverlayImageMaxSize 480.0

#define userWindowDefaultBarHeight 24.0
#define blackboardAspectRatio 4.0/3.0

#define answerOptionButtonHeight 40.0
#define BJLScUserOperateViewButtonHeight 50.0

// toolView
#define BJLScToolViewWidth ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 24.0 : 44.0)
#define BJLScToolViewButtonWidth ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 22.0 : 32.0)
#define BJLScToolViewButtonSpace 4.0
#define BJLScToolViewCornerRadius 2.0
#define BJLScToolViewColorLength (BJLScToolViewButtonWidth * 0.75)
#define BJLScToolViewColorSize ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 2.0 : 4.0)
#define BJLScToolViewDrawOffset 4.0
#define BJLScToolViewDrawSpace 6.0
#define BJLScToolViewDrawButtonSize 32.0
#define BJLScToolViewFontIconSize 20.0
#define BJLScToolViewDrawFontSize 24.0

typedef NS_OPTIONS(NSInteger, BJLScRectPosition) {
    BJLScRectPosition_top       = 1 << 0,
    BJLScRectPosition_bottom    = 1 << 1,
    BJLScRectPosition_left      = 1 << 2,
    BJLScRectPosition_right     = 1 << 3,
    BJLScRectPosition_all       = (1 << 4) - 1
};

// isNotchScreen
static inline BOOL bjlsc_iPhoneXSeries() {
    if (@available(iOS 11.0, *)) {
        static const CGFloat insetsLimit = 20.0;
        UIEdgeInsets insets = UIWindow.bjl_keyWindow.safeAreaInsets;
        return (insets.top > insetsLimit
                || insets.left > insetsLimit
                || insets.right > insetsLimit
                || insets.bottom > insetsLimit);
    }
    return NO;
}

#pragma mark -

/** 窗口类型 */
typedef NS_ENUM(NSInteger, BJLScWindowType) {
    BJLScWindowType_none,                   // 空类型
    BJLScWindowType_ppt,                    // ppt窗口 或 老师辅助摄像头窗口，需要根据是否存在辅助摄像头视图来决定
    BJLScWindowType_userVideo,              // 除老师外的窗口
    BJLScWindowType_teacherVideo,           // 老师窗口
};

/** 窗口所在的位置的类型 */
typedef NS_ENUM(NSInteger, BJLScPositionType) {
    BJLScPositionType_none,                  // 空类型
    BJLScPositionType_major,                 // 主视图窗口
    BJLScPositionType_minor,                 // 老师窗口
    BJLScPositionType_videoList,             // 视频列表区域
    BJLScPositionType_secondMinor,           // 第二个次要的窗口，目前仅用于 1v1
};

#pragma mark -

@interface UIColor (BJLSurfaceClass)

// common
@property (class, nonatomic, readonly) UIColor
*bjlsc_darkGrayBackgroundColor,
*bjlsc_lightGrayBackgroundColor,

*bjlsc_darkGrayTextColor,
*bjlsc_grayTextColor,
*bjlsc_lightGrayTextColor,

*bjlsc_grayBorderColor,
*bjlsc_grayLineColor,
*bjlsc_grayImagePlaceholderColor, // == bjlsc_grayLineColor

*bjlsc_blueBrandColor,
*bjlsc_orangeBrandColor,
*bjlsc_redColor;

// dim
@property (class, nonatomic, readonly) UIColor
*bjlsc_lightDimColor, // black-0.2
*bjlsc_dimColor,      // black-0.5
*bjlsc_darkDimColor;  // black-0.6

@end

#pragma mark - NSObject

@interface NSObject (BJLSurfaceClass)

/// 根据文本和尺寸限制获取预期的尺寸，目前仅用于计算文本的高度来决定是否完全显示文本，布局使用系统控件的自适应布局
/// #param text text description
/// #param attributedText attributedText description
/// #param maxWidth maxWidth
- (CGSize)bjlsc_suitableSizeWithText:(nullable NSString *)text attributedText:(nullable NSAttributedString *)attributedText maxWidth:(CGFloat)maxWidth;

- (CGSize)bjlsc_oneRowSizeWithText:(nullable NSString *)text attributedText:(nullable NSAttributedString *)attributedText fontSize:(CGFloat)fontSize;

@end

#pragma mark -

@interface UIImage (BJLSurfaceClass)

+ (UIImage *)bjlsc_imageNamed:(NSString *)name;

@end

@interface UIView (BJLSurfaceClass)

- (void)bjlsc_drawRectCorners:(UIRectCorner)coners radius:(CGFloat)radius backgroundColor:(UIColor *)color size:(CGSize)size;
- (void)bjlsc_removeCorners;
- (CAShapeLayer *)bjlsc_drawBackgroundViewWithColor:(nullable UIColor *)color rect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius hidden:(BOOL)hidden;
/**
 绘制圆角

 #param coners UIRectCornerTopLeft | UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight | UIRectCornerAllCorners
 #param cornerRadii cornerRadii
 #discussion must draw after set the view size
 */
- (void)bjlsc_drawRectCorners:(UIRectCorner)coners cornerRadii:(CGSize)cornerRadii;

@end

#pragma mark - button

@interface BJLScImageButton : BJLImageButton

// 通常态背景色
@property (nonatomic) UIColor *normalColor;
// 选中态背景色
@property (nonatomic) UIColor *selectedColor;
// 背景色大小，默认居中显示
@property (nonatomic) CGSize backgroundSize;
// 背景色圆角值
@property (nonatomic) CGFloat backgroundCornerRadius;

@end

@interface UIButton (BJLButtons)

+ (instancetype)makeTextButtonDestructive:(BOOL)destructive;
+ (instancetype)makeRoundedRectButtonHighlighted:(BOOL)highlighted;

@end

NS_ASSUME_NONNULL_END
