//
//  BJLIcStatusBarViewController.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcStatusBarViewController : UIViewController

@property (nonatomic, readonly) UIButton *exitButton;
@property (nonatomic, readonly) UIButton *settingButton;

@property (nonatomic, nullable) void (^showWeakNetworkTipCallback)(NSInteger duration);

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

// 更新上行丢包率和网络状况
- (void)updateUploadPackageLossRate:(CGFloat)packageLossRate networkStatus:(BJLNetworkStatus)status;
// 更新下行丢包率和网络状态
- (void)updateDownloadPackageLossRate:(CGFloat)packageLossRate networkStatus:(BJLNetworkStatus)status;

@end

NS_ASSUME_NONNULL_END
