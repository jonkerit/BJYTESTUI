//
//  BJLScStrokeColorSelectView.h
//  BJLiveUI
//
//  Created by xyp on 2020/8/24.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLScDrawSelectionBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScStrokeColorSelectView : BJLScDrawSelectionBaseView

@property (nonatomic) NSString *strokeColor;

- (void)reloadLayout;

@end

NS_ASSUME_NONNULL_END
