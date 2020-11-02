//
//  BJLUploadingTask.m
//  BJLiveUI
//
//  Created by MingLQ on 2017-03-18.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import "BJLUploadingTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLUploadingTask ()

@property (nonatomic, readwrite, nullable) ICLImageFile *imageFile;
@property (nonatomic, readwrite, nullable) BJLDocumentFile *documentFile;
@property (nonatomic, readwrite, nullable) UIImage *thumbnail;
@property (nonatomic, readwrite) CGSize imageSize;

@property (nonatomic, readwrite) CGFloat progress;

@property (nonatomic, weak, nullable) NSURLSessionUploadTask *uploadTask;
@property (nonatomic) BOOL isCancelled;

@property (nonatomic, readwrite, nullable) id result;
@property (nonatomic, readwrite, nullable) BJLError *error;

@end

@implementation BJLUploadingTask

+ (instancetype)uploadingTaskWithImageFile:(ICLImageFile *)imageFile {
    NSParameterAssert(imageFile);
    
    BJLUploadingTask *uploadingTask = [self new];
    uploadingTask.imageFile = imageFile;
    uploadingTask.thumbnail = imageFile.thumbnail;
    uploadingTask.imageSize = imageFile.imageSize;
    uploadingTask.state = BJLUploadState_waiting;
    return uploadingTask;
}

+ (instancetype)uploadingTaskWithDocumentFile:(BJLDocumentFile *)documentFile {
    NSParameterAssert(documentFile);
    
    BJLUploadingTask *uploadingTask = [self new];
    uploadingTask.documentFile = documentFile;
    uploadingTask.state = BJLUploadState_waiting;
    return uploadingTask;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.progressStep = 0.05;
    }
    return self;
}

- (void)upload {
    if (self.state != BJLUploadState_waiting) {
        return;
    }
    
    self.isCancelled = NO;
    self.result = nil;
    self.error = nil;
    self.progress = 0.0;
    self.state = BJLUploadState_uploading;
    
    bjl_weakify(self);
    void (^progressCallback)(CGFloat progress)
    = ^(CGFloat progress) {
        bjl_strongify(self);
        if (progress != self.progress
            && (progress == 0.0
                || progress == 1.0
                || ABS(progress - self.progress) >= MAX(0.001, self.progressStep))) {
                // !!!: MUST be sync
                bjl_dispatch_sync_main_queue(^{
                    self.progress = progress;
                });
            }
    };
    void (^finishCallback)(id _Nullable result, BJLError * _Nullable error)
    = ^(id _Nullable result, BJLError * _Nullable error) {
        bjl_strongify(self);
        self.uploadTask = nil;
        if (self.isCancelled) {
            return;
        }
        if (result) {
            self.result = result;
            self.state = (self.imageFile || self.documentFile.type == BJLDocumentFileImage) ? BJLUploadState_uploaded :  BJLUploadState_transcoding;
        }
        else {
            [self failWithError:error];
        }
    };
    
    if (self.imageFile) {
            self.uploadTask =
        [self uploadImageFile:[self.imageFile fileURL]
                     progress:progressCallback
                       finish:finishCallback];
    }
    else {
        self.uploadTask =
        [self uploadDocumentFile:self.documentFile.url
                        mimeType:self.documentFile.mimeType
                        fileName:self.documentFile.name
                      isAnimated:self.documentFile.type == BJLDocumentFileAnimatedPPT
                        progress:progressCallback
                          finish:finishCallback];
    }
    
    if (!self.uploadTask) {
        [self failWithError:BJLErrorMake(BJLErrorCode_invalidCalling, nil)];
    }
}

- (void)cancel {
    self.isCancelled = YES;
    
    [self.uploadTask cancel];
    self.uploadTask = nil;
    
    self.result = nil;
    self.error = nil;
    self.progress = 0.0;
    self.state = BJLUploadState_waiting;
}

- (void)failWithError:(nullable BJLError *)error {
    self.error = error;
    self.state = BJLUploadState_waiting;
}

- (nullable NSURLSessionUploadTask *)uploadImageFile:(NSURL *)fileURL
                                            progress:(nullable void (^)(CGFloat progress))progress
                                              finish:(void (^)(id _Nullable result, BJLError * _Nullable error))finish {
    return nil;
}

- (nullable NSURLSessionUploadTask *)uploadDocumentFile:(NSURL *)fileURL
                                               mimeType:(NSString *)mimeType
                                               fileName:(NSString *)fileName
                                             isAnimated:(BOOL)isAnimated
                                               progress:(nullable void (^)(CGFloat progress))progress
                                                 finish:(void (^)(id _Nullable document, BJLError * _Nullable error))finish {
    return nil;
}

@end

NS_ASSUME_NONNULL_END
