//
//  BJLScQuestionViewController+data.h
//  BJLiveUI
//
//  Created by xyp on 2020/9/28.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLScQuestionViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScQuestionViewController (data)

// 第一次进入页面时候的网络请求
- (void)firstRequestRefreshPage;

- (void)scrollToTheEndTableView;
- (void)updateUnreadMessagesTipButtonHidden:(BOOL)hidden;
- (BOOL)atTheBottomOfTableView;

- (void)makeObserving;
- (void)updateListWithSegmentIndex:(NSInteger)segmentIndex;

@end

NS_ASSUME_NONNULL_END
