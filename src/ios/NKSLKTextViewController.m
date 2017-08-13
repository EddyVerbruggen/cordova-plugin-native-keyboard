#import "NKSLKTextViewController.h"

@implementation NKSLKTextViewController

id <CDVCommandDelegate> _commandDelegate;
CDVInvokedUrlCommand* _command;
NSArray * _supportedOrientations;
CGFloat _baseKeyboardHeight = 224; // fallback
CGFloat _defaultContentHeight = 34;
CGFloat _lastContentHeight = 34;
BOOL _disableLeftButtonWhenTextEntered;
BOOL _keepOpenAfterSubmit;

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
  [self didChangeKeyboardStatus:SLKKeyboardStatusDidShow];
}

// The default is 'NO' which also means the 'keyboardWillHide' is not fired.
// Note that for WKWebView users this will return 'NO' again, so that event is not fired.
- (BOOL)forceTextInputbarAdjustmentForResponder:(UIResponder *)responder
{
  return [responder isKindOfClass:[UIWebView class]];
}

- (void)didChangeKeyboardStatus:(SLKKeyboardStatus)status {
  [super didChangeKeyboardStatus:status];
  CGFloat height = self.textView.frame.size.height;
  _lastContentHeight = height;
  if (SLKKeyboardStatusWillShow == status) {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"keyboardWillShow":@(YES), @"keyboardHeight":[NSNumber numberWithFloat:_baseKeyboardHeight+_lastContentHeight]}];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    [_commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
  } else if (SLKKeyboardStatusDidShow == status) {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"keyboardDidShow":@(YES), @"keyboardHeight":[NSNumber numberWithFloat:_baseKeyboardHeight+_lastContentHeight]}];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    [_commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
  } else if (SLKKeyboardStatusWillHide == status) {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"keyboardWillHide":@(YES)}];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    [_commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
  } else if (SLKKeyboardStatusDidHide == status) {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"keyboardDidHide":@(YES)}];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    [_commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
  }
}

// you can update JS on every keypress, but it makes more sense to send back the result when the rightbutton is pressed -- however it would be nice to pass back the grow height so the webview can move a bit -- or perhaps we can do that ourselves here, based on the contentheight etc.. if it's more than half the screen, move it down
- (void)textDidUpdate:(BOOL)animated {
  // Notifies the view controller that the text did update.
  [super textDidUpdate:animated];

  NSString *text = self.textView.text;
  // need to escape these to be able to pass to the webview
  if ([text isEqualToString:@"\n"]) {
    text = @"\\n";
  }
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"textChanged":text}];
  pluginResult.keepCallback = [NSNumber numberWithBool:YES];
  [_commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];

  if (_disableLeftButtonWhenTextEntered) {
    [self.leftButton setEnabled:self.textView.text.length == 0];
  }
  // the initial position of the webview is the responsibility of the dev,
  // but we'll reposition it if the contentarea grows/shrinks
  CGFloat height = self.textView.frame.size.height;
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
  if (![NativeKeyboardHelper checkLicense]) {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No valid license found; usage of the native keyboard plugin is restricted to 5 minutes."];
    [_commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
    return;
  }
  NSString *text = self.textView.text;
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"messengerRightButtonPressed":@(YES), @"text":text}];
  pluginResult.keepCallback = [NSNumber numberWithBool:YES];
  [_commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
  if (!_keepOpenAfterSubmit) {
    [self dismissKeyboard:YES];
  }
  [super didPressRightButton:sender];
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView {
  self = [super initWithScrollView:scrollView];
  return self;
}

- (void) configureMessengerWithCommand:(CDVInvokedUrlCommand*)command andCommandDelegate:(id <CDVCommandDelegate>)commandDelegate {
  if (![NativeKeyboardHelper checkLicense]) {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No valid license found; usage of the native keyboard plugin is restricted to 5 minutes."];
    [commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    return;
  }

  _command = command;
  _commandDelegate = commandDelegate;

  NSDictionary* options = [_command argumentAtIndex:0];
  NSNumber* maxChars = options[@"maxChars"];
  if (maxChars != nil) {
    self.textInputbar.maxCharCount = [maxChars intValue];
  } else {
    // limitless
    self.textInputbar.maxCharCount = 0;
  }

  self.textView.text = options[@"text"];

  // if a size is passed in we can set it here:
//  [self.textView setFont:[UIFont systemFontOfSize:15.0]];

  // style the messageview
  self.textView.placeholder = options[@"placeholder"];
  NSString* placeholderColor = options[@"placeholderColor"];
  if (placeholderColor != nil) {
    self.textView.placeholderColor = [NativeKeyboardHelper colorFromHexString:placeholderColor];
  }
  NSString* textViewBackgroundColor = options[@"textViewBackgroundColor"];
  if (textViewBackgroundColor != nil) {
    self.textView.backgroundColor = [NativeKeyboardHelper colorFromHexString:textViewBackgroundColor];
  }
  NSString* textViewBorderColor = options[@"textViewBorderColor"];
  if (textViewBorderColor != nil) {
    self.textView.layer.borderColor = [NativeKeyboardHelper colorFromHexString:textViewBorderColor].CGColor;
  }
  //  self.textView.pastableMediaTypes = SLKPastableMediaTypeAll;

  //  [self.leftButton setImage:[UIImage imageNamed:@"icn_upload"] forState:UIControlStateNormal];
  self.bounces = YES;
  self.shakeToClearEnabled = NO;
  self.keyboardPanningEnabled = YES;
  self.shouldScrollToBottomAfterKeyboardShows = [options[@"scrollToBottomAfterKeyboardShows"] boolValue];
  self.inverted = NO;
  _keepOpenAfterSubmit = [options[@"keepOpenAfterSubmit"] boolValue];

  NSString* backgroundColor = options[@"backgroundColor"];
  if (backgroundColor != nil) {
    self.textInputbar.backgroundColor = [NativeKeyboardHelper colorFromHexString:backgroundColor];
  }

  NSString *text = options[@"text"];
  self.textView.text = text;
  if (options[@"textColor"] != nil) {
    self.textView.textColor = [NativeKeyboardHelper colorFromHexString:options[@"textColor"]];
  }

  // TODO feature-allowed check
  SLKCounterStyle slkCounterStyle = [NKSLKTextViewController getSLKCounterStyle:options[@"counterStyle"]];
  self.textInputbar.counterStyle = slkCounterStyle;
  self.textInputbar.counterPosition = SLKCounterPositionTop; // TODO pass in some day

  if (options[@"type"] != nil) {
    if ([NativeKeyboardHelper allowFeature:NKFeatureKeyboardType]) {
      UIKeyboardType keyBoardType = [NativeKeyboardHelper getUIKeyboardType:options[@"type"]];
      [self.textView setKeyboardType:keyBoardType];
    }
  } else {
    // IMO this is better than the default (UIKeyboardTypeTwitter)
    [self.textView setKeyboardType:UIKeyboardTypeDefault];
  }

  if (options[@"appearance"] != nil && [@"dark" isEqualToString:options[@"appearance"]]) {
    self.textView.keyboardAppearance = UIKeyboardAppearanceDark;
  }

  if ([options[@"secure"] boolValue]) {
    // this is currently the only way to keep the 'Predictive text' bar away, but also disables Emoji entry
    self.textView.secureTextEntry = YES;
  }

  if ([options[@"showKeyboard"] boolValue]) {
    // this needs a little delay to work
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [self presentKeyboard:YES];
    });
  }

  NSDictionary *leftButton = options[@"leftButton"];
  if (![leftButton isKindOfClass:[NSNull class]] && leftButton != nil) {
    _disableLeftButtonWhenTextEntered = [leftButton[@"disabledWhenTextEntered"] boolValue];
    NSString *type = leftButton[@"type"];
    NSString *color = leftButton[@"color"];
    if (color == nil) {
      color = @"#007AFF"; // blue
    }
    if ([@"fa" isEqualToString:type] || [@"fontawesome" isEqualToString:type]) {
      [NativeKeyboardHelper setFAImage:leftButton[@"value"] onButton:self.leftButton withColor:color];
    } else if ([@"ion" isEqualToString:type] || [@"ionicon" isEqualToString:type]) {
      [NativeKeyboardHelper setIonImage:leftButton[@"value"] onButton:self.leftButton withColor:color];
    } else {
      // 'text' type is not yet supported, see https://github.com/slackhq/SlackTextViewController/issues/457
      NSLog(@"On iOS type 'text' is not supported (yet) on the left button.");
    }
  }

  // change the label and color of the send button
  NSDictionary* rightButton = options[@"rightButton"];
  if ([rightButton isKindOfClass:[NSNull class]] || rightButton == nil) {
    NSLog(@"No rightButton configured, but it's a pretty useful thing to have really..");
  } else {
    NSString *type = rightButton[@"type"];
    NSString *color = rightButton[@"color"];
    if (color == nil) {
      color = @"#007AFF"; // blue
    }
    if ([@"text" isEqualToString:type]) {
      [self.rightButton setTitle:rightButton[@"value"] forState:UIControlStateNormal];
      if (color != nil) {
        [self.rightButton setTintColor:[NativeKeyboardHelper colorFromHexString:color]];
      }
      NSString *textStyle = rightButton[@"textStyle"];
      if ([textStyle isKindOfClass:[NSNull class]] || textStyle == nil || [@"normal" isEqualToString:textStyle]) {
        self.rightButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
      } else if ([@"bold" isEqualToString:textStyle]) {
        self.rightButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
      } else if ([@"italic" isEqualToString:textStyle]) {
        self.rightButton.titleLabel.font = [UIFont italicSystemFontOfSize:15.0];
      }
    } else if ([@"fa" isEqualToString:type] || [@"fontawesome" isEqualToString:type]) {
      [NativeKeyboardHelper setFAImage:rightButton[@"value"] onButton:self.rightButton withColor:color];
    } else if ([@"ion" isEqualToString:type] || [@"ionicon" isEqualToString:type]) {
      [NativeKeyboardHelper setIonImage:rightButton[@"value"] onButton:self.rightButton withColor:color];
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
