//
//  BJLScQuestionDateSource.h
//  BJLiveUI
//
//  Created by xyp on 2020/9/28.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSInteger const perPageQuestionCount;

@interface BJLScQuestionDateSource : NSObject

- (instancetype)initWithRoom:(BJLRoom *)room state:(BJLQuestionState)state isSelf:(BOOL)isSelf;

@property (nonatomic) NSMutableArray<BJLQuestion *> *questionList;
@property (nonatomic) NSInteger totalQuestionPage;
@property (nonatomic) NSInteger currentQuestionPage;
@property (nonatomic) BOOL loadLatestQuestion; // UI 展示最后一页问答数据
@property (nonatomic, readonly) BJLQuestionState state;
@property (nonatomic, readonly) BOOL isSelf;

- (nullable NSError *)requestQuestionHistory;
- (void)checkLoadLatestQuestionWithHistory:(NSArray<BJLQuestion *> *)history currentPage:(NSInteger)currentPage totalPage:(NSInteger)totalPage;
- (void)updateQuestionListWithQuestion:(BJLQuestion *)question;

@end

NS_ASSUME_NONNULL_END
