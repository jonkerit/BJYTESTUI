//
//  BJLScStrokeWidthSelectView.m
//  BJLiveUI
//
//  Created by xyp on 2020/8/24.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/NSObject+BJLObserving.h>
#import <BJLiveBase/BJL_EXTScope.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLScAppearance.h"
#import "BJLScToolOptionCell.h"
#import "BJLScStrokeWidthSelectView.h"

static NSString * const sc_sessionHeaderIdentifier = @"sc_sessionHeaderIdentifier";

NS_ASSUME_NONNULL_BEGIN

@interface BJLScStrokeWidthSelectView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) UICollectionView *doodleStrokeWidthsView;
@property (nonatomic) NSArray *doodleStrokeWidths;

@property (nonatomic) NSInteger currentWidthIndex;

@end


@implementation BJLScStrokeWidthSelectView

- (void)dealloc {
    self.doodleStrokeWidthsView.dataSource = nil;
    self.doodleStrokeWidthsView.delegate = nil;
}

#pragma mark - subviews

- (void)setupSubviews {
    [super setupSubviews];
    self.doodleStrokeWidthsView = ({
        UICollectionView *collectionView = [BJLScDrawSelectionBaseView createSelectCollectionViewWithCellClass:[BJLScToolOptionCell class]
                                                                                               scrollDirection:UICollectionViewScrollDirectionHorizontal
                                                                                                   itemSpacing:0.0
                                                                                                      itemSize:CGSizeMake(BJLScToolViewDrawButtonSize, BJLScToolViewDrawButtonSize)];
        [collectionView registerClass:[UICollectionReusableView class]
           forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                  withReuseIdentifier:sc_sessionHeaderIdentifier];
        collectionView.dataSource = self;
        collectionView.delegate = self;
        bjl_return collectionView;
    });
    [self addSubview:self.doodleStrokeWidthsView];
    [self.doodleStrokeWidthsView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self).insets(UIEdgeInsetsMake(0.0, BJLScToolViewDrawSpace, 0.0, BJLScToolViewDrawSpace)).priorityHigh();
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.containerView bjlsc_drawRectCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(BJLScToolViewCornerRadius, BJLScToolViewCornerRadius)];
}

- (void)reloadLayout {
    [self.doodleStrokeWidthsView.collectionViewLayout invalidateLayout];
    [self.doodleStrokeWidthsView setNeedsLayout];
    [self.doodleStrokeWidthsView layoutIfNeeded];
    [self.doodleStrokeWidthsView reloadData];
}

#pragma mark - observers

- (void)setupObservers {
    if (!self.room) {
        return;
    }
    
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, doodleStrokeWidth)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        for (NSInteger index = 0; index < self.doodleStrokeWidths.count; index++) {
            CGFloat strokeWidth = [[self.doodleStrokeWidths bjl_objectAtIndex:index] bjl_floatValue];
            if (fabs(strokeWidth - self.room.drawingVM.doodleStrokeWidth) <= FLT_MIN) {
                self.currentWidthIndex = index;
                break;
            }
        }
        [self.doodleStrokeWidthsView reloadData];
        return YES;
    }];
}

#pragma mark - setting

- (void)setDoodleStrokeWidthWithIndex:(NSInteger)index {
    self.room.drawingVM.doodleStrokeWidth = [[self.doodleStrokeWidths bjl_objectAtIndex:index] bjl_floatValue];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.doodleStrokeWidths.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLScToolOptionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:scDrawSelectionCellReuseIdentifier forIndexPath:indexPath];
    NSInteger strokeWidth = [[self.doodleStrokeWidths bjl_objectAtIndex:indexPath.row] bjl_integerValue];
    NSString *optionKey = [NSString stringWithFormat:@"bjl_sc_toolbox_draw_%@_%td", @"strokeWidth", strokeWidth];
    UIImage *normalIcon = [UIImage bjlsc_imageNamed:[NSString stringWithFormat:@"%@_normal", optionKey]];
    UIImage *selectedIcon = [UIImage bjlsc_imageNamed:[NSString stringWithFormat:@"%@_selected", optionKey]];
    BOOL selected = (indexPath.row == self.currentWidthIndex);
    [cell updateContentWithOptionIcon:normalIcon
                         selectedIcon:selectedIcon
                          description:nil
                           isSelected:selected];
    
    bjl_weakify(self);
    [cell setSelectCallback:^(BOOL selected) {
        bjl_strongify(self);
        [self setDoodleStrokeWidthWithIndex:indexPath.row];
    }];
    
    return cell;
}

#pragma mark - getters

- (NSArray *)doodleStrokeWidths {
    if (!_doodleStrokeWidths) {
        _doodleStrokeWidths = @[@2.0, @4.0, @6.0, @8.0];
    }
    return _doodleStrokeWidths;
}

- (CGSize)expectedSize {
    CGSize size = CGSizeMake(BJLScToolViewDrawButtonSize * 4 + BJLScToolViewDrawSpace * 2,
                             BJLScToolViewDrawButtonSize + BJLScToolViewDrawOffset * 2);
    return size;
}
@end

NS_ASSUME_NONNULL_END
