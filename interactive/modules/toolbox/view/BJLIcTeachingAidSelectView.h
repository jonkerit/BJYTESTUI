//
//  BJLIcTeachingAidSelectView.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/6/4.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcDrawSelectionBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcTeachingAidOptionCell : UICollectionViewCell

@end

@interface BJLIcTeachingAidSelectView : BJLIcDrawSelectionBaseView

// 打开网页
@property (nonatomic) void(^openWebViewCallback)(void);

// 小黑板
@property (nonatomic) void(^clickWritingBoardCallback)(void);

// 答题器
@property (nonatomic) void(^questionAnswerCallback)(void);

// 抢答题
@property (nonatomic) void(^questionResponderCallback)(void);

// 计时器
@property (nonatomic) void(^countDownCallback)(void);

@end

NS_ASSUME_NONNULL_END
