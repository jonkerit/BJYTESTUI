//
//  BJLIcToolboxViewController+pad1to1.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/7/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolboxViewController+pad1to1.h"
#import "BJLIcToolboxViewController+private.h"

@implementation BJLIcToolboxViewController (pad1to1)

- (void)remakePad1to1ContainerViewForTeacherOrAssistant {
    [self.view addSubview:self.containerView];
    [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.equalTo(self.view).offset(-(BJLIcAppearance.toolboxButtonSize + BJLIcAppearance.toolboxButtonSpace));
        make.left.equalTo(self.view.bjl_left).offset(BJLIcAppearance.toolboxButtonSize + BJLIcAppearance.toolboxButtonSpace);
        make.height.equalTo(@(BJLIcAppearance.toolboxWidth));
    }];
    
    NSArray *buttons = self.room.loginUser.isTeacher ? [self teacherButtons] : [self assistantButtons];
    [self remakePad1to1ConstraintsWithButtons:buttons];
    [self remakePad1to1StrokeColorView];
    
    if ([buttons containsObject:self.PPTButton]
        && [buttons containsObject:self.selectButton]) {
        [self.view addSubview:self.pptSingleLine];
        [self.pptSingleLine bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.left.equalTo(self.PPTButton.bjl_right).offset(BJLIcAppearance.toolboxButtonSpace / 2.0);
            make.centerY.equalTo(self.containerView);
            make.width.equalTo(@1.0);
            make.height.equalTo(@(BJLIcAppearance.toolboxLineLength));
        }];
    }
    if ([buttons containsObject:self.eraserButton]
        && [buttons containsObject:self.coursewareButton]) {
        [self.view addSubview:self.singleLine];
        [self.singleLine bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.left.equalTo(self.eraserButton.bjl_right).offset(BJLIcAppearance.toolboxButtonSpace / 2.0);
            make.centerY.equalTo(self.containerView);
            make.width.equalTo(@1.0);
            make.height.equalTo(@(BJLIcAppearance.toolboxLineLength));
        }];
    }
}

- (void)remakePad1to1ContainerViewForStudent {
    if (!self.room.loginUser.isTeacherOrAssistant
        && !self.room.drawingVM.drawingGranted
        && !self.room.drawingVM.writingBoardEnabled
        && !self.room.documentVM.authorizedPPT) {
        return;
    }
    [self.view addSubview:self.containerView];
    [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.equalTo(self.view).offset(-(BJLIcAppearance.toolboxButtonSize + BJLIcAppearance.toolboxButtonSpace));
        make.centerX.equalTo(self.view);
        make.height.equalTo(@(BJLIcAppearance.toolboxWidth));
    }];
    
    NSArray *buttons = [self studentButtons];
    [self remakePad1to1ConstraintsWithButtons:buttons];
    [self remakePad1to1StrokeColorView];
    
    if ([buttons containsObject:self.PPTButton]
        && [buttons containsObject:self.selectButton]) {
        [self.view addSubview:self.pptSingleLine];
        [self.pptSingleLine bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.left.equalTo(self.PPTButton.bjl_right).offset(BJLIcAppearance.toolboxButtonSpace / 2.0);
            make.centerY.equalTo(self.containerView);
            make.width.equalTo(@1.0);
            make.height.equalTo(@(BJLIcAppearance.toolboxLineLength));
        }];
    }
}

- (void)remakePad1to1StrokeColorView {
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
            make.bottom.equalTo(self.containerView);
            make.height.equalTo(@(BJLIcAppearance.toolboxColorSize));
            make.centerX.equalTo(button);
            make.width.equalTo(@(BJLIcAppearance.toolboxColorLength));
        }];
    }
}

- (void)remakePad1to1ConstraintsWithButtons:(NSArray *)buttons {
    UIButton *lastButton = nil;
    for (UIButton *button in buttons) {
        [self.view addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.centerY.equalTo(self.containerView);
            // 上一个按钮为空, 则按钮大小可以为图片大小, 后续的按钮与第一个按钮大小保持一致
            if (lastButton) {
                make.width.height.equalTo(lastButton);
            }
            else {
                make.width.height.lessThanOrEqualTo(@(BJLIcAppearance.toolboxButtonSize));
                make.width.height.equalTo(@(BJLIcAppearance.toolboxButtonSize)).priorityHigh();
            }
            make.left.equalTo(lastButton.bjl_right ?: self.containerView.bjl_left).offset(BJLIcAppearance.toolboxButtonSpace);
            if (button == buttons.lastObject) {
                // 最后一个 button 右边约束
                make.right.equalTo(self.containerView).offset(-BJLIcAppearance.toolboxButtonSpace);
            }
        }];
        lastButton = button;
    }
}

@end
