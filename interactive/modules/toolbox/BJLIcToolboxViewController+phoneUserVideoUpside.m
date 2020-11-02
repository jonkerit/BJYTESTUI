//
//  BJLIcToolboxViewController+phoneUserVideoUpside.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolboxViewController+phoneUserVideoUpside.h"
#import "BJLIcToolboxViewController+private.h"

@implementation BJLIcToolboxViewController (phoneUserVideoUpside)

- (void)remakePhoneUserVideoUpsideContainerViewForTeacherOrAssistant {
    [self.view addSubview:self.containerView];
    // iphone 为 toolbar 留出空间，老师留出菜单按钮的空间
    [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.view).offset(BJLIcAppearance.userWindowDefaultBarHeight);
        make.right.equalTo(self.view).offset(-BJLIcAppearance.toolboxOffset);
        make.width.equalTo(@(BJLIcAppearance.toolboxWidth));
        make.bottom.lessThanOrEqualTo(self.view).offset(-(BJLIcAppearance.toolbarButtonWidth + BJLIcAppearance.toolbarSmallSpace * 2));
    }];
    
    NSArray *buttons = nil;
    if(self.room.loginUser.isTeacher) {
        buttons = [self teacherButtons];
    }
    else {
        buttons = [self assistantButtons];
    }
    
    [self remakePhoneUserVideoUpsideConstraintsWithButtons:buttons];

    [self.view addSubview:self.gestureView];
    [self.gestureView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
    [self setupGesture];
    [self remakePhoneUserVideoUpsideStrokeColorView];
    
    if ([buttons containsObject:self.PPTButton]
        && [buttons containsObject:self.selectButton]) {
        [self.view addSubview:self.pptSingleLine];
        [self.pptSingleLine bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.top.equalTo(self.PPTButton.bjl_bottom).offset((BJLIcAppearance.toolboxButtonSpace - 2 * BJLIcAppearance.toolboxButtonImageInset) / 2.0);
            make.centerX.equalTo(self.containerView);
            make.height.equalTo(@1.0);
            make.width.equalTo(@(BJLIcAppearance.toolboxLineLength));
        }];
    }
    if ([buttons containsObject:self.eraserButton]
        && [buttons containsObject:self.coursewareButton]) {
        [self.view addSubview:self.singleLine];
        [self.singleLine bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.top.equalTo(self.eraserButton.bjl_bottom).offset((BJLIcAppearance.toolboxButtonSpace - 2 * BJLIcAppearance.toolboxButtonImageInset) / 2.0);
            make.centerX.equalTo(self.containerView);
            make.height.equalTo(@1.0);
            make.width.equalTo(@(BJLIcAppearance.toolboxLineLength));
        }];
    }
}

- (void)remakePhoneUserVideoUpsideContainerViewForStudent {
    if (!self.room.loginUser.isTeacherOrAssistant
        && !self.room.drawingVM.drawingGranted
        && !self.room.drawingVM.writingBoardEnabled
        && !self.room.documentVM.authorizedPPT) {
        return;
    }
    NSArray *buttons = [self studentButtons];

    // iphone 为 toolbar 留出空间，学生留出举手按钮和菜单按钮的空间
    CGFloat offset = self.room.loginUser.isStudent ? -(BJLIcAppearance.toolbarButtonWidth + BJLIcAppearance.toolbarSmallSpace * 3 + BJLIcAppearance.speakRequestButtonWidth) : -(BJLIcAppearance.toolbarButtonWidth + BJLIcAppearance.toolbarSmallSpace * 2);
    [self.view addSubview:self.referenceViewForPhone];
    [self.referenceViewForPhone bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.view).offset(BJLIcAppearance.userWindowDefaultBarHeight);
        make.right.equalTo(self.view).offset(-BJLIcAppearance.toolboxOffset);
        make.width.equalTo(@(BJLIcAppearance.toolboxWidth));
        make.bottom.equalTo(self.view).offset(offset);
    }];
    
    [self.view addSubview:self.containerView];
    [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.left.right.equalTo(self.referenceViewForPhone);
        make.top.greaterThanOrEqualTo(self.referenceViewForPhone);
        make.bottom.lessThanOrEqualTo(self.referenceViewForPhone);
    }];
    
    [self remakePhoneUserVideoUpsideConstraintsWithButtons:buttons];

    [self.view addSubview:self.gestureView];
    [self.gestureView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
    [self setupGesture];
    [self remakePhoneUserVideoUpsideStrokeColorView];
    
    if ([buttons containsObject:self.PPTButton]
        && [buttons containsObject:self.selectButton]) {
        [self.view addSubview:self.pptSingleLine];
        [self.pptSingleLine bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.top.equalTo(self.PPTButton.bjl_bottom).offset((BJLIcAppearance.toolboxButtonSpace - 2 * BJLIcAppearance.toolboxButtonImageInset) / 2.0);
            make.centerX.equalTo(self.containerView);
            make.height.equalTo(@1.0);
            make.width.equalTo(@(BJLIcAppearance.toolboxLineLength));
        }];
    }
}

- (void)remakePhoneUserVideoUpsideStrokeColorView {
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

- (void)remakePhoneUserVideoUpsideConstraintsWithButtons:(NSArray *)buttons {
    UIButton *lastButton = nil;
    for (UIButton *button in buttons) {
        [self.view addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.centerX.equalTo(self.containerView);
            // 上一个按钮为空, 则按钮大小可以为图片大小, 后续的按钮与第一个按钮大小保持一致
            if (lastButton) {
                make.height.width.equalTo(lastButton);
                make.top.equalTo(lastButton.bjl_bottom).offset(BJLIcAppearance.toolboxButtonSpace - 2 * BJLIcAppearance.toolboxButtonImageInset);
            }
            else {
                make.width.equalTo(@(BJLIcAppearance.toolboxWidth)).priorityHigh();
                make.width.lessThanOrEqualTo(@(BJLIcAppearance.toolboxWidth));
//                make.height.equalTo(button.bjl_width);
                make.top.equalTo(self.containerView);
            }
            if (button == buttons.lastObject) {
                // 最后一个 button 底部约束
                make.bottom.equalTo(self.containerView);
            }
        }];
        lastButton = button;
    }
}

@end
