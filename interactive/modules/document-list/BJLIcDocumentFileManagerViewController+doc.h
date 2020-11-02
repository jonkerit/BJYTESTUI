//
//  BJLIcDocumentFileManagerViewController+doc.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/8/29.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcDocumentFileManagerViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDocumentFileManagerViewController (doc)

- (void)makeObservingForDoc;

- (void)loadAllRemoteDocuments:(NSArray<BJLDocument *> *)documents;

- (void)makeDocumentChooseView;

- (void)uploadDocumentFile:(BJLDocumentFile *)documentFile;

- (void)deleteSelectedDocumentFile:(BJLDocumentFile *)file;

@end

NS_ASSUME_NONNULL_END
