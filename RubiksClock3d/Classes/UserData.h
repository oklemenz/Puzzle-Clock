//
//  UserData.h
//  RubiksClock3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2012. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CC3Foundation.h"

@interface UserData : NSObject

@property (nonatomic, getter = isCameraOn) BOOL cameraOn;
@property (nonatomic, getter = isGyroOn) BOOL gyroOn;
@property (nonatomic, getter = isSoundOn) BOOL soundOn;
@property (nonatomic, getter = isInPlay) BOOL inPlay;
@property (nonatomic) double time;
@property (nonatomic) CC3Vector rotation;
@property (nonatomic) CC3Vector location;

@property (nonatomic, getter = hasDonated) BOOL donated;
@property (nonatomic) double donationTime;

@property (nonatomic, strong) NSMutableArray *buttonPos;
@property (nonatomic, strong) NSMutableArray *wheelPos;
@property (nonatomic, strong) NSMutableArray *clockPos;

- (void)load;
- (void)store;

+ (UserData *)instance;

- (void)increaseDonationTime;

@end
