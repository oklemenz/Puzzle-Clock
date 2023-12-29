// com.oklemenz.myjiggyapp
// /Applications/MyJiggyApp.app/main.js
Plugins.load( "UIKit" );
Plugins.load( "Images" );

var window = new UIWindow( UIHardware.fullScreenApplicationContentRect );
window.setHidden( false );
window.orderFront();
window.makeKey();
window.backgroundColor = [ 0 , 0 , 0 , 1 ];

var imageClockFilename = Bundle.pathForResource( "images/clock.png");
var imageClock = Images.imageAtPath( imageClockFilename);

var imageClock1Filename = Bundle.pathForResource( "images/clock_1.png");
var imageClock1 = Images.imageAtPath( imageClock1Filename);

var imageView = new UIImageView(imageClock);
imageView.setCanHandleSwipes(true);
window.setContentView( imageView );

imageView.onSwipe = 
function( direction , event ) {
  imageClock1.draw1PartImageInRect(

  log( "MAIN VIEW SWIPE : " + direction + " : " + event.toSource() );
};


