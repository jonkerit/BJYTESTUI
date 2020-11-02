//
//  BJLRainEffectViewController.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/7/2.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLScAppearance.h"
#import "BJLRainEffectViewController.h"
#import "BJLRainScene.h"
#import "BJLEnvelopeResultCell.h"

@interface BJLRainEffectViewController ()

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) SKView *rainView;
@property (nonatomic) BJLRainScene *rainScene;
@property (nonatomic) CGSize sceneSize;
@property (nonatomic) NSString *rainImageName;
@property (nonatomic) NSInteger rainCount;
@property (nonatomic) CGSize rainSize;
@property (nonatomic, readwrite) NSInteger envelopeID;
@property (nonatomic) NSInteger rainDuration;
@property (nonatomic) NSMutableArray<NSString *> *coinImageNames;

@property (nonatomic) NSString *openEnvelopeImageName;
@property (nonatomic) NSString *openEnvelopeEmptyImageName;
@property (nonatomic) CGSize openEnvelopeSize;
@property (nonatomic) CGSize openEnvelopeEmptySize;
// start delay
@property (nonatomic) UIView *delayRainTipView;
@property (nonatomic) UILabel *delayRainLabel;
@property (nonatomic) UILabel *delayRainTipLabel;
@property (nonatomic) NSTimer *delayRainTimer;
@property (nonatomic) NSInteger rainDelayTime;

// personalResult
@property (nonatomic) UIView *scoreResultView;
@property (nonatomic, nullable) UIView *noScoreView;
@property (nonatomic, nullable) UILabel *scoreLabel;

// end result
@property (nonatomic) NSArray<BJLEnvelopeRank *> *rankList;
@property (nonatomic) UIView *envelopeResultView;
@property (nonatomic) UITableView *resultTableView;
@property (nonatomic) UIView *emptyRankResultView;
@property (nonatomic) UIView *resultTableViewHeader;
@property (nonatomic) UIImageView *resultImageView;
@property (nonatomic) UIButton *closeButton;

@property (nonatomic) UIInterfaceOrientationMask orientationMask;
@property (nonatomic) BOOL enableReceiveRankingList;

@end

@implementation BJLRainEffectViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super init]) {
        self->_room = room;
        self.enableReceiveRankingList = YES;
    }
    return self;
}

- (instancetype)initWithRoom:(BJLRoom *)room envelopeID:(NSInteger)envelopeID duration:(NSInteger)duration {
    if (self = [self initWithRoom:room]) {
        self.envelopeID = envelopeID;
        self.rainDuration = duration;
        self.coinImageNames = [NSMutableArray new];
        self.rainDelayTime = BJLScRainDelay;
        // 确保和 root 的写法一致
        self.orientationMask = (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone
                                ? UIInterfaceOrientationMaskAllButUpsideDown
                                : UIInterfaceOrientationMaskAll);
        for (NSInteger i = 1; i <= 14; i ++) {
            NSString *imageName = [NSString stringWithFormat:@"bjl_ic_envelope_open%ld", (long)i];
            UIImage *image = [UIImage bjlsc_imageNamed:imageName];
            NSData *imageData = UIImagePNGRepresentation(image);
            NSString *imageFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:imageName];
            [imageData writeToFile:imageFilePath atomically:YES];
            [self.coinImageNames bjl_addObject:imageFilePath];
        }
    }
    return self;
}

- (void)dealloc {
    [self stopDelayRainTimer];
    self.resultTableView.delegate = nil;
    self.resultTableView.dataSource = nil;
}

- (void)setupRainEffectSize:(CGSize)size rainImageName:(NSString *)imageName rainCount:(NSInteger)count rainSize:(CGSize)rainSize {
    // 没有设置图片资源的情况下，取默认图片资源，转成 nsdata 后写入 APP temp 文件夹内，然后红包雨读取这个数据
    NSString *imageFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"bjl_ic_envelope_run.png"];
    if (!imageName.length) {
        UIImage *image = [UIImage bjlsc_imageNamed:@"bjl_ic_envelope_run"];
        NSData *imageData = UIImagePNGRepresentation(image);
        [imageData writeToFile:imageFilePath atomically:YES];
        imageName = imageFilePath;
    }
    self.sceneSize = size;
    self.rainImageName = imageName;
    self.rainCount = count;
    self.rainSize = rainSize;
}

- (void)setOpenEnvelopeImageName:(nullable NSString *)imageName emptyImageName:(nullable NSString *)emptyImageName size:(CGSize)size emptySize:(CGSize)emptySize {
    UIImage *image = [UIImage imageNamed:imageName];
    if (!image) {
        imageName = nil;
    }
    UIImage *emptyImage = [UIImage imageNamed:emptyImageName];
    if (!emptyImage) {
        emptyImageName = nil;
    }
    NSString *imageFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"bjl_ic_envelope_run.png"];
    if (!imageName.length) {
        UIImage *image = [UIImage bjlsc_imageNamed:@"bjl_ic_envelope_run"];
        NSData *imageData = UIImagePNGRepresentation(image);
        [imageData writeToFile:imageFilePath atomically:YES];
        imageName = imageFilePath;
        emptyImageName = imageFilePath;
    }
    self.openEnvelopeImageName = imageName;
    self.openEnvelopeEmptyImageName = emptyImageName;
    self.openEnvelopeSize = size;
    self.openEnvelopeEmptySize = emptySize;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    
    [self makeSubviewsAndConstraints];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIInterfaceOrientationMask orientationMask;
    UIInterfaceOrientation orientation;
    if (@available(iOS 13.0, *)) orientation = self.view.window.windowScene.interfaceOrientation;
    else orientation = UIApplication.sharedApplication.statusBarOrientation;
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            orientationMask = UIInterfaceOrientationMaskPortrait;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            orientationMask = UIInterfaceOrientationMaskLandscapeRight;
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            orientationMask = UIInterfaceOrientationMaskLandscapeLeft;
            break;
            
        default:
            orientationMask = UIInterfaceOrientationMaskAll;
            break;
    }
    self.orientationMask = orientationMask;
}

- (void)makeSubviewsAndConstraints {
    self.delayRainTipView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self.view addSubview:self.delayRainTipView];
    [self.delayRainTipView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.view);
    }];
    self.delayRainLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:72.0];
        label.text = [NSString stringWithFormat:@"%td", self.rainDelayTime];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label;
    });
    [self.delayRainTipView addSubview:self.delayRainLabel];
    [self.delayRainLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.delayRainTipView);
        make.height.equalTo(@74.0);
        make.centerX.equalTo(self.delayRainTipView);
    }];
    UIImageView *envelopeLeftView = [self makeEnvelopeImageViewWithName:@"bjl_ic_envelope_start"];
    UIImageView *envelopeRightView = [self makeEnvelopeImageViewWithName:@"bjl_ic_envelope_start"];
    UIImageView *envelopeCenterView = [self makeEnvelopeImageViewWithName:@"bjl_ic_envelope_start"];
    [self.delayRainTipView addSubview:envelopeCenterView];
    [envelopeCenterView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.delayRainLabel.bjl_bottom).offset(15.0);
        make.centerX.equalTo(self.delayRainTipView);
        make.height.equalTo(@191.0);
        make.width.equalTo(@144.0);
    }];
    [self.delayRainTipView insertSubview:envelopeLeftView belowSubview:envelopeCenterView];
    [envelopeLeftView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.equalTo(envelopeCenterView).offset(-9.0);
        make.width.equalTo(@114.0);
        make.height.equalTo(@151.0);
        make.right.equalTo(envelopeCenterView.bjl_left).offset(15.0);
    }];
    [self.delayRainTipView insertSubview:envelopeRightView belowSubview:envelopeCenterView];
    [envelopeRightView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.equalTo(envelopeCenterView).offset(-9.0);
        make.width.equalTo(@114.0);
        make.height.equalTo(@151.0);
        make.left.equalTo(envelopeCenterView.bjl_right).offset(-15.0);
    }];
    self.delayRainTipLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.text = @"抢红包啦";
        label.font = [UIFont systemFontOfSize:18.0];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label;
    });
    [envelopeCenterView addSubview:self.delayRainTipLabel];
    [self.delayRainTipLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(envelopeCenterView.bjl_centerX);
        make.bottom.equalTo(envelopeCenterView.bjl_bottom).offset(-29.0);
    }];
    UIView *cutView = ({
        UIView *view = [UIView new];
        view;
    });
    [self.delayRainTipView addSubview:cutView];
    [cutView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(envelopeCenterView.bjl_bottom).offset(3.0);
        make.width.equalTo(@274.0);
        make.height.equalTo(@74.0);
        make.centerX.equalTo(self.delayRainTipView);
        make.bottom.equalTo(self.delayRainTipView);
    }];
    CAShapeLayer *popoverLayer = [self makePopoverLayerWithSize:CGSizeMake(274.0, 74.0)];
    [cutView.layer addSublayer:popoverLayer];
    
    UILabel *cutTipLabel = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        NSMutableAttributedString *cutTipString = [NSMutableAttributedString new];
        NSTextAttachment *attach = [NSTextAttachment new];
        attach.bounds = CGRectMake(0, -10.0, 50.0, 40.0);
        attach.image = [UIImage bjlsc_imageNamed:@"bjl_ic_envelope_cut"];
        NSAttributedString *imageString = [NSAttributedString attributedStringWithAttachment:attach];
        [cutTipString appendAttributedString:imageString];
        NSAttributedString *tipString = [[NSAttributedString alloc] initWithString:@"也可以切红包哦~"
                                                                        attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18.0],
                                                                                     NSForegroundColorAttributeName : [UIColor whiteColor]}];
        [cutTipString appendAttributedString:tipString];
        label.attributedText = cutTipString;
        label;
    });
    [cutView addSubview:cutTipLabel];
    [cutTipLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(cutView);
        make.height.equalTo(@(74.0 - 20.0));
    }];
    // fire
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 / 6.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startDelayRainTimer];
    });
}

- (UIImageView *)makeEnvelopeImageViewWithName:(NSString *)name {
    UIImageView *imageView = [UIImageView new];
    imageView.image = [UIImage bjlsc_imageNamed:name];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    return imageView;
}

- (CAShapeLayer *)makePopoverLayerWithSize:(CGSize)size {
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(size.width / 2.0, 0.0)];
    CGFloat shapeHeight = 20.0;
    CGFloat contentHeight = size.height - shapeHeight;
    CGPoint leftPoint = CGPointMake(size.width / 2.0 - shapeHeight * sin(M_PI / 3), shapeHeight);
    [bezierPath addLineToPoint:leftPoint];
    [bezierPath addLineToPoint:CGPointMake(contentHeight / 2.0, shapeHeight)];
    [bezierPath moveToPoint:CGPointMake(contentHeight / 2.0, shapeHeight)];
    [bezierPath addArcWithCenter:CGPointMake(contentHeight / 2.0, shapeHeight + contentHeight / 2.0) radius:contentHeight / 2.0 startAngle:-M_PI / 2 endAngle:-3 * M_PI / 2 clockwise:NO];
    [bezierPath moveToPoint:CGPointMake(contentHeight / 2.0, size.height)];
    [bezierPath addLineToPoint:CGPointMake(size.width - contentHeight / 2.0, size.height)];
    [bezierPath addArcWithCenter:CGPointMake(size.width - contentHeight / 2.0, size.height - contentHeight / 2.0) radius:contentHeight / 2.0 startAngle:- 3 * M_PI / 2 endAngle:-M_PI / 2 clockwise:NO];
    [bezierPath moveToPoint:CGPointMake(size.width - contentHeight / 2.0, size.height - contentHeight)];
    CGPoint rightPoint = CGPointMake(size.width / 2.0 - shapeHeight * sin(M_PI / 12), shapeHeight);
    [bezierPath addLineToPoint:rightPoint];
    [bezierPath addLineToPoint:CGPointMake(size.width / 2.0, 0.0)];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.lineCap = kCALineCapRound;
    layer.lineJoin = kCALineJoinRound;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.strokeColor = [UIColor whiteColor].CGColor;
    layer.path = bezierPath.CGPath;
    return layer;
}

- (void)makeReadyAnimation {
    self.delayRainLabel.text = @"GO";
    CGAffineTransform zoomOut = CGAffineTransformMakeScale(2.0, 2.0);
    [UIView animateWithDuration:1.0 / 6.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.delayRainLabel.alpha = 0.0;
        self.delayRainLabel.transform = zoomOut;
    } completion:^(BOOL finished) {
        [self.delayRainTipView removeFromSuperview];
    }];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.orientationMask;
}

#pragma mark - timer

- (void)startDelayRainTimer {
    [self stopDelayRainTimer];
    bjl_weakify(self);
    self.delayRainTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1.0
                                                              repeats:YES
                                                                block:^(NSTimer * _Nonnull timer) {
        bjl_strongify_ifNil(self) {
            [timer invalidate];
            return;
        }
        [self updateDelayLabel];
    }];
}

- (void)stopDelayRainTimer {
    if (self.delayRainTimer) {
        [self.delayRainTimer invalidate];
        self.delayRainTimer = nil;
    }
}

- (void)updateDelayLabel {
    self.rainDelayTime--;
    if (self.rainDelayTime == 0) {
        [self makeReadyAnimation];
        [self makeRainScene];
        [self stopDelayRainTimer];
        return;
    }
    self.delayRainLabel.text = [NSString stringWithFormat:@"%td", self.rainDelayTime];
}

#pragma mark - scene

- (void)makeRainScene {
    if (self.rainView) {
        return;
    }
    self.rainView = [SKView new];
    [self.view addSubview:self.rainView];
    self.rainView.allowsTransparency = YES;
    self.rainView.backgroundColor = [UIColor clearColor];
    [self.rainView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    self.rainView.ignoresSiblingOrder = YES;
    self.rainScene = [BJLRainScene sceneWithSize:self.sceneSize rainImageName:self.rainImageName rainCount:self.rainCount rainSize:self.rainSize visibleSize:self.view.bounds.size];
    self.rainScene.userInteractionEnabled = self.room.loginUser.isStudent;
    bjl_weakify(self);
    [self.rainScene setRequestOpenEnvelopeScoreCallback:^(BJLOpenEnvelopeScoreCompletion _Nonnull completion) {
        bjl_strongify(self);
        [self.room.roomVM grapEnvelopeWithID:self.envelopeID completion:^(NSInteger score, BJLError * _Nullable error) {
            completion(score);
        }];
    }];
    self.rainScene.coinImageNames = self.coinImageNames;
    [self.rainView presentScene:self.rainScene];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.rainDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self removeRainScene];
    });
}

- (void)removeRainScene {
    BOOL rainSceneOnScreen = (self.rainView.superview != nil);
    if (rainSceneOnScreen) {
        [self.rainScene removeFromParent];
        [self.rainView removeFromSuperview];
        //跳转到本地得分页面，收到排行榜信令之后再显示排行榜
        if (self.room.loginUser.isStudent) {
            [self makeEnvelopeResultViewAndConstraints:self.rainScene.totalScore];
        }
        else {
            if (self.rankList.count > 0) {
                [self showEnvelopeRankResultViewWithData: self.rankList];
            }
            else {
                [self showRankingListViewAndSendQueryRequest];
            }
        }
    }
}

- (void)didReceiveRankList:(NSArray<BJLEnvelopeRank *> *)rankList {
    if (!self.enableReceiveRankingList) {
        return;
    }
    
    BOOL rainEffectOnScreen = (self.rainScene.parent != nil);
    if (rainEffectOnScreen) {
        self.rankList = rankList;
        return;
    }
    
    BOOL resultViewOnScreen = (self.scoreResultView.superview != nil);
    if (self.room.loginUser.isStudent && resultViewOnScreen) {
        self.rankList = rankList;
    }
    else {
        [self showEnvelopeRankResultViewWithData:rankList];
    }
}

- (void)showEnvelopeRankResultViewWithData:(NSArray<BJLEnvelopeRank *> *)rankList {
    if (rankList.count <= 0) {
        return;
    }
    
    [self makeEnvelopeRankResultViewAndConstraints];
    
    self.rankList = rankList;
    [self updateEmptyRankResultViewHidden:rankList.count];
    [self.resultTableView reloadData];
}

- (void)closeResultViewAndShowRankingList {
    if (self.scoreResultView) {
        [self.scoreResultView removeFromSuperview];
        self.scoreResultView = nil;
        self.rainScene = nil;
        self.rainView = nil;
    }
    
    [self hideControllerOrShowRankViewIfNeeded:self.rankList];
}

- (void)showRankingListViewAndSendQueryRequest {
    self.enableReceiveRankingList = NO; //主动发起http请求的话，就关闭信令接收逻辑
    [self makeEnvelopeRankResultViewAndConstraints];
    [self reloadRankList];
}

- (void)hideControllerOrShowRankViewIfNeeded:(NSArray<BJLEnvelopeRank *> *)rankList {
    if (self.rankList.count > 0) {
        [self showEnvelopeRankResultViewWithData: self.rankList];
    }
    else {
        [self hide];
    }
}

- (void)makeEnvelopeResultViewAndConstraints:(NSInteger)score {
    self.scoreResultView = [UIView new];
    [self.view addSubview:self.scoreResultView];
    [self.scoreResultView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    UIImageView *imageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.image = score > 0 ? [UIImage bjlsc_imageNamed:@"bjl_ic_envelope"] : [UIImage bjlsc_imageNamed:@"bjl_ic_envelope_empty"];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView;
    });
    [self.scoreResultView addSubview:imageView];
    [imageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.scoreResultView);
        make.width.height.lessThanOrEqualTo(self.view).multipliedBy(0.8);
        make.width.equalTo(imageView.bjl_height).multipliedBy(imageView.image.size.width / imageView.image.size.height);
        make.width.equalTo(@(imageView.image.size.width)).priorityHigh();
        make.height.equalTo(@(imageView.image.size.height)).priorityHigh();
    }];
    UIButton *confirmButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        button.layer.cornerRadius = 22.0;
        button.layer.masksToBounds = YES;
        button.titleLabel.font = [UIFont systemFontOfSize:18.0];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitle:score > 0 ? @"完成" : @"再接再厉" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(closeResultViewAndShowRankingList) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.scoreResultView addSubview:confirmButton];
    [confirmButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@44.0);
        make.width.equalTo(@220.0).priorityHigh();
        make.width.lessThanOrEqualTo(imageView);
        make.centerX.equalTo(imageView);
        make.bottom.equalTo(imageView.bjl_bottom).multipliedBy(0.94);
    }];
    
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.rainScene, totalScore)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        imageView.image = self.rainScene.totalScore > 0 ? [UIImage bjlsc_imageNamed:@"bjl_ic_envelope"] : [UIImage bjlsc_imageNamed:@"bjl_ic_envelope_empty"];
        [confirmButton setTitle:self.rainScene.totalScore > 0 ? @"完成" : @"再接再厉" forState:UIControlStateNormal];
        [self makeScoreLabelWithImageView:imageView score:self.rainScene.totalScore];
        return YES;
    }];
    
    CGAffineTransform zoomIn = CGAffineTransformMakeScale(0.5, 0.5);
    self.scoreResultView.transform = zoomIn;
    [UIView animateWithDuration:0.8 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.scoreResultView.transform = CGAffineTransformIdentity;
    } completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self closeResultViewAndShowRankingList];
    });
}

- (void)makeScoreLabelWithImageView:(UIImageView *)imageView score:(NSInteger)score {
    if (!imageView) {
        return;
    }
    if (self.scoreLabel) {
        [self.scoreLabel removeFromSuperview];
        self.scoreLabel = nil;
    }
    if (self.noScoreView) {
        [self.noScoreView removeFromSuperview];
        self.noScoreView = nil;
    }
    if (score > 0) {
        UILabel *label = ({
            UILabel *label = [UILabel new];
            label.numberOfLines = 2;
            label.backgroundColor = [UIColor clearColor];
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineSpacing = 0.0;
            paragraphStyle.paragraphSpacing = 0.0;
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
            paragraphStyle.alignment = NSTextAlignmentCenter;
            NSMutableAttributedString *attributeString = [NSMutableAttributedString new];
            NSAttributedString *first = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%td", score]
                                                                        attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:96.0],
                                                                                     NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                                     NSParagraphStyleAttributeName: paragraphStyle
                                                                        }];
            NSAttributedString *follow = [[NSAttributedString alloc] initWithString:@" 学分"
                                                                         attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:24.0],
                                                                                      NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                                      NSParagraphStyleAttributeName: paragraphStyle
                                                                         }];
            NSAttributedString *last = [[NSAttributedString alloc] initWithString:@"\n抢到学分红包啦"
                                                                       attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:24.0],
                                                                                    NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                                    NSParagraphStyleAttributeName: paragraphStyle
                                                                       }];
            [attributeString appendAttributedString:first];
            [attributeString appendAttributedString:follow];
            [attributeString appendAttributedString:last];
            label.attributedText = attributeString;
            label;
        });
        [imageView addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(imageView);
            make.bottom.equalTo(imageView.bjl_centerY);
        }];
        self.scoreLabel = label;
    }
    else {
        self.noScoreView = ({
            UIView *view = [UIView new];
            view;
        });
        [imageView addSubview:self.noScoreView];
        [self.noScoreView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(imageView);
        }];
        
        UILabel *label = ({
            UILabel *label = [UILabel new];
            label.backgroundColor = [UIColor clearColor];
            label.text = @"一个都没抢到～";
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont systemFontOfSize:24.0];
            label.textAlignment = NSTextAlignmentCenter;
            label;
        });
        [self.noScoreView addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(imageView);
            make.height.equalTo(@33.0).priorityHigh();
            make.top.equalTo(imageView.bjl_centerY).offset(-4.0);
        }];
        
        UIImageView *emoticonView = ({
            UIImageView *imageView = [UIImageView new];
            imageView.image = [UIImage bjlsc_imageNamed:@"bjl_ic_envelope_emoticon"];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView;
        });
        [self.noScoreView addSubview:emoticonView];
        [emoticonView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(imageView);
            make.height.width.equalTo(@(136.0));
            make.bottom.equalTo(label.bjl_top);
        }];
    }
}

- (void)makeEnvelopeRankResultViewAndConstraints {
    if (self.envelopeResultView) {
        [self.envelopeResultView removeFromSuperview];
        self.envelopeResultView = nil;
    }
    
    self.envelopeResultView = ({
        UIView *view = [UIView new];
        view;
    });
    [self.view addSubview:self.envelopeResultView];
    [self.envelopeResultView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    
    UIImageView *envelopeResultImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.userInteractionEnabled = YES;
        imageView.image = [UIImage bjlsc_imageNamed:@"bjl_ic_envelope_result"];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView;
    });
    [self.envelopeResultView addSubview:envelopeResultImageView];
    [envelopeResultImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.envelopeResultView);
        make.width.height.lessThanOrEqualTo(self.view).multipliedBy(0.8);
        make.width.equalTo(@(envelopeResultImageView.image.size.width)).priorityHigh();
        make.height.equalTo(@(envelopeResultImageView.image.size.height)).priorityHigh();
        make.width.equalTo(envelopeResultImageView.bjl_height).multipliedBy(envelopeResultImageView.image.size.width / envelopeResultImageView.image.size.height);
    }];
    self.resultTableView = ({
        UITableView *tableView = [UITableView new];
        tableView.backgroundColor = [UIColor clearColor];
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [tableView registerClass:[BJLEnvelopeResultCell class] forCellReuseIdentifier:BJLEnvelopeResultCellReuseIdentifier];
        tableView;
    });
    [envelopeResultImageView addSubview:self.resultTableView];
    [self.resultTableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(envelopeResultImageView.bjl_right).multipliedBy(0.13);
        make.right.equalTo(envelopeResultImageView.bjl_right).multipliedBy(0.81);
        make.height.equalTo(envelopeResultImageView.bjl_height).multipliedBy(0.458);
        make.top.equalTo(envelopeResultImageView.bjl_bottom).multipliedBy(0.394);
    }];
    self.emptyRankResultView = ({
        UIView *view = [UIView new];
        view.hidden = YES;
        view.accessibilityLabel = BJLKeypath(self, emptyRankResultView);
        view.backgroundColor = [UIColor whiteColor];
        UIView *imageView = ({
            UIView *view = [BJLHitTestView new];
            view.backgroundColor = [UIColor clearColor];
            view;
        });
        [view addSubview:imageView];
        [imageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.center.width.equalTo(view);
            make.top.greaterThanOrEqualTo(view);
            make.bottom.lessThanOrEqualTo(view);
        }];

        UIImageView *emoticonView = ({
            UIImageView *imageView = [UIImageView new];
            imageView.image = [UIImage bjlsc_imageNamed:@"bjl_ic_envelope_emoticon"];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView;
        });
        [imageView addSubview:emoticonView];
        [emoticonView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.greaterThanOrEqualTo(imageView);
            make.centerX.equalTo(imageView);
        }];
        
        UILabel *label = ({
            UILabel *label = [UILabel new];
            label.backgroundColor = [UIColor clearColor];
            label.text = @"没人抢到～";
            label.textColor = [UIColor blackColor];
            label.font = [UIFont systemFontOfSize:24.0];
            label.textAlignment = NSTextAlignmentCenter;
            label;
        });
        [view addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(imageView);
            make.top.equalTo(emoticonView.bjl_bottom).offset(6.0);
            make.bottom.lessThanOrEqualTo(imageView);
        }];
        view;
    });
    [envelopeResultImageView addSubview:self.emptyRankResultView];
    [self.emptyRankResultView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.resultTableView);
    }];
    self.resultTableViewHeader = [self makeHeaderForRankTableView];
    [envelopeResultImageView addSubview:self.resultTableViewHeader];
    [self.resultTableViewHeader bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.equalTo(self.resultTableView.bjl_top).offset(-13.0);
        make.height.equalTo(@20.0).priorityHigh();
        make.right.equalTo(self.resultTableView);
        make.left.equalTo(self.resultTableView).offset(2.0);
    }];
    self.closeButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_ic_envelope_close"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [envelopeResultImageView addSubview:self.closeButton];
    [self.closeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.height.equalTo(@44.0);
        make.right.top.equalTo(envelopeResultImageView);
    }];
}

- (void)reloadRankList {
    static NSInteger totalReloadTimes = 3;
    bjl_weakify(self);
    [self.room.roomVM requestRankListWithEnvelopeID:self.envelopeID completion:^(NSArray<BJLEnvelopeRank *> * _Nullable rankList, BJLError * _Nullable error) {
        bjl_strongify(self);
        if (!self) {
            return;
        }
        if (!error) {
            self.rankList = rankList;
            [self updateEmptyRankResultViewHidden:rankList.count];
            [self.resultTableView reloadData];
        }
        totalReloadTimes --;
        if (totalReloadTimes <= 0) {
            totalReloadTimes = 3;
        }
        else {
            // 各端可能不同时开始结束，排行榜显示后最多刷新2次，如果存在更慢的端也不处理
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self reloadRankList];
            });
        }
    }];
}

- (void)updateEmptyRankResultViewHidden:(BOOL)hidden {
    self.emptyRankResultView.hidden = hidden;
    self.resultTableViewHeader.hidden = !hidden;
}

- (void)hide {
    [self bjl_removeFromParentViewControllerAndSuperiew];
}

#pragma mark - table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rankList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLEnvelopeResultCell *cell = [tableView dequeueReusableCellWithIdentifier:BJLEnvelopeResultCellReuseIdentifier forIndexPath:indexPath];
    BJLEnvelopeRank *rank;
    for (BJLEnvelopeRank *r in self.rankList) {
        if (r.rank == indexPath.row + 1) {
            rank = r;
            break;
        }
    }
    [cell configureWithRank:rank.rank
                   userName:[BJLUser displayNameOfName:rank.userName]
                      score:rank.score];
    return cell;
}

#pragma mark - table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.frame.size.height / 5.0;
}

- (UIView *)makeHeaderForRankTableView {
    UIView *view = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    UILabel *rankLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:13.0];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = @"排名";
        label;
    });
    [view addSubview:rankLabel];
    [rankLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(view);
        make.top.bottom.equalTo(view);
    }];
    UILabel *userNameLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:13.0];
        label.textColor = [UIColor whiteColor];
        label.text = @"用户";
        label.textAlignment = NSTextAlignmentCenter;
        label;
    });
    [view addSubview:userNameLabel];
    [userNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(view);
        make.top.bottom.equalTo(view);
    }];
    UILabel *scoreLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:13.0];
        label.textColor = [UIColor whiteColor];
        label.text = @"金币";
        label.textAlignment = NSTextAlignmentRight;
        label;
    });
    [view addSubview:scoreLabel];
    [scoreLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(view);
        make.top.bottom.equalTo(view);
    }];
    return view;
}

@end
