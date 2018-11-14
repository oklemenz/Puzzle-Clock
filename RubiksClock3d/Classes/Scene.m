//
//  Scene.m
//  RubiksClock3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2012. All rights reserved.
//

#import "Scene.h"
#import "cocos2d.h"
#import "CC3PODResourceNode.h"
#import "CC3ActionInterval.h"
#import "CC3MeshNode.h"
#import "CC3Camera.h"
#import "CC3Light.h"
#import "CC3ShadowVolumes.h"

#import "CCTouchDispatcher.h"
#import "CGPointExtension.h"

#import "AppDelegate.h"
#import "UserData.h"
#import "SoundManager.h"

#define kCameraZoomFactor 20.0
#define kCameraMinLocation 6.2
#define kCameraMaxLocation 200

#define kRotateSwipeFactor 0.6

#define kSpinFrictionFactor 1.0
#define kSpinMinSpeed 6.0
#define kSpinMaxSpeed 500.0

#define kTurnDirectionCW 0
#define kTurnDirectionCCW 1

#define kButtonDownOffset -0.32
#define kButtonUpOffset 0.32

#define kRotationSpeed 0.8
#define kAnimationSpeed 0.1

#define kSolveMoveTypeDeltaToZero  1
#define kSolveMoveTypeDeltaToAlign 2
#define kSolveMoveTypeDeltaToLast  3

#define kRotationDistance 10

#define degrees(x) (180 * x / M_PI)
#define random(min, max) (arc4random() % (max - min)) + min

typedef NS_OPTIONS(NSUInteger, ClockWheelIndex) {
    ClockWheelIndexTopLeft     = 0,
    ClockWheelIndexTopRight    = 1,
    ClockWheelIndexBottomLeft  = 2,
    ClockWheelIndexBottomRight = 3,
};

typedef NS_OPTIONS(NSUInteger, ClockButtonIndex) {
    ClockButtonIndexTopLeft     = 0,
    ClockButtonIndexTopRight    = 1,
    ClockButtonIndexBottomLeft  = 2,
    ClockButtonIndexBottomRight = 3,
};

typedef NS_OPTIONS(NSUInteger, ClockButtonMask) {
    ClockButtonMaskTopLeft     = (1 << 0), // 1
    ClockButtonMaskTopRight    = (1 << 1), // 2
    ClockButtonMaskBottomLeft  = (1 << 2), // 4
    ClockButtonMaskBottomRight = (1 << 3), // 8

    ClockButtonMaskNone        = 0, // 0
    ClockButtonMaskTop         = ClockButtonMaskTopLeft | ClockButtonMaskTopRight, // 3
    ClockButtonMaskBottom      = ClockButtonMaskBottomLeft | ClockButtonMaskBottomRight, //12
    ClockButtonMaskLeft        = ClockButtonMaskTopLeft | ClockButtonMaskBottomLeft, // 5
    ClockButtonMaskRight       = ClockButtonMaskTopRight | ClockButtonMaskBottomRight, // 10
    ClockButtonMaskDiagonalTL  = ClockButtonMaskTopLeft | ClockButtonMaskBottomRight, // 9
    ClockButtonMaskDiagonalBL  = ClockButtonMaskBottomLeft | ClockButtonMaskTopRight, // 6
    ClockButtonMaskAll         = ClockButtonMaskTopLeft | ClockButtonMaskTopRight |
                                 ClockButtonMaskBottomLeft | ClockButtonMaskBottomRight, // 15

    ClockButtonMaskAllButTL    = ClockButtonMaskAll - ClockButtonMaskTopLeft, // 14
    ClockButtonMaskAllButTR    = ClockButtonMaskAll - ClockButtonMaskTopRight, // 13
    ClockButtonMaskAllButBL    = ClockButtonMaskAll - ClockButtonMaskBottomLeft, // 11
    ClockButtonMaskAllButBR    = ClockButtonMaskAll - ClockButtonMaskBottomRight, // 7
};

@interface CC3Node (CustomData)
@property int nodeIndex;
@end

@interface Scene () {
}

@property(nonatomic, strong) CC3Node *mainNode;
@property(nonatomic, strong) CC3Node *spinNode;
@property(nonatomic, strong) CC3Node *pickedNode;
@property(nonatomic, strong) CC3Node *pickedWheel;

@property(nonatomic, strong) NSMutableArray *buttonInMove;
@property(nonatomic, strong) NSMutableArray *wheels;
@property(nonatomic, strong) NSMutableArray *wheelTouches;
@property(nonatomic, strong) NSMutableArray *buttons;
@property(nonatomic, strong) NSMutableArray *buttonTouches;
@property(nonatomic, strong) NSMutableArray *clocks;

@property(nonatomic, strong) NSArray *solveMatrix;

@property CGPoint lastTouchEventPoint;
@property struct timeval lastTouchEventTime;
@property CC3Vector spinAxis;
@property GLfloat spinSpeed;
@property CC3Vector cameraMoveStartLocation;

@property(nonatomic, strong) CMAttitude *referenceAttitude;
@property int referenceAttitudeCount;

@property(nonatomic, copy) void (^clockRotateCompletionHandler)();
@property(nonatomic, copy) void (^buttonPushCompletionHandler)();
@property(nonatomic, copy) void (^wheelTurnCompletionHandler)();

@property(getter = isInClockRotate) BOOL inClockRotate;
@property(getter = isInButtonPush) BOOL inButtonPush;
@property(getter = isInWheelTurn) BOOL inWheelTurn;

@property int pushButtonCount;
@property int turnWheelCount;
@property int turnClockCount;

@property int shuffleTurnCount;
@property int shuffleTurnIndex;

@property int solveClockIndex;
@property int solveClockMoveIndex;
@property int solveClockLastDelta;

@property BOOL faceFront;

@end

@implementation Scene

- (void)initializeScene {
	CC3Camera* cam = [CC3Camera nodeWithName:@"Camera"];
    cam.location = [UserData instance].location;
	[self addChild:cam];
    cam.nearClippingDistance = 0.2;

	CC3Light* lamp = [CC3Light nodeWithName:@"Lamp"];
	lamp.location = cc3v(20.0, 20, 100.0);
	lamp.isDirectionalOnly = NO ;
	[cam addChild:lamp];

	[self addContentFromPODFile:@"rubiksClock.pod"];
	[self createGLBuffers];
	[self releaseRedundantData];
    
    self.ambientLight = kCCC4FBlackTransparent;
    
    self.mainNode.isTouchEnabled = YES;
    self.mainNode.rotation = kInitialFrontRotation;
    
    CC3MeshNode *coverFront = (CC3MeshNode *)[self.mainNode getNodeNamed:@"FrameCoverFront"];
    coverFront.material.opacity = 60;
    coverFront.material.shininess = 100;
    
    CC3MeshNode *coverSide = (CC3MeshNode *)[self.mainNode getNodeNamed:@"FrameSideOuterTop1"];
    coverSide.material.opacity = 60;
    coverSide.material.shininess = 100;
    
    CC3MeshNode *frontInlay = (CC3MeshNode *)[self.mainNode getNodeNamed:@"FrontInlay"];
    frontInlay.material.texture = [CC3Texture textureFromFile:@"texture_front.png"];
    
    CC3MeshNode *backInlay = (CC3MeshNode *)[self.mainNode getNodeNamed:@"BackInlay"];
    backInlay.material.texture = [CC3Texture textureFromFile:@"texture_back.png"];
    
    self.buttons = [NSMutableArray new];
    for (int i = 0; i < 4; i++) {
        CC3Node *button = [self.mainNode getNodeNamed:[NSString stringWithFormat:@"Button%i", i+1]];
        button.nodeIndex = i;
        button.location = CC3VectorMake(button.location.x, kButtonUpOffset, button.location.z);
        button.isTouchEnabled = YES;
        //TODO: add shadow => Leads to assertion in released mesh (Cocos3d Bug?)
        //[self.button addShadowVolumesForLight:lamp];
        [self.buttons addObject:button];
    }
    
    self.buttonTouches = [NSMutableArray new];
    for (int i = 0; i < 4; i++) {
        CC3MeshNode *buttonTouch = (CC3MeshNode *)[self.mainNode getNodeNamed:[NSString stringWithFormat:@"Button%iTopTouch", i+1]];
        buttonTouch.nodeIndex = i;
        buttonTouch.isTouchEnabled = YES;
        buttonTouch.shouldAllowTouchableWhenInvisible = YES;
        buttonTouch.shouldCastShadowsWhenInvisible = NO;
        buttonTouch.ambientColor = kCCC4FBlackTransparent;
        buttonTouch.visible = NO;
        buttonTouch.material = nil;
        [self.buttonTouches addObject:buttonTouch];
    }
    for (int i = 0; i < 4; i++) {
        CC3MeshNode *buttonTouch = (CC3MeshNode *)[self.mainNode getNodeNamed:[NSString stringWithFormat:@"Button%iBottomTouch", i+1]];
        buttonTouch.nodeIndex = i;
        buttonTouch.isTouchEnabled = YES;
        buttonTouch.shouldAllowTouchableWhenInvisible = YES;
        buttonTouch.shouldCastShadowsWhenInvisible = NO;
        buttonTouch.ambientColor = kCCC4FBlackTransparent;
        buttonTouch.visible = NO;
        buttonTouch.material = nil;
        [self.buttonTouches addObject:buttonTouch];
    }

    self.wheels = [NSMutableArray new];
    for (int i = 0; i < 4; i++) {
        CC3MeshNode *wheel = (CC3MeshNode *)[self.mainNode getNodeNamed:[NSString stringWithFormat:@"Wheel%iRingMiddle", i+1]];
        wheel.nodeIndex = i;
        wheel.isTouchEnabled = YES;
        [self.wheels addObject:wheel];
    }

    self.wheelTouches = [NSMutableArray new];
    for (int i = 0; i < 4; i++) {
        CC3MeshNode *wheelTouch = (CC3MeshNode *)[self.mainNode getNodeNamed:[NSString stringWithFormat:@"Wheel%iTouch", i+1]];
        wheelTouch.nodeIndex = i;
        wheelTouch.isTouchEnabled = YES;
        wheelTouch.shouldAllowTouchableWhenInvisible = YES;
        wheelTouch.shouldCastShadowsWhenInvisible = NO;
        wheelTouch.ambientColor = kCCC4FBlackTransparent;
        wheelTouch.visible = NO;
        wheelTouch.material = nil;
        [self.wheelTouches addObject:wheelTouch];
    }
    
    self.clocks = [NSMutableArray new];
    for (int i = 0; i < 9; i++) {
        CC3Node *clock = [self.mainNode getNodeNamed:[NSString stringWithFormat:@"FrontClock%iBase", i+1]];
        clock.nodeIndex = i;
        [self.clocks addObject:clock];
    }
    for (int i = 0; i < 9; i++) {
        CC3Node *clock = [self.mainNode getNodeNamed:[NSString stringWithFormat:@"BackClock%iBase", i+1]];
        clock.nodeIndex = 9 + i;
        [self.clocks addObject:clock];
    }
    
    self.buttonInMove = [NSMutableArray arrayWithCapacity:4];
    for (int i = 0; i < 4; i++) {
        self.buttonInMove[i] = @(NO);
    }
    
    self.solveMatrix = @[
        // Front
        @{ @"c" : @(0), @"m" : @[ @{ @"b" : @(ClockButtonMaskTopLeft), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
        @{ @"c" : @(1), @"m" : @[ @{ @"b" : @(ClockButtonMaskTopRight), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
        @{ @"c" : @(2), @"m" : @[ @{ @"b" : @(ClockButtonMaskTopLeft), @"t" : @(kSolveMoveTypeDeltaToAlign) },
                                  @{ @"b" : @(ClockButtonMaskTop), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
        @{ @"c" : @(3), @"m" : @[ @{ @"b" : @(ClockButtonMaskBottomLeft), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
        @{ @"c" : @(5), @"m" : @[ @{ @"b" : @(ClockButtonMaskBottomRight), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
        @{ @"c" : @(6), @"m" : @[ @{ @"b" : @(ClockButtonMaskTopLeft), @"t" : @(kSolveMoveTypeDeltaToAlign) },
                                  @{ @"b" : @(ClockButtonMaskLeft), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
        @{ @"c" : @(8), @"m" : @[ @{ @"b" : @(ClockButtonMaskTopRight), @"t" : @(kSolveMoveTypeDeltaToAlign) },
                                  @{ @"b" : @(ClockButtonMaskRight), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
        // - Optional
        @{ @"c" : @(7), @"m" : @[ @{ @"b" : @(ClockButtonMaskBottomLeft), @"t" : @(kSolveMoveTypeDeltaToZero) },
                                  @{ @"b" : @(ClockButtonMaskBottomRight), @"t" : @(kSolveMoveTypeDeltaToLast) },
                                  @{ @"b" : @(ClockButtonMaskBottom), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
        @{ @"c" : @(4), @"m" : @[ @{ @"b" : @(ClockButtonMaskTopRight), @"t" : @(kSolveMoveTypeDeltaToZero) },
                                  @{ @"b" : @(ClockButtonMaskBottomLeft), @"t" : @(kSolveMoveTypeDeltaToLast) },
                                  @{ @"b" : @(ClockButtonMaskDiagonalBL), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
        // Back
        @{ @"c" : @(10), @"m" : @[ @{ @"b" : @(ClockButtonMaskAllButTL), @"t" : @(kSolveMoveTypeDeltaToZero) },
                                   @{ @"b" : @(ClockButtonMaskAllButTR), @"t" : @(kSolveMoveTypeDeltaToLast) },
                                   @{ @"b" : @(ClockButtonMaskBottom), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
        @{ @"c" : @(12), @"m" : @[ @{ @"b" : @(ClockButtonMaskAllButBR), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
        @{ @"c" : @(13), @"m" : @[ @{ @"b" : @(ClockButtonMaskAllButBL), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
        @{ @"c" : @(14), @"m" : @[ @{ @"b" : @(ClockButtonMaskAllButBR), @"t" : @(kSolveMoveTypeDeltaToAlign) },
                                   @{ @"b" : @(ClockButtonMaskTop), @"t" : @(kSolveMoveTypeDeltaToZero) }] },
        @{ @"c" : @(15), @"m" : @[ @{ @"b" : @(ClockButtonMaskAllButTR), @"t" : @(kSolveMoveTypeDeltaToAlign) },
                                   @{ @"b" : @(ClockButtonMaskLeft), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
        @{ @"c" : @(17), @"m" : @[ @{ @"b" : @(ClockButtonMaskAllButTL), @"t" : @(kSolveMoveTypeDeltaToAlign) },
                                   @{ @"b" : @(ClockButtonMaskRight), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
        @{ @"c" : @(16), @"m" : @[ @{ @"b" : @(ClockButtonMaskAllButBL), @"t" : @(kSolveMoveTypeDeltaToZero) },
                                   @{ @"b" : @(ClockButtonMaskAllButBR), @"t" : @(kSolveMoveTypeDeltaToLast) },
                                   @{ @"b" : @(ClockButtonMaskTop), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
        @{ @"c" : @(13), @"m" : @[ @{ @"b" : @(ClockButtonMaskAllButTL), @"t" : @(kSolveMoveTypeDeltaToZero) },
                                   @{ @"b" : @(ClockButtonMaskAllButBR), @"t" : @(kSolveMoveTypeDeltaToLast) },
                                   @{ @"b" : @(ClockButtonMaskDiagonalBL), @"t" : @(kSolveMoveTypeDeltaToZero) } ] },
    ];
}

- (CC3Node *)mainNode {
    if (!_mainNode) {
        _mainNode = [self getNodeNamed: @"RubiksClock"];
    }
    return _mainNode;
}

- (CC3Node *)button:(int)index {
    return self.buttons[index];
}

- (CC3Node *)wheel:(int)index {
    return self.wheels[index];
}

- (CC3Node *)clock:(int)index {
    return self.clocks[index];
}

- (void)setup {
    self.mainNode.rotation = [UserData instance].rotation;
    self.activeCamera.location = [UserData instance].location;
    [self iterateButtons:^(int bi) {
        CC3Node *button = ((CC3Node *)self.buttons[bi]);
        button.location = CC3VectorMake(button.location.x,
                                        [[UserData instance].buttonPos[bi] boolValue] ? kButtonUpOffset : kButtonDownOffset,
                                        button.location.z);
    }];
    [self iterateWheels:^(int wi) {
        ((CC3Node *)self.wheels[wi]).rotation =
            CC3VectorMake(0, [self convertPosToRotation:[[UserData instance].wheelPos[wi] intValue]], 0);
    }];
    [self iterateClocks:^BOOL(BOOL front, int di, int ci) {
        ((CC3Node *)self.clocks[ci]).rotation =
            CC3VectorMake(0, [self convertPosToRotation:[[UserData instance].clockPos[ci] intValue]], 0);
        return NO;
    }];
}

- (void)rotateToFront {
    [self rotateToFront:nil];
}

- (void)rotateToFront:(void (^)())handler {
    self.spinNode = nil;
    self.spinSpeed = 0;
    self.clockRotateCompletionHandler = handler;
    self.inClockRotate = YES;
    CC3Vector initialCmaeraLocation = !IS_IPHONE_4 ? kInitialCameraLocation1 : kInitialCameraLocation2;
    CCActionInterval *move = [CC3MoveTo actionWithDuration:kRotationSpeed moveTo:initialCmaeraLocation];
    [self.activeCamera runAction:move];
    if (CC3VectorDistance(self.mainNode.rotation, kInitialFrontRotation) > kRotationDistance) {
        CCActionInterval *rotate = [CC3RotateTo actionWithDuration:kRotationSpeed rotateTo:kInitialFrontRotation];
        [self.mainNode runAction:[CCSequence actions:rotate, [CCCallFuncN actionWithTarget:self selector:@selector(rotateClockDidEnd:)], nil]];
    } else {
        [self rotateClockDidEnd:self.mainNode];
    }
}

- (void)rotateToBack {
    [self rotateToBack:nil];
}

- (void)rotateToBack:(void (^)())handler {
    self.spinNode = nil;
    self.spinSpeed = 0;
    self.clockRotateCompletionHandler = handler;
    self.inClockRotate = YES;
    if (CC3VectorDistance(self.mainNode.rotation, kInitialBackRotation) > kRotationDistance) {
        CCActionInterval *rotate = [CC3RotateTo actionWithDuration:kRotationSpeed rotateTo:kInitialBackRotation];
        [self.mainNode runAction:[CCSequence actions:rotate, [CCCallFuncN actionWithTarget:self selector:@selector(rotateClockDidEnd:)], nil]];
    } else {
        [self rotateClockDidEnd:self.mainNode];
    }
}

- (void)rotateClockDidEnd:(CC3Node *)clock {
    self.inClockRotate = NO;
    if (self.clockRotateCompletionHandler) {
        void (^handler)() = self.clockRotateCompletionHandler;
        self.clockRotateCompletionHandler = nil;
        handler();
    }
}

- (void)startZoomCamera {
    self.cameraMoveStartLocation = self.activeCamera.location;
}

- (void)zoomCameraBy:(CGFloat)aMovement {
    GLfloat camMoveDist = logf(aMovement) * kCameraZoomFactor;
    CC3Vector moveVector = CC3VectorScaleUniform(self.activeCamera.globalForwardDirection, camMoveDist);
    self.activeCamera.location = CC3VectorAdd(self.cameraMoveStartLocation, moveVector);
    if (self.activeCamera.location.z < kCameraMinLocation) {
        self.activeCamera.location = cc3v(0, 0, kCameraMinLocation);
    } else if (activeCamera.location.z > kCameraMaxLocation) {
        self.activeCamera.location = cc3v(0, 0, kCameraMaxLocation);
    }
}

- (void)stopZoomCamera {
}

- (void)rotateZ:(CGFloat)degree andVelocity:(CGFloat)velocity {
    self.spinNode = self.mainNode;
    self.spinAxis = cc3v(0, 0, -velocity);
    self.spinSpeed = velocity * 20 * (velocity > 0 ? 1 : -1);
    [self.spinNode rotateByAngle:-degree aroundAxis:cc3v(0, 0, 1)];
}

- (void)spinRotateZ {
    self.spinNode = self.mainNode;
    self.pickedNode = nil;
}

#pragma mark Updating custom activity

- (void)updateBeforeTransform:(CC3NodeUpdatingVisitor*)visitor {
    [self.delegate updateTimer:visitor.deltaTime];
    if (self.spinNode) {
        GLfloat dt = visitor.deltaTime;
        if (self.spinNode) {
            if (self.spinSpeed > kSpinMinSpeed) {
                GLfloat deltaAngle = self.spinSpeed * dt;
                [self.spinNode rotateByAngle:deltaAngle aroundAxis:self.spinAxis];
                self.spinSpeed -= (deltaAngle * kSpinFrictionFactor);
            } else {
                self.spinNode = nil;
                self.spinSpeed = 0;
            }
        }
    }
    self.faceFront = ((CC3Node *)self.clocks[4]).globalLocation.z >= ((CC3Node *)self.clocks[13]).globalLocation.z;
    [UserData instance].rotation = self.mainNode.rotation;
    [UserData instance].location = self.activeCamera.location;
}

- (void)updateAfterTransform:(CC3NodeUpdatingVisitor*)visitor {
    CMMotionManager *motionManager = [AppDelegate instance].motionManager;
    if (!motionManager.isDeviceMotionActive || !motionManager.isGyroActive) {
        return;
    }
    
    CMDeviceMotion *deviceMotion = [AppDelegate instance].motionManager.deviceMotion;
    CMAttitude *attitude = deviceMotion.attitude;

    if (!attitude) {
        return;
    }
    
    if (!self.referenceAttitude) {
        self.referenceAttitudeCount++;
        if (self.referenceAttitudeCount >= 5) {
            self.referenceAttitude = attitude;
        }
        return;
    }
    
    CMAttitude *originalAttitude = [attitude copy];
    [attitude multiplyByInverseOfAttitude:self.referenceAttitude];
    self.referenceAttitude = originalAttitude;

    CC3Vector rotation = kCC3VectorZero;
    
    CGFloat degree1 = degrees(attitude.pitch) * 2;
    CGFloat degree2 = degrees(attitude.roll) * 2;
    
    switch ([self.delegate ccOrientation]) {
        case UIDeviceOrientationPortrait:
            rotation = CC3VectorMake(degree1, degree2, 0);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            rotation = CC3VectorMake(-degree1, -degree2, 0);
            break;
        case UIDeviceOrientationLandscapeLeft:
            rotation = CC3VectorMake(-degree2, degree1, 0);
            break;
        case UIDeviceOrientationLandscapeRight:
            rotation = CC3VectorMake(degree2, -degree1, 0);
            break;
        default:
            return;
    }
    
    [self.mainNode rotateBy:rotation];
    /*
    NSLog(@"<- %f", self.mainNode.rotation.z);
    rotation.x += self.mainNode.rotation.x;
    rotation.y += self.mainNode.rotation.y;
    rotation.z += self.mainNode.rotation.z;
    self.mainNode.rotation = rotation;*/
}

- (void)toggleGyro:(BOOL)state {
    CMMotionManager *motionManager = [AppDelegate instance].motionManager;
    if (state) {
        if (!motionManager.isDeviceMotionActive) {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
            [motionManager startDeviceMotionUpdates];
            if (!motionManager.isGyroActive) {
                motionManager.gyroUpdateInterval = 1.0 / 60.0;
                [motionManager startGyroUpdates];
            }
        }
    } else if (motionManager.isDeviceMotionActive) {
        [motionManager stopDeviceMotionUpdates];
        [motionManager stopGyroUpdates];
        self.referenceAttitude = nil;
        self.referenceAttitudeCount = 0;
    }
}

#pragma mark Scene opening and closing

- (void)onOpen {
}

- (void)onClose {
}

#pragma mark Handling touch events

- (void)touchEvent: (uint) touchType at: (CGPoint) touchPoint {
    struct timeval now;
    gettimeofday(&now, NULL);
    ccTime dt = (now.tv_sec - self.lastTouchEventTime.tv_sec) +
                (now.tv_usec - self.lastTouchEventTime.tv_usec) / 1000000.0f;
    BOOL reset = YES;
    switch (touchType) {
        case kCCTouchBegan:
            [self pickNodeFromTouchEvent:touchType at:touchPoint];
            break;
        case kCCTouchMoved:
            if (self.pickedNode) {
                reset = [self rotateNodeFromSwipeAt:touchPoint interval:dt];
            } else if (self.pickedWheel) {
                reset = [self rotateWheelFromSwipeAt:touchPoint interval:dt];
            }
            break;
        case kCCTouchEnded:
            [self touchEnded];
            break;
        default:
            break;
    }
    if (reset) {
        self.lastTouchEventPoint = touchPoint;
        self.lastTouchEventTime = now;
    }
}

- (void)initializeTouchPoint:(CGPoint)touchPoint {
    self.lastTouchEventPoint = touchPoint;
    struct timeval now;
    gettimeofday(&now, NULL);
    self.lastTouchEventTime = now;
}

- (void)touchEnded {
    if (self.pickedWheel) {
        [self gridWheel:self.pickedWheel];
        self.pickedWheel = nil;
    }
    if (self.pickedNode != nil) {
        self.spinNode = self.pickedNode;
        self.pickedNode = nil;
    }
}

- (void)nodeSelected:(CC3Node *)aNode byTouchEvent:(uint)touchType at:(CGPoint)touchPoint {
    if (!aNode) {
        return;
    }
    if ([aNode isEqual:self.mainNode]) {
        self.pickedNode = aNode;
        if (self.pickedNode) {
            self.spinNode = nil;
            self.spinSpeed = 0;
        }
    } else if (!self.controlDisabled) {
        for (CC3Node *button in self.buttons) {
            if ([button isEqual:aNode]) {
                [self pushButton:button];
                return;
            }
        }
        for (CC3Node *buttonTouch in self.buttonTouches) {
            if ([buttonTouch isEqual:aNode]) {
                [self pushButton:self.buttons[buttonTouch.nodeIndex]];
                return;
            }
        }
        for (CC3Node *wheel in self.wheels) {
            if ([wheel isEqual:aNode]) {
                self.pickedWheel = wheel;
                return;
            }
        }
        for (CC3Node *wheelTouch in self.wheelTouches) {
            if ([wheelTouch isEqual:aNode]) {
                self.pickedWheel = self.wheels[wheelTouch.nodeIndex];
                return;
            }
        }
    }
}

- (BOOL)rotateNodeFromSwipeAt:(CGPoint)touchPoint interval:(ccTime)dt {
    if (self.pickedNode && !self.inClockRotate) {
        CGPoint swipe2d = ccpSub(touchPoint, self.lastTouchEventPoint);
        CGPoint axis2d = ccpPerp(swipe2d);
        CC3Vector axis = CC3VectorAdd(CC3VectorScaleUniform(self.activeCamera.rightDirection, axis2d.x),
                                      CC3VectorScaleUniform(self.activeCamera.upDirection, axis2d.y));
        GLfloat angle = ccpLength(swipe2d) * kRotateSwipeFactor;
        [self.pickedNode rotateByAngle:angle aroundAxis:axis];
        //NSLog(@"(%f, %f, %f)", self.pickedNode.rotation.x, self.pickedNode.rotation.y, self.pickedNode.rotation.z);
        self.spinAxis = axis;
        CGPoint swipeVelocity = ccpSub(touchPoint, self.lastTouchEventPoint);
        self.spinSpeed = (angle / dt) * ccpLength(swipeVelocity) / 50;
        if (self.spinSpeed > kSpinMaxSpeed) {
            self.spinSpeed = kSpinMaxSpeed;
        }
        self.spinNode = nil;
    }
    return YES;
}

- (BOOL)pushButton:(CC3Node *)button {
    if ([self.buttonInMove[button.nodeIndex] boolValue] || self.isInWheelTurn) {
        return NO;
    }
    self.buttonInMove[button.nodeIndex] = @(YES);
    CCActionInterval *move = nil;
    if ([[UserData instance].buttonPos[button.nodeIndex] boolValue]) {
        move = [CC3MoveTo actionWithDuration:kAnimationSpeed moveTo:CC3VectorMake(button.location.x, kButtonDownOffset, button.location.z)];
        [[SoundManager instance] playButtonPushDownSound];
    } else {
        move = [CC3MoveTo actionWithDuration:kAnimationSpeed moveTo:CC3VectorMake(button.location.x, kButtonUpOffset, button.location.z)];
        [[SoundManager instance] playButtonPushUpSound];
    }
    [button runAction:[CCSequence actions:move, [CCCallFuncN actionWithTarget:self selector:@selector(pushButtonDidEnd:)], nil]];
    [UserData instance].buttonPos[button.nodeIndex] = @(![[UserData instance].buttonPos[button.nodeIndex] boolValue]);
    return YES;
}

- (void)pushButton:(int)buttonIndex complete:(void (^)())handler {
    self.buttonPushCompletionHandler = handler;
    [self pushButton:self.buttons[buttonIndex]];
}

- (void)pushButtons:(int)buttonMask complete:(void (^)())handler {
    Scene *scene = self;
    self.buttonPushCompletionHandler = ^() {
        scene.pushButtonCount--;
        if (scene.pushButtonCount == 0) {
            scene.inButtonPush = NO;
            scene.buttonPushCompletionHandler = nil;
            if (handler) {
                handler();
            }
        }
    };
    self.inButtonPush = YES;
    if (buttonMask & ClockButtonMaskTopLeft) {
        if ([self pushButton:self.buttons[ClockButtonIndexTopLeft]]) {
            self.pushButtonCount++;
        }
    }
    if (buttonMask & ClockButtonMaskTopRight) {
        if ([self pushButton:self.buttons[ClockButtonIndexTopRight]]) {
            self.pushButtonCount++;
        }
    }
    if (buttonMask & ClockButtonMaskBottomLeft) {
        if ([self pushButton:self.buttons[ClockButtonIndexBottomLeft]]) {
            self.pushButtonCount++;
        }
    }
    if (buttonMask & ClockButtonMaskBottomRight) {
        if ([self pushButton:self.buttons[ClockButtonIndexBottomRight]]) {
            self.pushButtonCount++;
        }
    }
    if (self.pushButtonCount == 0) {
        self.inButtonPush = NO;
        self.buttonPushCompletionHandler = nil;
        if (handler) {
            handler();
        }
    }
}

- (void)pushButtonsToState:(int)buttonMask complete:(void (^)())handler {
    Scene *scene = self;
    self.buttonPushCompletionHandler = ^() {
        scene.pushButtonCount--;
        if (scene.pushButtonCount == 0) {
            scene.inButtonPush = NO;
            scene.buttonPushCompletionHandler = nil;            
            if (handler) {
                handler();
            }
        }
    };
    self.inButtonPush = YES;
    BOOL state = (buttonMask & ClockButtonMaskTopLeft) ? YES : NO;
    if (state != [[UserData instance].buttonPos[ClockButtonIndexTopLeft] boolValue]) {
        if ([self pushButton:self.buttons[ClockButtonIndexTopLeft]]) {
            self.pushButtonCount++;
        }
    }
    state = (buttonMask & ClockButtonMaskTopRight) ? YES : NO;
    if (state != [[UserData instance].buttonPos[ClockButtonIndexTopRight] boolValue]) {
        if ([self pushButton:self.buttons[ClockButtonIndexTopRight]]) {
            self.pushButtonCount++;
        }
    }
    state = (buttonMask & ClockButtonMaskBottomLeft) ? YES : NO;
    if (state != [[UserData instance].buttonPos[ClockButtonIndexBottomLeft] boolValue]) {
        if ([self pushButton:self.buttons[ClockButtonIndexBottomLeft]]) {
            self.pushButtonCount++;
        }
    }
    state = (buttonMask & ClockButtonMaskBottomRight) ? YES : NO;
    if (state != [[UserData instance].buttonPos[ClockButtonIndexBottomRight] boolValue]) {
        if ([self pushButton:self.buttons[ClockButtonIndexBottomRight]]) {
            self.pushButtonCount++;
        }
    }
    if (self.pushButtonCount == 0) {
        self.inButtonPush = NO;
        self.buttonPushCompletionHandler = nil;
        if (handler) {
            handler();
        }
    }
}

- (void)pushButtonDidEnd:(CC3Node *)button {
    self.buttonInMove[button.nodeIndex] = @(NO);
    if (self.buttonPushCompletionHandler) {
        void (^handler)() = self.buttonPushCompletionHandler;
        if (self.pushButtonCount == 0) {
            self.buttonPushCompletionHandler = nil;
        }
        handler();
    }
}

- (void)iterateButtons:(void (^)(int bi))handler {
    for (int i = 0; i < 4; i++) {
        handler(i);
    }
}

- (int)inversClockButtonMask:(int)buttonMask {
    return ClockButtonMaskAll - buttonMask;
}

- (int)wheelIndexForButtonMask:(int)buttonMask front:(BOOL)front {
    BOOL state = buttonMask & ClockButtonMaskTopLeft ? YES : NO;
    if (state == front)  {
        return ClockWheelIndexTopLeft;
    }
    state = buttonMask & ClockButtonMaskTopRight ? YES : NO;
    if (state == front) {
        return ClockWheelIndexTopRight;
    }
    state = buttonMask & ClockButtonMaskBottomLeft ? YES : NO;
    if (state == front) {
        return ClockWheelIndexBottomLeft;
    }
    state = buttonMask & ClockButtonMaskBottomRight ? YES : NO;
    if (state == front ) {
        return ClockWheelIndexBottomRight;
    }
    return -1;
}

/**
      x | -
        |
y       |       y
--------|--------
-       |       +
        |
      x | +
 */
- (BOOL)rotateWheelFromSwipeAt:(CGPoint)touchPoint interval:(ccTime)dt {
    if (self.pickedWheel && !self.inClockRotate) {
        CGPoint swipe2d = ccpSub(touchPoint, self.lastTouchEventPoint);
        CGPoint axis2d = ccpPerp(swipe2d);
        CC3Vector axis = CC3VectorAdd(CC3VectorScaleUniform(self.activeCamera.rightDirection, axis2d.x),
                                      CC3VectorScaleUniform(self.activeCamera.upDirection, axis2d.y));
        //NSLog(@"(%f, %f, %f)", axis.x, axis.y, axis.z);
        axis = [self.mainNode.transformMatrixInverted transformDirection:axis];
        GLfloat angle = ccpLength(swipe2d) * kRotateSwipeFactor;
        CGPoint swipeVelocity = ccpSub(touchPoint, self.lastTouchEventPoint);
        CGFloat spinSpeed = (angle / dt) * ccpLength(swipeVelocity) / 50;
        CGFloat gradient = [self calcGradient:axis forWheel:self.pickedWheel.nodeIndex];
        [self rotateWheel:self.pickedWheel angle:angle axis:cc3v(0, gradient, 0) speed:spinSpeed];
        return YES;
    }
    return NO;
}

- (CGFloat)calcGradient:(CC3Vector)axis forWheel:(int)wheelIndex {
    if (axis.y * axis.x < 0) {
        axis.y = -axis.y;
    }
    if (axis.x == 0) {
        // TODO: Wheel flickers sometimes, because gradient changes sign, when x is 0
    }
    CGFloat gradient = fabsf(axis.y) > fabsf(axis.x) ? axis.y : axis.x;
    gradient = wheelIndex % 2 == (self.faceFront ? 0 : 1) ? gradient : -gradient;
    return gradient;
}

- (void)rotateWheel:(CC3Node *)wheel angle:(GLfloat)angle axis:(CC3Vector)axis speed:(CGFloat)speed {
    if (self.isInWheelTurn) {
        return;
    }
    int pos = [self convertRotationToPos:wheel.rotation.y];
    int delta = [self calcDelta:wheel.nodeIndex newPos:pos];

    if (delta != 0) {
        [[SoundManager instance] playWheelTurnSound];
    }

    [self rotateWheels:wheel.nodeIndex delta:delta];
    [self iterateWheels:^(int wi) {
        [self.wheels[wi] rotateByAngle:angle aroundAxis:axis];
    } forWheel:wheel.nodeIndex];

    [self rotateClocks:wheel.nodeIndex delta:delta];
    [self iterateClocks:^(BOOL front, int ci) {
        [self.clocks[ci] rotateByAngle:(front ? angle : -angle) aroundAxis:axis];
    } forWheel:wheel.nodeIndex];
    // Logging
    /*int middleOffset = wheel.rotation.y < 0 ? -15 : 15;
    int rotation = (int)((wheel.rotation.y + middleOffset) / 30) * 30;
    NSLog(@"%i, %i, %i", rotation, pos, delta);*/
}

- (void)gridWheel:(CC3Node *)wheel {
    int pos = [self convertRotationToPos:wheel.rotation.y];
    int delta = [self calcDelta:wheel.nodeIndex newPos:pos];
    [[SoundManager instance] playGridTurnSound];
    [self turnWheel:wheel.nodeIndex delta:delta];
    BOOL solved = YES;
    for (NSNumber *c in [UserData instance].clockPos) {
        if ([c intValue] != 0) {
            solved = NO;
        }
    }
    if (solved) {
        [self.delegate gameSolved];
    }
}

- (BOOL)turnWheel:(int)wheelIndex delta:(int)delta {
    if (self.isInWheelTurn) {
        return NO;
    }
    self.inWheelTurn = YES;

    self.turnWheelCount = 0;
    double duration = delta == 0 ? kAnimationSpeed : fabs(kAnimationSpeed * delta);
    [self rotateWheels:wheelIndex delta:delta];
    [self iterateWheels:^(int wi) {
        self.turnWheelCount++;
        GLfloat rotation = [self convertPosToRotation:[[UserData instance].wheelPos[wi] intValue]];
        CCActionInterval *rotate = [CC3RotateTo actionWithDuration:duration rotateTo:CC3VectorMake(0, rotation, 0)];
        [self.wheels[wi] runAction:[CCSequence actions:rotate, [CCCallFuncN actionWithTarget:self selector:@selector(turnWheelDidEnd:)], nil]];
    } forWheel:wheelIndex];

    self.turnClockCount = 0;
    [self rotateClocks:wheelIndex delta:delta];
    [self iterateClocks:^(BOOL front, int ci) {
        self.turnClockCount++;        
        GLfloat rotation = [self convertPosToRotation:[[UserData instance].clockPos[ci] intValue]];
        CCActionInterval *rotate = [CC3RotateTo actionWithDuration:duration rotateTo:CC3VectorMake(0, rotation, 0)];
        [self.clocks[ci] runAction:[CCSequence actions:rotate, [CCCallFuncN actionWithTarget:self selector:@selector(turnClockDidEnd:)], nil]];
    } forWheel:wheelIndex];
    
    return YES;
}

- (void)turnWheel:(int)wheelIndex delta:(int)delta complete:(void (^)())handler {
    self.wheelTurnCompletionHandler = handler;
    if (![self turnWheel:wheelIndex delta:delta]) {
        if (self.wheelTurnCompletionHandler) {
            void (^handler)() = self.wheelTurnCompletionHandler;
            self.wheelTurnCompletionHandler = nil;
            handler();
        }
    }
}

- (void)turnWheelDidEnd:(CC3Node *)wheel {
    self.turnWheelCount--;
    [self checkWheelAndClockTurnDidEnd];
}

- (void)turnClockDidEnd:(CC3Node *)wheel {
    self.turnClockCount--;
    [self checkWheelAndClockTurnDidEnd];
}

- (void)checkWheelAndClockTurnDidEnd {
    if (self.turnWheelCount == 0 && self.turnClockCount == 0) {
        self.inWheelTurn = NO;
        if (self.wheelTurnCompletionHandler) {
            void (^handler)() = self.wheelTurnCompletionHandler;
            self.wheelTurnCompletionHandler = nil;
            handler();
        }
    }
}

- (int)getClockIndexForFrontWheel:(int)wheelIndex {
    switch (wheelIndex) {
        case 0: return 0;
        case 1: return 2;
        case 2: return 6;
        case 3: return 8;
    }
    return 0;
}

/* Pos       +180           /30    6-x    <0 => +12
=======================================================
 -180 < -150        0 <  30      0     6             6
 -150 < -120       30 <  60      1     5             5
 -120 <  -90       60 <  90      2     4             4
  -90 <  -60       90 < 120      3     3             3
  -60 <  -30      120 < 150      4     2             2
  -30 <    0      150 < 180      5     1             1
    0 <   30      180 < 210      6     0             0
   30 <   60      210 < 240      7    -1            11
   60 <   90      240 < 270      8    -2            10
   90 <  120      270 < 300      9    -3             9
  120 <  150      300 < 330     10    -4             8
  150 <  180      330 < 360     11    -5             7
======================================================= */
- (int)convertRotationToPos:(GLfloat)rotation {
    int middleOffset = 15;
    int pos = 6 - (int)(rotation + middleOffset + 180) / 30;
    return pos + (pos < 0 ? 12 : 0);
}

- (GLfloat)convertPosToRotation:(int)pos {
    return ((6 - (pos - (pos > 6 ? 12 : 0))) * 30) - 180;
}

/* Delta
==================
  0 ->  1  =>  1
  0 ->  2  =>  2
  4 ->  3  => -1
 11 ->  0  =>  1
 11 ->  1  =>  2
 0  -> 11  => -1
 1  -> 11  => -2
================== */
- (int)calcDelta:(int)wheelIndex newPos:(int)pos {
    int delta = pos - [[UserData instance].wheelPos[wheelIndex] intValue];
    if (delta < 0 && delta + 12 < -delta) {
        delta += 12;
    } else if (delta > 0 && 12 - delta < delta) {
        delta -= 12;
    }
    return delta;
}

- (void)rotateWheels:(int)wheelIndex delta:(int)delta {
    [self iterateWheels:^(int wi) {
        [UserData instance].wheelPos[wi] = @([[UserData instance].wheelPos[wi] intValue] + delta);
        [UserData instance].wheelPos[wi] = @([[UserData instance].wheelPos[wi] intValue] % 12 < 0 ?
                [[UserData instance].wheelPos[wi] intValue] % 12 + 12 : [[UserData instance].wheelPos[wi] intValue] % 12);
    } forWheel:wheelIndex];
}

- (void)iterateWheels:(void (^)(int ci))handler forWheel:(int)wheelIndex {
    NSArray *d = [self clockMoveMatrix:wheelIndex];
    [self iterateWheels:^(int wi) {
        int j = [self getClockIndexForFrontWheel:wi];
        if ([d[j] boolValue]) {
            handler(wi);
        }
    }];
}

- (void)iterateWheels:(void (^)(int wi))handler {
    for (int i = 0; i < 4; i++) {
        handler(i);
    }
}

- (void)rotateClocks:(int)wheelIndex delta:(int)delta {
    [self iterateClocks:^(BOOL front, int ci) {
        [UserData instance].clockPos[ci] = @([[UserData instance].clockPos[ci] intValue] + delta * (front ? 1 : -1));
        [UserData instance].clockPos[ci] = @([[UserData instance].clockPos[ci] intValue] % 12 < 0 ?
                [[UserData instance].clockPos[ci] intValue] % 12 + 12 : [[UserData instance].clockPos[ci] intValue] % 12);
    } forWheel:wheelIndex];
}

- (void)iterateClocks:(void (^)(BOOL front, int ci))handler forWheel:(int)wheelIndex {
    NSArray *d = [self clockMoveMatrix:wheelIndex];
    [self iterateClocks:^BOOL(BOOL front, int di, int ci) {
        if ([d[di] boolValue]) {
            handler(front, ci);
        }
        return NO;
    }];
}

- (void)iterateClocks:(BOOL (^)(BOOL front, int di, int ci))handler {
    for (int i = 0; i < 2; i++) {
        BOOL front = i == 0;
        int o = front ? 0 : 9;
        for (int i = 0; i < 9; i++) {
            int j = [self clock:i front:front];
            if (handler(front, i+o, j)) {
                break;
            }
        }
    }
}

- (int)clock:(int)index front:(BOOL)front {
    // Front: left to right: 0, 1, 2, 3, 4, 5, 6, 7, 8
    // Back : right to left: 11, 10, 9, 14, 13, 12, 17, 16, 15
    return front ? index : 9 + (2 - (index % 3) + 3 * (index / 3));
}

- (NSArray *)clockMoveMatrix:(int)wheelIndex {
    NSMutableArray *d = [[NSMutableArray alloc] initWithCapacity:18];
    for (int i = 0; i < 2; i++) {
        BOOL front = i == 0;
        int o = front ? 0 : 9;
        BOOL b0 = front ? [[UserData instance].buttonPos[0] boolValue] : ![[UserData instance].buttonPos[0] boolValue];
        BOOL b1 = front ? [[UserData instance].buttonPos[1] boolValue] : ![[UserData instance].buttonPos[1] boolValue];
        BOOL b2 = front ? [[UserData instance].buttonPos[2] boolValue] : ![[UserData instance].buttonPos[2] boolValue];
        BOOL b3 = front ? [[UserData instance].buttonPos[3] boolValue] : ![[UserData instance].buttonPos[3] boolValue];
        BOOL t0, t1;
        switch (wheelIndex) {
            case 0: t0 =  NO; t1 =  NO; break;
            case 1: t0 =  NO; t1 = YES; break;
            case 2: t0 = YES; t1 =  NO; break;
            case 3: t0 = YES; t1 = YES; break;
        }
        d[0+o] = @((!t0 && !t1) || ((b0==b1) && !t0) || ((b0==b2) && t0 && !t1) || ((b0==b3) && t0 && t1));
        d[1+o] = @((((!t0 && !t1) || (b3 && t0 && t1)) && b0) || ((b3 || !t0) && b1 && t1) || (((!b0 && b1) || b0) && b2 && t0 && !t1));
        d[2+o] = @((!t0 && t1) || ((b1==b0) && !t0) || ((b1==b2) && t0 && !t1) || ((b1==b3) && t1));
        d[3+o] = @(((!t1 || b1) && b0 && !t0) || ((!t1 || b3) && b2 && t0) || (((b1 && b2 && !t0) || (b0 && b3 && t0)) && t1));
        d[4+o] = @((((b3 && t1) || (b2 && !t1)) && t0) || (((b1 && t1) ||(b0 && !t1)) && !t0));
        d[5+o] = @((((b3 && t0) || (b1 && !t0)) && t1) || (((b3 && !t1) || b1) && b0 && !t0) || (((b1 && !t1) || b3) && b2 && t0));
        d[6+o] = @((t0 && !t1) || ((b2==b0) && !t0 && !t1) || ((b2==b1) && !t0 && t1) || ((b2==b3) && t0));
        d[7+o] = @(((b1 || t0) && b3 && t1) || (((b1 && !t0 && t1) || (t0 && !t1)) && b2) || ((b2 || b3) && b0 && !t0 && !t1));
        d[8+o] = @((t0 && t1) || ((b3==b0) && !t0 && !t1) || ((b3==b1) && t1) || ((b3==b2) && t0));
    }
    return d;
}

- (void)initShuffle {
    self.shuffleTurnCount = random(20, 40);
    self.shuffleTurnIndex = 0;
}

- (void)shuffleNextClock:(void (^)(int clock, BOOL turn, BOOL done))handler {
    if (self.shuffleTurnIndex < self.shuffleTurnCount) {
        int buttonMask = random(0, 16);
        BOOL turn = self.shuffleTurnIndex == self.shuffleTurnCount / 2;
        self.shuffleTurnIndex++;
        [self pushButtons:buttonMask complete:^{
            int delta = random(-6, 6);
            int wheel = random(0, 4);
            [[SoundManager instance] startWheelTurnSound];
            [self turnWheel:wheel delta:delta complete:^{
                [[SoundManager instance] stopWheelTurnSound];
                handler(self.shuffleTurnIndex, turn, NO);
            }];
        }];
    } else {
        handler(self.shuffleTurnIndex, NO, YES);
    }
}

- (void)initSolve {
    self.solveClockIndex = 0;
    self.solveClockMoveIndex = 0;
    self.solveClockLastDelta = 0;
}

- (void)solveNextClock:(void (^)(int clock, BOOL turn, BOOL done))handler {
    if (self.solveClockIndex >= self.solveMatrix.count) {
        return;
    }
    NSDictionary *solveClock = self.solveMatrix[self.solveClockIndex];
    int clockIndex = [solveClock[@"c"] intValue];
    BOOL front = clockIndex < 9;
    int clockPos = [[UserData instance].clockPos[clockIndex] intValue];
    int delta = [self deltaToClockZero:clockPos];
    delta = front ? delta : -delta;
    if (delta != 0 || self.solveClockMoveIndex > 0) {
        NSArray *clockMoves = solveClock[@"m"];
        NSInteger moveCount = clockMoves.count;
        if (self.solveClockMoveIndex < moveCount) {
            NSDictionary *solveClockMove = clockMoves[self.solveClockMoveIndex];
            self.solveClockMoveIndex++;
            if (self.solveClockMoveIndex == moveCount) {
                self.solveClockIndex++;
                self.solveClockMoveIndex = 0;
            }
            int buttonMask = [solveClockMove[@"b"] intValue];
            [self pushButtonsToState:buttonMask complete:^{
                int type = [solveClockMove[@"t"] intValue];
                if (type == kSolveMoveTypeDeltaToZero) {
                    [[SoundManager instance] startWheelTurnSound];
                    [self turnWheel:[self wheelIndexForButtonMask:buttonMask front:front] delta:delta complete:^{
                        [[SoundManager instance] stopWheelTurnSound];
                        [self nextTurn:handler increase:NO];
                    }];
                } else if (type == kSolveMoveTypeDeltaToAlign) {
                    [[SoundManager instance] startWheelTurnSound];
                    [self turnWheel:[self wheelIndexForButtonMask:buttonMask front:front] delta:-delta complete:^{
                        [[SoundManager instance] stopWheelTurnSound];
                        [self nextTurn:handler increase:NO];
                    }];
                } else if (type == kSolveMoveTypeDeltaToLast) {
                    [[SoundManager instance] startWheelTurnSound];
                    [self turnWheel:[self wheelIndexForButtonMask:buttonMask front:front] delta:self.solveClockLastDelta complete:^{
                        [[SoundManager instance] stopWheelTurnSound];
                        [self nextTurn:handler increase:NO];
                    }];
                }
                self.solveClockLastDelta = delta;
            }];
        } else {
            [self nextTurn:handler increase:YES];
        }
    } else {
        [self nextTurn:handler increase:YES];
    }
}

- (void)nextTurn:(void (^)(int clock, BOOL turn, BOOL done))handler increase:(BOOL)increase {
    if (increase) {
        self.solveClockIndex++;
        self.solveClockMoveIndex = 0;
    }
    BOOL turn = self.solveClockIndex == 9;
    BOOL done = self.solveClockIndex == self.solveMatrix.count;
    if (done) {
        [self pushButtonsToState:ClockButtonMaskAll complete:^{
            handler(self.solveClockIndex, turn, done);
        }];
    } else {
        handler(self.solveClockIndex, turn, done);
    }
}

- (int)deltaToClockZero:(int)clockPos {
    int delta = 0 - clockPos;
    if (abs(delta) >= abs(12 - clockPos)) {
        delta = 12 + delta;
    }
    return delta;
}

@end

@implementation CC3Node (CustomData)

- (void)setNodeIndex:(int)nodeIndex {
    self.userData = (void *)nodeIndex;
}

- (int)nodeIndex {
    return (int)self.userData;
}

@end