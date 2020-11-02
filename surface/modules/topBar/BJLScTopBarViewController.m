//
//  BJLScTopBarViewController.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/18.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScTopBarViewController.h"
#import "BJLScAppearance.h"

@interface BJLScTopBarViewController ()

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) NSTimer *classTimer;

@property (nonatomic) UILabel *titleLabel, *timeLabel;
@property (nonatomic) UIButton *closeButton, *serverRecordingButton, *shareButton, *settingButton;

#pragma mark - weak network

@property (nonatomic) UIButton *upPackageLossRateButton, *downPackageLossRateButton;
@property (nonatomic) NSString *upPackageLossRateString, *downPackageLossRateString;
@property (nonatomic) BJLNetworkStatus upPackageLossRateStatus, downPackageLossRateStatus;
@property (nonatomic) dispatch_queue_t headerHandleQueue;

// < userNumber, < time, loss rate > >
@property (nonatomic) NSMutableDictionary<NSString *, NSArray<NSDictionary<NSNumber *, NSNumber *> *> *> *lossRateDictionary;
@property (nonatomic, nullable) NSTimer *lossRateObservingTimer;
@property (nonatomic) CGFloat lossRateObservingTimeInterval;


@end

@implementation BJLScTopBarViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super init]) {
        self.room = room;
        self.upPackageLossRateString = @"0.00%";
        self.downPackageLossRateString = @"0.00%";
        self.upPackageLossRateStatus = BJLNetworkStatus_normal;
        self.downPackageLossRateStatus = BJLNetworkStatus_normal;
        self.lossRateDictionary = [NSMutableDictionary new];
        self.lossRateObservingTimeInterval = (self.room.featureConfig.lossRateRetainTime > 0) ? self.room.featureConfig.lossRateRetainTime : 10;
    }
    return self;
}

- (void)dealloc {
    [self stopTimer];
    [self stopLossRateObservingTimer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self makeSubviews];
    [self makeObserving];
    
    // fire
    [self updateUploadPackageLossRateString:self.upPackageLossRateString networkStatus:self.upPackageLossRateStatus];
    [self updateDownloadPackageLossRateString:self.downPackageLossRateString networkStatus:self.downPackageLossRateStatus];

    [self restartLossRateObservingTimer];
}

- (void)makeSubviews {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    self.view.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:iPhone ? 0.8 : 1.0];
    self.view.layer.masksToBounds = NO;
    self.view.layer.shadowOpacity = 0.3;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    self.view.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    self.view.layer.shadowRadius = 2.0;
    
    UIView *networkInfoView = ({
        UIView *view = [UIView new];
        [self.view addSubview:view];
        view;
    });
    [networkInfoView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
    }];
    
    self.upPackageLossRateButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, upPackageLossRateButton);
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_uplossrate"] forState:UIControlStateNormal];
        [button setAttributedTitle:[self packageLossRateAttributedStringWithString:self.upPackageLossRateString networkStatus:self.upPackageLossRateStatus] forState:UIControlStateNormal];
        [networkInfoView addSubview:button];
        button.userInteractionEnabled = NO;
        bjl_return button;
    });
    [self.upPackageLossRateButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.equalTo(@[networkInfoView, self.view.bjl_safeAreaLayoutGuide ?: self.view]);
        make.left.equalTo(networkInfoView).offset(BJLScViewSpaceS);
    }];
    
    self.downPackageLossRateButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, downPackageLossRateButton);
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_downlossrate"] forState:UIControlStateNormal];
        [button setAttributedTitle:[self packageLossRateAttributedStringWithString:self.downPackageLossRateString networkStatus:self.downPackageLossRateStatus] forState:UIControlStateNormal];
        [networkInfoView addSubview:button];
        button.userInteractionEnabled = NO;
        bjl_return button;
    });
    
    [self.downPackageLossRateButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.upPackageLossRateButton.bjl_right).offset(12.0);
        make.top.bottom.equalTo(self.upPackageLossRateButton);
        make.right.equalTo(networkInfoView);
    }];

    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, titleLabel);
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor bjl_colorWithHexString:@"#4A4A4A" alpha:1.0];
        label.text = @"课程标题";
        label;
    });
    [self.view addSubview:self.titleLabel];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.centerY.equalTo(self.view);
        make.centerX.equalTo(self.view).priorityHigh();
        make.horizontal.hugging.required();
        make.left.greaterThanOrEqualTo(networkInfoView.bjl_right).offset(BJLScViewSpaceM);
        make.right.lessThanOrEqualTo(self.timeLabel.bjl_left).offset(-BJLScViewSpaceM);
    }];

    self.closeButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, closeButton);
        button.layer.cornerRadius = 8.0;
        button.layer.masksToBounds = YES;
        button.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0];
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_close"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.view addSubview:self.closeButton];
    [self.closeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.view).offset(-8.0);
        make.centerY.equalTo(self.view);
        make.width.equalTo(@24.0);
        make.height.equalTo(@24.0);
    }];

    self.settingButton = [self makeButtonWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_setting"] selectedImage:nil action:@selector(showSetting)];
    self.shareButton = [self makeButtonWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_share"] selectedImage:nil action:@selector(share)];
    self.serverRecordingButton = [self makeButtonWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_recording"] selectedImage:[UIImage bjlsc_imageNamed:@"bjl_sc_recording_On"] action:@selector(updateServerRecording:)];
    self.serverRecordingButton.selected = self.room.serverRecordingVM.serverRecording;
    self.shareButton.hidden = YES;
    
    [self.view addSubview:self.settingButton];
    [self.view addSubview:self.shareButton];
    if (self.room.featureConfig.cloudRecordType == BJLServerRecordingType_cloud) {
        [self.view addSubview:self.serverRecordingButton];
    }
    
    self.timeLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, timeLabel);
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor bjl_colorWithHexString:@"#9EADB9" alpha:1.0];
        label.text = @"直播未开始";
        label.textAlignment = NSTextAlignmentRight;
        label;
    });
    [self.view addSubview:self.timeLabel];
}

- (void)makeConstraints {
    NSMutableArray<UIView *> *views = [@[self.settingButton, self.shareButton] mutableCopy];
    if (!self.room.featureConfig.enableShare || !self.shareCallback) {
        views = [@[self.settingButton] mutableCopy];
    }
    if ([self canshowServerRecordingState]) {
        [views bjl_addObject:self.serverRecordingButton];
    }
    else if (self.room.loginUser.isStudent && !self.room.featureConfig.hideRecordStatusOfStudent) {
        [views bjl_addObject:self.serverRecordingButton];
    }
    
    self.shareButton.hidden = !self.room.featureConfig.enableShare;
    [self makeConstraintsWithViews:[views copy]];
    
    [self.timeLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.horizontal.compressionResistance.required();
        make.left.greaterThanOrEqualTo(self.titleLabel.bjl_right).offset(BJLScViewSpaceM);
        make.right.equalTo(views.lastObject.bjl_left).offset(-8.0);
        make.height.centerY.equalTo(self.view);
    }];
}

#pragma mark - observing

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room, featureConfig)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.featureConfig) {
            [self makeConstraints];
        }
        return YES;
    }];
    
    // 目前在获取到了 roominfo 之后布局，可以直接 kvo roomInfo
    [self bjl_kvo:BJLMakeProperty(self.room.roomInfo, title)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.titleLabel.text = self.room.roomInfo.title;
             return YES;
         }];
    
    __block BOOL isInitial = YES;
    
    [self bjl_kvo:BJLMakeProperty(self.room.serverRecordingVM, serverRecording)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
          // bjl_strongify(self);
          return now.boolValue != old.boolValue;
      }
    observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        self.serverRecordingButton.selected = self.room.serverRecordingVM.serverRecording;
        
        if (![self canshowServerRecordingState]) {
            return YES;
        }
        
        if (now.boolValue) {
            [self showProgressHUDWithText:@"已开启录课"];
        }
        else {
            if (!isInitial) {
                [self showProgressHUDWithText:@"已关闭录课"];
            }
        }
        isInitial = NO;
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.serverRecordingVM, requestServerRecordingDidFailed:)
             observer:^BOOL(NSString *message) {
                 bjl_strongify(self);
                 [self showProgressHUDWithText:message];
                 return YES;
             }];

    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, mediaLossRateDidUpdateWithUser:videoLossRate:audioLossRate:)
             observer:(BJLMethodObserver)^BOOL(BJLMediaUser *user, CGFloat videoLossRate, CGFloat audioLossRate){
                 bjl_strongify(self);
                 // 目前只统计所有用户主摄流的丢包
                 if (user.mediaSource != BJLMediaSource_mainCamera) {
                     return YES;
                 }
                 
                 // 记录每个用户不同时间的丢包率数据
                 NSString *userNumber = user.number;
                 CGFloat packageLossRate = MIN(MAX(0.0, videoLossRate), 100.0);
                 NSString *userKey = [self userLossRateKeyWithUserNumber:userNumber mediaSource:user.mediaSource];
                dispatch_async(self.headerHandleQueue, ^{
                    NSMutableArray<NSDictionary *> *lossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
                    if (!lossRateArray) {
                        lossRateArray = [NSMutableArray new];
                    }
                    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
                    NSDictionary<NSNumber *, NSNumber *> *lossRateDic = [NSDictionary dictionaryWithObject:@(packageLossRate) forKey:@(timeInterval)];
                    [lossRateArray bjl_addObject:lossRateDic];
                    [self.lossRateDictionary bjl_setObject:lossRateArray forKey:userKey];
                });
                 return YES;
             }];

    [self startTimer];
}

- (void)startTimer {
    [self stopTimer];
    
    bjl_weakify(self);
    self.classTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self || !self.classTimer) {
            [timer invalidate];
            return ;
        }
        
        if (self.room.roomVM.classStartTimeMillisecond <= 0 || !self.room.roomVM.liveStarted) {
            return;
        }
        
        NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:[NSDate dateWithTimeIntervalSince1970:(self.room.roomVM.classStartTimeMillisecond/1000)]];
                               
        NSString *elapsedTimeString = [self elapsedTimeStringWithTimeInterval:time];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.timeLabel.text = elapsedTimeString;
        });
    }];
}

- (void)stopTimer {
    if (self.classTimer || [self.classTimer isValid]) {
        [self.classTimer invalidate];
        self.classTimer = nil;
    }
}

- (NSString *)elapsedTimeStringWithTimeInterval:(NSTimeInterval)timeInterval {
    if (timeInterval <= 0) {
        return @"直播未开始";
    }
    
    NSInteger elapsedTime = round(timeInterval);
    NSInteger second = elapsedTime % 60;
    NSInteger minute = (elapsedTime / 60) % 60;
    NSInteger hour = elapsedTime / 3600;
    NSString *secondString = second >= 10 ? [NSString stringWithFormat:@"%ld", (long)second] : [NSString stringWithFormat:@"0%ld", (long)second];
    NSString *minuteString = minute >= 10 ? [NSString stringWithFormat:@"%ld", (long)minute] : [NSString stringWithFormat:@"0%ld", (long)minute];
    NSString *hourString = hour >= 10 ? [NSString stringWithFormat:@"%ld", (long)hour] : [NSString stringWithFormat:@"0%ld", (long)hour];
    return [NSString stringWithFormat:@"直播中:  %@:%@:%@", hourString, minuteString, secondString];
}

#pragma mark - lossrate
- (void)stopLossRateObservingTimer {
    if (self.lossRateObservingTimer || [self.lossRateObservingTimer isValid]) {
        [self.lossRateObservingTimer invalidate];
        self.lossRateObservingTimer = nil;
    }
}

- (void)restartLossRateObservingTimer {
        [self stopLossRateObservingTimer];
        bjl_weakify(self);
        self.lossRateObservingTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            bjl_strongify_ifNil(self) {
                [timer invalidate];
                return;
            }
            dispatch_async(self.headerHandleQueue, ^{
                CGFloat downloadLossRate = 0.0f;
                CGFloat uploadLossRate = 0.0f;
                BOOL hasCurrentLoginUser = NO;
                NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];
                for (NSString *userKey in [self.lossRateDictionary.allKeys copy]) {
                    // 读取每个用户的丢包率数据
                    NSMutableArray<NSDictionary *> *lossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
                    NSString *userNumber = [self userNumberForUserLossRateKey:userKey];
                    NSInteger count = lossRateArray.count;
                    
                    if (count > 0) {
                        CGFloat totalLossRate = 0.0f;
                        for (NSDictionary<NSNumber *, NSNumber *> *lossRateDic in [lossRateArray copy]) {
                            // 读取用户丢包率数据中的时间，去掉 lossRateObservingTimeInterval 之外的时间
                            for (NSNumber *timeInterval in [lossRateDic.allKeys copy]) {
                                if (nowTimeInterval - [timeInterval bjl_doubleValue] > self.lossRateObservingTimeInterval) {
                                    // 大于 lossRateObservingTimeInterval 的数据移除
                                    [lossRateArray removeObject:lossRateDic];
                                }
                                else {
                                    // 否则加入计算
                                    totalLossRate += [lossRateDic bjl_floatForKey:timeInterval];
                                }
                            }
                        }
                        // 更新丢包率的字典
                        [self.lossRateDictionary bjl_setObject:lossRateArray forKey:userKey];
                        
                        if([userNumber isEqualToString:self.room.loginUser.number]) {
                            uploadLossRate = (lossRateArray.count > 0) ? totalLossRate / lossRateArray.count : 0.0f;
                            hasCurrentLoginUser = YES;
                        }
                        else {
                            downloadLossRate += (lossRateArray.count > 0) ? totalLossRate / lossRateArray.count : 0.0f;
                        }
                    }
                }
                
                if([self.lossRateDictionary.allKeys count]) {
                    if(hasCurrentLoginUser && [self.lossRateDictionary.allKeys count] > 1) {
                        downloadLossRate = downloadLossRate / ([self.lossRateDictionary.allKeys count] - 1);
                    }
                    else if(!hasCurrentLoginUser){
                        downloadLossRate = downloadLossRate / ([self.lossRateDictionary.allKeys count]);
                    }
                    else {
                        downloadLossRate = 0.0f;
                    }
                }
                else {
                    downloadLossRate = 0.0f;
                }
                
                // 记录处理时间
                BJLNetworkStatus uploadNetWork = [self netWorkStatusWithLossRate:uploadLossRate];
                BJLNetworkStatus downloadNetWork = [self netWorkStatusWithLossRate:downloadLossRate];
                NSString *upPackageLossRateString = [NSString stringWithFormat:@"%.2f%%", uploadLossRate];
                NSString *downPackageLossRateString = [NSString stringWithFormat:@"%.2f%%", downloadLossRate];
                [self updateUploadPackageLossRateString:upPackageLossRateString networkStatus:uploadNetWork];
                [self updateDownloadPackageLossRateString:downPackageLossRateString networkStatus:downloadNetWork];
            });
        }];
}

- (NSString *)userLossRateKeyWithUserNumber:(NSString *)userNumber mediaSource:(BJLMediaSource)mediaSource {
    return [NSString stringWithFormat:@"%@-%td", userNumber, mediaSource];
}

- (BJLMediaSource)mediaSourceForUserLossRateKey:(NSString *)key{
    NSString *separator = @"-";
    BJLMediaSource mediaSource = BJLMediaSource_mainCamera;
    NSRange separatorRange = [key rangeOfString:separator];
    if (separatorRange.location != NSNotFound) {
        mediaSource = [key substringFromIndex:separatorRange.location + separatorRange.length].integerValue;
    }
    return mediaSource;
}
- (nullable NSString *)userNumberForUserLossRateKey:(NSString *)key{
    NSString *separator = @"-";
    NSString *userNumber = nil;
    NSRange separatorRange = [key rangeOfString:separator];
    if (separatorRange.location != NSNotFound) {
        userNumber = [key substringToIndex:separatorRange.location];
    }
    return userNumber;
}

// 更新上行丢包率和网络状况
- (void)updateUploadPackageLossRateString:(NSString *)packageLossRateString
                            networkStatus:(BJLNetworkStatus)networkStatus {
    // 只有标签存在, 并且网络状态或丢包率的状态变化了, 才会更新
    dispatch_async(self.headerHandleQueue, ^{
        
        if (![self.upPackageLossRateString isEqualToString:packageLossRateString]) {
            self.upPackageLossRateString = packageLossRateString;
            if (self.upPackageLossRateButton) {
                NSAttributedString *packageLossRateAttributedString = [self packageLossRateAttributedStringWithString:packageLossRateString networkStatus:networkStatus];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.upPackageLossRateButton setAttributedTitle:packageLossRateAttributedString forState:UIControlStateNormal];
                });
            }
        }
    });
}

// 更新下行丢包率和网络状态
- (void)updateDownloadPackageLossRateString:(NSString *)packageLossRateString
                              networkStatus: (BJLNetworkStatus)networkStatus {
    // 只有标签存在, 并且网络状态或丢包率的状态变化了, 才会更新
    dispatch_async(self.headerHandleQueue, ^{
        
        if (![self.downPackageLossRateString isEqualToString:packageLossRateString]) {
            self.downPackageLossRateString = packageLossRateString;
            if (self.downPackageLossRateButton) {
                NSAttributedString *packageLossRateAttributedString = [self packageLossRateAttributedStringWithString:packageLossRateString networkStatus:networkStatus];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.downPackageLossRateButton setAttributedTitle:packageLossRateAttributedString forState:UIControlStateNormal];
                });
            }
        }
    });
}

- (nullable NSAttributedString *)packageLossRateAttributedStringWithString:(NSString
                                                                            *)packageLossRateString networkStatus:(BJLNetworkStatus)networkStatus {
    if (!packageLossRateString.length) {
        return nil;
    }
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] init];
    NSAttributedString *packageLossRateAttributedString = [[NSAttributedString alloc] initWithString:packageLossRateString
                                                                                          attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                                                                                        NSForegroundColorAttributeName : [self colorWithNetworkStatus:networkStatus],
                                                                                                        }];
    [mutableAttributedString appendAttributedString:packageLossRateAttributedString];
    return mutableAttributedString;
}

- (BJLNetworkStatus)netWorkStatusWithLossRate:(CGFloat)lossRate {
    NSArray *lossRateArray = [self.room.featureConfig.lossRateLevelArray copy];
    
    BJLNetworkStatus preLossRateLevel = BJLNetworkStatus_normal;
    BJLNetworkStatus currentLossRateLevel = BJLNetworkStatus_normal;
    for (NSInteger index = 0 ; index < [lossRateArray count]; index++) {
        NSNumber *nmber = [lossRateArray objectAtIndex:index];
        CGFloat lossRateLevel = nmber.floatValue;
        if(preLossRateLevel == BJLNetworkStatus_normal && lossRateLevel > 0 && lossRateLevel <= 100) {
            preLossRateLevel = (BJLNetworkStatus)index;
        }
        
        if(lossRateLevel <= 0 || lossRateLevel > 100) {
            continue;
        }
        
        if(lossRateLevel <= lossRate) {
            preLossRateLevel = (BJLNetworkStatus)index;
            continue;
        }
        
        if(lossRateLevel > lossRate) {
            currentLossRateLevel = (BJLNetworkStatus)index;
            break;
        }
    }
    
    if(currentLossRateLevel == BJLNetworkStatus_normal && preLossRateLevel == BJLNetworkStatus_normal) {
        return BJLNetworkStatus_normal;
    }
    
    if(currentLossRateLevel == BJLNetworkStatus_normal) {
        currentLossRateLevel = (preLossRateLevel + 1 <= BJLNetworkStatus_Bad_level5) ? (preLossRateLevel + 1) : BJLNetworkStatus_Bad_level5;
    }
    else {
        currentLossRateLevel = (currentLossRateLevel <= BJLNetworkStatus_Bad_level5) ? currentLossRateLevel : BJLNetworkStatus_Bad_level5;
    }
    return currentLossRateLevel;
}

- (UIColor *)colorWithNetworkStatus:(BJLNetworkStatus)networkStatus {
    switch (networkStatus) {
        case BJLNetworkStatus_normal:
            return [UIColor bjl_colorWithHexString:@"#88FF00" alpha:1.0];
            
        case BJLNetworkStatus_Bad_level1:
            return [UIColor bjl_colorWithHexString:@"#1199FF" alpha:1.0];
            
        case BJLNetworkStatus_Bad_level2:
            return [UIColor bjl_colorWithHexString:@"#FFBB33" alpha:1.0];
            
        case BJLNetworkStatus_Bad_level3:
        case BJLNetworkStatus_Bad_level4:
        case BJLNetworkStatus_Bad_level5:
            return [UIColor bjl_colorWithHexString:@"#FF0000" alpha:1.0];
            
        default:
            return [UIColor whiteColor];
    }
}

- (dispatch_queue_t)headerHandleQueue {
    if (!_headerHandleQueue) {
        _headerHandleQueue =  dispatch_queue_create("header_handle_queue", DISPATCH_QUEUE_SERIAL);
    }
    return _headerHandleQueue;
}

#pragma mark - action

- (void)close:(UIButton *)button {
    UIAlertController *alertController = [UIAlertController bjl_lightAlertControllerWithTitle:@"退出教室" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController bjl_addActionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil];
    [alertController bjl_addActionWithTitle:@"退出" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (self.exitCallback) {
            self.exitCallback();
        }
    }];
    if (self.room.roomVM.liveStarted && (self.room.loginUser.isTeacher || (self.room.loginUser.isAssistant && self.room.roomVM.getAssistantaAuthorityWithClassStartEnd))) {
        [alertController bjl_addActionWithTitle:@"下课并退出" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self.room.roomVM sendLiveStarted:NO];
            
            // 老师下课时发出关闭计时器信令
            if (self.room.loginUser.isTeacher) {
                [self.room.roomVM requestStopTimer];
            }
            if (self.exitCallback) {
                self.exitCallback();
            }
        }];
    }
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showSetting {
    if (self.showSettingCallback) {
        self.showSettingCallback();
    }
}

- (void)share {
    if (!self.room.featureConfig.enableShare) {
        return;
    }
    
    if (self.shareCallback) {
        self.shareCallback();
    }
}

- (void)updateServerRecording:(UIButton *)button {
    if (![self canUpdateServerRecording]) {
        return;
    }
    
    if (!button.selected) {
        BJLError *error = [self.room.serverRecordingVM requestServerRecording:!button.selected];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
        return;
    }
    
    bjl_weakify(self);
    UIAlertController *alertController = [UIAlertController bjl_lightAlertControllerWithTitle:@"正在录课中" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController bjl_addActionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil];
    [alertController bjl_addActionWithTitle:@"结束录课" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        bjl_strongify(self);
        BJLError *error = [self.room.serverRecordingVM requestServerRecording:!button.selected];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
    }];
    
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma makr - wheel

/* 是否展示云端录制
 大班老师/助教 && 配置为展示录制状态 && 教室配置为云端录制
 */
- (BOOL)canshowServerRecordingState {
    return (self.room.loginUser.isTeacherOrAssistant
            && self.room.loginUser.groupID == 0
            && !self.room.featureConfig.hideRecordStatusOfTeacherAndAssistant
            && self.room.featureConfig.cloudRecordType == BJLServerRecordingType_cloud);
}

/* 开启/关闭云端录制权限
 大班课老师, 配置了展示录制就允许操作
 大班课助教,允许操作云端录制 && 配置为展示录制  && 教室配置为云端录制
 */
- (BOOL)canUpdateServerRecording {
    return ((self.room.loginUser.isTeacher
             || (self.room.loginUser.isAssistant && self.room.roomVM.getAssistantaAuthorityWithCloudRecord))
            && self.room.loginUser.groupID == 0
            && !self.room.featureConfig.hideRecordStatusOfTeacherAndAssistant
            && self.room.featureConfig.cloudRecordType == BJLServerRecordingType_cloud);
}

- (void)makeConstraintsWithViews:(NSArray<UIView *> *)views {
    UIView *last = nil;
    for (UIView *view in views) {
        [view bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.horizontal.compressionResistance.required();
            make.centerY.equalTo(self.view);
            if (last) {
                make.right.equalTo(last.bjl_left);
                make.width.height.equalTo(last);
            }
            else {
                make.right.equalTo(self.closeButton.bjl_left).offset(-8.0);
                make.width.height.equalTo(@32.0).priorityHigh();
            }
        }];
        last = view;
    }
}

- (UIButton *)makeButtonWithImage:(UIImage *)image
                    selectedImage:(UIImage *)selectedImage
                           action:(SEL)selector {
    UIButton *button = [UIButton new];
    button.backgroundColor = [UIColor clearColor];
    if (image) {
        [button setImage:image forState:UIControlStateNormal];
    }
    if (selectedImage) {
        [button setImage:selectedImage forState:UIControlStateSelected];
        [button setImage:selectedImage forState:UIControlStateHighlighted | UIControlStateSelected];
    }
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

@end
