#import <Cordova/CDV.h>
#import <NativeKeyboard/NativeKeyboard.h>

@interface NKSLKTextViewController : SLKTextViewController

- (void)updateWithCommand:(CDVInvokedUrlCommand*)command andCommandDelegate:(id <CDVCommandDelegate>)commandDelegate;

- (instancetype)initWithScrollView:(UIScrollView *)scrollView withCommand:(CDVInvokedUrlCommand*)command andCommandDelegate:(id <CDVCommandDelegate>)commandDelegate;

- (void) updateKeyboardHeight:(CGFloat)height;

- (void) setSupportedInterfaceOrientations: (NSArray*) orientations;

@end