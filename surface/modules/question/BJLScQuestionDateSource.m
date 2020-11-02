//
//  BJLScQuestionDateSource.m
//  BJLiveUI
//
//  Created by xyp on 2020/9/28.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLScQuestionDateSource.h"

@interface BJLScQuestionDateSource ()

@property (nonatomic, readwrite) BJLQuestionState state;
@property (nonatomic, readwrite) BOOL isSelf;
@property (nonatomic, readonly, weak) BJLRoom *room;

@end

NSInteger const perPageQuestionCount = 10;

@implementation BJLScQuestionDateSource

- (instancetype)initWithRoom:(BJLRoom *)room state:(BJLQuestionState)state isSelf:(BOOL)isSelf {
    self = [super init];
    if (self) {
        self.questionList = [NSMutableArray array];
        self.currentQuestionPage = 0;
        self.totalQuestionPage = 0;
        self.loadLatestQuestion = NO;
        self.state = state;
        self->_room = room;
        self.isSelf = isSelf;
    }
    return self;
}

- (nullable NSError *)requestQuestionHistory {
    return [self.room.roomVM loadQuestionHistoryWithPage:self.currentQuestionPage countPerPage:perPageQuestionCount state:self.state isSelf:self.isSelf];
}

- (void)checkLoadLatestQuestionWithHistory:(NSArray<BJLQuestion *> *)history currentPage:(NSInteger)currentPage totalPage:(NSInteger)totalPage {
    self.currentQuestionPage = currentPage;
    if (!self.loadLatestQuestion) {
        self.loadLatestQuestion = YES;
        self.currentQuestionPage = totalPage;
        [self requestQuestionHistory];
    }
    else {
        [self updateQuestionListWithQuestions:history];
    }
}

- (void)updateQuestionListWithQuestion:(BJLQuestion *)question {
    // 先删除已经存在的, 再添加, 便于排序
    for (BJLQuestion *oldQuestion in [self.questionList copy]) {
        if ([oldQuestion.ID isEqualToString:question.ID]) {
            [self.questionList removeObject:question];
            break;
        }
    }
    [self updateQuestionListWithPublishQuestion:question];
}

#pragma mark -

- (void)updateQuestionListWithQuestions:(NSArray<BJLQuestion *> *)questions {
    // !!! 更新问答
    for (BJLQuestion *newQuestion in [questions copy]) {

        // 先删除已经存在的, 如果remove为NO, 则表示需要重新排序后插入
        for (BJLQuestion *oldQuestion in [self.questionList copy]) {
            if ([oldQuestion.ID isEqualToString:newQuestion.ID]) {
                [self.questionList removeObject:oldQuestion];
                break;
            }
        }
        // 优先根据问答的最后更新时间 lastTime 正序排列, 如果时间相同,则根据 ID 正序排列
        [self updateQuestionListWithPublishQuestion:newQuestion];
    }
}

// 排序
- (void)updateQuestionListWithPublishQuestion:(BJLQuestion *)question {
    // !!! 根据发布的新问答更新问答列表，发布的问答可能不是最新的问答，老师和助教在问答发送时就获得了问答，处理更新逻辑
    BOOL insertQuestion = NO;
    for (BJLQuestion *oldQuestion in [self.questionList copy]) {
        // 优先根据问答的最后更新时间 lastTime 正序排列, 如果时间相同,则根据 ID 正序排列
        if (question.lastTime < oldQuestion.lastTime) {
            NSInteger index = [self.questionList indexOfObject:oldQuestion];
            [self.questionList bjl_insertObject:question atIndex:index];
            insertQuestion = YES;
            break;
        }
        else if (question.lastTime == oldQuestion.lastTime) {
            // 插入到第一个比新发布的问答序号大的前面
            if ([question.ID integerValue] < [oldQuestion.ID integerValue]) {
                NSInteger index = [self.questionList indexOfObject:oldQuestion];
                [self.questionList bjl_insertObject:question atIndex:index];
                insertQuestion = YES;
                break;
            }
        }
    }
    if (!insertQuestion) {
        // 如果没有直接添加到末尾
        [self.questionList bjl_addObject:question];
    }
}

@end
