//
//  BJLIcDrawTextOptionView.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/12.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/NSObject+BJLObserving.h>
#import <BJLiveBase/BJL_EXTScope.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcDrawTextOptionView.h"
#import "BJLIcTextFontTableViewCell.h"
#import "BJLIcToolboxOptionCell.h"

static NSString * const textFontCellReuseIdentifier = @"textFontCell";
static NSString * const textOptionCellReuseIdentifier = @"textOptionCell";
static NSString * const textFontSizeCellReuseIdentifier = @"textFontSizeCell";

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDrawTextOptionView () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) BJLIcRectPosition position;

@property (nonatomic) UIView *containerView;
@property (nonatomic) UICollectionView *textOptionView;
@property (nonatomic) UITableView *textFontsView;

@property (nonatomic) NSArray *textOptionKeys;
@property (nonatomic) NSArray *textFonts;

@end

@implementation BJLIcDrawTextOptionView

- (void)dealloc {
    self.textFontsView.dataSource = nil;
    self.textFontsView.delegate = nil;
    self.textOptionView.dataSource = nil;
    self.textOptionView.delegate = nil;
}

- (instancetype)initWithRoom:(id)room{
    self = [super init];
    if (self) {
        self->_room = room;
        self.position = BJLIcRectPosition_all;
        [self setupSubviews];
        [self setupObservers];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.containerView bjlic_drawRectCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(BJLIcAppearance.toolboxCornerRadius, BJLIcAppearance.toolboxCornerRadius)];
}

#pragma mark - subviews

- (void)setupSubviews {
    self.layer.shadowOffset = CGSizeMake(0, 0);
    self.layer.shadowOpacity = 0.8;
    self.layer.shadowColor = BJLIcTheme.windowShadowColor.CGColor;
    self.layer.shadowRadius = 5.0;

    self.containerView = ({
        UIView *containerView = [BJLHitTestView new];
        containerView.backgroundColor = BJLIcTheme.toolboxBackgroundColor;
        containerView;
    });
    [self addSubview:self.containerView];

    // text 选项视图
    self.textOptionView = [BJLIcDrawSelectionBaseView
                           createSelectCollectionViewWithCellClass:[BJLIcToolboxOptionCell class]
                           scrollDirection:UICollectionViewScrollDirectionHorizontal
                           itemSpacing:BJLIcAppearance.toolboxDrawSpace
                           itemSize:CGSizeMake(BJLIcAppearance.toolboxDrawButtonSize, BJLIcAppearance.toolboxDrawButtonSize)];
    self.textOptionView.accessibilityLabel = BJLKeypath(self, textOptionView);
    [self.textOptionView registerClass:[BJLIcToolboxOptionCell class]
            forCellWithReuseIdentifier:textOptionCellReuseIdentifier];
    [self.textOptionView registerClass:[BJLIcToolboxOptionCell class]
            forCellWithReuseIdentifier:textFontSizeCellReuseIdentifier];
    self.textOptionView.dataSource = self;
    self.textOptionView.delegate = self;
    self.textOptionView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.textOptionView];

    // text fonts
    self.textFontsView = ({
        UITableView *view = [[UITableView alloc] init];
        view.accessibilityLabel = BJLKeypath(self, textFontsView);
        view.layer.cornerRadius = BJLIcAppearance.toolboxCornerRadius;
        view.backgroundColor = BJLIcTheme.windowBackgroundColor;
        view.separatorStyle = UITableViewCellSeparatorStyleNone;
        view.rowHeight = BJLIcAppearance.toolboxDrawButtonSize;
        view.hidden = YES;
        view.showsVerticalScrollIndicator = YES;
        view.showsHorizontalScrollIndicator = NO;
        view.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        view.clipsToBounds = YES;
        view.dataSource = self;
        view.delegate = self;
        [view registerClass:[BJLIcTextFontTableViewCell class] forCellReuseIdentifier:textFontCellReuseIdentifier];
        bjl_return view;
    });
    [self addSubview:self.textFontsView];
    [self remarkConstraintsWithPosition:BJLIcRectPosition_left];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.textOptionView);
    }];
}

// position 是视图相对于 toolbox 的位置
- (void)remarkConstraintsWithPosition:(BJLIcRectPosition)position {
    if (self.position == position) {
        return;
    }
    switch (position) {
        // 显示在左边或下边
        case BJLIcRectPosition_left:
        case BJLIcRectPosition_right:
        case BJLIcRectPosition_bottom: {
            [self.textOptionView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                make.top.left.right.equalTo(self);
                make.size.equal.sizeOffset([self textOptionSize]);
            }];
            [self.textFontsView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.left.equalTo(self.textOptionView.bjl_left).offset(BJLIcAppearance.toolboxDrawSpace);
                make.top.equalTo(self.textOptionView.bjl_bottom);
                make.size.equal.sizeOffset([self textFontSize]).priorityHigh();
                make.bottom.lessThanOrEqualTo(self);
            }];
        }
            break;
            
        // 显示在上边
        case BJLIcRectPosition_top: {
            [self.textOptionView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                make.top.left.right.equalTo(self);
                make.size.equal.sizeOffset([self textOptionSize]);
            }];
            [self.textFontsView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.left.equalTo(self.textOptionView.bjl_left).offset(BJLIcAppearance.toolboxDrawSpace);
                make.top.equalTo(self.textOptionView.bjl_bottom);
                make.size.equal.sizeOffset([self textFontSize]).priorityHigh();
                make.bottom.lessThanOrEqualTo(self);
            }];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - observers

- (void)setupObservers {
    if (!self.room) {
        return;
    }
    
    bjl_weakify(self);
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.drawingVM, textBold),
                         BJLMakeProperty(self.room.drawingVM, textItalic)]
                filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        return now.boolValue != old.boolValue;
    }
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self.textOptionView reloadData];
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, textFontSize)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        return now.doubleValue != old.doubleValue;
    }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self.textOptionView reloadData];
        [self.textFontsView reloadData];
        return YES;
    }];
}

#pragma mark - actions

- (void)updateFontWithKey:(NSString *)key {
    if ([key isEqualToString:@"bold"]) {
        self.room.drawingVM.textBold = !self.room.drawingVM.textBold;
    }
    else if ([key isEqualToString:@"italic"]) {
        self.room.drawingVM.textItalic = !self.room.drawingVM.textItalic;
    }
    [self.textOptionView reloadData];
}

- (BOOL)selectedWithtextOptionKey:(NSString *)key {
    BOOL selected = NO;
    if ([key isEqualToString:@"bold"]) {
        selected = self.room.drawingVM.textBold;
    }
    else if ([key isEqualToString:@"italic"]) {
        selected = self.room.drawingVM.textItalic;
    }
    return selected;
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    else {
        NSInteger count = self.textOptionKeys.count;
        return count;
    }
}

#pragma mark - <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // 字体尺寸的按钮大 20 用于放图标
        return CGSizeMake(BJLIcAppearance.toolboxDrawButtonSize + BJLIcAppearance.toolboxDrawFontIconSize, BJLIcAppearance.toolboxDrawButtonSize);
    }
    else {
        return CGSizeMake(BJLIcAppearance.toolboxDrawButtonSize, BJLIcAppearance.toolboxDrawButtonSize);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, BJLIcAppearance.toolboxDrawSpace, 0, BJLIcAppearance.toolboxDrawSpace);
}

#pragma mark - <UICollectionViewDelegate>

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    bjl_weakify(self);
    if (indexPath.section == 0) {
        BJLIcToolboxOptionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:textFontSizeCellReuseIdentifier forIndexPath:indexPath];
        BOOL selected = !self.textFontsView.hidden;
        UIColor *backgroundColor = selected ? BJLIcTheme.toolboxBackgroundColor : [UIColor clearColor];
        UIImage *image = [UIImage bjlic_imageNamed:@"bjl_toolbox_draw_text_font"];
        UIImage *selectImage = [UIImage bjlic_imageNamed:@"bjl_toolbox_draw_text_font_selected"];
        NSString *fontSizeName = [NSString stringWithFormat:@"%.f", self.room.drawingVM.textFontSize];
        [cell updateBackgroundIcon:image
                      selectedIcon:selectImage
                   backgroundColor:backgroundColor
                       description:fontSizeName
                        isSelected:!self.textFontsView.hidden];
        [cell setSelectCallback:^(BOOL selected) {
            bjl_strongify(self);
            self.textFontsView.hidden = !selected;
            [self.textOptionView reloadData];
        }];
        return cell;
    }
    else {
        BJLIcToolboxOptionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:textOptionCellReuseIdentifier forIndexPath:indexPath];
        NSString *imageKey = [self.textOptionKeys bjl_objectAtIndex:indexPath.row];
        NSString *imageName = [NSString stringWithFormat:@"bjl_toolbox_draw_text_%@", imageKey];
        UIImage *image = [UIImage bjlic_imageNamed:[NSString stringWithFormat:@"%@_normal", imageName]];
        UIImage *selectedImage = [UIImage bjlic_imageNamed:[NSString stringWithFormat:@"%@_selected", imageName]];
        BOOL selected = [self selectedWithtextOptionKey:imageKey];
        [cell updateContentWithOptionIcon:image
                             selectedIcon:selectedImage
                              description:nil
                               isSelected:selected];
        [cell setSelectCallback:^(BOOL selected) {
            bjl_strongify(self);
            [self updateFontWithKey:imageKey];
        }];
        return cell;
    }
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.textFonts.count;
}

#pragma mark - <UITableViewDelegate>

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger fontSize = [[self.textFonts bjl_objectAtIndex:indexPath.row] bjl_integerValue];
    BJLIcTextFontTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:textFontCellReuseIdentifier forIndexPath:indexPath];
    BOOL selected = (fabs(self.room.drawingVM.textFontSize - fontSize) < FLT_MIN);
    [cell updateContentWithFont:fontSize selected:selected];
    bjl_weakify(self);
    [cell setSelectCallback:^(BOOL selected) {
        bjl_strongify(self);
        if (selected) {
            self.room.drawingVM.textFontSize = fontSize;
        }
    }];
    return cell;
}

#pragma mark - getters

- (NSArray *)textFonts {
    if (!_textFonts) {
        _textFonts = @[@12, @14, @16, @18, @20, @22, @24, @26, @28, @30, @40, @80];
    }
    return _textFonts;
}

- (NSArray *)textOptionKeys {
    if (!_textOptionKeys) {
        _textOptionKeys = @[@"bold", @"italic"];
    }
    return _textOptionKeys;
}

- (CGSize)textFontSize {
    // 字体列表和字体尺寸按钮的大小保持一致，预期显示五行
    CGSize size = CGSizeMake(BJLIcAppearance.toolboxDrawButtonSize + BJLIcAppearance.toolboxDrawFontIconSize - 2.0,
                             BJLIcAppearance.toolboxDrawButtonSize * 5 + BJLIcAppearance.toolboxOffset * 2);
    return size;
}

- (CGSize)textOptionSize {
    CGSize size = CGSizeMake(BJLIcAppearance.toolboxDrawButtonSize * 3 + BJLIcAppearance.toolboxDrawFontIconSize + BJLIcAppearance.toolboxDrawSpace * 4,
                             BJLIcAppearance.toolboxDrawButtonSize + BJLIcAppearance.toolboxOffset * 2);
    return size;
}

- (CGSize)expectedSize {
    CGSize size = CGSizeMake(BJLIcAppearance.toolboxDrawButtonSize * 3 + BJLIcAppearance.toolboxDrawFontIconSize + BJLIcAppearance.toolboxDrawSpace * 4,
                             BJLIcAppearance.toolboxDrawButtonSize * 6 + BJLIcAppearance.toolboxOffset * 2);
    return size;
}

@end

NS_ASSUME_NONNULL_END
