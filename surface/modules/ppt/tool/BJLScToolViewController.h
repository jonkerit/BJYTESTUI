//
//  BJLScToolViewController.h
//  BJLiveUI
//
//  Created by xyp on 2020/8/19.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScToolViewController : UIViewController

@property (nonatomic, readonly) BOOL expectedHidden;

@property (nonatomic, nullable) void (^showCoursewareCallback)(void);
@property (nonatomic, nullable) void (^openCountDownCallback)(void);

- (instancetype)initWithRoom:(BJLRoom *)room;

- (void)removeFromView:(UIView *)removeView
        addToSuperView:(UIView *)superView
      shouldFullScreen:(BOOL)shouldFullScreen;
- (void)updateToolViewHidden:(BOOL)shouldHidden;
- (void)updateToolViewOffset:(CGFloat)offset;

@end

NS_ASSUME_NONNULL_END
