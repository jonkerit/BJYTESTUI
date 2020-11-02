//
//  BJLIcVideoWindowViewController.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/21.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLIcWindowViewController.h"
#import "BJLIcUserMediaInfoView.h"

NS_ASSUME_NONNULL_BEGIN

@class BJLRoom;

@interface BJLIcVideoWindowViewController : BJLIcWindowViewController

@property (nonatomic, nullable, readonly) BJLIcUserMediaInfoView *videoView;

@property (nonatomic, copy, nullable) void (^videoWindowCloseCallback)(NSString *mediaID);

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

- (void)updateVideoView:(nullable BJLIcUserMediaInfoView *)videoView;

@end

NS_ASSUME_NONNULL_END
