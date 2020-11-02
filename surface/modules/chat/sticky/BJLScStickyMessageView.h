//
//  BJLScStickyMessageView.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/4/2.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScStickyMessageView : UIView

@property (nonatomic, nullable) void (^cancelStickyCallback)(BJLMessage *message);
@property (nonatomic, nullable) void (^updateConstraintsCallback)(BOOL showcompleteMessage);
@property (nonatomic, nullable) BOOL (^linkURLCallback)(NSURL *url);
@property (nonatomic, nullable) void (^imageSelectCallback)(BJLMessage * _Nullable message);

@property (nonatomic) BOOL showCompleteMessage;

- (instancetype)initWithMessageList:(nullable NSArray <BJLMessage *> *)messageList room:(BJLRoom *)room;
- (void)updateStickyMessageList:(nullable NSArray <BJLMessage *> *)messageList;
- (void)resetStickyMessageView;

@end

NS_ASSUME_NONNULL_END
