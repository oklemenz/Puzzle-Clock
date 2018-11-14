//
//  TouchView.h
//  RubiksClock3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Layer.h"

@interface TouchView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *touchView;
@property (nonatomic, strong) Layer *cc3Layer;

@end
