//
//  BJLScMarkStrokeWidthSelectView.m
//  BJLiveUI
//
//  Created by xyp on 2020/8/24.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLScMarkStrokeWidthSelectView.h"

#import "BJLScAppearance.h"
#import "BJLScToolOptionCell.h"

@interface BJLScMarkStrokeWidthSelectView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) UICollectionView *markStrokeWidthsView;
@property (nonatomic) NSArray *markStrokeWidths;

@property (nonatomic) NSInteger currentWidthIndex;

@end


@implementation BJLScMarkStrokeWidthSelectView

- (void)dealloc {
    self.markStrokeWidthsView.dataSource = nil;
    self.markStrokeWidthsView.delegate = nil;
}

#pragma mark - subviews

- (void)setupSubviews {
    [super setupSubviews];
    
    self.markStrokeWidthsView = ({
        UICollectionView *collectionView = [BJLScDrawSelectionBaseView createSelectCollectionViewWithCellClass:[BJLScToolOptionCell class]
                                                                                               scrollDirection:UICollectionViewScrollDirectionHorizontal
                                                                                                   itemSpacing:0.0
                                                                                                      itemSize:CGSizeMake(BJLScToolViewDrawButtonSize, BJLScToolViewDrawButtonSize)];
        collectionView.dataSource = self;
        collectionView.delegate = self;
        bjl_return collectionView;
    });
    [self addSubview:self.markStrokeWidthsView];
    [self.markStrokeWidthsView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self).insets(UIEdgeInsetsMake(0.0, BJLScToolViewDrawSpace, 0.0, BJLScToolViewDrawSpace)).priorityHigh();
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.containerView bjlsc_drawRectCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(BJLScToolViewCornerRadius, BJLScToolViewCornerRadius)];
}

- (void)reloadLayout {
    [self.markStrokeWidthsView.collectionViewLayout invalidateLayout];
    [self.markStrokeWidthsView setNeedsLayout];
    [self.markStrokeWidthsView layoutIfNeeded];
    [self.markStrokeWidthsView reloadData];
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
        for (NSInteger index = 0; index < self.markStrokeWidths.count; index++) {
            CGFloat strokeWidth = [[self.markStrokeWidths bjl_objectAtIndex:index] bjl_floatValue];
            if (fabs(strokeWidth - self.room.drawingVM.doodleStrokeWidth) <= FLT_MIN) {
                self.currentWidthIndex = index;
                break;
            }
        }
        [self.markStrokeWidthsView reloadData];
        return YES;
    }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.drawingVM, strokeColor),
                         BJLMakeProperty(self.room.drawingVM, strokeAlpha)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self.markStrokeWidthsView reloadData];
    }];
}

#pragma mark - setting

- (void)setMarkStrokeWidthWithIndex:(NSInteger)index {
    self.room.drawingVM.doodleStrokeWidth = [[self.markStrokeWidths bjl_objectAtIndex:index] integerValue];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.markStrokeWidths.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLScToolOptionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:scDrawSelectionCellReuseIdentifier forIndexPath:indexPath];
    NSString *optionKey = [NSString stringWithFormat:@"bjl_sc_toolbox_draw_%@_%td", @"markWidth", indexPath.row + 1];
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
        [self setMarkStrokeWidthWithIndex:indexPath.row];
    }];
    return cell;
}

#pragma mark - getters

- (NSArray *)markStrokeWidths {
    if (!_markStrokeWidths) {
        _markStrokeWidths = @[@8.0, @12.0, @14.0, @24.0];
    }
    return _markStrokeWidths;
}

- (CGSize)expectedSize {
    CGSize size = CGSizeMake(BJLScToolViewDrawButtonSize * 4 + BJLScToolViewDrawSpace * 2,
                             BJLScToolViewDrawButtonSize + BJLScToolViewDrawOffset * 2);
    return size;
}


@end
