//
//  BJLIcPopoverView.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/20.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcPopoverView.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcPopoverView ()

@property (nonatomic) BJLIcPopoverViewType type;
@property (nonatomic, readwrite) CGSize viewSize;
@property (nonatomic, nullable) UIView *backgroundView;

@property (nonatomic) UIView *messageContainerView;
@property (nonatomic, readwrite) UILabel *messageLabel;

@property (nonatomic, readwrite) UIButton *cancelButton;
@property (nonatomic, readwrite) UIButton *confirmButton;
@property (nonatomic, readwrite, nullable) UIButton *appendButton;

@end

@implementation BJLIcPopoverView

- (instancetype)init {
    return [self initWithType:BJLIcPopoverViewDefaultType];
}

- (instancetype)initWithType:(BJLIcPopoverViewType)type {
    if (self = [super init]) {
        self.type = type;
        self.viewSize = CGSizeMake(BJLIcAppearance.popoverViewWidth, BJLIcAppearance.popoverViewHeight);
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)makeSubviewsAndConstraints {
    [self makeCommonView];

    switch (self.type) {
        case BJLIcExitViewNormal:
            [self makeNormalExitView];
            break;
            
        case BJLIcExitViewKickOut:
            [self makeKickOutExitView];
            break;
            
        case BJLIcExitViewTimeOut:
            [self makeTimeOutExitView];
            break;
            
        case BJLIcExitViewConnectFail:
            [self makeConnectFailExitView];
            break;
            
        case BJLIcExitViewAppend:
            [self makeAppendExitView];
            break;
            
        case BJLIcKickOutUser:
            [self makeKickOutUserView];
            break;
            
        case BJLIcSwitchStage:
            [self makeSwitchStageView];
            break;
            
        case BJLIcFreeBlockedUser:
            [self makeFreeAllBlockedUserView];
            break;
            
        case BJLIcStartCloudRecord:
            [self makeStartCloudRecordView];
            break;
            
        case BJLIcDisBandGroup:
            [self makeDisBandGroupView];
            break;
            
        case BJLIcRevokeWritingBoard:
            [self makeRevokeWritingBoardView];
            break;
            
        case BJLIcClearWritingBoard:
            [self makeClearWritingBoardView];
            break;

        case BJLIcCloseWritingBoard:
            [self makeCloseWritingBoardView];
            break;

        case BJLIcCloseWebPage:
            [self makeCloseWebPageView];
            break;
            
        case BJLIcCloseQuiz:
            [self makeCloseQuizView];
            break;
            
        case BJLIcHighLoassRate:
            [self makeHighLoassRateView];
            break;
            
        case BJLIcAnimatePPTTimeOut:
            [self makeAnimatePPTTimeOutView];
            break;
        
        case BJLIcDeletePPT:
            [self makeDeletePPT];
            break;

        case BJLIcSupportHomework:
            [self makeSupportHomeworkView];
            break;

        default:
            break;
    }
}

#pragma mark - exit

- (void)makeDeletePPT {
    [self makePureMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 40.0) space:52.0 positive:NO];
    self.messageLabel.text = @"确定删除课件吗?";
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    
    self.cancelButton.backgroundColor = BJLIcTheme.subButtonBackgroundColor;
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:BJLIcTheme.subButtonTextColor forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = BJLIcTheme.warningColor;
    [self.confirmButton setTitle:@"确认删除" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)makeNormalExitView {
    [self makeSingleMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 40.0) space:52.0 positive:NO];
    self.messageLabel.text = @"正在关闭教室, 是否结束授课?";
    
    self.cancelButton.backgroundColor = BJLIcTheme.subButtonBackgroundColor;
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:BJLIcTheme.subButtonTextColor forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = BJLIcTheme.warningColor;
    [self.confirmButton setTitle:@"关闭教室" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)makeKickOutExitView {
    [self makeSingleMessageView];
    [self makePassiveExitButtonViewWithButtonSize:CGSizeMake(120.0, 40.0)];
    [self.confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    self.messageLabel.text = @"您已被移出教室";
}

- (void)makeTimeOutExitView {
    [self makeSingleMessageView];
    [self makePassiveExitButtonViewWithButtonSize:CGSizeMake(120.0, 40.0)];
    self.messageLabel.text = @"严重超时! 教室已自动关闭";
}

- (void)makeConnectFailExitView {
    [self makeSingleMessageView];
    self.viewSize = CGSizeMake(450, BJLIcAppearance.popoverViewHeight);
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 40.0) space:52.0 positive:NO];
    self.messageLabel.text = @"连接超时! 请尝试重新登录";
    
    self.cancelButton.backgroundColor = BJLIcTheme.subButtonBackgroundColor;
    [self.cancelButton setTitle:@"退出教室" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:BJLIcTheme.warningColor forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [BJLIcTheme brandColor];
    [self.confirmButton setTitle:@"继续连接" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
}

- (void)makeAppendExitView {
    [self makeSingleMessageView];
    [self makeAppendButtonView];
    self.viewSize = CGSizeMake(422.0, 287.0);
    self.messageLabel.text = @"正在关闭教室, 是否结束授课?";
    
    self.cancelButton.backgroundColor = [BJLIcTheme subButtonBackgroundColor];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[BJLIcTheme subButtonTextColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = BJLIcTheme.warningColor;
    [self.confirmButton setTitle:@"关闭教室" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.appendButton.backgroundColor = [BJLIcTheme brandColor];
    [self.appendButton setTitle:@"下课并查看表情报告" forState:UIControlStateNormal];
    [self.appendButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
}

#pragma mark - actions

- (void)makeKickOutUserView {
    [self makeDoubleMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 40.0) space:52.0 positive:NO];
    self.messageLabel.text = @"是否将用户移出教室? \n 移出后将无法再次进入教室";
    
    self.cancelButton.backgroundColor = [UIColor bjl_colorWithHex:0XEEEEEE];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor bjl_colorWithHex:0X666666] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = BJLIcTheme.warningColor;
    [self.confirmButton setTitle:@"移出教室" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)makeSwitchStageView {
    [self makePureMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 40.0) space:52.0 positive:NO];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 4.0;
    paragraphStyle.paragraphSpacing = 4.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:@"坐席已满\n请设置下台后继续操作"
                                                                         attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16.0],
                                                                                      NSForegroundColorAttributeName : BJLIcTheme.viewTextColor,
                                                                                      NSParagraphStyleAttributeName : paragraphStyle}];
    self.messageLabel.attributedText = attributedText;
    
    self.confirmButton.backgroundColor = [BJLIcTheme brandColor];
    [self.confirmButton setTitle:@"去设置下台" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
    self.cancelButton.backgroundColor = [BJLIcTheme subButtonBackgroundColor];
    [self.cancelButton setTitle:@"取消操作" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[BJLIcTheme subButtonTextColor] forState:UIControlStateNormal];
}

- (void)makeFreeAllBlockedUserView {
    [self makePureMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 40.0) space:52.0 positive:NO];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 4.0;
    paragraphStyle.paragraphSpacing = 4.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:@"是否将黑名单全部成员解禁？"
                                                                         attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16.0],
                                                                                      NSForegroundColorAttributeName : BJLIcTheme.viewTextColor,
                                                                                      NSParagraphStyleAttributeName : paragraphStyle}];
    self.messageLabel.attributedText = attributedText;
    
    self.confirmButton.backgroundColor = [BJLIcTheme brandColor];
    [self.confirmButton setTitle:@"再想想" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
    self.cancelButton.backgroundColor = [BJLIcTheme subButtonBackgroundColor];
    [self.cancelButton setTitle:@"全部解禁" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[BJLIcTheme subButtonTextColor] forState:UIControlStateNormal];
}

- (void)makeStartCloudRecordView {
    [self makePureMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 40.0) space:52.0 positive:NO];
//    self.titleLabel.text = @"云端录制";
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 14.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    NSDictionary *attributedDic = @{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                    NSForegroundColorAttributeName : BJLIcTheme.viewTextColor,
                                    NSParagraphStyleAttributeName : paragraphStyle};
    self.messageLabel.attributedText = [[NSAttributedString alloc] initWithString:@"重新开启云端录制 \n 继续前一次云端录制还是开启新的云端录制?" attributes:attributedDic];
    
    self.cancelButton.backgroundColor = [BJLIcTheme subButtonBackgroundColor];
    [self.cancelButton setTitle:@"新的录制" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[BJLIcTheme subButtonTextColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [BJLIcTheme brandColor];
    [self.confirmButton setTitle:@"继续录制" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
}

- (void)makeDisBandGroupView {
    [self makeSingleMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 40.0) space:52.0 positive:NO];
    self.messageLabel.text = @"是否解散全部分组";
    
    self.cancelButton.backgroundColor = [BJLIcTheme brandColor];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [BJLIcTheme subButtonBackgroundColor];
    [self.confirmButton setTitle:@"全部解散" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[BJLIcTheme subButtonTextColor] forState:UIControlStateNormal];
}

- (void)makeRevokeWritingBoardView {
    [self makePureMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 40.0) space:52.0 positive:NO];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 14.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributedDic = @{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                    NSForegroundColorAttributeName : BJLIcTheme.viewTextColor,
                                    NSParagraphStyleAttributeName : paragraphStyle};
    self.messageLabel.attributedText = [[NSAttributedString alloc] initWithString:@"撤销小黑板将不保留学生数据\n是否继续撤销" attributes:attributedDic];
    
    self.cancelButton.backgroundColor = [BJLIcTheme subButtonBackgroundColor];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[BJLIcTheme subButtonTextColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [BJLIcTheme brandColor];
    [self.confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
}

- (void)makeClearWritingBoardView {
    [self makePureMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 40.0) space:52.0 positive:NO];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 14.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributedDic = @{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                    NSForegroundColorAttributeName : BJLIcTheme.viewTextColor,
                                    NSParagraphStyleAttributeName : paragraphStyle};
    self.messageLabel.attributedText = [[NSAttributedString alloc] initWithString:@"清空小黑板无法恢复\n是否继续清空" attributes:attributedDic];
    
    self.cancelButton.backgroundColor = [BJLIcTheme subButtonBackgroundColor];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[BJLIcTheme subButtonTextColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [BJLIcTheme brandColor];
    [self.confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
}

- (void)makeCloseWritingBoardView {
    [self makePureMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 40.0) space:52.0 positive:NO];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 14.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributedDic = @{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                    NSForegroundColorAttributeName : BJLIcTheme.viewTextColor,
                                    NSParagraphStyleAttributeName : paragraphStyle};
    self.messageLabel.attributedText = [[NSAttributedString alloc] initWithString:@"关闭窗口将收回学生页面, 是否继续?" attributes:attributedDic];
    
    self.cancelButton.backgroundColor = [BJLIcTheme subButtonBackgroundColor];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[BJLIcTheme subButtonTextColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [BJLIcTheme brandColor];
    [self.confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
}

- (void)makeCloseWebPageView {
    [self makePureMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 40.0) space:52.0 positive:NO];
    self.messageLabel.text = @"学生端将同步关闭窗口 是否继续？";
    
    self.cancelButton.backgroundColor = [BJLIcTheme subButtonBackgroundColor];
    [self.cancelButton setTitle:@"关闭" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[BJLIcTheme subButtonTextColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [BJLIcTheme brandColor];
    [self.confirmButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
}

- (void)makeCloseQuizView {
    [self makeSingleMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 40.0) space:52.0 positive:NO];
    self.messageLabel.text = @"确认关闭测验？";
    
    self.cancelButton.backgroundColor = [BJLIcTheme subButtonBackgroundColor];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[BJLIcTheme subButtonTextColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [BJLIcTheme brandColor];
    [self.confirmButton setTitle:@"关闭" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
}

- (void)makeHighLoassRateView {
    [self makePureMessageView];
    [self makePassiveExitButtonViewWithButtonSize:CGSizeMake(160.0, 40.0)];
    self.messageLabel.text = @"哎呀，您的网络开小差了，检测网络后重新进入教室";
    self.confirmButton.backgroundColor = [BJLIcTheme brandColor];
    [self.confirmButton setTitle:@"好的" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
}

- (void)makeAnimatePPTTimeOutView {
    [self makePureMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 40.0) space:52.0 positive:NO];
    self.messageLabel.text = @"PPT动画加载失败！\n网络较差建议跳过动画";
    
    self.cancelButton.backgroundColor = BJLIcTheme.subButtonBackgroundColor;
    [self.cancelButton setTitle:@"跳过动画" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:BJLIcTheme.subButtonTextColor forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = BJLIcTheme.brandColor;
    [self.confirmButton setTitle:@"重新加载" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:BJLIcTheme.buttonTextColor forState:UIControlStateNormal];
}

- (void)makeSupportHomeworkView {
    [self makePureMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 40.0) space:52.0 positive:NO];
    self.messageLabel.text = @"您授课的教室中，有部分学员未更新到App最新版本，作业模块暂无法使用，请在教室中叮嘱学员及时更新，避免影响正常教室秩序!";
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    
    self.cancelButton.backgroundColor = BJLIcTheme.subButtonBackgroundColor;
    [self.cancelButton setTitle:@"不再提醒" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:BJLIcTheme.subButtonTextColor forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = BJLIcTheme.brandColor;
    [self.confirmButton setTitle:@"知道了" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

#pragma mark - wheel

- (void)makeCommonView {
    // shadow
    self.layer.masksToBounds = NO;
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowColor = BJLIcTheme.windowShadowColor.CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 4.0);
    self.layer.shadowRadius = 10.0;
    
    // 背景色
    self.backgroundView = ({
        UIView *view = [UIView new];
        // border && corner
        view.layer.cornerRadius = 4.0;
        view.layer.masksToBounds = YES;
        view.layer.borderWidth = 1.0;
        view.layer.borderColor = [UIColor bjl_colorWithHex:0XDDDDDD alpha:0.1].CGColor;
        view.backgroundColor = BJLIcTheme.windowBackgroundColor;
        view;
    });
    [self addSubview:self.backgroundView];
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
}

// 提示message为一行
- (void)makeSingleMessageView {
    self.messageContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, messageContainerView);
        view;
    });
    [self addSubview:self.messageContainerView];
    [self.messageContainerView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self).offset(16);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.height.equalTo(@(90));
    }];

    // message
    self.messageLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = BJLIcTheme.viewTextColor;
        label.numberOfLines = 1;
        label.font = [UIFont systemFontOfSize:16.0];
        label;
    });
    [self addSubview:self.messageLabel];
    [self.messageLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.center.equalTo(self.messageContainerView);
    }];
}

// 提示message为两行
- (void)makeDoubleMessageView {
    self.messageContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, messageContainerView);
        view;
    });
    [self addSubview:self.messageContainerView];
    [self.messageContainerView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self).offset(16);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.height.equalTo(@(100));
    }];

    // message
    self.messageLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = BJLIcTheme.viewTextColor;
        label.numberOfLines = 2;
        label.font = [UIFont systemFontOfSize:16.0];
        label;
    });
    [self addSubview:self.messageLabel];
    [self.messageLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.center.equalTo(self.messageContainerView);
    }];
}

- (void)makePureMessageView {
    self.messageContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, messageContainerView);
        view;
    });
    [self addSubview:self.messageContainerView];
    [self.messageContainerView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self).offset(36);
        make.left.equalTo(self).offset(40);
        make.right.equalTo(self).offset(-40);
        make.height.equalTo(@(90));
    }];
    
    self.messageLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = BJLIcTheme.viewTextColor;
        label.font = [UIFont systemFontOfSize:16.0];
        label;
    });
    [self addSubview:self.messageLabel];
    [self.messageLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.messageContainerView);
        make.left.right.equalTo(self.messageContainerView);
    }];
}

- (void)makeDoubleHorizontalButtonViewWithButtonSize:(CGSize)size space:(CGFloat)space positive:(BOOL)positive {
    UIButton *leftButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.layer.cornerRadius = 3.0;
        button.layer.masksToBounds = YES;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont systemFontOfSize:16.0];
        button.titleLabel.textColor = [UIColor bjl_colorWithHex:0X666666];
        button;
    });
    [self addSubview:leftButton];
    [leftButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.greaterThanOrEqualTo(self);
        make.right.equalTo(self.bjl_centerX).offset(-space/2);
        make.top.equalTo(self.messageContainerView.bjl_bottom).offset(BJLIcAppearance.popoverViewSpace);
        make.height.equalTo(@(size.height));
        make.width.equalTo(@(size.width));
    }];
    
    UIButton *rightButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.layer.cornerRadius = 3.0;
        button.layer.masksToBounds = YES;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont systemFontOfSize:16.0];
        button;
    });
    [self addSubview:rightButton];
    [rightButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.lessThanOrEqualTo(self);
        make.left.equalTo(self.bjl_centerX).offset(space/2);
        make.top.equalTo(leftButton);
        make.height.equalTo(@(size.height));
        make.width.equalTo(@(size.width));
    }];
    if (positive) {
        self.confirmButton = leftButton;
        self.cancelButton = rightButton;
    }
    else {
        self.cancelButton = leftButton;
        self.confirmButton = rightButton;
    }
}

- (void)makeAppendButtonView {
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(96.0, 40.0) space:32.0 positive:NO];
    
    // append
    self.appendButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 3.0;
        button.layer.masksToBounds = YES;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont systemFontOfSize:16.0];
        button;
    });
    [self addSubview:self.appendButton];
    [self.appendButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.cancelButton.bjl_bottom).offset(24.0);
        make.centerX.equalTo(self);
        make.left.height.equalTo(self.cancelButton);
        make.right.equalTo(self.confirmButton.bjl_right);
    }];
}

- (void)makePassiveExitButtonViewWithButtonSize:(CGSize)size {
    // confirm
    self.confirmButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [BJLIcTheme brandColor];
        button.layer.cornerRadius = 3.0;
        button.layer.masksToBounds = YES;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont systemFontOfSize:16.0];
        [button setTitle:@"关闭" forState:UIControlStateNormal];
        [button setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
        button;
    });
    [self addSubview:self.confirmButton];
    [self.confirmButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self.messageContainerView.bjl_bottom).offset(BJLIcAppearance.popoverViewSpace);
        make.height.equalTo(@(size.height));
        make.width.equalTo(@(size.width));
    }];
}

@end

NS_ASSUME_NONNULL_END
