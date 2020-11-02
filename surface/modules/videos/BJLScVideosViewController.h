//
//  BJLScVideosViewController.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLScAppearance.h"
#import "BJLScMediaInfoView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScVideosViewController : UIViewController

// 点击的视频，点击的视频索引，大屏视图将要替换成的类型
@property (nonatomic, nullable) void (^replaceMajorWindowCallback)(BJLScMediaInfoView * _Nullable mediaInfoView, NSInteger index, BJLScWindowType majorWindowType, BOOL recording);
@property (nonatomic, nullable) void (^resetPPTCallback)(void);
@property (nonatomic, nullable) void (^restoreFullscreenOrMajorWindowCallback)(void); // 处理视频列表持有的视图在全屏区域时，销毁之后没有清理全屏区域的情况
@property (nonatomic, nullable) void (^updateVideoCallback)(BJLMediaUser *user, BOOL on);
@property (nonatomic, nullable, weak, readonly) BJLScMediaInfoView *majorMediaInfoView; // 大屏区域的媒体视图

- (instancetype)initWithRoom:(BJLRoom *)room;
// 重置视频列表，收回在大屏区域的视频
- (void)resetVideo;
// 因为视频位置改变，更新视频列表
- (void)updateCurrentMediaInfoViews;
// 由于辅助摄像头的出现更新列表，一般移除辅助摄像头将不需要处理
- (void)reloadVideoWithTeacherExtraMediaInfoView:(nullable BJLScMediaInfoView *)teacherExtraMediaInfoView;
// 替换视频列表 index 位置的内容替换到大屏，如果存在老师辅助摄像头，则替换老师辅助摄像头
- (void)replaceMajorContentViewAtIndex:(NSInteger)index recording:(BOOL)recording teacherExtraMediaInfoView:(nullable BJLScMediaInfoView *)teacherExtraMediaInfoView;

@end

NS_ASSUME_NONNULL_END
