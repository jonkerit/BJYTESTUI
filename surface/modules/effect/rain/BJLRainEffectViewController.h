//
//  BJLRainEffectViewController.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/7/2.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BJLViewControllerImports.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLRainEffectViewController : UIViewController <
UITableViewDataSource,
UITableViewDelegate,
BJLRoomChildViewController>

@property (nonatomic, readonly) NSInteger envelopeID;

/**
 envelope rain
 #param room BJLRoom
 #param envelopeID envelopeID
 #param duration rain duration
 #return self
 */
- (instancetype)initWithRoom:(BJLRoom *)room envelopeID:(NSInteger)envelopeID duration:(NSInteger)duration;

/**
 rain effect scene
 #param size scene size, often equal to view controller view size
 #param imageName the name or path of the image to show rain
 #param count rain count in the scene, normaly nearly to this count
 #param rainSize rain size in the scene, scale [0.8 1.2]
 */
- (void)setupRainEffectSize:(CGSize)size rainImageName:(nullable NSString *)imageName rainCount:(NSInteger)count rainSize:(CGSize)rainSize;

/**
 open red envelope
 #discussion set these property after init
 #param imageName the name or path of the image to load when open no empty envelope
 #param emptyImageName the name or path of the image to load when open a empty envelope
 #param size size
 #param emptySize emptySize
 */
- (void)setOpenEnvelopeImageName:(nullable NSString *)imageName emptyImageName:(nullable NSString *)emptyImageName size:(CGSize)size emptySize:(CGSize)emptySize;

/** remove rain and show result */
- (void)removeRainScene;

- (void)didReceiveRankList:(NSArray<BJLEnvelopeRank *> *)rankList;
@end

NS_ASSUME_NONNULL_END
