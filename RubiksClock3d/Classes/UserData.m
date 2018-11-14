//
//  UserData.m
//  RubiksClock3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2012. All rights reserved.
//

#import "UserData.h"
#import "Scene.h"
#import "AppDelegate.h"

#define kDonationTimeValue 5 * 60;

@implementation UserData

- (id)init {
    self = [super init];
    if (self) {
        [self load];
    }
    return self;
}

- (void)reset {
    _cameraOn = NO;
    _gyroOn = NO;
    _soundOn = NO;
    _time = 0;
    _rotation = kInitialFrontRotation;
    _location = !IS_IPHONE_4 ? kInitialCameraLocation1 : kInitialCameraLocation2;
    
    _donated = NO;
    _donationTime = kDonationTimeValue;
    
    _buttonPos = [NSMutableArray arrayWithCapacity:4];
    _wheelPos = [NSMutableArray arrayWithCapacity:4];
    for (int i = 0; i < 4; i++) {
        _buttonPos[i] = @(YES);
        _wheelPos[i] = @(0);
    }
    _clockPos = [NSMutableArray arrayWithCapacity:18];
    for (int i = 0; i < 18; i++) {
        _clockPos[i] = @(0);
    }
}

- (void)load {
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
    if ([data integerForKey:@"init"] == 1) {
        _cameraOn = [[data valueForKey:@"camera"] boolValue];
        _gyroOn = [[data valueForKey:@"gyro"] boolValue];
        _soundOn = [[data valueForKey:@"sound"] boolValue];
        _inPlay = [[data valueForKey:@"play"] boolValue];
        NSDictionary *rotationDict = [data valueForKey:@"rotation"];
        _rotation = CC3VectorMake([rotationDict[@"x"] doubleValue], [rotationDict[@"y"] doubleValue], [rotationDict[@"z"] doubleValue]);
        NSDictionary *locationDict = [data valueForKey:@"location"];
        _location = CC3VectorMake([locationDict[@"x"] doubleValue], [locationDict[@"y"] doubleValue], [locationDict[@"z"] doubleValue]);
        _donated = [[data valueForKey:@"donated"] boolValue];
        _donationTime = [[data valueForKey:@"donationTime"] doubleValue];
        _time = [[data valueForKey:@"time"] doubleValue];
        _buttonPos = [[data valueForKey:@"button"] mutableCopy];
        _wheelPos = [[data valueForKey:@"wheel"] mutableCopy];
        _clockPos = [[data valueForKey:@"clock"] mutableCopy];
    } else {
        [self reset];
        [self store];
    }
}

- (void)store {
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
	[data setInteger:1 forKey:@"init"];
    [data setValue:[NSNumber numberWithBool:_cameraOn] forKey:@"camera"];
    [data setValue:[NSNumber numberWithBool:_gyroOn] forKey:@"gyro"];
    [data setValue:[NSNumber numberWithBool:_soundOn] forKey:@"sound"];
    [data setValue:[NSNumber numberWithBool:_inPlay] forKey:@"play"];
    [data setValue:@{ @"x" : @(_rotation.x), @"y" : @(_rotation.y), @"z" : @(_rotation.z)} forKey:@"rotation"];
    [data setValue:@{ @"x" : @(_location.x), @"y" : @(_location.y), @"z" : @(_location.z)} forKey:@"location"];
    [data setValue:[NSNumber numberWithBool:_donated] forKey:@"donated"];
    [data setValue:[NSNumber numberWithDouble:_donationTime] forKey:@"donationTime"];
    [data setValue:[NSNumber numberWithDouble:_time] forKey:@"time"];
    [data setValue:_buttonPos forKey:@"button"];
    [data setValue:_wheelPos forKey:@"wheel"];
    [data setValue:_clockPos forKey:@"clock"];
    [data synchronize];
}

+ (UserData *)instance {
    static UserData *instance;    
    @synchronized(self) {
        if (!instance) {
            instance = [UserData new];
        }
        return instance;
    }
}

- (void)increaseDonationTime {
    self.donationTime += kDonationTimeValue;
}

@end