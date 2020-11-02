//
//  BJLIcUserVideoListViewController+padUserVideoUpside.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/18.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcUserVideoListViewController+padUserVideoUpside.h"
#import "BJLIcUserVideoListViewController+private.h"

@implementation BJLIcUserVideoListViewController (padUserVideoUpside)

- (void) makePadUserVideoUpsideSubviews {    
    // 视频列表
    self.videoCollectionView = ({
        // layout: 不要设置 itemSize，触发 UICollectionViewDelegateFlowlayout
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = itemSpacing;
        layout.minimumLineSpacing = itemSpacing;
        layout.sectionInset = UIEdgeInsetsZero;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
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

- (CGSize)padUserVideoUpsideItemSize {
    NSInteger itemCount = [self padUserVideoUpsideCollectionView:self.videoCollectionView numberOfItemsInSection:0];

    if (!itemCount) {
        return CGSizeZero;
    }
    
    CGFloat itemWidth = 0.0;
    CGFloat itemHeight = self.videoCollectionView.bounds.size.height;
    if (itemCount > BJLIcAppearance.fullSizedVideosCount) {
        itemWidth = (self.videoCollectionView.bounds.size.width - (itemCount - 1) * itemSpacing) / self.videoUsers.count ;
    }
    else {
        itemWidth = itemHeight * BJLIcAppearance.videoAspectRatio;
    }
    
    // 根据屏幕 scale 丢弃部分 itemWidth 精度，保证计算值与屏幕实际渲染效果一致
    CGFloat screenScale = [UIScreen mainScreen].scale;
    itemWidth = floor(itemWidth * screenScale) / screenScale;
    
    return CGSizeMake(itemWidth, itemHeight);
}

- (NSInteger)padUserVideoUpsideCollectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    BJLMediaUser *user = [self mediaInfoViewWithIndex:0 forDisplay:YES].user;
    // 保留老师占位
    return self.currentUserMediaInfoViews.count + ((user && user.isTeacher) ? 0 : 1);
}

- (nullable BJLIcUserMediaInfoView *)padUserVideoUpsideMediaInfoViewWithIndex:(NSInteger)index {
    BJLIcUserMediaInfoView *mediaInfoView = [self mediaInfoViewWithIndex:index forDisplay:YES];
    switch (index) {
        case 0: {
            if (!mediaInfoView.user.isTeacher) {
                mediaInfoView = nil;
            }
            break;
         }
        default: {
            BJLIcUserMediaInfoView *teacherMediaInfoView = [self mediaInfoViewWithIndex:0 forDisplay:YES];
            /* 台上正常情况：（一个老师，多个学生）
             异常情况：（无老师，多个学生）
             如果只有学生开音视频的用户的情况，需要保留老师占位图，其他情况正常取值
             */
            index -= !teacherMediaInfoView.user.isTeacher;
            mediaInfoView = [self mediaInfoViewWithIndex:index forDisplay:YES];
        }
            break;
    }
    return mediaInfoView;
}

@end
