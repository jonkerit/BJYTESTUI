//
//  BJLPhotoPicker.h
//  CodeLabSwift
//
//  Created by Ney on 10/15/20.
//  Copyright © 2020 Ney. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, BJLPhotoPickerFilter) {
    BJLPhotoPickerFilterImages = 1 << 0,
    BJLPhotoPickerFilterAll = BJLPhotoPickerFilterImages
};

@class BJLPhotoPicker;
@class PHAsset;
@class PHPickerResult;
@class BJLPhotoPickerResult;
@class ICLImageFile;

@protocol BJLPhotoPickerDelegate <NSObject>
@optional

/// 用户已经选择好照片
/// @param BJLPhotoPicker picker 实例
/// @param result 包含照片数据的BJLPhotoPickerResult实例
- (void)photoPicker:(BJLPhotoPicker *)BJLPhotoPicker didFinishPicking:(BJLPhotoPickerResult *)result;


/// 已经自动加载好照片
/// @param BJLPhotoPicker picker 实例
/// @param data 成功加载的图片对象
/// @param failureItems 加载失败的对象
/// @param result 原始数据
- (void)photoPicker:(BJLPhotoPicker *)BJLPhotoPicker didFinishLoadImageData:(NSArray<ICLImageFile *> *)data failureItems:(NSArray<NSError *> *)failureItems originResult:(BJLPhotoPickerResult *)result;
@end


@interface BJLPhotoPickerResult : NSObject
@property (nonatomic, strong) NSArray<PHAsset *> *assetsFormatData;
@property (nonatomic, strong) NSArray<PHPickerResult *> *phPickerFormatData;
- (BOOL)empty;
@end


@interface BJLPhotoPickerConfiguration : NSObject
@property (nonatomic, assign) NSInteger selectionLimit;
@property (nonatomic, assign) BJLPhotoPickerFilter filter;

/// 自动加载(包含从icloud下载数据)图片数据，默认YES
@property (nonatomic, assign) BOOL autoLoadImageData;

/// 默认NO
@property (nonatomic, assign) BOOL highQualityMode;
@end


@interface BJLPhotoPicker : NSObject
@property (nonatomic, strong, readonly)  BJLPhotoPickerConfiguration *configuration;
@property (nonatomic, readonly) UIViewController *viewController;
@property (nonatomic, weak) id<BJLPhotoPickerDelegate>  delegate;

+ (BOOL)enableNewPhotoPicker;
+ (void)syncServerConfig_disable_phpicker:(BOOL)disable_phpicker;
- (instancetype)initWithConfiguration:(BJLPhotoPickerConfiguration *)configuration;
- (void)requestAuthorizationIfNeededAndPresentPickerControllerFrom:(UIViewController *)fromController;
- (void)dismissPickerController;
@end


