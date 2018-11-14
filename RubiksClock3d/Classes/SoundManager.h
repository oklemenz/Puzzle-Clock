//
//  SoundManager.h
//  RubiksClock3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2012. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimpleAudioEngine.h"
#import "CDXPropertyModifierAction.h"
#import "UserData.h"

@interface SoundManager : NSObject {
	CDSoundSource *clockMoveSound;
	CDSoundSource *wheelTurnSound;
	
	SimpleAudioEngine *soundEngine;
	CDXPropertyModifierAction* faderAction;
	CCActionManager *actionManager;
}

@property (nonatomic, retain, readonly) UserData *userData;
@property BOOL clockMoveSoundPlaying;
@property BOOL wheelTurnSoundPlaying;

- (void)startClockMoveSound;
- (void)stopClockMoveSound;
- (void)startWheelTurnSound;
- (void)stopWheelTurnSound;

- (void)playButtonPushUpSound;
- (void)playButtonPushDownSound;
- (void)playStartTurnSound;
- (void)playWheelTurnSound;
- (void)playGridTurnSound;
- (void)playHUDButtonSound;

- (void)stopSound;

+ (SoundManager *)instance;

@end
