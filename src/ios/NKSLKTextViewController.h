#import <NativeKeyboard/NativeKeyboard.h>
#import <Cordova/CDV.h>

@interface NKSLKTextViewController : SLKTextViewController

- (void)updateWithCommand:(CDVInvokedUrlCommand*)command andCommandDelegate:(id <CDVCommandDelegate>)commandDelegate;

- (instancetype)initWithScrollView:(UIScrollView *)scrollView withCommand:(CDVInvokedUrlCommand*)command andCommandDelegate:(id <CDVCommandDelegate>)commandDelegate;

- (void) updateKeyboardHeight:(CGFloat)height;

@end