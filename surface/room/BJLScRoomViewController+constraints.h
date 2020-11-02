//
//  BJLScRoomViewController+constraints.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScRoomViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScRoomViewController (constraints)

- (void)makeConstraints;
- (void)makeViewControllers;
- (void)makeCountDownViewController;
- (void)updateVideosViewHidden:(BOOL)hidden;
- (void)updateTeacherVideoView;
- (void)updateTeacherExtraVideoViewWithMediaUser:(nullable BJLMediaUser *)user;
- (void)updateSecondMinorContentViewWithUser:(nullable BJLMediaUser *)user recording:(BOOL)recording;
- (void)updateMinorViewRatio:(CGFloat)ratio;
- (void)updateTeacherVideoPlaceholderView;
- (void)updateSecondMinorVideoPlaceholderView;

@end

NS_ASSUME_NONNULL_END
