#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UITextView.h>
#import <Celestial/AVController.h>
#import <Celestial/AVItem.h>
#import <UIKit/UIButtonBar.h>

extern NSString *kUIButtonBarButtonAction;
extern NSString *kUIButtonBarButtonInfo;
extern NSString *kUIButtonBarButtonInfoOffset;
extern NSString *kUIButtonBarButtonSelectedInfo;
extern NSString *kUIButtonBarButtonStyle;
extern NSString *kUIButtonBarButtonTag;
extern NSString *kUIButtonBarButtonTarget;
extern NSString *kUIButtonBarButtonTitle;
extern NSString *kUIButtonBarButtonTitleVerticalHeight;
extern NSString *kUIButtonBarButtonTitleWidth;
extern NSString *kUIButtonBarButtonType;

@interface ClockView : UIView {
	bool front;
	UIImage *background;
	UIImage *clock[12];
	UIImage *button[2];
	CGPoint leftTop;
	CGPoint clockOffset[12];
	CGPoint clockSize[12];
	CGPoint clockTile;
	CGPoint buttonOffset[2];
	CGPoint buttonSize[2];
	CGPoint buttonTile;
	@public int c[9];
	@public	bool b[4];
}	
- (id)initWithFrame:(CGRect)rect:(bool)isFront;
- (void)push:(int)buttonId;
- (void)turn:(int)wheelId:(int)num;
- (void)drawRect:(CGRect)rect;
- (void)dealloc;
@end

@interface MainView : UIView {
	bool front;
	ClockView *clockFrontView;
	ClockView *clockBackView;
	UITransitionView *transView;
	int dragWheel;
	CGPoint dragWheelStart;
	CGRect buttonArea[4];
	CGRect wheelArea[4];
    AVController *controller;
    AVItem *soundTurn;
	AVItem *soundPushDown;
	AVItem *soundPushUp;
	UINavigationBar *navBar;
    UINavigationItem *navItem;
	UIButtonBar *buttonBar;
	UIAlertSheet *shuffleSheet;
	UIAlertSheet *resetSheet;
}
- (id)initWithFrame:(CGRect)rect;
- (UINavigationBar *)createNavBar:(CGRect)rect;
- (UIButtonBar *)createButtonBar;
- (NSArray *)buttonBarItemList;
- (void)buttonBarClicked:(id)sender;
- (void)push:(int)buttonId;
- (void)turn:(int)wheelId:(int)num;
- (void)mouseDown:(struct _GSEvent *)event;
- (void)mouseUp: (struct _GSEvent *)event;
- (void)mouseDragged: (struct _GSEvent *)event;
- (int)swipe: (int)direction withEvent: (struct _GSEvent *)event;
- (bool)canHandleSwipes;
- (void)dealloc;
@end

@interface RubiksClock : UIApplication {
   UIWindow *window;
   MainView *mainView;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
@end


