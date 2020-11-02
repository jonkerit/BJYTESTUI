//
//  BJLUploadingTask.h
//  BJLiveUI
//
//  Created by MingLQ on 2017-03-18.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>
#import "BJL_iCloudLoading.h"
#import "BJLDocumentFile.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLUploadState) {
    BJLUploadState_waiting,
    BJLUploadState_uploading,
    BJLUploadState_transcoding,
    BJLUploadState_uploaded
};

@interface BJLUploadingTask : NSObject

+ (instancetype)uploadingTaskWithImageFile:(ICLImageFile *)imageFile;
+ (instancetype)uploadingTaskWithDocumentFile:(BJLDocumentFile *)documentFile;

@property (nonatomic, readonly, nullable) ICLImageFile *imageFile;
@property (nonatomic, readonly, nullable) BJLDocumentFile *documentFile;
@property (nonatomic, readonly, nullable) UIImage *thumbnail;
@property (nonatomic, readonly) CGSize imageSize;

@property (nonatomic) BJLUploadState state;
@property (nonatomic, readonly) CGFloat progress; // 主线程更新，不会过于频繁
@property (nonatomic) CGFloat progressStep; // default: 0.05, min: 0.001

@property (nonatomic, readonly, nullable) id result; // on uploaded > non-nil
@property (nonatomic, readonly, nullable) BJLError *error;

- (void)upload;
- (void)cancel;
- (void)failWithError:(nullable BJLError *)error;

// abstract method, subclasses MUST override and DONOT call super
- (nullable NSURLSessionUploadTask *)uploadImageFile:(NSURL *)fileURL
                                            progress:(nullable void (^)(CGFloat progress))progress
                                              finish:(void (^)(id _Nullable result, BJLError * _Nullable error))finish;
- (nullable NSURLSessionUploadTask *)uploadDocumentFile:(NSURL *)fileURL
                                               mimeType:(NSString *)mimeType
                                               fileName:(NSString *)fileName
                                             isAnimated:(BOOL)isAnimated
                                               progress:(nullable void (^)(CGFloat progress))progress
                                                 finish:(void (^)(id _Nullable document, BJLError * _Nullable error))finish;

@end

NS_ASSUME_NONNULL_END
