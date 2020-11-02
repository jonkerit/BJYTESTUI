//
//  BJLScTextFontCell.h
//  BJLiveUI
//
//  Created by xyp on 2020/8/19.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScTextFontCell : UITableViewCell

@property (nonatomic, nullable, copy) void (^selectCallback)(BOOL selected);

- (void)updateContentWithFont:(NSInteger)font selected:(BOOL)selected;

@end

NS_ASSUME_NONNULL_END
