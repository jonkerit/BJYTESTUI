//
//  BJLIcDocumentFileCell.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/9/17.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcDocumentFileCell.h"
#import "BJLAnnularProgressView.h"
#import "BJLIcAppearance.h"

NSString
* const BJLIcDocumentCellReuseIdentifier = @"kIcDocumentCellReuseIdentifier",
* const BJLIcCloudCellReuseIdentifier = @"kIcCloudCellReuseIdentifier",
* const BJLIcHomeworkCellReuseIdentifier = @"kIcHomeworkCellReuseIdentifier";

@interface BJLIcDocumentFileCell ()

@property (nonatomic) BJLUser *loginUser;
@property (nonatomic) BJLDocumentFile *file;

@property (nonatomic) UIImageView *docIcon, *stickyIcon, *relatedDocIcon;
@property (nonatomic) UILabel *documentNameLabel, *documentSizeLabel, *documentFromUserLabel, *uploadTimeLabel;
@property (nonatomic) UILabel *stateLabel;
@property (nonatomic) UIView *optionContainerView;
@property (nonatomic) UIButton *deleteButton, *playButton, *cancelUploadButton, *failedDetailButton, *reuploadButton, *turnToNormalButton, *downloadButton;
@property (nonatomic) BJLAnnularProgressView *downloadProgressView;

@property (nonatomic) UIImageView *cloudSyncImageView;
@property (nonatomic) BOOL animating, needStopAnimation;

@end

@implementation BJLIcDocumentFileCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setUpSubviews];
        self.needStopAnimation = YES;
        [self prepareForReuse];
    }
    return self;
}

- (void)setUpSubviews {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    if ([self.reuseIdentifier isEqualToString:BJLIcDocumentCellReuseIdentifier]) {
        [self makeDocumentViewsAndConstraints];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcCloudCellReuseIdentifier]) {
        [self makeCloudViewsAndConstraints];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcHomeworkCellReuseIdentifier]) {
        [self makeHomeworkViewsAndConstraints];
    }
    
}

- (void)makeCommonViewsAndConstraints {
    self.docIcon = [UIImageView new];
    self.documentNameLabel = [self makeLabelWithAccessibilityLabel:BJLKeypath(self, documentNameLabel)];
    self.stateLabel = [self makeLabelWithAccessibilityLabel:BJLKeypath(self, stateLabel)];
    self.stateLabel.hidden = YES;
    self.stateLabel.textAlignment = NSTextAlignmentCenter;
    
    self.optionContainerView = [BJLHitTestView new];
    self.optionContainerView.accessibilityLabel = BJLKeypath(self, optionContainerView);
    self.deleteButton = [self makeImageButtonWithTitlt:nil image:[UIImage bjlic_imageNamed:@"bjl_document_delete"] highLightImage:[UIImage bjlic_imageNamed:@"bjl_document_delete_highlight"]];
    self.playButton = [self makeImageButtonWithTitlt:nil image:[UIImage bjlic_imageNamed:@"bjl_document_play"] highLightImage:[UIImage bjlic_imageNamed:@"bjl_document_play_highlight"]];
    self.failedDetailButton = [self makeImageButtonWithTitlt:@"失败详情" image:nil highLightImage:nil];
    self.cancelUploadButton = ({
        UIButton *button = [UIButton new];
        [button bjl_setTitle:@"取消上传" forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
        [button bjl_setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
        [button.titleLabel setFont:[UIFont systemFontOfSize:12]];
        button;
    });
    
    [self.deleteButton addTarget:self action:@selector(deleteDocument) forControlEvents:UIControlEventTouchUpInside];
    [self.playButton addTarget:self action:@selector(showDocument) forControlEvents:UIControlEventTouchUpInside];
    [self.failedDetailButton addTarget:self action:@selector(showError) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelUploadButton addTarget:self action:@selector(deleteDocument) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:self.docIcon];
    [self.contentView addSubview:self.documentNameLabel];
    [self.contentView addSubview:self.stateLabel];
    [self.contentView addSubview:self.optionContainerView];
    [self.contentView addSubview:self.deleteButton];
    [self.contentView addSubview:self.playButton];
    [self.contentView addSubview:self.failedDetailButton];
    [self.contentView addSubview:self.cancelUploadButton];
    
    [self.docIcon bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(8.0);
        make.width.height.equalTo(@(32.0));
    }];
    
    [self.stateLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.documentNameLabel.bjl_right);
        make.right.equalTo(self.failedDetailButton.bjl_left);
        make.centerY.equalTo(self.contentView);
    }];
    
    [self.optionContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.height.equalTo(self.contentView);
        make.right.equalTo(self.contentView).offset(-8);
        make.width.equalTo(@(0.0));
    }];
    
    [self.failedDetailButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.contentView);
        make.right.equalTo(self.optionContainerView.bjl_left);
    }];
}

- (void)makeDocumentViewsAndConstraints {
    [self makeCommonViewsAndConstraints];
    
    self.relatedDocIcon = [UIImageView new];
    [self.relatedDocIcon setImage:[UIImage bjlic_imageNamed:@"bjl_document_related"]];
    self.documentSizeLabel = [self makeLabelWithAccessibilityLabel:BJLKeypath(self, documentSizeLabel)];
    
    self.reuploadButton = [self makeImageButtonWithTitlt:nil image:[UIImage bjlic_imageNamed:@"bjl_document_reupload"] highLightImage:[UIImage bjlic_imageNamed:@"bjl_document_reupload_highlight"]];
    self.turnToNormalButton = [self makeImageButtonWithTitlt:nil image:[UIImage bjlic_imageNamed:@"bjl_document_toNormal"] highLightImage:[UIImage bjlic_imageNamed:@"bjl_document_toNormal_highlight"]];
    
    [self.reuploadButton addTarget:self action:@selector(reupload) forControlEvents:UIControlEventTouchUpInside];
    [self.turnToNormalButton addTarget:self action:@selector(turnToNormalDocument) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:self.documentSizeLabel];
    [self.contentView addSubview:self.relatedDocIcon];
    [self.contentView addSubview:self.reuploadButton];
    [self.contentView addSubview:self.turnToNormalButton];
    
    [self.documentNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.horizontal.hugging.compressionResistance.required();
        make.left.equalTo(self.docIcon.bjl_right).offset(8.0);
        make.centerY.equalTo(self.contentView);
        make.width.lessThanOrEqualTo(self.contentView.bjl_width).multipliedBy(2.0/5.0);
    }];
    
    [self.relatedDocIcon bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.documentNameLabel.bjl_right).offset(10);
        make.width.height.equalTo(@(12.0));
        make.centerY.equalTo(self.documentNameLabel);
    }];
    
    [self.documentSizeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.horizontal.hugging.compressionResistance.required();
        make.centerY.equalTo(self.contentView);
        make.width.equalTo(@(90));
        make.right.equalTo(self.contentView).offset(-120);
    }];
}

- (void)makeCloudViewsAndConstraints {
    [self makeCommonViewsAndConstraints];
    
    [self.playButton bjl_setImage:[UIImage bjlic_imageNamed:@"bjl_cloud_open"] forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
    self.cloudSyncImageView = ({
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage bjlic_imageNamed:@"bjl_cloud_open"]];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.accessibilityLabel = BJLKeypath(self, cloudSyncImageView);
        imageView.backgroundColor = BJLIcTheme.windowBackgroundColor;
        imageView.hidden = YES;
        imageView;
    });
    [self.playButton addSubview:self.cloudSyncImageView];
    [self.cloudSyncImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.playButton);
    }];

    self.documentSizeLabel = [self makeLabelWithAccessibilityLabel:BJLKeypath(self, documentSizeLabel)];
    self.uploadTimeLabel = [self makeLabelWithAccessibilityLabel:BJLKeypath(self, uploadTimeLabel)];
    
    self.reuploadButton = [self makeImageButtonWithTitlt:nil image:[UIImage bjlic_imageNamed:@"bjl_document_reupload"] highLightImage:[UIImage bjlic_imageNamed:@"bjl_document_reupload_highlight"]];
    self.turnToNormalButton = [self makeImageButtonWithTitlt:nil image:[UIImage bjlic_imageNamed:@"bjl_document_toNormal"] highLightImage:[UIImage bjlic_imageNamed:@"bjl_document_toNormal_highlight"]];
    
    [self.reuploadButton addTarget:self action:@selector(reupload) forControlEvents:UIControlEventTouchUpInside];
    [self.turnToNormalButton addTarget:self action:@selector(turnToNormalDocument) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:self.documentSizeLabel];
    [self.contentView addSubview:self.uploadTimeLabel];
    [self.contentView addSubview:self.reuploadButton];
    [self.contentView addSubview:self.turnToNormalButton];
    
    [self.documentNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.docIcon.bjl_right).offset(8.0);
        make.centerY.equalTo(self.contentView);
        make.right.lessThanOrEqualTo(self.documentSizeLabel).offset(-10);
        make.width.equalTo(self.contentView.bjl_width).multipliedBy(2.0/5.0).priorityHigh();
    }];
    
    [self.documentSizeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.contentView);
        make.width.equalTo(@(60));
        make.right.equalTo(self.uploadTimeLabel.bjl_left).offset(-20);
    }];
    
    [self.uploadTimeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.horizontal.hugging.compressionResistance.required();
        make.centerY.equalTo(self.contentView);
        make.width.equalTo(@(110));
        make.right.equalTo(self.contentView).offset(-120);
    }];
}

- (void)makeHomeworkViewsAndConstraints {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    [self makeCommonViewsAndConstraints];
    self.stickyIcon = ({
        UIImageView *imageView = [UIImageView new];
        [imageView setImage:[UIImage bjlic_imageNamed:@"bjl_homework_stickyIcon"]];
        imageView.contentMode = UIViewContentModeTopLeft;
        imageView;
    });
    self.documentFromUserLabel = [self makeLabelWithAccessibilityLabel:BJLKeypath(self, documentFromUserLabel)];
    self.documentSizeLabel = [self makeLabelWithAccessibilityLabel:BJLKeypath(self, documentSizeLabel)];
    self.uploadTimeLabel = [self makeLabelWithAccessibilityLabel:BJLKeypath(self, uploadTimeLabel)];
    
    self.downloadButton = [self makeImageButtonWithTitlt:nil image:[UIImage bjlic_imageNamed:@"bjl_homework_download"] highLightImage:[UIImage bjlic_imageNamed:@"bjl_homework_download_highlight"]];
    self.downloadProgressView = ({
        BJLAnnularProgressView *progressView = [BJLAnnularProgressView new];
        progressView.size = 14;
        progressView.annularWidth = 1.0;
        progressView.color = [BJLIcTheme brandColor];
        progressView.userInteractionEnabled = NO;
        progressView.hidden = YES;
        progressView;
    });
    [self.downloadButton addTarget:self action:@selector(downloadDocument) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:self.stickyIcon];
    [self.contentView addSubview:self.documentFromUserLabel];
    [self.contentView addSubview:self.documentSizeLabel];
    [self.contentView addSubview:self.uploadTimeLabel];
    [self.contentView addSubview:self.downloadButton];
    [self.downloadButton addSubview:self.downloadProgressView];
    [self.downloadProgressView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.downloadButton);
    }];
    
    [self.documentNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.docIcon.bjl_right).offset(8.0);
        make.centerY.equalTo(self.contentView);
        if (iPhone) {
            make.width.equalTo(@(140));
        }
        else {
            make.width.equalTo(self.contentView.bjl_width).multipliedBy(2.0/5.0);
        }
    }];
    
    [self.documentSizeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.contentView);
        make.width.equalTo(@(60));
        make.left.equalTo(self.documentNameLabel.bjl_right).offset(10.0);
    }];
    [self.documentFromUserLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.contentView);
        make.left.equalTo(self.documentSizeLabel.bjl_right).offset(iPhone ? 10.0 : 30.0);
        make.right.lessThanOrEqualTo(self.uploadTimeLabel.bjl_left).offset(-20);
    }];
    [self.uploadTimeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.horizontal.hugging.compressionResistance.required();
        make.centerY.equalTo(self.contentView);
        make.width.equalTo(@(110));
        make.right.equalTo(self.contentView).offset(-120);
    }];
}

#pragma mark - action

- (void)showDocument {
    bjl_returnIfRobot(1);
    if (self.showDocumentCallback) {
        self.showDocumentCallback();
    }
}

- (void)deleteDocument {
    bjl_returnIfRobot(1);
    if (self.deleteDocumentCallback) {
        self.deleteDocumentCallback();
    }
}

- (void)showError {
    bjl_returnIfRobot(1);
    if (self.showErrorCallback) {
        self.showErrorCallback(self.failedDetailButton);
    }
}

- (void)downloadDocument {
    bjl_returnIfRobot(1);
    if (self.downloadDocumentCallback) {
        self.downloadDocumentCallback(self.downloadButton);
    }
}

- (void)reupload {
    bjl_returnIfRobot(1);
    if (self.reuploadCallback) {
        self.reuploadCallback();
    }
}

- (void)turnToNormalDocument {
    bjl_returnIfRobot(1);
    if (self.turnToNormalDocumentCallback) {
        self.turnToNormalDocumentCallback();
    }
}

#pragma mark - public

- (void)updatecloudSyncHidden:(BOOL)hidden {
    if (!self.cloudSyncImageView || self.cloudSyncImageView.hidden == hidden || !self.playButton.superview) {
        return;
    }
    
    self.cloudSyncImageView.hidden = hidden;
    if (hidden) {
        [self stopLoadingAnimation];
    }
    else {
        if (self.animating || !self.needStopAnimation) {
            return;
        }
        
        self.needStopAnimation = NO;
        bjl_weakify(self);
        [self startLoadingAnimationWithAngle:0 completion:^{
            bjl_strongify(self);
            if (!self.needStopAnimation) {
                self.animating = YES;
            }
        }];
    }
}

- (void)startLoadingAnimationWithAngle:(NSInteger)angle completion:(void (^ __nullable)(void))completion {
    if (self.hidden || !self || !self.window) {
        [self stopLoadingAnimation];
        return;
    }
    
    NSInteger nextAngle = angle + 20;
    if (nextAngle > 360) {
        nextAngle = 0;
    }
    CGAffineTransform endAngle = CGAffineTransformMakeRotation(angle * (M_PI / 180.0f));
    // 预期不会出现顺序调用，后调用的先回调 completion
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.cloudSyncImageView.transform = endAngle;
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
        if (self.animating && finished) {
            [self startLoadingAnimationWithAngle:nextAngle completion:nil];
        }
        else {
            [self stopLoadingAnimation];
        }
    }];
}

- (void)stopLoadingAnimation {
    self.animating = NO;
    self.needStopAnimation = YES;
    
    self.cloudSyncImageView.hidden = YES;
    [self.cloudSyncImageView.layer removeAllAnimations];
    self.cloudSyncImageView.transform = CGAffineTransformIdentity;
}

- (void)updateWithDocumentFile:(nullable BJLDocumentFile *)file
                  downloadItem:(nullable BJLHomeworkDownloadItem *)downloadItem
                     loginUser:(BJLUser *)loginUser
                   isCloudSync:(BOOL)isCloudSync {
    self.file = file;
    self.loginUser = loginUser;
    
    self.docIcon.image = [UIImage bjlic_imageNamed:self.file.suggestImageName];
    self.documentNameLabel.text = self.file.name;
    self.relatedDocIcon.hidden = !file.isRelatedDocument;
        
    if ([self.reuseIdentifier isEqualToString:BJLIcDocumentCellReuseIdentifier]) {
        self.documentSizeLabel.text = [self sizeToString:file.remoteDocument.byteSize];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcCloudCellReuseIdentifier]) {
        self.documentSizeLabel.text = [self sizeToString:file.remoteCloudFile.byteSize];
        self.uploadTimeLabel.text = [self getUploadTimeWith:self.file.remoteCloudFile.lastTimeInterval];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcHomeworkCellReuseIdentifier]) {
        BOOL isStickyFile = file.remoteHomework.fromUserRole != BJLUserRole_student && file.state == BJLDocumentFileNormal;
        self.stickyIcon.hidden = !isStickyFile;
        if (isStickyFile) {
            self.contentView.backgroundColor = [UIColor bjl_colorWithHex:0x9FA8B5 alpha:0.1];
        }
        else {
            self.contentView.backgroundColor = [UIColor clearColor];
        }
        
        self.documentSizeLabel.text = [self sizeToString:file.remoteHomework.byteSize];
        self.documentFromUserLabel.text = self.file.remoteHomework.fromUserName;
        self.uploadTimeLabel.text = [self getUploadTimeWith:self.file.remoteHomework.lastTimeInterval];
        
        self.downloadProgressView.hidden = YES;
        [self.downloadButton bjl_setImage:[UIImage bjlic_imageNamed:@"bjl_homework_download"] forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
        if (!downloadItem) {
            [self updateFileState];
            return;
        }
        
        if (downloadItem.state == BJLDownloadItemState_running) {
            self.downloadProgressView.hidden = NO;
            self.downloadProgressView.progress = downloadItem.progress.fractionCompleted;
        }
        else if (downloadItem.state == BJLDownloadItemState_completed && !downloadItem.error) {
            [self.downloadButton bjl_setImage:[UIImage bjlic_imageNamed:@"bjl_homework_openfile"] forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
        }
        else if (downloadItem.state == BJLDownloadItemState_paused && !downloadItem.error) {
            //            [self.downloadButton bjl_setImage:[UIImage bjlic_imageNamed:@"bjl_homework_pause"] forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
        }
        else if (downloadItem.error) {
            [self.downloadButton bjl_setImage:[UIImage bjlic_imageNamed:@"bjl_homework_downloadfailed"] forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
        }
    }
    
    [self updateFileState];
    [self updatecloudSyncHidden:!isCloudSync];
}

- (void)updateFileState {
    self.stateLabel.text = nil;
    self.stateLabel.hidden = YES;
    self.documentSizeLabel.hidden = YES;
    self.documentFromUserLabel.hidden = YES;
    self.uploadTimeLabel.hidden = YES;
    self.failedDetailButton.hidden = YES;
    self.deleteButton.enabled = YES;
    
    [self.playButton removeFromSuperview];
    [self.downloadButton removeFromSuperview];
    [self.deleteButton removeFromSuperview];
    [self.reuploadButton removeFromSuperview];
    [self.turnToNormalButton removeFromSuperview];
    [self.cancelUploadButton removeFromSuperview];
    
    if (!self.file) {
        return;
    }
    
    self.stateLabel.textColor = BJLIcTheme.viewTextColor;
    NSArray<UIButton *> *buttons = nil;
    
    switch (self.file.state) {
        case BJLDocumentFileNormal:
        {
            self.documentSizeLabel.hidden = NO;
            self.documentFromUserLabel.hidden = NO;
            self.uploadTimeLabel.hidden = NO;
            
            self.deleteButton.enabled = ([self.reuseIdentifier isEqualToString:BJLIcHomeworkCellReuseIdentifier] && self.loginUser.isTeacherOrAssistant && !self.file.remoteHomework.isRelatedFile)
            || ([self.reuseIdentifier isEqualToString:BJLIcCloudCellReuseIdentifier])
            || ([self.reuseIdentifier isEqualToString:BJLIcDocumentCellReuseIdentifier] && !self.file.isRelatedDocument);
            
            if ([self.reuseIdentifier isEqualToString:BJLIcDocumentCellReuseIdentifier] || [self.reuseIdentifier isEqualToString:BJLIcCloudCellReuseIdentifier]) {
                buttons = @[self.playButton, self.deleteButton];
            }
            else if ([self.reuseIdentifier isEqualToString:BJLIcHomeworkCellReuseIdentifier]) {
                if (self.loginUser.isTeacherOrAssistant && self.file.remoteHomework.canPreview) {
                    buttons = @[self.playButton, self.downloadButton, self.deleteButton];
                }
                else if (self.loginUser.isTeacherOrAssistant) {
                    buttons = @[self.downloadButton, self.deleteButton];
                }
                if (self.loginUser.isStudent) {
                    buttons = @[self.downloadButton];
                }
            }
        }
            
            break;
            
        case BJLDocumentFileTranscodeError:
        case BJLDocumentFileUploadError:
        {
            self.stateLabel.hidden = NO;
            self.stateLabel.text = (self.file.state == BJLDocumentFileTranscodeError) ? @"转码失败" : @"上传失败";
            self.stateLabel.textColor = [UIColor bjl_colorWithHex:0XFF2A4C];
            self.failedDetailButton.hidden = NO;
            
            if (self.file.errorCode == 10012 || self.file.errorCode == 10011
                || BJLDocumentFileUploadError == self.file.state
                || [self.reuseIdentifier isEqualToString:BJLIcHomeworkCellReuseIdentifier]) {
                buttons = @[self.deleteButton];
            }
            else {
                if (self.file.type == BJLDocumentFileAnimatedPPT) {
                    buttons = @[self.turnToNormalButton, self.reuploadButton, self.deleteButton];
                }
                else {
                    buttons = @[self.reuploadButton, self.deleteButton];
                }
            }
        }
            
            break;
        case BJLDocumentFileUploading: {
            self.stateLabel.hidden = NO;
            self.stateLabel.text = @"上传中...";
            buttons = @[self.cancelUploadButton];
        }
            
            break;
        case BJLDocumentFileTranscoding: {
            self.stateLabel.hidden = NO;
            self.stateLabel.text = @"转码中...";
            buttons = @[self.deleteButton];
        }
            
            break;
            
        default:
            break;
    }
    
    [self updateOptionsButtonConstraintsWith:buttons];
}

- (void)updateOptionsButtonConstraintsWith:(NSArray<UIButton *> *)buttons {
    if (![buttons count]) {
        return;
    }
    CGFloat buttonWidth = 24;
    if ([buttons containsObject:self.cancelUploadButton]) {
        buttonWidth = 50;
    }
    
    [self.optionContainerView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.equalTo(@([buttons count] * (buttonWidth + 10)));
    }];
    UIButton *lastButton = nil;
    for (UIButton *button in buttons) {
        [self.contentView addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.centerY.equalTo(self.contentView);
            // 上一个按钮为空, 则按钮大小可以为图片大小, 后续的按钮与第一个按钮大小保持一致
            if (lastButton) {
                make.width.height.equalTo(lastButton);
            }
            else {
                make.width.height.equalTo(@(24)).priorityHigh();
            }
            make.left.equalTo(lastButton.bjl_right ?: self.optionContainerView.bjl_left).offset(4);
            if (button == buttons.lastObject) {
                // 最后一个 button 右侧约束
                make.right.equalTo(self.optionContainerView);
            }
        }];
        lastButton = button;
    }
}

#pragma mark - wheel

- (NSString *)getUploadTimeWith:(NSTimeInterval)lastTimeInterval {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:lastTimeInterval];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"zh_Hans_CN"];
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:+28800];
    dateFormatter.dateFormat = @"yyyy/MM/dd HH:mm";
    NSString *tempstr = [dateFormatter stringFromDate:date];
    return tempstr;
}

// 转换大小格式
- (NSString *)sizeToString:(CGFloat)size {
    CGFloat kbSize = size / pow(1024.0, 1.0);
    CGFloat mbSize = size / pow(1024.0, 2.0);
    if (mbSize < 1.0) {
        return [NSString stringWithFormat:@"%.2fK", kbSize];
    }
    CGFloat gbSize = size / pow(1024.0, 3.0);
    if (gbSize < 1.0) {
        return [NSString stringWithFormat:@"%.2fM", mbSize];
    }
    CGFloat tbSize = size / pow(1024.0, 4.0);
    if (tbSize < 1.0) {
        return [NSString stringWithFormat:@"%.2fG", gbSize];
    }
    return [NSString stringWithFormat:@"%.2fT", tbSize];
}

- (UILabel *)makeLabelWithAccessibilityLabel:(NSString *)accessibilityLabel {
    UILabel *label = [UILabel new];
    label.numberOfLines = 1;
    label.textColor = BJLIcTheme.viewTextColor;
    label.textAlignment = NSTextAlignmentLeft;
    label.font = [UIFont systemFontOfSize:12];
    label.accessibilityLabel = accessibilityLabel;
    label.backgroundColor = [UIColor clearColor];
    return label;
}

- (UIButton *)makeImageButtonWithTitlt:(NSString *)title image:(UIImage *)image highLightImage:(UIImage *)highLightImage {
    UIButton *button = [UIButton new];
    if (title) {
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont systemFontOfSize:12]];
    }
    if (image) {
        [button setImage:image forState:UIControlStateNormal];
    }
    if (highLightImage) {
        [button setImage:highLightImage forState:UIControlStateHighlighted];
        [button setImage:highLightImage forState:UIControlStateNormal | UIControlStateHighlighted];
    }
    return button;
}

#pragma mark - class method

+ (NSArray <NSString *> *)allCellIdentifiers {
    return @[BJLIcDocumentCellReuseIdentifier,
             BJLIcCloudCellReuseIdentifier,
             BJLIcHomeworkCellReuseIdentifier];
}
+ (NSString *)cellIdentifierForCellType:(BJLIcDocumentFileCellType)type {
    switch (type) {
        case BJLIcDocumentFileCellTypeHomework:
            return BJLIcHomeworkCellReuseIdentifier;
            break;
            
        case BJLIcDocumentFileCellTypeCloud:
            return BJLIcCloudCellReuseIdentifier;
            break;
            
        default:
            return BJLIcDocumentCellReuseIdentifier;
            break;
    }
}

@end
