//
//  SoundManager.m
//  RubiksClock3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2012. All rights reserved.
//

#import "SoundManager.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation SoundManager

+ (SoundManager *)instance {
	static SoundManager *_instance;
	@synchronized(self) {
		if (!_instance) {
			_instance = [SoundManager new];
		}
	}
	return _instance;
}

- (id)init {
	if ((self = [super init])) {

		soundEngine = [SimpleAudioEngine sharedEngine];
		[[CDAudioManager sharedManager] setResignBehavior:kAMRBStopPlay autoHandle:YES];
		actionManager = [CCActionManager sharedManager];
		soundEngine.effectsVolume = 1.0f;

		[soundEngine preloadEffect:@"clock_move.caf"];
		[soundEngine preloadEffect:@"button_push_up.caf"];
		[soundEngine preloadEffect:@"button_push_down.caf"];
		[soundEngine preloadEffect:@"start_turn.caf"];
		[soundEngine preloadEffect:@"wheel_turn.caf"];
		[soundEngine preloadEffect:@"grid_turn.caf"];
		[soundEngine preloadEffect:@"hud_button.caf"];
		
		clockMoveSound = [soundEngine soundSourceForFile:@"clock_move.caf"];
		clockMoveSound.gain = 0.0f;
		wheelTurnSound = [soundEngine soundSourceForFile:@"wheel_turn.caf"];
		wheelTurnSound.gain = 0.0f;
	}
	return self;
}

- (void)startClockMoveSound {
	if ([UserData instance].isSoundOn && !self.clockMoveSoundPlaying) {
		[[CCActionManager sharedManager] removeAllActionsFromTarget:clockMoveSound];
		clockMoveSound.looping = YES;
		[clockMoveSound play];
		[CDXPropertyModifierAction fadeSoundEffect:0.25f finalVolume:1.0f curveType:kIT_Linear shouldStop:NO effect:clockMoveSound];
		self.clockMoveSoundPlaying = YES;
	}
}

- (void)stopClockMoveSound {
	if (self.clockMoveSoundPlaying) {
		[[CCActionManager sharedManager] removeAllActionsFromTarget:clockMoveSound];
		[CDXPropertyModifierAction fadeSoundEffect:0.5f finalVolume:0.0f curveType:kIT_Linear shouldStop:YES effect:clockMoveSound];
		self.clockMoveSoundPlaying = NO;
	}
}

- (void)startWheelTurnSound {
	if ([UserData instance].isSoundOn && !self.wheelTurnSoundPlaying) {
		[[CCActionManager sharedManager] removeAllActionsFromTarget:wheelTurnSound];
		wheelTurnSound.looping = YES;
		[wheelTurnSound play];
		[CDXPropertyModifierAction fadeSoundEffect:0.25f finalVolume:1.0f curveType:kIT_Linear shouldStop:NO effect:wheelTurnSound];
		self.wheelTurnSoundPlaying = YES;
	}
}

- (void)stopWheelTurnSound {
	if (self.wheelTurnSoundPlaying) {
		[[CCActionManager sharedManager] removeAllActionsFromTarget:wheelTurnSound];
		[CDXPropertyModifierAction fadeSoundEffect:0.25f finalVolume:0.0f curveType:kIT_Linear shouldStop:YES effect:wheelTurnSound];
		self.wheelTurnSoundPlaying = NO;
	}
}

- (void)playButtonPushUpSound {
	if ([UserData instance].isSoundOn) {
		[soundEngine playEffect:@"button_push_up.caf"];
	}
}

- (void)playButtonPushDownSound {
	if ([UserData instance].isSoundOn) {
		[soundEngine playEffect:@"button_push_down.caf"];
	}
}

- (void)playStartTurnSound {
	if ([UserData instance].isSoundOn) {
		[soundEngine playEffect:@"start_turn.caf"];
	}
}

- (void)playWheelTurnSound {
	if ([UserData instance].isSoundOn) {
		[soundEngine playEffect:@"wheel_turn.caf"];
	}
}

- (void)playGridTurnSound {
	if ([UserData instance].isSoundOn) {
		[soundEngine playEffect:@"grid_turn.caf"];
	}
}

- (void)playHUDButtonSound {
	if ([UserData instance].isSoundOn) {
		[soundEngine playEffect:@"hud_button.caf"];
	}
}

- (void)stopSound {
    [self stopClockMoveSound];
    [self stopWheelTurnSound];
}

- (void)dealloc {
	[actionManager removeAllActionsFromTarget:clockMoveSound];
	[actionManager removeAllActionsFromTarget:wheelTurnSound];
	[actionManager removeAllActionsFromTarget:[[CDAudioManager sharedManager] audioSourceForChannel:kASC_Left]];
	[actionManager removeAllActionsFromTarget:[CDAudioManager sharedManager].soundEngine];
	[SimpleAudioEngine end];
	soundEngine = nil;
}

@end