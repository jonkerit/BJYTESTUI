//
//  BJLIcDocumentFileManagerViewController+cloud.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/9/9.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcDocumentFileManagerViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDocumentFileManagerViewController (cloud)

- (void)loadAllRemoteCloudDocuments;

- (void)uploadCloudDocumentFile:(BJLDocumentFile *)documentFile;

- (void)updateTranscodeCloudListWithDocumentFile:(BJLDocumentFile *)documentFile;

- (void)deleteSelectedCloudDocumentFile:(BJLDocumentFile *)file;

- (void)syncAndOpenCloudDocumentFile:(BJLDocumentFile *)file;

@end

NS_ASSUME_NONNULL_END
