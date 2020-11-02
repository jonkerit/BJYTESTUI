//
//  BJLIcRandomChooseViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/7/15.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcRandomChooseViewController.h"
#import "BJLIcWindowViewController+protected.h"
#import "BJLIcAppearance.h"

#define kCellHeight 32
#define kPerTime 0.01
#define kTime 2.5

@interface BJLIcRandomChooseViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, readonly, weak) BJLRoom *room;

@property (nonatomic, copy) NSArray <NSString *> *candidates;
@property (nonatomic) BJLUser *choosenUser;

@property (nonatomic) UIView *cornerView, *tableViewContainerView;
@property (nonatomic) UITableView *tableView1, *tableView2;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) CGFloat leftOffset, CellCount;

@property (nonatomic) UIButton *closeButton;

@end

@implementation BJLIcRandomChooseViewController

- (instancetype)initWithRoom:(BJLRoom *)room
                  candidates:(NSArray<NSString *> *)candidates
                 choosenUser:(BJLUser *)user {
    self = [super init];
    if (self) {
        self->_room = room;
        self.choosenUser = user;
        [self handleDateSourceWithUserNames:candidates];
        [self prepareToOpen];
    }
    return self;
}

- (void)prepareToOpen {
    self.caption = @"随机选人";
    self.minWindowHeight = 240.0f;
    self.minWindowWidth = 460.0f;
    self.fixedAspectRatio = self.minWindowWidth/self.minWindowHeight;

    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);

    CGFloat relativeWidth = self.minWindowWidth / (self.view.superview.frame.size.width ?: (!iPhone ? 1024 : 600.0)) ;
    CGFloat relativeHeight = self.minWindowHeight / (self.view.superview.frame.size.height ?: (!iPhone ? 512 : 330.0)) ;
    CGFloat relativeX = (1 - relativeWidth) / 2.0;
    self.relativeRect = [self rectInBounds:CGRectMake(relativeX, (1 - relativeHeight) / 4.0, relativeWidth, relativeHeight)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.layer.shadowColor = BJLIcTheme.windowShadowColor.CGColor;
    self.view.layer.shadowOffset = CGSizeMake(0, 0);
    self.view.layer.shadowRadius = BJLIcAppearance.toolboxCornerRadius;
    self.view.layer.shadowOpacity = 0.3;

    self.backgroundView.backgroundColor = BJLIcTheme.windowBackgroundColor;
    self.doubleTapToMaximize = NO;
    self.resizeHandleImageViewHidden = YES;
    self.panToMove = YES;
    self.closeButtonHidden = YES;
    self.fullscreenButtonHidden = YES;
    self.maximizeButtonHidden = YES;
    self.topBar.hidden = NO;
    self.bottomBar.hidden = YES;
    self.topBar.backgroundView.hidden = YES;
    
    [self makeConstraints];
    
    // 延时是为了不至于在打开的一瞬间里面开始动画,给0.1秒的缓冲时间
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startRandomAnmated];
    });
    
    [self makeObserving];
}

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveRandomSelectCandidateList:choosenUser:)
             observer:^BOOL(NSArray <NSString *> *candidateList, BJLUser *user) {
        bjl_strongify(self);
        if (!user) {
            return YES;
        }
        self.choosenUser = user;
        [self handleDateSourceWithUserNames:candidateList];
        [self updateConstraints];
        [self startRandomAnmated];

        return YES;
    }];
}
     
- (void)handleDateSourceWithUserNames:(NSArray <NSString *> *)candidateList {
    NSMutableArray *mutableCandidates = [NSMutableArray new];
    for (NSString *userName in candidateList) {
        [mutableCandidates bjl_addObject:[BJLUser displayNameOfName:userName]];
    }
    
    if ([mutableCandidates count] > 1) {
        [mutableCandidates bjl_insertObject:[BJLUser displayNameOfName:self.choosenUser.name] atIndex:1];
        self.candidates = [mutableCandidates copy];
    }
    else if ([mutableCandidates count] == 1) {
        [mutableCandidates bjl_addObject:[BJLUser displayNameOfName:self.choosenUser.name]];
        self.candidates = [mutableCandidates copy];
    }
    else {
        self.candidates = @[[BJLUser displayNameOfName:self.choosenUser.name]];
    }
    self.CellCount = MAX(4, [self.candidates count]);
    self.leftOffset = self.CellCount * kCellHeight * 16;
}

- (void)makeConstraints {
    self.view.backgroundColor = [UIColor clearColor];

    // top bar
    [self.topBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@(BJLIcAppearance.userWindowDefaultBarHeight));
    }];

    UIView *topGapLine = [UIView bjlic_createSeparateLine];
    [self.view addSubview:topGapLine];
    [topGapLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.topBar);
        make.top.equalTo(self.topBar.bjl_bottom);
        make.height.equalTo(@1.0);
    }];

    self.cornerView = ({
        UIView *cornerView = [UIView new];
        cornerView.layer.cornerRadius = 4;
        cornerView.layer.borderColor = BJLIcTheme.separateLineColor.CGColor;
        cornerView.layer.borderWidth = 1.0;
        cornerView.accessibilityLabel = BJLKeypath(self, cornerView);
        cornerView;
    });
    [self.view addSubview:self.cornerView];
    [self.cornerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.view).offset(50);
        make.right.equalTo(self.view).offset(-50);
        make.top.equalTo(topGapLine.bjl_bottom).offset(25);
        make.height.equalTo(@(3 * kCellHeight));
    }];
    
    self.tableViewContainerView = ({
        UIView *tableViewContainerView = [UIView new];
        tableViewContainerView.layer.cornerRadius = 4;
        tableViewContainerView.clipsToBounds = YES;
        tableViewContainerView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
        tableViewContainerView.accessibilityLabel = BJLKeypath(self, tableViewContainerView);
        tableViewContainerView;
    });
    [self.view addSubview:self.tableViewContainerView];
    [self.tableViewContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.cornerView).insets(UIEdgeInsetsMake(10, 10, 10, 10));
    }];

    self.tableView1 = ({
        UITableView *tableView = [UITableView new];
        tableView.backgroundColor = [UIColor clearColor];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.userInteractionEnabled = NO;
        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
        tableView;
    });
    
    self.tableView2 = ({
        UITableView *tableView = [UITableView new];
        tableView.backgroundColor = [UIColor clearColor];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.userInteractionEnabled = NO;
        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
        tableView;
    });

    [self.tableViewContainerView addSubview:self.tableView1];
    [self.tableViewContainerView addSubview:self.tableView2];
    [self.tableView1 bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.cornerView);
        make.top.equalTo(self.cornerView);
        make.height.equalTo(@(self.CellCount * kCellHeight));
    }];
    
    [self.tableView2 bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.cornerView);
        make.top.equalTo(self.tableView1.bjl_bottom);
        make.height.equalTo(@(self.CellCount * kCellHeight));
    }];
    
    // 分割线
    UIView *gapLine1 = [UIView new];
    gapLine1.backgroundColor = [UIColor bjl_colorWithHexString:@"9FA8B5" alpha:0.1];
    UIView *gapLine2 = [UIView new];
    gapLine2.backgroundColor = [UIColor bjl_colorWithHexString:@"9FA8B5" alpha:0.1];

    [self.tableViewContainerView addSubview:gapLine1];
    [self.tableViewContainerView addSubview:gapLine2];
    [gapLine1 bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.cornerView);
        make.height.equalTo(@(1.0));
        make.top.equalTo(self.cornerView).offset(kCellHeight);
    }];
    [gapLine2 bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.height.equalTo(gapLine1);
        make.bottom.equalTo(self.cornerView).offset(-kCellHeight);
    }];
    
    self.closeButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = BJLIcAppearance.toolboxCornerRadius;
        button.layer.masksToBounds = YES;
        button.hidden = YES;
        button.accessibilityLabel = BJLKeypath(self, closeButton);
        button.backgroundColor = [BJLIcTheme brandColor];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitle:@"关闭" forState:UIControlStateNormal];
        [button setTitle:@"关闭" forState:UIControlStateNormal | UIControlStateHighlighted];
        [button setTitleColor:BJLIcTheme.buttonTextColor forState:UIControlStateNormal | UIControlStateHighlighted];
        [button addTarget:self action:@selector(closeRandomAnmated) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    
    UIView *closeView = [BJLHitTestView new];
    [self.view addSubview:closeView];
    [closeView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.cornerView.bjl_bottom);
        make.width.centerX.bottom.equalTo(self.view);
    }];
    [self.view addSubview:self.closeButton];
    
    [self.closeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(closeView);
        make.width.equalTo(@(120));
        make.height.equalTo(@(32));
        make.bottom.lessThanOrEqualTo(self.view.bjl_bottom);
    }];
}

- (void)updateConstraints {
    [self.tableView1 bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@(self.CellCount * kCellHeight));
    }];
    
    [self.tableView2 bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@(self.CellCount * kCellHeight));
    }];
}

#pragma mark - timer

- (void)closeRandomAnmated {
    [self stopCountDownTimer];
    [self closeWithoutRequest];
}

- (void)startRandomAnmated {
    // 停止动画time
    [self stopCountDownTimer];
    // 复原tbaleview
    [self resetTableView];

    // 关闭按钮隐藏
    self.closeButton.hidden = YES;

    bjl_weakify(self);
    __block CGFloat time = kTime;
    self.timer = [NSTimer bjl_scheduledTimerWithTimeInterval:kPerTime repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        time -= kPerTime;

        if (self.leftOffset <= 0) {
            [timer invalidate];
            [self stopCountDownTimer];
            // 动画结束时,突出第二行即目标用户的选中效果
            UITableViewCell *cell = [self.tableView1 cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            cell.textLabel.font = [UIFont systemFontOfSize:16];
            cell.textLabel.textColor = BJLIcTheme.viewTextColor;
            
            self.closeButton.hidden = NO;
        }
        else {
            [self updateTableView];
        }
    }];
}

- (void)stopCountDownTimer {
    if (self.timer || [self.timer isValid]) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)resetTableView {
    CGRect tableview1Frame = self.tableView1.frame;
    tableview1Frame.origin.y = -10;
    self.tableView1.frame = tableview1Frame;
    [self.tableView1 reloadData];
    
    CGRect tableview2Frame = self.tableView2.frame;
    tableview1Frame.origin.y = self.tableView1.frame.size.height + self.tableView1.frame.origin.y;
    self.tableView2.frame = tableview2Frame;
    [self.tableView2 reloadData];
}

/*
 leftOffset初始值为tableview的高度的整数倍, 就能保证偏移结束时, tableview的第二行正好展示在正中间突出选择效果
 每次取剩余偏移量的1/40, 偏移量最小值为kCellHeight/40.0, 当剩余偏移量比kCellHeight/40.0还小时,直接偏移剩余值,表示偏移结束
 偏移量越来越小造成一种第一步加速,后续慢慢减速的动态变化
 */
- (void)updateTableView {
    CGFloat willOffset = MAX(kCellHeight/40.0, self.leftOffset/40.0);

    if (self.leftOffset <= kCellHeight/40.0) {
        willOffset = self.leftOffset;
    }

    CGRect tableview1Frame = self.tableView1.frame;
    tableview1Frame.origin.y -= willOffset;
    
    if (tableview1Frame.origin.y <= -self.tableView2.frame.size.height) {
        tableview1Frame.origin.y = self.tableView2.frame.size.height + self.tableView2.frame.origin.y;
        tableview1Frame.origin.y -= willOffset;
    }
    self.tableView1.frame = tableview1Frame;
    
    CGRect tableview2Frame = self.tableView2.frame;
    tableview2Frame.origin.y -= willOffset;
    if (tableview2Frame.origin.y <= -self.tableView1.frame.size.height) {

        tableview2Frame.origin.y = self.tableView1.frame.size.height + self.tableView1.frame.origin.y;
    }
    self.tableView2.frame = tableview2Frame;
    self.leftOffset -= willOffset;
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.CellCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class]) forIndexPath:indexPath];
    NSInteger index = indexPath.row % [self.candidates count];
    cell.textLabel.text = [self.candidates bjl_objectAtIndex:index];
    cell.textLabel.textColor = BJLIcTheme.viewSubTextColor;
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 1.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kCellHeight;
}

@end
