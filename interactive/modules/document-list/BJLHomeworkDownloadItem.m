//
//  BJLHomeworkDownloadItem.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/9/1.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLiveCore.h>
#import <BJLiveBase/BJLDownloadItem+subclass.h>

#import "BJLHomeworkDownloadItem.h"

@interface BJLHomeworkDownloadItem () <BJLDownloadItem>

@end

@implementation BJLHomeworkDownloadItem

#pragma mark - <BJLDownloadItem>

- (void)requestDownloadFilesWithCompletion:(void (NS_NOESCAPE ^)(NSArray<BJLDownloadFile *> * _Nullable downloadFiles, NSError * _Nullable error))completion {    
    if (!self.sourceURL) {
        completion(nil, BJLErrorMake(BJLErrorCode_invalidArguments, @"下载地址不可为空"));
    }
    
    NSArray *downloadFiles = @[[BJLDownloadFile fileWithSourceURL:self.sourceURL expectedFileSize:0]];
    completion(downloadFiles, nil);
    [self resume];
}

#pragma mark - <YYModel>

+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    Class superClass = [self superclass];
    NSMutableDictionary<NSString *, id> *mapper = ([superClass respondsToSelector:_cmd]
                                                   ? [[superClass modelCustomPropertyMapper] mutableCopy]
                                                   : [NSMutableDictionary new]);
    
    //                                  key: property-name                                                  value: info.plist-key, DONOT change
    [mapper addEntriesFromDictionary:@{
                                        BJLInstanceKeypath(BJLHomeworkDownloadItem, sourceURL):                 @"sourceURL",
                                        BJLInstanceKeypath(BJLHomeworkDownloadItem, homework):                  @"homework",
                                        BJLInstanceKeypath(BJLHomeworkDownloadItem, downloadTimeInterval):      @"downloadTimeInterval",
                                        BJLInstanceKeypath(BJLHomeworkDownloadItem, roomName):                  @"roomName",
                                        BJLInstanceKeypath(BJLHomeworkDownloadItem, roomID):                    @"roomID",
                                        }];
    return mapper;
}

@end
