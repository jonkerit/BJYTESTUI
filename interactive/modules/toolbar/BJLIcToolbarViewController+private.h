//
//  BJLIcToolbarViewController+private.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolbarViewController.h"
#import "BJLIcAppearance.h"
#import "BJLAnnularProgressView.h"
#import "BJLIcUserSeatCell.h"
#import "BJLIcTeachingAidSelectView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcToolbarViewController () <UIPopoverPresentationControllerDelegate>

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) BOOL shouldShowCloudRecordingTipView, isCloudRecordingInitialized;
@property (nonatomic) BOOL isPhoneToolbarInitialized;

@property (nonatomic) UIView *backgroundView, *mediaBackgroundView, *menuBackgroundView;
@property (nonatomic, nullable) UIView *containerView;
@property (nonatomic) UIView *teacherMediaInfoContainerView;
@property (nonatomic) UILabel *teacherNamelabel;
@property (nonatomic) UIImageView *teacherPlaceholderImageView;
@property (nonatomic) BOOL teacherLeaveSeat;
@property (nonatomic, readwrite, nullable) BJLIcUserMediaInfoView *teacherMediaInfoView;
@property (nonatomic) UIPanGestureRecognizer *touchMoveGesture;
@property (nonatomic) UITapGestureRecognizer *tapGesture;
//  !!!: 控制器内【不】能通过 hidden 属性控制任何按钮的显示隐藏
@property (nonatomic, readwrite) UIButton
*exitButton, // 不用于 padUserVideoUpside
*menuButton, // 仅用于 padUserVideoUpside iphone
*speakerButton,
*microphoneButton,
*cameraButton,
*eyeProtectedButton,
*layoutButton, // version 2
*gallerylayoutButton,
*blackboardLayoutButton,
*cloudRecordingButton,
*unmuteAllMicrophoneButton,
*muteAllMicrophoneButton,
*forbidSpeakRequestButton,
*speakRequestButton,
*userListButton,
*chatListButton,
*homeworkButton, // 仅用于学生端打开作业
*coursewareButton, // 仅用于 1v1 iphone
*teachingAidButton; // 仅用于 1v1 iphone
@property (nonatomic) BJLAnnularProgressView *speakRequestProgressView;
@property (nonatomic) UIView *singleLine;
@property (nonatomic) BOOL needSpeakRequestBackground;
@property (nonatomic, readwrite, nullable) UILabel *chatListRedDot, *userListRedDot, *menuRedDot;
@property (nonatomic, nullable) UIViewController *layoutViewController, *cloudRecordingViewController, *cloudRecordingTipViewController, *speakingRequeatTipViewController;
@property (nonatomic) BJLIcTeachingAidSelectView *teachingAidSelectView;// 仅用于1V1 iphone

@end

NS_ASSUME_NONNULL_END
