//
//  BJLIcDocumentFileVIew.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/26.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcDocumentFileView.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDocumentFileView ()

@property (nonatomic, weak) BJLRoom *room;

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIView *topSingleLine;
@property (nonatomic, readwrite) UIButton *closeButton;

// 关联文件/教室内上传文件 选择栏
@property (nonatomic) UIView *documentTypeLine, *searchSingleLine;
@property (nonatomic, readwrite) UIButton *documentTipButton;
@property (nonatomic, readwrite) UIButton *showDocumentButton;
@property (nonatomic, readwrite) UIButton *showMyCloudFileButton;
@property (nonatomic, readwrite) UIButton *showMyHomeworkButton;

// 关联文档 & 作业区搜索视图
@property (nonatomic, readwrite) UIView *searchContainerView, *searchTextFieldContainerView;
@property (nonatomic, readwrite) BJLButton *uploadFileButton, *allowStudentUploadButton;
@property (nonatomic, readwrite) UITextField *searchTextField;
@property (nonatomic, readwrite) UIButton *clearSearchButton;

// 如果存在文档, 显示 tableview
@property (nonatomic, readwrite) UITableView *tableView;

// 如果不存在文档, 显示 empty view, 所有内容都加到这个视图上
@property (nonatomic, readwrite) UIView *emptyView;
@property (nonatomic, readwrite) UILabel *emptyMessageLabel;

// 当前展示的文档类型
@property (nonatomic, readwrite) BJLIcDocumentFileLayoutType documentFileLayoutType;

@end

@implementation BJLIcDocumentFileView

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super init]) {
        self.room = room;
        self.documentFileLayoutType = -1;
        [self makeSubviewsAndConstraints];
        [self makeObserving];
    }
    return self;
}

#pragma mark - private view

- (void)makeSubviewsAndConstraints {
    self.backgroundColor = [UIColor clearColor];
    // shadow
    self.layer.masksToBounds = NO;
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.2].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 5.0);
    self.layer.shadowRadius = 10.0;
    
    UIView *backgroundView = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = BJLIcTheme.windowBackgroundColor;
        // border && corner
        view.layer.cornerRadius = 8.0;
        view.layer.masksToBounds = YES;
        view;
    });
    [self addSubview:backgroundView];
    [backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    // title
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = self.room.loginUser.isStudent ? @"作业区" : @"选择文件";
        label.textColor = BJLIcTheme.viewTextColor;
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self addSubview:self.titleLabel];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self).offset(16.0);
        make.top.equalTo(self);
        make.height.equalTo(@32.0);
    }];
    // close button
    self.closeButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"window_close"] forState:UIControlStateNormal];
        button;
    });
    [self addSubview:self.closeButton];
    [self.closeButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self).offset(-8.0);
        make.top.bottom.equalTo(self.titleLabel);
        make.width.equalTo(self.closeButton.bjl_height);
    }];
    
    // top shadow line
    self.topSingleLine = [self createShadowSingleLine];
    [self addSubview:self.topSingleLine];
    // 因为设置了不裁切, 所以左右在设置约束的时候减少 1.0, 使得显示时不会到达边界
    [self.topSingleLine bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self).offset(1.0);
        make.right.equalTo(self).offset(-1.0);
        make.top.equalTo(self.titleLabel.bjl_bottom);
        make.height.equalTo(@(1.0));
    }];
    
    if (self.room.loginUser.isTeacherOrAssistant) {
        [self makeDocumentTypeChangeView];
    }
    
    [self makeDocumentSearchView];
    [self makeDocumentsTableView];
    
    [self makeEmptyView];
    if (self.room.loginUser.isTeacherOrAssistant) {
        [self showDocument];
    }
    else {
        [self showMyHomeworkView];
    }
}

- (void)makeDocumentTypeChangeView {
    self.showDocumentButton = [self createDocumentTypeButtonWithTitle:@"教室文件" image:nil selectedImage:nil needBorder:YES accessibilityLabel:BJLKeypath(self, showDocumentButton)];
    [self.showDocumentButton addTarget:self action:@selector(showDocument) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:self.showDocumentButton];
    [self.showDocumentButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.titleLabel);
        make.top.equalTo(self.topSingleLine).offset(7);
        make.width.equalTo(@(96));
        make.height.equalTo(@(24));
    }];
    
    if (self.room.cloudDiskVM.enableCloudStorage) {
        self.showMyCloudFileButton = [self createDocumentTypeButtonWithTitle:@"我的云盘" image:nil selectedImage:nil needBorder:YES accessibilityLabel:BJLKeypath(self, showMyCloudFileButton)];
        [self.showMyCloudFileButton addTarget:self action:@selector(showMyDocumentView) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.showMyCloudFileButton];
        [self.showMyCloudFileButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.showDocumentButton.bjl_right).offset(8);
            make.top.width.height.equalTo(self.showDocumentButton);
        }];
    }
    
    if (self.room.featureConfig.enableHomework) {
        self.showMyHomeworkButton = [self createDocumentTypeButtonWithTitle:@"作业区" image:nil selectedImage:nil needBorder:YES accessibilityLabel:BJLKeypath(self, showMyHomeworkButton)];
        [self.showMyHomeworkButton addTarget:self action:@selector(showMyHomeworkView) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.showMyHomeworkButton];
        [self.showMyHomeworkButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            if (self.showMyCloudFileButton || self.showDocumentButton) {
                make.left.equalTo(self.showMyCloudFileButton.bjl_right ?: self.showDocumentButton.bjl_right).offset(8);
                make.top.width.height.equalTo(self.showMyCloudFileButton ?: self.showDocumentButton);
            }
            else {
                make.left.equalTo(self.titleLabel);
                make.top.equalTo(self.topSingleLine).offset(7);
                make.width.equalTo(@(96));
                make.height.equalTo(@(24));
            }
        }];
        
        self.documentTipButton = ({
            UIButton *button = [UIButton new];
            [button setTitle:@"移动端版本未更新的学生无法使用作业功能" forState:UIControlStateNormal];
            [button setTitleColor:BJLIcTheme.viewSubTextColor forState:UIControlStateNormal];
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_document_tip"] forState:UIControlStateNormal];
            [button.titleLabel setFont:[UIFont systemFontOfSize:12]];
            [button.titleLabel setLineBreakMode:NSLineBreakByTruncatingTail];
            button.userInteractionEnabled = NO;
            button;
        });
        [self addSubview:self.documentTipButton];
        [self.documentTipButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.equalTo(self.showMyHomeworkButton);
            make.right.equalTo(self).offset(-10.0);
            make.left.greaterThanOrEqualTo(self.showMyCloudFileButton.bjl_right ?: self.showDocumentButton.bjl_right).offset(10);
        }];
    }
    
    self.documentTypeLine = [self createShadowSingleLine];
    [self addSubview:self.documentTypeLine];
    [self.documentTypeLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self).offset(1.0);
        make.right.equalTo(self).offset(-1.0);
        make.top.equalTo(self.showDocumentButton.bjl_bottom).offset(7.0);
        make.height.equalTo(@(1.0));
    }];
}

- (void)makeDocumentSearchView {
    self.searchContainerView = [BJLHitTestView new];
    [self addSubview:self.searchContainerView];
    [self.searchContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self);
        make.top.equalTo(self.documentTypeLine.bjl_bottom ?: self.topSingleLine.bjl_bottom);
        make.height.equalTo(@47.0);
    }];
    
    // 右侧搜索输入框
    self.searchTextFieldContainerView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = @"searchContainerView";
        view.layer.cornerRadius = 12.0;
        view.layer.masksToBounds = YES;
        view.layer.borderWidth = 1.0;
        view.layer.borderColor = BJLIcTheme.buttonBorderColor.CGColor;
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self.searchContainerView addSubview:self.searchTextFieldContainerView];
    [self.searchTextFieldContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.searchContainerView.bjl_right).offset(-10.0);
        make.centerY.equalTo(self.searchContainerView);
        make.height.equalTo(@24.0);
        make.width.equalTo(@220.0);
    }];
    
    UIButton *searchButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = @"searchButton";
        button.backgroundColor = [UIColor clearColor];
        button.alpha = 0.5;
        [button setImage:[UIImage bjlic_imageNamed:@"window_search"] forState:UIControlStateNormal];
        button;
    });
    [self.searchTextFieldContainerView addSubview:searchButton];
    [searchButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.bottom.top.equalTo(self.searchTextFieldContainerView);
        make.width.equalTo(searchButton.bjl_height);
    }];
    
    self.searchTextField = ({
        self.clearSearchButton = ({
            UIButton *button = [UIButton new];
            button.frame = CGRectMake(0, 0, 32.0, 32.0);
            [button setImage:[UIImage bjlic_imageNamed:@"window_cleartext"] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(clearSearchText) forControlEvents:UIControlEventTouchUpInside];
            button.hidden = YES;
            button;
        });
        UITextField *textField = [UITextField new];
        textField.accessibilityLabel = BJLKeypath(self, searchTextField);
        textField.backgroundColor = [UIColor clearColor];
        NSAttributedString *messageAttributedText = [[NSAttributedString alloc] initWithString:@"请输入文件名搜索"
                                                                                    attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12.0],
                                                                                                 NSForegroundColorAttributeName : BJLIcTheme.viewSubTextColor}];
        textField.attributedPlaceholder = messageAttributedText;
        textField.textColor = BJLIcTheme.viewTextColor;
        textField.returnKeyType = UIReturnKeyGo;
        textField.rightView = self.clearSearchButton;
        textField.rightViewMode = UITextFieldViewModeAlways;
        textField.keyboardType = UIKeyboardTypeURL;
        textField.font = [UIFont systemFontOfSize:14.0];
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.enablesReturnKeyAutomatically = YES;
        textField;
    });
    [self.searchTextFieldContainerView addSubview:self.searchTextField];
    [self.searchTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(searchButton.bjl_right);
        make.top.equalTo(self.searchTextFieldContainerView);
        make.bottom.equalTo(self.searchTextFieldContainerView).offset(-1);
        make.right.equalTo(self.searchTextFieldContainerView);
    }];
    
    self.uploadFileButton = (BJLButton *)[self createDocumentTypeButtonWithTitle:@"上传文件" image:[UIImage bjlic_imageNamed:@"bjl_homework_upload"] selectedImage:[UIImage bjlic_imageNamed:@"bjl_homework_upload"] needBorder:NO accessibilityLabel:@"uploadButton"];
    [self.uploadFileButton setTitleColor:BJLIcTheme.brandColor forState:UIControlStateNormal];
    [self.uploadFileButton setTitleColor:BJLIcTheme.brandColor forState:UIControlStateNormal | UIControlStateHighlighted];
    self.uploadFileButton.layer.cornerRadius = 12.0;
    self.uploadFileButton.layer.borderColor = BJLIcTheme.brandColor.CGColor;
    self.uploadFileButton.layer.borderWidth = 1.0;
    [self.uploadFileButton addTarget:self action:@selector(uploadFile:) forControlEvents:UIControlEventTouchUpInside];
    [self.searchContainerView addSubview:self.uploadFileButton];
    [self.uploadFileButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        if (self.showDocumentButton) {
            make.left.size.equalTo(self.showDocumentButton);
        }
        else {
            make.left.equalTo(self.titleLabel);
            make.width.equalTo(@(96));
            make.height.equalTo(@(24));
        }
        make.centerY.equalTo(self.searchContainerView);
    }];
    
    if (self.room.loginUser.isTeacherOrAssistant) {
        self.allowStudentUploadButton = (BJLButton *)[self createDocumentTypeButtonWithTitle:@"允许学生上传" image:[UIImage bjlic_imageNamed:@"bjl_homework_forbidUpload"] selectedImage:[UIImage bjlic_imageNamed:@"bjl_homework_allowUpload"] needBorder:NO accessibilityLabel:@"allowButton"];
        self.allowStudentUploadButton.midSpace = 5.0;
        [self.allowStudentUploadButton setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateNormal];
        [self.allowStudentUploadButton setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateNormal | UIControlStateHighlighted];
        [self.allowStudentUploadButton setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateSelected];
        [self.allowStudentUploadButton setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateSelected | UIControlStateHighlighted];
        [self.allowStudentUploadButton addTarget:self action:@selector(allowStudentUpload:) forControlEvents:UIControlEventTouchUpInside];
        [self.searchContainerView addSubview:self.allowStudentUploadButton];
        [self.allowStudentUploadButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.uploadFileButton.bjl_right).offset(20);
            make.centerY.equalTo(self.searchContainerView);
            make.horizontal.hugging.compressionResistance.required();
        }];
    }
    
    UIButton *refreshButton = [BJLImageButton new];
    [refreshButton setImage:[UIImage bjlic_imageNamed:@"bjl_homework_refresh"] forState:UIControlStateNormal];
    [refreshButton setImage:[UIImage bjlic_imageNamed:@"bjl_homework_refresh_highlight"] forState:UIControlStateHighlighted];
    [refreshButton setImage:[UIImage bjlic_imageNamed:@"bjl_homework_refresh_highlight"] forState:UIControlStateNormal | UIControlStateHighlighted];
    [refreshButton addTarget:self action:@selector(refreshHomeworkList:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.searchContainerView addSubview:refreshButton];
    [refreshButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.searchTextFieldContainerView.bjl_left).offset(-15);
        make.centerY.equalTo(self.searchContainerView);
        make.width.height.equalTo(@(24));
    }];
    
    self.searchSingleLine = [self createShadowSingleLine];
    [self.searchContainerView addSubview:self.searchSingleLine];
    [self.searchSingleLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self).offset(1.0);
        make.right.equalTo(self).offset(-1.0);
        make.bottom.equalTo(self.searchContainerView.bjl_bottom);
        make.height.equalTo(@(1.0));
    }];
}

// 存在文档时显示的视图
- (void)makeDocumentsTableView {
    self.tableView = ({
        UITableView *tableView = [UITableView new];
        tableView.estimatedRowHeight = 50;
        tableView.rowHeight = 50;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.tableFooterView = [UIView new];
        tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        tableView.separatorColor = BJLIcTheme.separateLineColor;
        tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0 );
        tableView.hidden = YES;
        tableView;
    });
    [self addSubview:self.tableView];
    [self.tableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.searchContainerView.bjl_bottom);
        make.right.bottom.equalTo(self);
        make.left.equalTo(self).offset(0);
    }];
}

// 不存在文档时显示的视图
- (void)makeEmptyView {
    // empty view
    self.emptyView = [BJLHitTestView new];
    [self addSubview:self.emptyView];
    [self.emptyView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.top.equalTo(self.documentTypeLine.bjl_bottom ?: self.topSingleLine.bjl_bottom);
    }];
    
    // containerView
    UIView *containerView = [UIView new];
    [self.emptyView addSubview:containerView];
    [containerView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.emptyView);
    }];
    // empty label
    self.emptyMessageLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, emptyMessageLabel);
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"课程没有关联文件";
        label.textColor = BJLIcTheme.viewSubTextColor;
        label.font = [UIFont systemFontOfSize:16.0];
        label;
    });
    [containerView addSubview:self.emptyMessageLabel];
    [self.emptyMessageLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(containerView);
        make.height.equalTo(@16.0);
        make.centerY.equalTo(containerView).offset(4.0);
    }];
    // empty image
    UIImageView *emptyImageView = [UIImageView new];
    emptyImageView.image = [UIImage bjlic_imageNamed:@"bjl_document_empty"];
    [containerView addSubview:emptyImageView];
    [emptyImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(containerView);
        make.bottom.equalTo(self.emptyMessageLabel.bjl_top).offset(-15);
        make.height.greaterThanOrEqualTo(@50.0);
        make.height.equalTo(@94.0).priorityHigh();
        make.width.equalTo(emptyImageView.bjl_height).multipliedBy(emptyImageView.image.size.width / emptyImageView.image.size.height);
    }];
}

- (void)makeObserving {
    BOOL allow = self.room.homeworkVM.allowStudentUploadHomework;
    self.allowStudentUploadButton.selected = allow;
    if (self.room.loginUser.isStudent) {// 学生需要更新隐藏/展示上传按钮
        self.uploadFileButton.hidden = !allow;
    }
    
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.homeworkVM, didReceiveAllowStudentUploadHomework:)
             observer:(BJLMethodObserver)^BOOL(BOOL allow) {
        bjl_strongify(self);
        // 更新老师助教端的按钮状态
        self.allowStudentUploadButton.selected = allow;
        
        if (self.room.loginUser.isStudent) {// 学生需要更新隐藏/展示上传按钮
            self.uploadFileButton.hidden = !allow;
        }
        return YES;
    }];
}

#pragma mark - public

- (void)updateDocumentFileViewHidden:(BOOL)hidden {
    // 如果不存在文档
    if (hidden) {
        // 显示 empty view
        self.tableView.hidden = YES;
        self.emptyMessageLabel.text = [self emptyViewMessage];
        self.emptyView.hidden = NO;
        [self.emptyView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.bottom.right.equalTo(self);
            make.left.equalTo(self);
            make.top.equalTo(self.searchContainerView.bjl_bottom);
        }];
    }
    // 如果存在文档
    else {
        // 隐藏 empty 视图
        self.emptyView.hidden = YES;
        self.tableView.hidden = NO;
    }
}

#pragma mark - actions

- (void)clearSearchText {
    if (!self.searchTextField.text.length) {
        return;
    }
    
    self.searchTextField.text = nil;
    self.shouldShowSearchResult = NO;
    self.clearSearchButton.hidden = YES;
    
    // 调整布局之后抛出回调, 由外界控制数据源
    if (self.willshowFilelistCallback) {
        self.willshowFilelistCallback();
    }
}

- (NSString *)emptyViewMessage {
    switch (self.documentFileLayoutType) {
        case BJLIcDocumentFileLayoutTypeDocument:
        {
            if (self.shouldShowSearchResult) {
                return @"没有找到课件~";
            }
            else {
                return @"课程没有文件";
            }
        }
        case BJLIcDocumentFileLayoutTypeCloud:
                return @"暂无文件";
        case BJLIcDocumentFileLayoutTypeHomework:
            {
                if (self.shouldShowSearchResult) {
                    return @"没有找到作业~";
                }
                else {
                    return @"暂无作业";
                }
            }
        default:
            return @"暂无文件";
            break;
    }
}

- (void)showDocument {
    [self.searchTextField setPlaceholder:@"请输入文件名搜索"];
    [self switchDocumentType:BJLIcDocumentFileLayoutTypeDocument];
}

- (void)showMyDocumentView {
    [self.searchTextField setPlaceholder:@"请输入文件名搜索"];
    [self switchDocumentType:BJLIcDocumentFileLayoutTypeCloud];
}

- (void)showMyHomeworkView {
    [self.searchTextField setPlaceholder:@"请输入作业名/昵称"];
    [self switchDocumentType:BJLIcDocumentFileLayoutTypeHomework];
    if (self.room.loginUser.isTeacherOrAssistant) {
        if (self.switchToHomeworkCallback) {
            self.switchToHomeworkCallback();
        };
    }
}

- (void)allowStudentUpload:(UIButton *)button {
    button.selected = !button.selected;
    if (self.allowStudentUploadFileCallback) {
        self.allowStudentUploadFileCallback(button.selected);
    }
}

- (void)refreshHomeworkList:(UIButton *)button {
    bjl_returnIfRobot(1);
    if (self.refreshHomeworkCallback) {
        self.refreshHomeworkCallback();
    }
}

- (void)uploadFile:(UIButton *)button {
    bjl_returnIfRobot(1);
    if (self.uploadFileCallback) {
        self.uploadFileCallback();
    }
}

- (void)switchDocumentType:(BJLIcDocumentFileLayoutType)documentFileLayoutType {
    if (self.documentFileLayoutType == documentFileLayoutType) {
        return;
    }
    
    self.shouldShowSearchResult = NO;
    self.searchTextField.text = nil;
    
    self.documentFileLayoutType = documentFileLayoutType;
    BOOL isRelatedDocument = (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeDocument);
    BOOL isMyCloud = (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeCloud);
    BOOL isHomework = (self.documentFileLayoutType == BJLIcDocumentFileLayoutTypeHomework);
    
    // 调整UI布局
    self.showDocumentButton.selected = isRelatedDocument;
    self.showDocumentButton.layer.borderWidth = isRelatedDocument ? 0.0 : 1.0;
    [self.showDocumentButton setBackgroundColor:(!isRelatedDocument ? [UIColor clearColor] : BJLIcTheme.brandColor)];
    self.showDocumentButton.layer.borderColor = (isRelatedDocument ? [UIColor clearColor] : BJLIcTheme.buttonBorderColor).CGColor;
    
    self.showMyCloudFileButton.selected = isMyCloud;
    self.showMyCloudFileButton.layer.borderWidth = !isMyCloud ? 1.0 : 0.0;
    [self.showMyCloudFileButton setBackgroundColor:(!isMyCloud ? [UIColor clearColor] : BJLIcTheme.brandColor)];
    self.showMyCloudFileButton.layer.borderColor = (isMyCloud ? [UIColor clearColor] : BJLIcTheme.buttonBorderColor).CGColor;
    
    self.showMyHomeworkButton.selected = isHomework;
    self.showMyHomeworkButton.layer.borderWidth = !isHomework ? 1.0 : 0.0;
    [self.showMyHomeworkButton setBackgroundColor:(!isHomework ? [UIColor clearColor] : BJLIcTheme.brandColor)];
    self.showMyHomeworkButton.layer.borderColor = (isHomework ? [UIColor clearColor] : BJLIcTheme.buttonBorderColor).CGColor;
    
    self.documentTipButton.hidden = !isHomework;
    self.allowStudentUploadButton.hidden = !isHomework;
    
    BOOL shouldHiddenSearchTextField = isHomework && self.room.loginUser.isStudent;
    self.searchTextFieldContainerView.hidden = shouldHiddenSearchTextField;
    [self.searchTextFieldContainerView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.equalTo(shouldHiddenSearchTextField ? @(0.0) : @(220.0));
    }];
    
    [self.tableView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(self);
        make.top.equalTo(self.searchContainerView.bjl_bottom);
    }];
    
    self.emptyMessageLabel.text = [self emptyViewMessage];
    [self.emptyView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.left.bottom.right.equalTo(self);
        make.top.equalTo(self.searchContainerView.bjl_bottom);
    }];
    
    // 调整布局之后抛出回调, 由外界控制数据源
    if (self.willshowFilelistCallback) {
        self.willshowFilelistCallback();
    }
    
    [self setNeedsLayout];
}

#pragma mark - wheel

- (UIView *)createShadowSingleLine {
    UIView *view = [UIView bjlic_createSeparateLine];
    // shadow
    view.layer.masksToBounds = NO;
    view.layer.shadowOpacity = 0.2;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOffset = CGSizeMake(0.0, 5.0);
    view.layer.shadowRadius = 10.0;
    return view;
}

- (UIButton *)createDocumentTypeButtonWithTitle:(NSString *)title
                                          image:(nullable UIImage *)image
                                  selectedImage:(nullable UIImage *)selectedImage
                                     needBorder:(BOOL)needBorder
                             accessibilityLabel:(NSString *)accessibilityLabel {
    UIButton *button = [BJLButton new];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal | UIControlStateHighlighted];
    [button setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateNormal];
    [button setTitleColor:BJLIcTheme.buttonTextColor forState:UIControlStateSelected];
    [button setBackgroundColor:[UIColor clearColor]];
    
    if (image) {
        [button setImage:image forState:UIControlStateNormal];
        [button setImage:image forState:UIControlStateNormal | UIControlStateHighlighted];
    }
    if (selectedImage) {
        [button setImage:selectedImage forState:UIControlStateSelected];
        [button setImage:selectedImage forState:UIControlStateSelected | UIControlStateHighlighted];
    }
    [button.titleLabel setFont:[UIFont systemFontOfSize:12]];
    button.accessibilityLabel = accessibilityLabel;
    if (needBorder) {
        button.layer.masksToBounds = YES;
        button.layer.borderWidth = 1.0;
        button.layer.borderColor = BJLIcTheme.buttonBorderColor.CGColor;
        button.layer.cornerRadius = 12.0;
    }
    return button;
}

@end

NS_ASSUME_NONNULL_END
