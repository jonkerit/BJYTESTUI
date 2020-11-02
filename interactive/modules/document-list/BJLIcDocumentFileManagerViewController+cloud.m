//
//  BJLIcDocumentFileManagerViewController+cloud.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/9/9.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcDocumentFileManagerViewController+cloud.h"
#import "BJLIcDocumentFileManagerViewController+private.h"

@implementation BJLIcDocumentFileManagerViewController (cloud)


- (void)loadAllRemoteCloudDocuments {
    bjl_weakify(self);
    
    self.requestListTask = [self.room.cloudDiskVM requestCloudListWithCompletion:^(NSArray<BJLCloudFile *> * _Nullable cloudDocuments, BJLError * _Nullable error) {
        bjl_strongify(self);
        self.requestListTask = nil;
        
        NSMutableArray <BJLDocumentFile *> *mutableCloudFileList = [NSMutableArray new];
        
        for (BJLCloudFile *cloudFile in cloudDocuments) {
            BJLDocumentFile *file = [[BJLDocumentFile alloc] initWithRemoteCloudFile:cloudFile];
            [mutableCloudFileList bjl_addObject:file];
        }
        self.mutableCloudFileList = mutableCloudFileList;
        [self removeFromTranscodeCloudListWith:cloudDocuments];
        [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeCloud];
    }];
}

// 收到信令, 过滤本地上传转码的作业list
- (void)removeFromTranscodeCloudListWith:(NSArray<BJLCloudFile *> *)cloudDocuments {
    if (![cloudDocuments count]) {
        return;
    }
    NSMutableArray<BJLDocumentFile *> *mutableTranscodeCloudFileList = [self.mutableTranscodeCloudFileList mutableCopy];
    for (BJLCloudFile *cloud in cloudDocuments) {
        [self.mutableTranscodeCloudFileList enumerateObjectsUsingBlock:^(BJLDocumentFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.remoteCloudFile.fileID isEqualToString:cloud.fileID]) {
                [mutableTranscodeCloudFileList bjl_removeObject:obj];
                *stop = YES;
            }
        }];
    }
    self.mutableTranscodeCloudFileList = [mutableTranscodeCloudFileList mutableCopy];
}

- (void)uploadCloudDocumentFile:(BJLDocumentFile *)documentFile {
    bjl_weakify(self);
    // 改变状态
    documentFile.state = BJLDocumentFileUploading;
    documentFile.errorCode = 0;
    documentFile.progress = 0.0;
    [self updateTranscodeCloudListWithDocumentFile:documentFile];
    
    BOOL isAnimated = documentFile.type == BJLDocumentFileAnimatedPPT;
    
    self.uploadCloudFileRequest = [self.room.cloudDiskVM uploadCloudFile:documentFile.url
                                                                mimeType:documentFile.mimeType
                                                                fileName:documentFile.name
                                                              isAnimated:isAnimated
                                                                progress:^(CGFloat progress) {
        bjl_strongify(self);
        [self updateDocumentFileWithLocalID:documentFile.localID fileID:nil progress:progress errorCode:0];
    } finish:^(BJLCloudFile * _Nullable cloudFile, BJLError * _Nullable error) {
        bjl_strongify(self);
        self.uploadCloudFileRequest = nil;
        if (!error) {
            // 如果文档在上传过程中删除了，丢弃远端文档
            if (![self.mutableTranscodeCloudFileList containsObject:documentFile]) {
                return;
            }
            // 远端文档和本地文档对应，以便更新文档列表
            BJLDocumentFile *file = [[BJLDocumentFile alloc] initWithRemoteCloudFile:cloudFile];
            // 保存本地文件的本地路径, 方便重传/重转
            file.localPathURL = documentFile.localPathURL;
            file.localID = documentFile.localID;
            // 设置状态为转码,重置进度,更新文档列表
            file.state = (file.type != BJLDocumentFileImage) ? BJLDocumentFileTranscoding : BJLDocumentFileNormal;
            file.progress = 0.0;
            [self updateTranscodeCloudListWithDocumentFile:file];
            if (file.type != BJLDocumentFileImage) {
                // 开始轮询转码进度
                [self startPollTimer];
            }
        }
        else {
            documentFile.state = BJLDocumentFileUploadError;
            documentFile.errorMessage = error.localizedFailureReason ?: @"上传失败，请重新上传！";
            [self updateTranscodeCloudListWithDocumentFile:documentFile];
        }
    }];
    
    [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeCloud];
}

- (void)deleteSelectedCloudDocumentFile:(BJLDocumentFile *)file {
    if (file.remoteCloudFile.fileID.length
        && (file.state == BJLDocumentFileNormal || file.state == BJLDocumentFileTranscoding)) {
        bjl_weakify(self);
        [self.room.cloudDiskVM requestDeleteCloudFileWithFileID:file.remoteCloudFile.fileID
                                                completion:^(BOOL success, BJLError * _Nullable error) {
            bjl_strongify(self);
            if (!success) {
                if (self.showErrorMessageCallback) {
                    self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
                }
            }
        }];
    }
    
    [self deleteCloudDocumentFile:file];
    [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeCloud];
}

- (void)deleteCloudDocumentFile:(BJLDocumentFile *)file {
    if ([self.mutableCloudFileList containsObject:file]) {
        [self.mutableCloudFileList bjl_removeObject:file];
    }
    
    if ([self.mutableTranscodeCloudFileList containsObject:file]) {
        [self.mutableTranscodeCloudFileList bjl_removeObject:file];
    }

    if ([self.mutableCloudSearchResultFileList containsObject:file]) {
        [self.mutableCloudSearchResultFileList bjl_removeObject:file];
    }
    
    if ([self.syncCloudFidArray containsObject:file.remoteCloudFile.fileID]) {
        [self.syncCloudFidArray bjl_removeObject:file.remoteCloudFile.fileID];
    }
}

// 由于云盘列表不提供转码的数据, 所以需要在打开时请求getImage接口获取信息
- (void)syncAndOpenCloudDocumentFile:(BJLDocumentFile *)cloudFile {
    bjl_weakify(self);
    
    if (!cloudFile.remoteCloudFile.fileID.length) {
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(@"云盘文件fid为空");
        }
        return;
    }
    
    BJLDocumentFile *documentFile = [self documentFileWithCloudFileID:cloudFile.remoteCloudFile.fileID];
    if (documentFile) { // 已经存在课件中了
        if ([self.syncCloudFidArray containsObject:cloudFile.remoteCloudFile.fileID]) {
            [self.syncCloudFidArray bjl_removeObject:cloudFile.remoteCloudFile.fileID];
        }
        
        if (self.selectDocumentFileCallback) {
            self.selectDocumentFileCallback(documentFile, nil);
        }
        return;
    }
    
    if ([self.syncCloudFidArray containsObject:cloudFile.remoteCloudFile.fileID]) {
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(@"请稍候再试");
        }
        return;
    }
    
    [self.syncCloudFidArray bjl_addObject:cloudFile.remoteCloudFile.fileID];
    [self.room.documentVM requestDocumentListWithFileIDList:@[cloudFile.remoteCloudFile.fileID]
                                                 completion:^(NSArray<BJLDocument *> * _Nullable documentArray, BJLError * _Nullable error) {
        bjl_strongify(self);
        if (error) {// 出错处理
            if ([self.syncCloudFidArray containsObject:cloudFile.remoteCloudFile.fileID]) {
                [self.syncCloudFidArray bjl_removeObject:cloudFile.remoteCloudFile.fileID];
            }
            
            if (self.showErrorMessageCallback) {
                self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            }
            return;
        }
        
        BJLDocument *document = documentArray.firstObject;
        if (!document) {// 转码返回为空
            if ([self.syncCloudFidArray containsObject:cloudFile.remoteCloudFile.fileID]) {
                [self.syncCloudFidArray bjl_removeObject:cloudFile.remoteCloudFile.fileID];
            }
            self.showErrorMessageCallback(@"请稍候再试");
            return;
        }
        
        BJLDocumentFile *documentFile = [self documentFileWithCloudFileID:document.fileID];
        if (documentFile) {// 已经存在课件中了
            if ([self.syncCloudFidArray containsObject:cloudFile.remoteCloudFile.fileID]) {
                [self.syncCloudFidArray bjl_removeObject:cloudFile.remoteCloudFile.fileID];
            }
            self.selectDocumentFileCallback(documentFile, nil);
            return;
        }
        
        BJLDocumentFile *cloudDocumentFile = [self cloudFileWithLocalID:nil fileID:document.fileID];
        cloudDocumentFile.remoteDocument = [BJLDocument documentWithUploadCloudResponseData:[[cloudDocumentFile.remoteCloudFile bjlyy_modelToJSONObject] bjl_asDictionary]];
        [cloudDocumentFile.remoteDocument updateDocumentName:cloudDocumentFile.name documentFromTranscode:document];
        [self.room.documentVM addDocument:cloudDocumentFile.remoteDocument];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            BJLDocumentFile *documentFile = [self documentFileWithCloudFileID:document.fileID];
            
            if (self.selectDocumentFileCallback && documentFile) {
                if ([self.syncCloudFidArray containsObject:cloudFile.remoteCloudFile.fileID]) {
                    [self.syncCloudFidArray bjl_removeObject:cloudFile.remoteCloudFile.fileID];
                }
                self.selectDocumentFileCallback(documentFile, nil);
            }
            else if (!documentFile) {
                self.showErrorMessageCallback(@"请稍候再试");
            }
        });
    }];
}

#pragma mark - wheel

- (void)updateTranscodeCloudListWithDocumentFile:(BJLDocumentFile *)documentFile {
    BJLDocumentFile *changedFile = [self cloudFileWithLocalID:documentFile.localID fileID:documentFile.remoteCloudFile.fileID];
    // file 发生改变
    if (changedFile) {
        // 转码完成前没有办法判断是否是动态PPT，因此根据本地上传文档来判断
        documentFile.type = changedFile.type;
        documentFile.localPathURL = changedFile.localPathURL;
        [self.mutableTranscodeCloudFileList bjl_removeObject:changedFile];
    }
    if (documentFile.state == BJLDocumentFileNormal) {
        [self.mutableCloudFileList bjl_addObject:documentFile];
    }
    else {
        [self.mutableTranscodeCloudFileList bjl_addObject:documentFile];
    }
    [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeCloud];
}

- (nullable BJLDocumentFile *)cloudFileWithLocalID:(nullable NSString *)localID
                                            fileID:(nullable NSString *)fileID {
    for (BJLDocumentFile *documentFile in [self.mutableCloudFileList copy]) {
        if (localID.length && [documentFile.localID isEqualToString:localID]) {
            return documentFile;
        }
        else if (fileID.length && [documentFile.remoteCloudFile.fileID isEqualToString:fileID]) {
            return documentFile;
        }
    }
    
    for (BJLDocumentFile *documentFile in [self.mutableTranscodeCloudFileList copy]) {
        if (localID.length && [documentFile.localID isEqualToString:localID]) {
            return documentFile;
        }
        else if (fileID.length && [documentFile.remoteCloudFile.fileID isEqualToString:fileID]) {
            return documentFile;
        }
    }
    return nil;
}

// 从doclist中寻找云盘fid对应的课件文件
- (nullable BJLDocumentFile *)documentFileWithCloudFileID:(NSString *)fileID {
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

@end
