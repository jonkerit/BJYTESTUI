//
//  BJLIcBlackboardLayoutViewController+WritingBoard.h
//  BJLiveCore
//
//  Created by 凡义 on 2019/3/22.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcBlackboardLayoutViewController (WritingBoard)

- (void)makeObserversForWritingBoard;

/** 作答中的老师窗口, 关闭时要同时发收回小黑板信令 */
- (void)closeWritingBoardWithGatherRequest;

/** 老师小黑板窗口时间输入的回调事件 */
- (void)setWritingBoardTime:(NSString *)text;

- (NSString *)keyForWritingBoard:(NSString *)boardID pageIndex:(NSInteger)pageIndex userNumber:(NSString *)userNumber;

- (__kindof UIViewController *)displayWritingBoardWindowWith:(BJLWritingBoard *)writingBoard
                                                  userNumber:(NSString *)userNumber
                                               requestUpdate:(BOOL)requestUpdate;

- (void)closeDisplayingWritingBoardWindowWithID:(NSString *)documentID
                                      pageIndex:(NSInteger)pageIndex
                                     userNumber:(NSString *)userNumber
                                  requestUpdate:(BOOL)requestUpdate;

- (void)closeDisplayingWritingBoardWindowsWithRequestUpdate:(BOOL)requestUpdate;

@end

NS_ASSUME_NONNULL_END
