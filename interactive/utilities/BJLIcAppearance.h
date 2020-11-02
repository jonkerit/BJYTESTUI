//
//  BJLIcAppearance.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcTheme.h"

typedef NS_ENUM(NSInteger, BJLIcVideoPosition) {
    BJLIcVideoPosition_none = 0,
    // 板书布局座位区
    BJLIcVideoPosition_videoList = 1,
    // 板书布局黑板区域
    BJLIcVideoPosition_blackboard = 2,
    // 画廊布局区域
    BJLIcVideoPosition_gallary = 3
};

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcAppearance : NSObject

+ (instancetype)sharedAppearanceWithTemplateType:(BJLIcTemplateType)type videoDefinition:(BJLVideoDefinition)videoDefinition;
+ (void)destroy;

// layout
@property (class, nonatomic, readonly) CGFloat layoutWidth;
@property (class, nonatomic, readonly) CGFloat layoutHeight;
@property (class, nonatomic, readonly) CGFloat layoutRatio;
@property (class, nonatomic, readonly) CGFloat layoutCornerRadius;
@property (class, nonatomic, readonly) CGFloat widgetWidthFraction;
@property (class, nonatomic, readonly) CGFloat buttonSize;

// blackboard
@property (class, nonatomic, readonly) CGFloat blackboardAspectRatio;
@property (class, nonatomic, readonly) CGFloat blackboardHeightFraction;
@property (class, nonatomic, readonly) CGFloat blackboardWidthFraction;

// video
@property (class, nonatomic, readonly) CGFloat videoAspectRatio;
@property (class, nonatomic, readonly) NSInteger fullSizedVideosCount;
@property (class, nonatomic, readonly) CGFloat videosHeightFraction;
@property (class, nonatomic, readonly) CGFloat videosWidthFraction;


// statusbar
@property (class, nonatomic, readonly) CGFloat statusBarHeightFraction;
@property (class, nonatomic, readonly) CGFloat statusBarHeight;
@property (class, nonatomic, readonly) CGFloat statusBarButtonSize;
@property (class, nonatomic, readonly) CGFloat statusBarSpace;

// livestart
@property (class, nonatomic, readonly) CGFloat liveStartButtonWidth;
@property (class, nonatomic, readonly) CGFloat liveStartButtonHeight;
@property (class, nonatomic, readonly) CGFloat liveStartViewSpace;

// popover
@property (class, nonatomic, readonly) CGFloat popoverViewWidth;
@property (class, nonatomic, readonly) CGFloat popoverViewHeight;
@property (class, nonatomic, readonly) CGFloat popoverImageSize;
@property (class, nonatomic, readonly) CGFloat popoverViewSpace;

// prompt
@property (class, nonatomic, readonly) CGFloat promptCellHeiht;
@property (class, nonatomic, readonly) CGFloat promptCellSmallSpace;
@property (class, nonatomic, readonly) CGFloat promptCellLargeSpace;
@property (class, nonatomic, readonly) NSInteger promptDuration;
@property (class, nonatomic, readonly) NSInteger promptCellMaxCount;
@property (class, nonatomic, readonly) CGFloat promptViewHeight;

// toolbox
@property (class, nonatomic, readonly) CGFloat toolboxHeightFraction;
@property (class, nonatomic, readonly) CGFloat toolboxWidth;
@property (class, nonatomic, readonly) CGFloat toolboxOffset;
@property (class, nonatomic, readonly) CGFloat toolboxButtonSize;
@property (class, nonatomic, readonly) CGFloat toolboxButtonSpace;
@property (class, nonatomic, readonly) CGFloat toolboxLineLength; // 分割线长度
@property (class, nonatomic, readonly) CGFloat toolboxButtonImageInset;
@property (class, nonatomic, readonly) CGFloat toolboxColorSize;
@property (class, nonatomic, readonly) CGFloat toolboxColorLength;
@property (class, nonatomic, readonly) CGFloat toolboxCornerRadius;
@property (class, nonatomic, readonly) CGFloat toolboxDrawSpace;
@property (class, nonatomic, readonly) CGFloat toolboxDrawButtonSize;
@property (class, nonatomic, readonly) CGFloat toolboxDrawFontIconSize;
@property (class, nonatomic, readonly) CGFloat toolboxDrawFontSize;

// document
@property (class, nonatomic, readonly) CGFloat documentFileCellWidth;
@property (class, nonatomic, readonly) CGFloat documentFileCellHeight;
@property (class, nonatomic, readonly) CGFloat documentFileCellImageSize;
@property (class, nonatomic, readonly) CGFloat documentFileDisplayListWidth;

// toolbar
@property (class, nonatomic, readonly) CGFloat toolbarHeightFraction;
@property (class, nonatomic, readonly) CGFloat toolbarWidth;
@property (class, nonatomic, readonly) CGFloat toolbarOffset;
@property (class, nonatomic, readonly) CGFloat toolbarButtonWidth; // 用于 ipad 右侧有可能存在文字的按钮尺寸，包括边框间隔大小，作为点击热区
@property (class, nonatomic, readonly) CGFloat toolbarButtonSize; // 用于 ipad 左侧按钮尺寸或者手机按钮显示，一般为图片视觉大小
@property (class, nonatomic, readonly) CGFloat toolbarLineLength; // 分割线长度
@property (class, nonatomic, readonly) CGFloat toolbarRedDotSize; // 无数量显示的红点使用的尺寸
@property (class, nonatomic, readonly) CGFloat toolbarRedLabelSize; // 有数量显示的红点使用的尺寸
@property (class, nonatomic, readonly) CGFloat toolbarButtonImageInset;
@property (class, nonatomic, readonly) CGFloat toolbarCornerRadius;
@property (class, nonatomic, readonly) CGFloat toolbarButtonSpace;
@property (class, nonatomic, readonly) CGFloat toolbarLargeSpace;
@property (class, nonatomic, readonly) CGFloat toolbarMediumSpace;
@property (class, nonatomic, readonly) CGFloat toolbarSmallSpace;

// speakrequest
@property (class, nonatomic, readonly) CGFloat speakRequestButtonWidth;

// writingBorad
@property (class, nonatomic, readonly) CGFloat writingBoradToolbarButtonWidth;
@property (class, nonatomic, readonly) CGFloat writingBoradToolbarLargeSpace;
@property (class, nonatomic, readonly) CGFloat writingBoradToolbarSmallSpace;
@property (class, nonatomic, readonly) CGFloat questionAnswerOptionButtonWidth;
@property (class, nonatomic, readonly) CGFloat questionAnswerOptionButtonHeight;

// chat list
@property (class, nonatomic, readonly) CGFloat chatViewLargeSpace;
@property (class, nonatomic, readonly) CGFloat chatViewMediumSpace;
@property (class, nonatomic, readonly) CGFloat chatViewSmallSpace;
@property (class, nonatomic, readonly) CGFloat chatCellMaxWidth;
@property (class, nonatomic, readonly) CGFloat chatCellMaxTextHeight;
@property (class, nonatomic, readonly) CGFloat chatCellMinTextHeight;
@property (class, nonatomic, readonly) CGFloat chatCellMinUserInOutTextHeight;
@property (class, nonatomic, readonly) CGFloat chatCellMinTextWidth;
@property (class, nonatomic, readonly) CGFloat chatCellMaxImageHeight;

// user list view
@property (class, nonatomic, readonly) CGFloat userViewMaxSpace;
@property (class, nonatomic, readonly) CGFloat userViewLargeSpace;
@property (class, nonatomic, readonly) CGFloat userViewMediumSpace;
@property (class, nonatomic, readonly) CGFloat userViewSmallSpace;
@property (class, nonatomic, readonly) CGFloat userTableViewCellHeight;
@property (class, nonatomic, readonly) CGFloat userViewIpadHeightFraction;
@property (class, nonatomic, readonly) CGFloat userViewIpadWidthFraction;
@property (class, nonatomic, readonly) CGFloat userCellAvatarSize;
@property (class, nonatomic, readonly) CGFloat userCellButtonSize;
@property (class, nonatomic, readonly) CGFloat userOptionViewHeight;
@property (class, nonatomic, readonly) CGFloat userWindowDefaultBarHeight;
@property (class, nonatomic, readonly) CGFloat userHeaderTitleWidth;

@property (class, nonatomic, readonly) CGFloat robotDelayS;
@property (class, nonatomic, readonly) CGFloat robotDelayM;
@property (class, nonatomic, readonly) NSInteger maxReloadTimes;
@property (class, nonatomic, readonly) CGFloat userVideoPlaceholderImageMaxWidth;
@property (class, nonatomic, readonly) CGFloat userVideoPlaceholderImageMinWidth;

@end

#pragma mark -

typedef NS_ENUM(NSInteger, BJLIcColorType) {
    BJLIcColorType_normal,
    BJLIcColorType_lightBlue,
    BJLIcColorType_blue,
    BJLIcColorType_deepBlue,
    BJLIcColorType_black,
    BJLIcColorType_grey,
    BJLIcColorType_white,
    BJLIcColorType_lightRed,
    BJLIcColorType_red,
    BJLIcColorType_deepRed,
    BJLIcColorType_lightGreen,
    BJLIcColorType_green,
    BJLIcColorType_deepGreen,
    BJLIcColorType_lightOrange,
    BJLIcColorType_orange,
    BJLIcColorType_deepOrange
};

@interface UIColor (BJLInteractiveClass)

// networkloss
@property (class, nonatomic, readonly) UIColor
*bjl_ic_quiteBadNetColor,
*bjl_ic_extremelyBadNetColor;

@end

#pragma mark - NSObject

@interface NSObject (BJLInteractiveClass)

/// 根据文本和尺寸限制获取预期的尺寸，目前仅用于计算文本的高度来决定是否完全显示文本，布局使用系统控件的自适应布局
/// #param text text description
/// #param attributedText attributedText description
/// #param maxWidth maxWidth
- (CGSize)bjlic_suitableSizeWithText:(nullable NSString *)text attributedText:(nullable NSAttributedString *)attributedText maxWidth:(CGFloat)maxWidth;

@end

#pragma mark - UIImage

@interface UIImage (BJLInteractiveClass)

/**
 获取image

 #param name image name
 #return image
 */
+ (UIImage *)bjlic_imageNamed:(NSString *)name;

@end

#pragma mark - button

@interface BJLIcImageButton : BJLImageButton

// 通常态背景色
@property (nonatomic) UIColor *normalColor;
// 选中态背景色
@property (nonatomic) UIColor *selectedColor;
// 背景色大小，默认居中显示
@property (nonatomic) CGSize backgroundSize;
// 背景色圆角值
@property (nonatomic) CGFloat backgroundCornerRadius;

@end

typedef NS_OPTIONS(NSInteger, BJLIcRectPosition) {
    BJLIcRectPosition_top       = 1 << 0,
    BJLIcRectPosition_bottom    = 1 << 1,
    BJLIcRectPosition_left      = 1 << 2,
    BJLIcRectPosition_right     = 1 << 3,
    BJLIcRectPosition_all       = (1 << 4) - 1
};

#pragma mark - UIView

@interface UIView (BJLInteractiveClass)

/**
 绘制内阴影，绘制新的内阴影时会自动移除上一个内阴影

 #param alpha alpha
 #param cornerRadius cornerRadius
 #return layer
 #discussion no offset, must draw after set the view size
 */
- (CAShapeLayer *)bjlic_drawInnerShadowAlpha:(CGFloat)alpha cornerRadius:(CGFloat)cornerRadius;

/**
 绘制圆角

 #param coners UIRectCornerTopLeft | UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight | UIRectCornerAllCorners
 #param cornerRadii cornerRadii
 #discussion must draw after set the view size
 */
- (void)bjlic_drawRectCorners:(UIRectCorner)coners cornerRadii:(CGSize)cornerRadii;

/**
 绘制边框，绘制新的边框的时候会自动移除上一个边框
 
 #param borderWidth borderWidth
 #param borderColor borderColor
 #param coners coners
 #param cornerRadii cornerRadii
 #return layer
 */
- (CAShapeLayer *)bjlic_drawBorderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor corners:(UIRectCorner)coners cornerRadii:(CGSize)cornerRadii;

/**
 绘制边框，绘制新的边框的时候会自动移除上一个边框

 #param borderWidth borderWidth
 #param borderColor borderColor
 #param position BJLIcRectPosition
 #return layer
 */
- (CAShapeLayer *)bjlic_drawBorderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor position:(BJLIcRectPosition)position;

/**
 绘制圆形背景
 
 #param color 背景色
 #param hidden 隐藏背景时，不关注背景色的值
 #return layer
 */
- (CAShapeLayer *)bjlic_drawCircleBackgroundViewWithColor:(nullable UIColor *)color hidden:(BOOL)hidden;
- (CAShapeLayer *)bjlic_drawBackgroundViewWithColor:(nullable UIColor *)color rect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius hidden:(BOOL)hidden;

/// 通用分割线, 色值: #9FA8B5, 0.1透明度
+ (UIView *)bjlic_createSeparateLine;

@end

NS_ASSUME_NONNULL_END
