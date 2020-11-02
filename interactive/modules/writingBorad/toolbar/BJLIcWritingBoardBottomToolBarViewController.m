//
//  BJLIcWritingBoardBottomToolBarViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/19.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcWritingBoardBottomToolBarViewController.h"

static CGFloat const WriteBoardToolBarButtonHeight = 24;

@interface BJLIcWritingBoardBottomToolBarViewController ()

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic, assign) BJLIcWriteBoardStatus barStyle;

@property (nonatomic, readwrite) UIButton
*clearButton,
*nextPageButton,
*prevPageButton,
*revokeButton,
*gatherButton,
*submitButton,
*publishButton,
*reEditButton,
*rePublishButton,
*closeButton,
*restrictTimeButton,
*showNickNameButton,
*screenShotButton,
*shareBoardButton
;
@property (nonatomic, readwrite) UILabel *pageNumberLabel, *timeForStuLabel;

@property (nonatomic, readwrite) NSString *restrictTime;

@property (nonatomic) UIView *containView;

@end

@implementation BJLIcWritingBoardBottomToolBarViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
        self.barStyle = BJLIcWriteBoardStatus_None;
    }
    return self;
}

- (void)loadView {
    self.view = [BJLHitTestView viewWithTitTestBlock:^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
        if ([hitView isKindOfClass:[UIButton class]] || [hitView isKindOfClass:[UITextField class]]) {
            return hitView;
        }
        return nil;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    [self.view setBackgroundColor:[UIColor clearColor]];

    [self makeSubviews];
}

- (void)makeSubviews {
    self.clearButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_ic_boardclear_normal"] selectedImage:[UIImage bjlic_imageNamed:@"bjl_ic_boardclear_selected"] accessibilityLabel:BJLKeypath(self, clearButton)];

    self.containView = ({
        UIView * view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, containView);
        bjl_return view;
    });
    
    //teacher
    self.screenShotButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_ic_boardScreenshot_normal"] selectedImage:[UIImage bjlic_imageNamed:@"bjl_ic_boardScreenshot_selected"] accessibilityLabel:BJLKeypath(self, screenShotButton)];
    self.shareBoardButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_ic_boardShare_normal"] selectedImage:[UIImage bjlic_imageNamed:@"bjl_ic_boardShare_selected"] accessibilityLabel:BJLKeypath(self, shareBoardButton)];
    [self.screenShotButton addTarget:self action:@selector(screenShot) forControlEvents:UIControlEventTouchUpInside];
    [self.shareBoardButton addTarget:self action:@selector(shareBoard) forControlEvents:UIControlEventTouchUpInside];

    self.nextPageButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"window_nextpage"] selectedImage:[UIImage bjlic_imageNamed:@"window_nextpage"] accessibilityLabel:BJLKeypath(self, nextPageButton)];
    
    self.prevPageButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"window_prevpage"] selectedImage:[UIImage bjlic_imageNamed:@"window_prevpage"] accessibilityLabel:BJLKeypath(self, prevPageButton)];
    
    self.revokeButton = [self makeButtonWithTitle:@"撤销" selectedTitle:@"撤销" image:nil selectedImage:nil accessibilityLabel:@"revokeButton"];
    [self.revokeButton setTitleColor:[BJLIcTheme subButtonTextColor] forState:UIControlStateNormal];
    [self.revokeButton setBackgroundColor:[BJLIcTheme subButtonBackgroundColor]];

    self.gatherButton = [self makeButtonWithTitle:@"收回" selectedTitle:@"收回" image:nil selectedImage:nil accessibilityLabel:@"gatherButton"];
    [self.gatherButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
    [self.gatherButton setBackgroundColor:[BJLIcTheme brandColor]];

    self.reEditButton = [self makeButtonWithTitle:@"重新编辑" selectedTitle:@"重新编辑" image:nil selectedImage:nil accessibilityLabel:@"reEditButton"];
    [self.reEditButton setTitleColor:[BJLIcTheme subButtonTextColor] forState:UIControlStateNormal];
    [self.reEditButton setBackgroundColor:[BJLIcTheme subButtonBackgroundColor]];
    
    self.rePublishButton = [self makeButtonWithTitle:@"再次发布" selectedTitle:@"再次发布" image:nil selectedImage:nil accessibilityLabel:@"rePublishButton"];
    [self.rePublishButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
    [self.rePublishButton setBackgroundColor:[BJLIcTheme brandColor]];

    self.publishButton = [self makeButtonWithTitle:@"发布" selectedTitle:@"发布" image:nil selectedImage:nil accessibilityLabel:@"publishButton"];
    [self.publishButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
    [self.publishButton setBackgroundColor:[BJLIcTheme brandColor]];
    
    self.closeButton = [self makeButtonWithTitle:@"关闭" selectedTitle:@"关闭" image:nil selectedImage:nil accessibilityLabel:@"closeButton"];
    [self.closeButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];
    [self.closeButton setBackgroundColor:[BJLIcTheme brandColor]];

    self.showNickNameButton.titleEdgeInsets = UIEdgeInsetsMake(0, BJLIcAppearance.chatViewSmallSpace, 0, 0);
    self.showNickNameButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, BJLIcAppearance.chatViewSmallSpace);

    self.showNickNameButton = [self makeButtonWithTitle:@"显示昵称"
                                          selectedTitle:@"显示昵称" image:[UIImage bjlic_imageNamed:@"bjl_chat_checkbox_normal"]
                                          selectedImage:[UIImage bjlic_imageNamed:@"bjl_chat_checkbox_selected"]
                                     accessibilityLabel:@"showNickNameButton"];
    self.showNickNameButton.titleEdgeInsets = UIEdgeInsetsMake(0, BJLIcAppearance.chatViewSmallSpace, 0, 0);
    self.showNickNameButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, BJLIcAppearance.chatViewSmallSpace);
    
    self.restrictTimeButton = ({
        UIButton *button = [UIButton new];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [button.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
        button.accessibilityLabel = BJLKeypath(self, restrictTimeButton);
        [button setBackgroundColor:BJLIcTheme.buttonBorderColor];
        button.layer.cornerRadius = 4.0;
        [button setTitle:@"0" forState:UIControlStateNormal];
        bjl_return button;
    });
    self.restrictTime = @"0";
    
    self.pageNumberLabel = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor whiteColor];
        label.accessibilityLabel = BJLKeypath(self, pageNumberLabel);
        label.text = @"1/1";
        bjl_return label;
    });

    //student
    self.submitButton = [self makeButtonWithTitle:@"提交" selectedTitle:@"提交" image:nil selectedImage:nil accessibilityLabel:@"submitButton"];
    [self.submitButton setBackgroundColor:[BJLIcTheme brandColor]];
    [self.submitButton setTitleColor:[BJLIcTheme buttonTextColor] forState:UIControlStateNormal];

    self.timeForStuLabel = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [BJLIcTheme viewTextColor];
        label.backgroundColor = [UIColor clearColor];
        label.accessibilityLabel = BJLKeypath(self, timeForStuLabel);
        label.text = @"";
        bjl_return label;
    });
}

- (void)updateViewConstraintsWithStatus:(BJLIcWriteBoardStatus)status
                    shouldshareUserName:(BOOL)shouldshareUserName {
    self.barStyle = status;
    
    self.timeForStuLabel.text = @"";
    [self.containView removeFromSuperview];
    for (UIView *subView in self.containView.subviews) {
        [subView removeFromSuperview];
    }

    [self makeConstraints];
    self.showNickNameButton.selected = (shouldshareUserName && status == BJLIcWriteBoardStatus_teacherShare);
}

- (void)updateInputTimeString:(nullable NSString *)timeString {
    self.restrictTime = (timeString.length) ? timeString : @"0";
    [self.restrictTimeButton setTitle:self.restrictTime forState:UIControlStateNormal];
}

#pragma mark - private
- (void)makeConstraints {
    [self.view addSubview:self.containView];
    [self.containView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    
    switch (self.barStyle) {
        case BJLIcWriteBoardStatus_teacherEditing:
            [self makeContraintsForTeacherEditing];
            break;
        case BJLIcWriteBoardStatus_teacherPublished:
            [self makeContraintsForteacherPublished];
            break;
        case BJLIcWriteBoardStatus_teacherGathered:
            [self makeContraintsForteacherGathered];
            break;
        case BJLIcWriteBoardStatus_teacherShare:
            [self makeContraintsForteacherShare];
            break;
        case BJLIcWriteBoardStatus_studentEdit:
            [self makeContraintsForstudentEdit];
            break;
        default:
            break;
    }
}

- (void)makeContraintsForTeacherEditing {
    [self.containView addSubview:self.clearButton];
    
    UILabel *leftLabel = ({
        UILabel *label = [UILabel new];
        label.textColor = [BJLIcTheme viewSubTextColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentRight;
        label.text = @"倒计时";
        bjl_return label;
    });
    
    UILabel *rightLabel = ({
        UILabel *label = [UILabel new];
        label.textColor = [BJLIcTheme viewSubTextColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment =NSTextAlignmentLeft;
        label.text = @"分钟后收回";
        bjl_return label;
    });
    
    [self.containView addSubview:leftLabel];
    [self.containView addSubview:rightLabel];
    [self.containView addSubview:self.restrictTimeButton];
    [self updateInputTimeString:@"0"];
    [self.containView addSubview:self.publishButton];

    [self.clearButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.height.equalTo(@(WriteBoardToolBarButtonHeight + 2));
        make.width.equalTo(self.clearButton.bjl_height);
        make.left.equalTo(self.containView).offset(BJLIcAppearance.writingBoradToolbarSmallSpace);
    }];
    [self.restrictTimeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.containView);
        make.height.equalTo(self.clearButton);
        make.width.equalTo(@(40));
    }];
    [leftLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(self.restrictTimeButton.bjl_left).offset(-BJLIcAppearance.writingBoradToolbarSmallSpace / 2);
        make.left.greaterThanOrEqualTo(self.clearButton.bjl_right);
    }];
    [rightLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.left.equalTo(self.restrictTimeButton.bjl_right).offset(BJLIcAppearance.writingBoradToolbarSmallSpace / 2);
        make.right.lessThanOrEqualTo(self.publishButton.bjl_left);
    }];
    [self.publishButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(self.containView).offset(-BJLIcAppearance.writingBoradToolbarSmallSpace);
        make.height.equalTo(self.clearButton);
        make.width.equalTo(@(BJLIcAppearance.writingBoradToolbarButtonWidth));
    }];
}

- (void)makeContraintsForteacherPublished {
    [self.containView addSubview:self.screenShotButton];
    [self.containView addSubview:self.prevPageButton];
    [self.containView addSubview:self.nextPageButton];
    
    UIView *pageNumberContainerView = [UIView new];
    pageNumberContainerView.backgroundColor = [UIColor clearColor];
    pageNumberContainerView.layer.cornerRadius = BJLIcAppearance.toolboxCornerRadius;
    pageNumberContainerView.clipsToBounds = YES;
    pageNumberContainerView.backgroundColor = BJLIcTheme.buttonBorderColor;
    [self.containView addSubview:pageNumberContainerView];

    [self.containView addSubview:self.pageNumberLabel];
    [self.containView addSubview:self.revokeButton];
    [self.containView addSubview:self.gatherButton];

    [self.screenShotButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.height.equalTo(@(WriteBoardToolBarButtonHeight + 2));
        make.width.equalTo(self.screenShotButton.bjl_height);
        make.left.equalTo(self.containView).offset(BJLIcAppearance.writingBoradToolbarSmallSpace);
    }];
    [self.prevPageButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(pageNumberContainerView.bjl_left).offset(-BJLIcAppearance.writingBoradToolbarSmallSpace / 2);
        make.height.equalTo(@(WriteBoardToolBarButtonHeight));
        make.left.greaterThanOrEqualTo(self.screenShotButton.bjl_right);
    }];
    [pageNumberContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.containView);
        make.height.equalTo(self.screenShotButton);
    }];
    
    [self.pageNumberLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.containView);
        make.height.equalTo(self.screenShotButton);
        make.left.equalTo(pageNumberContainerView).offset(BJLIcAppearance.writingBoradToolbarSmallSpace / 2);
        make.right.equalTo(pageNumberContainerView).offset(-BJLIcAppearance.writingBoradToolbarSmallSpace / 2);
    }];
    [self.nextPageButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.left.equalTo(pageNumberContainerView.bjl_right).offset(BJLIcAppearance.writingBoradToolbarSmallSpace / 2);
        make.height.equalTo(self.screenShotButton);
        make.right.lessThanOrEqualTo(self.revokeButton.bjl_left);
    }];
    [self.revokeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.height.equalTo(self.screenShotButton);
        make.width.equalTo(@(BJLIcAppearance.writingBoradToolbarButtonWidth));
        make.right.equalTo(self.gatherButton.bjl_left).offset(-BJLIcAppearance.writingBoradToolbarSmallSpace);
    }];
    
    [self.gatherButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(self.containView).offset(-BJLIcAppearance.writingBoradToolbarSmallSpace);
        make.height.equalTo(self.screenShotButton);
        make.width.equalTo(@(BJLIcAppearance.writingBoradToolbarButtonWidth));
    }];
}

- (void)makeContraintsForteacherGathered {
    [self.containView addSubview:self.screenShotButton];
    [self.containView addSubview:self.shareBoardButton];
    [self.containView addSubview:self.prevPageButton];
    [self.containView addSubview:self.nextPageButton];
    
    UIView *pageNumberContainerView = [UIView new];
    pageNumberContainerView.backgroundColor = [UIColor clearColor];
    pageNumberContainerView.layer.cornerRadius = BJLIcAppearance.toolboxCornerRadius;
    pageNumberContainerView.clipsToBounds = YES;
    pageNumberContainerView.backgroundColor = BJLIcTheme.buttonBorderColor;
    [self.containView addSubview:pageNumberContainerView];

    [self.containView addSubview:self.pageNumberLabel];
    [self.containView addSubview:self.reEditButton];
    [self.containView addSubview:self.rePublishButton];
    
    [self.screenShotButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.height.equalTo(@(WriteBoardToolBarButtonHeight + 2));
        make.width.equalTo(self.screenShotButton.bjl_height);
        make.left.equalTo(self.containView).offset(BJLIcAppearance.writingBoradToolbarSmallSpace);
    }];
    [self.shareBoardButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.width.height.equalTo(self.screenShotButton);
        make.left.equalTo(self.screenShotButton.bjl_right).offset(BJLIcAppearance.writingBoradToolbarSmallSpace);
    }];

    [self.prevPageButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(pageNumberContainerView.bjl_left).offset(-BJLIcAppearance.writingBoradToolbarSmallSpace / 2);
        make.height.equalTo(@(WriteBoardToolBarButtonHeight));
        make.left.greaterThanOrEqualTo(self.containView).offset(BJLIcAppearance.writingBoradToolbarSmallSpace);
    }];
    [pageNumberContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.containView);
        make.height.equalTo(self.screenShotButton);
    }];
    
    [self.pageNumberLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.containView);
        make.height.equalTo(self.screenShotButton);
        make.left.equalTo(pageNumberContainerView).offset(BJLIcAppearance.writingBoradToolbarSmallSpace / 2);
        make.right.equalTo(pageNumberContainerView).offset(-BJLIcAppearance.writingBoradToolbarSmallSpace / 2);
    }];
    
    [self.nextPageButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.left.equalTo(pageNumberContainerView.bjl_right).offset(BJLIcAppearance.writingBoradToolbarSmallSpace / 2);
        make.height.equalTo(self.prevPageButton);
        make.right.lessThanOrEqualTo(self.reEditButton.bjl_left);
    }];
    
    [self.reEditButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.height.equalTo(self.prevPageButton);
        make.width.equalTo(@(BJLIcAppearance.writingBoradToolbarButtonWidth));
        make.right.equalTo(self.rePublishButton.bjl_left).offset(-BJLIcAppearance.writingBoradToolbarSmallSpace);
    }];
    
    [self.rePublishButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(self.containView).offset(-BJLIcAppearance.writingBoradToolbarSmallSpace);
        make.height.equalTo(self.prevPageButton);
        make.width.equalTo(@(BJLIcAppearance.writingBoradToolbarButtonWidth));
    }];
}

- (void)makeContraintsForteacherShare {
    [self.containView addSubview:self.showNickNameButton];
    [self.containView addSubview:self.closeButton];

    [self.closeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(self.containView).offset(-BJLIcAppearance.writingBoradToolbarSmallSpace);
        make.height.equalTo(@(WriteBoardToolBarButtonHeight));
        make.width.equalTo(@(BJLIcAppearance.writingBoradToolbarButtonWidth));
    }];
    
    [self.showNickNameButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.height.equalTo(self.closeButton);
        make.width.equalTo(@(80));
        make.right.equalTo(self.closeButton.bjl_left).offset(-BJLIcAppearance.writingBoradToolbarSmallSpace);
    }];
}

- (void)makeContraintsForstudentEdit {
    [self.containView addSubview:self.clearButton];
    [self.containView addSubview:self.timeForStuLabel];
    [self.containView addSubview:self.submitButton];
    
    [self.clearButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.height.equalTo(@(WriteBoardToolBarButtonHeight + 2));
        make.width.equalTo(self.clearButton.bjl_height);
        make.left.equalTo(self.containView).offset(BJLIcAppearance.writingBoradToolbarSmallSpace);
    }];
    
    [self.timeForStuLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.containView);
        make.left.greaterThanOrEqualTo(self.clearButton.bjl_right);
        make.right.lessThanOrEqualTo(self.submitButton.bjl_left);
    }];
    [self.submitButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(self.containView).offset(-BJLIcAppearance.writingBoradToolbarSmallSpace);
        make.height.equalTo(self.clearButton);
        make.width.equalTo(@(BJLIcAppearance.writingBoradToolbarButtonWidth));
    }];
}

#pragma mark - action

- (void)shareBoard {
    if(self.shareBoardCallback) {
        self.shareBoardCallback();
    }
}

- (void)screenShot {
    if(self.screenShotCallback) {
        self.screenShotCallback();
    }
}

- (UIButton *)makeImageButton:(nullable UIImage *)image selectedImage:(nullable UIImage *)selectedImage accessibilityLabel:(nullable NSString *)accessibilityLabel {
    UIButton *button = [BJLImageButton new];
    button.layer.masksToBounds = YES;
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:selectedImage forState:UIControlStateSelected];
    [button setImage:selectedImage forState:UIControlStateHighlighted];
    [button setImage:selectedImage forState:UIControlStateSelected | UIControlStateHighlighted];
    button.accessibilityLabel = accessibilityLabel;

    return button;
}

- (UIButton *)makeButtonWithTitle:(nullable NSString *)title selectedTitle:(nullable NSString *)selectedTitle
                            image:(nullable UIImage *)image selectedImage:(nullable UIImage *)selectedImage
               accessibilityLabel:(nullable NSString *)accessibilityLabel {
    UIButton *button = [BJLButton new];
    button.layer.masksToBounds = YES;
    button.accessibilityLabel = accessibilityLabel;
    button.titleLabel.font = [UIFont systemFontOfSize:14.0];
    button.layer.cornerRadius = BJLIcAppearance.toolboxCornerRadius;

    if (title) {
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:BJLIcTheme.viewTextColor forState:UIControlStateNormal];
    }
    if (selectedTitle) {
        [button setTitle:selectedTitle forState:UIControlStateSelected];
        [button setTitle:selectedTitle forState:UIControlStateHighlighted];
        [button setTitle:selectedTitle forState:UIControlStateHighlighted | UIControlStateSelected];
    }
    if (image) {
        [button setImage:image forState:UIControlStateNormal];
    }
    if (selectedImage) {
        [button setImage:selectedImage forState:UIControlStateSelected];
        [button setImage:selectedImage forState:UIControlStateHighlighted];
        [button setImage:selectedImage forState:UIControlStateHighlighted | UIControlStateSelected];
    }
    return button;
}

@end
