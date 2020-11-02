//
//  BJLHomeworkDownloadItem.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/9/1.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLDownloadItem.h"
#import <BJLiveCore/BJLHomework.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLHomeworkDownloadItem : BJLDownloadItem

@property (nonatomic, nullable) NSURL *sourceURL;

/** 作业信息 */
@property (nonatomic, nullable) BJLHomework *homework;
@property (nonatomic, assign) NSTimeInterval downloadTimeInterval;
@property (nonatomic, copy, nullable) NSString *roomName, *roomID;

@end

NS_ASSUME_NONNULL_END
