//
//  BJLRainScene.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/7/2.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLRainScene.h"
#import "BJLRainNode.h"
#import "BJLScAppearance.h"
#import "BJLViewControllerImports.h"

static const CGFloat acceleration = 9.8; // 固定 9.8 的加速度，与物理空间加速度一致
static const CGFloat duration = 3.0; // 3s 显示时长
static const CGFloat durationInterval = 0.5; // 0.5s 的浮动时长
static const CGFloat rainAreaRatio = 1.0 / 30; // 雨水尺寸为场景可见尺寸的 1.0 / 30

@interface BJLTrackPoint : NSObject

@property (nonatomic) CGPoint point;
@property (nonatomic) NSTimeInterval timeInterval;
@property (nonatomic, readonly) BOOL needRemoveFromDataSource;

@end

@implementation BJLTrackPoint

- (instancetype)initWithPoint:(CGPoint)point {
    if (self = [super init]) {
        self.point = point;
        self.timeInterval = [NSDate timeIntervalSinceReferenceDate];
    }
    return self;
}

- (BOOL)needRemoveFromDataSource {
    if ([NSDate timeIntervalSinceReferenceDate] - self.timeInterval > 0.2) {
        return YES;
    }
    return NO;
}

@end

@interface BJLRainScene () <SKPhysicsContactDelegate>

@property (nonatomic) CGSize visibleSize; // 可见尺寸，这个尺寸可以动态修改，切换横竖屏时需要修改，暂未支持
@property (nonatomic) NSString *rainImageName; // 雨水图片
// param
@property (nonatomic) NSInteger rainCount; // 可见区域预期雨水总数量
@property (nonatomic) CGSize rainSize, expectedRainSize; // 雨水大小，根据可见区域计算的雨水大小
@property (nonatomic) CGFloat minSpeed, maxSpeed; // 可见区域的最小和最大的初始速度
@property (nonatomic) BOOL willRain; // 是否下雨，控制刷新雨水的频率

// node
@property (nonatomic) SKNode *rainNode;
@property (nonatomic) NSMutableArray<SKTexture *> *animateTexture;

// track
@property (nonatomic) NSMutableArray<BJLTrackPoint *> *trackPoints; // 手势的轨迹
@property (nonatomic, nullable) SKShapeNode *trackNode;

@end

@implementation BJLRainScene

+ (instancetype)sceneWithSize:(CGSize)size rainImageName:(NSString *)rainImageName rainCount:(NSInteger)rainCount rainSize:(CGSize)rainSize visibleSize:(CGSize)visibleSize {
    return [[self alloc] initWithSize:size rainImageName:rainImageName rainCount:rainCount rainSize:rainSize visibleSize:visibleSize];
}

- (instancetype)initWithSize:(CGSize)size rainImageName:(NSString *)rainImageName rainCount:(NSInteger)rainCount rainSize:(CGSize)rainSize visibleSize:(CGSize)visibleSize {
    if (self = [super initWithSize:visibleSize]) {
        self.visibleSize = visibleSize;
        self.rainSize = rainSize;
        self.rainCount = rainCount;
        self.rainImageName = rainImageName;
        self.totalScore = 0;
        self.trackPoints = [NSMutableArray new];
        [self prepareForScene];
    }
    return self;
}

- (void)prepareForScene {
    // 坐标系是数学直角坐标系，左下角为原点，调整加速度为每 pt 9.8 左右的值
    self.physicsWorld.gravity = CGVectorMake(0, -0.066);
    self.physicsWorld.contactDelegate = self;
    self.backgroundColor = [SKColor clearColor];
    self.scaleMode = SKSceneScaleModeAspectFill;
    
    // 下雨场景可见区域
    CGFloat width = self.visibleSize.width;
    CGFloat height = self.visibleSize.height;
    // 雨水图片比例
    CGFloat rainRatio = self.rainSize.width / self.rainSize.height;
    
    CGFloat maxDuration = duration + durationInterval;
    CGFloat minDuration = duration - durationInterval;
    
    // w = (w1 / h1) * h, h * w = area * rainAreaRatio 根据雨水占屏幕的预期比例，计算出雨水高度
    CGFloat expectedRainHeight = sqrt(width * height * rainAreaRatio / rainRatio);
    CGFloat expectedRainWidth = expectedRainHeight * rainRatio;
    self.expectedRainSize = CGSizeMake(expectedRainWidth, expectedRainHeight);
    
    // h = 1/2 * a * t^2 + v * t 计算出在下雨场景的可见区域雨水显示的最短和最长时长的入场初速度
    self.minSpeed = ((height + expectedRainHeight) - acceleration * pow(maxDuration, 2.0) / 2) / maxDuration;
    self.maxSpeed = ((height + expectedRainHeight) - acceleration * pow(minDuration, 2.0) / 2) / minDuration;
        
    self.willRain = YES;
    self.rainNode = [SKNode node];
    [self addChild:self.rainNode];
    [self createRainNode];
}

- (void)getMaxInvisibleSpeed:(CGFloat *)maxInvisibleSpeed minInvisibleSpeed:(CGFloat *)minInvisibleSpeed withYPosition:(CGFloat)yPosition {
    // t = (-v + sqrt(v^2 - 4 * a/2 * (-y))) / 2 * a/2  最长的不可见区域加速时间，由最大的初速度决定，最小的不可见区域加速时间为0
    CGFloat maxInvisibleDuration = (self.minSpeed - sqrt(pow(self.minSpeed, 2.0) - 2 * acceleration * yPosition)) / acceleration;
    
    *maxInvisibleSpeed = self.maxSpeed - maxInvisibleDuration * acceleration; // 经过了最长的时间也只能加速到最快的速度，这个为最大值，不能更大
    *minInvisibleSpeed = self.minSpeed - maxInvisibleDuration * acceleration; // 没有经过任何时间也要有最慢的速度，这个是最小值，不能更小
}

- (void)update:(NSTimeInterval)currentTime {
    NSMutableArray *rainToRemove = [NSMutableArray new];
    for (BJLRainNode *node in [self.rainNode.children copy]) {
        if (node.position.y < self.visibleSize.height + self.expectedRainSize.height
                 && node.position.y > 0) {
        }
        else if (node.position.y < -0.0) {
            [rainToRemove bjl_addObject:node];
        }
    }
    if (rainToRemove.count > 0) {
        [self.rainNode removeChildrenInArray:rainToRemove];
    }
    [self createRainNode];
    [self removeTrackPoints];
}

- (void)createRainNode {
    if (!self.willRain) {
        return;
    }
    self.willRain = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.willRain = YES;
    });
    
    // 需要掉落的雨水数量不大于每行预计的雨水数量
    NSInteger count = self.rainCount;
    self.totalNodeCount += count;
    for (NSInteger i = 0; i < count; i ++) {
        CGFloat x = (CGFloat)arc4random_uniform(self.visibleSize.width * 0.8) + self.visibleSize.width * 0.1; // 随机 x 轴位置
        CGFloat y = (CGFloat) ((NSInteger)arc4random_uniform(self.visibleSize.height * 10) % (NSInteger)self.visibleSize.height); // 随机 y 轴位置，但至少要在可视距离外初始化
        CGPoint position = CGPointMake(x, y + self.visibleSize.height + self.expectedRainSize.height);
        CGFloat zPosition = (CGFloat)arc4random_uniform(100) - 50.0; // 随机 z 轴位置
        CGFloat maxInvisibleSpeed = self.maxSpeed;
        CGFloat minInvisibleSpeed = self.minSpeed;
        [self getMaxInvisibleSpeed:&maxInvisibleSpeed minInvisibleSpeed:&minInvisibleSpeed withYPosition:y];
        CGFloat speed = (CGFloat)arc4random_uniform(maxInvisibleSpeed - minInvisibleSpeed) + minInvisibleSpeed;
        BJLRainNode *rainNode = [[BJLRainNode alloc] initWithImageName:self.rainImageName size:self.expectedRainSize];
        rainNode.position = position;
        rainNode.zPosition = zPosition;
        [self.rainNode addChild:rainNode];
        // 需要在添加了节点之后给一个冲击速度
        [rainNode setupVelocity:CGVectorMake(0, -speed)];
    }
}

#pragma mark - touch

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self tryToRemoveNodeWithTouches:touches];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self tryToRemoveNodeWithTouches:touches];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self tryToRemoveNodeWithTouches:touches];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self tryToRemoveNodeWithTouches:touches];
}

#pragma mark -

- (void)tryToRemoveNodeWithTouches:(NSSet<UITouch *> *)touches {
    if (!self.userInteractionEnabled) {
        return;
    }
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInNode:self];
    [self addTrackPoint:point];
    [self drawTrackPoint];
    for (BJLRainNode *node in [self.rainNode.children copy]) {
        CGRect nodeFrame = node.frame;
        if (node.alpha >= 1.0 && [node containsPoint:point]) {
            self.totalHitCount++;
            node.alpha = 0.0;
            CGPoint center = CGPointMake(nodeFrame.origin.x + nodeFrame.size.width / 2.0, nodeFrame.origin.y + nodeFrame.size.height / 2.0);
            if (self.requestOpenEnvelopeScoreCallback) {
                bjl_weakify(self);
                self.requestOpenEnvelopeScoreCallback(^(NSInteger score) {
                    bjl_strongify(self);
                    if (score > 0) {
                        self.scoreHitCount++;
                        [self showOpenEnvelopAnimation:center score:score];
                        [self storeScore:score];
                    }
                });
            }
            break; // only affect one envelope
        }
    }
}

#pragma mark - track

- (void)drawTrackPoint {
    [self.trackNode removeFromParent];
    if (!self.trackPoints.count) {
        return;
    }
    self.trackNode.path = [self updatePathWithLineWidth:4.0].CGPath;
    [self addChild:self.trackNode];
}

- (UIBezierPath *)updatePathWithLineWidth:(CGFloat)lineWidth {
    UIBezierPath *upPath = [UIBezierPath bezierPath];
    UIBezierPath *downPath = [UIBezierPath bezierPath];
    
    BJLTrackPoint *startPoint = self.trackPoints.lastObject;
    [upPath moveToPoint:startPoint.point];
    [downPath moveToPoint:startPoint.point];
    
    for (NSInteger i = self.trackPoints.count - 2; i > 0; i--) {
        BJLTrackPoint *firstPoint = [self.trackPoints bjl_objectAtIndex:i];
        BJLTrackPoint *secondPoint = [self.trackPoints bjl_objectAtIndex:i - 1];
        
        CGFloat startLen = sqrt(pow(secondPoint.point.y - startPoint.point.y, 2.0) + pow(secondPoint.point.x - startPoint.point.x, 2.0));
        CGFloat infLen = sqrt(pow(firstPoint.point.y - startPoint.point.y, 2.0) + pow(firstPoint.point.x - startPoint.point.x, 2.0));
        
        CGFloat startX = (secondPoint.point.y - startPoint.point.y) / startLen;
        CGFloat startY = (secondPoint.point.x - startPoint.point.x) / startLen;
        
        CGFloat infX = (firstPoint.point.y - startPoint.point.y) / infLen;
        CGFloat infY = (firstPoint.point.x - startPoint.point.x) / infLen;
        
        CGFloat cta = (infX * startX + infY * startY);

        NSInteger index = self.trackPoints.count - 2 - i;
        CGFloat f = 1 / (0.04 * index * index + 0.09 * index + 1);
        CGFloat l = lineWidth * f;
        
        CGFloat verticalX = l / cta * startX;
        CGFloat verticalY = l / cta * startY;
        
        if (fabs(verticalX) > lineWidth) {
            verticalX = verticalX > 0 ? lineWidth : -lineWidth;
        }
        if (fabs(verticalY) > lineWidth) {
            verticalY = verticalY > 0 ? lineWidth : -lineWidth;
        }
        
        CGPoint upPoint = CGPointMake(firstPoint.point.x + verticalX, firstPoint.point.y + verticalY);
        CGPoint downPoint = CGPointMake(firstPoint.point.x - verticalX, firstPoint.point.y - verticalY);
        [upPath addLineToPoint:upPoint];
        [downPath addLineToPoint:downPoint];
        startPoint = firstPoint;
    }

    [upPath addLineToPoint:downPath.currentPoint];
    [upPath appendPath:downPath];
    return upPath;
}

- (void)addTrackPoint:(CGPoint)point {
    [self removeTrackPoints];
    BJLTrackPoint *trackPoint = [[BJLTrackPoint alloc] initWithPoint:point];
    [self.trackPoints addObject:trackPoint];
}

- (void)removeTrackPoints {
    while (self.trackPoints.count && self.trackPoints.firstObject.needRemoveFromDataSource) {
        [self.trackPoints removeObjectAtIndex:0];
    }
    [self drawTrackPoint];
}

- (SKShapeNode *)trackNode {
    if (!_trackNode) {
        _trackNode = ({
            SKShapeNode *shapeNode = [SKShapeNode node];
            shapeNode.name = BJLKeypath(self, trackNode);
            shapeNode.zPosition = 10000;
            shapeNode.lineJoin = kCGLineJoinRound;
            shapeNode.lineWidth = 1.0;
            shapeNode.antialiased = YES;
            shapeNode.strokeColor = [SKColor bjl_colorWithHex:0xF7B500];
            shapeNode.fillColor = [SKColor whiteColor];
            shapeNode;
        });
    }
    return _trackNode;
}

#pragma mark -

- (void)storeScore:(NSInteger)score {
    self.totalScore += score;
}

- (void)setCoinImageNames:(NSMutableArray<NSString *> *)coinImageNames {
    _coinImageNames = coinImageNames;
    self.animateTexture = [NSMutableArray new];
    for (NSString *imageName in coinImageNames) {
        SKTexture *texture = [SKTexture textureWithImageNamed:imageName];
        [self.animateTexture bjl_addObject:texture];
    }
}

- (void)showOpenEnvelopAnimation:(CGPoint)center score:(NSInteger)score {
    SKSpriteNode *imageNode = [SKSpriteNode new];
    imageNode.size = CGSizeMake(200.0, 200.0);
    imageNode.position = center;
    imageNode.zPosition = 1001;
    [self addChild:imageNode];
    SKAction *imageAction = [SKAction animateWithTextures:self.animateTexture timePerFrame:0.1];
    [imageNode runAction:imageAction];
    
    SKLabelNode *labelNode = [SKLabelNode labelNodeWithText:[NSString stringWithFormat:@"+%td", score]];
    labelNode.position = center;
    labelNode.zPosition = 1001;
    labelNode.fontSize = 24.0;
    labelNode.fontName = [UIFont systemFontOfSize:24.0].fontName;
    labelNode.fontColor = [UIColor whiteColor];
    [self addChild:labelNode];
    SKAction *labelAction = [SKAction moveToY:center.y + 20.0 duration:1.0];
    [labelNode runAction:labelAction];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [labelNode removeAllActions];
        [labelNode removeFromParent];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [imageNode removeAllActions];
        [imageNode removeFromParent];
    });
}

@end
