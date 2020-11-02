//
//  BJLIcDocumentFileView.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/26.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

typedef NS_ENUM(NSInteger, BJLIcDocumentFileLayoutType) {
    BJLIcDocumentFileLayoutTypeDocument,
    BJLIcDocumentFileLayoutTypeCloud,
    BJLIcDocumentFileLayoutTypeHomework,
};

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDocumentFileView : UIView

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic) void(^willshowFilelistCallback)(void);
@property (nonatomic) void(^allowStudentUploadFileCallback)(BOOL allow);
@property (nonatomic) void(^refreshHomeworkCallback)(void);
@property (nonatomic) void(^uploadFileCallback)(void);
@property (nonatomic) void(^switchToHomeworkCallback)(void);

@property (nonatomic, readonly) BJLIcDocumentFileLayoutType documentFileLayoutType;

// 关联文件是否展示的搜索结果
@property (nonatomic, readwrite) BOOL shouldShowSearchResult;

/**
 关闭课件管理视图
 */
@property (nonatomic, readonly) UIButton *closeButton;

@property (nonatomic, readonly) UITextField *searchTextField;

/**
搜索框的清空按钮
*/
@property (nonatomic, readonly) UIButton *clearSearchButton;

/**
 文档集合视图
 */
@property (nonatomic, readonly) UITableView *tableView;

/**
 更新文档视图显示

 #param hidden NO --> 不存在文档时隐藏, YES --> 存在文档时显示
 */
- (void)updateDocumentFileViewHidden:(BOOL)hidden;

@property (nonatomic, readonly) BJLButton *uploadFileButton;

@end

NS_ASSUME_NONNULL_END
