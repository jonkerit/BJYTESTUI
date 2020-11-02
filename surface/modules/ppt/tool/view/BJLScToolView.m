//
//  BJLScToolView.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLScToolView.h"
#import "BJLScAppearance.h"

@interface BJLScToolView ()

@property (nonatomic, weak) BJLRoom *room;

@property (nonatomic, readwrite) BOOL expectedHidden;
@property (nonatomic) UIView *singleLine;

@property (nonatomic, readwrite) UIButton
*selectButton,                           // 普通选择
*paintBrushButton,                       // 画笔
*markPenButton,                          // 马克笔
*shapeButton,                            // 形状
*textButton,                             // 文字
*laserPointerButton,                     // 激光笔
*eraserButton,                           // 橡皮
*coursewareButton,                       // 课件
*countDownButton;                        // 倒计时

@property (nonatomic, nullable) UIButton *currentSelectedButton;
@property (nonatomic) NSArray <UIView *> *views;

@end

@implementation BJLScToolView

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super initWithFrame:CGRectZero]) {
        self.room = room;
        self.expectedHidden = YES;
        [self makeSubviews];
        [self remakeToolButtonConstraints];
        [self makeObserving];
        
        self.currentToolboxShape = BJLDrawingShapeType_segment;
        self.doodleStrokeWidth = room.drawingVM.doodleStrokeWidth;
        self.markStrokeWidth = 8.0;
    }
    return self;
}

- (CGSize)expectedSize {
    NSInteger toolCount = self.views.count;
    
    CGSize size = CGSizeZero;
    if (!toolCount) {
        return size;
    }
    
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (iPhone) {
        size = CGSizeMake(BJLScToolViewWidth, toolCount * BJLScToolViewWidth + (toolCount + 1) * BJLScToolViewButtonSpace);
    }
    else {
        size = CGSizeMake(toolCount * BJLScToolViewButtonWidth + (toolCount + 1) * BJLScToolViewButtonSpace, BJLScToolViewWidth);
    }
    return size;
}


#pragma mark - init view

- (void)makeSubviews {
    self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    self.layer.cornerRadius = 4.0;
    self.layer.masksToBounds = NO;
    self.layer.shadowOpacity = 0.3;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    self.layer.shadowRadius = 2.0;
    
    self.selectButton       = [self makeButtonWithImage:@"bjl_sc_toolview_select_normal" selectedImage:@"bjl_sc_toolview_select_selected" accessibilityLabel:BJLKeypath(self, selectButton)];
    self.paintBrushButton   = [self makeButtonWithImage:@"bj_sc_toolview_paintbrush_normal" selectedImage:@"bjl_sc_toolview_paintbrush_selected" accessibilityLabel:BJLKeypath(self, paintBrushButton)];
    self.markPenButton      = [self makeButtonWithImage:@"bjl_sc_toolview_marker_normal" selectedImage:@"bjl_sc_toolview_marker_selected" accessibilityLabel:BJLKeypath(self, markPenButton)];
    self.shapeButton        = [self makeButtonWithImage:@"bjl_sc_toolbox_draw_shape_segment_normal" selectedImage:@"bjl_sc_toolbox_draw_shape_segment_selected" accessibilityLabel:BJLKeypath(self, shapeButton)];
    self.textButton         = [self makeButtonWithImage:@"bjl_sc_toolview_text_normal" selectedImage:@"bjl_sc_toolview_text_selected" accessibilityLabel:BJLKeypath(self, textButton)];
    self.laserPointerButton = [self makeButtonWithImage:@"bjl_sc_toolview_laserpointer_normal" selectedImage:@"bjl_sc_toolview_laserpointer_selected" accessibilityLabel:BJLKeypath(self, laserPointerButton)];
    self.eraserButton       = [self makeButtonWithImage:@"bjl_sc_toolview_eraser_normal" selectedImage:@"bjl_sc_toolview_eraser_selected" accessibilityLabel:BJLKeypath(self, eraserButton)];
    
    self.coursewareButton   = [self makeButtonWithImage:@"bjl_sc_toolview_courseware_normal" accessibilityLabel:BJLKeypath(self, coursewareButton)];
    self.countDownButton    = [self makeButtonWithImage:@"bjl_sc_timer" accessibilityLabel:BJLKeypath(self, coursewareButton)];
    
    self.paintStrokeColorView = [self makeStrokeColorView:BJLKeypath(self, paintStrokeColorView)];
    self.markStrokeColorView = [self makeStrokeColorView:BJLKeypath(self, markStrokeColorView)];
    self.shapeStrokeColorView = [self makeStrokeColorView:BJLKeypath(self, shapeStrokeColorView)];
    self.textStrokeColorView = [self makeStrokeColorView:BJLKeypath(self, textStrokeColorView)];
}

- (void)remakeStrokeColorConstraints {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    
    NSArray<UIView *> *buttons = @[self.paintBrushButton, self.markPenButton, self.shapeButton, self.textButton];
    NSArray<UIView *> *colorViews = @[self.paintStrokeColorView, self.markStrokeColorView, self.shapeStrokeColorView, self.textStrokeColorView];
    for (NSInteger i = 0; i < buttons.count; i++) {
        UIView *button = [buttons bjl_objectAtIndex:i];
        UIView *colorView = [colorViews bjl_objectAtIndex:i];
        [self addSubview:colorView];
        if (iPhone) {
            [colorView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.right.equalTo(self);
                make.centerY.equalTo(button);
                make.height.equalTo(@(BJLScToolViewColorLength));
                make.width.equalTo(@(BJLScToolViewColorSize));
            }];
        }
        else {
            [colorView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.bottom.equalTo(self);
                make.centerX.equalTo(button);
                make.width.equalTo(@(BJLScToolViewColorLength));
                make.height.equalTo(@(BJLScToolViewColorSize));
            }];
        }
    }
}


#pragma mark - Observing

- (void)makeObserving {
    bjl_weakify(self);
    BJLPropertyFilter ifIntegerChanged = ^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        return now != old;
    };

    [self bjl_kvo:BJLMakeProperty(self.room, state)
           filter:ifIntegerChanged
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.state == BJLRoomState_connected) {
            [self remakeToolButtonConstraints];
        }
        return YES;
    }];
    
    if (!self.room.loginUser.isTeacherOrAssistant) {
        [self bjl_kvoMerge:@[BJLMakeProperty(self.room.drawingVM, drawingGranted),
                             BJLMakeProperty(self.room.speakingRequestVM, speakingEnabled)]
                    filter:ifIntegerChanged
                  observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            [self remakeToolButtonConstraints];
        }];
    }
    
    if (self.room.loginUser.isAssistant) {
        [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveAssistantaAuthorityChanged)
                 observer:^BOOL{
            bjl_strongify(self);
            // 权限变更  重新布局
            [self remakeToolButtonConstraints];
            return YES;
        }];
    }
    
#pragma mark - strokeColor
    
    // 小黑板使用中，老师取消授权画笔时，重置画笔工具状态
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, brushOperateMode)
           filter:^BJLControlObserving(NSNumber * _Nullable value, NSNumber * _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        //        bjl_strongify(self);
        BJLBrushOperateMode mode = value.integerValue;
        return (BJLBrushOperateMode_defaut == mode && value.integerValue != oldValue.integerValue);
    }
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self cancelCurrentSelectedButton];
        return YES;
    }];
    
    //    此处主要是处理文字画笔工具再编辑时,更新画笔工具的状态
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, brushOperateMode)
           filter:^BJLControlObserving(NSNumber * _Nullable value, NSNumber * _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        BJLBrushOperateMode mode = value.integerValue;
        return (BJLBrushOperateMode_draw == mode
                && value.integerValue != oldValue.integerValue
                && self.room.drawingVM.drawingShapeType ==BJLDrawingShapeType_text );
    }
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.currentSelectedButton == self.selectButton) {
            [self cancelCurrentSelectedButton];
            
            self.currentSelectedButton = self.textButton;
            self.currentSelectedButton.selected = YES;
        }
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, doodleStrokeWidth)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        CGFloat strokeWidth = self.room.drawingVM.doodleStrokeWidth;
        if (self.markPenButton.selected) {
            self.markStrokeWidth = strokeWidth;
        }
        else {
            self.doodleStrokeWidth = strokeWidth;
        }
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, hasSelectedShape)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        UIImage *image = self.room.drawingVM.hasSelectedShape ? [UIImage bjlsc_imageNamed:@"bjl_sc_toolview_delete_normal"] : [UIImage bjlsc_imageNamed:@"bjl_sc_toolview_eraser_normal"];
        UIImage *selectedImage = self.room.drawingVM.hasSelectedShape ? [UIImage bjlsc_imageNamed:@"bjl_sc_toolview_delete_selected"] : [UIImage bjlsc_imageNamed:@"bjl_sc_toolview_eraser_selected"];
        [self.eraserButton bjl_setImage:image forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
        [self.eraserButton bjl_setImage:selectedImage forState:UIControlStateSelected optionalStates:UIControlStateHighlighted];
        return YES;
    }];
    
    // 学生本地页面和远端老师页码不一致时，需要更新drawingEnabled
    [self bjl_kvo:BJLMakeProperty(self.room.slideshowViewController, pageIndex)
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.slideshowViewController.pageIndex != self.room.documentVM.currentSlidePage.documentPageIndex) {
            if (!self.room.loginUser.isTeacherOrAssistant
                && self.room.slideshowViewController.drawingEnabled) {
                [self.room.drawingVM updateDrawingEnabled:NO];
            }
        }
        return YES;
    }];
}

#pragma mark - update toolbox shape

- (void)updateToolboxShape:(NSString *)shapeKey {
    UIImage *image = [UIImage bjlsc_imageNamed:[NSString stringWithFormat:@"bjl_sc_toolbox_%@_normal", shapeKey]];
    UIImage *selectedImage = [UIImage bjlsc_imageNamed:[NSString stringWithFormat:@"bjl_sc_toolbox_%@_selected", shapeKey]];
    [self.shapeButton bjl_setImage:image forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
    [self.shapeButton bjl_setImage:selectedImage forState:UIControlStateSelected optionalStates:UIControlStateHighlighted];
}

#pragma mark - action

- (void)cancelCurrentSelectedButton {
    self.currentSelectedButton.selected = NO;
    self.currentSelectedButton = nil;
}

- (void)didSelectButton:(UIButton *)button {
    // 画笔开关: TODO: coding style
    BOOL drawingEnabled = (button != self.currentSelectedButton
                           && (button == self.selectButton
                               || button == self.paintBrushButton
                               || button == self.markPenButton
                               || button == self.shapeButton
                               || button == self.textButton
                               || button == self.laserPointerButton
                               || button == self.eraserButton));
    if (drawingEnabled) {
        if (self.room.loginUser.isTeacherOrAssistant) {
            if (!self.room.roomVM.liveStarted) {
                [self showErrorMessage:@"上课状态才能开启画笔"];
                return;
            }
        }
        else if (!self.room.drawingVM.drawingGranted) {
            [self showErrorMessage:@"未被授权使用画笔"];
            return;
        }
        
        if (self.room.slideshowViewController.pageIndex != self.room.documentVM.currentSlidePage.documentPageIndex) {
            [self showErrorMessage:@"PPT 翻页与老师不同步，不能开启画笔"];
            return;
        }
    }
    
    BOOL enableSelectButton = self.room.drawingVM.hasSelectedShape;
    // 如果点击当前选中的 button
    if ([button isEqual:self.currentSelectedButton]) {
        [self cancelCurrentSelectedButton];
    }
    // 点击的 button 不是当前选中的 button
    else {
        // 选中点击的 button
        self.currentSelectedButton.selected = NO;
        self.currentSelectedButton = button;
        self.currentSelectedButton.selected = YES;
    }
    
    BJLError *requestError = [self.room.drawingVM updateDrawingEnabled:drawingEnabled];
    if (self.paintBrushButton.selected) {
        // UI上虚线和涂鸦画笔互斥
        self.room.drawingVM.drawingShapeType = BJLDrawingShapeType_doodle;
        self.room.drawingVM.isDottedLine = NO;
    }
    
    // 普通画笔、马克笔线宽及透明度设置
    if (self.markPenButton.selected) {
        self.room.drawingVM.drawingShapeType = BJLDrawingShapeType_doodle;
        self.room.drawingVM.doodleStrokeWidth = self.markStrokeWidth;
        self.room.drawingVM.strokeAlpha = 0.3;
    }
    else {
        self.room.drawingVM.doodleStrokeWidth = self.doodleStrokeWidth;
        self.room.drawingVM.strokeAlpha = 1.0;
    }
    
    // 画笔模式操作模式
    BJLBrushOperateMode operateMode = BJLBrushOperateMode_defaut;
    if (drawingEnabled
        && !self.selectButton.selected
        && !self.eraserButton.selected) {
        // 添加画笔开关
        operateMode = BJLBrushOperateMode_draw;
    }
    else if (self.selectButton.selected) {
        // 画笔选择开关
        operateMode = BJLBrushOperateMode_select;
    }
    else if (self.eraserButton.selected) {
        // 橡皮擦开关
        operateMode = BJLBrushOperateMode_erase;
    }
    
    requestError = [self.room.drawingVM updateBrushOperateMode:operateMode] ?: requestError;
    
    // request 之后画笔的开关状态, writingBoardEnabled = YES 则返回有画笔权限
    drawingEnabled = self.room.drawingVM.drawingEnabled;
    // 激光笔
    if (self.laserPointerButton.selected) {
        if (drawingEnabled) {
            self.room.drawingVM.drawingShapeType = BJLDrawingShapeType_laserPoint;
        }
    }
    else  {
        if (self.room.drawingVM.drawingShapeType == BJLDrawingShapeType_laserPoint) {
            self.room.drawingVM.drawingShapeType = BJLDrawingShapeType_doodle;
            self.room.drawingVM.isDottedLine = NO;
        }
    }
    
    // 文字
    if (self.textButton.selected) {
        if (drawingEnabled) {
            self.room.drawingVM.drawingShapeType = BJLDrawingShapeType_text;
        }
    }
    else {
        if (self.room.drawingVM.drawingShapeType == BJLDrawingShapeType_text) {
            self.room.drawingVM.drawingShapeType = BJLDrawingShapeType_doodle;
        }
    }
    
    // 图形
    if (self.shapeButton.selected) {
        if (drawingEnabled) {
            // 设置图形
            self.room.drawingVM.drawingShapeType = self.currentToolboxShape;
        }
    }
    
    //requestError 是获取的大黑板的drawingEnabled, 如果有小黑板的画笔权限不报错
    if (requestError && !drawingEnabled) {
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(requestError.localizedFailureReason);
        }
        [self cancelCurrentSelectedButton];
    }
    
    // 特别的，橡皮擦删除了框选画笔之后，重置为选择按钮
    if (self.currentSelectedButton == self.eraserButton
        && enableSelectButton) {
        [self.selectButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }

    if (self.toolButtonClickCallback) {
        self.toolButtonClickCallback([self toolViewButtonTypeWithButton:button], button.isSelected);
    }
    
}

- (void)buttonClickAction:(UIButton *)button {
    // 单独处理 countDownButton 或者 coursewareButton
    if (button == self.countDownButton
        || button == self.coursewareButton) {
        if (self.toolButtonClickCallback) {
            self.toolButtonClickCallback([self toolViewButtonTypeWithButton:button], button.isSelected);
        }
    }
}

- (void)showErrorMessage:(NSString *)message {
    if (self.showErrorMessageCallback) {
        self.showErrorMessageCallback(message);
    }
}

#pragma mark - wheel

- (UIView *)makeStrokeColorView:(NSString *)accessibilityLabel {
    UIView *view = [UIView new];
    NSString *strokeColor = self.room.drawingVM.strokeColor;
    view.backgroundColor = [UIColor bjl_colorWithHexString:strokeColor];
    self.paintStrokeColor = self.markStrokeColor = self.shapeStrokeColor = self.textStrokeColor = strokeColor;
    view.accessibilityLabel = accessibilityLabel;
    return view;
}

- (UIButton *)makeButtonWithImage:(NSString *)imageName accessibilityLabel:(NSString *)accessibilityLabel {
    UIButton *button = [UIButton new];
    button.backgroundColor = [UIColor clearColor];
    CGFloat inset = 2.0;
    button.imageEdgeInsets = UIEdgeInsetsMake(inset, inset, inset, inset);
    button.accessibilityLabel = accessibilityLabel;
    UIImage *image = [[UIImage bjlsc_imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    if (image) {
        [button bjl_setImage:image forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
    }
    [button addTarget:self action:@selector(buttonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)makeButtonWithImage:(nullable NSString *)imageName
                    selectedImage:(nullable NSString *)selectedImageName
               accessibilityLabel:(NSString *)accessibilityLabel {
    // create custom button
    BJLScImageButton *button = [BJLScImageButton new];
    
    button.accessibilityLabel = accessibilityLabel;
    CGFloat inset = 2.0;
    button.imageEdgeInsets = UIEdgeInsetsMake(inset, inset, inset, inset);
    
    button.backgroundSize = CGSizeMake(BJLScToolViewButtonWidth, BJLScToolViewButtonWidth);
    button.backgroundCornerRadius = BJLScToolViewCornerRadius;
    
    // yes:禁止同时点击; 默认为no，可以同时点击
    button.exclusiveTouch = YES;
    
    // selected no tint color
    button.tintColor = [UIColor clearColor];
    [button addTarget:self action:@selector(didSelectButton:) forControlEvents:UIControlEventTouchUpInside];
    
    // use origin image
    UIImage *image = [[UIImage bjlsc_imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *selectedImage = [[UIImage bjlsc_imageNamed:selectedImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    if (image) {
        [button bjl_setImage:image forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
    }
    if (selectedImage) {
        [button bjl_setImage:selectedImage forState:UIControlStateSelected optionalStates:UIControlStateHighlighted];
        button.selectedColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    }
    return button;
}

- (BJLScToolViewButtonType)toolViewButtonTypeWithButton:(UIButton *)button {
    if ([button isEqual:self.selectButton]) {
        return BJLScToolViewButtonType_select;
    }
    else if ([button isEqual:self.paintBrushButton]) {
        return BJLScToolViewButtonType_paintBrush;
    }
    else if ([button isEqual:self.markPenButton]) {
        return BJLScToolViewButtonType_markPen;
    }
    else if ([button isEqual:self.shapeButton]) {
        return BJLScToolViewButtonType_shape;
    }
    else if ([button isEqual:self.textButton]) {
        return BJLScToolViewButtonType_text;
    }
    else if ([button isEqual:self.laserPointerButton]) {
        return BJLScToolViewButtonType_laserPointer;
    }
    else if ([button isEqual:self.eraserButton]) {
        return BJLScToolViewButtonType_eraser;
    }
    else if ([button isEqual:self.coursewareButton]) {
        return BJLScToolViewButtonType_courseware;
    }
    else if ([button isEqual:self.countDownButton]) {
        return BJLScToolViewButtonType_countDown;
    }
    
    return BJLScToolViewButtonType_none;
}

#pragma mark - remake

- (void)remakeToolButtonConstraints {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    
    BOOL is1toN = self.room.roomInfo.roomType == BJLRoomType_1vNClass;
    BOOL drawingGranted = NO;
    BOOL enableTeachingAid = NO;
    if (self.room.loginUser.isTeacher) {
        drawingGranted = YES;
        enableTeachingAid = YES;
    }
    else if (self.room.loginUser.isAssistant) {
        drawingGranted = [self.room.roomVM getAssistantaAuthorityWithPainter];
    }
    else {
        drawingGranted = (self.room.speakingRequestVM.speakingEnabled || !is1toN) && self.room.drawingVM.drawingGranted;
    }
    NSMutableArray<UIView *> *views = [NSMutableArray new];
    if (drawingGranted) {
        [views addObjectsFromArray:[self drawingButtons]];
    }
    // 不论助教是否有上传文档的权限,都需要有coursewareButton按钮
    if (self.room.loginUser.isTeacherOrAssistant) {
        [views addObjectsFromArray:[self documentButtons]];
    }
    if (enableTeachingAid) {
        [views addObjectsFromArray:[self optionButtons]];
    }
    self.views = views;
    BOOL expectedHidden = !self.views.count || self.room.loginUser.isAudition || self.room.loadingVM;
    if (self.expectedHidden != expectedHidden) {
        self.expectedHidden = expectedHidden;
    }
        
    UIView *last = nil;
    for (UIView *view in views) {
        [self addSubview:view];
        if (iPhone) {
            [view bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                if (last) {
                    make.top.equalTo(last.bjl_bottom).offset(BJLScToolViewButtonSpace);
                    make.centerX.width.height.equalTo(last);
                }
                else {
                    make.top.equalTo(self).offset(BJLScToolViewButtonSpace);
                    make.left.right.equalTo(self);
                    make.height.equalTo(view.bjl_width);
                }
            }];
        }
        else {
            [view bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                if (last) {
                    make.left.equalTo(last.bjl_right).offset(BJLScToolViewButtonSpace);
                    make.centerY.width.height.equalTo(last);
                }
                else {
                    make.left.equalTo(self).offset(BJLScToolViewButtonSpace);
                    make.height.equalTo(@(BJLScToolViewButtonWidth));
                    make.centerY.equalTo(self);
                    make.width.equalTo(view.bjl_height);
                }
            }];
        }
        last = view;
    }
    if (self.remakeConstraintsCallback) {
        self.remakeConstraintsCallback();
    }
    if (drawingGranted) {
        [self remakeStrokeColorConstraints];
    }
}

- (NSArray *)drawingButtons {
    return @[self.selectButton, self.paintBrushButton, self.markPenButton, self.shapeButton, self.textButton, self.laserPointerButton, self.eraserButton];
}

- (NSArray *)documentButtons {
    return @[self.coursewareButton];
}

- (NSArray *)optionButtons {
    return @[self.countDownButton];
}

@end
