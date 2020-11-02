//
//  BJLIcUserVideoListViewController+pad1to1.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/7/24.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcUserVideoListViewController+pad1to1.h"
#import "BJLIcUserVideoListViewController+private.h"

@implementation BJLIcUserVideoListViewController (pad1to1)

- (void)makePad1to1Subviews {
    
    // 视频列表
    self.videoCollectionView = ({
        // layout: 不要设置 itemSize，触发 UICollectionViewDelegateFlowlayout
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = itemSpacing;
        layout.minimumLineSpacing = 16.0;
        layout.sectionInset = UIEdgeInsetsZero;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.backgroundColor = [UIColor clearColor];
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.bounces = YES;
        collectionView.alwaysBounceHorizontal = YES;
        collectionView.pagingEnabled = NO;
        collectionView.scrollEnabled = NO;
        collectionView.dataSource = self;
        collectionView.delegate = self;
        if (@available(iOS 11.0, *)) {
            collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [collectionView registerClass:[BJLIcUserSeatCell class] forCellWithReuseIdentifier:cellReuseIdentifier];
        [collectionView registerClass:[BJLIcUserSeatCell class] forCellWithReuseIdentifier:cellReuseIdentifierFor1to1];
        bjl_return collectionView;
    });
    [self.view addSubview:self.videoCollectionView];
    [self.videoCollectionView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (CGSize)pad1to1ItemSize {
    CGFloat itemWidth = self.videoCollectionView.bounds.size.width;
    CGFloat itemHeight = itemWidth / BJLIcAppearance.videoAspectRatio;
    
    // 根据屏幕 scale 丢弃部分 itemHeight 精度，保证计算值与屏幕实际渲染效果一致
    CGFloat screenScale = [UIScreen mainScreen].scale;
    itemHeight = floor(itemHeight * screenScale) / screenScale + 40.0;
    
    return CGSizeMake(itemWidth, itemHeight);
}

// 1v1 最多 2 个用户
- (NSInteger)pad1to1CollectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 2;
}

// 1、最多二个上麦的用户，第一个用户不能为学生，只能为助教或老师，2、第二个用户为学生或助教，不能为老师
- (nullable BJLIcUserMediaInfoView *)pad1to1MediaInfoViewWithIndex:(NSInteger)index {
    BJLIcUserMediaInfoView *mediaInfoView = [self mediaInfoViewWithIndex:index forDisplay:YES];
    switch (index) {
        case 0: {
            if (!mediaInfoView.user.isTeacherOrAssistant) {
                mediaInfoView = nil;
            }
        }
            break;
            
        case 1: {
            BJLIcUserMediaInfoView *preMediaInfoView = [self mediaInfoViewWithIndex:0 forDisplay:YES];
            /* 正常情况：（一个老师，一个学生）（一个助教，一个学生）（一个老师，一个助教）（二个助教）
             异常情况：（无老师助教，一个学生）
             如果只有一个学生开音视频的用户的情况，学生需要放在第二个位置，其他情况正常取值
             */
            if (!mediaInfoView.user && preMediaInfoView.user.isStudent) {
                mediaInfoView = preMediaInfoView;
            }
        }
            break;
            
        default:
            break;
    }
    return mediaInfoView;
}

@end
