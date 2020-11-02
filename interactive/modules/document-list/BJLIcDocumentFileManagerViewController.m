//
//  BJLIcDocumentFileManagerViewController.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/26.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveBase/BJLNetworking+BaijiaYun.h>
#import <BJLiveBase/BJLError.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcDocumentFileManagerViewController.h"
#import "BJLIcDocumentFileManagerViewController+private.h"
#import "BJLIcPopoverViewController.h"
#import "BJLIcAppearance.h"
#import "BJLIcDocumentFileCell.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcDocumentFileManagerViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super init]) {
        self.room = room;
        self.mutableAllDocumentFileList = [NSMutableArray new];
        self.mutableTranscodeDocumentFileList = [NSMutableArray new];
        self.mutableDocumentSearchResultFileList = [NSMutableArray new];
        self.mutableCloudFileList = [NSMutableArray new];
        self.mutableTranscodeCloudFileList = [NSMutableArray new];
        self.mutableCloudSearchResultFileList = [NSMutableArray new];
        self.syncCloudFidArray = [NSMutableArray new];
        self.mutableHomeworkFileList = [NSMutableArray new];
        self.mutableHomeworkSearchResultFileList = [NSMutableArray new];
        self.syncHomeworkFidArray = [NSMutableArray new];
        self.homeworkCursor = nil;
        self.shouldShowHomeworkSupportView = YES;
        self.finishDocumentFileIDList = [NSMutableArray new];
        self.mutableTranscodeHomeworkFileList = [NSMutableArray new];
        [self makeObserving];
        if (self.room.state == BJLRoomState_connected) {
            [self loadAllRemoteDocuments:self.room.documentVM.allDocuments];
            [self loadAllRemoteHomeworks:self.room.homeworkVM.allHomeworks];
        }
    }
    return self;
}

- (void)dealloc {
    self.documentFileView.tableView.delegate = nil;
    self.documentFileView.tableView.dataSource = nil;
    [self bjl_stopAllMethodParametersObserving];
    [self stopPollTimer];
    [self.progressTimer invalidate];
    self.progressTimer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [BJLDownloadManager downloadManagerWithIdentifier:@"homeworkDownloadManager"];
    self.manager.delegate = self;
    
    [self makeSubviewsAndConstraints];
    [self makeActions];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadTableViewWithLayoutType:self.documentFileLayoutType];
}

- (void)makeSubviewsAndConstraints {
    self.view.backgroundColor = [UIColor clearColor];
    // 毛玻璃效果
    UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIView *backgroundView = [[UIVisualEffectView alloc] initWithEffect:effect];
    [self.view addSubview:backgroundView];
    [backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.documentFileView = [[BJLIcDocumentFileView alloc] initWithRoom:self.room];
    self.documentFileView.tableView.delegate = self;
    self.documentFileView.tableView.dataSource = self;
    for (NSString *cellIdentifier in [BJLIcDocumentFileCell allCellIdentifiers]) {
        [self.documentFileView.tableView registerClass:[BJLIcDocumentFileCell class] forCellReuseIdentifier:cellIdentifier];
    }
    [self.view addSubview:self.documentFileView];
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    UIEdgeInsets edgeinset = iPhone ? UIEdgeInsetsMake(8, 8, 8, 8) : UIEdgeInsetsMake(72, 44, 72, 44);
    [self.documentFileView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view).insets(edgeinset);
    }];
    [self updateDocumentFileViewHidden];
    [self makeDocumentFileViewCallback];
    [self makeObservingForDocumentFileView];
    
    UITapGestureRecognizer *tapGesture = ({
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboardView)];
        tapGesture.numberOfTapsRequired = 1;
        tapGesture;
    });
    // overlay
    self.overlayView = ({
        UIView *view = [UIView new];
        view.userInteractionEnabled = YES;
        view.backgroundColor = [UIColor clearColor];
        [view addGestureRecognizer:tapGesture];
        view.accessibilityLabel = BJLKeypath(self, overlayView);
        view;
    });
    
    if (self.room.loginUser.isTeacherOrAssistant) {
        [self makeDocumentChooseView];
    }
}

#pragma mark - observing

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_kvoMerge:@[BJLMakeProperty(self, uploadDocumentRequest),
                         BJLMakeProperty(self, uploadHomeworkRequest),
                         BJLMakeProperty(self, uploadCloudFileRequest)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        BOOL hasDocumentUpload = self.uploadDocumentRequest && (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeDocument);
        BOOL hasCloudUpload = self.uploadCloudFileRequest && (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeCloud);
        BOOL hasHomeworkUpload = self.uploadHomeworkRequest && (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework);
        self.documentFileView.uploadFileButton.enabled = !(hasDocumentUpload || hasCloudUpload || hasHomeworkUpload);
    }];
    
    [self makeObservingForDoc];
    [self makeObservingForHomework];
}

- (void)makeObservingForDocumentFileView {
    bjl_weakify(self);
    
    self.progressTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify_ifNil(self) {
            [timer invalidate]; // or invalidate in dealloc
            return;
        }
        NSArray<NSIndexPath *> *indexPaths = [self.documentFileView.tableView indexPathsForVisibleRows];
        
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden
            || ![indexPaths count] || self.shouldShowSearchResult) {
            return;
        }
        
        for (NSIndexPath *indexPath in indexPaths) {
            BJLDocumentFile *file = [self documentFileWithIndexPath:indexPath];
            BJLIcDocumentFileCell *cell = [[self.documentFileView.tableView cellForRowAtIndexPath:indexPath] bjl_as:[BJLIcDocumentFileCell class]];
            if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework) {
                BJLHomeworkDownloadItem *downloadItem = [self localDownloadItemWithHomeworkFile:file];
                [cell updateWithDocumentFile:file downloadItem:downloadItem loginUser:self.room.loginUser isCloudSync:NO];
            }
            else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeDocument) {
                [cell updateWithDocumentFile:file downloadItem:nil loginUser:self.room.loginUser isCloudSync:NO];
            }
            else {
                [cell updateWithDocumentFile:file downloadItem:nil loginUser:self.room.loginUser isCloudSync:[self.syncCloudFidArray containsObject:file.remoteCloudFile.fileID]];
            }
        }
    }];
    
    [self.documentFileView setWillshowFilelistCallback:^ {
        bjl_strongify(self);
        [self reloadTableViewWithLayoutType:self.documentFileLayoutType];
        
        BOOL hasDocumentUpload = self.uploadDocumentRequest && (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeDocument);
        BOOL hasCloudUpload = self.uploadCloudFileRequest && (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeCloud);
        BOOL hasHomeworkUpload = self.uploadHomeworkRequest && (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework);
        self.documentFileView.uploadFileButton.enabled = !(hasDocumentUpload || hasCloudUpload || hasHomeworkUpload);
        
        NSString *title = (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework) ? @"上传作业" : @"上传文件";
        [self.documentFileView.uploadFileButton setTitle:title forState:UIControlStateNormal];
        [self.documentFileView.uploadFileButton setTitle:title forState:UIControlStateNormal | UIControlStateHighlighted];
        
        if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeCloud) {
            if (self.requestListTask) {
                return;
            }
            [self loadAllRemoteCloudDocuments];
        }
    }];
    
    [self.documentFileView setUploadFileCallback:^{
        bjl_strongify(self);
        if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework) {
            [self showHomeWorkPickerViewController];
        }
        else {
            [self showChooseAnimatedOrNormalFileView];
        }
    }];
    
    [self.documentFileView setRefreshHomeworkCallback:^{
        bjl_strongify(self);
        if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework) {
            if (!self.room.loginUser.isTeacherOrAssistant) {
                BJLError *error = [self.room.homeworkVM reloadAllHomeworks];
                if (error) {
                    self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
                }
            }
            else {
                [self.room.homeworkVM requestForceRefreshHomeworkListWithCompletion:^(BOOL success, BJLError * _Nullable error) {
                    bjl_strongify(self);
                    if (error) {
                        self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
                    }
                }];
            }
        }
        else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeDocument) {
            bjl_returnIfRobot(1);
            [self.room.documentVM loadAllDocuments];
        }
        else {
            if (self.requestListTask) {
                [self.requestListTask cancel];
                self.requestListTask = nil;
            }
            
            [self loadAllRemoteCloudDocuments];
        }
    }];
}

#pragma mark - actions

- (void)makeActions {
    // close button
    [self.documentFileView.closeButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    // add animate document file
    [self.addAnimatedDocumentFileEmptyButton addTarget:self action:@selector(addAnimatedDocumentFile) forControlEvents:UIControlEventTouchUpInside];
    // add normal document file
    [self.addNormalDocumentFileEmptyButton addTarget:self action:@selector(addNormalDocumentFile) forControlEvents:UIControlEventTouchUpInside];
    self.documentFileView.searchTextField.delegate = self;
    [self.documentFileView.searchTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

// 隐藏
- (void)hide {
    if (self.hideCallback) {
        self.hideCallback();
    }
    [self bjl_removeFromParentViewControllerAndSuperiew];
}

#pragma mark - choose Animated/Normal file

- (void)showChooseAnimatedOrNormalFileView {
    self.chooseDocumentLayer.hidden = NO;
}

// 添加动态PPT
- (void)addAnimatedDocumentFile {
    self.chooseDocumentLayer.hidden = YES;
    self.isSelectAnimatedDocumentFile = YES;
    [self showDocumentPickerViewController];
}

// 添加普通PPT
- (void)addNormalDocumentFile {
    self.chooseDocumentLayer.hidden = YES;
    self.isSelectAnimatedDocumentFile = NO;
    [self showDocumentPickerViewController];
}

- (void)showDocumentPickerViewController {
    if (@available(iOS 11.0, *)) {
        // open 仅限于打开自己的文件, import 可以导入共享的文件
        NSArray *array = @[@"public.data"];
        if (self.isSelectAnimatedDocumentFile) {
            array = @[@"org.openxmlformats.presentationml.presentation", @"com.microsoft.powerpoint.ppt"];
        }
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

- (void)reloadTableViewWithLayoutType:(BJLIcDocumentFileLayoutType)layoutType {
    if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden
        || (self.documentFileLayoutType != layoutType)) {
        return;
    }
    
    [self updateDocumentFileViewHidden];
    [self.documentFileView.tableView reloadData];
    
    if (self.documentFileLayoutType != BJLIcDocumentFileLayoutTypeHomework) {
        return;
    }
    
    NSArray<NSIndexPath *> *indexPaths = [self.documentFileView.tableView indexPathsForVisibleRows];
    if ([indexPaths count] == [self allDocumentFileListCountOfTableView] && [indexPaths count] > 0) {
        if (self.shouldShowSearchResult && self.hasmore) {
            bjl_returnIfRobot(1.0);
            BJLError *error = [self.room.homeworkVM searchHomeworksWithKeyword:self.documentFileView.searchTextField.text lastHomework:self.homeworkCursor count:20];
            if(error) {
                self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            }
        }
        else if (!self.shouldShowSearchResult && self.room.homeworkVM.hasMoreHomeworks) {
            bjl_returnIfRobot(1.0);
            BJLError *error = [self.room.homeworkVM loadMoreHomeworksWithCount:20];
            if(error) {
                self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            }
        }
    }
}

- (NSInteger)allDocumentFileListCountOfTableView {
    if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeCloud) {
        if (self.shouldShowSearchResult) {
            return [self.mutableCloudSearchResultFileList count];
        }
        else {
            return [self.mutableCloudFileList count] + [self.mutableTranscodeCloudFileList count];
        }
    }
    else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeDocument) {
        if (self.shouldShowSearchResult) {
            return [self.mutableDocumentSearchResultFileList count];
            ;
        }
        else {
            return [self.mutableAllDocumentFileList count] + [self.mutableTranscodeDocumentFileList count];
        }
    }
    else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework) {
        if (self.shouldShowSearchResult) {
            return [self.mutableHomeworkSearchResultFileList count];
        }
        else {
            return [self.mutableHomeworkFileList count] + [self.mutableTranscodeHomeworkFileList count];
        }
    }
    return 0;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.documentFileView.searchTextField) {
        if (self.overlayView.superview && self.overlayView.superview != self.view) {
            if ([self.overlayView respondsToSelector:@selector(removeFromSuperview)]) {
                [self.overlayView removeFromSuperview];
            }
        }
        
        if (!self.overlayView.superview) {
            [self.view addSubview:self.overlayView];
            [self.overlayView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.view);
            }];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self reloadSearchResultTableViewWith:textField.text];
    return NO;
}

- (void)textFieldDidChange:(UITextField *)textField {
    UITextRange * selectedRange = textField.markedTextRange;
    if(selectedRange == nil || selectedRange.empty){
        NSString *text = textField.text;
        [self reloadSearchResultTableViewWith:text];
    }
}

- (void)reloadSearchResultTableViewWith:(NSString *)keyWord {
    self.documentFileView.clearSearchButton.hidden = !keyWord.length;
    if (!keyWord.length) {
        [self.mutableDocumentSearchResultFileList removeAllObjects];
        [self.mutableHomeworkSearchResultFileList removeAllObjects];
        [self.mutableCloudSearchResultFileList removeAllObjects];
        self.homeworkCursor = nil;
        self.documentFileView.shouldShowSearchResult = NO;
        [self reloadTableViewWithLayoutType:self.documentFileLayoutType];
        return;
    }
    
    NSMutableArray <BJLDocumentFile *> *resultArray = [NSMutableArray new];
    
    if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeDocument) {
        for (BJLDocumentFile *documentFile in [self.mutableAllDocumentFileList copy]) {
            if ([documentFile.name containsString:keyWord]) {
                [resultArray bjl_addObject:documentFile];
            }
        }
        for (BJLDocumentFile *documentFile in [self.mutableTranscodeDocumentFileList copy]) {
            if ([documentFile.name containsString:keyWord]) {
                [resultArray bjl_addObject:documentFile];
            }
        }
        self.mutableDocumentSearchResultFileList = resultArray;
    }
    else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework) {
        self.homeworkCursor = nil;
        [self.mutableHomeworkSearchResultFileList removeAllObjects];
        [self.room.homeworkVM searchHomeworksWithKeyword:keyWord lastHomework:self.homeworkCursor count:20];
    }
    else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeCloud) {
        for (BJLDocumentFile *documentFile in [self.mutableCloudFileList copy]) {
            if ([documentFile.name containsString:keyWord]) {
                [resultArray bjl_addObject:documentFile];
            }
        }
        for (BJLDocumentFile *documentFile in [self.mutableTranscodeCloudFileList copy]) {
            if ([documentFile.name containsString:keyWord]) {
                [resultArray bjl_addObject:documentFile];
            }
        }
        self.mutableCloudSearchResultFileList = resultArray;
    }
    self.documentFileView.shouldShowSearchResult = YES;
    [self reloadTableViewWithLayoutType:self.documentFileLayoutType];
}

#pragma mark - tableview view data source & delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.shouldShowSearchResult) {
        return 1;
    }
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self documentFileListWithSection:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLDocumentFile *file = [self documentFileWithIndexPath:indexPath];
    NSString *cellIdentifier = [BJLIcDocumentFileCell cellIdentifierForCellType:(BJLIcDocumentFileCellType)self.documentFileLayoutType];
    BJLIcDocumentFileCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    BJLHomeworkDownloadItem *downloadItem = [self localDownloadItemWithHomeworkFile:file];
    
    BOOL isCloudSync = (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeCloud) ? [self.syncCloudFidArray containsObject:file.remoteCloudFile.fileID] : NO;
    [cell updateWithDocumentFile:file downloadItem:downloadItem loginUser:self.room.loginUser isCloudSync:isCloudSync];
    bjl_weakify(self)
    [cell setShowDocumentCallback:^{
        bjl_strongify(self);
        BJLDocumentFile *file = [self documentFileWithIndexPath:indexPath];
        if (![file shouldSupportUploadAndPlay]) {
            if (self.showErrorMessageCallback) {
                self.showErrorMessageCallback(@"只支持PC端打开");
            }
            return;
        }
        
        if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeDocument) {
            if (self.selectDocumentFileCallback) {
                self.selectDocumentFileCallback(file, nil);
            }
        }
        else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeCloud) {
            [self syncAndOpenCloudDocumentFile:file];
        }
        else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework) {
            [self syncAndOpenHomeworkDocumentFile:file];
        }
    }];
    
    [cell setDownloadDocumentCallback:^(UIButton *button){
        bjl_strongify(self);
        CGRect rectForOpenInIpad = [button.superview convertRect:button.frame toView:self.view];
        BJLDocumentFile *file = [self documentFileWithIndexPath:indexPath];
        [self downloadActionWithHomeworkFile:file withRect:rectForOpenInIpad];
    }];
    
    [cell setDeleteDocumentCallback:^{
        bjl_strongify(self);
        BJLDocumentFile *file = [self documentFileWithIndexPath:indexPath];
        [self deleteActionInCellWithFile:file];
    }];
    
    [cell setShowErrorCallback:^(UIButton *button) {
        bjl_strongify(self);
        BJLDocumentFile *file = [self documentFileWithIndexPath:indexPath];
        UILabel *errorLabel = [self makeErrorTipLableWithText:file.errorMessage];
        CGSize size = [self bjlic_suitableSizeWithText:errorLabel.text attributedText:nil maxWidth:300];
        UIViewController *optionViewController = ({
            UIViewController *viewController = [[UIViewController alloc] init];
            viewController.view.backgroundColor = BJLIcTheme.windowBackgroundColor;
            viewController.modalPresentationStyle = UIModalPresentationPopover;
            viewController.preferredContentSize = CGSizeMake(size.width + 20.0, 50);
            viewController.popoverPresentationController.backgroundColor = BJLIcTheme.windowBackgroundColor;
            viewController.popoverPresentationController.delegate = self;
            viewController.popoverPresentationController.sourceView = button;
            viewController.popoverPresentationController.sourceRect = CGRectMake(button.bounds.origin.x + 5, button.bounds.origin.y, 1.0, 1.0);
            viewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionDown;
            viewController;
        });
        [optionViewController.view addSubview:errorLabel];
        [errorLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(optionViewController.view).insets(UIEdgeInsetsMake(10, 10, 20, 10));
        }];
        if (self.parentViewController.presentedViewController) {
            [self.parentViewController.presentedViewController bjl_dismissAnimated:YES completion:nil];
        }
        [self.parentViewController presentViewController:optionViewController animated:YES completion:nil];
    }];
    
    [cell setReuploadCallback:^{
        bjl_strongify(self);
        BJLDocumentFile *file = [self documentFileWithIndexPath:indexPath];
        BJLDocumentFileType fileType = file.type;
        [self deleteFile:file];
        
        if (!file.localPathURL) {
            if (self.showErrorMessageCallback) {
                self.showErrorMessageCallback(@"请重新上传");
            }
            return;
        }
        UIDocument *document = [[UIDocument alloc] initWithFileURL:file.localPathURL];
        BJLDocumentFile *documentFile = [[BJLDocumentFile alloc] initWithLocalDocument:document];
        documentFile.type = fileType;
        if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeDocument) {
            [self uploadDocumentFile:documentFile];
        }
        else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeCloud) {
            [self uploadCloudDocumentFile:documentFile];
        }
    }];
    
    [cell setTurnToNormalDocumentCallback:^{
        bjl_strongify(self);
        BJLDocumentFile *file = [self documentFileWithIndexPath:indexPath];
        [self deleteSelectedDocumentFile:file];
        if (!file.localPathURL) {
            if (self.showErrorMessageCallback) {
                self.showErrorMessageCallback(@"请重新上传");
            }
            return;
        }
        UIDocument *document = [[UIDocument alloc] initWithFileURL:file.localPathURL];
        BJLDocumentFile *documentFile = [[BJLDocumentFile alloc] initWithLocalDocument:document];
        documentFile.type = BJLDocumentFileNormalPPT;
        if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeDocument) {
            [self uploadDocumentFile:documentFile];
        }
        else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeCloud) {
            [self uploadCloudDocumentFile:documentFile];
        }
    }];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)deleteActionInCellWithFile:(BJLDocumentFile *)file {
    // 如果是上传中的文档 , 取消上传
    if (file.state == BJLDocumentFileUploading || file.state == BJLDocumentFileUploadError || file.state == BJLDocumentFileTranscodeError) {
        [self deleteFile:file];
        return;
    }
    
    NSString *tipMessage = nil;
    if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeDocument) {
        tipMessage = @"确定删除课件吗?";
    }
    else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeCloud) {
        tipMessage = @"确定删除云盘文件吗?";
    }
    else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework) {
        tipMessage = @"确定删除作业吗?";
    }
    
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcDeletePPT message:tipMessage];
    [self bjl_addChildViewController:popoverViewController superview:self.view];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    bjl_weakify(self);
    [popoverViewController setConfirmCallback:^{
        bjl_strongify(self);
        [self deleteFile:file];
    }];
}

- (void)deleteFile:(BJLDocumentFile *)file {
    if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeDocument) {
        [self deleteSelectedDocumentFile:file];
    }
    else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeCloud) {
        [self deleteSelectedCloudDocumentFile:file];
    }
    else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework) {
        [self deleteSelectedHomework:file];
    }
}

#pragma mark - load more user

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.dragging && !scrollView.decelerating) {
        return;
    }
    // 只有台下用户列表会存在更多用户的情况
    if (!self.documentFileView.tableView.hidden
        && self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework
        && [self atTheBottomOfTableView]) {
        if (self.shouldShowSearchResult && self.hasmore) {
            bjl_returnIfRobot(1.0);
            BJLError *error = [self.room.homeworkVM searchHomeworksWithKeyword:self.documentFileView.searchTextField.text lastHomework:self.homeworkCursor count:20];
            if(error) {
                self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            }
        }
        else if (!self.shouldShowSearchResult && self.room.homeworkVM.hasMoreHomeworks) {
            bjl_returnIfRobot(1.0);
            BJLError *error = [self.room.homeworkVM loadMoreHomeworksWithCount:20];
            if(error) {
                self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            }
        }
    }
}

- (BOOL)atTheBottomOfTableView {
    UITableView *tableView = self.documentFileView.tableView;
    CGFloat contentOffsetY = tableView.contentOffset.y;
    CGFloat bottom = tableView.contentInset.bottom;
    CGFloat viewHeight = CGRectGetHeight(tableView.frame);
    CGFloat contentHeight = tableView.contentSize.height;
    CGFloat bottomOffset = contentOffsetY + viewHeight - bottom - contentHeight;
    return bottomOffset >= 0.0 - 50;
}


#pragma mark - UIDocumentPicker Delegate

// TODO:选取的文件存在没有预览图的警告
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    self.chooseDocumentLayer.hidden = YES;
    for (NSURL *url in urls) {
        UIDocument *document = [[UIDocument alloc] initWithFileURL:url];
        BJLDocumentFile *documentFile = [[BJLDocumentFile alloc] initWithLocalDocument:document];
        documentFile.type = self.isSelectAnimatedDocumentFile ? BJLDocumentFileAnimatedPPT : documentFile.type;
        if (![documentFile shouldSupportUploadAndPlay]) {
            if (self.showErrorMessageCallback) {
                self.showErrorMessageCallback(@"上传文件格式不支持");
            }
            return;
        }
        
        if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeDocument) {
            [self uploadDocumentFile:documentFile];
        }
        else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework) {
            [self uploadHomeWorkFile:documentFile];
        }
        else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeCloud) {
            [self uploadCloudDocumentFile:documentFile];
        }
    }
    self.isSelectAnimatedDocumentFile = NO;
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

#pragma mark -

- (nullable NSArray<BJLDocumentFile *> *)documentFileListWithSection:(NSInteger)section {
    NSArray<BJLDocumentFile *> *fileList = nil;
    if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeCloud) {
        if (self.shouldShowSearchResult) {
            fileList = self.mutableCloudSearchResultFileList;
        }
        else {
            if (section == 0) {
                fileList = self.mutableCloudFileList;
            }
            else {
                fileList = self.mutableTranscodeCloudFileList;
            }
        }
    }
    else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeDocument) {
        if (self.shouldShowSearchResult) {
            fileList = self.mutableDocumentSearchResultFileList;
        }
        else {
            if (section == 0) {
                fileList = self.mutableAllDocumentFileList;
            }
            else {
                fileList = self.mutableTranscodeDocumentFileList;
            }
        }
    }
    else if (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework) {
        if (self.shouldShowSearchResult) {
            fileList = self.mutableHomeworkSearchResultFileList;
        }
        else {
            if (section == 0) {
                fileList = self.mutableHomeworkFileList;
            }
            else {
                fileList = self.mutableTranscodeHomeworkFileList;
            }
        }
    }
    return fileList;
}

- (nullable BJLDocumentFile *)documentFileWithIndexPath:(NSIndexPath *)indexPath {
    NSArray<BJLDocumentFile *> *fileList = [self documentFileListWithSection:indexPath.section];
    return [fileList bjl_objectAtIndex:indexPath.row];
}

- (void)updateDocumentFileViewHidden {
    NSInteger cloudFileCount = [self.mutableTranscodeCloudFileList count] + [self.mutableCloudFileList count];
    BOOL hasCloudFile = (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeCloud) && (self.shouldShowSearchResult ? [self.mutableCloudSearchResultFileList count] : cloudFileCount);
    
    NSInteger documentCount = [self.mutableAllDocumentFileList count] + [self.mutableTranscodeDocumentFileList count];
    BOOL hasDocument = (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeDocument) && (self.shouldShowSearchResult ? [self.mutableDocumentSearchResultFileList count] : documentCount);
    
    NSInteger homeworkFileCount = [self.mutableTranscodeHomeworkFileList count] + [self.mutableHomeworkFileList count];
    BOOL hasHomework = (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework) && (self.shouldShowSearchResult ? [self.mutableHomeworkSearchResultFileList count] : homeworkFileCount);
    
    [self.documentFileView updateDocumentFileViewHidden:!hasDocument && !hasCloudFile && !hasHomework];
}

- (BJLIcDocumentFileLayoutType)documentFileLayoutType {
    return self.documentFileView.documentFileLayoutType;
}

- (BOOL)shouldShowSearchResult {
    return self.documentFileView.shouldShowSearchResult;
}

- (void)hideKeyboardView {
    [self.documentFileView.searchTextField resignFirstResponder];
    
    if ([self.overlayView respondsToSelector:@selector(removeFromSuperview)]) {
        [self.overlayView removeFromSuperview];
    }
}

- (UILabel *)makeErrorTipLableWithText:(NSString *)errorMessage {
    UILabel *label = [UILabel new];
    label.textColor = BJLIcTheme.viewTextColor;
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.text = errorMessage;
    return label;
}

@end

NS_ASSUME_NONNULL_END
