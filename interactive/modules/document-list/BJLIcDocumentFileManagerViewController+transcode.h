//
//  BJLIcDocumentFileManagerViewController+transcode.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/8/28.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcDocumentFileManagerViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDocumentFileManagerViewController (transcode)

- (void)startPollTimer;
- (void)stopPollTimer;

// 远端文档转码完成
- (void)finishUpdateDocumentFileWithFileID:(NSString *)fileID;

// 更新上传和转码进度
- (void)updateDocumentFileWithLocalID:(nullable NSString *)localID
                               fileID:(nullable NSString *)fileID
                             progress:(CGFloat)progress
                            errorCode:(NSInteger)errorCode;
@end

NS_ASSUME_NONNULL_END
