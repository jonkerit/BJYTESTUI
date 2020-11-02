//
//  BJLScMessageOperatorView.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/2/21.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLRecallType) {
    BJLRecallTypeNone,
    BJLRecallTypeNormal,
    BJLRecallTypeDelete,
};

@interface BJLScMessageOperatorView : UIView

- (instancetype)initWithNeedTranslate:(BOOL)needTranslate
needShowOnlyTeacherOrAssistant:(BOOL)needShowOnlyTeacherOrAssistant
                    recallType:(BJLRecallType)recallType
              canStickyMessage:(BOOL)canStickyMessage
                      isSticky:(BOOL)isSticky;

- (void)updateButtonConstraints;

@property (nonatomic, nullable) void (^onClikCopyCallback)(BOOL on);
@property (nonatomic, nullable) void (^onClikTranslateCallback)(BOOL on);
@property (nonatomic, nullable) void (^onlyShowTeacherORAssistantMessageCallback)(BOOL on);
@property (nonatomic, nullable) void (^recallMessageCallback)(BOOL on);
// YES: 置顶;  NO: 取消置顶
@property (nonatomic, nullable) void (^stickyMessageCallback)(BOOL on);

@end

NS_ASSUME_NONNULL_END
