//
//  BJLIcDocumentFileManagerViewController+homework.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/8/26.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcDocumentFileManagerViewController.h"
#import "BJLHomeworkDownloadItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDocumentFileManagerViewController (homework)

- (void)makeObservingForHomework;
- (void)makeDocumentFileViewCallback;
- (void)showHomeWorkPickerViewController;

- (void)loadAllRemoteHomeworks:(NSArray<BJLHomework *> *)homeworks;
- (void)uploadHomeWorkFile:(BJLDocumentFile *)documentFile;

- (void)syncAndOpenHomeworkDocumentFile:(BJLDocumentFile *)file;
- (void)deleteSelectedHomework:(BJLDocumentFile *)file;
- (void)downloadActionWithHomeworkFile:(BJLDocumentFile *)file withRect:(CGRect)rectForOpenInIpad;
- (nullable BJLHomeworkDownloadItem *)localDownloadItemWithHomeworkFile:(BJLDocumentFile *)file;

@end

NS_ASSUME_NONNULL_END
