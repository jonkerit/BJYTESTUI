//
//  BJLCustomWebViewController.h
//  BJLiveUI
//
//  Created by MingLQ on 2020-07-09.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLWebViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLCustomWebViewController : BJLWebViewController

@property (nonatomic, copy, nullable) void (^closeWebViewCallback)(void);

- (instancetype)initWithRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
