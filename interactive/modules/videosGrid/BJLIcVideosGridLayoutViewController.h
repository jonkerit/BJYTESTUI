//
//  BJLIcVideosGridLayoutViewController.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcUserMediaInfoView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcVideosGridLayoutViewController : UICollectionViewController

- (instancetype)initWithRoom:(BJLRoom *)room;

- (void)updateWithUserMediaInfoViews:(nullable NSArray<BJLIcUserMediaInfoView *> *)mediaInfoViews;

- (void)updateActive:(BOOL)active;

@end

NS_ASSUME_NONNULL_END
