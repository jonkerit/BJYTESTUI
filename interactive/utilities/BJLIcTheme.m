//
//  BJLIcTheme.m
//  BJLiveUI
//
//  Created by xijia dai on 2020/6/12.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#include <BJLiveBase/BJLiveBase.h>

#import "BJLIcTheme.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcTheme () <BJLYYModel>

// key --> 色值  value --> 颜色类型枚举
@property (nonatomic) NSDictionary *colorTypeConfig;

#pragma mark - 支持的配置项，根据需要增删

/** 品牌色 适用范围：高亮、按键等主要视觉引导，包括主要按钮色 */
@property (nonatomic) NSString *brandColor;

/** 弹窗内容字体主色 */
@property (nonatomic) NSString *containerTextColor;
/**  弹窗内容字体辅助色 */
@property (nonatomic) NSString *subContainerTextColor;

/** 弹窗中主要按钮字体颜色 适用范围：按钮等可交互的控件的字体色 */
@property (nonatomic) NSString *controlTextColor;
/** 弹窗中次要按钮字体颜色 适用范围：按钮等可交互的控件的辅助字体色 */
@property (nonatomic) NSString *subControlTextColor;

#pragma mark - 细分模块颜色

#pragma mark - text

@property (nonatomic) NSString *viewTextColor;
@property (nonatomic) NSString *viewSubTextColor;
@property (nonatomic) NSString *buttonBorderColor;

@property (nonatomic) NSString *buttonTextColor;
@property (nonatomic) NSString *subBbuttonTextColor;
@property (nonatomic) NSString *subButtonBackgroundColor;

/** room */
@property (nonatomic) NSString *roomBackgroundColor;

/** blackboard */
@property (nonatomic) NSString *blackboardColor;

/** separate Line color */
@property (nonatomic) NSString *separateLineColor;

/** user list */
@property (nonatomic) NSString *userCellRoleAssistantColor;
@property (nonatomic) NSString *userCellRolePresenterColor;

/** userMediaInfoView */
@property (nonatomic) NSString *userViewBackgroundColor;

/** 教具窗口: 小黑板, 答题器, 抢答器, 网页, 计时器 */
@property (nonatomic) NSString *windowBackgroundColor;
@property (nonatomic) NSString *windowCountDonwTextColor;

/** status bar */
@property (nonatomic) NSString *statusBackgroungColor;
@property (nonatomic) NSString *toolButtonTitleColor;

/** toolbox */
@property (nonatomic) NSString *toolboxBackgroundColor;
@property (nonatomic) NSString *toolboxFontBackgroundColor;

/** warning color */
@property (nonatomic) NSString *warningColor;

@end

@implementation BJLIcTheme

static BJLIcTheme * _Nullable sharedInstance = nil;

+ (void)setupColorWithConfig:(nullable NSDictionary *)config {
    if (!sharedInstance) {
        sharedInstance = [BJLIcTheme new];
    }
    if (config) {
        [sharedInstance bjlyy_modelSetWithJSON:config];
    }
}

+ (void)destroy {
    sharedInstance = nil;
}

- (instancetype)init {
    if (self = [super init]) {
        // 颜色色值和类型 mapper
        self.colorTypeConfig = @{  @"#1795FF": @(BJLIcColorType_lightBlue),
                                   @"#0000FF": @(BJLIcColorType_blue),
                                   @"#00007F": @(BJLIcColorType_deepBlue),
                                   @"#000000": @(BJLIcColorType_black),
                                   @"#7F7F7F": @(BJLIcColorType_grey),
                                   @"#FFFFFF": @(BJLIcColorType_white),
                                   @"#FF1F49": @(BJLIcColorType_lightRed),
                                   @"#FF0000": @(BJLIcColorType_red),
                                   @"#7F0000": @(BJLIcColorType_deepRed),
                                   @"#6DD400": @(BJLIcColorType_lightGreen),
                                   @"#00FF00": @(BJLIcColorType_green),
                                   @"#007F00": @(BJLIcColorType_deepGreen),
                                   @"#F7B500": @(BJLIcColorType_lightOrange),
                                   @"#FF8000": @(BJLIcColorType_orange),
                                   @"#804000": @(BJLIcColorType_deepOrange)
        };
        [self setupDefaultColorConfig];
    }
    return self;
}

// 初始化默认的颜色
- (void)setupDefaultColorConfig {
    self.brandColor = @"#1795FF"; // b-1

/*
    // 白色主题
    // windown
    self.windowBackgroundColor = @"#FFFFFF"; // b-2 #313847
    
    // toolbox
    self.toolboxBackgroundColor = @"#FFFFFF"; // b-2  313847 + 0.9透明度
    
    // room
    self.roomBackgroundColor = @"#F1F3FA";//b-3 161D2B
    
    // blackboard
    self.blackboardColor = @"#FBFBFE";//b-4 242A36
    
    // text
    self.viewTextColor = @"#333333"; //b-6 FFFFFF
*/

    // 深色主题
    // windown
    self.windowBackgroundColor = @"#313847"; // b-2 #
    
    // toolbox
    self.toolboxBackgroundColor = @"#313847"; // b-2 + 0.9透明度
    
    // room
    self.roomBackgroundColor = @"#161D2B";//b-3
    
    // blackboard
    self.blackboardColor = @"#242A36";//b-4
    
    // text
    self.viewTextColor = @"#FFFFFF"; //b-6
    
    self.buttonTextColor = @"#ffffff"; // b-10

    self.viewSubTextColor = @"#999999"; // 副内容文字b-7
    self.buttonBorderColor = @"#9FA8B5";
    self.subBbuttonTextColor = @"#666666";
    self.subButtonBackgroundColor = @"#EEEEEE";
    
    // separateLineColor
    self.separateLineColor = @"#9FA8B5";
        
    // user list
    self.userCellRoleAssistantColor = @"#FA6400";
    self.userCellRolePresenterColor = @"#1795FF";
        
    // userVideo
    self.userViewBackgroundColor = @"#313847";
            
    self.windowCountDonwTextColor = @"#9FA8B5";
    
    // status
    self.statusBackgroungColor = @"#9FA8B5"; // +0.15透明度
    self.toolButtonTitleColor = @"#9FA8B5";
    
    self.toolboxFontBackgroundColor = @"#3E4651";
    
    // warning color
    self.warningColor = @"#FF1F49";
}

// 支持服务端配置的值需要在此处解析
+ (nullable NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{
                // 主题色
                BJLInstanceKeypath(BJLIcTheme, brandColor):                 @"b1",
                BJLInstanceKeypath(BJLIcTheme, buttonTextColor):            @"b10",
                // 黑板
                BJLInstanceKeypath(BJLIcTheme, blackboardColor):            @"b4",
                // 窗口色
                BJLInstanceKeypath(BJLIcTheme, roomBackgroundColor):        @"b3",
                BJLInstanceKeypath(BJLIcTheme, windowBackgroundColor):      @"b2",
                BJLInstanceKeypath(BJLIcTheme, toolboxBackgroundColor):     @"b2",
                BJLInstanceKeypath(BJLIcTheme, toolButtonTitleColor):       @"b5",
                // 字体颜色
                BJLInstanceKeypath(BJLIcTheme, viewSubTextColor):           @"b7",
                BJLInstanceKeypath(BJLIcTheme, viewTextColor):              @"b6",
                BJLInstanceKeypath(BJLIcTheme, subBbuttonTextColor):        @"b9",
                BJLInstanceKeypath(BJLIcTheme, subButtonBackgroundColor):   @"b8",
    };
}

#pragma mark - public

+ (UIColor *)brandColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.brandColor] ?: [UIColor clearColor];
}

#pragma mark - text

+ (UIColor *)viewTextColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.viewTextColor] ?: [UIColor clearColor];
}

+ (UIColor *)viewSubTextColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.viewSubTextColor] ?: [UIColor clearColor];
}

+ (UIColor *)buttonBorderColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.buttonBorderColor alpha:0.5] ?: [UIColor clearColor];
}

+ (UIColor *)buttonTextColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.buttonTextColor] ?: [UIColor clearColor];
}

+ (UIColor *)subButtonTextColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.subBbuttonTextColor] ?: [UIColor clearColor];
}

+ (UIColor *)subButtonBackgroundColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.subButtonBackgroundColor] ?: [UIColor clearColor];
}

#pragma mark - room

+ (UIColor *)roomBackgroundColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.roomBackgroundColor] ?: [UIColor clearColor];
}

#pragma mark - blackboard

+ (UIColor *)blackboardColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.blackboardColor] ?: [UIColor clearColor];
}

#pragma mark - separate Line color

+ (UIColor *)separateLineColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.separateLineColor alpha:0.2] ?: [UIColor clearColor];
}

#pragma mark - user list

+ (UIColor *)userCellRoleAssistantColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.userCellRoleAssistantColor] ?: [UIColor clearColor];
}

+ (UIColor *)userCellRolePresenterColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.userCellRolePresenterColor] ?: [UIColor clearColor];
}

#pragma mark - userMediaInfoView

+ (UIColor *)userViewBackgroundColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.userViewBackgroundColor] ?: [UIColor clearColor];
}

#pragma mark -

+ (UIColor *)windowBackgroundColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.windowBackgroundColor] ?: [UIColor clearColor];
}

+ (UIColor *)windowShadowColor {
    return [UIColor colorWithWhite:0 alpha:0.2] ?: [UIColor clearColor];
}

+ (UIColor *)windowCountDonwTextColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.windowCountDonwTextColor] ?: [UIColor clearColor];
}

#pragma mark - status bar

+ (UIColor *)statusBackgroungColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.statusBackgroungColor alpha:0.15] ?: [UIColor clearColor];
}

+ (UIColor *)toolButtonTitleColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.toolButtonTitleColor] ?: [UIColor clearColor];
}

#pragma mark - toolbox

+ (UIColor *)toolboxBackgroundColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.toolboxBackgroundColor alpha:0.9] ?: [UIColor clearColor];
}

+ (UIColor *)toolboxFontBackgroundColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.toolboxFontBackgroundColor] ?: [UIColor clearColor];
}

#pragma mark - warning

+ (UIColor *)warningColor {
    return [UIColor bjl_colorWithHexString:sharedInstance.warningColor] ?: [UIColor clearColor];
}

@end

NS_ASSUME_NONNULL_END
