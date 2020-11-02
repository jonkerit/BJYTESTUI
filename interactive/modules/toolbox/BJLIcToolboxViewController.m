//
//  BJLIcToolboxViewController.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/25.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcToolboxViewController.h"
#import "BJLIcToolboxViewController+private.h"
#import "BJLIcToolboxViewController+padUserVideoUpside.h"
#import "BJLIcToolboxViewController+phoneUserVideoUpside.h"
#import "BJLIcToolboxViewController+phone1to1.h"
#import "BJLIcToolboxViewController+pad1to1.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcToolboxViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
        self.doodleStrokeWidth = room.drawingVM.doodleStrokeWidth;
        self.markStrokeWidth = 8.0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    bjl_weakify(self);
    self.view = [BJLHitTestView viewWithTitTestBlock:^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
        bjl_strongify(self);
        if ([hitView isKindOfClass:[UIButton class]]
            || [hitView isKindOfClass:[UICollectionView class]]
            || [hitView isKindOfClass:[UITableView class]]
            || (hitView == self.gestureView)) {
            return hitView;
        }
        if (!self.selectViewHidden) {
            [self hideSelectViews];
            return hitView;
        }
        if (self.hideSelectViewsCallback) {
            self.hideSelectViewsCallback();
        }

        return nil;
    }];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    self.view.backgroundColor = [UIColor clearColor];
    self.selectViewHidden = YES;
    self.currentToolboxShape = BJLDrawingShapeType_segment;
    
    [self makeToolboxView];
    [self makeObserving];
    [self cancelCurrentSelectedButton];
}

- (void)didMoveToParentViewController:(nullable UIViewController *)parent {
    // 布局和父视图有关，因此不能在 viewdidload 中布局，需要在此方法中布局，而此方法会调用多次，需要使用 remake 来正确布局
    [super didMoveToParentViewController:parent];
    if (parent) {
        if (self.room.loginUser.isStudent) {
            [self clearToolbox];
            [self remakeToolboxConstraintsForStudent];
            [self remakeSelectViewsAndConstraints];
            [self updateStrokeColorSelectViewHidden];
        }
        else if (self.room.loginUser.isTeacherOrAssistant) {
            [self clearToolbox];
            if (BJLIcToolboxLayoutFullScreen == self.type) {
                [self remakeToolboxConstraintsForStudent];
            }
            else {
                [self remakeToolboxConstraintsForTeacherOrAssistant];
            }
            [self remakeSelectViewsAndConstraints];
            [self updateStrokeColorSelectViewHidden];
        }
        else {
            [self clearToolbox];
        }
    }
}

- (void)makeToolboxView {
    self.containerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = BJLIcTheme.toolboxBackgroundColor;
        view.layer.cornerRadius = BJLIcAppearance.toolboxCornerRadius;
        view.layer.borderWidth = 1.0;
        view.layer.borderColor = [UIColor bjl_colorWithHex:0XDDDDDD alpha:0.1].CGColor;
        view.layer.shadowRadius = 5.0;
        view.layer.shadowColor = BJLIcTheme.windowShadowColor.CGColor;
        view.layer.shadowOffset = CGSizeMake(0, 0);
        view.layer.shadowOpacity = 1;
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view;
    });
    
    self.gestureView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, gestureView);
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    
    self.referenceViewForPhone = ({
        UIView *view = [UIView new];
        view.userInteractionEnabled = NO;
        view.accessibilityLabel = BJLKeypath(self, referenceViewForPhone);
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    
    self.PPTButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_ppt_normal"]
                                 selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_ppt_selected"]
                                    needAction:YES accessibilityLabel:BJLKeypath(self, PPTButton)];
    
    self.selectButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_select_normal"]
                                    selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_select_selected"]
                                       needAction:YES accessibilityLabel:BJLKeypath(self, selectButton)];
    
    self.paintBrushButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_paintbrush_normal"]
                                        selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_paintbrush_selected"]
                                           needAction:YES accessibilityLabel:BJLKeypath(self, paintBrushButton)];
    self.paintStrokeColorView = [self makeStrokeColorView:BJLKeypath(self, paintStrokeColorView)];
    
    self.markPenButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_marker_normal"]
                                     selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_marker_selected"]
                                        needAction:YES accessibilityLabel:BJLKeypath(self, markPenButton)];
    self.markStrokeColorView = [self makeStrokeColorView:BJLKeypath(self, markStrokeColorView)];
    
    self.shapeButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_draw_shape_segment_normal"]
                                   selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_draw_shape_segment_selected"]
                                      needAction:YES  accessibilityLabel:BJLKeypath(self, shapeButton)];
    self.shapeStrokeColorView = [self makeStrokeColorView:BJLKeypath(self, shapeStrokeColorView)];
    
    self.laserPointerButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_laserpointer_normal"]
                                          selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_laserpointer_selected"]
                                             needAction:YES accessibilityLabel:BJLKeypath(self, laserPointerButton)];
    
    self.textButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_text_normal"]
                                  selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_text_selected"]
                                     needAction:YES accessibilityLabel:BJLKeypath(self, textButton)];
    self.textStrokeColorView = [self makeStrokeColorView:BJLKeypath(self, textStrokeColorView)];
    
    self.eraserButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_eraser_normal"]
                                    selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_eraser_selected"]
                                       needAction:YES accessibilityLabel:BJLKeypath(self, eraserButton)];
    
    self.pptSingleLine = [UIView bjlic_createSeparateLine];
    self.singleLine = [UIView bjlic_createSeparateLine];
    
    self.coursewareButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_courseware_normal"]
                                        selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_courseware_selected"]
                                           needAction:YES accessibilityLabel:BJLKeypath(self, coursewareButton)];

    self.teachingAidButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_teachingaid_normal"]
                                         selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_teachingaid_selected"]
                                            needAction:YES accessibilityLabel:BJLKeypath(self, teachingAidButton)];

    self.groupButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_group_normal"]
                                   selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_group_selected"]
                                      needAction:NO accessibilityLabel:BJLKeypath(self, groupButton)];
    
    // 线宽选择
    self.strokeWidthSelectView = ({
        BJLIcDrawStrokeWidthSelectView *view = [[BJLIcDrawStrokeWidthSelectView alloc] initWithRoom:self.room];
        view.hidden = YES;
        bjl_return view;
    });
    
    // 马克笔线宽选择
    self.markStrokeWidthSelectView = ({
        BJLIcDrawMarkStrokeWidthSelectView *view = [[BJLIcDrawMarkStrokeWidthSelectView alloc] initWithRoom:self.room];
        view.hidden = YES;
        bjl_return view;
    });
    
    // 图形选择
    self.shapeSelectView = ({
        BJLIcDrawShapeSelectView *view = [[BJLIcDrawShapeSelectView alloc] initWithRoom:self.room];
        view.hidden = YES;
        bjl_return view;
    });
    
    // 颜色选择
    self.strokeColorSelectView = ({
        BJLIcDrawStrokeColorSelectView *view = [[BJLIcDrawStrokeColorSelectView alloc] initWithRoom:self.room];
        view.hidden = YES;
        bjl_return view;
    });
    
    // 字体选择
    self.textOptionView = ({
        BJLIcDrawTextOptionView *view = [[BJLIcDrawTextOptionView alloc] initWithRoom:self.room];
        view.hidden = YES;
        bjl_return view;
    });
    
    // 老师教具
    self.teachingAidSelectView = ({
        BJLIcTeachingAidSelectView *view = [[BJLIcTeachingAidSelectView alloc] initWithRoom:self.room];
        view.hidden = YES;
        bjl_weakify(self)
        view.clickWritingBoardCallback = ^(void) {
            bjl_strongify(self);
            [self hideSelectViews];
            if (self.clickWritingBoardCallback) {
                self.clickWritingBoardCallback();
            }
        };
    
        view.questionResponderCallback = ^(void) {
            bjl_strongify(self);
            [self hideSelectViews];
            if (self.questionResponderCallback) {
                self.questionResponderCallback();
            }
        };

        view.questionAnswerCallback = ^(void) {
            bjl_strongify(self);
            [self hideSelectViews];
            if (self.questionAnswerCallback) {
                self.questionAnswerCallback();
            }
        };

        view.countDownCallback = ^(void) {
            bjl_strongify(self);
            [self hideSelectViews];
            if (self.countDownCallback) {
                self.countDownCallback();
            }
        };

        view.openWebViewCallback = ^(void) {
            bjl_strongify(self);
            [self hideSelectViews];
            if (self.openWebViewCallback) {
                self.openWebViewCallback();
            }
        };
        bjl_return view;
    });
}

#pragma mark - gesture

- (void)setupGesture {
    bjl_weakify(self);
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    __block CGPoint originOffsetPoint = CGPointZero;
    __block CGPoint movingTranslation = CGPointZero;
    __block CGFloat originHeight = 0;
    __block BOOL left = NO;
    UIPanGestureRecognizer *panGesture = [UIPanGestureRecognizer bjl_gestureWithHandler:^(__kindof UIPanGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        UIView *gestureView = gesture.view;
        if (gesture.state == UIGestureRecognizerStateBegan) {
            [gesture setTranslation:CGPointZero inView:self.view];
            originHeight = gestureView.frame.size.height;
            originOffsetPoint = CGPointMake(gestureView.frame.origin.x, gestureView.frame.origin.y);
        }
        else if (gesture.state == UIGestureRecognizerStateChanged) {
            if (!self.selectViewHidden) {
                [self hideSelectViews];
            }
            CGFloat toolboxWidth = self.containerView.bounds.size.width;
            movingTranslation = [gesture translationInView:self.view];
            CGFloat offsetX = MAX(0, MIN(originOffsetPoint.x + movingTranslation.x, self.view.frame.size.width - toolboxWidth));
            CGFloat offsetY = MAX(0, MIN(originOffsetPoint.y + movingTranslation.y, self.view.frame.size.height - originHeight));
           
            [gestureView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.left.equalTo(self.view).offset(offsetX);
                make.top.equalTo(self.view).offset(offsetY);
                make.width.equalTo(@(toolboxWidth));
                make.height.equalTo(@(originHeight));
            }];
            [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(gestureView);
            }];
            if (BJLIcTemplateType_1v1 != self.room.roomInfo.interactiveClassTemplateType
                || (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType && iPhone)) {
                if (offsetX < self.view.frame.size.width / 2 && left) {
                    left = NO;
                    [self remakeSelectViewsAndConstraintsWithPosition:BJLIcRectPosition_right];
                }
                else if (offsetX > self.view.frame.size.width / 2 && !left) {
                    left = YES;
                    [self remakeSelectViewsAndConstraintsWithPosition:BJLIcRectPosition_left];
                }
            }
        }
    }];

    UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UITapGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        CGPoint point = [gesture locationInView:self.view];
        for (NSObject *object in [self toolboxArray]) {
            if ([object isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)object;
                if (button.isHidden || !button.superview) {
                    continue;
                }
                if(CGRectContainsPoint(button.frame, point)) {
                    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
                }
            }
        }
    }];
    [tapGesture requireGestureRecognizerToFail:panGesture];
    [self.gestureView addGestureRecognizer:tapGesture];
    [self.gestureView addGestureRecognizer:panGesture];
}

#pragma mark - update

- (void)remakeToolboxConstraintsWithLayoutType:(BJLIcToolboxLayoutType)type {
    self.type = type;
    switch (self.type) {
            // 全屏状态或者最大化状态，改变工具栏布局
        case BJLIcToolboxLayoutFullScreen:
        case BJLIcToolboxLayoutMaximized: {
            // 只有老师才会切换，学生的工具栏的样式是不变的
            if (!self.room.loginUser.isStudent) {
                // 清理工具盒
                [self clearToolbox];
                self.singleLine.hidden = (BJLIcToolboxLayoutMaximized != self.type);
                if (self.currentSelectedButton == self.laserPointerButton) {
                    [self cancelCurrentSelectedButton];
                }
                if (BJLIcToolboxLayoutMaximized == self.type) {
                    [self remakeToolboxConstraintsForTeacherOrAssistant];
                }
                else {
                    [self remakeToolboxConstraintsForStudent];
                }
                [self remakeSelectViewsAndConstraints];
                [self updateStrokeColorSelectViewHidden];
            }
            break;
        }
            // 恢复布局
        case BJLIcToolboxLayoutNormal: {
            if (!self.room.loginUser.isStudent) {
                [self clearToolbox];
                self.singleLine.hidden = NO;
                [self remakeToolboxConstraintsForTeacherOrAssistant];
            }
            else {
                [self clearToolbox];
                self.singleLine.hidden = YES;
                [self remakeToolboxConstraintsForStudent];
            }
            [self remakeSelectViewsAndConstraints];
            [self updateStrokeColorSelectViewHidden];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - teacher style

- (void)remakeToolboxConstraintsForTeacherOrAssistant {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        if (iPhone) {
            [self remakePhone1to1ContainerViewForTeacherOrAssistant];
        }
        else {
            [self remakePad1to1ContainerViewForTeacherOrAssistant];
        }
    }
    else {
        if (iPhone) {
            [self remakePhoneUserVideoUpsideContainerViewForTeacherOrAssistant];
        }
        else {
            [self remakePadUserVideoUpsideContainerViewForTeacherOrAssistant];
        }
    }
}

- (NSArray *)teacherButtons {
    return @[
             self.PPTButton,
             self.selectButton,
             self.paintBrushButton,
             self.markPenButton,
             self.shapeButton,
             self.textButton,
             self.laserPointerButton,
             self.eraserButton,
             self.coursewareButton,
             self.teachingAidButton
             /*self.groupButton*/];
}

- (NSArray *)assistantButtons {
    return @[
             self.PPTButton,
             self.selectButton,
             self.paintBrushButton,
             self.markPenButton,
             self.shapeButton,
             self.textButton,
             self.laserPointerButton,
             self.eraserButton,
             self.coursewareButton
             /*self.teachingAidButton,
              self.groupButton*/];
}

- (NSArray *)optionButtons {
    if (self.room.loginUser.isTeacher) {
        return @[self.coursewareButton,
                 self.teachingAidButton
                  /*self.groupButton*/];
    }
    else if (self.room.loginUser.isAssistant) {
        return @[self.coursewareButton
                 /*self.teachingAidButton,
                  self.groupButton*/];
    }
    else {
        return @[];
    }
}

#pragma mark - student style

- (void)remakeToolboxConstraintsForStudent {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        if (iPhone) {
            [self remakePhone1to1ContainerViewForStudent];
        }
        else {
            [self remakePad1to1ContainerViewForStudent];
        }
    }
    else {
        if (iPhone) {
            [self remakePhoneUserVideoUpsideContainerViewForStudent];
        }
        else {
            [self remakePadUserVideoUpsideContainerViewForStudent];
        }
    }
}

- (NSArray *)studentButtons {
    NSMutableArray *array = [NSMutableArray new];
    if (self.room.loginUser.isStudent) {
        if (self.room.documentVM.authorizedPPT) {
            [array addObjectsFromArray:[self studentPPTButtons]];
        }
        if (self.room.drawingVM.drawingGranted || self.room.drawingVM.writingBoardEnabled) {
            [array addObjectsFromArray:[self studentDrawingButtons]];
        }
    }
    else if (self.room.loginUser.isTeacherOrAssistant) {
        [array addObjectsFromArray:[self studentPPTButtons]];
        [array addObjectsFromArray:[self studentDrawingButtons]];
    }
    return array;
}

- (NSArray *)studentDrawingButtons {
    return @[
             self.selectButton,
             self.paintBrushButton,
             self.markPenButton,
             self.shapeButton,
             self.textButton,
             self.eraserButton];
}

- (NSArray *)studentPPTButtons {
    return @[self.PPTButton];
}

#pragma mark - clear

// 这里只用需要在 remake 时移除的视图
- (NSArray *)toolboxArray {
    NSArray *toolboxArray = @[ self.referenceViewForPhone ?: [NSNull null],
                               self.containerView ?: [NSNull null],
                               self.gestureView ?: [NSNull null],
                               self.PPTButton ?: [NSNull null],
                               self.selectButton ?: [NSNull null],
                               self.paintBrushButton ?: [NSNull null],
                               self.paintStrokeColorView ?: [NSNull null],
                               self.markPenButton ?: [NSNull null],
                               self.markStrokeColorView ?: [NSNull null],
                               self.shapeButton ?: [NSNull null],
                               self.shapeStrokeColorView ?: [NSNull null],
                               self.textButton ?: [NSNull null],
                               self.laserPointerButton ?: [NSNull null],
                               self.textStrokeColorView ?: [NSNull null],
                               self.eraserButton ?: [NSNull null],
                               self.coursewareButton ?: [NSNull null],
                               self.pptSingleLine ?: [NSNull null],
                               self.singleLine ?: [NSNull null],
                               self.teachingAidButton ?: [NSNull null],
                               self.strokeWidthSelectView ?: [NSNull null],
                               self.markStrokeWidthSelectView ?: [NSNull null],
                               self.shapeSelectView ?: [NSNull null],
                               self.shapeSelectView ?: [NSNull null],
                               self.strokeColorSelectView ?: [NSNull null],
                               self.teachingAidSelectView ?: [NSNull null]];
    return toolboxArray;
}

/** 所有在remake中的视图，都需要在此清空 */
- (void)clearToolbox {
    for (UIView *view in [self toolboxArray]) {
        if ([view respondsToSelector:@selector(removeFromSuperview)]) {
            [view removeFromSuperview];
        }
    }
}

#pragma mark - select

- (void)remakeSelectViewsAndConstraints {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        if (iPhone) {
            [self remakeSelectViewsAndConstraintsWithPosition:BJLIcRectPosition_left];
        }
        else {
            [self remakeSelectViewsAndConstraintsWithPosition:BJLIcRectPosition_top];
        }
    }
    else {
        [self remakeSelectViewsAndConstraintsWithPosition:BJLIcRectPosition_left];
    }
}

#pragma mark - observers

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, strokeColor)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        NSString *strokeColor = self.room.drawingVM.strokeColor;
        UIColor *color = [UIColor bjl_colorWithHexString:strokeColor];
        if (self.strokeColorSelectView.hidden) {
            self.paintStrokeColor = self.markStrokeColor = self.shapeStrokeColor = self.textStrokeColor = strokeColor;
            self.paintStrokeColorView.backgroundColor = self.markStrokeColorView.backgroundColor = self.shapeStrokeColorView.backgroundColor = self.textStrokeColorView.backgroundColor = color;
        }
        else if (!self.strokeWidthSelectView.hidden) {
            self.paintStrokeColor = strokeColor;
            self.paintStrokeColorView.backgroundColor = color;
        }
        else if (!self.markStrokeWidthSelectView.hidden) {
            self.markStrokeColor = strokeColor;
            self.markStrokeColorView.backgroundColor = color;
        }
        else if (!self.shapeSelectView.hidden) {
            self.shapeStrokeColor = strokeColor;
            self.shapeStrokeColorView.backgroundColor = color;
        }
        else if (!self.textOptionView.hidden) {
            self.textStrokeColor = strokeColor;
            self.textStrokeColorView.backgroundColor = color;
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
    }
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateToolboxShape];
        return YES;
    }];
    
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
        UIImage *image = self.room.drawingVM.hasSelectedShape ? [UIImage bjlic_imageNamed:@"bjl_toolbox_delete_normal"] : [UIImage bjlic_imageNamed:@"bjl_toolbox_eraser_normal"];
        UIImage *selectedImage = self.room.drawingVM.hasSelectedShape ? [UIImage bjlic_imageNamed:@"bjl_toolbox_delete_selected"] : [UIImage bjlic_imageNamed:@"bjl_toolbox_eraser_selected"];
        [self.eraserButton bjl_setImage:image forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
        [self.eraserButton bjl_setImage:selectedImage forState:UIControlStateSelected optionalStates:UIControlStateHighlighted];
        return YES;
    }];
}

#pragma mark - update toolbox shape

- (void)updateToolboxShape {
    self.currentToolboxShape = self.room.drawingVM.drawingShapeType;
    NSString *shapeKey = [self.shapeSelectView shapeOptionKeyWithType:self.currentToolboxShape filled:!!self.room.drawingVM.fillColor];
    UIImage *image = [UIImage bjlic_imageNamed:[NSString stringWithFormat:@"bjl_toolbox_%@_normal", shapeKey]];
    UIImage *selectedImage = [UIImage bjlic_imageNamed:[NSString stringWithFormat:@"bjl_toolbox_%@_selected", shapeKey]];
    [self.shapeButton bjl_setImage:image forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
    [self.shapeButton bjl_setImage:selectedImage forState:UIControlStateSelected optionalStates:UIControlStateHighlighted];
}

#pragma mark - actions

- (void)cancelCurrentSelectedButton {
    self.currentSelectedButton.selected = NO;
    self.currentSelectedButton = nil;
    [self hideSelectViews];
    [self updateSelectViewHidden];
}

- (void)didSelectButton:(UIButton *)button {
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
    
    // 画笔开关: TODO: coding style
    BOOL drawingEnabled = (self.selectButton.selected
                           || self.paintBrushButton.selected
                           || self.markPenButton.selected
                           || self.shapeButton.selected
                           || self.textButton.selected
                           || self.laserPointerButton.selected
                           || self.eraserButton.selected);
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
    drawingEnabled = self.room.drawingVM.drawingEnabled || self.room.drawingVM.writingBoardEnabled;
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
    
    // 线宽选择
    self.strokeWidthSelectView.hidden = !self.paintBrushButton.selected;
    
    // 马克笔线宽选择
    self.markStrokeWidthSelectView.hidden = !self.markPenButton.selected;
    
    // 图形选择
    self.shapeSelectView.hidden = !self.shapeButton.selected;
    
    // 隐藏颜色选择
//    self.strokeColorSelectView.hidden = YES;
    
    // 文字画笔
    self.textOptionView.hidden = !self.textButton.selected;
    
    // 老师教具
    self.teachingAidSelectView.hidden = !self.teachingAidButton.selected;
    
    [self updateSelectViewHidden];
    [self updateStrokeColorSelectViewHidden];
    
    // 特别的，橡皮擦删除了框选画笔之后，重置为选择按钮
    if (self.currentSelectedButton == self.eraserButton
        && enableSelectButton) {
        [self.selectButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)updateSelectViewHidden {
    if (!self.strokeWidthSelectView.hidden ||
        !self.markStrokeWidthSelectView.hidden ||
        !self.shapeSelectView.hidden ||
        !self.teachingAidSelectView.hidden ||
        !self.textOptionView.hidden) {
        self.selectViewHidden = NO;
    }
    else {
        self.selectViewHidden = YES;
    }
}

- (void)hideSelectViews {
    self.selectViewHidden = YES;
    self.shapeSelectView.hidden = YES;
    self.strokeWidthSelectView.hidden = YES;
    self.markStrokeWidthSelectView.hidden = YES;
    self.textOptionView.hidden = YES;
    self.teachingAidSelectView.hidden = YES;
    [self updateStrokeColorSelectViewHidden];
    
    if (self.teachingAidButton.isSelected) {
        self.teachingAidButton.selected = NO;
    }
    
    if (self.hideSelectViewsCallback) {
        self.hideSelectViewsCallback();
    }
}

- (void)updateStrokeColorSelectViewHidden {
    UIView *view = nil;
    NSString *strokeColor = nil;
    if (!self.strokeWidthSelectView.hidden) {
        view = self.strokeWidthSelectView;
        strokeColor = self.paintStrokeColor;
    }
    else if (!self.markStrokeWidthSelectView.hidden) {
        view = self.markStrokeWidthSelectView;
        strokeColor = self.markStrokeColor;
    }
    else if (!self.shapeSelectView.hidden) {
        view = self.shapeSelectView;
        strokeColor = self.shapeStrokeColor;
    }
    else if (!self.textOptionView.hidden) {
        view = self.textOptionView;
        strokeColor = self.textStrokeColor;
    }
    // 由于存在取消授权后，没有重置视图的 hidden 属性，因此
    self.strokeColorSelectView.hidden = !view || !view.superview || !strokeColor;
    if (self.strokeColorSelectView.hidden) {
        return;
    }
    if (strokeColor) {
        self.strokeColorSelectView.strokeColor = strokeColor;
    }
    [self.strokeColorSelectView removeFromSuperview];
    if (view && view.superview == self.view) {
        [self.view insertSubview:self.strokeColorSelectView belowSubview:view];
    }
    [self.strokeColorSelectView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        switch (self.toolboxPosition) {
            case BJLIcRectPosition_top:
            {
                if (view == self.textOptionView) {
                    make.top.equalTo(view.bjl_top).offset(self.textOptionView.textOptionSize.height);
                }
                else {
                    make.top.equalTo(view.bjl_bottom);
                }
                make.bottom.equalTo(self.containerView.bjl_top).offset(-1.0);
            }
                break;
                
            case BJLIcRectPosition_bottom:
            case BJLIcRectPosition_left:
            case BJLIcRectPosition_right:
            {
                if (view == self.textOptionView) {
                    make.top.equalTo(view.bjl_top).offset(self.textOptionView.textOptionSize.height);
                }
                else {
                    make.top.equalTo(view.bjl_bottom);
                }
                make.bottom.lessThanOrEqualTo(self.view);
            }
                break;
                
            default:
                break;
        }
        make.left.right.equalTo(view);
        make.height.equalTo(self.strokeColorSelectView.bjl_width);
        make.top.left.greaterThanOrEqualTo(self.view);
        make.right.lessThanOrEqualTo(self.view);
    }];
    [self.strokeColorSelectView reloadLayout];
}

#pragma mark - subviews

// position 是相对于 toolbox 的位置
- (void)remakeSelectViewsAndConstraintsWithPosition:(BJLIcRectPosition)position {
    self.toolboxPosition = position;
    if (self.room.loginUser.isStudent && !self.room.drawingVM.drawingGranted && !self.room.drawingVM.writingBoardEnabled) {
        return;
    }
    // 由于存在工具盒被拖动后重新布局的问题，所以这里可能不需要重新 add
    if (self.strokeColorSelectView.superview != self.view) {
        [self.view addSubview:self.strokeWidthSelectView];
    }
    [self.strokeWidthSelectView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        switch (position) {
            case BJLIcRectPosition_top:
                make.bottom.equalTo(self.paintBrushButton.bjl_top).offset(-1.0).priorityHigh();
                make.top.greaterThanOrEqualTo(self.view);
                make.centerX.equalTo(self.paintBrushButton).priorityHigh();
                break;

            case BJLIcRectPosition_bottom:
                make.top.equalTo(self.paintBrushButton.bjl_bottom).offset(1.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
                make.centerX.equalTo(self.paintBrushButton).priorityHigh();
                break;

            case BJLIcRectPosition_left:
                make.right.equalTo(self.containerView.bjl_left).offset(-1.0).priorityHigh();
                make.top.equalTo(self.paintBrushButton).offset(-15.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
                break;

            case BJLIcRectPosition_right:
                make.left.equalTo(self.containerView.bjl_right).offset(1.0).priorityHigh();
                make.top.equalTo(self.paintBrushButton).offset(-15.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
                break;

            default:
                break;
        }
        make.top.left.greaterThanOrEqualTo(self.view);
        make.bottom.right.lessThanOrEqualTo(self.view);
        make.size.equal.sizeOffset(self.strokeWidthSelectView.expectedSize);
    }];
    
    if (self.markStrokeWidthSelectView.superview != self.view) {
        [self.view addSubview:self.markStrokeWidthSelectView];
    }
    [self.markStrokeWidthSelectView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        switch (position) {
            case BJLIcRectPosition_top:
                make.bottom.equalTo(self.markPenButton.bjl_top).offset(-1.0).priorityHigh();
                make.top.greaterThanOrEqualTo(self.view);
                make.centerX.equalTo(self.markPenButton).priorityHigh();
                break;
                
            case BJLIcRectPosition_bottom:
                make.top.equalTo(self.markPenButton.bjl_bottom).offset(1.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
                make.centerX.equalTo(self.markPenButton).priorityHigh();
                break;
                
            case BJLIcRectPosition_left:
                make.right.equalTo(self.containerView.bjl_left).offset(-1.0).priorityHigh();
                make.top.equalTo(self.markPenButton).offset(-15.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view).priorityHigh();
                break;
                
            case BJLIcRectPosition_right:
                make.left.equalTo(self.containerView.bjl_right).offset(1.0).priorityHigh();
                make.top.equalTo(self.markPenButton).offset(-15.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
                break;
                
            default:
                break;
        }
        make.top.left.greaterThanOrEqualTo(self.view);
        make.bottom.right.lessThanOrEqualTo(self.view);
        make.size.equal.sizeOffset(self.markStrokeWidthSelectView.expectedSize);
    }];
    
    if (self.shapeSelectView.superview != self.view) {
        [self.view addSubview:self.shapeSelectView];
    }
    [self.shapeSelectView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        switch (position) {
            case BJLIcRectPosition_top:
                make.bottom.equalTo(self.shapeButton.bjl_top).offset(-1.0).priorityHigh();
                make.top.greaterThanOrEqualTo(self.view);
                make.centerX.equalTo(self.shapeButton).priorityMedium();
                break;
                
            case BJLIcRectPosition_bottom:
                make.top.equalTo(self.shapeButton.bjl_bottom).offset(1.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
                make.centerX.equalTo(self.shapeButton).priorityMedium();
                break;
                
            case BJLIcRectPosition_left:
                make.right.equalTo(self.containerView.bjl_left).offset(-1.0).priorityHigh();
                make.top.equalTo(self.shapeButton).offset(-15.0).priorityMedium();
                make.bottom.lessThanOrEqualTo(self.view);
                break;
                
            case BJLIcRectPosition_right:
                make.left.equalTo(self.containerView.bjl_right).offset(1.0).priorityHigh();
                make.top.equalTo(self.shapeButton).offset(-15.0).priorityMedium();
                make.bottom.lessThanOrEqualTo(self.view);
                break;
                
            default:
                break;
        }
        make.top.left.greaterThanOrEqualTo(self.view);
        make.bottom.right.lessThanOrEqualTo(self.view);
        make.size.equal.sizeOffset(self.shapeSelectView.expectedSize);
    }];
    
    if (self.textOptionView.superview != self.view) {
        [self.view addSubview:self.textOptionView];
    }
    [self.textOptionView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        switch (position) {
            case BJLIcRectPosition_top:
                make.bottom.equalTo(self.textButton.bjl_top).offset(-1.0).priorityHigh();
                make.top.greaterThanOrEqualTo(self.view);
                make.centerX.equalTo(self.textButton.bjl_left).priorityHigh();
                break;
                
            case BJLIcRectPosition_bottom:
                make.top.equalTo(self.textButton.bjl_bottom).offset(1.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
                make.centerX.equalTo(self.textButton.bjl_left).priorityHigh();
                break;
                
            case BJLIcRectPosition_left:
                make.right.equalTo(self.containerView.bjl_left).offset(-1.0).priorityHigh();
                make.top.equalTo(self.textButton).offset(-15.0).priorityMedium();
                make.top.greaterThanOrEqualTo(self.view);
                make.bottom.lessThanOrEqualTo(self.view).priorityHigh();
                break;
                
            case BJLIcRectPosition_right:
                make.left.equalTo(self.containerView.bjl_right).offset(1.0).priorityHigh();
                make.top.equalTo(self.textButton).offset(-15.0).priorityMedium();
                make.top.greaterThanOrEqualTo(self.view);
                make.bottom.lessThanOrEqualTo(self.view).priorityHigh();
                break;
                
            default:
                break;
        }
        make.top.left.greaterThanOrEqualTo(self.view);
        make.bottom.right.lessThanOrEqualTo(self.view);
        make.size.equal.sizeOffset(self.textOptionView.expectedSize);
    }];
    
    // 手机端1V1老师的教具不在toolbox, 全屏状态没有教具按钮
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (!(BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType && iPhone) && self.teachingAidButton.superview) {
        CGFloat teachingAidOptionWidth = 50.0;
        CGFloat teachingAidOptionHeight = 54.0;
        CGSize teachingAidSelectViewSize = CGSizeMake(teachingAidOptionWidth * 3 + 8.0 * 4,
                                                      teachingAidOptionHeight * 2 + 12.0 + 10.0 * 2);
        
        if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
            teachingAidSelectViewSize = CGSizeMake(teachingAidOptionWidth * 2 + 8.0 * 3,
                                                   teachingAidOptionHeight * 1 + 10.0 * 2);
        }
        if (self.teachingAidSelectView.superview != self.view) {
            [self.view addSubview:self.teachingAidSelectView];
        }
        [self.teachingAidSelectView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            switch (position) {
                case BJLIcRectPosition_top:
                    make.bottom.equalTo(self.teachingAidButton.bjl_top).offset(-1.0).priorityHigh();
                    make.top.greaterThanOrEqualTo(self.view);
                    make.centerX.equalTo(self.teachingAidButton).priorityHigh();
                    break;
                    
                case BJLIcRectPosition_bottom:
                    make.top.equalTo(self.teachingAidButton.bjl_bottom).offset(1.0).priorityHigh();
                    make.bottom.lessThanOrEqualTo(self.view);
                    make.centerX.equalTo(self.teachingAidButton).priorityHigh();
                    break;
                    
                case BJLIcRectPosition_left:
                    make.right.equalTo(self.containerView.bjl_left).offset(-1.0).priorityHigh();
                    make.top.equalTo(self.teachingAidButton).offset(-30.0).priorityHigh();
                    make.bottom.lessThanOrEqualTo(self.view);
                    break;
                    
                case BJLIcRectPosition_right:
                    make.left.equalTo(self.containerView.bjl_right).offset(1.0).priorityHigh();
                    make.top.equalTo(self.teachingAidButton).offset(-30.0).priorityHigh();
                    make.bottom.lessThanOrEqualTo(self.view);
                    break;
                    
                default:
                    break;
            }
            make.top.left.greaterThanOrEqualTo(self.view);
            make.bottom.right.lessThanOrEqualTo(self.view);
            make.size.equal.sizeOffset(teachingAidSelectViewSize);
        }];
    }

    [self.textOptionView remarkConstraintsWithPosition:position];
}

#pragma mark - wheel

- (UIView *)makeStrokeColorView:(NSString *)accessibilityLabel {
    UIView *view = [UIView new];
    view.accessibilityLabel = accessibilityLabel;
    return view;
}

- (UIButton *)makeButtonWithImage:(nullable UIImage *)image
                    selectedImage:(nullable UIImage *)selectedImage
                       needAction:(BOOL)needAction
               accessibilityLabel:(NSString *)accessibilityLabel {
    // create custom button
    BJLIcImageButton *button = [BJLIcImageButton new];
    button.accessibilityLabel = accessibilityLabel;
    CGFloat inset = BJLIcAppearance.toolboxButtonImageInset;
    button.imageEdgeInsets = UIEdgeInsetsMake(inset, inset, inset, inset);
    button.selectedColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    button.backgroundSize = CGSizeMake(BJLIcAppearance.toolboxButtonSize, BJLIcAppearance.toolboxButtonSize);
    button.backgroundCornerRadius = BJLIcAppearance.toolboxCornerRadius;
    
    // 禁止同时点击
    button.exclusiveTouch = YES;
    
    // selected no tint color
    button.tintColor = [UIColor clearColor];
    if (needAction) {
        [button addTarget:self action:@selector(didSelectButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // use origin image
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    selectedImage = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    if (image) {
        [button bjl_setImage:image forState:UIControlStateNormal optionalStates:UIControlStateHighlighted];
    }
    if (selectedImage) {
        [button bjl_setImage:selectedImage forState:UIControlStateSelected optionalStates:UIControlStateHighlighted];
    }
    return button;
}

@end

NS_ASSUME_NONNULL_END
