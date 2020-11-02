//
//  BJLScShapeSelectView.h
//  BJLiveUI
//
//  Created by xyp on 2020/8/24.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLScDrawSelectionBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScShapeSelectView : BJLScDrawSelectionBaseView

- (NSString *)shapeOptionKeyWithType:(BJLDrawingShapeType)shapeType filled:(BOOL)filled;

- (CGSize)expectedSize;
- (void)reloadLayout;

@end

NS_ASSUME_NONNULL_END
