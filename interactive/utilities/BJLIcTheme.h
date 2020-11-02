//
//  BJLIcTheme.h
//  BJLiveUI
//
//  Created by xijia dai on 2020/6/12.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcTheme : NSObject

+ (void)setupColorWithConfig:(nullable NSDictionary *)config;
+ (void)destroy;

#pragma mark - color

@property (class, nonatomic, readonly) UIColor *brandColor; // 品牌主题色b-1

#pragma mark - text

// TODO:也许会走配置项的文本颜色:比如 黑色模板是ffffff, 白色模板是333333
@property (class, nonatomic, readonly) UIColor *viewTextColor; //窗口内容文字主色 b-6

// 按钮的边框颜色
@property (class, nonatomic, readonly) UIColor *buttonBorderColor;
// 可以完美适配深色/浅色的副文本小标题
@property (class, nonatomic, readonly) UIColor *viewSubTextColor; //窗口副内容文字主色 b-7

@property (class, nonatomic, readonly) UIColor *buttonTextColor; //主色按钮文字色 b-10
@property (class, nonatomic, readonly) UIColor *subButtonTextColor; //灰色按钮文字色 b-9
@property (class, nonatomic, readonly) UIColor *subButtonBackgroundColor; //灰色按钮背景色 b-8

#pragma mark - room

@property (class, nonatomic, readonly) UIColor *roomBackgroundColor;// 房间背景色b-3

#pragma mark - blackboard

@property (class, nonatomic, readonly) UIColor *blackboardColor;// 大黑板背景色b-4

#pragma mark - separate Line color

@property (class, nonatomic, readonly) UIColor *separateLineColor;// 定值

#pragma mark - user list

@property (class, nonatomic, readonly) UIColor *userCellRoleAssistantColor;
@property (class, nonatomic, readonly) UIColor *userCellRolePresenterColor;

#pragma mark - userMediaInfoView

@property (class, nonatomic, readonly) UIColor *userViewBackgroundColor;

#pragma mark - 教具窗口: 小黑板, 答题器, 抢答器, 网页, 计时器

/// 计时器文字的颜色
@property (class, nonatomic, readonly) UIColor *windowCountDonwTextColor;

#pragma mark - status bar

// 状态栏颜色 + 固定在底部的工具栏底色
@property (class, nonatomic, readonly) UIColor *statusBackgroungColor;

@property (class, nonatomic, readonly) UIColor *toolButtonTitleColor; // 目前定值

#pragma mark - toolbox 画笔工具盒 +工具盒弹框 + 可展开收起的工具栏 + 各种气泡 + 聊天 + prompt

@property (class, nonatomic, readonly) UIColor *toolboxBackgroundColor; // 窗口背景色 b-2+0.9

@property (class, nonatomic, readonly) UIColor *toolboxFontBackgroundColor;

#pragma mark - window 教具+强提示选择弹框+用户列表+文件管理+设置

@property (class, nonatomic, readonly) UIColor *windowBackgroundColor; // 窗口背景色 b-2

@property (class, nonatomic, readonly) UIColor *windowShadowColor; // 窗口阴影色

#pragma mark - warning color

@property (class, nonatomic, readonly) UIColor *warningColor;

@end

NS_ASSUME_NONNULL_END
