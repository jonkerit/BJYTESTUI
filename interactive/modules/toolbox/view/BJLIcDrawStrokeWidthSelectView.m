//
//  BJLIcDrawStrokeWidthSelectView.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/2.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/NSObject+BJLObserving.h>
#import <BJLiveBase/BJL_EXTScope.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcAppearance.h"
#import "BJLIcDrawStrokeWidthSelectView.h"
#import "BJLIcToolboxOptionCell.h"

static NSString * const sessionHeaderIdentifier = @"sessionHeader";

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDrawStrokeWidthSelectView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) UICollectionView *doodleStrokeWidthsView;
@property (nonatomic) NSArray *doodleStrokeWidths;

@property (nonatomic) NSInteger currentWidthIndex;

@end

@implementation BJLIcDrawStrokeWidthSelectView

- (void)dealloc {
    self.doodleStrokeWidthsView.dataSource = nil;
    self.doodleStrokeWidthsView.delegate = nil;
}

#pragma mark - subviews

- (void)setupSubviews {
    [super setupSubviews];
    self.doodleStrokeWidthsView = ({
        UICollectionView *collectionView = [BJLIcDrawSelectionBaseView createSelectCollectionViewWithCellClass:[BJLIcToolboxOptionCell class]
                                                                                               scrollDirection:UICollectionViewScrollDirectionHorizontal
                                                                                                   itemSpacing:0.0
                                                                                                      itemSize:CGSizeMake(BJLIcAppearance.toolboxDrawButtonSize, BJLIcAppearance.toolboxDrawButtonSize)];
        [collectionView registerClass:[UICollectionReusableView class]
           forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                  withReuseIdentifier:sessionHeaderIdentifier];
        collectionView.dataSource = self;
        collectionView.delegate = self;
        bjl_return collectionView;
    });
    [self addSubview:self.doodleStrokeWidthsView];
    [self.doodleStrokeWidthsView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self).insets(UIEdgeInsetsMake(0.0, BJLIcAppearance.toolboxDrawSpace, 0.0, BJLIcAppearance.toolboxDrawSpace)).priorityHigh();
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.containerView bjlic_drawRectCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(BJLIcAppearance.toolboxCornerRadius, BJLIcAppearance.toolboxCornerRadius)];
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
    BJLIcToolboxOptionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:drawSelectionCellReuseIdentifier forIndexPath:indexPath];
    NSInteger strokeWidth = [[self.doodleStrokeWidths bjl_objectAtIndex:indexPath.row] bjl_integerValue];
    NSString *optionKey = [NSString stringWithFormat:@"bjl_toolbox_draw_%@_%td", @"strokeWidth", strokeWidth];
    UIImage *normalIcon = [UIImage bjlic_imageNamed:[NSString stringWithFormat:@"%@_normal", optionKey]];
    UIImage *selectedIcon = [UIImage bjlic_imageNamed:[NSString stringWithFormat:@"%@_selected", optionKey]];
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
    CGSize size = CGSizeMake(BJLIcAppearance.toolboxDrawButtonSize * 4 + BJLIcAppearance.toolboxDrawSpace * 2,
                             BJLIcAppearance.toolboxDrawButtonSize + BJLIcAppearance.toolboxOffset * 2);
    return size;
}

@end

NS_ASSUME_NONNULL_END
