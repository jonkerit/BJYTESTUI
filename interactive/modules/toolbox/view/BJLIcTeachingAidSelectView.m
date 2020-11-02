//
//  BJLIcTeachingAidSelectView.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/6/4.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/NSObject+BJLObserving.h>
#import <BJLiveBase/BJL_EXTScope.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcAppearance.h"
#import "BJLIcTeachingAidSelectView.h"

@interface BJLIcTeachingAidOptionCell ()

@property (nonatomic) UIButton *optionButton;
@property (nonatomic, nullable, copy) void (^selectCallback)(BOOL selected);

@property (nonatomic) UIImageView *icon;
@property (nonatomic) UILabel *text;

@end

@implementation BJLIcTeachingAidOptionCell 

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

#pragma mark - subviews

- (void)setupSubviews {
    self.icon = ({
        UIImageView *view = [UIImageView new];
        view.contentMode = UIViewContentModeScaleAspectFit;
        view;
    });
    self.text = ({
        UILabel *label = [UILabel new];
        label.textColor = BJLIcTheme.toolButtonTitleColor;
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentCenter;
        label;
    });
    
    self.optionButton = ({
        UIButton *button = [[UIButton alloc] init];
        
        bjl_weakify(self);
        [button bjl_addHandler:^(UIButton * _Nonnull button) {
            bjl_strongify(self);
            if (self.selectCallback) {
                self.selectCallback(!button.selected);
            }
        }];
        button;
    });
    [self.contentView addSubview:self.icon];
    [self.contentView addSubview:self.text];
    [self.icon bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.width.equalTo(@(40));
        make.top.centerX.equalTo(self.contentView);
    }];
    [self.text bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.icon.bjl_bottom).offset(4);
        make.bottom.centerX.equalTo(self.contentView);
    }];
    [self.contentView addSubview:self.optionButton];
    [self.optionButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.contentView);
    }];
}

@end

#pragma mark - BJLIcTeachingAidSelectView

@interface BJLIcTeachingAidSelectView ()<UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) UICollectionView *strokeColorsView;
@property (nonatomic) NSArray *teachingAidButtons, *teachingAidButtonIcons;

@end

@implementation BJLIcTeachingAidSelectView

- (void)dealloc {
    self.strokeColorsView.dataSource = nil;
    self.strokeColorsView.delegate = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.containerView bjlic_drawRectCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(BJLIcAppearance.toolboxCornerRadius, BJLIcAppearance.toolboxCornerRadius)];
}

- (void)setupSubviews {
    [super setupSubviews];
    
    self.strokeColorsView = ({
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = 8;
        layout.minimumLineSpacing = 12;
        layout.sectionInset = UIEdgeInsetsMake(10, 0.0, 10, 0.0);
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.itemSize = CGSizeMake(50.0, 54.0);
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.backgroundColor = [UIColor clearColor];
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.bounces = YES;
        collectionView.alwaysBounceVertical = YES;
        collectionView.pagingEnabled = NO;
        collectionView.scrollEnabled = NO;
        if (@available(iOS 11.0, *)) {
            collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [collectionView registerClass:[BJLIcTeachingAidOptionCell class]  forCellWithReuseIdentifier:NSStringFromClass([BJLIcTeachingAidOptionCell class])];
        collectionView.dataSource = self;
        collectionView.delegate = self;
        bjl_return collectionView;
    });
    [self addSubview:self.strokeColorsView];
    [self.strokeColorsView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self).insets(UIEdgeInsetsMake(0.0, 6.0, 0.0, 6.0)).priorityHigh();
    }];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.teachingAidButtons.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLIcTeachingAidOptionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BJLIcTeachingAidOptionCell class]) forIndexPath:indexPath];
    NSString *title = [self.teachingAidButtons bjl_objectAtIndex:indexPath.row];
    UIImage *icon = [UIImage bjlic_imageNamed:[self.teachingAidButtonIcons bjl_objectAtIndex:indexPath.row]];
    [cell.icon setImage:icon];
    cell.text.text = title;
    
    bjl_weakify(self);
    [cell setSelectCallback:^(BOOL selected) {
        bjl_strongify(self);
        switch (indexPath.row) {
            case 0:
            {
                if (self.openWebViewCallback)
                    self.openWebViewCallback();
            }
                break;
            case 1:
            {
                if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
                    if (self.countDownCallback)
                        self.countDownCallback();
                }
                else {
                    if (self.clickWritingBoardCallback)
                        self.clickWritingBoardCallback();
                }
            }
                break;
            case 2:
            {
                if (self.questionAnswerCallback)
                    self.questionAnswerCallback();
            }
                break;
            case 3:
            {
                if (self.questionResponderCallback)
                    self.questionResponderCallback();
            }
                break;
            case 4:
            {
                if (self.countDownCallback)
                    self.countDownCallback();
            }
                break;
            default:
                break;
        }
    }];
    return cell;
}

#pragma mark - getters

- (NSArray *)teachingAidButtons {
    if (!_teachingAidButtons) {
        if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
            _teachingAidButtons = @[@"打开网页", @"计时器"];
        }
        else {
            _teachingAidButtons = @[@"打开网页", @"小黑板", @"答题器", @"抢答器", @"计时器"];
        }
    }
    return _teachingAidButtons;
}

- (NSArray *)teachingAidButtonIcons {
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
    return @[@"bjl_toolbox_openweb_normal",
             @"bjl_toolbox_countdown_normal"];
    }
    else {
        return @[@"bjl_toolbox_openweb_normal",
                 @"bjl_toolbox_writingboard_normal",
                 @"bjl_toolbox_questionanswer_normal",
                 @"bjl_toolbox_questionResponder_normal",
                 @"bjl_toolbox_countdown_normal"];
    }
}

@end
