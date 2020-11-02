//
//  BJLDocumentFile.m
//  BJLiveUI
//
//  Created by xijia dai on 2020/8/17.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLDocumentFile.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLDocumentFile

- (instancetype)init {
    if (self = [super init]) {
        self.state = BJLDocumentFileStateDefault;
        self.editMode = BJLDocumentFileEditModeDefault;
        self.type = BJLDocumentFileTypeDefault;
        self.progress = 0.0;
    }
    return self;
}

- (instancetype)initWithLocalDocument:(UIDocument *)localDocument {
    if (self = [super init]) {
        self.localDocument = localDocument;
        self.localID = [self getUniqueId];
        [self updateFileNameAndSuffixWithFileURL:localDocument.fileURL];
        [self updateFileTypeWithSuffix:self.suffix];
    }
    return self;
}

- (BOOL)shouldSupportUploadAndPlay {
    NSArray<NSString *> *supportedSuffixArray = @[@".ppt",
                                                  @".pptx",
                                                  @".doc",
                                                  @".pdf",
                                                  @".docx",
                                                  @".jpg",
                                                  @".jpeg",
                                                  @".png",
                                                  @".gif",
                                                  @".bjon",
                                                  @".zip"];
    return [self compareSuffix:self.suffix withSuffixArray:supportedSuffixArray];
}

- (instancetype)initWithRemoteDocument:(BJLDocument *)remoteDocument {
    if (self = [super init]) {
        self.remoteDocument = remoteDocument;
        self.isRelatedDocument = remoteDocument.isRelatedDocument;
        self.name = remoteDocument.fileName;
        self.suffix = remoteDocument.fileExtension;
        self.url = [NSURL URLWithString:remoteDocument.pageInfo.pageURLString];
        [self updateFileTypeWithSuffix:self.suffix];
        if (remoteDocument.isAnimate && self.type == BJLDocumentFileNormalPPT) {
            self.type = BJLDocumentFileAnimatedPPT;
            self.suggestImageName = @"bjl_document_animatedppt";
        }
    }
    return self;
}

- (instancetype)initWithRemoteHomework:(BJLHomework *)remoteHomework {
    if (self = [super init]) {
        self.remoteHomework = remoteHomework;
        self.isRelatedDocument = remoteHomework.isRelatedFile;
        self.name = remoteHomework.fileName;
        self.suffix = remoteHomework.fileExtension;
        [self updateFileTypeWithSuffix:self.suffix];
        if (remoteHomework.isAnimate && self.type == BJLDocumentFileNormalPPT) {
            self.type = BJLDocumentFileAnimatedPPT;
            self.suggestImageName = @"bjl_document_animatedppt";
        }
    }
    return self;
}

- (instancetype)initWithRemoteCloudFile:(BJLCloudFile *)remoteCloudFile {
    if (self = [super init]) {
        self.remoteCloudFile = remoteCloudFile;
        self.name = remoteCloudFile.fileName;
        self.suffix = remoteCloudFile.fileExtension;
        [self updateFileTypeWithSuffix:self.suffix];
        if (remoteCloudFile.format > 1 && self.type == BJLDocumentFileNormalPPT) {
            self.type = BJLDocumentFileAnimatedPPT;
            self.suggestImageName = @"bjl_document_animatedppt";
        }
    }
    return self;
}

#pragma mark -

- (void)setErrorCode:(NSInteger)errorCode {
    _errorCode = errorCode;
    self.errorMessage = [self errorMessageWithCode:errorCode];
}

#pragma mark -

- (void)updateFileNameAndSuffixWithFileURL:(NSURL *)url {
    NSString *urlString = url.absoluteString;
    NSString *name = [urlString.lastPathComponent stringByRemovingPercentEncoding];
    NSString *suffix = name.pathExtension;
    self.url = url;
    self.localPathURL = url;
    self.name = name;
    self.suffix = [@"." stringByAppendingString:suffix];
    // 处理 HEIC 和 HEIF 格式的图片
    NSArray *imageSuffixArray = @[@".heic",
                                  @".heif"];
    if ([self compareSuffix:self.suffix withSuffixArray:imageSuffixArray]) {
        CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)self.localDocument.fileURL, nil);
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, nil);
        NSString *cachesDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        NSString *fileName = [name.stringByDeletingPathExtension stringByAppendingString:@".jpg"];
        NSString *filePath = [cachesDir stringByAppendingPathComponent:fileName];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        CGImageDestinationRef fileURLRef = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeJPEG, 1, nil);
        if (!fileURLRef) {
            CGImageRelease(imageRef);
            CFRelease(source);
            NSLog(@"unable to create CGImageDestination");
            return;
        }
        CGImageDestinationAddImage(fileURLRef, imageRef, nil);
        CGImageDestinationFinalize(fileURLRef);
        // 重新赋值
        self.url = fileURL;
        self.name = fileName;
        self.suffix = @".jpg";
        
        CGImageRelease(imageRef);
        CFRelease(fileURLRef);
        CFRelease(source);
    }
}

- (NSString *)getUniqueId {
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    return [NSString stringWithFormat:@"documentFile%@",(__bridge_transfer NSString *)uuidStringRef];
}

- (void)updateFileTypeWithSuffix:(NSString *)suffix {
    // txt
    NSArray *txtSuffixArray = @[@".txt"];
    // image
    NSArray *imageSuffixArray = @[@".jpg",
                                  @".png",
                                  @".jpeg",
                                  @".webp",
                                  @".bmp",
                                  @".ico",
                                  @".gif",
                                  @".heic",
                                  @".heif"];
    // doc
    NSArray *docSuffixArray = @[@".doc",
                                @".docx"];
    
    // web doc
    NSArray *webDocSuffixArray = @[@".zip"];
    
    // pdf
    NSArray *pdfSuffixArray = @[@".pdf"];
    // xls
    NSArray *xlsSuffixArray = @[@".xls",
                                @".xlsx"];
    // ppt
    NSArray *pptSuffixArray = @[@".ppt",
                                @".pptx"];
    // audio mp3、wma、wav、mid、midd、kar、ogg、m4a、ra、ram、mod
    NSArray *audioSuffixArray = @[@".mp3",
                                  @".wma",
                                  @".wav",
                                  @".mid",
                                  @".midd",
                                  @".kar",
                                  @".m4a",
                                  @".ra",
                                  @".ram",
                                  @".flac",
                                  @".au",
                                  @".ogg",
                                  @".aac",
                                  @".pcm",
                                  @".arm",
                                  @".mod"];
    // video wmv、avi、dat、asf、rm、rmvb、ram、mpg、mpeg、3gp、mov、mp4、m4v、dvix、dv、mkv、flv、vob、qt、divx、cpk、fli、flc、mod
    NSArray *videoSuffixArray = @[@".wmv",
                                  @".avi",
                                  @".dat",
                                  @".asf",
                                  @".rm",
                                  @".rmvb",
                                  @".ram",
                                  @".mpg",
                                  @".mpeg",
                                  @".3gp",
                                  @".mov",
                                  @".mp4",
                                  @".m4v",
                                  @".dvix",
                                  @".dv",
                                  @".mkv",
                                  @".flv",
                                  @".vob",
                                  @".qt",
                                  @".divx",
                                  @".cpk",
                                  @".fli",
                                  @".flc"];
    if ([self compareSuffix:suffix withSuffixArray:txtSuffixArray]) {
        self.type = BJLDocumentFileTXT;
        self.suggestImageName = @"bjl_document_txt";
    }
    else if ([self compareSuffix:suffix withSuffixArray:imageSuffixArray]) {
        self.type = BJLDocumentFileImage;
        self.suggestImageName = @"bjl_document_img";
    }
    else if ([self compareSuffix:suffix withSuffixArray:docSuffixArray]) {
        self.type = BJLDocumentFileDOC;
        self.suggestImageName = @"bjl_document_doc";
    }
    else if ([self compareSuffix:suffix withSuffixArray:pdfSuffixArray]) {
        self.type = BJLDocumentFilePDF;
        self.suggestImageName = @"bjl_document_pdf";
    }
    else if ([self compareSuffix:suffix withSuffixArray:xlsSuffixArray]) {
        self.type = BJLDocumentFileXLS;
        self.suggestImageName = @"bjl_document_xls";
    }
    else if ([self compareSuffix:suffix withSuffixArray:pptSuffixArray]) {
        self.type = BJLDocumentFileNormalPPT;
        self.suggestImageName = @"bjl_document_ppt";
    }
    else if ([self compareSuffix:suffix withSuffixArray:webDocSuffixArray]) {
        self.type = BJLDocumentFileWebPPT;
        self.suggestImageName = @"bjl_document_webppt";
    }
    else if ([self compareSuffix:suffix withSuffixArray:audioSuffixArray]) {
        self.type = BJLDocumentFileAudio;
        self.suggestImageName = @"bjl_document_audio";
    }
    else if ([self compareSuffix:suffix withSuffixArray:videoSuffixArray]) {
        self.type = BJLDocumentFileVideo;
        self.suggestImageName = @"bjl_document_video";
    }
    // default
    else {
        self.type = BJLDocumentFileTypeDefault;
        self.suggestImageName = @"bjl_document_error";
    }
    self.mimeType = BJLMimeTypeForPathExtension(self.url.absoluteString.pathExtension);
}

- (BOOL)compareSuffix:(NSString *)suffix withSuffixArray:(NSArray <NSString *>*)suffixArray {
    BOOL flag = NO;
    for (NSString *targetSuffix in suffixArray) {
        if ([suffix compare:targetSuffix options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            flag = YES;
            break;
        }
    }
    return flag;
}

- (NSString *)errorMessageWithCode:(NSInteger)errorCode {
    NSString *errorMessage = @"未知错误";
    switch (errorCode) {
        case 10001:
            errorMessage = @"下载文件失败";
            break;
        case 10002:
            errorMessage = @"office转PDF失败";
            break;
        case 10003:
            errorMessage = @"pdf转png失败";
            break;
        case 10004:
            errorMessage = @"上传静态文件失败";
            break;
        case 10005:
            errorMessage = @"动画转html失败";
            break;
        case 10006:
            errorMessage = @"打包动画文件失败";
            break;
        case 10007:
            errorMessage = @"压缩动画文件失败";
            break;
        case 10008:
            errorMessage = @"上传动画压缩文件失";
            break;
        case 10009:
            errorMessage = @"上传动画html失败";
            break;
        case 10010:
            errorMessage = @"转码失败";
            break;
        case 10011:
            errorMessage = @"文件被加密，请上传非加密文件";
            break;
        case 10012:
            errorMessage = @"删除隐藏页或另存为pptx格式文件";
            break;
            
        default:
            errorMessage = @"未知错误";
            break;
    }
    return errorMessage;
}

@end

NS_ASSUME_NONNULL_END
