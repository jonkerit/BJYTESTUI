//
//  BJLScDrawSelectionBaseView.h
//  BJLiveUI
//
//  Created by xyp on 2020/8/24.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const scDrawSelectionCellReuseIdentifier;

@interface BJLScDrawSelectionBaseView : UIView

@property (nonatomic, readonly, weak) BJLRoom *room;

// 用于子类画圆角边框
@property (nonatomic) UIView *containerView;

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

- (void)setupSubviews;

- (void)setupObservers;

+ (UICollectionView *)createSelectCollectionViewWithCellClass:(nullable Class)cellClass
                                              scrollDirection:(UICollectionViewScrollDirection)scrollDirection
                                                  itemSpacing:(CGFloat)itemSpacing
                                                     itemSize:(CGSize)itemSize;

@end

NS_ASSUME_NONNULL_END
