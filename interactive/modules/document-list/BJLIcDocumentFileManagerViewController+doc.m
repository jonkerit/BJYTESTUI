//
//  BJLIcDocumentFileManagerViewController+doc.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/8/29.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcDocumentFileManagerViewController+doc.h"
#import "BJLIcDocumentFileManagerViewController+private.h"
#import "BJLIcAppearance.h"

@implementation BJLIcDocumentFileManagerViewController (doc)

#pragma mark - choose Animated/Normal file

- (void)makeDocumentChooseView {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    
    self.chooseDocumentLayer = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_colorWithHex:0 alpha:0.2];
        view.hidden = YES;
        view;
    });
    [self.view addSubview:self.chooseDocumentLayer];
    [self.chooseDocumentLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    
    self.addDocumentContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = BJLIcTheme.windowBackgroundColor;
        view.layer.cornerRadius = 4.0;
        view.accessibilityLabel = BJLKeypath(self, addDocumentContainerView);
        view;
    });
    
    [self.chooseDocumentLayer addSubview:self.self.addDocumentContainerView];
    [self.addDocumentContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.chooseDocumentLayer);
        make.width.equalTo(@(560.0));
        make.height.equalTo(@(248.0));
    }];
    
    // tip label
    UILabel *titleLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = @"上传文件";
        label.textColor = BJLIcTheme.viewTextColor;
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self.addDocumentContainerView addSubview:titleLabel];
    [titleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.addDocumentContainerView).offset(16.0);
        make.height.equalTo(@32.0);
        make.top.equalTo(self.addDocumentContainerView);
    }];
    
    // close button
    UIButton *closeButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"window_close"] forState:UIControlStateNormal];
        button;
    });
    
    bjl_weakify(self);
    [closeButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        self.chooseDocumentLayer.hidden = YES;
    }];
    [self.addDocumentContainerView addSubview:closeButton];
    [closeButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.addDocumentContainerView).offset(-8.0);
        make.top.bottom.equalTo(titleLabel);
        make.width.equalTo(closeButton.bjl_height);
    }];
    
    UIView *gapline1 = [UIView bjlic_createSeparateLine];
    [self.addDocumentContainerView addSubview:gapline1];
    [gapline1 bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(self.addDocumentContainerView);
        make.height.equalTo(@1.0);
        make.top.equalTo(titleLabel.bjl_bottom);
    }];
    
    // normal file image
    self.addNormalDocumentFileEmptyButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor clearColor];
        [button setBackgroundImage:[UIImage bjl_imageWithColor:[UIColor bjl_colorWithHex:0X9FA8B5 alpha:0.3]] forState:UIControlStateHighlighted];
        button.layer.cornerRadius = 4.0;
        button.layer.borderWidth = 1.0;
        button.layer.borderColor = BJLIcTheme.buttonBorderColor.CGColor;
        button;
    });
    [self.addDocumentContainerView addSubview:self.addNormalDocumentFileEmptyButton];
    [self.addNormalDocumentFileEmptyButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(gapline1.bjl_bottom).offset(20.0);
        make.right.equalTo(self.addDocumentContainerView.bjl_centerX).offset(-10);
        make.left.equalTo(self.addDocumentContainerView).offset(30);
        make.height.greaterThanOrEqualTo(@64.0);
    }];
    
    UIImageView *normalFileImageView = [UIImageView new];
    normalFileImageView.image = [UIImage bjlic_imageNamed:@"bjl_document_normalfile"];
    [self.addDocumentContainerView addSubview:normalFileImageView];
    // normal file label
    UILabel *normalFileLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = @"上传普通文件";
        label.textColor = BJLIcTheme.viewTextColor;
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self.addDocumentContainerView addSubview:normalFileLabel];
    // normal file detail label
    UILabel *normalFileDetailLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = @"转码时间较短";
        label.textColor = BJLIcTheme.viewSubTextColor;
        label.font = [UIFont systemFontOfSize:12.0];
        label;
    });
    [self.addDocumentContainerView addSubview:normalFileDetailLabel];
    UIImageView *normalIcon = [[UIImageView alloc] initWithImage:[UIImage bjlic_imageNamed:@"bjl_document_upload"] highlightedImage:[UIImage bjlic_imageNamed:@"bjl_document_upload_highlight"]];
    [self.addDocumentContainerView addSubview:normalIcon];
    
    [normalFileImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.addNormalDocumentFileEmptyButton).offset(iPhone ? 6.0 : 10.0);
        make.height.centerY.equalTo(self.addNormalDocumentFileEmptyButton);
        make.width.equalTo(normalFileImageView.bjl_height).multipliedBy(normalFileImageView.image.size.width / normalFileImageView.image.size.height);
    }];
    
    [normalFileLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.bottom.equalTo(normalFileImageView.bjl_centerY).offset(0.0);
        make.left.equalTo(normalFileImageView.bjl_right);
        make.height.equalTo(@16.0);
    }];
    [normalFileDetailLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(normalFileImageView.bjl_centerY).offset(3.0);
        make.left.height.equalTo(normalFileLabel);
    }];
    [normalIcon bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.addNormalDocumentFileEmptyButton);
        make.width.height.equalTo(@(24));
        make.right.lessThanOrEqualTo(self.addNormalDocumentFileEmptyButton).offset(-20);
    }];
    
    // animate file image
    self.addAnimatedDocumentFileEmptyButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor clearColor];
        button.layer.cornerRadius = 4.0;
        button.layer.borderWidth = 1.0;
        button.layer.borderColor = BJLIcTheme.buttonBorderColor.CGColor;
        [button setBackgroundImage:[UIImage bjl_imageWithColor:[UIColor bjl_colorWithHex:0X9FA8B5 alpha:0.3]] forState:UIControlStateHighlighted];
        button;
    });
    [self.addDocumentContainerView addSubview:self.addAnimatedDocumentFileEmptyButton];
    [self.addAnimatedDocumentFileEmptyButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.height.width.equalTo(self.addNormalDocumentFileEmptyButton);
        make.left.equalTo(self.addNormalDocumentFileEmptyButton.bjl_right).offset(20);
    }];
    
    UIImageView *animatedFileImageView = [UIImageView new];
    animatedFileImageView.image = [UIImage bjlic_imageNamed:@"bjl_document_animatedfile"];
    [self.addDocumentContainerView addSubview:animatedFileImageView];
    // animate file label
    UILabel *animatedFileLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentRight;
        label.text = @"上传动效文件";
        label.textColor = BJLIcTheme.viewTextColor;
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self.addDocumentContainerView addSubview:animatedFileLabel];
    // animate file detail label
    UILabel *animatedFileDetailLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = @"转码时间较长";
        label.textColor = BJLIcTheme.viewSubTextColor;
        label.font = [UIFont systemFontOfSize:12.0];
        label;
    });
    [self.addDocumentContainerView addSubview:animatedFileDetailLabel];
    UIImageView *animateIcon = [[UIImageView alloc] initWithImage:[UIImage bjlic_imageNamed:@"bjl_document_upload"] highlightedImage:[UIImage bjlic_imageNamed:@"bjl_document_upload_highlight"]];
    [self.addDocumentContainerView addSubview:animateIcon];
    
    [animatedFileImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.addAnimatedDocumentFileEmptyButton).offset(iPhone ? 6.0 : 10.0);
        make.height.centerY.equalTo(self.addAnimatedDocumentFileEmptyButton);
        make.width.equalTo(animatedFileImageView.bjl_height).multipliedBy(animatedFileImageView.image.size.width / animatedFileImageView.image.size.height);
    }];
    
    [animatedFileLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.bottom.equalTo(animatedFileImageView.bjl_centerY).offset(0.0);
        make.left.equalTo(animatedFileImageView.bjl_right);
        make.height.equalTo(@16.0);
    }];
    [animatedFileDetailLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(animatedFileImageView.bjl_centerY).offset(3.0);
        make.left.height.equalTo(animatedFileLabel);
    }];
    [animateIcon bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.addAnimatedDocumentFileEmptyButton);
        make.width.height.equalTo(normalIcon);
        make.right.lessThanOrEqualTo(self.addAnimatedDocumentFileEmptyButton).offset(-20);
    }];
    
    // notice label
    UILabel *noticeLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.lineBreakMode =  NSLineBreakByTruncatingTail;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = BJLIcTheme.viewSubTextColor;
        label.font = [UIFont systemFontOfSize:14.0];
        label.text = @"1. 动效文件支持ppt、pptx、zip(H5)格式，上传后还原源文件中的动效\n"
        "2. 普通文件支持ppt、pptx、doc、docx、jpg、pdf格式\n"
        "3. 文件中不能包含密码\n"
        "4. WPS编辑的文档请转换成PDF后上传";
        label;
    });
    [self.addDocumentContainerView addSubview:noticeLabel];
    [noticeLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.addNormalDocumentFileEmptyButton);
        make.width.equalTo(self.addDocumentContainerView).multipliedBy(0.9);
        make.top.greaterThanOrEqualTo(animatedFileImageView.bjl_bottom);
        make.bottom.equalTo(self.addDocumentContainerView).offset(-30);
    }];    
}

#pragma mark - Observing

- (void)makeObservingForDoc {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, allDocumentsDidOverwrite:)
             observer:^BOOL{
        bjl_strongify(self);
        [self loadAllRemoteDocuments:self.room.documentVM.allDocuments];
        return YES;
    }];
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didAddDocument:)
             observer:^BOOL(BJLDocument *document) {
        bjl_strongify(self);
        // 更新文档状态
        [self updateDocumentsListWithDocument:document];
        return YES;
    }];
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didDeleteDocument:)
             observer:^BOOL(BJLDocument *document) {
        bjl_strongify(self);
        BJLDocumentFile *documentFile = [self documentFileWithLocalID:nil fileID:document.fileID];
        [self deleteDocumetFile:documentFile];
        return YES;
    }];
}

// 加载所有远端文档
- (void)loadAllRemoteDocuments:(NSArray<BJLDocument *> *)documents {
    [self.mutableAllDocumentFileList removeAllObjects];
    [self.mutableDocumentSearchResultFileList removeAllObjects];
    
    NSMutableArray *mutableRelatedDocumentFileList = [NSMutableArray new];
    NSMutableArray *mutableDocumentFileList = [NSMutableArray new];
    
    for (BJLDocument *document in documents) {
        if ([document.documentID isEqualToString:BJLBlackboardID]) {
            continue; // 白板不计入
        }
        if ([document.documentID isEqualToString:BJLWritingboardID]) {
            continue; // 小黑板不计入
        }
        BJLDocumentFile *documentFile = [[BJLDocumentFile alloc] initWithRemoteDocument:document];
                
        if (documentFile.isRelatedDocument) {
            [mutableRelatedDocumentFileList bjl_addObject:documentFile];
        }
        else {
            [mutableDocumentFileList bjl_addObject:documentFile];
        }
    }
    
    NSMutableArray *mutableAllDocumentFileList = [NSMutableArray new];
    if ([mutableRelatedDocumentFileList count]) {
        [mutableAllDocumentFileList addObjectsFromArray:[mutableRelatedDocumentFileList copy]];
    }
    if ([mutableDocumentFileList count]) {
        [mutableAllDocumentFileList addObjectsFromArray:[mutableDocumentFileList copy]];
    }
    self.mutableAllDocumentFileList = mutableAllDocumentFileList;
    [self removeFromTranscodeDocumentListWith:documents];
    [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeDocument];
}

// 收到信令, 过滤本地上传转码的课件list
- (void)removeFromTranscodeDocumentListWith:(NSArray<BJLDocument *> *)documents {
    if (![documents count]) {
        return;
    }
    NSMutableArray<BJLDocumentFile *> *mutableTranscodeFileList = [self.mutableTranscodeDocumentFileList mutableCopy];
    for (BJLCloudFile *document in documents) {
        [self.mutableTranscodeDocumentFileList enumerateObjectsUsingBlock:^(BJLDocumentFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.remoteDocument.fileID isEqualToString:document.fileID]) {
                [mutableTranscodeFileList bjl_removeObject:obj];
                *stop = YES;
            }
        }];
    }
    self.mutableTranscodeDocumentFileList = [mutableTranscodeFileList mutableCopy];
}

// 更新文档列表, 使用远端文档数据
- (void)updateDocumentsListWithDocument:(BJLDocument *)document {
    BJLDocumentFile *documentFile  = [[BJLDocumentFile alloc] initWithRemoteDocument:document];

    BJLDocumentFile *changedFile = [self documentFileWithLocalID:documentFile.localID fileID:documentFile.remoteDocument.fileID];
    // file 发生改变
    if (changedFile) {
        // 转码完成前没有办法判断是否是动态PPT，因此根据本地上传文档来判断
        documentFile.type = changedFile.type;
        documentFile.localPathURL = changedFile.localPathURL;
        [self.mutableAllDocumentFileList bjl_removeObject:changedFile];
    }
    
    [self.mutableAllDocumentFileList bjl_addObject:documentFile];

    [self removeFromTranscodeDocumentListWith:@[document]];
    [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeDocument];
}

// 上传过程中实时更新本地的上传转码list的数据
- (void)updateTranscodeListWithDocumentFile:(BJLDocumentFile *)documentFile {
    BJLDocumentFile *changedFile = nil;
    NSString *localID = documentFile.localID;
    NSString *homeworkID = documentFile.remoteDocument.documentID;
    for (BJLDocumentFile *documentFile in [self.mutableTranscodeDocumentFileList copy]) {
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
        documentFile.type = changedFile.type;
        documentFile.localPathURL = changedFile.localPathURL;
        [self.mutableTranscodeDocumentFileList removeObject:changedFile];
    }
    
    [self.mutableTranscodeDocumentFileList bjl_addObject:documentFile];
    [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeDocument];
}

- (void)deleteDocumetFile:(BJLDocumentFile *)file {
    if ([self.mutableAllDocumentFileList containsObject:file]) {
        [self.mutableAllDocumentFileList removeObject:file];
    }
    
    if ([self.mutableDocumentSearchResultFileList containsObject:file]) {
        [self.mutableDocumentSearchResultFileList bjl_removeObject:file];
    }
    
    if ([self.mutableTranscodeDocumentFileList containsObject:file]) {
        [self.mutableTranscodeDocumentFileList bjl_removeObject:file];
    }
    
    [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeDocument];
}

#pragma mark - action

// 上传文档 TODO:!!!上传时存在 BoringSSL 的警告
- (void)uploadDocumentFile:(BJLDocumentFile *)documentFile {
    // 改变状态
    documentFile.state = BJLDocumentFileUploading;
    documentFile.errorCode = 0;
    documentFile.progress = 0.0;
    [self updateTranscodeListWithDocumentFile:documentFile];
    bjl_weakify(self);
    BOOL isAnimated = documentFile.type == BJLDocumentFileAnimatedPPT;
    // 上传
    self.uploadDocumentRequest = [self.room.documentVM uploadFile:documentFile.url
                                                         mimeType:documentFile.mimeType
                                                         fileName:documentFile.name
                                                       isAnimated:isAnimated
                                                         progress:^(CGFloat progress) {
        bjl_strongify(self);
        [self updateDocumentFileWithLocalID:documentFile.localID fileID:nil progress:progress errorCode:0];
    }
                                                           finish:^(BJLDocument * _Nullable document, BJLError * _Nullable error) {
        bjl_strongify(self);
        self.uploadDocumentRequest = nil;
        if (!error) {
            // 如果文档在上传过程中删除了，丢弃远端文档
            if (![self.mutableTranscodeDocumentFileList containsObject:documentFile]) {
                return;
            }
            // 远端文档和本地文档对应，以便更新文档列表
            BJLDocumentFile *file = [[BJLDocumentFile alloc] initWithRemoteDocument:document];
            // 保存本地文件的本地路径, 方便重传/重转
            file.localPathURL = documentFile.localPathURL;
            file.localID = documentFile.localID;
            // 设置状态为转码, 重置进度，更新文档列表
            file.state = BJLDocumentFileTranscoding;
            file.progress = 0.0;
            [self updateTranscodeListWithDocumentFile:file];
            if (file.type == BJLDocumentFileImage) {
                // 图片不需要转码，直接添加到教室
                [self finishUpdateDocumentFileWithFileID:file.remoteDocument.fileID];
            }
            else {
                // 开始轮询转码进度
                [self startPollTimer];
            }
        }
        else {
            documentFile.state = BJLDocumentFileUploadError;
            documentFile.errorMessage = error.localizedFailureReason ?: @"上传失败，请重新上传！";
            [self updateTranscodeListWithDocumentFile:documentFile];
        }
    }];
    [self reloadTableViewWithLayoutType:BJLIcDocumentFileLayoutTypeDocument];
}

// 删除选中的文档, 不等待返回删除成功
- (void)deleteSelectedDocumentFile:(BJLDocumentFile *)file {
    if (file.state == BJLDocumentFileUploading) {
        [self.uploadDocumentRequest cancel];
        self.uploadDocumentRequest = nil;
    }
    
    if (file.state == BJLDocumentFileNormal) {
        BJLError *error = [self.room.documentVM deleteDocumentWithID:file.remoteDocument.documentID];
        if (error) {
            NSLog(@"error occur when delete file %@ error %@", file.name, error);
            return;
        }
    }
    [self deleteDocumetFile:file];
}

#pragma mark - wheel

- (nullable BJLDocumentFile *)documentFileWithLocalID:(nullable NSString *)localID
                                               fileID:(nullable NSString *)fileID {
    for (BJLDocumentFile *documentFile in [self.mutableAllDocumentFileList copy]) {
        if (localID.length && [documentFile.localID isEqualToString:localID]) {
            return documentFile;
        }
        else if (fileID.length && [documentFile.remoteDocument.fileID isEqualToString:fileID]) {
            return documentFile;
        }
    }
    for (BJLDocumentFile *documentFile in [self.mutableTranscodeDocumentFileList copy]) {
        if (localID.length && [documentFile.localID isEqualToString:localID]) {
            return documentFile;
        }
        else if (fileID.length && [documentFile.remoteDocument.fileID isEqualToString:fileID]) {
            return documentFile;
        }
    }
    
    for (BJLDocumentFile *documentFile in [self.mutableAllDocumentFileList copy]) {
        if (localID.length && [documentFile.localID isEqualToString:localID]) {
            return documentFile;
        }
        else if (fileID.length && [documentFile.remoteDocument.fileID isEqualToString:fileID]) {
            return documentFile;
        }
    }
    return nil;
}

@end
