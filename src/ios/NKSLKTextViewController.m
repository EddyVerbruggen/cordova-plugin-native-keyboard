#import "NKSLKTextViewController.h"

@implementation NKSLKTextViewController

id <CDVCommandDelegate> _commandDelegate;
CDVInvokedUrlCommand* _command;
NSArray * _supportedOrientations;
CGFloat _baseKeyboardHeight = 224; // fallback
CGFloat _defaultContentHeight = 34;
CGFloat _lastContentHeight = 34;
BOOL _disableLefButtonWhenTextEntered;

// copied from CDVViewController so the rotation isn't altered during/after using the SlackViewController
#ifdef __IPHONE_9_0
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#else
- (NSUInteger)supportedInterfaceOrientations
#endif
{
  NSUInteger ret = 0;
  if ([self supportsOrientation:UIInterfaceOrientationPortrait]) {
    ret = ret | (1 << UIInterfaceOrientationPortrait);
  }
  if ([self supportsOrientation:UIInterfaceOrientationPortraitUpsideDown]) {
    ret = ret | (1 << UIInterfaceOrientationPortraitUpsideDown);
  }
  if ([self supportsOrientation:UIInterfaceOrientationLandscapeRight]) {
    ret = ret | (1 << UIInterfaceOrientationLandscapeRight);
  }
  if ([self supportsOrientation:UIInterfaceOrientationLandscapeLeft]) {
    ret = ret | (1 << UIInterfaceOrientationLandscapeLeft);
  }
  return ret;
}

- (BOOL)supportsOrientation:(UIInterfaceOrientation)orientation
{
  return [_supportedOrientations containsObject:[NSNumber numberWithInt:orientation]];
}

- (void) setSupportedInterfaceOrientations: (NSArray*) orientations {
  _supportedOrientations = orientations;
}

- (void) updateKeyboardHeight:(CGFloat)height {
  _baseKeyboardHeight = height;
}

- (void)didChangeKeyboardStatus:(SLKKeyboardStatus)status {
  [super didChangeKeyboardStatus:status];
  if (SLKKeyboardStatusDidShow == status) {
    // TODO extract a convenience method for sending stuff back to JS
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"keyboardDidShow":@(YES), @"keyboardHeight":[NSNumber numberWithFloat:_baseKeyboardHeight+_lastContentHeight]}];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    [_commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
  } else if (SLKKeyboardStatusWillHide == status) {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"keyboardWillHide":@(YES)}];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    [_commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
  }
}

// you can update JS on every keypress, but it makes more sense to send back the result when the rightbutton is pressed -- however it would be nice to pass back th grow height so the webview can move a bit -- or perhaps we can do that ourselves here, based on the contentheight etc.. if it's more than half the screen move it down
- (void)textDidUpdate:(BOOL)animated {
  // Notifies the view controller that the text did update.
  [super textDidUpdate:animated];

  if (_disableLefButtonWhenTextEntered) {
    [self.leftButton setEnabled:self.textView.text.length == 0];
  }
  // the initial position of the webview is the responsibility of the dev,
  // but we'll reposition it if the contentarea grows/shrinks
  CGFloat height = self.textInputbar.textView.frame.size.height;
  if (_defaultContentHeight == 0) {
    _defaultContentHeight = height;
    _lastContentHeight = height;
  }
  if (height != _lastContentHeight) {
    CGFloat diff = height - _defaultContentHeight;
//    [self.scrollView setContentOffset: CGPointMake(0, 400) animated:YES];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"contentHeight":[NSNumber numberWithFloat:height], @"contentHeightDiff":[NSNumber numberWithFloat:diff]}];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    [_commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
  }
  _lastContentHeight = height;
}

- (void)didPressLeftButton:(id)sender {
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"messengerLeftButtonPressed":@(YES)}];
  pluginResult.keepCallback = [NSNumber numberWithBool:YES];
  [_commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
}

- (void)didPressRightButton:(id)sender {
  NSString *text = self.textInputbar.textView.text;
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"messengerRightButtonPressed":@(YES), @"text":text}];
  pluginResult.keepCallback = [NSNumber numberWithBool:YES];
  [_commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
  [self dismissKeyboard:YES];
  [super didPressRightButton:sender];
}

- (void)updateWithCommand:(CDVInvokedUrlCommand*)command andCommandDelegate:(id <CDVCommandDelegate>)commandDelegate {
  _commandDelegate = commandDelegate;
  _command = command;
  [self configureMessenger];
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView withCommand:(CDVInvokedUrlCommand*)command andCommandDelegate:(id <CDVCommandDelegate>)commandDelegate {
  self = [super initWithScrollView:scrollView];
  _commandDelegate = commandDelegate;
  _command = command;
  [self configureMessenger];
  return self;
}

- (void) configureMessenger {
  NSDictionary* options = [_command argumentAtIndex:0];
  NSNumber* maxChars = options[@"maxChars"];
  if (maxChars != nil) {
    self.textInputbar.maxCharCount = [maxChars intValue];
  }
  
  // style the messageview
  self.textInputbar.textView.placeholder = options[@"placeholder"];
  NSString* placeholderColor = options[@"placeholderColor"];
  if (placeholderColor != nil) {
    self.textInputbar.textView.placeholderColor = [NativeKeyboardHelper colorFromHexString:placeholderColor];
  }
  NSString* textViewBackgroundColor = options[@"textViewBackgroundColor"];
  if (textViewBackgroundColor != nil) {
    self.textInputbar.textView.backgroundColor = [NativeKeyboardHelper colorFromHexString:textViewBackgroundColor];
  }
  NSString* textViewBorderColor = options[@"textViewBorderColor"];
  if (textViewBorderColor != nil) {
    self.textInputbar.textView.layer.borderColor = [NativeKeyboardHelper colorFromHexString:textViewBorderColor].CGColor;
  }
//  self.textInputbar.textView.pastableMediaTypes = SLKPastableMediaTypeAll;

//  [self.leftButton setImage:[UIImage imageNamed:@"icn_upload"] forState:UIControlStateNormal];
  self.bounces = YES;
  self.shakeToClearEnabled = NO;
  self.keyboardPanningEnabled = YES;
  self.shouldScrollToBottomAfterKeyboardShows = [options[@"scrollToBottomAfterKeyboardShows"] boolValue];
  self.inverted = NO;
  
  NSString* textViewContainerBackgroundColor = options[@"textViewContainerBackgroundColor"];
  if (textViewContainerBackgroundColor != nil) {
    self.textInputbar.backgroundColor = [NativeKeyboardHelper colorFromHexString:textViewContainerBackgroundColor];
  }

  NSString *text = options[@"text"];
  self.textInputbar.textView.text = text;
  if (options[@"textColor"] != nil) {
    self.textInputbar.textView.textColor = [NativeKeyboardHelper colorFromHexString:options[@"textColor"]];
  }

  // TODO feature-allowed check
  SLKCounterStyle slkCounterStyle = [NKSLKTextViewController getSLKCounterStyle:options[@"counterStyle"]];
  self.textInputbar.counterStyle = slkCounterStyle;
  self.textInputbar.counterPosition = SLKCounterPositionTop; // TODO pass in some day
  
  // we can also set the keyboard type!
  if (options[@"type"] != nil) {
    if ([NativeKeyboardHelper allowFeature:NKFeatureKeyboardType]) {
      UIKeyboardType keyBoardType = [NativeKeyboardHelper getUIKeyboardType:options[@"type"]];
      [self.textInputbar.textView setKeyboardType:keyBoardType];
    }
  }
  

//  [self.textInputbar.textView setKeyboardType:UIKeyboardTypePhonePad];

  if ([options[@"showKeyboard"] boolValue]) {
    [self presentKeyboard:YES];
  }

  NSDictionary *leftButton = options[@"leftButton"];
  if (leftButton != nil) {
    _disableLefButtonWhenTextEntered = [leftButton[@"disabledWhenTextEntered"] boolValue];
    NSString *type = leftButton[@"type"];
    if ([@"fa" isEqualToString:type] || [@"fontawesome" isEqualToString:type]) {
      [NativeKeyboardHelper setFAImage:leftButton[@"value"] onButton:self.leftButton withColor:leftButton[@"color"]];
    }
  }

  // change the label and color of the send button
  NSDictionary* rightButton = options[@"rightButton"];
  if (rightButton != nil) {
    NSString *type = rightButton[@"type"];
    NSString *color = rightButton[@"color"];
    if ([@"text" isEqualToString:type]) {
      [self.rightButton setTitle:rightButton[@"value"] forState:UIControlStateNormal];
      if (color != nil) {
        [self.rightButton setTintColor:[NativeKeyboardHelper colorFromHexString:color]];
      }
    } else if ([@"fa" isEqualToString:type] || [@"fontawesome" isEqualToString:type]) {
      [NativeKeyboardHelper setFAImage:rightButton[@"value"] onButton:self.rightButton withColor:color];
    }
    [self.rightButton setEnabled:text.length > 0];
  }
}

+ (SLKCounterStyle) getSLKCounterStyle:(NSString*)style {
  if (style == nil) {
    return SLKCounterStyleNone;
  }
  style = style.lowercaseString;
  if ([style isEqualToString:@"split"]) {
    return SLKCounterStyleSplit;
  } else if ([style isEqualToString:@"countdown"]) {
    return SLKCounterStyleCountdown;
  } else if ([style isEqualToString:@"countdownreversed"]) {
    return SLKCounterStyleCountdownReversed;
  } else {
    return SLKCounterStyleNone;
  }
}

@end