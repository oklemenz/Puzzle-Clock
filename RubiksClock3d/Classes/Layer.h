//
//  Layer.h
//  RubiksClock3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2012. All rights reserved.
//

#import "CC3Layer.h"

@interface Layer : CC3Layer {
}

@property (nonatomic) BOOL zoomStart;
@property int touchCount;
@property (nonatomic, retain) UITouch *multiTouchLead;

- (void)zoomCamera:(UIPinchGestureRecognizer *)gesture;
- (void)rotateNode:(UIRotationGestureRecognizer *)gesture;
- (void)moveMultiple:(NSSet *)touches;

@end
