//
//  BJLIcBlackboardLayoutViewController+document.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/28.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcBlackboardLayoutViewController (document)

- (void)makeObserversForDocument;

- (void)closeDisplayingDocumentWindowWithID:(NSString *)documentID requestUpdate:(BOOL)requestUpdate;
- (void)closeDisplayingDocumentWindowsWithRequestUpdate:(BOOL)requestUpdate;

- (void)updateBlackboardPageNumber:(CGFloat)pageNumber;
- (void)resetDocumentWindowsWithModel:(BJLWindowUpdateModel *)updateModel;
- (void)updateDocumentWindowWithModel:(BJLWindowUpdateModel *)updateModel;

- (__kindof UIViewController *)displayDocumentWindowWithID:(NSString *)documentID requestUpdate:(BOOL)requestUpdate;
// 切换全屏文档窗口
- (void)switchFullScreenDocumentWindowWithID:(NSString *)documentID;
// 切换最大化文档窗口
- (void)switchMaximizedDocumentWindowWithID:(NSString *)documentID;

- (void)addImageShapeToBlackboardWithURL:(NSString *)imageURL
                               imageSize:(CGSize)imageSize;

- (void)changeDocumentWithDocumentID:(NSString *)documentID pageIndex:(NSInteger)pageIndex;

- (void)getMainMaximizedDisplayInfo:(BJLWindowDisplayInfo * _Nullable * _Nullable)mainMaximizedDisplayInfo
          mainFullScreenDisplayInfo:(BJLWindowDisplayInfo * _Nullable * _Nullable)mainFullScreenDisplayInfo;

@end

NS_ASSUME_NONNULL_END
