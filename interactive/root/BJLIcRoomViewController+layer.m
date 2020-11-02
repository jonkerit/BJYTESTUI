//
//  BJLIcRoomViewController+layer.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/20.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLIcRoomViewController+layer.h"
#import "BJLIcRoomViewController+private.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcRoomViewController (layer)

- (void)makeLayoutLayer {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    [self.view insertSubview:self.backgroundImageView belowSubview:self.loadingLayer];
    [self.view insertSubview:self.layoutLayer belowSubview:self.loadingLayer];
    [self.layoutLayer addSubview:self.layoutContainer];
    
    [self.backgroundImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // 默认第一套模板布局，默认 ipad 布局
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        if (iPhone) {
            [self makePhone1to1LayoutLayer];
        }
        else {
            [self makePad1to1LayoutLayer];
        }
    }
    else {
        if (iPhone) {
            [self makePhoneUserVideoUpsideLayoutLayer];
        }
        else {
            [self makePadUserVideoUpsideLayoutLayer];
        }
    }
}

- (void)makeWidgetLayer {
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        [self make1to1WidgetLayer];
    }
    else {
        [self makeUserVideoUpsideWidgetLayer];
    }
}

- (void)makeOtherLayers {
    // settingLayer
    [self.view insertSubview:self.settingsLayer belowSubview:self.loadingLayer];
    [self.settingsLayer bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.layoutLayer);
    }];
    
    // fullscreenLayer
    [self.view insertSubview:self.fullscreenLayer belowSubview:self.loadingLayer];
    [self.fullscreenLayer bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.layoutLayer);
    }];
    
    // fullscreenToolboxLayer
    [self.view insertSubview:self.fullscreenToolboxLayer belowSubview:self.loadingLayer];
    [self.fullscreenToolboxLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.layoutLayer);
    }];
    
    // lamp
    [self.view insertSubview:self.lampView belowSubview:self.loadingLayer];
    [self.lampView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    // popoversLayer
    [self.view insertSubview:self.popoversLayer belowSubview:self.loadingLayer];
    [self.popoversLayer bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

#pragma mark - userVideoUpside

- (void)makePadUserVideoUpsideLayoutLayer {
    [self.layoutLayer addSubview:self.toolbar];
    [self.layoutLayer addSubview:self.statusBar];
    
    [self.layoutLayer bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.bottom.centerX.equalTo(self.view);
        make.width.equalTo(self.layoutLayer.bjl_height).multipliedBy(BJLIcAppearance.layoutRatio);
    }];
    
    [self.layoutContainer addSubview:self.blackboardLayer];
    [self.layoutContainer addSubview:self.videosLayer];
    
    // 层级由上到下 statusbar -> layoutContainer -> toolbar
    [self.statusBar bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.left.right.equalTo(self.layoutLayer);
        make.height.equalTo(self.layoutLayer).multipliedBy(BJLIcAppearance.statusBarHeightFraction);
    }];
    
    // 包括黑板和视频窗口
    [self.layoutContainer bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(self.layoutLayer);
        make.top.equalTo(self.statusBar.bjl_bottom);
        make.bottom.equalTo(self.toolbar.bjl_top);
    }];
    
    [self.blackboardLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(self.layoutContainer);
        make.height.equalTo(self.blackboardLayer.bjl_width).multipliedBy(1.0 / BJLIcAppearance.blackboardAspectRatio);
    }];
    
    [self.videosLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.layoutContainer);
        make.bottom.equalTo(self.blackboardLayer.bjl_top);
        make.centerX.equalTo(self.layoutContainer);
        make.width.equalTo(self.videosLayer.bjl_height).multipliedBy(16.0 / 1.5);
    }];
    
    // 用户操作
    [self.toolbar bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.bottom.left.right.equalTo(self.layoutLayer);
        make.height.equalTo(self.layoutLayer).multipliedBy(BJLIcAppearance.toolbarHeightFraction);
    }];
}

- (void)makePhoneUserVideoUpsideLayoutLayer {
    [self.layoutLayer addSubview:self.toolbar];
    [self.layoutLayer addSubview:self.statusBar];
    
    [self.layoutLayer bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.bottom.centerX.equalTo(self.view);
        make.width.equalTo(self.layoutLayer.bjl_height).multipliedBy(BJLIcAppearance.layoutRatio);
    }];
    
    [self.layoutContainer addSubview:self.blackboardLayer];
    [self.layoutContainer addSubview:self.videosLayer];
    
    [self.statusBar bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.left.right.equalTo(self.layoutLayer);
        make.height.equalTo(self.layoutLayer).multipliedBy(BJLIcAppearance.statusBarHeightFraction);
    }]; 
    
    [self.layoutContainer bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(self.layoutLayer);
        make.top.equalTo(self.statusBar.bjl_bottom);
        make.bottom.equalTo(self.toolbar.bjl_top);
    }];
    
    [self.blackboardLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(self.layoutContainer);
        make.height.equalTo(self.blackboardLayer.bjl_width).multipliedBy(1.0 / BJLIcAppearance.blackboardAspectRatio);
    }];
    
    [self.videosLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.layoutContainer);
        make.bottom.equalTo(self.blackboardLayer.bjl_top);
        make.centerX.equalTo(self.layoutContainer);
        make.width.equalTo(self.videosLayer.bjl_height).multipliedBy(16.0 / 1.5);
    }];
    
    // iphone toolbar 在 Widget layer 上
    [self.toolbar bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.bottom.left.right.equalTo(self.layoutLayer);
        make.height.equalTo(self.layoutLayer).multipliedBy(0.0);
    }];
}

- (void)makeUserVideoUpsideWidgetLayer {
    // widgetLayer
    [self.view insertSubview:self.widgetLayer belowSubview:self.loadingLayer];
    [self.widgetLayer bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.layoutContainer);
        make.height.equalTo(self.layoutContainer.bjl_width).multipliedBy(1.0 / BJLIcAppearance.blackboardAspectRatio);
    }];
    
    // widgetContainer
    [self.widgetLayer addSubview:self.widgetContainer];
    [self.widgetContainer bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.widgetLayer);
        make.width.equalTo(self.widgetLayer).multipliedBy(BJLIcAppearance.widgetWidthFraction);
    }];
    
    // toolbox
    [self.widgetLayer addSubview:self.toolbox];
    [self.toolbox bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.widgetLayer);
    }];
}

#pragma mark - 1to1

- (void)makePad1to1LayoutLayer {
    [self.layoutLayer addSubview:self.statusBar];
    [self.layoutLayer addSubview:self.toolbar];
    [self.layoutLayer addSubview:self.toolbox];
    
    [self.layoutLayer bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.bottom.centerX.equalTo(self.view);
        make.width.equalTo(self.layoutLayer.bjl_height).multipliedBy(BJLIcAppearance.layoutRatio);
    }];
    
    [self.layoutContainer addSubview:self.blackboardLayer];
    [self.layoutContainer addSubview:self.videosLayer];

    // 包括 statusbar，黑板，视频窗口，toolbar，toolbox
    [self.layoutContainer bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.layoutLayer);
    }];
    
    [self.statusBar bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.left.right.equalTo(self.layoutContainer);
        make.height.equalTo(@(BJLIcAppearance.statusBarHeight));
    }];
    
    [self.blackboardLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.centerY.equalTo(self.layoutContainer);
        make.width.equalTo(self.layoutContainer).multipliedBy(BJLIcAppearance.blackboardWidthFraction);
        make.height.equalTo(self.blackboardLayer.bjl_width).multipliedBy(1.0 / BJLIcAppearance.blackboardAspectRatio);
    }];
    
    [self.toolbar bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.statusBar.bjl_bottom);
        make.left.equalTo(self.layoutContainer);
        make.width.equalTo(self.blackboardLayer);
        make.bottom.equalTo(self.blackboardLayer.bjl_top);
    }];
    
    [self.toolbox bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.bottom.equalTo(self.layoutContainer);
        make.top.width.equalTo(self.blackboardLayer);
    }];
    
    [self.videosLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.blackboardLayer.bjl_right);
        make.right.bottom.equalTo(self.layoutContainer);
        make.top.equalTo(self.statusBar.bjl_bottom);
    }];
}

- (void)makePhone1to1LayoutLayer {
    [self.layoutLayer addSubview:self.statusBar];
    [self.layoutLayer addSubview:self.toolbar];
    [self.layoutLayer addSubview:self.toolbox];
    
    [self.layoutLayer bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.bottom.centerX.equalTo(self.view);
        make.width.equalTo(self.layoutLayer.bjl_height).multipliedBy(BJLIcAppearance.layoutRatio);
    }];
    
    // 层级由上到下 statusbar -> layoutContainer
    [self.statusBar bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.left.right.equalTo(self.layoutLayer);
        make.height.equalTo(@(BJLIcAppearance.statusBarHeight));
    }];
    
    [self.layoutContainer addSubview:self.blackboardLayer];
    [self.layoutContainer addSubview:self.videosLayer];
    
    // 包括黑板，视频窗口，toolbar，toolbox
    [self.layoutContainer bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.layoutLayer);
        make.top.equalTo(self.statusBar.bjl_bottom);
    }];
    
    [self.toolbar bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.bottom.equalTo(self.layoutLayer);
        make.width.equalTo(@(BJLIcAppearance.toolbarWidth));
        make.top.equalTo(self.statusBar.bjl_bottom);
    }];
    
    [self.blackboardLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.layoutLayer).offset(BJLIcAppearance.toolbarWidth);
        make.top.equalTo(self.statusBar.bjl_bottom);
        make.bottom.equalTo(self.layoutLayer);
        make.height.equalTo(self.blackboardLayer.bjl_width).multipliedBy(1.0 /  BJLIcAppearance.blackboardAspectRatio);
    }];
    
    [self.toolbox bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.blackboardLayer);
    }];
    
    [self.videosLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.top.bottom.equalTo(self.layoutContainer);
        make.left.equalTo(self.blackboardLayer.bjl_right);
    }];
}

- (void)make1to1WidgetLayer {
    // widgetLayer
    [self.view insertSubview:self.widgetLayer belowSubview:self.loadingLayer];
    [self.widgetLayer bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardLayer);
    }];
    
    // widgetContainer
    [self.widgetLayer addSubview:self.widgetContainer];
    [self.widgetContainer bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.widgetLayer);
        make.width.equalTo(self.layoutLayer).multipliedBy(BJLIcAppearance.widgetWidthFraction);
    }];
}

@end

NS_ASSUME_NONNULL_END
