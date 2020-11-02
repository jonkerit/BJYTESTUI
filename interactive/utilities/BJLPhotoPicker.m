//
//  BJLPhotoPicker.m
//  CodeLabSwift
//
//  Created by Ney on 10/15/20.
//  Copyright © 2020 Ney. All rights reserved.
//

#import "BJLPhotoPicker.h"
#import <PhotosUI/PHPicker.h>
#import <CoreServices/UTCoreTypes.h>
#import <UniformTypeIdentifiers/UTCoreTypes.h>
#import <QBImagePickerController/QBImagePickerController.h>
#import "BJL_iCloudLoading.h"
#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLiveCore.h>

NSURL*   copyImageFromSystemTempPathToSandboxTempPath(NSURL *from, NSError **error);
UIImage* loadAndDownsampleImageFromURL(NSURL *url, NSError **error);


@interface BJLPHPickerResultLoadTaskConfiguration : NSObject @end
@implementation BJLPHPickerResultLoadTaskConfiguration @end

@class BJLPHPickerResultLoadTask;
@protocol BJLPHPickerResultLoadTaskDelegate <NSObject>
- (void)task:(BJLPHPickerResultLoadTask *)task didFinishWithLoadedData:(NSArray *)loadedData;
@end

API_AVAILABLE(ios(14))
@interface BJLPHPickerResultLoadTask : NSObject
@property (nonatomic, assign)  BOOL onLoading;
@property (nonatomic, assign)  BOOL isCanceled;
@property (nonatomic, strong)  BJLPHPickerResultLoadTaskConfiguration *configuration;
@property (nonatomic, strong)  NSArray<PHPickerResult *> *pickedData;
@property (nonatomic, strong)  NSMutableArray *loadedData;
@property (nonatomic, weak) id<BJLPHPickerResultLoadTaskDelegate> delegate;

@property (nonatomic, strong)  dispatch_group_t workGroup;

- (instancetype)initWithConfiguration:(BJLPHPickerResultLoadTaskConfiguration *)configuration pickedData:(NSArray<PHPickerResult *> *)results;
- (void)startTask;
- (void)cancelTask;
@end

@implementation BJLPHPickerResultLoadTask
- (instancetype)initWithConfiguration:(BJLPHPickerResultLoadTaskConfiguration *)configuration pickedData:(NSArray<PHPickerResult *> *)pickedData {
    if (configuration == nil || pickedData == nil || pickedData.count <= 0) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.configuration = configuration;
        self.pickedData = pickedData;
        
        self.workGroup = dispatch_group_create();
        self.loadedData = [NSMutableArray array];
    }
    return self;
}

- (void)startTask {
    self.onLoading = YES;
    for (NSInteger i=0; i < self.pickedData.count; i++) {
        [self.loadedData addObject:NSNull.null];
    }
    
    __weak __typeof(self)weakSelf = self;
    dispatch_group_t group = self.workGroup;
    for (NSInteger i=0; i < self.pickedData.count; i++) {
        PHPickerResult *r = self.pickedData[i];
        dispatch_group_enter(group);
        @autoreleasepool {
            [r.itemProvider loadFileRepresentationForTypeIdentifier:(NSString *)kUTTypeImage completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
                if (weakSelf.isCanceled) {
                    dispatch_group_leave(group);
                    return;
                }
                if (error) {
                    [weakSelf putObj:error toImageDataArrayThreadSafely:i];
                    dispatch_group_leave(group);
                    return;
                }

                NSError *imgErr = nil;
                ICLImageFile *imgObj = [weakSelf buildICLImageFileObjecWithPickerResult:r fileURL:url error:&imgErr];
                if (imgObj) {
                    [weakSelf putObj:imgObj toImageDataArrayThreadSafely:i];
                }
                else if (imgErr) {
                    [weakSelf putObj:imgErr toImageDataArrayThreadSafely:i];
                }
                
                dispatch_group_leave(group);
            }];
        }
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        self.onLoading = NO;
        if ([self.delegate respondsToSelector:@selector(task:didFinishWithLoadedData:)]) {
            [self.delegate task:self didFinishWithLoadedData:self.loadedData];
        }
    });
}

- (void)cancelTask {
    self.onLoading = NO;
    self.isCanceled = YES;
    self.delegate = nil;
}

- (void)putObj:(id)obj toImageDataArrayThreadSafely:(NSInteger)index {
    if (self.isCanceled) {
        return;
    }
    
    @synchronized (self) {
        id targetObj = obj;
        if (!targetObj) {
            targetObj = NSNull.null;
        }
        [self.loadedData replaceObjectAtIndex:index withObject:targetObj];
    }
}

- (ICLImageFile *)buildICLImageFileObjecWithPickerResult:(PHPickerResult *)pickerResult fileURL:(NSURL *)fileURL error:(NSError *__autoreleasing  _Nullable *)error {
    if (fileURL == nil) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.bjy.imageFileWithPickerResult" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"url is null"}];
        }
        return nil;
    }

    NSError *urlErr = nil;
    NSURL *newURL = copyImageFromSystemTempPathToSandboxTempPath(fileURL, &urlErr);
    if (urlErr && error) {
        *error = urlErr;
        return nil;
    }
    
    NSError *imgErr = nil;
    UIImage *img = loadAndDownsampleImageFromURL(fileURL, &imgErr);
    if (imgErr && error) {
        *error = imgErr;
        return nil;
    }
    
    return [ICLImageFile imageFileWithPickerResult:pickerResult thumbnail:img filePath:newURL.absoluteString error:nil];
}
@end



static BOOL DISABLE_PHPICKER = NO;

@interface BJLPhotoPicker() < PHPickerViewControllerDelegate, QBImagePickerControllerDelegate, QBImagePickerControllerDelegate_iCloudLoading, BJLPHPickerResultLoadTaskDelegate>
@property (nonatomic, strong)  BJLPhotoPickerConfiguration * configurationStorage;
@property (nonatomic, strong)  UIViewController * pickerViewController;
@property (nonatomic, strong)  BJLPhotoPickerResult * pickedData;
@property (nonatomic, strong)  BJLPHPickerResultLoadTask * loadTask API_AVAILABLE(ios(14));
@property (nonatomic, assign)  NSTimeInterval lastTapTime;
@end

@implementation BJLPhotoPicker
- (instancetype)init {
    return [self initWithConfiguration: nil];
}

+ (void)syncServerConfig_disable_phpicker:(BOOL)disable_phpicker {
    DISABLE_PHPICKER = disable_phpicker;
}

+ (BOOL)enableNewPhotoPicker {
    BOOL enable = !DISABLE_PHPICKER;

    if (@available(iOS 14.0, *)) {
    }
    else {
        return NO;
    }
    
    return enable;
}

- (instancetype)initWithConfiguration:(BJLPhotoPickerConfiguration *)configuration {
    self = [super init];
    if (self) {
        if (!configuration) {
            configuration = [self defaultConfiguration];
        }

        self.configurationStorage = configuration;
        self.pickerViewController = [self pickerViewControllerWithConfiguration:configuration];
    }
    return self;
}

- (void)requestAuthorizationIfNeededAndPresentPickerControllerFrom:(UIViewController *)fromController {
    if ([self.class enableNewPhotoPicker]) {
        [self presentPickerControllerFrom:fromController];
    }
    else {
        [BJLAuthorization checkPhotosAccessAndRequest:YES callback:^(BOOL granted, UIAlertController * _Nullable alert) {
            if (granted) {
                [self presentPickerControllerFrom:fromController];
            }
            else if (alert) {
                if (fromController.presentedViewController) {
                    [fromController.presentedViewController bjl_dismissAnimated:YES completion:nil];
                }
                [fromController presentViewController:alert animated:YES completion:nil];
            }
        }];
    }
}

- (void)presentPickerControllerFrom:(UIViewController *)fromController {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (fromController.presentedViewController) {
            [fromController.presentedViewController bjl_dismissAnimated:YES completion:nil];
        }
        if (@available(iOS 13.0, *)) {
            self.pickerViewController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        }
        [fromController bjl_presentFullScreenViewController:self.pickerViewController animated:YES completion:nil];
    });
}

- (void)dismissPickerController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.pickerViewController bjl_dismissAnimated:YES completion:nil];
    });
}

- (BJLPhotoPickerConfiguration *)configuration {
    return self.configurationStorage.copy;
}

- (UIViewController *)viewController {
    return self.pickerViewController;
}


#pragma mark - helper
- (UIViewController *)pickerViewControllerWithConfiguration:(BJLPhotoPickerConfiguration *)configuration {
    UIViewController *resultController = nil;
    if (@available(iOS 14, *)) {
        if ([self.class enableNewPhotoPicker]) {
            resultController = [self phPickerControllerWithConfiguration:configuration];
        }
        else {
            resultController = [self qbPickerControllerWithConfiguration:configuration];
        }
    }
    else {
        resultController = [self qbPickerControllerWithConfiguration:configuration];
    }

    return resultController;
}

- (BJLPhotoPickerConfiguration *)defaultConfiguration {
    BJLPhotoPickerConfiguration *configuration = [BJLPhotoPickerConfiguration new];
    return configuration;
}

- (void)callDidFinishPickingDelegateMethod:(BJLPhotoPickerResult *)result {
    if ([self.delegate respondsToSelector:@selector(photoPicker:didFinishPicking:)]) {
        [self.delegate photoPicker:self didFinishPicking:result];
    }
}


#pragma mark - DELEGATE
#pragma mark - PHPickerViewController delegate
- (PHPickerViewController *)phPickerControllerWithConfiguration:(BJLPhotoPickerConfiguration *)configuration API_AVAILABLE(ios(14)) {
    PHPickerConfiguration *config = [PHPickerConfiguration new];
    config.selectionLimit = configuration.selectionLimit;
    config.filter = PHPickerFilter.imagesFilter;
    PHPickerViewController * pickerVC = [[PHPickerViewController alloc] initWithConfiguration:config];
    pickerVC.delegate = self;
    
    return pickerVC;
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results  API_AVAILABLE(ios(14)) {
    NSTimeInterval now = [NSDate.date timeIntervalSince1970];
    NSTimeInterval lastTap = self.lastTapTime;
    self.lastTapTime = now;
    
    if (results.count <= 0) {
        if ([self.delegate respondsToSelector:@selector(photoPicker:didFinishPicking:)]) {
            [self.delegate photoPicker:self didFinishPicking: nil];
        }
        else if ([self.delegate respondsToSelector:@selector(photoPicker:didFinishLoadImageData:failureItems:originResult:)]) {
            [self.delegate photoPicker:self didFinishLoadImageData:nil failureItems:nil originResult:nil];
        }
        
        if (self.loadTask) {
            [self.loadTask cancelTask];
            self.loadTask = nil;
        }
        return;
    }

    if (now - lastTap >= 1) {
        [self highFrequencyOperationFilteredPicker:picker didFinishPicking:results];
    }
}

- (void)highFrequencyOperationFilteredPicker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14)) {
    BJLPhotoPickerResult *data = [BJLPhotoPickerResult new];
    data.phPickerFormatData = results;
    self.pickedData = data;
    [self callDidFinishPickingDelegateMethod:data];
    
    if (!self.configurationStorage.autoLoadImageData) {
        return;
    }
    
    [self loadImageData: results];
}



- (void)loadImageData:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14)) {
    if (self.loadTask) {
        [self.loadTask cancelTask];
        self.loadTask = nil;
    }
    
    BJLPHPickerResultLoadTaskConfiguration *config = [BJLPHPickerResultLoadTaskConfiguration new];
    self.loadTask = [[BJLPHPickerResultLoadTask alloc] initWithConfiguration:config pickedData:results];
    self.loadTask.delegate = self;
    [self.loadTask startTask];
}

- (void)task:(BJLPHPickerResultLoadTask *)task didFinishWithLoadedData:(NSArray *)loadedData  API_AVAILABLE(ios(14)) {
    NSMutableArray *successItems = [NSMutableArray array];
    NSMutableArray *failureItems = [NSMutableArray array];
    for (id obj in loadedData) {
        if ([obj isKindOfClass:ICLImageFile.class]) {
            [successItems addObject:obj];
        }
        else if ([obj isKindOfClass:NSError.class]) {
            [failureItems addObject:obj];
        }
        else {
            NSError *error = [NSError errorWithDomain:@"com.bjy.callDidFinishLoadDelegateMethod" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"error info miss."}];
            [failureItems addObject:error];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(photoPicker:didFinishLoadImageData:failureItems:originResult:)]) {
        [self.delegate photoPicker:self didFinishLoadImageData:successItems failureItems:failureItems originResult:self.pickedData];
    }
}



#pragma mark - QBImagePickerController delegate
- (QBImagePickerController *)qbPickerControllerWithConfiguration:(BJLPhotoPickerConfiguration *)configuration {
    QBImagePickerController * pickerVC = [[QBImagePickerController alloc] init];
    pickerVC.mediaType = QBImagePickerMediaTypeImage;
    pickerVC.allowsMultipleSelection = (configuration.selectionLimit > 1);
    pickerVC.showsNumberOfSelectedAssets = YES;
    pickerVC.maximumNumberOfSelection = configuration.selectionLimit;
    pickerVC.delegate = self;
    return pickerVC;
}

- (void)qb_imagePickerController:(QBImagePickerController *)picker didFinishPickingAssets:(NSArray<PHAsset *> *)assets {
    BJLPhotoPickerResult *data = [BJLPhotoPickerResult new];
    data.assetsFormatData = assets;
    self.pickedData = data;
    [self callDidFinishPickingDelegateMethod:data];

    if (!self.configurationStorage.autoLoadImageData) {
        return;
    }
    
    CGSize thumbnailSize = [UIScreen mainScreen].bounds.size;
    if (self.configurationStorage.highQualityMode) {
        thumbnailSize = CGSizeZero;
    }
    [picker icl_loadImageFilesWithAssets:assets contentMode:PHImageContentModeAspectFit
                              targetSize:CGSizeMake(BJLAliIMGMaxSize, BJLAliIMGMaxSize)
                           thumbnailSize:thumbnailSize];
}


- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)picker {
    if ([self.delegate respondsToSelector:@selector(photoPicker:didFinishPicking:)]) {
        [self.delegate photoPicker:self didFinishPicking: nil];
    }
    else if ([self.delegate respondsToSelector:@selector(photoPicker:didFinishLoadImageData:failureItems:originResult:)]) {
        [self.delegate photoPicker:self didFinishLoadImageData:nil failureItems:nil originResult:nil];
    }
}


#pragma mark- icloud loader
- (void)icl_imagePickerController:(QBImagePickerController *)imagePickerController didFinishLoadingImageFiles:(NSArray<ICLImageFile *> *)imageFiles {
    if ([self.delegate respondsToSelector:@selector(photoPicker:didFinishLoadImageData:failureItems:originResult:)]) {
        [self.delegate photoPicker:self didFinishLoadImageData:imageFiles failureItems:nil originResult:self.pickedData];
    }
}

- (void)icl_imagePickerControllerDidCancelLoadingImageFiles:(QBImagePickerController *)imagePickerController {
    if ([self.delegate respondsToSelector:@selector(photoPicker:didFinishLoadImageData:failureItems:originResult:)]) {
        [self.delegate photoPicker:self didFinishLoadImageData:nil failureItems:nil originResult:self.pickedData];
    }
}
@end









@implementation BJLPhotoPickerResult
- (BOOL)empty {
    return (self.assetsFormatData == nil) && (self.phPickerFormatData == nil);
}
@end

@implementation BJLPhotoPickerConfiguration
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.selectionLimit = 1;
        self.filter = BJLPhotoPickerFilterImages;
        self.autoLoadImageData = YES;
        self.highQualityMode = NO;
    }
    return self;
}

- (id)copy
{
    BJLPhotoPickerConfiguration *newObj = [BJLPhotoPickerConfiguration new];
    newObj.selectionLimit = self.selectionLimit;
    newObj.filter = self.filter;
    newObj.autoLoadImageData = self.autoLoadImageData;
    newObj.highQualityMode = self.highQualityMode;
    return newObj;
}

@end



UIImage* loadAndDownsampleImageFromURL(NSURL *url, NSError **error) {
    if (url == nil) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.bjy.loadAndDownsampleImageFromURL" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"url is null"}];
        }
        return nil;
    }
    
    NSDictionary *imgSourceOpt = @{(NSString *)kCGImageSourceShouldCache:@(false)};
    CGImageSourceRef imgSourceRef = CGImageSourceCreateWithURL((CFURLRef)url, (__bridge CFDictionaryRef)imgSourceOpt);
    if (imgSourceOpt == NULL){
        if (error) {
            *error = [NSError errorWithDomain:@"com.bjy.loadAndDownsampleImageFromURL" code:-2 userInfo:@{NSLocalizedDescriptionKey:@"CGImageSourceCreateWithURL failed."}];
        }
        return nil;
    }
    
    NSDictionary *sampleDownImageOpt = @{
        (NSString *)kCGImageSourceCreateThumbnailWithTransform:@(YES),
        (NSString *)kCGImageSourceCreateThumbnailFromImageIfAbsent:@(YES),
        (NSString *)kCGImageSourceThumbnailMaxPixelSize:@(BJLAliIMGMaxSize),
    };
    CGImageRef sampleDownImageRef = CGImageSourceCreateThumbnailAtIndex(imgSourceRef, 0, (__bridge CFDictionaryRef)sampleDownImageOpt);
    if (sampleDownImageRef == NULL){
        if (error) {
            *error = [NSError errorWithDomain:@"com.bjy.loadAndDownsampleImageFromURL" code:-3 userInfo:@{NSLocalizedDescriptionKey:@"CGImageSourceCreateThumbnailAtIndex failed."}];
        }
        return nil;
    }
    
    
    NSMutableData *imageData = [NSMutableData data];
    CGImageDestinationRef imageDestRef = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, kUTTypeJPEG, 1, NULL);
    if (imageDestRef == NULL){
        if (error) {
            *error = [NSError errorWithDomain:@"com.bjy.loadAndDownsampleImageFromURL" code:-4 userInfo:@{NSLocalizedDescriptionKey:@"CGImageDestinationCreateWithData failed."}];
        }
        return nil;
    }
    
    BOOL isPNG = NO;
    CFStringRef type = CGImageGetUTType(sampleDownImageRef);
    if (type != NULL && (CFStringCompare(type, kUTTypePNG, kCFCompareCaseInsensitive) == kCFCompareEqualTo)) {
        isPNG = YES;
    }
    float compressQuality = isPNG ? 1 : 0.6;
    
    NSDictionary *compressOpt = @{(NSString *)kCGImageDestinationLossyCompressionQuality : @(compressQuality)};
    CGImageDestinationAddImage(imageDestRef, sampleDownImageRef, (__bridge CFDictionaryRef)compressOpt);
    CGImageDestinationFinalize(imageDestRef);
    UIImage *image = [UIImage imageWithData:imageData];

    if (imageDestRef) CFRelease(imageDestRef);
    if (type) CFRelease(type);
    if (sampleDownImageRef) CFRelease(sampleDownImageRef);
    if (imgSourceRef) CFRelease(imgSourceRef);
    
    return image;
}

static NSString * const BJYPHTemporaryDirectory = @"BJYPHTemporaryDirectory";
NSURL* copyImageFromSystemTempPathToSandboxTempPath(NSURL *from, NSError **error) {
    NSString *fileDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:BJYPHTemporaryDirectory];
    
    NSString *fileName = [NSString stringWithFormat:@"%lld", ({
        const uint32_t randomLength = 3, randomMultiplier = pow(10, randomLength);
        long long now = (long long)([NSDate timeIntervalSinceReferenceDate] * 1000);
        now = now * randomMultiplier + arc4random_uniform(randomMultiplier);
        now;
    })];
    
    NSString *filePath = [fileDirectory stringByAppendingPathComponent:fileName];
    
    if (error) *error = nil;
    BOOL written = [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectory
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:error];
    if (!written) {
        return nil;
    }

    written = [NSFileManager.defaultManager copyItemAtPath:from.relativePath toPath:filePath error:error];
    if (!written) {
        return nil;
    }
    
    return [NSURL URLWithString:filePath];
}
