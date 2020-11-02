//
//  BJLScLotteryUserCell.h
//  BJLiveUI
//
//  Created by xyp on 2020/8/27.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScLotteryUserCell : UITableViewCell

- (void)updateWithUserName:(NSString *)userName prizeName:(NSString *)prizeName;

@end

NS_ASSUME_NONNULL_END
