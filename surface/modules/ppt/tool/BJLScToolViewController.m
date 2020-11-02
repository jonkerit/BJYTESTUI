//
//  BJLScToolViewController.m
//  BJLiveUI
//
//  Created by xyp on 2020/8/19.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLScToolViewController.h"
#import "BJLScToolView.h"
#import "BJLScAppearance.h"

#import "BJLScStrokeColorSelectView.h"
#import "BJLScStrokeWidthSelectView.h"
#import "BJLScMarkStrokeWidthSelectView.h"
#import "BJLScShapeSelectView.h"
#import "BJLScTextOptionView.h"
#import "BJLScLaserPointView.h"

@interface BJLScToolViewController ()

@property (nonatomic, weak) BJLRoom *room;

@property (nonatomic) BJLScToolView *toolView;
@property (nonatomic, readwrite) BOOL expectedHidden;

@property (nonatomic) BJLScStrokeWidthSelectView *strokeWidthSelectView; // 画笔宽度选择
@property (nonatomic) BJLScMarkStrokeWidthSelectView *markStrokeWidthSelectView; // 马克笔宽度选择
@property (nonatomic) BJLScShapeSelectView *shapeSelectView; // 形状选择
@property (nonatomic) BJLScTextOptionView *textOptionView; // 文字选择
@property (nonatomic) BJLScStrokeColorSelectView *strokeColorSelectView; // 调色盘
@property (nonatomic) BJLScLaserPointView *laserPointView; // 激光笔

@property (nonatomic) BOOL selectViewHidden, isFullScreen, hasMoved;
@property (nonatomic) CGFloat toolViewOffset;

@end

@implementation BJLScToolViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
        self.toolViewOffset = 16.0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    bjl_weakify(self);
    self.view = [BJLHitTestView viewWithTitTestBlock:^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
        bjl_strongify(self);
        if ([hitView isKindOfClass:[UIButton class]]
            || [hitView isKindOfClass:[BJLScToolView class]]
            || [hitView isKindOfClass:[UICollectionView class]]
            || [hitView isKindOfClass:[UITableView class]]) {
            return hitView;
        }
        
        if (!self.selectViewHidden) {
            [self hideSelectViewAndOptionView];
        }
        
        if (hitView == self.laserPointView) {
            return hitView;
        }
        
        return nil;
    }];
    
    self.selectViewHidden = YES;
    [self makeSubviews];
    [self makeConstraintsFullScreen:NO];
    [self makeObserving];
    [self makeCallback];
}

#pragma mark - public

- (void)removeFromView:(UIView *)removeView
        addToSuperView:(UIView *)superView
      shouldFullScreen:(BOOL)shouldFullScreen {
    if ([self.view.superview isEqual:removeView]) {
        [self.view removeFromSuperview];
        [superView addSubview:self.view];
        [self.view bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(superView);
        }];
    }
    
    [self makeConstraintsFullScreen:shouldFullScreen];
}

- (void)updateToolViewHidden:(BOOL)shouldHidden {
    self.toolView.hidden = shouldHidden;
}

#pragma mark - view

- (void)makeSubviews {
    
    self.laserPointView = [[BJLScLaserPointView alloc] initWithRoom:self.room];
    self.laserPointView.accessibilityLabel = BJLKeypath(self, laserPointView);
    
    self.toolView = [[BJLScToolView alloc] initWithRoom:self.room];
    bjl_weakify(self);
    [self.toolView setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        [self showProgressHUDWithText:message];
    }];
    self.toolView.accessibilityLabel = BJLKeypath(self, toolView);
    [self.view addSubview:self.toolView];
    [self setupGesture];
    
    // 线宽选择
    self.strokeWidthSelectView = [[BJLScStrokeWidthSelectView alloc] initWithRoom:self.room];
    self.strokeWidthSelectView.hidden = YES;
    self.strokeWidthSelectView.accessibilityLabel = BJLKeypath(self, strokeWidthSelectView);
    
    // 马克笔线宽选择
    self.markStrokeWidthSelectView = [[BJLScMarkStrokeWidthSelectView alloc] initWithRoom:self.room];
    self.markStrokeWidthSelectView.hidden = YES;
    self.markStrokeWidthSelectView.accessibilityLabel = BJLKeypath(self, markStrokeWidthSelectView);
    
    // 图形选择
    self.shapeSelectView = [[BJLScShapeSelectView alloc] initWithRoom:self.room];
    self.shapeSelectView.hidden = YES;
    self.shapeSelectView.accessibilityLabel = BJLKeypath(self, shapeSelectView);
    
    // 字体选择
    self.textOptionView = [[BJLScTextOptionView alloc] initWithRoom:self.room];
    self.textOptionView.hidden = YES;
    self.textOptionView.accessibilityLabel = BJLKeypath(self, textOptionView);
    
    // 颜色选择
    self.strokeColorSelectView = [[BJLScStrokeColorSelectView alloc] initWithRoom:self.room];
    self.strokeColorSelectView.hidden = YES;
    self.strokeColorSelectView.accessibilityLabel = BJLKeypath(self, strokeColorSelectView);
}

- (void)makeConstraintsFullScreen:(BOOL)isFullScreen {
    self.isFullScreen = isFullScreen;
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (!self.toolView.superview) {
        [self.view addSubview:self.toolView];
    }
    
    if (isFullScreen) {
        [self.toolView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.view.bjl_safeAreaLayoutGuide).offset(iPhone ? -8.0 : -24.0);
            make.top.equalTo(self.view.bjl_safeAreaLayoutGuide).offset(iPhone ? 8.0 : 24.0);
            make.height.equalTo(@(self.toolView.expectedSize.height));
            make.width.equalTo(@(self.toolView.expectedSize.width));
        }];
    }
    else {
        [self.toolView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.view.bjl_right).offset(iPhone ? -8.0 : -16.0);
            if (iPhone) {
                make.bottom.equalTo(self.view).offset(-24.0 - BJLScControlSize);
            }
            else {
                make.top.equalTo(self.view.bjl_top).offset(self.toolViewOffset);
            }
            make.height.equalTo(@(self.toolView.expectedSize.height));
            make.width.equalTo(@(self.toolView.expectedSize.width)); 
        }];
    }
}

- (void)updateToolViewOffset:(CGFloat)offset {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (!self.isFullScreen && !iPhone && !self.hasMoved) {
        self.toolViewOffset = 16.0 + offset;
        if (self.toolView.superview != self.view) {
            return;
        }
        [self.toolView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.view.bjl_top).offset(self.toolViewOffset);
        }];
    }
}

#pragma mark - call back

- (void)makeCallback {
    bjl_weakify(self);
    // 大小班切换时, 用户角色可能变化,需要更新画笔工具的约束
    [self.toolView setRemakeConstraintsCallback:^{
        bjl_strongify(self);
        if (self.toolView.superview) {
            [self.toolView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.width.equalTo(@(self.toolView.expectedSize.width));
                make.height.equalTo(@(self.toolView.expectedSize.height));
            }];
        }
    }];
    
    [self.toolView setToolButtonClickCallback:^(BJLScToolViewButtonType type, BOOL isSelected) {
        bjl_strongify(self);
        [self hideSelectViewAndOptionView];
        if (type == BJLScToolViewButtonType_courseware) {
            if (self.showCoursewareCallback) {
                self.showCoursewareCallback();
            }
        }
        else if (type == BJLScToolViewButtonType_countDown){
            if (self.openCountDownCallback) {
                self.openCountDownCallback();
            }
        }
        else if (type == BJLScToolViewButtonType_laserPointer){
            if (!isSelected) {
                [self.laserPointView hideLaserPoint];
            }
        }
        else {        
            if (isSelected) {
                [self toolButtonClickWithType:type];
            }
        }
    }];
}

- (void)toolButtonClickWithType:(BJLScToolViewButtonType)type {
    UIView *selectView = nil;
    UIButton *button = nil;
    NSString *strokeColor = nil;
    CGSize expectedSize = CGSizeZero;
    switch (type) {
        case BJLScToolViewButtonType_paintBrush:
            selectView = self.strokeWidthSelectView;
            button = self.toolView.paintBrushButton;
            expectedSize = self.strokeWidthSelectView.expectedSize;
            strokeColor = self.toolView.paintStrokeColor;
            break;
            
        case BJLScToolViewButtonType_markPen:
            selectView = self.markStrokeWidthSelectView;
            button = self.toolView.markPenButton;
            expectedSize = self.markStrokeWidthSelectView.expectedSize;
            strokeColor = self.toolView.markStrokeColor;
            break;
            
        case BJLScToolViewButtonType_shape:
            selectView = self.shapeSelectView;
            button = self.toolView.shapeButton;
            expectedSize = self.shapeSelectView.expectedSize;
            strokeColor = self.toolView.shapeStrokeColor;
            break;
            
        case BJLScToolViewButtonType_text:
            selectView = self.textOptionView;
            button = self.toolView.textButton;
            expectedSize = self.textOptionView.expectedSize;
            strokeColor = self.toolView.textStrokeColor;
            break;
            
        default:
            break;
    }
    // selectView 或者 button 为空，说明点击的不是上面的四个按钮
    if (!selectView || !button) {
        return;
    }
    selectView.hidden = NO;
    self.strokeColorSelectView.hidden = NO;
    self.selectViewHidden = NO;
    
    if (!selectView.superview || selectView.superview != self.view) {
        [self.view addSubview:selectView];
    }
    
    if (!self.strokeColorSelectView.superview || self.strokeColorSelectView.superview != self.view) {
        [self.view insertSubview:self.strokeColorSelectView belowSubview:self.toolView];
        
    }
    if (strokeColor) {
        self.strokeColorSelectView.strokeColor = strokeColor;
    }
    
    BOOL top = CGRectGetMinY(self.toolView.frame) + CGRectGetHeight(self.toolView.frame) / 2.0 < CGRectGetHeight(self.view.bounds) / 2.0;
    BOOL left = CGRectGetMinX(self.toolView.frame) + CGRectGetWidth(self.toolView.frame) / 2.0 < CGRectGetWidth(self.view.bounds) / 2.0;
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    [selectView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        if (iPhone) {
            if (left) {
                make.left.equalTo(self.toolView.bjl_right).offset(1.0).priorityHigh();
                make.top.equalTo(button).offset(-50.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view).priorityHigh();
            }
            else {
                make.right.equalTo(self.toolView.bjl_left).offset(-1.0).priorityHigh();
                make.top.equalTo(button).offset(-50.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view).priorityHigh();
            }
        }
        else {
            if (top) {
                make.top.equalTo(button.bjl_bottom).offset(1.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
            }
            else {
                make.bottom.equalTo(button.bjl_top).offset(-1.0).priorityHigh();
                make.top.greaterThanOrEqualTo(self.view);
            }
            make.centerX.equalTo(button).priorityHigh();

        }
        
        make.top.left.greaterThanOrEqualTo(self.view);
        make.bottom.right.lessThanOrEqualTo(self.view);
        make.size.equal.sizeOffset(expectedSize);
    }];
    
    [self.strokeColorSelectView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        if (selectView == self.textOptionView) {
            make.top.equalTo(selectView.bjl_top).offset(self.textOptionView.textOptionSize.height);
        }
        else {
            make.top.equalTo(selectView.bjl_bottom);
        }
        if (!iPhone && !top) {
            make.bottom.equalTo(button.bjl_top).offset(-1.0);
        }
        make.left.right.equalTo(selectView);
        make.height.equalTo(self.strokeColorSelectView.bjl_width);
        make.top.left.greaterThanOrEqualTo(self.view);
        make.right.bottom.lessThanOrEqualTo(self.view);
    }];
    [self.strokeColorSelectView reloadLayout];
    
    if (selectView == self.markStrokeWidthSelectView) {
        [self.markStrokeWidthSelectView reloadLayout];
    }
    else if (selectView == self.strokeWidthSelectView) {
        [self.strokeWidthSelectView reloadLayout];
    }
    else if (selectView == self.shapeSelectView) {
        [self.shapeSelectView reloadLayout];
    }
}

#pragma mark - Observing

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, strokeColor)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        NSString *strokeColor = self.room.drawingVM.strokeColor;
        UIColor *color = [UIColor bjl_colorWithHexString:strokeColor];
        if (self.strokeColorSelectView.hidden) {
            self.toolView.paintStrokeColor = self.toolView.markStrokeColor = self.toolView.shapeStrokeColor = self.toolView.textStrokeColor = strokeColor;
            self.toolView.paintStrokeColorView.backgroundColor = self.toolView.markStrokeColorView.backgroundColor = self.toolView.shapeStrokeColorView.backgroundColor = self.toolView.textStrokeColorView.backgroundColor = color;
        }
        else if (!self.strokeWidthSelectView.hidden) {
            self.toolView.paintStrokeColor = strokeColor;
            self.toolView.paintStrokeColorView.backgroundColor = color;
        }
        else if (!self.markStrokeWidthSelectView.hidden) {
            self.toolView.markStrokeColor = strokeColor;
            self.toolView.markStrokeColorView.backgroundColor = color;
        }
        else if (!self.shapeSelectView.hidden) {
            self.toolView.shapeStrokeColor = strokeColor;
            self.toolView.shapeStrokeColorView.backgroundColor = color;
        }
        else if (!self.textOptionView.hidden) {
            self.toolView.textStrokeColor = strokeColor;
            self.toolView.textStrokeColorView.backgroundColor = color;
        }
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, drawingShapeType)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        BJLDrawingShapeType type = now.integerValue;
        switch (type) {
            case BJLDrawingShapeType_segment:
            case BJLDrawingShapeType_arrow:
            case BJLDrawingShapeType_doubleSideArrow:
            case BJLDrawingShapeType_triangle:
            case BJLDrawingShapeType_rectangle:
            case BJLDrawingShapeType_oval:
            case BJLDrawingShapeType_image:
                return YES;
                
            default:
                return NO;
        }
    } observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        NSString *shapeKey = [self.shapeSelectView shapeOptionKeyWithType:self.room.drawingVM.drawingShapeType filled:!!self.room.drawingVM.fillColor];
        self.toolView.currentToolboxShape = self.room.drawingVM.drawingShapeType;
        [self.toolView updateToolboxShape:shapeKey];
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.toolView, expectedHidden)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        self.expectedHidden = self.toolView.expectedHidden;
        return YES;
    }];
    
    if (self.room.slideshowViewController) {
        [self bjl_kvo:BJLMakeProperty(self.room.slideshowViewController, imageFrameInPPTView)
             observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            if (!self.laserPointView.superview || self.laserPointView.superview != self.room.slideshowViewController.view) {
                [self.room.slideshowViewController.view addSubview:self.laserPointView];
            }
            CGRect imageFrame = self.room.slideshowViewController.imageFrameInPPTView;
            [self.laserPointView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.left.equalTo(self.room.slideshowViewController.view).offset(imageFrame.origin.x);
                make.top.equalTo(self.room.slideshowViewController.view).offset(imageFrame.origin.y);
                make.size.equal.sizeOffset(imageFrame.size).priorityHigh();
            }];
  
            [self.laserPointView updateShapeShowSize:imageFrame.size];
            return YES;
        }];
    }
}

#pragma mark - unitily

- (void)hideSelectViewAndOptionView {
    self.selectViewHidden = YES;
    self.strokeWidthSelectView.hidden = YES;
    [self.strokeWidthSelectView removeFromSuperview];
    self.strokeColorSelectView.hidden = YES;
    [self.strokeColorSelectView removeFromSuperview];
    self.markStrokeWidthSelectView.hidden = YES;
    [self.markStrokeWidthSelectView removeFromSuperview];
    self.shapeSelectView.hidden = YES;
    [self.shapeSelectView removeFromSuperview];
    self.textOptionView.hidden = YES;
    [self.textOptionView removeFromSuperview];
}

- (void)setupGesture {
    __block CGPoint originOffsetPoint = CGPointZero;
    __block CGPoint movingTranslation = CGPointZero;
    __block CGFloat originHeight = 0;
    bjl_weakify(self);
    UIPanGestureRecognizer *panGesture = [UIPanGestureRecognizer bjl_gestureWithHandler:^(__kindof UIPanGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        UIView *gestureView = gesture.view;
        if (gesture.state == UIGestureRecognizerStateBegan) {
            [gesture setTranslation:CGPointZero inView:self.view];
            originHeight = gestureView.frame.size.height;
            originOffsetPoint = CGPointMake(gestureView.frame.origin.x, gestureView.frame.origin.y);
        }
        else if (gesture.state == UIGestureRecognizerStateChanged) {
            self.hasMoved = YES;
            if (!self.selectViewHidden) {
                [self hideSelectViewAndOptionView];
            }
            CGFloat originWidth = gestureView.frame.size.width;
            movingTranslation = [gesture translationInView:self.view];
            CGFloat offsetX = MAX(0, MIN(originOffsetPoint.x + movingTranslation.x, self.view.frame.size.width - originWidth));
            CGFloat offsetY = MAX(0, MIN(originOffsetPoint.y + movingTranslation.y, self.view.frame.size.height - originHeight));
            
            [gestureView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.left.equalTo(self.view).offset(offsetX);
                make.top.equalTo(self.view).offset(offsetY);
                make.width.equalTo(@(originWidth));
                make.height.equalTo(@(originHeight));
            }];
        }
    }];
    [self.toolView addGestureRecognizer:panGesture];
}

@end
