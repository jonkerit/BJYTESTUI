//
//  BJLIcToolboxViewController+padUserVideoUpside.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolboxViewController+padUserVideoUpside.h"
#import "BJLIcToolboxViewController+private.h"

@implementation BJLIcToolboxViewController (padUserVideoUpside)

- (void)remakePadUserVideoUpsideContainerViewForTeacherOrAssistant {
    [self.view addSubview:self.containerView];
    [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.view);
        make.centerY.equalTo(self.view);
        make.height.lessThanOrEqualTo(self.view);
        make.width.equalTo(@(BJLIcAppearance.toolboxWidth));
    }];
    
    NSArray *buttons = self.room.loginUser.isTeacher ? [self teacherButtons] : [self assistantButtons];
    [self remakePadUserVideoUpsideConstraintsWithButtons:buttons];
    [self.view addSubview:self.gestureView];
    [self.gestureView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
    [self setupGesture];
    [self remakePadUserVideoUpsideStrokeColorView];
    
    if ([buttons containsObject:self.PPTButton]
        && [buttons containsObject:self.selectButton]) {
        [self.view addSubview:self.pptSingleLine];
        [self.pptSingleLine bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.top.equalTo(self.PPTButton.bjl_bottom).offset(BJLIcAppearance.toolboxButtonSpace / 2.0);
            make.centerX.equalTo(self.containerView);
            make.height.equalTo(@1.0);
            make.width.equalTo(@(BJLIcAppearance.toolboxLineLength));
        }];
    }
    if ([buttons containsObject:self.eraserButton]
        && [buttons containsObject:self.coursewareButton]) {
        [self.view addSubview:self.singleLine];
        [self.singleLine bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.top.equalTo(self.eraserButton.bjl_bottom).offset(BJLIcAppearance.toolboxButtonSpace / 2.0);
            make.centerX.equalTo(self.containerView);
            make.height.equalTo(@1.0);
            make.width.equalTo(@(BJLIcAppearance.toolboxLineLength));
        }];
    }
}

- (void)remakePadUserVideoUpsideContainerViewForStudent {
    if (!self.room.loginUser.isTeacherOrAssistant
        && !self.room.drawingVM.drawingGranted
        && !self.room.drawingVM.writingBoardEnabled
        && !self.room.documentVM.authorizedPPT) {
        return;
    }
    [self.view addSubview:self.containerView];
    [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.view);
        make.centerY.equalTo(self.view);
        make.height.lessThanOrEqualTo(self.view);
        make.width.equalTo(@(BJLIcAppearance.toolboxWidth));
    }];
    
    NSArray *buttons = [self studentButtons];
    [self remakePadUserVideoUpsideConstraintsWithButtons:buttons];
    
    [self.view addSubview:self.gestureView];
    [self.gestureView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
    [self setupGesture];
    [self remakePadUserVideoUpsideStrokeColorView];
    
    if ([buttons containsObject:self.PPTButton]
        && [buttons containsObject:self.selectButton]) {
        [self.view addSubview:self.pptSingleLine];
        [self.pptSingleLine bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.top.equalTo(self.PPTButton.bjl_bottom).offset(BJLIcAppearance.toolboxButtonSpace / 2.0);
            make.centerX.equalTo(self.containerView);
            make.height.equalTo(@1.0);
            make.width.equalTo(@(BJLIcAppearance.toolboxLineLength));
        }];
    }
}

- (void)remakePadUserVideoUpsideStrokeColorView {
    if (!self.room.loginUser.isTeacherOrAssistant
        && !self.room.drawingVM.drawingGranted
        && !self.room.drawingVM.writingBoardEnabled) {
        return;
    } 
    
    NSArray<UIView *> *buttons = @[self.paintBrushButton, self.markPenButton, self.shapeButton, self.textButton];
    NSArray<UIView *> *colorViews = @[self.paintStrokeColorView, self.markStrokeColorView, self.shapeStrokeColorView, self.textStrokeColorView];
    for (NSInteger i = 0; i < buttons.count; i++) {
        UIView *button = [buttons bjl_objectAtIndex:i];
        UIView *colorView = [colorViews bjl_objectAtIndex:i];
        [self.containerView addSubview:colorView];
        [colorView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.containerView);
            make.width.equalTo(@(BJLIcAppearance.toolboxColorSize));
            make.centerY.equalTo(button);
            make.height.equalTo(@(BJLIcAppearance.toolboxColorLength));
        }];
    }
}

- (void)remakePadUserVideoUpsideConstraintsWithButtons:(NSArray *)buttons {
    UIButton *lastButton = nil;
    for (UIButton *button in buttons) {
        [self.view addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.centerX.equalTo(self.containerView);
            // 上一个按钮为空, 则按钮大小可以为图片大小, 后续的按钮与第一个按钮大小保持一致
            if (lastButton) {
                make.width.height.equalTo(lastButton);
            }
            else {
                make.width.height.lessThanOrEqualTo(@(BJLIcAppearance.toolboxButtonSize));
                make.width.height.equalTo(@(BJLIcAppearance.toolboxButtonSize)).priorityHigh();
            }
            make.top.equalTo(lastButton.bjl_bottom ?: self.containerView.bjl_top).offset(BJLIcAppearance.toolboxButtonSpace);
            if (button == buttons.lastObject) {
                // 最后一个 button 底部约束
                make.bottom.equalTo(self.containerView).offset(-BJLIcAppearance.toolboxButtonSpace);
            }
        }];
        lastButton = button;
    }
}

@end
