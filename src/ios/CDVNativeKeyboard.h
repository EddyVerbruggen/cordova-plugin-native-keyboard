#import <Cordova/CDV.h>
#import <NativeKeyboard/NativeKeyboard.h>

@interface CDVNativeKeyboard : CDVPlugin<UITextViewDelegate, UITextFieldDelegate, UIScrollViewDelegate, NSLayoutManagerDelegate>

@property (nonatomic, strong) NKTextView *textView;
@property (nonatomic, strong) NKTextField *textField;

- (void)show:(CDVInvokedUrlCommand*)command;
- (void)hide:(CDVInvokedUrlCommand*)command;

- (void)showMessenger:(CDVInvokedUrlCommand*)command;
- (void)hideMessenger:(CDVInvokedUrlCommand*)command;

@end