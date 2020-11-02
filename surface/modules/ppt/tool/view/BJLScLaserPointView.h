//
//  BJLScLaserPointView.h
//  BJLiveUI
//
//  Created by xyp on 2020/8/26.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScLaserPointView : UIView

@property (nonatomic) NSString *documentID;
@property (nonatomic) NSInteger pageIndex;

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

- (void)updateShapeShowSize:(CGSize)size;

- (void)hideLaserPoint;

@end

NS_ASSUME_NONNULL_END
