//
//  BJLScRoomViewController+actions.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScRoomViewController.h"
#import "BJLScAppearance.h"
#import "BJLScMediaInfoView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScRoomViewController (actions)

- (void)makeActionsOnViewDidLoad;
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)updatePPTUserInteractionEnable;
- (void)updateButtonStates;
- (void)touchHandUp;
- (void)showQuestionViewController;
- (void)updateQuestionRedDotHidden:(BOOL)hidden;

- (void)fullscreenCurrentMajorWindow;
- (void)restoreCurrentFullscreenWindow;

#pragma mark - replace

- (void)replaceMajorContentViewWithPPTView;
- (void)replaceMinorContentViewWithPPTView;
- (void)replaceMajorContentViewWithTeacherMediaInfoView;
- (void)replaceMinorContentViewWithTeacherMediaInfoView;
- (void)replaceMajorContentViewWithSecondMinorMediaInfoView;
- (void)replaceSecondMinorContentViewWithPPTView;
- (void)replaceSecondMinorContentViewWithSecondMinorMediaInfoView;
- (void)replaceFullscreenWithWindowType:(BJLScWindowType)windowType mediaInfoView:(nullable BJLScMediaInfoView *)mediaInfoView;
- (void)resetFullscreenWindowType;

@end

NS_ASSUME_NONNULL_END
