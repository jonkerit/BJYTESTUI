//
//  BJLIcAppearance.m
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <objc/runtime.h>

#import "BJLIcAppearance.h"
#import "BJLIcRoomViewController.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -

@interface BJLIcAppearance ()

// layout
@property (nonatomic) CGFloat layoutWidth;
@property (nonatomic) CGFloat layoutHeight;
@property (nonatomic) CGFloat layoutRatio;
@property (nonatomic) CGFloat layoutCornerRadius;
@property (nonatomic) CGFloat widgetWidthFraction;
@property (nonatomic) CGFloat buttonSize;

// blackboard
@property (nonatomic) CGFloat blackboardAspectRatio;
@property (nonatomic) CGFloat blackboardHeightFraction;
@property (nonatomic) CGFloat blackboardWidthFraction;

// video
@property (nonatomic) CGFloat videoAspectRatio;
@property (nonatomic) NSInteger fullSizedVideosCount;
@property (nonatomic) CGFloat videosHeightFraction;
@property (nonatomic) CGFloat videosWidthFraction;


// statusbar
@property (nonatomic) CGFloat statusBarHeightFraction;
@property (nonatomic) CGFloat statusBarHeight;
@property (nonatomic) CGFloat statusBarButtonSize;
@property (nonatomic) CGFloat statusBarSpace;

// livestart
@property (nonatomic) CGFloat liveStartButtonWidth;
@property (nonatomic) CGFloat liveStartButtonHeight;
@property (nonatomic) CGFloat liveStartViewSpace;

// popover
@property (nonatomic) CGFloat popoverViewWidth;
@property (nonatomic) CGFloat popoverViewHeight;
@property (nonatomic) CGFloat popoverImageSize;
@property (nonatomic) CGFloat popoverViewSpace;

// prompt
@property (nonatomic) CGFloat promptCellHeiht;
@property (nonatomic) CGFloat promptCellSmallSpace;
@property (nonatomic) CGFloat promptCellLargeSpace;
@property (nonatomic) NSInteger promptDuration;
@property (nonatomic) NSInteger promptCellMaxCount;
@property (nonatomic) CGFloat promptViewHeight;

// toolbox
@property (nonatomic) CGFloat toolboxHeightFraction;
@property (nonatomic) CGFloat toolboxWidth;
@property (nonatomic) CGFloat toolboxOffset;
@property (nonatomic) CGFloat toolboxButtonSize;
@property (nonatomic) CGFloat toolboxButtonSpace;
@property (nonatomic) CGFloat toolboxLineLength; // 分割线长度
@property (nonatomic) CGFloat toolboxButtonImageInset;
@property (nonatomic) CGFloat toolboxColorSize;
@property (nonatomic) CGFloat toolboxColorLength;
@property (nonatomic) CGFloat toolboxCornerRadius;
@property (nonatomic) CGFloat toolboxDrawSpace;
@property (nonatomic) CGFloat toolboxDrawButtonSize;
@property (nonatomic) CGFloat toolboxDrawFontIconSize;
@property (nonatomic) CGFloat toolboxDrawFontSize;

// document
@property (nonatomic) CGFloat documentFileCellWidth;
@property (nonatomic) CGFloat documentFileCellHeight;
@property (nonatomic) CGFloat documentFileCellImageSize;
@property (nonatomic) CGFloat documentFileDisplayListWidth;

// toolbar
@property (nonatomic) CGFloat toolbarHeightFraction;
@property (nonatomic) CGFloat toolbarWidth;
@property (nonatomic) CGFloat toolbarOffset;
@property (nonatomic) CGFloat toolbarButtonWidth; // 用于 ipad 右侧有可能存在文字的按钮尺寸，包括边框间隔大小，作为点击热区
@property (nonatomic) CGFloat toolbarButtonSize; // 用于 ipad 左侧按钮尺寸或者手机按钮显示，一般为图片视觉大小
@property (nonatomic) CGFloat toolbarLineLength; // 分割线长度
@property (nonatomic) CGFloat toolbarRedDotSize; // 无数量显示的红点使用的尺寸
@property (nonatomic) CGFloat toolbarRedLabelSize; // 有数量显示的红点使用的尺寸
@property (nonatomic) CGFloat toolbarButtonImageInset;
@property (nonatomic) CGFloat toolbarCornerRadius;
@property (nonatomic) CGFloat toolbarButtonSpace;
@property (nonatomic) CGFloat toolbarLargeSpace;
@property (nonatomic) CGFloat toolbarMediumSpace;
@property (nonatomic) CGFloat toolbarSmallSpace;

// speakrequest
@property (nonatomic) CGFloat speakRequestButtonWidth;

// writingBorad
@property (nonatomic) CGFloat writingBoradToolbarButtonWidth;
@property (nonatomic) CGFloat writingBoradToolbarLargeSpace;
@property (nonatomic) CGFloat writingBoradToolbarSmallSpace;
@property (nonatomic) CGFloat questionAnswerOptionButtonWidth;
@property (nonatomic) CGFloat questionAnswerOptionButtonHeight;

// chat list
@property (nonatomic) CGFloat chatViewLargeSpace;
@property (nonatomic) CGFloat chatViewMediumSpace;
@property (nonatomic) CGFloat chatViewSmallSpace;
@property (nonatomic) CGFloat chatCellMaxWidth;
@property (nonatomic) CGFloat chatCellMaxTextHeight;
@property (nonatomic) CGFloat chatCellMinTextHeight;
@property (nonatomic) CGFloat chatCellMinUserInOutTextHeight;
@property (nonatomic) CGFloat chatCellMinTextWidth;
@property (nonatomic) CGFloat chatCellMaxImageHeight;

// user list view
@property (nonatomic) CGFloat userViewMaxSpace;
@property (nonatomic) CGFloat userViewLargeSpace;
@property (nonatomic) CGFloat userViewMediumSpace;
@property (nonatomic) CGFloat userViewSmallSpace;
@property (nonatomic) CGFloat userTableViewCellHeight;
@property (nonatomic) CGFloat userViewIpadHeightFraction;
@property (nonatomic) CGFloat userViewIpadWidthFraction;
@property (nonatomic) CGFloat userCellAvatarSize;
@property (nonatomic) CGFloat userCellButtonSize;
@property (nonatomic) CGFloat userOptionViewHeight;
@property (nonatomic) CGFloat userWindowDefaultBarHeight;
@property (nonatomic) CGFloat userHeaderTitleWidth;

@property (nonatomic) CGFloat robotDelayS;
@property (nonatomic) CGFloat robotDelayM;
@property (nonatomic) NSInteger maxReloadTimes;
@property (nonatomic) CGFloat userVideoPlaceholderImageMaxWidth;
@property (nonatomic) CGFloat userVideoPlaceholderImageMinWidth;

@end

@implementation BJLIcAppearance

static BJLIcAppearance * _Nullable sharedInstance = nil;

+ (instancetype)sharedAppearanceWithTemplateType:(BJLIcTemplateType)type videoDefinition:(BJLVideoDefinition)videoDefinition {
    sharedInstance = [[BJLIcAppearance alloc] initWithTemplateType:type videoDefinition:videoDefinition];
    return sharedInstance;
}

+ (void)destroy {
    sharedInstance = nil;
}

- (instancetype)init {
    return [self initWithTemplateType:BJLIcTemplateType_userVideoUpside videoDefinition:BJLVideoDefinition_default];
}

- (instancetype)initWithTemplateType:(BJLIcTemplateType)type videoDefinition:(BJLVideoDefinition)videoDefinition {
    if (self = [super init]) {
        BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
        
        // BJLIcTemplateType_1v1
        
        if (type == BJLIcTemplateType_1v1) {
            self.layoutWidth = 16.0;
            self.layoutHeight = iPhone ? 9.0 : 12.0;
            self.layoutRatio = self.layoutWidth / self.layoutHeight;
            self.blackboardAspectRatio = 4.0 / 3.0;
            self.blackboardWidthFraction = 12.0 / self.layoutWidth;
            self.videosWidthFraction = 4.0 / self.layoutWidth;
            self.toolboxHeightFraction = 1.5 / self.layoutHeight;
            self.statusBarHeight = 24.0;
            self.statusBarButtonSize = 24.0;
            self.toolbarWidth = 44.0;
            self.toolbarButtonWidth = iPhone ? 24.0 : 44.0;
        }
        
        // BJLIcTemplateType_userVideoUpside
        
        else {
            self.layoutWidth = 16.0;
            self.layoutHeight = iPhone ? 10.0 : 12.0;
            self.layoutRatio = self.layoutWidth / self.layoutHeight;
            self.blackboardAspectRatio = 2.0 / 1;
            self.blackboardHeightFraction = self.layoutRatio * self.blackboardAspectRatio;
            self.statusBarHeightFraction = iPhone ? 0.5 / self.layoutHeight : 0.75 / self.layoutHeight;
            self.videosHeightFraction = 1.5 / self.layoutHeight;
            self.toolbarHeightFraction = iPhone ? 1.0 / self.layoutHeight : 1.75 / self.layoutHeight;
            self.toolbarButtonWidth = iPhone ? 24.0 : 64.0;
            self.statusBarButtonSize = iPhone ? 24.0 : 44.0;
        }
        
        // common
        self.widgetWidthFraction = 5.0 / self.layoutWidth;
        [self updateVideoAspectRatioWithVideoDefinition:videoDefinition];

        self.buttonSize = 44.0;
        self.layoutCornerRadius = 4.0;
        
        // statusbar
        self.statusBarSpace = 12.0;
        
        // toolbox
        self.toolboxWidth = iPhone ? 24.0 : 44.0;
        self.toolboxButtonSize = iPhone ? 18.0 : 32.0;
        self.toolboxButtonSpace = iPhone ? 6.0 : 8.0;
        self.toolboxCornerRadius = iPhone ? 2.0 : 4.0;
        self.toolboxLineLength = self.toolboxWidth * 2.0 / 3.0;
        self.toolboxButtonImageInset = iPhone ? (self.toolboxWidth - self.toolboxButtonSize) / 2.0 : 0;
        self.toolboxOffset = 4.0;
        self.toolboxColorSize = 3.0;
        self.toolboxColorLength = self.toolboxButtonSize * 0.75;
        self.toolboxDrawSpace = 6.0;
        self.toolboxDrawButtonSize = 32.0;
        self.toolboxDrawFontIconSize = 20.0;
        self.toolboxDrawFontSize = 24.0;
        
        // toolbar
        self.toolbarButtonSize = iPhone ? 20.0 : 48.0;
        self.toolbarButtonSpace = iPhone ? 14.0 : 32.0;
        self.toolbarLineLength = self.toolbarButtonWidth * 2.0 / 3.0;
        self.toolbarCornerRadius = iPhone ? 4.0 : 8.0;
        self.toolbarRedDotSize = 8.0;
        self.toolbarRedLabelSize = iPhone ? 8.0 : 16.0;
        self.toolbarButtonImageInset = iPhone ? (self.toolbarButtonWidth - self.toolbarButtonSize) / 2.0 : 0;
        self.toolbarOffset = 4.0;
        self.toolbarLargeSpace = 40.0;
        self.toolbarMediumSpace = 20.0;
        self.toolbarSmallSpace = 10.0;
        
        self.speakRequestButtonWidth = iPhone ? 48.0 : 64.0;

        self.liveStartButtonWidth = 243.0;
        self.liveStartButtonHeight = 54.0;
        self.liveStartViewSpace = 14.0;
        
        self.popoverViewWidth = 422.0;
        self.popoverViewHeight = 216.0;
        self.popoverImageSize = 24.0;
        self.popoverViewSpace = 20.0;
        self.promptCellHeiht = 42.0;
        self.promptCellSmallSpace = 6.0;
        self.promptCellLargeSpace = 12.0;
        self.promptDuration = 3;
        self.promptCellMaxCount = 3;
        self.promptViewHeight = 138.0;
        
        self.documentFileCellWidth = 96.0;
        self.documentFileCellHeight = 106.0;
        self.documentFileCellImageSize = 64.0;
        self.documentFileDisplayListWidth = 142.0;
        
        self.writingBoradToolbarButtonWidth = 80.0;
        self.writingBoradToolbarLargeSpace = 40.0;
        self.writingBoradToolbarSmallSpace = 10.0;
        self.questionAnswerOptionButtonWidth = 34.0;
        self.questionAnswerOptionButtonHeight = 37.0;
        
        self.chatViewLargeSpace = 12.0;
        self.chatViewMediumSpace = 10.0;
        self.chatViewSmallSpace = 6.0;
        self.chatCellMaxWidth = 220.0;
        self.chatCellMaxTextHeight = 256.0;
        self.chatCellMinTextHeight = 40.0;
        self.chatCellMinUserInOutTextHeight = 26;
        self.chatCellMinTextWidth = 36.0;
        self.chatCellMaxImageHeight = 165.0;
        
        self.userViewMaxSpace = 16.0;
        self.userViewLargeSpace = 12.0;
        self.userViewMediumSpace = 10.0;
        self.userViewSmallSpace = 6.0;
        self.userTableViewCellHeight = 40.0;
        self.userViewIpadHeightFraction = 480.0 / 768.0;
        self.userViewIpadWidthFraction = 690.0 / 1024.0;
        self.userCellAvatarSize = 40.0;
        self.userCellButtonSize = 32.0;
        self.userOptionViewHeight = 40.0;
        self.userWindowDefaultBarHeight = 24.0;
        self.userHeaderTitleWidth = 90.0;
        
        self.robotDelayS = 1;
        self.robotDelayM = 2;
        self.maxReloadTimes = 7;
        self.userVideoPlaceholderImageMaxWidth = 480.0;
        self.userVideoPlaceholderImageMinWidth = 32.0;
    }
    return self;
}

- (void)updateVideoAspectRatioWithVideoDefinition:(BJLVideoDefinition)videoDefinition {
    CGFloat videoAspectRatio = 16.0 / 9.0;
    NSInteger fullSizedVideosCount = 6;
    if (videoDefinition < BJLVideoDefinition_720p) {
        videoAspectRatio = 4.0 / 3.0;
        fullSizedVideosCount = 8;
    }
    self.videoAspectRatio = videoAspectRatio;
    self.fullSizedVideosCount = fullSizedVideosCount;
}

#pragma mark - getter

+ (CGFloat)layoutWidth { return sharedInstance.layoutWidth; }
+ (CGFloat)layoutHeight { return sharedInstance.layoutHeight; }
+ (CGFloat)layoutRatio { return sharedInstance.layoutRatio; }
+ (CGFloat)layoutCornerRadius { return sharedInstance.layoutCornerRadius; }
+ (CGFloat)widgetWidthFraction { return sharedInstance.widgetWidthFraction; }
+ (CGFloat)buttonSize { return sharedInstance.buttonSize; }
+ (CGFloat)blackboardAspectRatio { return sharedInstance.blackboardAspectRatio; }
+ (CGFloat)blackboardHeightFraction { return sharedInstance.blackboardHeightFraction; }
+ (CGFloat)blackboardWidthFraction { return sharedInstance.blackboardWidthFraction; }
+ (CGFloat)videoAspectRatio { return sharedInstance.videoAspectRatio; }
+ (NSInteger)fullSizedVideosCount { return sharedInstance.fullSizedVideosCount; }
+ (CGFloat)videosHeightFraction { return sharedInstance.videosHeightFraction; }
+ (CGFloat)videosWidthFraction { return sharedInstance.videosWidthFraction; }
+ (CGFloat)statusBarHeightFraction { return sharedInstance.statusBarHeightFraction; }
+ (CGFloat)statusBarHeight { return sharedInstance.statusBarHeight; }
+ (CGFloat)statusBarButtonSize { return sharedInstance.statusBarButtonSize; }
+ (CGFloat)statusBarSpace { return sharedInstance.statusBarSpace; }
+ (CGFloat)liveStartButtonWidth { return sharedInstance.liveStartButtonWidth; }
+ (CGFloat)liveStartButtonHeight { return sharedInstance.liveStartButtonHeight; }
+ (CGFloat)liveStartViewSpace { return sharedInstance.liveStartViewSpace; }
+ (CGFloat)popoverViewWidth { return sharedInstance.popoverViewWidth; }
+ (CGFloat)popoverViewHeight { return sharedInstance.popoverViewHeight; }
+ (CGFloat)popoverImageSize { return sharedInstance.popoverImageSize; }
+ (CGFloat)popoverViewSpace { return sharedInstance.popoverViewSpace; }
+ (CGFloat)promptCellHeiht { return sharedInstance.promptCellHeiht; }
+ (CGFloat)promptCellSmallSpace { return sharedInstance.promptCellSmallSpace; }
+ (CGFloat)promptCellLargeSpace { return sharedInstance.promptCellLargeSpace; }
+ (NSInteger)promptDuration { return sharedInstance.promptDuration; }
+ (NSInteger)promptCellMaxCount { return sharedInstance.promptCellMaxCount; }
+ (CGFloat)promptViewHeight { return sharedInstance.promptViewHeight; }
+ (CGFloat)toolboxHeightFraction { return sharedInstance.toolboxHeightFraction; }
+ (CGFloat)toolboxWidth { return sharedInstance.toolboxWidth; }
+ (CGFloat)toolboxOffset { return sharedInstance.toolboxOffset; }
+ (CGFloat)toolboxButtonSize { return sharedInstance.toolboxButtonSize; }
+ (CGFloat)toolboxButtonSpace { return sharedInstance.toolboxButtonSpace; }
+ (CGFloat)toolboxLineLength { return sharedInstance.toolboxLineLength; }
+ (CGFloat)toolboxButtonImageInset { return sharedInstance.toolboxButtonImageInset; }
+ (CGFloat)toolboxColorSize { return sharedInstance.toolboxColorSize; }
+ (CGFloat)toolboxColorLength { return sharedInstance.toolboxColorLength; }
+ (CGFloat)toolboxCornerRadius { return sharedInstance.toolboxCornerRadius; }
+ (CGFloat)toolboxDrawSpace { return sharedInstance.toolboxDrawSpace; }
+ (CGFloat)toolboxDrawButtonSize { return sharedInstance.toolboxDrawButtonSize; }
+ (CGFloat)toolboxDrawFontIconSize { return sharedInstance.toolboxDrawFontIconSize; }
+ (CGFloat)toolboxDrawFontSize { return sharedInstance.toolboxDrawFontSize; }
+ (CGFloat)documentFileCellWidth { return sharedInstance.documentFileCellWidth; }
+ (CGFloat)documentFileCellHeight { return sharedInstance.documentFileCellHeight; }
+ (CGFloat)documentFileCellImageSize { return sharedInstance.documentFileCellImageSize; }
+ (CGFloat)documentFileDisplayListWidth { return sharedInstance.documentFileDisplayListWidth; }
+ (CGFloat)toolbarHeightFraction { return sharedInstance.toolbarHeightFraction; }
+ (CGFloat)toolbarWidth { return sharedInstance.toolbarWidth; }
+ (CGFloat)toolbarOffset { return sharedInstance.toolbarOffset; }
+ (CGFloat)toolbarButtonWidth { return sharedInstance.toolbarButtonWidth; }
+ (CGFloat)toolbarButtonSize { return sharedInstance.toolbarButtonSize; }
+ (CGFloat)toolbarLineLength{ return sharedInstance.toolbarLineLength; }
+ (CGFloat)toolbarRedDotSize { return sharedInstance.toolbarRedDotSize; }
+ (CGFloat)toolbarRedLabelSize { return sharedInstance.toolbarRedLabelSize; }
+ (CGFloat)toolbarButtonImageInset { return sharedInstance.toolbarButtonImageInset; }
+ (CGFloat)toolbarCornerRadius { return sharedInstance.toolbarCornerRadius; }
+ (CGFloat)toolbarButtonSpace { return sharedInstance.toolbarButtonSpace; }
+ (CGFloat)toolbarLargeSpace { return sharedInstance.toolbarLargeSpace; }
+ (CGFloat)toolbarMediumSpace { return sharedInstance.toolbarMediumSpace; }
+ (CGFloat)toolbarSmallSpace { return sharedInstance.toolbarSmallSpace; }
+ (CGFloat)speakRequestButtonWidth { return sharedInstance.speakRequestButtonWidth; }
+ (CGFloat)writingBoradToolbarButtonWidth { return sharedInstance.writingBoradToolbarButtonWidth; }
+ (CGFloat)writingBoradToolbarLargeSpace { return sharedInstance.writingBoradToolbarLargeSpace; }
+ (CGFloat)writingBoradToolbarSmallSpace { return sharedInstance.writingBoradToolbarSmallSpace; }
+ (CGFloat)questionAnswerOptionButtonWidth { return sharedInstance.questionAnswerOptionButtonWidth; }
+ (CGFloat)questionAnswerOptionButtonHeight { return sharedInstance.questionAnswerOptionButtonHeight; }
+ (CGFloat)chatViewLargeSpace { return sharedInstance.chatViewLargeSpace; }
+ (CGFloat)chatViewMediumSpace { return sharedInstance.chatViewMediumSpace; }
+ (CGFloat)chatViewSmallSpace { return sharedInstance.chatViewSmallSpace; }
+ (CGFloat)chatCellMaxWidth { return sharedInstance.chatCellMaxWidth; }
+ (CGFloat)chatCellMaxTextHeight { return sharedInstance.chatCellMaxTextHeight; }
+ (CGFloat)chatCellMinTextHeight { return sharedInstance.chatCellMinTextHeight; }
+ (CGFloat)chatCellMinUserInOutTextHeight { return sharedInstance.chatCellMinUserInOutTextHeight; }
+ (CGFloat)chatCellMinTextWidth { return sharedInstance.chatCellMinTextWidth; }
+ (CGFloat)chatCellMaxImageHeight { return sharedInstance.chatCellMaxImageHeight; }
+ (CGFloat)userViewMaxSpace { return sharedInstance.userViewMaxSpace; }
+ (CGFloat)userViewLargeSpace { return sharedInstance.userViewLargeSpace; }
+ (CGFloat)userViewMediumSpace { return sharedInstance.userViewMediumSpace; }
+ (CGFloat)userViewSmallSpace { return sharedInstance.userViewSmallSpace; }
+ (CGFloat)userTableViewCellHeight { return sharedInstance.userTableViewCellHeight; }
+ (CGFloat)userViewIpadHeightFraction { return sharedInstance.userViewIpadHeightFraction; }
+ (CGFloat)userViewIpadWidthFraction { return sharedInstance.userViewIpadWidthFraction; }
+ (CGFloat)userCellAvatarSize { return sharedInstance.userCellAvatarSize; }
+ (CGFloat)userCellButtonSize { return sharedInstance.userCellButtonSize; }
+ (CGFloat)userOptionViewHeight { return sharedInstance.userOptionViewHeight; }
+ (CGFloat)userWindowDefaultBarHeight { return sharedInstance.userWindowDefaultBarHeight; }
+ (CGFloat)userHeaderTitleWidth { return sharedInstance.userHeaderTitleWidth; }
+ (CGFloat)robotDelayS { return sharedInstance.robotDelayS; }
+ (CGFloat)robotDelayM { return sharedInstance.robotDelayM; }
+ (NSInteger)maxReloadTimes { return sharedInstance.maxReloadTimes; }
+ (CGFloat)userVideoPlaceholderImageMaxWidth { return sharedInstance.userVideoPlaceholderImageMaxWidth; }
+ (CGFloat)userVideoPlaceholderImageMinWidth { return sharedInstance.userVideoPlaceholderImageMinWidth; }

@end

#pragma mark -

@implementation UIColor (BJLInteractiveClass)

+ (UIColor *)bjl_ic_quiteBadNetColor {
    return [UIColor bjl_colorWithHex:0xF5A623];
}

+ (UIColor *)bjl_ic_extremelyBadNetColor {
    return [UIColor bjl_colorWithHex:0xFF0000];
}

@end

#pragma mark -

@implementation NSObject (BJLInteractiveClass)

- (CGSize)bjlic_suitableSizeWithText:(nullable NSString *)text attributedText:(nullable NSAttributedString *)attributedText maxWidth:(CGFloat)maxWidth {
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

@end

#pragma mark -

@implementation UIImage (BJLInteractiveClass)

+ (UIImage *)bjlic_imageNamed:(NSString *)name {
    static NSString * const bundleName = @"BJLInteractiveClass", * const bundleType = @"bundle";
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *classBundle = [NSBundle bundleForClass:[BJLIcRoomViewController class]];
        NSString *bundlePath = [classBundle pathForResource:bundleName ofType:bundleType];
        bundle = [NSBundle bundleWithPath:bundlePath];
    });
    return [self imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
}

@end

#pragma mark - button

@implementation BJLIcImageButton

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self drawBackgroundCorner];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self drawBackgroundCorner];
}

- (void)drawBackgroundCorner {
    CGFloat xOffset = (self.bounds.size.width - self.backgroundSize.width) / 2.0;
    CGFloat yOffset = (self.bounds.size.height - self.backgroundSize.height) / 2.0;
    CGRect rect = CGRectMake(xOffset, yOffset, self.backgroundSize.width, self.backgroundSize.height);
    if (self.selected) {
        [self bjlic_drawBackgroundViewWithColor:self.selectedColor rect:rect cornerRadius:self.backgroundCornerRadius hidden:self.selectedColor ? NO : YES];
    }
    else {
        [self bjlic_drawBackgroundViewWithColor:self.normalColor rect:rect cornerRadius:self.backgroundCornerRadius hidden:self.normalColor ? NO : YES];
    }
}
    
@end

#pragma mark -

@implementation UIView (BJLInteractiveClass)

#if ! defined(__LP64__) || ! __LP64__ // #see CGFloat
+ (void)load {
    NSString *systemVersion = [UIDevice currentDevice].systemVersion;
    if (BJLVersionGE(systemVersion, @"10")
        && BJLVersionLT(systemVersion, @"11")) {
        BJLSwizzleMethod(self, @selector(removeFromSuperview), @selector(_bjlic_removeFromSuperview));
    }
}
- (void)_bjlic_removeFromSuperview {
    [self _bjlic_removeSuperviewConstraints];
    [self _bjlic_removeFromSuperview];
}
- (void)_bjlic_removeSuperviewConstraints {
    UIView *superview = self;
    while ((superview = superview.superview)) {
        if ([superview isKindOfClass:[UINavigationBar class]]) {
            continue;
        }
        for (NSLayoutConstraint *constraint in superview.constraints) {
            if (constraint.firstItem == self || constraint.secondItem == self) {
                [superview removeConstraint:constraint];
            }
        }
    }
}
#endif

- (CAShapeLayer *)bjlic_borderLayer {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setBjlic_borderLayer:(nullable CAShapeLayer *)borderLayer {
    objc_setAssociatedObject(self, @selector(bjlic_borderLayer), borderLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CAShapeLayer *)bjlic_shadowLayer {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setBjlic_shadowLayer:(nullable CAShapeLayer *)shadowLayer {
    objc_setAssociatedObject(self, @selector(bjlic_shadowLayer), shadowLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CAShapeLayer *)bjlic_backgroundLayer {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setBjlic_backgroundLayer:(nullable CAShapeLayer *)backgroundLayer {
    objc_setAssociatedObject(self, @selector(bjlic_backgroundLayer), backgroundLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CAShapeLayer *)bjlic_drawInnerShadowAlpha:(CGFloat)alpha cornerRadius:(CGFloat)cornerRadius {
    if (self.bjlic_shadowLayer && self.bjlic_shadowLayer.superlayer) {
        [self.bjlic_shadowLayer removeFromSuperlayer];
        self.bjlic_shadowLayer = nil;
    }
    CAShapeLayer *shadowLayer = [CAShapeLayer layer];
    shadowLayer.frame = self.bounds;
    shadowLayer.shadowOpacity = alpha;
    shadowLayer.shadowColor = [UIColor colorWithWhite:1.0 alpha:alpha].CGColor;
    shadowLayer.shadowOffset = CGSizeMake(0.0, 0.0);
    shadowLayer.fillRule = kCAFillRuleEvenOdd;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectInset(self.bounds, cornerRadius, cornerRadius));
    CGPathRef innerPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:cornerRadius].CGPath;
    CGPathAddPath(path, NULL, innerPath);
    CGPathCloseSubpath(path);
    shadowLayer.path = path;
    CGPathRelease(path);
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = innerPath;
    shadowLayer.mask = maskLayer;
    [self.layer addSublayer:shadowLayer];
    self.bjlic_shadowLayer = shadowLayer;
    return shadowLayer;
}

- (void)bjlic_drawRectCorners:(UIRectCorner)coners cornerRadii:(CGSize)cornerRadii {
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:coners cornerRadii:cornerRadii];
    shapeLayer.frame = self.bounds;
    shapeLayer.path = path.CGPath;
    self.layer.mask = shapeLayer;
}

- (CAShapeLayer *)bjlic_drawBorderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor corners:(UIRectCorner)coners cornerRadii:(CGSize)cornerRadii {
    if (self.bjlic_borderLayer && self.bjlic_borderLayer.superlayer) {
        [self.bjlic_borderLayer removeFromSuperlayer];
        self.bjlic_borderLayer = nil;
    }
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:coners cornerRadii:cornerRadii];
    shapeLayer.frame = self.bounds;
    shapeLayer.path = path.CGPath;
    shapeLayer.strokeColor = borderColor.CGColor;
    shapeLayer.fillColor = nil;
    shapeLayer.lineWidth = borderWidth;
    [self.layer addSublayer:shapeLayer];
    self.bjlic_borderLayer = shapeLayer;
    return shapeLayer;
}

- (CAShapeLayer *)bjlic_drawBorderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor position:(BJLIcRectPosition)position {
    if (self.bjlic_borderLayer && self.bjlic_borderLayer.superlayer) {
        [self.bjlic_borderLayer removeFromSuperlayer];
        self.bjlic_borderLayer = nil;
    }
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);

    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    
    if (position & BJLIcRectPosition_top) {
        CALayer *topLayer = [CALayer layer];
        topLayer.frame = CGRectMake(0.0, 0.0, width, borderWidth);
        topLayer.backgroundColor = borderColor.CGColor;
        [shapeLayer addSublayer:topLayer];
    }
    
    if (position & BJLIcRectPosition_bottom) {
        CALayer *bottomLayer = [CALayer layer];
        bottomLayer.frame = CGRectMake(0.0, height, width, borderWidth);
        bottomLayer.backgroundColor = borderColor.CGColor;
        [shapeLayer addSublayer:bottomLayer];
    }
    
    if (position & BJLIcRectPosition_left) {
        CALayer *leftLayer = [CALayer layer];
        leftLayer.frame = CGRectMake(0.0, 0.0, borderWidth, height);
        leftLayer.backgroundColor = borderColor.CGColor;
        [shapeLayer addSublayer:leftLayer];
    }
    
    if (position & BJLIcRectPosition_right) {
        CALayer *rightLayer = [CALayer layer];
        rightLayer.frame = CGRectMake(width, 0.0, borderWidth, height);
        rightLayer.backgroundColor = borderColor.CGColor;
        [shapeLayer addSublayer:rightLayer];
    }
    
    [self.layer addSublayer:shapeLayer];
    self.bjlic_borderLayer = shapeLayer;
    return shapeLayer;
}

- (CAShapeLayer *)bjlic_drawCircleBackgroundViewWithColor:(nullable UIColor *)color hidden:(BOOL)hidden {
    return [self bjlic_drawBackgroundViewWithColor:color rect:self.bounds cornerRadius:self.bounds.size.height / 2.0 hidden:hidden];
}

- (CAShapeLayer *)bjlic_drawBackgroundViewWithColor:(nullable UIColor *)color rect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius hidden:(BOOL)hidden {
    if (hidden) {
        self.bjlic_backgroundLayer.hidden = hidden;
        return self.bjlic_backgroundLayer;
    }
    if (self.bjlic_backgroundLayer && self.bjlic_backgroundLayer.superlayer) {
        [self.bjlic_backgroundLayer removeFromSuperlayer];
        self.bjlic_backgroundLayer = nil;
    }
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
    shapeLayer.frame = self.bounds;
    shapeLayer.fillColor = color.CGColor;
    shapeLayer.path = path.CGPath;
    [self.layer insertSublayer:shapeLayer atIndex:0];
    self.bjlic_backgroundLayer = shapeLayer;
    return shapeLayer;
}

+ (UIView *)bjlic_createSeparateLine {
    UIView *view = [UIView new];
    view.backgroundColor = BJLIcTheme.separateLineColor;
    return view;
}

@end

NS_ASSUME_NONNULL_END
