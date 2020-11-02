//
//  BJLIcDocumentFileManagerViewController+private.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/8/26.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcDocumentFileManagerViewController.h"
#import "BJLIcDocumentFileManagerViewController+homework.h"
#import "BJLIcDocumentFileManagerViewController+transcode.h"
#import "BJLIcDocumentFileManagerViewController+doc.h"
#import "BJLIcDocumentFileManagerViewController+cloud.h"
#import "BJLIcDocumentFileView.h"
#import "BJLDocumentFile.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDocumentFileManagerViewController () <UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, BJLDownloadManagerDelegate>

@property (nonatomic, weak) BJLRoom *room;
// 文档管理视图
@property (nonatomic) BJLIcDocumentFileView *documentFileView;
// 区分动态和静态PPT调用按钮
@property (nonatomic) BOOL isSelectAnimatedDocumentFile;
// 轮询转码进度 timer
@property (nonatomic, nullable) NSTimer *pollTimer;

@property (nonatomic) NSMutableArray<BJLDocumentFile *> *mutableAllDocumentFileList, *mutableTranscodeDocumentFileList;
@property (nonatomic) NSMutableArray<BJLDocumentFile *> *mutableDocumentSearchResultFileList;
@property (nonatomic, nullable) NSURLSessionUploadTask *uploadDocumentRequest;

// 云盘
@property (nonatomic) NSMutableArray<BJLDocumentFile *> *mutableCloudFileList, *mutableTranscodeCloudFileList, *mutableCloudSearchResultFileList;
@property (nonatomic, nullable) NSURLSessionDataTask *requestListTask;
@property (nonatomic, nullable) NSURLSessionUploadTask *uploadCloudFileRequest;
@property (nonatomic, nullable) NSMutableArray<NSString *> *syncCloudFidArray;// 同步中的云盘文件fid

// homework
@property (nonatomic, nullable) UIDocumentInteractionController *documentController;
@property (nonatomic) NSMutableArray<BJLDocumentFile *> *mutableHomeworkFileList, *mutableTranscodeHomeworkFileList, *mutableHomeworkSearchResultFileList;
@property (nonatomic, nullable) NSURLSessionUploadTask *uploadHomeworkRequest;
@property (nonatomic, nullable) BJLHomework *homeworkCursor;
@property (nonatomic) BOOL hasmore;
@property (nonatomic) BOOL shouldShowHomeworkSupportView;
@property (nonatomic, nullable) NSMutableArray<NSString *> *syncHomeworkFidArray;// 同步中的作业文件fid

// 文档/作业成功添加列表
@property (nonatomic) NSMutableArray<NSString *> *finishDocumentFileIDList;

// 教室内文档上传视图
@property (nonatomic, readwrite) UIView *addDocumentContainerView, *chooseDocumentLayer;
@property (nonatomic, readwrite) UIButton *addAnimatedDocumentFileEmptyButton;
@property (nonatomic, readwrite) UIButton *addNormalDocumentFileEmptyButton;

// keyboard input
@property (nonatomic) UIView *overlayView;

#pragma mark - download

@property (nonatomic) BJLDownloadManager *manager;

@property (nonatomic, nullable) NSTimer *progressTimer;

#pragma mark -

- (BJLIcDocumentFileLayoutType)documentFileLayoutType;

- (void)reloadTableViewWithLayoutType:(BJLIcDocumentFileLayoutType)layoutType;

- (nullable BJLDocumentFile *)documentFileWithIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
