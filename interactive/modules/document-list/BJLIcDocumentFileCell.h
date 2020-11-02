//
//  BJLIcDocumentFileCell.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/9/17.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BJLDocumentFile.h"
#import "BJLHomeworkDownloadItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLIcDocumentFileCellType) {
    BJLIcDocumentFileCellTypeDocument,
    BJLIcDocumentFileCellTypeCloud,
    BJLIcDocumentFileCellTypeHomework,
};

@interface BJLIcDocumentFileCell : UITableViewCell

@property (nonatomic) void(^showDocumentCallback)(void);

@property (nonatomic) void(^deleteDocumentCallback)(void);

@property (nonatomic) void(^showErrorCallback)(UIButton *button);

@property (nonatomic) void(^reuploadCallback)(void);

@property (nonatomic) void(^turnToNormalDocumentCallback)(void);

@property (nonatomic) void(^downloadDocumentCallback)(UIButton *button);

+ (NSArray <NSString *> *)allCellIdentifiers;
+ (NSString *)cellIdentifierForCellType:(BJLIcDocumentFileCellType)type;

- (void)updateWithDocumentFile:(nullable BJLDocumentFile *)file
                  downloadItem:(nullable BJLHomeworkDownloadItem *)downloadItem
                     loginUser:(BJLUser *)loginUser
                   isCloudSync:(BOOL)isCloudSync;

@end

NS_ASSUME_NONNULL_END
