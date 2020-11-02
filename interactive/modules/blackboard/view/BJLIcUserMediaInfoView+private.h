//
//  BJLIcUserMediaInfoView+private.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/18.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveBase/BJL_M9Dev.h>

#import "BJLIcUserMediaInfoView.h"
#import "BJLIcUserOperateView.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserMediaInfoView () <UIPopoverPresentationControllerDelegate>

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic, weak) UIViewController *parentViewController;

#pragma mark - user

@property (nonatomic, readwrite) BJLMediaUser *user;
@property (nonatomic) BOOL isRecording;
@property (nonatomic) NSArray<NSString *> *availableMediaID;

#pragma mark - view

@property (nonatomic) BJLIcVideoPosition prevPosition;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UIButton *speakRequestButton;
@property (nonatomic) UIView *speakRequestControlView;
@property (nonatomic) UIButton *allowSpeakRequestButton, *refuseSpeakRequestButton;
@property (nonatomic) UIView *infoGroupView, *groupColorView;
@property (nonatomic) UIImageView *audioLevelView, *signalLevelView;
@property (nonatomic) UILabel *userNameLabel;
@property (nonatomic) UIImageView *drawingGrantedView, *webPPTAuthorizedView;
//@property (nonatomic, weak) UIView *videoView;
@property (nonatomic, readwrite) BJLButton *likeButton;
@property (nonatomic) UIViewController *optionViewController;
@property (nonatomic) UIViewController *awardsViewController;

#pragma mark - placeholder

@property (nonatomic, nullable) NSString *imageURLString; // 用户设置的背景图片<用于未开视频时展示占位>
@property (nonatomic) UIView *placeholderImageLayer; // 用于fit放置width为1/2的png图片
@property (nonatomic) UIView *urlImageLayer; // 用于fill放置全屏的网页加载的图片
@property (nonatomic) UIImageView *placeholderImageView;
@property (nonatomic) UIImageView *urlImageView;

- (UIImageView *)imageViewWithName:(NSString *)imageName;

#pragma mark - loading

@property (nonatomic, nullable) id<BJLObservation> mediaUserObservation;
@property (nonatomic) UIView *videoLoadingView;
@property (nonatomic) UIImageView *videoLoadingImageView;
@property (nonatomic) BOOL animating, needStopAnimation;

#pragma mark - weak nerwork

@property (nonatomic) UILabel *lossRateLabel;
@property (nonatomic) UILabel *networkMessageLabel;
@property (nonatomic) BOOL isNetworkMessageShowing;
// < userNumber, < time, loss rate key > >
@property (nonatomic) NSMutableDictionary<NSString *, NSArray<NSDictionary<NSNumber *, NSNumber *> *> *> *lossRateDictionary;
@property (nonatomic, nullable) NSTimer *lossRateObservingTimer;

#pragma mark - action

- (void)sendLikeForCurrentUser;
- (BOOL)blockCurrentUser;
- (void)showSpeakRequestControlView;
- (void)allowSpeakRequest;
- (void)refuseSpeakRequest;

@end

NS_ASSUME_NONNULL_END
