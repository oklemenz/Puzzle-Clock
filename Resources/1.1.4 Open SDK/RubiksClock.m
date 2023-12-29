#import "RubiksClock.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <GraphicsServices/GraphicsServices.h>
#import <LayerKit/LKTransition.h>
#import <LayerKit/LKAnimation.h>
#import <stdlib.h>

@implementation ClockView
- (id)initWithFrame:(CGRect)rect:(bool)isFront {
	self = [ super initWithFrame: rect ];
	if (nil != self) {
		front = isFront;
		if (front) {
			background = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/clock_front.png" ];
		} else {
			background = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/clock_back.png" ];
		}
		clock[0]  = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/clock_00.png" ];
		clock[1]  = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/clock_01.png" ];
		clock[2]  = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/clock_02.png" ];
		clock[3]  = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/clock_03.png" ];
		clock[4]  = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/clock_04.png" ];
		clock[5]  = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/clock_05.png" ];
		clock[6]  = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/clock_06.png" ];
		clock[7]  = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/clock_07.png" ];
		clock[8]  = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/clock_08.png" ];
		clock[9]  = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/clock_09.png" ];
		clock[10] = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/clock_10.png" ];
		clock[11] = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/clock_11.png" ];
		button[0] = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/button_up.png" ];
		button[1] = [ UIImage imageAtPath: @"/Applications/RubiksClock.app/images/button_down.png" ];
		leftTop = CGPointMake(88, 150);
		clockOffset[0] = CGPointMake(0, 0);
		clockOffset[1] = CGPointMake(0, 1);
		clockOffset[2] = CGPointMake(0, 9);
		clockOffset[3] = CGPointMake(0, 14);
		clockOffset[4] = CGPointMake(0, 15);
		clockOffset[5] = CGPointMake(0, 15);
		clockOffset[6] = CGPointMake(0, 14);
		clockOffset[7] = CGPointMake(-1, 14);
		clockOffset[8] = CGPointMake(-11, 14);
		clockOffset[9] = CGPointMake(-14, 14);
		clockOffset[10] = CGPointMake(-11, 9);
		clockOffset[11] = CGPointMake(-1, 1);
		clockSize[0] = CGPointMake(13, 27);
		clockSize[1] = CGPointMake(14, 26);
		clockSize[2] = CGPointMake(24, 17);
		clockSize[3] = CGPointMake(27, 13);
		clockSize[4] = CGPointMake(24, 17);
		clockSize[5] = CGPointMake(14, 25);
		clockSize[6] = CGPointMake(13, 27);
		clockSize[7] = CGPointMake(14, 26);
		clockSize[8] = CGPointMake(24, 18);
		clockSize[9] = CGPointMake(27, 13);
		clockSize[10] = CGPointMake(24, 18);
		clockSize[11] = CGPointMake(14, 26);
		clockTile = CGPointMake(66, 71);
		buttonOffset[0] = CGPointMake(26, 46);
		buttonOffset[1] = CGPointMake(31, 46);
		buttonSize[0] = CGPointMake(23, 22);
		buttonSize[1] = CGPointMake(17, 16);
		buttonTile = CGPointMake(67, 70);
		int i;
		for (i = 0; i < 9; i++) {
			c[i] = 0;
		}
		for (i = 0; i < 4; i++) {
			b[i] = !front;
		}
	}
    return self;
}

- (void)push:(int)buttonId {
	if (buttonId >= 0 && buttonId < 4) {
		b[buttonId] = !b[buttonId];
	}
}

- (void)turn:(int)wheelId:(int)num {
	int i;
	bool t0, t1, b0 = b[0], b1 = b[1], b2 = b[2], b3 = b[3];
	bool d[9];
	switch (wheelId) {
		case 0: t0 = false; t1 = false; break;
		case 1: t0 = false; t1 = true; 	break;
		case 2: t0 = true; 	t1 = false; break;
		case 3: t0 = true; 	t1 = true; 	break;
		default: return;
	}		
	d[0] = (!t0 && !t1) || ((b0==b1) && !t0) || ((b0==b2) && t0 && !t1) || ((b0==b3) && t0 && t1);
	d[1] = (((!t0 && !t1) || (b3 && t0 && t1)) && b0) || ((b3 || !t0) && b1 && t1) || (((!b0 && b1) || b0) && b2 && t0 && !t1);
	d[2] = (!t0 && t1) || ((b1==b0) && !t0) || ((b1==b2) && t0 && !t1) || ((b1==b3) && t1);
	d[3] = ((!t1 || b1) && b0 && !t0) || ((!t1 || b3) && b2 && t0) || (((b1 && b2 && !t0) || (b0 && b3 && t0)) && t1);
	d[4] = (((b3 && t1) || (b2 && !t1)) && t0) || (((b1 && t1) ||(b0 && !t1)) && !t0);
	d[5] = (((b3 && t0) || (b1 && !t0)) && t1) || (((b3 && !t1) || b1) && b0 && !t0) || (((b1 && !t1) || b3) && b2 && t0);
	d[6] = (t0 && !t1) || ((b2==b0) && !t0 && !t1) || ((b2==b1) && !t0 && t1) || ((b2==b3) && t0);
	d[7] = ((b1 || t0) && b3 && t1) || (((b1 && !t0 && t1) || (t0 && !t1)) && b2) || ((b2 || b3) && b0 && !t0 && !t1);
	d[8] = (t0 && t1) || ((b3==b0) && !t0 && !t1) || ((b3==b1) && t1) || ((b3==b2) && t0);
	for (i = 0; i < 9; i++) {
		if (d[i]) {
			c[i] += num;
			c[i] = c[i]%12 < 0 ? c[i] % 12 + 12 : c[i] % 12;
		}
	}
}

- (void)drawRect:(CGRect)rect {
	int i, j, k, pos;
    CGRect myRect;
    CGSize imageSize = [ background size ];
    myRect.origin.x = 0;
    myRect.origin.y = 0;
    myRect.size.width = imageSize.width;
    myRect.size.height = imageSize.height;
    [ background draw1PartImageInRect: myRect ];
	for (i = 0; i < 2; i++) {
		for (j = 0; j < 2; j++) {
			if (front) {
				pos = j+2*i;
			} else {
				pos = 1-j+2*i;
			}
			k = b[pos] ? 0 : 1;
			[ button[k] draw1PartImageInRect: CGRectMake(leftTop.x + buttonOffset[k].x + buttonTile.x*j, leftTop.y + buttonOffset[k].y + buttonTile.y*i, buttonSize[k].x, buttonSize[k].y) ];
		}
	}
	for (i = 0; i < 3; i++) {
		for (j = 0; j < 3; j++) {
			if (front) {
				pos = j+3*i;
			} else {
				pos = 2-j+3*i;
			}
			k = c[pos];
			[ clock[k] draw1PartImageInRect: CGRectMake(leftTop.x + clockOffset[k].x + clockTile.x*j, leftTop.y + clockOffset[k].y + clockTile.y*i, clockSize[k].x, clockSize[k].y) ];
		}
	}
}

- (void)dealloc {
    [ self dealloc ];
    [ super dealloc ];
}
@end

@implementation MainView
- (id)initWithFrame:(CGRect)rect {
	self = [ super initWithFrame: rect ];
	if (nil != self) {
		front = true;
		clockFrontView = [ [ ClockView alloc ] initWithFrame: rect: true ];
		clockBackView = [ [ ClockView alloc ] initWithFrame: rect: false ];
		transView = [ [ UITransitionView alloc ] initWithFrame: rect ];
		[ self addSubview: transView ];
		[ transView transition: 0 toView: clockFrontView ];
		wheelArea[0]  = CGRectMake(0, 70, 100, 100);
		wheelArea[1]  = CGRectMake(220, 70, 100, 100);
		wheelArea[2]  = CGRectMake(0, 310, 100, 100);
		wheelArea[3]  = CGRectMake(220, 310, 100, 100);
		buttonArea[0] = CGRectMake(108, 187, 36, 36);
		buttonArea[1] = CGRectMake(176, 187, 36, 36);
		buttonArea[2] = CGRectMake(108, 260, 36, 36);
		buttonArea[3] = CGRectMake(176, 260, 36, 36);
		controller = [ [ AVController alloc ] init ];
		NSError *err;
        soundTurn = [ [ AVItem alloc ] initWithPath: @"/Applications/RubiksClock.app/sounds/turn.m4a" error:&err ];
		soundPushDown = [ [ AVItem alloc ] initWithPath: @"/Applications/RubiksClock.app/sounds/push_down.m4a" error:&err ];
		soundPushUp = [ [ AVItem alloc ] initWithPath: @"/Applications/RubiksClock.app/sounds/push_up.m4a" error:&err ];
		navBar = [ self createNavBar: rect ];
		[ self addSubview: navBar ];
	    buttonBar = [ self createButtonBar ];
        [ self addSubview: buttonBar ];
	}
    return self;
}

- (UINavigationBar *)createNavBar:(CGRect)rect {
    UINavigationBar *newNav = [ [UINavigationBar alloc] initWithFrame: CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 48.0) ];
    [ newNav setDelegate: self ];
    navItem = [ [UINavigationItem alloc] initWithTitle:@"Rubik's Clock" ];
    [ newNav pushNavigationItem: navItem ];
    return newNav;
}

- (UIButtonBar *)createButtonBar {
    UIButtonBar *myButtonBar = [ [ UIButtonBar alloc ] initInView: self withFrame: CGRectMake(0.0f, 411.0f, 320.0f, 49.0f) withItemList: [ self buttonBarItemList ] ];
    [ myButtonBar setDelegate: self ];
    [ myButtonBar setBarStyle: 1 ];
    [ myButtonBar setButtonBarTrackingMode: 2 ];

    int buttons[5] = { 1, 2, 3, 4, 5 };
    [ myButtonBar registerButtonGroup: 0 withButtons: buttons withCount: 5 ];
    [ myButtonBar showButtonGroup: 0 withDuration: 0.0 ];
    int tag;
    for(tag = 1; tag < 5; tag++) {
        [ [ myButtonBar viewWithTag: tag ]
            setFrame:CGRectMake(2.0f + ((tag - 1) * 63.0), 1.0, 64.0, 48.0f)
        ];
    }
    [ myButtonBar showSelectionForButton: 3 ];
    return myButtonBar;
}

- (NSArray *)buttonBarItemList {
    return [ NSArray arrayWithObjects:
        [ NSDictionary dictionaryWithObjectsAndKeys:
          @"buttonBarClicked:", kUIButtonBarButtonAction,
          @"History.png", kUIButtonBarButtonInfo,
          @"History.png", kUIButtonBarButtonSelectedInfo,
          [ NSNumber numberWithInt: 1], kUIButtonBarButtonTag,
            self, kUIButtonBarButtonTarget,
          @"Shuffle", kUIButtonBarButtonTitle,
          @"0", kUIButtonBarButtonType,
          nil
        ],
		[ NSDictionary dictionaryWithObjectsAndKeys:
          @"buttonBarClicked:", kUIButtonBarButtonAction,
          @"History.png", kUIButtonBarButtonInfo,
          @"History.png", kUIButtonBarButtonSelectedInfo,
          [ NSNumber numberWithInt: 2], kUIButtonBarButtonTag,
            self, kUIButtonBarButtonTarget,
          @"Reset", kUIButtonBarButtonTitle,
          @"0", kUIButtonBarButtonType,
          nil
        ],
        nil ];
}

- (void)buttonBarClicked:(id)sender {
	int buttonId = [ sender tag ];
	if (buttonId == 1) {
		shuffleSheet = [ [ UIAlertSheet alloc ] initWithFrame: CGRectMake(0, 240, 320, 240) ];
	    [ shuffleSheet setTitle: @"Please Confirm" ];
	    [ shuffleSheet setBodyText:@"Do you really want to shuffle the game?" ];
	    [ shuffleSheet setDestructiveButton: [ shuffleSheet addButtonWithTitle:@"Shuffle" ] ];
	    [ shuffleSheet addButtonWithTitle:@"Cancel" ];
	    [ shuffleSheet setDelegate: self ];
	    [ shuffleSheet presentSheetInView: self ];
	} else if (buttonId == 2) {
	    resetSheet = [ [ UIAlertSheet alloc ] initWithFrame: CGRectMake(0, 240, 320, 240) ];
	    [ resetSheet setTitle: @"Please Confirm" ];
	    [ resetSheet setBodyText:@"Do you really want to reset the game?" ];
	    [ resetSheet setDestructiveButton: [ resetSheet addButtonWithTitle:@"Reset" ] ];
	    [ resetSheet addButtonWithTitle:@"Cancel" ];
	    [ resetSheet setDelegate: self ];
	    [ resetSheet presentSheetInView: self ];
	}
}

- (void)alertSheet:(UIAlertSheet *)sheet buttonClicked:(int)button {
	int i, j;
	if (sheet == shuffleSheet) {
		switch(button) {
			case 1:
				for (i = 0; i < 9; i++) {
					clockFrontView->c[i] = random() % 12;
				}
				for (i = 0; i < 3; i++) {
					for (j = 0; j < 3; j++) {
						int pos = j+3*i;
						if ((i == j || i+j == 2) && i != 1) { 
							clockBackView->c[pos] = 12-clockFrontView->c[pos]; 
							if (clockBackView->c[pos] == 12) { 
								clockBackView->c[pos] = 0; 
							}
						} else {
							clockBackView->c[pos] = random() % 12;
						}
					}
				}
				for (i = 0; i < 4; i++) {
					clockFrontView->b[i] = random() % 2 == 0 ? true : false;
					clockBackView->b[i] = !clockFrontView->b[i];
				}
				[ clockFrontView setNeedsDisplay ];
				[ clockBackView setNeedsDisplay ];
				break;
			case 2:
				break;
		}
    } else if (sheet == resetSheet) {
        switch(button) {
            case 1:
				for (i = 0; i < 9; i++) {
					clockFrontView->c[i] = 0;
					clockBackView->c[i] = 0;
				}
				for (i = 0; i < 4; i++) {
					clockFrontView->b[i] = false;
					clockBackView->b[i] = true;
				}
				[ clockFrontView setNeedsDisplay ];
				[ clockBackView setNeedsDisplay ];
                break;
            case 2:
                break;
        }
    }
	[ sheet dismiss ];
}

- (void)push:(int)buttonId {
	[ clockFrontView push:buttonId ];
	[ clockFrontView setNeedsDisplay ];
	[ clockBackView push:buttonId ];
	[ clockBackView setNeedsDisplay ];
	int ringerState = [ UIHardware ringerState ];
	if (ringerState == 1) {
		if ((front && clockFrontView->b[buttonId]) ||
		    (!front && clockBackView->b[buttonId])) {
			[ controller setCurrentItem: soundPushUp preservingRate:NO ];
		} else {
			[ controller setCurrentItem: soundPushDown preservingRate:NO ];
		}
        [ controller play:nil ];
	}
}

- (void)turn:(int)wheelId:(int)num {
	if (front) {
		[ clockFrontView turn:wheelId:num ];
		[ clockBackView turn:wheelId:-num ];
	} else {
		[ clockBackView turn:wheelId:num ];
		[ clockFrontView turn:wheelId:-num ];
	}
	[ clockFrontView setNeedsDisplay ];
	[ clockBackView setNeedsDisplay ];
	int ringerState = [ UIHardware ringerState ];
	if (ringerState == 1) {
		[ controller setCurrentItem: soundTurn preservingRate:NO ];
        [ controller play:nil ];
	}
}

- (void)mouseDown: (struct _GSEvent *)event {
	int i, j, pos;
    CGPoint point = GSEventGetLocationInWindow(event);
	for (i = 0; i < 2; i++) {
		for (j = 0; j < 2; j++) {
			pos = j+2*i;
			if (CGRectContainsPoint(buttonArea[pos], point)) {
				if (!front) {
					pos = 1-j+2*i;
				} 
				[ self push:pos ];					
				return;
			} else if (CGRectContainsPoint(wheelArea[pos], point)) {
				dragWheel = pos;
				dragWheelStart = point;
				return;
			}
        }
    }
}

- (void)mouseUp: (struct _GSEvent *)event {
	dragWheel = -1;
}

- (void)mouseDragged: (struct _GSEvent *)event {
	CGPoint point = GSEventGetLocationInWindow(event);
	if (dragWheel != -1) {
		if (CGRectContainsPoint(wheelArea[dragWheel], point)) {
			float dx = dragWheelStart.x - point.x;
			float dy = dragWheelStart.y - point.y;
			float distance = sqrt( dx*dx + dy*dy );
			if (distance >= 10) {
				int num = 0;
				if (dragWheel == 0 || dragWheel == 2) {
					num = 1;
				} else {
					num = -1;
				}
				if (point.y > dragWheelStart.y) {
					num = -num;
				}
				int k;
				if (front) {
					k = dragWheel;
				} else {
					if (dragWheel == 0 || dragWheel == 2) {
						k = dragWheel + 1;
					} else {
						k = dragWheel - 1;
					}
				}
				[ self turn:k:num ];
				dragWheelStart = point;
			}
		}
	} else {
		[ self mouseDown:event ];
	}
}

- (int)swipe:(int)direction withEvent: (struct _GSEvent *)event {
	if (direction != 4 && direction != 8) {
		return 0;
	}
	LKAnimation *animation = [ LKTransition animation ];
	[ animation setType: @"oglFlip" ];
	if (direction == 4) {
		[ animation setSubtype: @"fromRight" ];
    } else if (direction == 8) {
		[ animation setSubtype: @"fromLeft" ];
	}
    [ animation setTimingFunction: [ LKTimingFunction functionWithName: @"easeInEaseOut" ] ];
	[ animation setFillMode: @"extended" ];
	[ animation setTransitionFlags: 3 ];
	[ animation setSpeed: 0.75 ];
	[ [ self _layer ] addAnimation: animation forKey: 0 ];
	if (front) {
		[ transView transition: 0 toView: clockBackView];
		front = false;
	} else {
		[ transView transition: 0 toView: clockFrontView];
		front = true;
	}
}

- (bool)canHandleSwipes {
	return true;
}

- (void)dealloc {
	[ self dealloc ];
    [ super dealloc ];
}
@end

@implementation RubiksClock
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    window = [ [ UIWindow alloc ] initWithContentRect:
        [ UIHardware fullScreenApplicationContentRect ]
    ];

    CGRect rect = [ UIHardware fullScreenApplicationContentRect ];
    rect.origin.x = rect.origin.y = 0.0f;
	
	mainView = [ [ MainView alloc ] initWithFrame: rect ];
	[ window setContentView: mainView ];
    [ window orderFront: self ];
    [ window makeKey: self ];
    [ window _setHidden: NO ];
}
@end