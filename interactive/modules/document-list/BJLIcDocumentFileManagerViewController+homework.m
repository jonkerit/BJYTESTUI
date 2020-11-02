//
//  BJLIcDocumentFileManagerViewController+homework.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/8/26.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcDocumentFileManagerViewController+homework.h"
#import "BJLIcDocumentFileManagerViewController+private.h"
#import "BJLIcPopoverViewController.h"

@implementation BJLIcDocumentFileManagerViewController (homework)

#pragma mark - Observing

- (void)makeObservingForHomework {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.homeworkVM, allHomeworksDidOverwrite:)
             observer:^BOOL(NSArray<BJLHomework *> *homeworks) {
        bjl_strongify(self);
        [self loadAllRemoteHomeworks:self.room.homeworkVM.allHomeworks];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.homeworkVM, didAddHomeworks:)
             observer:^BOOL(NSArray<BJLHomework *> *homeworks) {
        bjl_strongify(self);
        [self updateHomeWorksListWithHomeWorks:homeworks];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.homeworkVM, didDeleteHomework:)
             observer:^BOOL(BJLHomework *homework) {
        bjl_strongify(self);
        [self deleteHomework:homework];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.homeworkVM, didReceiveHomeworkSearchResultWithKeyword:list:hasmore:)
             observer:(BJLMethodObserver)^BOOL(NSString *keyword, NSArray<BJLHomework *> * _Nullable homeworks, BOOL hasmore) {
        bjl_strongify(self);
        if (self.documentFileLayoutType != BJLIcDocumentFileLayoutTypeHomework
            || ![self.documentFileView.searchTextField.text isEqualToString:keyword]) {
            return YES;
        }
        self.hasmore = hasmore;
        // 30 秒后变成 YES 允许上层再次尝试加载
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetHasMore) object:nil];
        if (!self.hasmore) {
            [self performSelector:@selector(resetHasMore) withObject:nil afterDelay:30.0];
        }
        
        self.homeworkCursor = homeworks.lastObject;
        [self updateSearchResultListWithHomeWorks:homeworks];
        return YES;
    }];    
}

- (void)loadAllRemoteHomeworks:(NSArray<BJLHomework *> *)homeworks {
    [self.mutableHomeworkFileList removeAllObjects];
    
    for (BJLHomework *homework in homeworks) {
        BJLDocumentFile *documentFile = [[BJLDocumentFile alloc] initWithRemoteHomework:homework];
        [self.mutableHomeworkFileList bjl_addObject:documentFile];
    }
    
    [self removeFromTranscodeHomeWorksListWithHomeWorks:homeworks];
    [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeHomework];
}

- (void)deleteHomework:(BJLHomework *)homework {
    BJLDocumentFile *documentFile = [self homeworkFileWithHomeworkID:homework.homeworkID];
    if (documentFile) {
        [self.mutableHomeworkFileList bjl_removeObject:documentFile];
    }
    
    [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeHomework];
}

- (void)updateHomeWorksListWithHomeWorks:(NSArray<BJLHomework *> *)homeworks {
    for (BJLHomework * homework in homeworks) {
        BJLDocumentFile *homeworkFile = [[BJLDocumentFile alloc] initWithRemoteHomework:homework];
        BJLDocumentFile *changedFile = [self homeworkFileWithHomeworkID:homework.homeworkID];
        // file 发生改变
        if (changedFile) {
            // 转码完成前没有办法判断是否是动态PPT，因此根据本地上传文档来判断
            homeworkFile.type = changedFile.type;
            homeworkFile.localPathURL = changedFile.localPathURL;
            [self.mutableHomeworkFileList removeObject:changedFile];
        }
        [self.mutableHomeworkFileList bjl_addObject:homeworkFile];
    }
    
    NSMutableArray <BJLDocumentFile *> *relatedHomeworkFileList = [NSMutableArray new];
    NSMutableArray <BJLDocumentFile *> *teachersHomeworkFileList = [NSMutableArray new];
    NSMutableArray <BJLDocumentFile *> *studentHomeworkFileList = [NSMutableArray new];
    for (BJLDocumentFile *file in [self.mutableHomeworkFileList copy]) {
        if (file.remoteHomework.isRelatedFile) {
            [relatedHomeworkFileList bjl_addObject:file];
        }
        else if (file.remoteHomework.fromUserRole != BJLUserRole_student) {
            [teachersHomeworkFileList bjl_addObject:file];
        }
        else {
            [studentHomeworkFileList bjl_addObject:file];
        }
    }
    [relatedHomeworkFileList sortUsingComparator:^NSComparisonResult(BJLDocumentFile *obj1, BJLDocumentFile *obj2) {
        NSNumber *homework1ID = [NSNumber numberWithInteger:obj1.remoteHomework.homeworkID.integerValue];
        NSNumber *homework2ID = [NSNumber numberWithInteger:obj2.remoteHomework.homeworkID.integerValue];
        NSComparisonResult result =[homework1ID compare:homework2ID];
        return result;
    }];
    [teachersHomeworkFileList sortUsingComparator:^NSComparisonResult(BJLDocumentFile *obj1, BJLDocumentFile *obj2) {
        NSNumber *homework1ID = [NSNumber numberWithInteger:obj1.remoteHomework.homeworkID.integerValue];
        NSNumber *homework2ID = [NSNumber numberWithInteger:obj2.remoteHomework.homeworkID.integerValue];
        NSComparisonResult result =[homework1ID compare:homework2ID];
        return result;
    }];
    [studentHomeworkFileList sortUsingComparator:^NSComparisonResult(BJLDocumentFile *obj1, BJLDocumentFile *obj2) {
        NSNumber *homework1ID = [NSNumber numberWithInteger:obj1.remoteHomework.homeworkID.integerValue];
        NSNumber *homework2ID = [NSNumber numberWithInteger:obj2.remoteHomework.homeworkID.integerValue];
        NSComparisonResult result =[homework1ID compare:homework2ID];
        return result;
    }];
    NSMutableArray *mutableHomeworkFileList = [NSMutableArray new];
    if ([relatedHomeworkFileList count]) {
        [mutableHomeworkFileList addObjectsFromArray:[relatedHomeworkFileList copy]];
    }
    if ([teachersHomeworkFileList count]) {
        [mutableHomeworkFileList addObjectsFromArray:[teachersHomeworkFileList copy]];
    }
    if ([studentHomeworkFileList count]) {
        [mutableHomeworkFileList addObjectsFromArray:[studentHomeworkFileList copy]];
    }
    
    self.mutableHomeworkFileList = mutableHomeworkFileList;
    
    [self removeFromTranscodeHomeWorksListWithHomeWorks:homeworks];
    [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeHomework];
}

// 收到信令, 过滤本地上传转码的作业list
- (void)removeFromTranscodeHomeWorksListWithHomeWorks:(NSArray<BJLHomework *> *)homeworks {
    if (![homeworks count]) {
        return;
    }
    NSMutableArray<BJLDocumentFile *> *mutableTranscodeHomeworkFileList = [self.mutableTranscodeHomeworkFileList mutableCopy];
    for (BJLHomework *homework in homeworks) {
        [self.mutableTranscodeHomeworkFileList enumerateObjectsUsingBlock:^(BJLDocumentFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.remoteHomework.homeworkID isEqualToString:homework.homeworkID]) {
                [mutableTranscodeHomeworkFileList bjl_removeObject:obj];
                *stop = YES;
            }
        }];
    }
    self.mutableTranscodeHomeworkFileList = [mutableTranscodeHomeworkFileList mutableCopy];
}

- (void)updateSearchResultListWithHomeWorks:(NSArray<BJLHomework *> *)homeworks {
    for (BJLHomework * homework in homeworks) {
        BJLDocumentFile *homeworkFile = [[BJLDocumentFile alloc] initWithRemoteHomework:homework];
        BJLDocumentFile *changedFile = nil;
        for (BJLDocumentFile *documentFile in [self.mutableHomeworkSearchResultFileList copy]) {
            if (homework.homeworkID.length && [documentFile.remoteHomework.homeworkID isEqualToString:homework.homeworkID]) {
                changedFile = documentFile;
                break;
            }
        }
        
        // file 发生改变
        if (changedFile) {
            // 转码完成前没有办法判断是否是动态PPT，因此根据本地上传文档来判断
            homeworkFile.type = changedFile.type;
            homeworkFile.localPathURL = changedFile.localPathURL;
            [self.mutableHomeworkSearchResultFileList removeObject:changedFile];
        }
        [self.mutableHomeworkSearchResultFileList bjl_addObject:homeworkFile];
    }
    
    [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeHomework];
}

- (void)resetHasMore {
    self.hasmore = YES;
}

#pragma mark - callback

- (void)makeDocumentFileViewCallback {
    bjl_weakify(self);
    
    [self.documentFileView setAllowStudentUploadFileCallback:^(BOOL allow) {
        bjl_strongify(self);
        BJLError *error = [self.room.homeworkVM requestAllowStudentUploadHomework:allow];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
        }
    }];
    
    [self.documentFileView setSwitchToHomeworkCallback:^{
        bjl_strongify(self);
        if (!self.room.loginUser.isTeacherOrAssistant) {
            return;
        }
        if (!self.room.homeworkVM.allStudentsSupportHomework && self.shouldShowHomeworkSupportView) {
            BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcSupportHomework message:nil];
            [self bjl_addChildViewController:popoverViewController superview:self.view];
            [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.view);
            }];
            bjl_weakify(self);
            [popoverViewController setCancelCallback:^{
                bjl_strongify(self);
                self.shouldShowHomeworkSupportView = NO;
            }];
        }
    }];
}

- (void)showHomeWorkPickerViewController {
    if (@available(iOS 11.0, *)) {
        // open 仅限于打开自己的文件, import 可以导入共享的文件
        NSArray *array = @[@"public.data"];
        UIDocumentPickerViewController* vc = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:array
                                                                                                    inMode:UIDocumentPickerModeImport];
        vc.delegate = self;
        vc.allowsMultipleSelection = NO;
        if (@available(iOS 13.0, *)) {
            vc.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        }
        if (self.presentedViewController) {
            [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
        }
        [self bjl_presentFullScreenViewController:vc animated:YES completion:nil];
    }
    else {
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(@"当前系统版本不支持，请升级到11.0以上版本");
        }
    }
}

#pragma mark - action

- (void)syncAndOpenHomeworkDocumentFile:(BJLDocumentFile *)homeworkFile {
    bjl_weakify(self);
    NSString *homeworkFileID = homeworkFile.remoteHomework.fileID;
    
    if (!homeworkFileID.length) {
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(@"作业fid为空");
        }
        return;
    }
    
    BJLDocumentFile *documentFile = [self documentFileWithHomeworkFileID:homeworkFileID];
    if (documentFile) { // 已经存在课件中了
        if ([self.syncHomeworkFidArray containsObject:homeworkFileID]) {
            [self.syncHomeworkFidArray bjl_removeObject:homeworkFileID];
        }
        
        if (self.selectDocumentFileCallback) {
            self.selectDocumentFileCallback(documentFile, nil);
        }
        return;
    }
    
    if ([self.syncHomeworkFidArray containsObject:homeworkFileID]) {
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(@"请稍候再试");
        }
        return;
    }
    
    [self.syncHomeworkFidArray bjl_addObject:homeworkFileID];
    [self.room.documentVM requestDocumentListWithFileIDList:@[homeworkFileID]
                                                 completion:^(NSArray<BJLDocument *> * _Nullable documentArray, BJLError * _Nullable error) {
        bjl_strongify(self);
        if (error) {// 出错处理
            if ([self.syncHomeworkFidArray containsObject:homeworkFileID]) {
                [self.syncHomeworkFidArray bjl_removeObject:homeworkFileID];
            }
            
            if (self.showErrorMessageCallback) {
                self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            }
            return;
        }
        
        BJLDocument *document = documentArray.firstObject;
        if (!document) {// 转码返回为空
            if ([self.syncHomeworkFidArray containsObject:homeworkFileID]) {
                [self.syncHomeworkFidArray bjl_removeObject:homeworkFileID];
            }
            self.showErrorMessageCallback(@"请稍候再试");
            return;
        }
        
        BJLDocumentFile *documentFile = [self documentFileWithHomeworkFileID:homeworkFileID];
        if (documentFile) {// 已经存在课件中了
            if ([self.syncHomeworkFidArray containsObject:homeworkFileID]) {
                [self.syncHomeworkFidArray bjl_removeObject:homeworkFileID];
            }
            self.selectDocumentFileCallback(documentFile, nil);
            return;
        }
        
        BJLDocumentFile *homeworkDocumentFile = [self homeworkFileWithHomeworkID:homeworkFile.remoteHomework.homeworkID];
        homeworkDocumentFile.remoteDocument = [BJLDocument documentWithHomeworkResponseData:[[homeworkDocumentFile.remoteHomework bjlyy_modelToJSONObject] bjl_asDictionary]];
        [homeworkDocumentFile.remoteDocument updateDocumentName:homeworkDocumentFile.name documentFromTranscode:document];
        BJLError *documentAddError = [self.room.documentVM addDocument:homeworkDocumentFile.remoteDocument];
        if (documentAddError) {
            if ([self.syncHomeworkFidArray containsObject:homeworkFileID]) {
                [self.syncHomeworkFidArray bjl_removeObject:homeworkFileID];
            }
            
            if (self.showErrorMessageCallback) {
                self.showErrorMessageCallback(documentAddError.localizedFailureReason ?: documentAddError.localizedDescription);
            }
            return;
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            BJLDocumentFile *documentFile = [self documentFileWithHomeworkFileID:document.fileID];
            
            if (self.selectDocumentFileCallback && documentFile) {
                if ([self.syncHomeworkFidArray containsObject:homeworkFileID]) {
                    [self.syncHomeworkFidArray bjl_removeObject:homeworkFileID];
                }
                self.selectDocumentFileCallback(documentFile, nil);
            }
            else if (!documentFile) {
                self.showErrorMessageCallback(@"请稍候再试");
            }
        });
    }];
}

// 本地删除选中的文档, 不等待返回删除成功
- (void)deleteSelectedHomework:(BJLDocumentFile *)file {
    // 如果是上传中的作业 , 取消上传
    if (file.state == BJLDocumentFileUploading) {
        [self.uploadHomeworkRequest cancel];
        self.uploadHomeworkRequest = nil;
    }
    
    // 作业删除
    bjl_weakify(self);
    if ((file.state == BJLDocumentFileNormal || file.state == BJLDocumentFileTranscoding)
        && !self.room.loginUser.isStudent && file.remoteHomework.homeworkID.length) {
        [self.room.homeworkVM requestDeleteHomeworkWithHomeworkID:file.remoteHomework.homeworkID completion:^(BOOL success, BJLError * _Nullable error) {
            bjl_strongify(self);
            if (error) {
                self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            }
        }];
    }
    
    // 本地删除
    if ([self.mutableTranscodeHomeworkFileList containsObject:file]) {
        [self.mutableTranscodeHomeworkFileList bjl_removeObject:file];
    }
    if ([self.mutableHomeworkFileList containsObject:file]) {
        [self.mutableHomeworkFileList bjl_removeObject:file];
    }
    if ([self.mutableHomeworkSearchResultFileList containsObject:file]) {
        [self.mutableHomeworkSearchResultFileList bjl_removeObject:file];
    }
    if ([self.syncHomeworkFidArray containsObject:file.remoteHomework.fileID]) {
        [self.syncHomeworkFidArray bjl_removeObject:file.remoteHomework.fileID];
    }
    
    // 下载删除 产品确认不删除
//    [self cancelDownloadHomework:file];
    [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeHomework];
}

- (void)uploadHomeWorkFile:(BJLDocumentFile *)documentFile {
    // 改变状态
    documentFile.state = BJLDocumentFileUploading;
    documentFile.errorCode = 0;
    documentFile.progress = 0.0;
    [self updateTranscodeHomeWorksListWithHomeWorkFile:documentFile];
    bjl_weakify(self);
    // 上传
    self.uploadHomeworkRequest = [self.room.homeworkVM uploadHomeworkFile:documentFile.url
                                                                 mimeType:documentFile.mimeType
                                                                 fileName:documentFile.name
                                                                 progress:^(CGFloat progress) {
        bjl_strongify(self);
        [self updateDocumentFileWithLocalID:documentFile.localID fileID:nil progress:progress errorCode:0];
    }
                                                               finish:^(BJLHomework * _Nullable homework, BJLDocument * _Nullable document, BJLError * _Nullable error) {
        bjl_strongify(self);
        self.uploadHomeworkRequest = nil;
        if (!error) {
            // 如果文档在上传过程中删除了，丢弃远端文档
            if (![self.mutableTranscodeHomeworkFileList containsObject:documentFile]) {
                return;
            }
            // 远端文档和本地文档对应，以便更新文档列表
            BJLDocumentFile *file = [[BJLDocumentFile alloc] initWithRemoteHomework:homework];
            // 保存本地文件的本地路径, 方便重传/重转
            file.localPathURL = documentFile.localPathURL;
            file.localID = documentFile.localID;
            // 设置状态为转码, 重置进度，更新文档列表
            file.state = (file.remoteHomework.canPreview &&  file.type != BJLDocumentFileImage) ? BJLDocumentFileTranscoding : BJLDocumentFileNormal;
            file.progress = 0.0;
            [self updateTranscodeHomeWorksListWithHomeWorkFile:file];
            if (!file.remoteHomework.canPreview) {
                BJLError *error = [self.room.homeworkVM addHomework:file.remoteHomework];
                if (error) {
                    self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
                }
            }
            else if (file.type == BJLDocumentFileImage) {
                // 图片不需要转码，直接添加到教室
                [self finishUpdateDocumentFileWithFileID:file.remoteHomework.fileID];
            }
            else {
                // 开始轮询转码进度
                [self startPollTimer];
            }
        }
        else {
            documentFile.state = BJLDocumentFileUploadError;
            documentFile.errorMessage = error.localizedFailureReason ?: @"上传失败，请重新上传！";
            [self updateTranscodeHomeWorksListWithHomeWorkFile:documentFile];
        }
    }];
    
    [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeHomework];
}

// 上传过程中实时更新本地的上传转码作业list的数据
- (void)updateTranscodeHomeWorksListWithHomeWorkFile:(BJLDocumentFile *)file {
    BJLDocumentFile *changedFile = nil;
    NSString *localID = file.localID;
    NSString *homeworkID = file.remoteHomework.homeworkID;
    for (BJLDocumentFile *documentFile in [self.mutableTranscodeHomeworkFileList copy]) {
        if (localID.length && [documentFile.localID isEqualToString:localID]) {
            changedFile = documentFile;
        }
        else if (homeworkID.length && [documentFile.remoteHomework.homeworkID isEqualToString:homeworkID]) {
            changedFile = documentFile;
        }
    }
    
    // file 发生改变
    if (changedFile) {
        // 转码完成前没有办法判断是否是动态PPT，因此根据本地上传文档来判断
        file.type = changedFile.type;
        file.localPathURL = changedFile.localPathURL;
        [self.mutableTranscodeHomeworkFileList removeObject:changedFile];
    }
    
    [self.mutableTranscodeHomeworkFileList bjl_addObject:file];
    [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeHomework];
}

#pragma mark - download

- (void)downloadActionWithHomeworkFile:(BJLDocumentFile *)file withRect:(CGRect)rectForOpenInIpad {
    BJLHomeworkDownloadItem *downloadItem = [self localDownloadItemWithHomeworkFile:file];
    
    if (!downloadItem) {
        [self downloadHomework:file];
//        self.showErrorMessageCallback(@"课件开始下载");
    }
    else if (downloadItem.state == BJLDownloadItemState_running && !downloadItem.error) {
//        self.showErrorMessageCallback(@"课件还在下载中");
    }
    else if (downloadItem.state == BJLDownloadItemState_completed && !downloadItem.error) {
        [self openFile:file withRect:rectForOpenInIpad];
//        self.showErrorMessageCallback(@"课件打开");
    }
    else if (downloadItem.state == BJLDownloadItemState_paused && !downloadItem.error) {
        [downloadItem resume];
//        self.showErrorMessageCallback(@"暂停时再继续下载");
    }
    else if (downloadItem.error) {
        [self cancelDownloadHomework:file];
        [self downloadHomework:file];
//        self.showErrorMessageCallback(@"课件重新下载");
    }
    else {
//        self.showErrorMessageCallback(@"这是什么状态??");
    }
}

- (void)downloadHomework:(BJLDocumentFile *)file {
    BOOL isValidItemIdentifier = [self.manager validateItemIdentifier:[self itemIdentifierWithHomeworkID:file.remoteHomework.homeworkID]];
    if (!isValidItemIdentifier) {
//        self.showErrorMessageCallback(@"下载任务已添加");
        return;
    }
    
    bjl_weakify(self);
    [self.room.homeworkVM requestDownloadURLWithHomeworkID:file.remoteHomework.homeworkID
                                            completion:^(BOOL success, BJLError * _Nullable error, NSString * _Nonnull downloadUrl) {
        bjl_strongify(self);
        if (!success) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
        }
        else {
//            self.showErrorMessageCallback(@"下载地址请求OK");
            
            NSString *itemIdentifier = [self itemIdentifierWithHomeworkID:file.remoteHomework.homeworkID];
            [self.manager addDownloadItemWithIdentifier:itemIdentifier itemClass:[BJLHomeworkDownloadItem class] setting:^(__kindof BJLHomeworkDownloadItem * _Nonnull item) {
                bjl_strongify(self);
                item.sourceURL = [NSURL URLWithString:downloadUrl];
                item.homework = file.remoteHomework;
                item.downloadTimeInterval = [NSDate timeIntervalSinceReferenceDate];
                item.roomName = self.room.roomInfo.title;
                item.roomID = self.room.roomInfo.ID;
            }];
        }
    }];
}

- (void)cancelDownloadHomework:(BJLDocumentFile *)file {
    [self.manager removeDownloadItemWithIdentifier:[self itemIdentifierWithHomeworkID:file.remoteHomework.homeworkID]];
}

// UIDocumentInteractionController 不可使用局部变量, 否则会发送失败
// https://stackoverflow.com/questions/18091485/uidocumentinteractioncontroller-not-appearing-on-ipad-but-working-on-iphone
- (void)openFile:(BJLDocumentFile *)file  withRect:(CGRect)rectForOpenInIpad {
    BJLDownloadItem *downloadItem = [self localDownloadItemWithHomeworkFile:file];
    if (downloadItem && downloadItem.state == BJLDownloadItemState_completed && !downloadItem.error) {
        UIDocumentInteractionController *controller = [UIDocumentInteractionController new];
        controller.URL = [[NSURL alloc] initFileURLWithPath:downloadItem.downloadFiles.firstObject.filePath];
        controller.name = file.name;
        BOOL iphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
        CGRect rect = iphone ? self.view.bounds : rectForOpenInIpad;
        [controller presentOptionsMenuFromRect:rect inView:self.view animated:YES];
        self.documentController = controller;
    }
}

// 使用classID-homeworkID 唯一指定一个下载文件
- (NSString *)itemIdentifierWithHomeworkID:(NSString *)homeworkID {
    return [NSString stringWithFormat:@"%@-%@", self.room.roomInfo.ID, homeworkID ?: @""];
}

- (nullable BJLHomeworkDownloadItem *)localDownloadItemWithHomeworkFile:(BJLDocumentFile *)file {
    if (!file.remoteHomework) {
        return nil;
    }
    
    __block BJLHomeworkDownloadItem *downloadItem = nil;
    NSString *itemIdentifier = [self itemIdentifierWithHomeworkID:file.remoteHomework.homeworkID];
    NSArray *downloadItems = self.manager.downloadItems.copy;
    [downloadItems enumerateObjectsUsingBlock:^(BJLHomeworkDownloadItem *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //        bjl_strongify(self);
        if([obj.itemIdentifier isEqualToString:itemIdentifier]) {
            *stop = YES;
            downloadItem = obj;
        }
    }];
    return downloadItem;
}

#pragma mark - wheel

- (nullable BJLDocumentFile *)homeworkFileWithHomeworkID:(nullable NSString *)homeworkID {
    for (BJLDocumentFile *documentFile in [self.mutableHomeworkFileList copy]) {
        if (homeworkID.length && [documentFile.remoteHomework.homeworkID isEqualToString:homeworkID]) {
            return documentFile;
        }
    }
    return nil;
}

// 从doclist中寻找作业fid对应的课件文件
- (nullable BJLDocumentFile *)documentFileWithHomeworkFileID:(NSString *)fileID {
    if (!fileID) {
        return nil;
    }
    for (BJLDocumentFile *documentFile in self.mutableAllDocumentFileList) {
        if ([documentFile.remoteDocument.fileID isEqualToString:fileID]) {
            return documentFile;
        }
    }
    return nil;
}

#pragma mark - <BJLDownloadManagerDelegate>

- (void)downloadManager:(BJLDownloadManager *)downloadManager
           downloadItem:(BJLHomeworkDownloadItem *)downloadItem
              didChange:(BJLPropertyChange *)change {
    if (downloadItem.error) {
        self.showErrorMessageCallback(downloadItem.error.localizedFailureReason ?: downloadItem.error.localizedDescription);
    }
}

@end
