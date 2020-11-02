//
//  BJLIcToolboxViewController+private.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/18.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolboxViewController.h"
#import "BJLIcAppearance.h"
#import "BJLIcDrawShapeSelectView.h"
#import "BJLIcDrawStrokeWidthSelectView.h"
#import "BJLIcDrawMarkStrokeWidthSelectView.h"
#import "BJLIcDrawStrokeColorSelectView.h"
#import "BJLIcDrawTextOptionView.h"
#import "BJLIcTeachingAidSelectView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcToolboxViewController ()

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic, readwrite) BJLIcToolboxLayoutType type;
@property (nonatomic) BOOL selectViewHidden;

@property (nonatomic) UIView *referenceViewForPhone;
@property (nonatomic) UIView *containerView;
@property (nonatomic, nullable) UIView *gestureView;
@property (nonatomic) UIView *pptSingleLine, *singleLine;
@property (nonatomic, readwrite) UIButton
*PPTButton,                              // 操作PPT，常驻选中状态
*selectButton,                           // 普通选择
*paintBrushButton,                       // 画笔
*markPenButton,                          // 马克笔
*shapeButton,                            // 形状
*laserPointerButton,                     // 激光笔
*textButton,                             // 文字
*eraserButton,                           // 橡皮
*coursewareButton,                       // 课件
*teachingAidButton,                      // 教具
*groupButton;                            // 分组

@property (nonatomic, nullable) UIButton *currentSelectedButton;

@property (nonatomic) BJLIcDrawShapeSelectView *shapeSelectView; // 形状选择
@property (nonatomic) BJLIcDrawStrokeWidthSelectView *strokeWidthSelectView; // 画笔宽度选择
@property (nonatomic) BJLIcDrawMarkStrokeWidthSelectView *markStrokeWidthSelectView; // 马克笔宽度选择
@property (nonatomic) BJLIcTeachingAidSelectView *teachingAidSelectView; // 教具选择
@property (nonatomic) BJLIcDrawTextOptionView *textOptionView; // 文字选择
@property (nonatomic) BJLIcDrawStrokeColorSelectView *strokeColorSelectView; // 调色盘

@property (nonatomic) BJLDrawingShapeType currentToolboxShape;
@property (nonatomic) CGFloat doodleStrokeWidth;
@property (nonatomic) CGFloat markStrokeWidth;
@property (nonatomic) NSString *paintStrokeColor, *markStrokeColor, *shapeStrokeColor, *textStrokeColor;
@property (nonatomic) UIView *paintStrokeColorView, *markStrokeColorView, *shapeStrokeColorView, *textStrokeColorView;
@property (nonatomic) BJLIcRectPosition toolboxPosition;

- (void)setupGesture;
- (NSArray *)teacherButtons;
- (NSArray *)assistantButtons;
- (NSArray *)studentButtons;
- (NSArray *)optionButtons;

@end

NS_ASSUME_NONNULL_END
