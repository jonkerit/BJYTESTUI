//
//  BJLScToolView.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScToolView : UIView

typedef NS_ENUM(NSInteger, BJLScToolViewButtonType) {
    BJLScToolViewButtonType_none,
    BJLScToolViewButtonType_select,
    BJLScToolViewButtonType_paintBrush,
    BJLScToolViewButtonType_markPen,
    BJLScToolViewButtonType_shape,
    BJLScToolViewButtonType_text,
    BJLScToolViewButtonType_laserPointer,
    BJLScToolViewButtonType_eraser,
    BJLScToolViewButtonType_courseware,
    BJLScToolViewButtonType_countDown,
    _BJLScToolViewButtonType_count
};

- (instancetype)initWithRoom:(BJLRoom *)room;

@property (nonatomic, readonly) BOOL expectedHidden; // 根据 room 的状态的期望的显示或者隐藏效果

@property (nonatomic, nullable) void (^remakeConstraintsCallback)(void);
@property (nonatomic, nullable) void (^showErrorMessageCallback)(NSString *message);
@property (nonatomic, nullable) void (^toolButtonClickCallback)(BJLScToolViewButtonType type, BOOL isSelected);

@property (nonatomic, readonly) UIButton
*selectButton,                           // 普通选择
*paintBrushButton,                       // 画笔
*markPenButton,                          // 马克笔
*shapeButton,                            // 形状
*textButton,                             // 文字
*laserPointerButton,                     // 激光笔
*eraserButton,                           // 橡皮
*coursewareButton,                       // 课件
*countDownButton;                        // 倒计时

@property (nonatomic) NSString *paintStrokeColor, *markStrokeColor, *shapeStrokeColor, *textStrokeColor;
@property (nonatomic) UIView *paintStrokeColorView, *markStrokeColorView, *shapeStrokeColorView, *textStrokeColorView;

@property (nonatomic) BJLDrawingShapeType currentToolboxShape;
@property (nonatomic) CGFloat markStrokeWidth, doodleStrokeWidth;

- (CGSize)expectedSize;
- (void)updateToolboxShape:(NSString *)shapeKey;

@end

NS_ASSUME_NONNULL_END
