//
//  BJLScSpeakRequestUsersViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/24.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLTableViewController.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScSpeakRequestUsersViewController : BJLTableViewController

@property (nonatomic, nullable) void (^agreeSpeakingRequestCallback)(void);

- (instancetype)initWithRoom:(BJLRoom *)room;

@end

NS_ASSUME_NONNULL_END
