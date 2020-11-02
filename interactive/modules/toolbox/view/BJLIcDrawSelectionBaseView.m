//
//  BJLIcDrawSelectionBaseView.m
//  BJLiveUI
//
//  Created by HuangJie on 2020/1/6.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcDrawSelectionBaseView.h"
#import "BJLIcAppearance.h"

NSString * const drawSelectionCellReuseIdentifier = @"drawSelectionCell";

@implementation BJLIcDrawSelectionBaseView

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self->_room = room;
        [self setupSubviews];
        [self setupObservers];
    }
    return self;
}

- (void)setupSubviews {
    // 阴影由基类设置
    self.layer.shadowOffset = CGSizeMake(0, 0);
    self.layer.shadowOpacity = 0.8;
    self.layer.shadowColor = BJLIcTheme.windowShadowColor.CGColor;
    self.layer.shadowRadius = 5.0;
    
    // 用于画圆角边框
    self.containerView = ({
        UIView *containerView = [BJLHitTestView new];
        containerView.backgroundColor = BJLIcTheme.toolboxBackgroundColor;
        containerView;
    });
    [self addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
}

- (void)setupObservers {
}

+ (UICollectionView *)createSelectCollectionViewWithCellClass:(Class)cellClass
                                              scrollDirection:(UICollectionViewScrollDirection)scrollDirection
                                                  itemSpacing:(CGFloat)itemSpacing
                                                     itemSize:(CGSize)itemSize {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = itemSpacing;
    layout.minimumLineSpacing = itemSpacing;
    layout.sectionInset = scrollDirection == UICollectionViewScrollDirectionVertical ? UIEdgeInsetsMake(itemSpacing, 0.0, itemSpacing, 0.0) : UIEdgeInsetsMake(0.0, itemSpacing, 0.0, itemSpacing);
    layout.scrollDirection = scrollDirection;
    layout.itemSize = itemSize;
    
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
    [collectionView registerClass:cellClass forCellWithReuseIdentifier:drawSelectionCellReuseIdentifier];
    
    return collectionView;
}

@end
