//
//  BJLIcSettingView.h
//  BJLiveUI
//
//  Created by 辛亚鹏 on 2020/4/23.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcSettingView : UIView

- (instancetype)initWithRoom:(BJLRoom *)room;

@property (nonatomic, nullable) void (^switchMirrorModeCallback)(BOOL isOn);
@property (nonatomic, nullable) void (^pptQualityChangeCallback)(BOOL isOriginal, BJLIcSettingView *settingView);
@property (nonatomic, nullable) void (^closeCallback)(void);

- (void)updateButtonStateWhenError;

@end

NS_ASSUME_NONNULL_END
