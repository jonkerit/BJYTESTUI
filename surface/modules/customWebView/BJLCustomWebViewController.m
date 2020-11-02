//
//  BJLCustomWebViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2020-07-09.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLCustomWebViewController.h"

#import "BJLScAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLCustomWebViewController () <WKNavigationDelegate>

@property (nonatomic, copy, nullable) NSURLRequest *request;

@property (nonatomic) UIView *progressView, *topView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *reloadButton, *closeButton;

@end

@implementation BJLCustomWebViewController

- (instancetype)initWithRequest:(NSURLRequest *)request {
    self = [super initWithConfiguration:nil];
    if (self) {
        self.request = request;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.userAgentSuffix = [BJLUserAgent defaultInstance].sdkUserAgent;
    
    self.progressView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjlsc_blueBrandColor];
        view;
    });
    
    self.reloadButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, reloadButton);
        [button setTitle:@"加载失败，点击重试" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjlsc_lightGrayTextColor] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor whiteColor];
        button;
    });
    
    self.topView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, topView);
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:16.0];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor bjlsc_blueBrandColor];
        label.text = nil; // set when didFinish
        [self.topView addSubview:label];
        label;
    });
    UIView *line = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjlsc_grayLineColor];
        [self.topView addSubview:view];
        bjl_return view;
    });
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.topView];
    [self.topView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        make.height.equalTo(@(BJLScControlSize));
    }];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.topView.bjl_safeAreaLayoutGuide ?: self.topView).with.offset(BJLScViewSpaceL);
        make.top.equalTo(self.topView.bjl_safeAreaLayoutGuide ?: self.topView);
    }];
    [line bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.equalTo(self.topView.bjl_safeAreaLayoutGuide ?: self.topView);
        make.left.equalTo(self.topView.bjl_safeAreaLayoutGuide ?: self.topView).with.offset(BJLScViewSpaceL);
        make.right.equalTo(self.topView.bjl_safeAreaLayoutGuide ?: self.topView).with.offset(-BJLScViewSpaceL);
        make.height.equalTo(@(BJLScOnePixel));
        make.top.equalTo(self.titleLabel.bjl_bottom);
    }];
    
    [self.webView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo((self.view.bjl_safeAreaLayoutGuide ?: self.view));
        make.top.equalTo(self.topView.bjl_bottom);
    }];
    
    self.closeButton = ({
        UIButton *button = [BJLButton makeTextButtonDestructive:NO];
        [button setTitle:@"关闭" forState:UIControlStateNormal];
        button;
    });
    [self.topView addSubview:self.closeButton];
    [self.closeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.topView.bjl_safeAreaLayoutGuide ?: self.topView).with.offset(-BJLScViewSpaceL);
        make.top.equalTo(self.topView.bjl_safeAreaLayoutGuide ?: self.topView);
        make.height.equalTo(self.titleLabel);
    }];
    
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.webView, estimatedProgress)
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.progressView.superview) {
            [self.progressView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                make.left.equalTo(self.view);
                make.top.equalTo(self.topView.bjl_bottom);
                make.width.equalTo(self.view).multipliedBy(self.webView.estimatedProgress);
                make.height.equalTo(@(BJLScOnePixel));
            }];
        }
        return YES;
    }];
    
    [self.reloadButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        [self.webView stopLoading];
        [self.webView loadRequest:self.request];
    }];
    
    [self.closeButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        UIAlertController *alert = [UIAlertController bjl_lightAlertControllerWithTitle:@"提示"
                                                                                message:@"确认关闭？"
                                                                         preferredStyle:UIAlertControllerStyleAlert];
        [alert bjl_addActionWithTitle:@"确认"
                                style:UIAlertActionStyleDestructive
                              handler:^(UIAlertAction * _Nonnull action) {
            bjl_strongify(self);
            [self.webView stopLoading];
            if (self.closeWebViewCallback) self.closeWebViewCallback();
        }];
        [alert bjl_addActionWithTitle:@"取消"
                                style:UIAlertActionStyleCancel
                              handler:nil];
        if (self.presentedViewController) {
            [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
        }
        [self presentViewController:alert animated:YES completion:nil];
    }];
    
    
    [self.webView loadRequest:self.request];
}

#pragma mark - loading state

- (void)didStartLoading {
    [self.view addSubview:self.progressView];
    [self.progressView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.top.equalTo(self.topView.bjl_bottom);
        make.width.equalTo(self.view).multipliedBy(self.webView.estimatedProgress);
        make.height.equalTo(@(BJLScOnePixel));
    }];
    
    [self.reloadButton removeFromSuperview];
}

- (void)didFailLoading {
    [self.progressView removeFromSuperview];
    
    [self.view addSubview:self.reloadButton];
    [self.reloadButton bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.closeButton.hidden = NO;
}

- (void)didFinishLoading {
    [self.progressView removeFromSuperview];
}

#pragma mark - <WKNavigationDelegate>

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"[CustomWebPage] didStartProvisionalNavigation: %@", navigation);
    self.titleLabel.text = @"加载中...";
    [self didStartLoading];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"[CustomWebPage] didFailProvisionalNavigation: %@ || %@", navigation, error);
    self.titleLabel.text = @"加载失败";
    [self didFailLoading];
}

/*
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"[CustomWebPage] didCommitNavigation: %@", navigation);
    self.navigationItem.title = @"加载中...";
} */

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"[CustomWebPage] didFailNavigation: %@ || %@", navigation, error);
    self.titleLabel.text = @"加载失败";
    [self didFailLoading];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"[CustomWebPage] didFinishNavigation: %@", navigation);
    [self.webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        self.titleLabel.text = bjl_as(result, NSString);
    }];
    [self didFinishLoading];
}

#if DEBUG
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    if (completionHandler) {
        NSURLCredential *credential = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
}
#endif

@end

NS_ASSUME_NONNULL_END
