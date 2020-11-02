//
//  BJLIcBlackboardLayoutViewController+webview.h
//  BJLiveUI
//
//  Created by xijia dai on 2020/6/2.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcBlackboardLayoutViewController (webview)

- (void)makeObserversForWebPage;
- (void)closeWebViewController;
- (void)openWebView;

@end

NS_ASSUME_NONNULL_END
