//
//  BJLScStickyCell.h
//  BJLiveUI
//
//  Created by xyp on 2020/8/12.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString
* const BJLScStudentStickyCellIdentifier,
* const BJLScTeacherStickyCellIdentifier;

@interface BJLScStickyCell : UITableViewCell

@property (nonatomic, nullable) void (^cancelStickyCallback)(void);
@property (nonatomic, nullable) BOOL (^linkURLCallback)(NSURL *url);
@property (nonatomic, nullable) void (^imageTapCallback)(BJLMessage * _Nullable message);

@property (nonatomic, readonly) BJLMessage *message;

- (void)updateWithMessage:(BJLMessage *)message
             customString:(NSString *)customString;

@end

NS_ASSUME_NONNULL_END
