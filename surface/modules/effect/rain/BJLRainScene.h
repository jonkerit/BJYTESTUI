//
//  BJLRainScene.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/7/2.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^BJLOpenEnvelopeScoreCompletion)(NSInteger);

@interface BJLRainScene : SKScene

+ (instancetype)sceneWithSize:(CGSize)size
                rainImageName:(NSString *)rainImageName
                    rainCount:(NSInteger)rainCount
                     rainSize:(CGSize)rainSize
                  visibleSize:(CGSize)visibleSize;

#pragma mark - for red envelope rain

// set these property before the time you open envelope
@property (nonatomic) NSMutableArray<NSString *> *coinImageNames;
@property (nonatomic) void (^requestOpenEnvelopeScoreCallback)(BJLOpenEnvelopeScoreCompletion);
@property (nonatomic) NSInteger totalScore;
@property (nonatomic) NSInteger totalHitCount, scoreHitCount, totalNodeCount;

@end

NS_ASSUME_NONNULL_END
