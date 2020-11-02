//
//  BJLDocumentFile.h
//  BJLiveUI
//
//  Created by xijia dai on 2020/8/17.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLDocumentFileType) {
    BJLDocumentFileTXT,                                           // txt 文本, 不在枚举之类的默认设置为 txt
    BJLDocumentFileDOC,                                           // word 文档
    BJLDocumentFilePDF,                                           // pdf 文档
    BJLDocumentFileXLS,                                           // excel 等表格
    BJLDocumentFileNormalPPT,                                     // 普通 ppt, 本地不区分动态 ppt, 默认为普通 ppt
    BJLDocumentFileAnimatedPPT,                                   // 动效 ppt
    BJLDocumentFileWebPPT,                                        // web ppt
    BJLDocumentFileImage,                                         // 图片
    BJLDocumentFileAudio,                                         // 音频
    BJLDocumentFileVideo,                                         // 视频
    BJLDocumentFileTypeCount,                                     // 文件类型计数
    BJLDocumentFileTypeDefault = BJLDocumentFileTXT,
};

typedef NS_ENUM(NSInteger, BJLDocumentFileState) {
    BJLDocumentFileNormal,                                        // 普通状态
    BJLDocumentFileUploading,                                     // 上传状态
    BJLDocumentFileUploadError,                                   // 上传错误状态
    BJLDocumentFileTranscoding,                                   // 转码状态
    BJLDocumentFileTranscodeError,                                // 转码错误状态
    BJLDocumentFileStateDefault = BJLDocumentFileNormal,
};

typedef NS_ENUM(NSInteger, BJLDocumentFileEditMode) {
    BJLDocumentFileNonEdit,                                       // 未编辑状态
    BJLDocumentFileUnselected,                                    // 非选中状态
    BJLDocumentFileSelected,                                      // 选中状态
    BJLDocumentFileEditModeDefault = BJLDocumentFileNonEdit,
};

@interface BJLDocumentFile : NSObject

@property (nonatomic) NSString *localID;                            // 文档标识符, 远端文档为nil
@property (nonatomic) NSString *name;                               // 文档名
@property (nonatomic) NSString *suffix;                             // 文件后缀
@property (nonatomic) NSString *mimeType;                           // 文档web类型
@property (nonatomic) NSURL *url;                                   // 文档url, 上传到远端后为远端文档url
@property (nonatomic) NSURL *localPathURL;                          // 本地上传文档的路径,可以为空,便于重传
@property (nonatomic) BJLDocumentFileType type;                     // 文档类型
@property (nonatomic) NSString *suggestImageName;                   // 根据文档类型的建议的占位图名
@property (nonatomic) BJLDocumentFileState state;                   // 文档状态
@property (nonatomic) BJLDocumentFileEditMode editMode;             // 文档编辑状态
@property (nonatomic) UIDocument *localDocument;                    // 本地文档, 远端文档此属性为nil
@property (nonatomic) BJLDocument *remoteDocument;                  // 远端文档, 本地文档此属性为nil
@property (nonatomic) CGFloat progress;                             // 上传和转码进度
@property (nonatomic) BOOL isRelatedDocument;                       // 是否为后台关联的课件
@property (nonatomic) NSInteger errorCode;                          // 错误码
@property (nonatomic) NSString *errorMessage;                       // 错误码对应的描述

/**
 使用本地文档初始化
 #param localDocument UIDocument
 #return self
 */
- (instancetype)initWithLocalDocument:(UIDocument *)localDocument;

// 本地上传/播放之前判断是否支持当前文件类型
- (BOOL)shouldSupportUploadAndPlay;

#pragma mark - ppt

/**
 使用远端文档初始化
 #param remoteDocument BJLDocument
 #return self
 */
- (instancetype)initWithRemoteDocument:(BJLDocument *)remoteDocument;

#pragma mark - homework

@property (nonatomic) BJLHomework *remoteHomework;                  // 远端作业

/**
 使用远端作业文档初始化
 #param remoteHomework BJLHomework
 #return self
 */
- (instancetype)initWithRemoteHomework:(BJLHomework *)remoteHomework;

#pragma mark - cloud

@property (nonatomic) BJLCloudFile *remoteCloudFile;                  // 远端云盘文档

/**
 使用远端云盘文件初始化
 #param remoteCloudFile BJLCloudFile
 #return self
 */
- (instancetype)initWithRemoteCloudFile:(BJLCloudFile *)remoteCloudFile;

@end

NS_ASSUME_NONNULL_END
