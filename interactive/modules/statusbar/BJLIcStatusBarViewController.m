//
//  BJLIcStatusBarViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcStatusBarViewController.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcStatusBarViewController ()

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) NSDate *classStartDate;
@property (nonatomic) NSString *classTimeString;
@property (nonatomic, nullable) NSTimer *updateClassElapsedTimeTimer;

@property (nonatomic) UIView *backgroundView;
@property (nonatomic, readwrite) UIButton *exitButton, *settingButton;
@property (nonatomic) UILabel *classTitleLabel, *timeLabel;
@property (nonatomic) UILabel *lossRateLabel, *networkStatusLabel;
@property (nonatomic) CGFloat upPackageLossRate, downPackageLossRate, maxPackageLossRate;
@property (nonatomic) BJLNetworkStatus upNetworkStatus, downNetworkStatus;

@end

@implementation BJLIcStatusBarViewController

- (instancetype)initWithRoom:(id)room {
    if (self = [super init]) {
        self.maxPackageLossRate = -1.0;
        self.room = room;
        self.classTimeString = @"00:00:00";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    self.view.backgroundColor = BJLIcTheme.statusBackgroungColor;
    [self makeSubviewsAndConstraints];
    [self startUpdateClassElapsedTimeTimer];
}

- (void)makeSubviewsAndConstraints {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    CGFloat fontSize = iPhone ? 12.0 : 14.0;
    NSMutableArray<UIButton *> *buttonArrM = [NSMutableArray array];
    BOOL noExitButton = (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) && !iPhone;
    if (!noExitButton) {
        self.exitButton = ({
            UIButton *button = [BJLImageButton new];
            button.accessibilityLabel = BJLKeypath(self, exitButton);
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_statusbar_exit"] forState:UIControlStateNormal];
            [self.view addSubview:button];
            bjl_return button;
        });
        [buttonArrM addObject:self.exitButton];
        
        self.settingButton = ({
            UIButton *button = [BJLImageButton new];
            button.accessibilityLabel = BJLKeypath(self, settingButton);
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_statusbar_settings"] forState:UIControlStateNormal];
            [self.view addSubview:button];
            bjl_return button;
        });
        [buttonArrM addObject:self.settingButton];
        
        // 按照顺序从右向左添加
        UIButton *last = nil;
        for (UIButton *button in buttonArrM) {
            [button bjl_makeConstraints:^(BJLConstraintMaker *make) {
                make.centerY.equalTo(self.view);
                make.right.equalTo(last.bjl_left ?: self.view);
                make.top.greaterThanOrEqualTo(self.view).required();
                make.bottom.lessThanOrEqualTo(self.view).required();
                make.height.equalTo(@(BJLIcAppearance.statusBarButtonSize)).priorityHigh();
                make.width.equalTo(button.bjl_height);
            }];
            last = button;
        }
    }
    
    self.classTitleLabel = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 1;
        label.text = self.room.roomInfo.title;
        label.font = [UIFont systemFontOfSize:fontSize];
        label.textColor = BJLIcTheme.viewTextColor;
        [self.view addSubview:label];
        bjl_return label;
    });
    
    self.timeLabel = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 1;
        label.text = [self updateClassTimeString];
        label.font = [UIFont systemFontOfSize:fontSize];
        label.textColor = BJLIcTheme.viewTextColor;
        [self.view addSubview:label];
        bjl_return label;
    });
    
    self.lossRateLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 1;
        label.font = [UIFont systemFontOfSize:fontSize];
        label.textColor = BJLIcTheme.viewTextColor;
        label.attributedText = [self packageLossRateAttributedString];
        [self.view addSubview:label];
        bjl_return label;
    });
    
    self.networkStatusLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 1;
        label.font = [UIFont systemFontOfSize:fontSize];
        label.attributedText = [self networkStatusAttributedString:[self networkStatusStringWithNetworkingStatus:BJLNetworkStatus_normal]];
        [self.view addSubview:label];
        bjl_return label;
    });
    
    [self.lossRateLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.equalTo(self.view);
        make.horizontal.hugging.compressionResistance.required();
        make.left.equalTo(self.view).offset(BJLIcAppearance.statusBarSpace);
    }];

    [self.networkStatusLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.equalTo(self.view);
        make.horizontal.hugging.compressionResistance.required();
        make.left.equalTo(self.lossRateLabel.bjl_right).offset(BJLIcAppearance.statusBarSpace);
    }];
    
    if (iPhone) {
        [self.timeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.bottom.equalTo(self.view);
            make.right.equalTo(self.classTitleLabel.bjl_left).offset(-BJLIcAppearance.statusBarSpace);
            make.left.equalTo(self.networkStatusLabel.bjl_right).offset(BJLIcAppearance.statusBarSpace);
        }];
        
        [self.classTitleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.top.bottom.equalTo(self.view);
            make.left.equalTo(self.timeLabel.bjl_right).offset(BJLIcAppearance.statusBarSpace);
            make.right.lessThanOrEqualTo(buttonArrM.lastObject.bjl_left ?: self.view).offset(-BJLIcAppearance.statusBarSpace);
        }];
    }
    else {
        UIView *view = [UIView new];
        [self.view addSubview:view];
        [view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.bottom.equalTo(self.view);
            make.centerX.equalTo(self.view).priorityHigh();
            make.left.greaterThanOrEqualTo(self.networkStatusLabel.bjl_right).offset(BJLIcAppearance.statusBarSpace);
            make.right.lessThanOrEqualTo(buttonArrM.lastObject.bjl_left ?: self.view).offset(-BJLIcAppearance.statusBarSpace);
        }];
        [self.timeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.height.equalTo(view);
            make.right.equalTo(self.classTitleLabel.bjl_left).offset(-BJLIcAppearance.statusBarSpace);
        }];
        [self.classTitleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.right.height.equalTo(view);
            make.left.equalTo(self.timeLabel.bjl_right).offset(BJLIcAppearance.statusBarSpace);
        }];
    }
}

#pragma mark - actions

// 更新上行丢包率和网络状况
- (void)updateUploadPackageLossRate:(CGFloat)packageLossRate networkStatus:(BJLNetworkStatus)status {
    self.upPackageLossRate = packageLossRate;
    self.upNetworkStatus = status;
    [self updateLoassRateAndNetworkStatus];
}

// 更新下行丢包率和网络状态
- (void)updateDownloadPackageLossRate:(CGFloat)packageLossRate networkStatus:(BJLNetworkStatus)status {
    self.downPackageLossRate = packageLossRate;
    self.downNetworkStatus = status;
    [self updateLoassRateAndNetworkStatus];
}

- (void)updateLoassRateAndNetworkStatus {
    // 不需要更新丢包时, 置为初始值--
    if ([self needNotUpdateStatus]) {
        self.maxPackageLossRate = -1;
        self.lossRateLabel.attributedText = [self packageLossRateAttributedString];
        self.networkStatusLabel.attributedText =  [self networkStatusAttributedString:[self networkStatusStringWithNetworkingStatus:BJLNetworkStatus_normal]];
        return;
    }
    // 上下行: 展示最差的丢包率的值
    BJLNetworkStatus status = BJLNetworkStatus_normal;
    CGFloat lossRate = 0.0;
    if (self.upPackageLossRate > self.downPackageLossRate) {
        status = self.upNetworkStatus;
        lossRate = self.upPackageLossRate;
    }
    else {
        status = self.downNetworkStatus;
        lossRate = self.downPackageLossRate;
    }
    
    NSString *networkStatusString = [self networkStatusStringWithNetworkingStatus:status];
    
    // 更新较差的 丢包率 & 网络状况
    if (lossRate != self.maxPackageLossRate) {
        self.maxPackageLossRate = lossRate;
        self.lossRateLabel.attributedText = [self packageLossRateAttributedString];
        self.networkStatusLabel.attributedText = [self networkStatusAttributedString:networkStatusString];
    }
}

#pragma mark - timer

- (void)startUpdateClassElapsedTimeTimer {
    [self stopUpdateClassElapsedTimeTimer];
    bjl_weakify(self);
    self.updateClassElapsedTimeTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify_ifNil(self) {
            [timer invalidate];
            return;
        }
        if (self.room.roomVM.classStartTimeMillisecond <= 0) {
//            return;
        }
        self.timeLabel.text = [self updateClassTimeString];
    }];
}

- (void)stopUpdateClassElapsedTimeTimer {
    if (self.updateClassElapsedTimeTimer || [self.updateClassElapsedTimeTimer isValid]) {
        [self.updateClassElapsedTimeTimer invalidate];
        self.updateClassElapsedTimeTimer = nil;
    }
}

/*
 1. 已到上课时间,老师未点击上课 -> `已延迟 xx:xx:xx` = now - startTime => realstartTime == startTime
 2. 老师已经开始上课 -> `已上课 xx:xx:xx` = now - realstartTime
 3. 未到上课时间,老师未点击上课 -> `距离上课 xx:xx:xx` = startTime - now => realstartTime == startTime
 4. 已下课(时间不清零,保持最后的上课时间) -> `已下课 xx:xx:xx` => realstartTime != startTime
    1) 在教室经历过从上课到下课的学生, 在下课状态能拿到上课的时间;
    2) 下课后再进教室的学生只能判断到已经下课, 无法拿到上课的时间,因为没有下课时间. 
 */
- (NSString *)updateClassTimeString {
    NSString *timeTextString = nil;
    NSString *timeString = @"00:00:00";
    NSTimeInterval time = 0;
    NSTimeInterval classStartRealTimeSecond = (self.room.roomVM.classStartTimeMillisecond <= 0
                                                ? self.room.roomInfo.startTimeMillisecond
                                                : self.room.roomVM.classStartTimeMillisecond) / 1000;
    NSTimeInterval classStartTimeSecond = self.room.roomInfo.startTimeInterval;
    self.timeLabel.textColor = BJLIcTheme.viewTextColor;
    
    if (self.room.roomVM.liveStarted) {
        time = BJLTimeIntervalSince1970() - classStartRealTimeSecond;
        self.classTimeString = [self elapsedTimeStringWithTimeInterval:time];
        timeString = self.classTimeString;
        timeTextString = @"已上课";
    }
    else if (classStartRealTimeSecond == classStartTimeSecond) {
        time = BJLTimeIntervalSince1970() - classStartTimeSecond;
        if (time > 0) {
            timeString = [self elapsedTimeStringWithTimeInterval:time];
            timeTextString = @"已延迟";
        }
        else {
            timeString = [self elapsedTimeStringWithTimeInterval:-time];
            timeTextString = @"距离上课";
        }
        self.timeLabel.textColor = BJLIcTheme.warningColor;
    }
    else {
        timeString = self.classTimeString;
        timeTextString = @"已下课";
    }
    return [NSString stringWithFormat:@"%@ %@", timeTextString, timeString];
}

#pragma mark - wheel

- (nullable NSAttributedString *)packageLossRateAttributedString {
    NSString *preString = @"丢包率: ";
    NSString *lossRateString = [NSString stringWithFormat:@"%.0f%%", self.maxPackageLossRate];
    if ([self needNotUpdateStatus]) {
        lossRateString = @"--";
    }
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] init];
    NSAttributedString *preAttributedString = [[NSAttributedString alloc] initWithString:preString
                                                                              attributes:@{NSForegroundColorAttributeName : BJLIcTheme.viewTextColor}];
    
    NSAttributedString *lossRateAttributedString = [[NSAttributedString alloc] initWithString:lossRateString
                                                                                   attributes:@{NSForegroundColorAttributeName : [self colorWithLossRateString:lossRateString]}];
    
    [mutableAttributedString appendAttributedString:preAttributedString];
    [mutableAttributedString appendAttributedString:lossRateAttributedString];
    
    return mutableAttributedString;
}

- (nullable NSAttributedString *)networkStatusAttributedString:(NSString *)networkStatusString {
    NSString *preString = @"网络状况: ";
    if ([self needNotUpdateStatus]) {
        networkStatusString = @"--";
    }
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] init];
    NSAttributedString *preAttributedString = [[NSAttributedString alloc] initWithString:preString
                                                                              attributes:@{NSForegroundColorAttributeName : BJLIcTheme.viewTextColor}];
    
    NSAttributedString *networkStatusAttributedString = [[NSAttributedString alloc] initWithString:networkStatusString
                                                                                        attributes:@{NSForegroundColorAttributeName : [self colorWithNetworkStatusString:networkStatusString]}];
    
    [mutableAttributedString appendAttributedString:preAttributedString];
    [mutableAttributedString appendAttributedString:networkStatusAttributedString];
    
    return mutableAttributedString;
}

- (NSString *)networkStatusStringWithNetworkingStatus:(BJLNetworkStatus)status {
    NSString *networkStatusString = @"优秀";
    switch (status) {
        case BJLNetworkStatus_normal:
            networkStatusString = @"优秀";
            break;
            
        case BJLNetworkStatus_Bad_level1:
            networkStatusString = @"良好";
            break;
            
        case BJLNetworkStatus_Bad_level2:
            networkStatusString = @"差";
            break;
            
        case BJLNetworkStatus_Bad_level3:
        case BJLNetworkStatus_Bad_level4:
        case BJLNetworkStatus_Bad_level5:
            networkStatusString = @"极差";
            break;
            
        default:
            break;
    }
    return networkStatusString;
}

- (UIColor *)colorWithNetworkStatusString:(NSString *)networkStatusString {
    if ([self needNotUpdateStatus]) {
        return BJLIcTheme.viewTextColor;
    }
    if ([networkStatusString isEqualToString:@"优秀"]) {
        return [UIColor bjl_colorWithHexString:@"#2CDB87" alpha:1.0];
    }
    else if ([networkStatusString isEqualToString:@"良好"]) {
        return [UIColor bjl_colorWithHexString:@"#1199FF" alpha:1.0];
    }
    else if ([networkStatusString isEqualToString:@"差"]) {
        return [UIColor bjl_colorWithHexString:@"#FFBB33" alpha:1.0];
    }
    else if ([networkStatusString isEqualToString:@"极差"]) {
        return [UIColor bjl_colorWithHexString:@"#FF0000" alpha:1.0];
    }
    else {
        return BJLIcTheme.viewTextColor;
    }
}

- (UIColor *)colorWithLossRateString:(NSString *)lossRateString {
    return BJLIcTheme.viewTextColor;
}

- (NSString *)elapsedTimeStringWithTimeInterval:(NSTimeInterval)timeInterval {
    NSInteger elapsedTime = round(timeInterval);
    NSInteger second = elapsedTime % 60;
    NSInteger minute = (elapsedTime / 60) % 60;
    NSInteger hour = elapsedTime / 3600;
    NSString *secondString = second >= 10 ? [NSString stringWithFormat:@"%ld", (long)second] : [NSString stringWithFormat:@"0%ld", (long)second];
    NSString *minuteString = minute >= 10 ? [NSString stringWithFormat:@"%ld", (long)minute] : [NSString stringWithFormat:@"0%ld", (long)minute];
    NSString *hourString = hour >= 10 ? [NSString stringWithFormat:@"%ld", (long)hour] : [NSString stringWithFormat:@"0%ld", (long)hour];
    return [NSString stringWithFormat:@"%@:%@:%@", hourString, minuteString, secondString];
}

- (BOOL)needNotUpdateStatus {
    return (!self.room.playingVM.playingUsers.count
            || self.room.state != BJLRoomState_connected
            || !self.room.roomVM.liveStarted);
}

@end

NS_ASSUME_NONNULL_END
