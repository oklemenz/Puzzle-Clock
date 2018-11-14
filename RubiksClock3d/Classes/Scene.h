//
//  Scene.h
//  RubiksClock3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2012. All rights reserved.
//

#import "CC3Scene.h"
#import <CoreMotion/CoreMotion.h>

#define kInitialFrontRotation   cc3v(60,   25, 10) // cc3v(90,    0,  0)
#define kInitialBackRotation    cc3v(75, -120, 80) // cc3v(90, -180,  0)
#define kInitialCameraLocation1 cc3v(0.0, 0.0, 25.0)
#define kInitialCameraLocation2 cc3v(0.0, 0.0, 21.0)

@protocol SceneDelegate <NSObject>

- (void)updateTimer:(ccTime)delta;
- (void)gameSolved;
- (ccDeviceOrientation)ccOrientation;

@end

@interface Scene : CC3Scene {
}

@property(nonatomic) id<SceneDelegate> delegate;
@property(getter = isControlDisabled) BOOL controlDisabled;
@property(nonatomic) BOOL multipleTouches;
@property(nonatomic) BOOL multiplePicked;

- (void)setup;

- (void)rotateToFront;
- (void)rotateToFront:(void (^)())handler;
- (void)rotateToBack;
- (void)rotateToBack:(void (^)())handler;

- (void)pushButton:(int)buttonIndex complete:(void (^)())handler;
- (void)pushButtons:(int)buttonMask complete:(void (^)())handler;
- (void)pushButtonsToState:(int)buttonMask complete:(void (^)())handler;
- (void)turnWheel:(int)wheelIndex delta:(int)delta complete:(void (^)())handler;

- (void)initSolve;
- (void)solveNextClock:(void (^)(int clock, BOOL turn, BOOL done))handler;

- (void)initShuffle;
- (void)shuffleNextClock:(void (^)(int clock, BOOL turn, BOOL done))handler;

- (void)touchEnded;
- (void)startZoomCamera;
- (void)zoomCameraBy:(CGFloat)aMovement;
- (void)stopZoomCamera;
- (void)rotateZ:(CGFloat)degree andVelocity:(CGFloat)velocity;
- (void)spinRotateZ;

- (void)toggleGyro:(BOOL)state;
- (void)initializeTouchPoint:(CGPoint)touchPoint;

@end
