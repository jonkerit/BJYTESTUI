//
//  BJLScStrokeColorSelectView.m
//  BJLiveUI
//
//  Created by xyp on 2020/8/24.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/NSObject+BJLObserving.h>
#import <BJLiveBase/BJL_EXTScope.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLScStrokeColorSelectView.h"
#import "BJLScAppearance.h"
#import "BJLScToolOptionCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScStrokeColorSelectView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) UICollectionView *strokeColorsView;
@property (nonatomic) NSArray *strokeColors;

@property (nonatomic) NSString *currentColor;

@end

@implementation BJLScStrokeColorSelectView

- (void)dealloc {
    self.strokeColorsView.dataSource = nil;
    self.strokeColorsView.delegate = nil;
}

#pragma mark - subviews

- (void)setupSubviews {
    [super setupSubviews];
    self.strokeColor = self.room.drawingVM.strokeColor;
    
    UIView *line = [UIView new];
    line.backgroundColor = [UIColor bjl_colorWithHexString:@"#9FA8B5" alpha:0.2];
    [self addSubview:line];
    [line bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self);
        make.left.right.equalTo(self).inset(BJLScToolViewDrawSpace).priorityHigh();
        make.height.equalTo(@1.0);
    }];
    self.strokeColorsView = ({
        UICollectionView *collectionView = [BJLScDrawSelectionBaseView createSelectCollectionViewWithCellClass:[BJLScToolOptionCell class]
                                                                                               scrollDirection:UICollectionViewScrollDirectionVertical
                                                                                                   itemSpacing:0.0
                                                                                                      itemSize:CGSizeMake(BJLScToolViewDrawButtonSize, BJLScToolViewDrawButtonSize)];
        collectionView.dataSource = self;
        collectionView.delegate = self;
        bjl_return collectionView;
    });
    [self addSubview:self.strokeColorsView];
    [self.strokeColorsView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self).insets(UIEdgeInsetsMake(BJLScToolViewDrawSpace, BJLScToolViewDrawSpace, BJLScToolViewDrawSpace, BJLScToolViewDrawSpace)).priorityHigh();
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.containerView bjlsc_drawRectCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(BJLScToolViewCornerRadius, BJLScToolViewCornerRadius)];
}

- (void)reloadLayout {
    [self.strokeColorsView.collectionViewLayout invalidateLayout];
    [self.strokeColorsView setNeedsLayout];
    [self.strokeColorsView layoutIfNeeded];
    [self.strokeColorsView reloadData];
}

#pragma mark - observers

- (void)setupObservers {
    if (!self.room) {
        return;
    }
    
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self, strokeColor)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateStrokeColor:self.strokeColor];
        [self.strokeColorsView reloadData];
        return YES;
    }];
}

#pragma mark - <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self itemSize];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return BJLScToolViewDrawOffset * 2;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return BJLScToolViewDrawOffset * 2;
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.strokeColors.count;
}

#pragma mark - <UICollectionViewDelegate>

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLScToolOptionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:scDrawSelectionCellReuseIdentifier forIndexPath:indexPath];
    NSString *strokeColor = [self.strokeColors bjl_objectAtIndex:indexPath.row];
    UIImage *colorIcon = [UIImage bjl_imageWithColor:[UIColor bjl_colorWithHexString:strokeColor]
                                                 size:[self itemSize]];
    cell.showSelectBorder = YES;
    [cell updateContentWithOptionIcon:colorIcon
                         selectedIcon:nil
                          description:nil
                           isSelected:[strokeColor isEqualToString:self.strokeColor]];
    bjl_weakify(self);
    [cell setSelectCallback:^(BOOL selected) {
        bjl_strongify(self);
        self.strokeColor = strokeColor;
    }];
    return cell;
}

- (void)updateStrokeColor:(NSString *)strokeColor {
    if (strokeColor == self.room.drawingVM.strokeColor) {
        return;
    }
    
    self.room.drawingVM.strokeColor = strokeColor;
    self.room.drawingVM.shouldRejectColorGranted = YES;
    if (self.room.drawingVM.fillColor) {
        // !!!: fillColor 不为空代表实心图形，需要根据调色板的选择修改填充色
        self.room.drawingVM.fillColor = strokeColor;
    }
}

#pragma mark - getters

// 视图需要自适应，一行 4 个颜色
- (CGSize)itemSize {
    CGFloat itemWidth = (self.strokeColorsView.bounds.size.width - BJLScToolViewDrawOffset * 2 * 3) / 4.0;
    if (itemWidth < 0) {
        return CGSizeMake(0.0, 0.0);
    }
    return CGSizeMake(itemWidth, itemWidth);
}

- (NSArray *)strokeColors {
    if (!_strokeColors) {
        _strokeColors = @[@"#FF9500", @"#FFBF2F", @"#F8E71C", @"#EE4844",
                          @"#1795FF", @"#00CAF5", @"#50E3C2", @"#FC9D9A",
                          @"#8B572A", @"#417505", @"#29CF42", @"#9A1BFF",
                          @"#FFFFFF", @"#8E8E93", @"#424242", @"#000000"];
    }
    return _strokeColors;
}

@end

NS_ASSUME_NONNULL_END
