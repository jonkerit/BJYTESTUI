//
//  BJLIcWebViewWindowViewController.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/24.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcWindowViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLIcWebViewWindowLayout) {
    BJLIcWebViewWindowLayout_normal,    // 非老师身份, 展示网页
    BJLIcWebViewWindowLayout_unpublish, // 老师身份未发布
    BJLIcWebViewWindowLayout_publish,   // 老师身份已发布
};

@interface BJLIcWebViewWindowViewController : BJLIcWindowViewController

@property (nonatomic, nullable) void (^publishWebViewCallback)(NSString * _Nullable urlString, BOOL publish, BOOL close);
@property (nonatomic, nullable) void (^closeWebViewCallback)(void);
@property (nonatomic, nullable) void (^keyboardFrameChangeCallback)(CGRect keyboardFrame);

- (instancetype)initWithURLString:(nullable NSString *)urlString layout:(BJLIcWebViewWindowLayout)layout;
- (void)hideKeyboardView;
- (void)closeWebView;
- (void)remakeConstraintsWithLayout:(BJLIcWebViewWindowLayout)layout;

@end

NS_ASSUME_NONNULL_END
