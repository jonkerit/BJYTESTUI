//
//  BJLIcVideosGridLayoutViewController.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/14.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveBase/NSObject+BJLObserving.h>
#import <BJLiveBase/BJL_EXTScope.h>

#import "BJLIcVideosGridLayoutViewController.h"
#import "BJLIcUserMediaInfoView.h"
#import "BJLIcVideosGridCell.h"

#define itemSpacing (1.0 / [UIScreen mainScreen].scale)

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcVideosGridLayoutViewController ()

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) BOOL active;
@property (nonatomic) NSArray<BJLIcUserMediaInfoView *> *userMediaInfoViews;

@end

@implementation BJLIcVideosGridLayoutViewController

static NSString * const reuseIdentifier = @"Cell";

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [self init];
    if (self) {
        self->_room = room;
        self.active = NO;
    }
    return self;
}

- (instancetype)init {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = itemSpacing;
    layout.minimumLineSpacing = itemSpacing;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    self = [super initWithCollectionViewLayout:layout];
    
    if (self) {
        self.collectionView.scrollEnabled = NO;
        self.collectionView.backgroundColor = [UIColor clearColor];
        [self.collectionView registerClass:[BJLIcVideosGridCell class] forCellWithReuseIdentifier:reuseIdentifier];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadCollectionView];
}

#pragma mark - update

- (void)updateWithUserMediaInfoViews:(nullable NSArray<BJLIcUserMediaInfoView *> *)mediaInfoViews {
    self.userMediaInfoViews = mediaInfoViews;
    [self reloadCollectionView];
}

- (void)updateActive:(BOOL)active {
    self.active = active;
    if (active) {
        for (BJLIcUserMediaInfoView *view in [self.userMediaInfoViews copy]) {
            view.position = BJLIcVideoPosition_gallary;
        }
        [self reloadCollectionView];
    }
}

- (void)reloadCollectionView {
    if (!self || !self.isViewLoaded || !self.active) {
        return;
    }
    [self.collectionView reloadData];
}

#pragma mark - <UICollectionViewDelegateFlowlayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self itemSize];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewFlowLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section{
    CGSize itemSize = [self itemSize];
    NSInteger numberOfItems = [collectionView numberOfItemsInSection:section];
    if (numberOfItems <= 0) {
        return UIEdgeInsetsZero;
    }
    CGFloat combinedItemWidth = (numberOfItems * itemSize.width) + ((numberOfItems - 1) * itemSpacing);
    CGFloat padding = (collectionView.bounds.size.width - combinedItemWidth) / 2;
    padding = padding > 0.0 ? padding : 0.0;
    CGFloat screenScale = [UIScreen mainScreen].scale;
    padding = floor(padding * screenScale) / screenScale;
    return UIEdgeInsetsMake(0.0, padding, itemSpacing, padding);
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self sectionCount];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSUInteger maxItemCount = [self maxItemCountForEachSection];
    return MIN(maxItemCount, self.userMediaInfoViews.count - maxItemCount * section);
}

#pragma mark <UICollectionViewDelegate>

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.section * [self maxItemCountForEachSection] + indexPath.row;
    BJLIcVideosGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    // 用户音视频信息视图，不能通过 cell 重用，需要单独处理
    BJLIcUserMediaInfoView *mediaInfoView = [self.userMediaInfoViews bjl_objectAtIndex:index];
    // 由于画廊布局刷新数据时，预期所有数据都在画廊布局列表中，因此在此处重新设置一下，目的是解决刚进教室默认就是画廊布局时，由于有黑板区的缓存的位置信息，导致视图位置信息不对的问题
    mediaInfoView.position = BJLIcVideoPosition_gallary;
    if (BJLIcTemplateType_1v1 != self.room.roomInfo.interactiveClassTemplateType) {
        [self.room.playingVM switchVideoDefinitionWithUser:mediaInfoView.user useLowDefinition:NO];
    }
    [mediaInfoView removeFromSuperview];
    [cell.mediaInfoContainerView addSubview:mediaInfoView];
    [mediaInfoView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(cell.mediaInfoContainerView);
    }];
    [mediaInfoView updateParentViewController:self];
    [mediaInfoView updateContentWithUser:mediaInfoView.user combineVideoView:YES];
    return cell;
}

#pragma mark - calculatiing methods

- (CGSize)itemSize {
    NSUInteger row = [self sectionCount];
    NSUInteger column = [self maxItemCountForEachSection];
    if (row <= 0 || column <= 0) {
        return CGSizeZero;
    }
    
    CGSize viewSize = self.view.bounds.size;
    CGFloat itemWidth = (viewSize.width - (column - 1) * itemSpacing) / column;
    CGFloat itemHeight = (viewSize.height - (row - 1) * itemSpacing) / row;
    
    // 根据屏幕 scale 丢弃部分 itemWidth 精度，保证计算值与屏幕实际渲染效果一致
    CGFloat screenScale = [UIScreen mainScreen].scale;
    return CGSizeMake(floor(itemWidth * screenScale) / screenScale, floor(itemHeight * screenScale) / screenScale);
}

- (NSUInteger)sectionCount {
    NSUInteger sourceCount = self.userMediaInfoViews.count;
    NSUInteger maxItemCount = [self maxItemCountForEachSection];
    return (sourceCount / maxItemCount + (sourceCount % maxItemCount > 0 ? 1 : 0));
}

- (NSUInteger)maxItemCountForEachSection {
    NSUInteger sourceCount = self.userMediaInfoViews.count;
    if (sourceCount <= 2) {
        return sourceCount;
    }
    else if (sourceCount <= 8) {
        // 2～3 列
        return sourceCount / 2 + (sourceCount % 2 > 0 ? 1 : 0);
    }
    else if (sourceCount <= 12) {
        // 3～4 列
        return sourceCount / 3 + (sourceCount % 3 > 0 ? 1 : 0);
    }
    else if (sourceCount <= 16) {
        return 4;
    }
    else {
        // 专业版小班课一般不超过 16 人
        return floor(sqrt(sourceCount));
    }
}

@end

NS_ASSUME_NONNULL_END
