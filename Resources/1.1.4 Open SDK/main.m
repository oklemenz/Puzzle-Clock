#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RubiksClock.h"

int main(int argc, char *argv[]) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int ret = UIApplicationMain(argc, argv, [RubiksClock class]);
	[pool release];
	return ret;
}
