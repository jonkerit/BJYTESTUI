//
//  BJLIcUserHeaderView.h
//  BJLiveUI
//
//  Created by 辛亚鹏 on 2020/6/10.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLIcUserHeaderType) {
    BJLIcUserHeaderTypeOnStage,      // 台上成员的header
    BJLIcUserHeaderTypeDownStage,    // 台下成员的header
    BJLIcUserHeaderTypeBlockedUser,  // 黑名单的header
};

@interface BJLIcUserHeaderView : UIView

- (instancetype)initWithHeaderTppe:(BJLIcUserHeaderType)type;

@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) BOOL isExpand;

/// 展开的回调
@property (nonatomic, nullable) void (^expandCallback)(void);

/// 只有当type == BJLIcUserHeaderTypeBlockedUser, freeBlockedUserButton 和 freeBlockedCallback 才有值
@property (nonatomic, readonly) UIButton *freeBlockedUserButton;
@property (nonatomic, nullable) void (^freeBlockedCallback)(void);

- (void)updateExpand:(BOOL)isExpand;

@end

NS_ASSUME_NONNULL_END
