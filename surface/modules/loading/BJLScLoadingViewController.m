//
//  BJLScLoadingViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/10/9.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScLoadingViewController.h"
#import "BJLScAppearance.h"
#import "ICLProgressView.h"

@interface BJLScLoadingViewController ()

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic, copy, nullable) void (^reloadCallback)(void);

@property (nonatomic) UIView *containerView; // 仅用于同步退出按钮的位置
@property (nonatomic) UIButton *exitButton;
@property (nonatomic) UIView *loadingContainerView;
@property (nonatomic) UILabel *loadingProgressLabel;
@property (nonatomic) ICLProgressView *loadingProgressView;
@property (nonatomic, nullable) UIView *supportMessageView;
@property (nonatomic) UIView *errorContainerView;
@property (nonatomic) UIButton *reloadButton;
@property (nonatomic) UILabel *errorTitleLabel, *errorTipsLabel, *errorMoreLabel;

@end

@implementation BJLScLoadingViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor bjlsc_dimColor];
    self.view.hidden = YES;
    
    [self makeSubviews];
    [self makeConstraints];
    [self makeObserving];
    [self makeActions];
}

- (void)makeSubviews {
    self.containerView = ({
        UIView *view = [UIView new];
        view.userInteractionEnabled = NO;
        view.backgroundColor = [UIColor clearColor];
        [self.view addSubview:view];
        view;
    });
    
    self.exitButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, exitButton);
        button.layer.cornerRadius = 8.0;
        button.layer.masksToBounds = YES;
        button.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0];
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_close"] forState:UIControlStateNormal];
        [self.view addSubview:button];
        button;
    });
    
    self.loadingContainerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor whiteColor];
        view.layer.cornerRadius = BJLScButtonCornerRadius;
        view.layer.masksToBounds = YES;
        [self.view insertSubview:view atIndex:0];
        view;
    });
    
    self.loadingProgressView = ({
        ICLProgressView *view = [ICLProgressView new];
        view.size = 20.0;
        view.color = [UIColor bjlsc_lightGrayTextColor];
        [self.loadingContainerView addSubview:view];
        view;
    });
    
    self.loadingProgressLabel = ({
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:16.0];
        label.textColor = [UIColor bjlsc_lightGrayTextColor];
        label.text = @"连接中 ...";
        [self.loadingContainerView addSubview:label];
        label;
    });
    
    self.errorContainerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        [self.view insertSubview:view atIndex:0];
        view;
    });
    
    self.reloadButton = ({
        UIButton *button = [UIButton new];
        [button setTitle:@"刷新重试" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjlsc_blueBrandColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:16.0];
        button.backgroundColor = [UIColor whiteColor];
        button.layer.cornerRadius = BJLScButtonCornerRadius;
        button.layer.masksToBounds = YES;
        [self.errorContainerView addSubview:button];
        button;
    });
    
    self.errorTitleLabel = ({
        UILabel *label = [UILabel new];
        label.font = [UIFont boldSystemFontOfSize:24.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        [self.errorContainerView addSubview:label];
        label;
    });
    
    self.errorTipsLabel = ({
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:15.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.numberOfLines = 0;
        [self.errorContainerView addSubview:label];
        label;
    });
    
    self.errorMoreLabel = ({
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:15.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.numberOfLines = 0;
        [self.errorContainerView addSubview:label];
        label;
    });
    
    self.supportMessageView = ({
        UIView *supportMessgaeView = [[UIView alloc] init];
        [self.view addSubview:supportMessgaeView];
        
        // logo
        UIImageView *logoImageView = ({
            UIImage *logo = [UIImage bjlsc_imageNamed:@"bjl_sc_logo"];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:logo];
            imageView.alpha = 0.3;
            imageView;
        });
        [supportMessgaeView addSubview:logoImageView];
        [logoImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.left.centerY.equalTo(supportMessgaeView);
            make.size.equal.sizeOffset(CGSizeMake(19.0, 13.0));
        }];
        
        // message label
        UILabel *messageLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.font = [UIFont systemFontOfSize:12.0];
            label.text = @"百家云提供直播服务";
            label.textColor = [UIColor bjlsc_grayBorderColor];
            label.numberOfLines = 0;
            label.alpha = 0.3;
            label;
        });
        [supportMessgaeView addSubview:messageLabel];
        [messageLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.left.equalTo(logoImageView.bjl_right).offset(5.0);
            make.right.top.bottom.equalTo(supportMessgaeView);
        }];
        
        supportMessgaeView.hidden = YES;
        supportMessgaeView;
    });

}

- (void)makeConstraints {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);

    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.center.bottom.equalTo(self.view);
        make.width.equalTo(self.view.bjl_height).multipliedBy(iPhone ? 16.0 / 9.0 : 4.0 / 3.0);
    }];
    
    [self.exitButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self.containerView.bjl_safeAreaLayoutGuide ?: self.bjl_topLayoutGuide).offset(4.0);
        make.right.equalTo(self.containerView).with.offset(- 8.0);
        make.width.equalTo(@24.0);
        make.height.equalTo(@24.0);
    }];
    
    [self.loadingContainerView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.equalTo(@144);
        make.height.equalTo(@40);
    }];
    
    [self.loadingProgressView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.loadingContainerView).with.offset(BJLScViewSpaceL);
        make.centerY.equalTo(self.loadingContainerView);
        make.width.height.equalTo(@20);
    }];
    
    [self.loadingProgressLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.loadingProgressView.bjl_right).with.offset(BJLScViewSpaceM);
        make.centerY.equalTo(self.loadingContainerView);
    }];
    
    [self.errorContainerView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.reloadButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.center.equalTo(self.errorContainerView);
        make.width.equalTo(@144.0);
        make.height.equalTo(@40.0);
    }];
    
    CGFloat largeSpace = 24.0;
    
    [self.errorTipsLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(self.errorContainerView).with.inset(BJLScViewSpaceM);
        make.bottom.equalTo(self.reloadButton.bjl_top).with.offset(- largeSpace);
    }];
    
    [self.errorTitleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(self.errorContainerView).with.inset(BJLScViewSpaceM);
        make.bottom.equalTo(self.errorTipsLabel.bjl_top).with.offset(- BJLScViewSpaceM);
    }];
    
    [self.errorMoreLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(self.errorContainerView).with.inset(BJLScViewSpaceM);
        make.top.equalTo(self.reloadButton.bjl_bottom).with.offset(largeSpace);
    }];
    
    [self.supportMessageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).with.offset(- 20.0);
        make.left.greaterThanOrEqualTo(self.view).with.offset(BJLScViewSpaceL);
        make.right.lessThanOrEqualTo(self.view).with.offset(- BJLScViewSpaceL);
    }];
}

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room, loadingVM)
           filter:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
               bjl_strongify(self);
               self.view.hidden = !self.room.loadingVM;
               return !!now;
           }
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self showLoadingWithVM:self.room.loadingVM];
             return YES;
         }];
    
    [self.room setReloadingBlock:^(BJLLoadingVM *reloadingVM, void (^callback)(BOOL reload)) {
        bjl_strongify(self);
        self.view.hidden = NO;
        [self showReloadingWithVM:reloadingVM];
        callback(YES);
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room, roomInfo)
           filter:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
               return !!now;
           }
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.errorMoreLabel.text = self.room.roomInfo.customerSupportMessage;
             return YES;
         }];
}

- (void)makeActions {
    bjl_weakify(self);
    
    [self.exitButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        if (self.exitCallback) self.exitCallback();
    }];
    
    [self.reloadButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        if (self.reloadCallback) {
            self.reloadCallback();
        }
    }];
}

#pragma mark - getters & setters

- (BOOL)isHidden {
    return self.view.hidden;
}

- (void)showLoadingWithVM:(nullable BJLLoadingVM *)loadingVM {
    self.view.backgroundColor = [UIColor bjlsc_dimColor];
    self.loadingContainerView.hidden = NO;
    self.errorContainerView.hidden = YES;
    
    if (self.showCallback) self.showCallback(NO);
    
    if (loadingVM) {
        [self makeObservingForLoadingVM:loadingVM reload:NO];
    }
}

- (void)showReloadingWithVM:(nullable BJLLoadingVM *)loadingVM {
    self.view.backgroundColor = [UIColor clearColor];
    self.loadingContainerView.hidden = NO;
    self.errorContainerView.hidden = YES;
    
    if (self.showCallback) self.showCallback(NO);
    
    if (loadingVM) {
        [self makeObservingForLoadingVM:loadingVM reload:YES];
    }
}

- (void)showErrorWithTitle:(NSString *)title tips:(NSString *)tips {
    self.view.backgroundColor = [UIColor bjlsc_dimColor];
    self.loadingContainerView.hidden = YES;
    self.errorContainerView.hidden = NO;
    
    if (self.showCallback) self.showCallback(YES);
    
    self.errorTitleLabel.text = title;
    self.errorTipsLabel.text = tips;
}

- (void)makeObservingForLoadingVM:(BJLLoadingVM *)loadingVM reload:(BOOL)reload {
    bjl_weakify(self);
    loadingVM.suspendBlock = ^(BJLLoadingStep step,
                               BJLLoadingSuspendReason reason,
                               BJLError *error,
                               void (^continueCallback)(BOOL isContinue)) {
        bjl_strongify(self);
        
        // 成功
        BOOL enterWrongTemplate = NO;
        if (reason != BJLLoadingSuspendReason_errorOccurred) {
            if (self.room.roomInfo && self.room.roomInfo.roomType == BJLRoomType_interactiveClass) {
                enterWrongTemplate = YES;
            }
            else {
                continueCallback(YES);
                return;
            }
        }
        
        // 直接退出
        
        if (error.code == BJLErrorCode_enterRoom_auditionTimeout) {
            continueCallback(NO);
            return;
        }
        
        // 出错
        
        if (!error) {
            error = BJLErrorMake(BJLErrorCode_unknown, nil);
        }
        
        // 默认错误信息
        NSString *message = @"哎呀出错了";
        NSString *detailMessage = [NSString stringWithFormat:@"%@: %@(%td-%td)",
                                   error.localizedDescription,
                                   error.localizedFailureReason ?: @"",
                                   step,
                                   reason];
        self.errorMoreLabel.hidden = NO;
        
        // 特殊错误信息
        switch (error.code) {
            case BJLErrorCode_enterRoom_roomIsFull:
                message = @"教室已满";
                detailMessage = @"该教室成员已满，无法进入教室";
                self.errorMoreLabel.hidden = YES;
                break;
            case BJLErrorCode_enterRoom_unsupportedClient:
                message = @"iOS端不支持";
                detailMessage = @"iOS端不支持该班型，请使用PC客户端进入";
                self.errorMoreLabel.hidden = YES;
                break;
            case BJLErrorCode_enterRoom_unsupportedDevice:
                message = @"设备不支持";
                detailMessage = @"你的设备不支持该教室，请更换设备进入";
                self.errorMoreLabel.hidden = YES;
                break;
            case BJLErrorCode_enterRoom_forbidden:
                message = @"无法进入";
                detailMessage = @"你已被移出，无法再次进入教室";
                self.errorMoreLabel.hidden = YES;
                break;
            case BJLErrorCode_enterRoom_loginConflict:
                message = @"已有老师";
                detailMessage = @"继续进入将导致该老师强制下线";
                self.errorMoreLabel.hidden = YES;
                break;
            case BJLErrorCode_enterRoom_timeExpire:
                message = @"无法进入";
                detailMessage = @"教室已过期";
                self.errorMoreLabel.hidden = YES;
                break;
            default:
                break;
        }
        if (enterWrongTemplate) {
            message = @"班型错误";
            detailMessage = @"当前 UI 不支持专业小班课";
            error = BJLErrorMake(BJLErrorCode_enterRoom_unsupportedClient, message);
        }
        
        [self showErrorWithTitle:message tips:detailMessage];
        
        if (error.code == BJLErrorCode_enterRoom_unsupportedClient
            || error.code == BJLErrorCode_enterRoom_unsupportedDevice
            || error.code == BJLErrorCode_enterRoom_timeExpire) {
            [self.reloadButton setTitle:@"我知道了" forState:UIControlStateNormal];
            self.reloadCallback = ^{
                bjl_strongify(self);
                if (self.exitCallback) self.exitCallback();
            };
        }
        else {
            if (error.code == BJLErrorCode_enterRoom_loginConflict) {
                [self.reloadButton setTitle:@"进入教室" forState:UIControlStateNormal];
            }
            else {
                [self.reloadButton setTitle:@"刷新重试" forState:UIControlStateNormal];
            }
            self.reloadCallback = ^{
                bjl_strongify(self);
                self.reloadCallback = nil;
                [self showReloadingWithVM:nil];
                continueCallback(YES);
            };
        }
    };
    
    [self bjl_observe:BJLMakeMethod(loadingVM, loadingUpdateProgress:)
             observer:(BJLMethodObserver)^BOOL(CGFloat progress) {
        bjl_strongify(self);
        self.loadingProgressView.progress = progress;
        if (self.supportMessageView
            && self.room.featureConfig
            && !self.room.featureConfig.hideSupportMessage) {
            self.supportMessageView.hidden = NO;
        }
        return YES;
    }];
    
    /** 首次加载成功进入教室之后，创建 UI，隐藏 loading
     TODO:之所以换到加载完成后构建，由于遗留一个问题，在加载过程中构建，如果触发退出教室，会出现界面卡住的情况，暂未找到解决方法
     因此在成功进入教室后有二次确认弹窗，不会过快退出教室，因此转移到进入教室后才构建 UI
     由于大班课始终有二次确认弹窗，此处仅为了和小班课布局设置同步
     */
    [self bjl_observe:BJLMakeMethod(loadingVM, loadingSuccess)
             observer:^BOOL() {
        bjl_strongify(self);
        if (!reload && self.loadRoomInfoSucessCallback) {
            self.loadRoomInfoSucessCallback();
        }
        self.view.hidden = YES;
        [self.supportMessageView removeFromSuperview];
        self.supportMessageView = nil;
        if (self.hideCallback) self.hideCallback();
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(loadingVM, loadingFailureWithError:)
             observer:^BOOL(BJLError *error) {
        bjl_strongify(self);
        if (self.exitCallbackWithError) self.exitCallbackWithError(error);
        self.view.hidden = YES;
        [self.supportMessageView removeFromSuperview];
        self.supportMessageView = nil;
        return YES;
    }];
}

@end
