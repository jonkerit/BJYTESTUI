//
//  BJLIcDocumentFileManagerViewController+transcode.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/8/28.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcDocumentFileManagerViewController+transcode.h"
#import "BJLIcDocumentFileManagerViewController+private.h"

@implementation BJLIcDocumentFileManagerViewController (transcode)

static const CGFloat pollDuration = 2.0;

#pragma mark - timer

// 轮询转码
- (void)startPollTimer {
    [self stopPollTimer];
    // 立即请求一次
    [self requestTranscodingProgress];
    bjl_weakify(self);
    self.pollTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:pollDuration repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self) {
            [timer invalidate];
            return;
        }
        [self requestTranscodingProgress];
    }];
}

- (void)stopPollTimer {
    [self.pollTimer invalidate];
    self.pollTimer = nil;
}

- (void)requestTranscodingProgress {
    // 查询所有转码中的文档进度
    NSMutableArray *array = [NSMutableArray new];
    for (BJLDocumentFile *documentFile in [self.mutableTranscodeDocumentFileList copy]) {
        if (documentFile.state == BJLDocumentFileTranscoding) {
            if (documentFile.remoteDocument.fileID.length) {
                [array bjl_addObject:documentFile.remoteDocument.fileID];
            }
        }
    }
    
    for (BJLDocumentFile *documentFile in [self.mutableTranscodeHomeworkFileList copy]) {
        if (documentFile.state == BJLDocumentFileTranscoding) {
            if (documentFile.remoteHomework.fileID.length) {
                [array bjl_addObject:documentFile.remoteHomework.fileID];
            }
        }
    }
    
    for (BJLDocumentFile *documentFile in [self.mutableTranscodeCloudFileList copy]) {
        if (documentFile.state == BJLDocumentFileTranscoding) {
            if (documentFile.remoteCloudFile.fileID.length) {
                [array bjl_addObject:documentFile.remoteCloudFile.fileID];
            }
        }
    }
    
    // 当前没有转码中文档，停止轮询
    if (!array.count) {
        [self stopPollTimer];
        return;
    }
    // 请求转码进度接口
    bjl_weakify(self);
    [self.room.documentVM requestTranscodingProgressWithFileIDList:array
                                                        completion:^(NSArray<BJLDocumentTranscodeModel *> * _Nullable transcodeModelArray, BJLError * _Nullable error) {
        bjl_strongify(self);
        if (error) {
            NSLog(@"error when requestTranscodingProgressWithFileIDList %@", error);
            return;
        }
        for (BJLDocumentTranscodeModel *model in transcodeModelArray) {
            if (model.progress >= 100) {
                // 转码完成
                [self finishUpdateDocumentFileWithFileID:model.fileID];
            }
            else {
                // 更新转码进度
                [self updateDocumentFileWithLocalID:nil fileID:model.fileID progress:model.progress errorCode:model.errorCode];
            }
        }
    }];
}

// 远端文档转码完成
- (void)finishUpdateDocumentFileWithFileID:(NSString *)fileID {
    BJLDocumentFile *documentFile = [self transcodeDocumentFileWithLocalID:nil fileID:fileID];
    if (!documentFile) {
        return;
    }
    if (documentFile.type == BJLDocumentFileImage && !documentFile.remoteCloudFile) {// 图片不需要转码
        documentFile.state = BJLDocumentFileNormal;
        if (documentFile.remoteHomework) { // 作业
            [self.room.homeworkVM addHomework:documentFile.remoteHomework];
        }
        else {
            [self.room.documentVM addDocument:documentFile.remoteDocument];
        }
    }
    else {
        // 添加文档
        bjl_weakify(self);
        [self.room.documentVM requestDocumentListWithFileIDList:@[fileID]
                                                     completion:^(NSArray<BJLDocument *> * _Nullable documentArray, BJLError * _Nullable error) {
            bjl_strongify(self);
            if (error) {
                NSLog(@"error when requestDocumentListWithFileIDList %@", error);
                return;
            }
            for (BJLDocument *document in documentArray) {
                for (NSString *fileID in self.finishDocumentFileIDList) {
                    // 如果文档已经添加到了教室, 不处理
                    if ([document.fileID isEqualToString:fileID]) {
                        return;
                    }
                }
                // 请求到文档信息之后添加文档，这时认为已经添加到了教室里
                [self.finishDocumentFileIDList bjl_addObject:document.fileID];
                // 转码成功后可以获得文档的页码信息，更新本地document
                BJLDocumentFile *documentFile = [self transcodeDocumentFileWithLocalID:nil fileID:document.fileID];
                if (documentFile.remoteHomework) {
                    documentFile.state = BJLDocumentFileNormal;
                    [self.room.homeworkVM addHomework:documentFile.remoteHomework];
                }
                else {
                    documentFile.state = BJLDocumentFileNormal;
                    [documentFile.remoteDocument updateDocumentName:documentFile.name documentFromTranscode:document];
                    if (!documentFile.remoteCloudFile) {
                        [self.room.documentVM addDocument:documentFile.remoteDocument];
                    }
                    else {
                        [self updateTranscodeCloudListWithDocumentFile:documentFile];
                    }
                }
            }
        }];
    }
}

#pragma mark - wheel

// 更新上传和转码进度
- (void)updateDocumentFileWithLocalID:(nullable NSString *)localID
                               fileID:(nullable NSString *)fileID
                             progress:(CGFloat)progress
                            errorCode:(NSInteger)errorCode {
    BJLDocumentFile *documentFile = [self transcodeDocumentFileWithLocalID:localID fileID:fileID];
    if (documentFile.state == BJLDocumentFileUploading || documentFile.state == BJLDocumentFileTranscoding) {
        documentFile.progress = progress;
        documentFile.errorCode = errorCode;
    }
    
    if (progress < 0) {
        documentFile.state = BJLDocumentFileTranscodeError;
    }
}

- (nullable BJLDocumentFile *)transcodeDocumentFileWithLocalID:(nullable NSString *)localID
                                                        fileID:(nullable NSString *)fileID {
    for (BJLDocumentFile *documentFile in [self.mutableTranscodeDocumentFileList copy]) {
        if (localID.length && [documentFile.localID isEqualToString:localID]) {
            return documentFile;
        }
        else if (fileID.length && [documentFile.remoteDocument.fileID isEqualToString:fileID]) {
            return documentFile;
        }
    }
    for (BJLDocumentFile *documentFile in [self.mutableTranscodeHomeworkFileList copy]) {
        if (localID.length && [documentFile.localID isEqualToString:localID]) {
            return documentFile;
        }
        if (fileID.length && [documentFile.remoteHomework.fileID isEqualToString:fileID]) {
            return documentFile;
        }
    }
    for (BJLDocumentFile *documentFile in [self.mutableTranscodeCloudFileList copy]) {
        if (localID.length && [documentFile.localID isEqualToString:localID]) {
            return documentFile;
        }
        if (fileID.length && [documentFile.remoteCloudFile.fileID isEqualToString:fileID]) {
            return documentFile;
        }
    }
    
    return nil;
}

@end
