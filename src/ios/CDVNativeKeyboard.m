#import "CDVNativeKeyboard.h"
#import "NKSLKTextViewController.h"

@implementation CDVNativeKeyboard

BOOL DEBUG_KEYBOARD = NO;

// TODO move as much as possible to the helper, and move this to the framwework and wire the Cordova-SLK stuff via the NKHelper class
NKSLKTextViewController * tvc;

UIToolbar * toolBar;
NSString * callbackId;
double offsetTop, lineSpacing;
BOOL textarea, wasTextarea;
int maxlength;

- (void)registerForKeyboardNotifications
{
  // especially useful for the messenger component
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification object:nil];

  // for the textField
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textFieldDidChange:)
                                               name:UITextFieldTextDidChangeNotification object:self.textField];
}

// Called when the UIKeyboardWillShowNotification is sent.
- (void)keyboardWillShow:(NSNotification*)aNotification
{
  if (tvc != nil) {
    CGSize kbSize = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    [tvc updateKeyboardHeight:kbSize.height];
  }
}

- (void)pluginInitialize
{
  self.textView = [NKTextView new];
  [self.textView configure:DEBUG_KEYBOARD];
  self.textView.delegate = self;

  self.textField = [NKTextField new];
  [self.textField configure:DEBUG_KEYBOARD];
  self.textField.delegate = self;

  toolBar = [UIToolbar new];

  [self registerForKeyboardNotifications];
}

- (UIControl<NKTextInput>*) getActiveTextViewOrField {
  return (UIControl<NKTextInput>*)(textarea ? self.textView : self.textField);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  // this event is triggered implicitly by our code, so overriding the default impl which scrolls back to top
}

- (void)showMessengerKeyboard:(CDVInvokedUrlCommand*)command {
  if (tvc != nil) {
    [tvc presentKeyboard:YES];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  } else {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Call 'showMessenger' first. You can use this method to give focus back to the messenger once its lost."];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }
}

- (void)showMessenger:(CDVInvokedUrlCommand*)command {
  if (![NativeKeyboardHelper allowFeature:NKFeatureMessenger]) {
    // TODO error callback (errorlog must be done in featurecheck)
    return;
  }

  NSDictionary* options = [command argumentAtIndex:0];

  [self.textView removeFromSuperview];
  [self.textField removeFromSuperview];

  if (tvc == nil) {
      tvc = [[NKSLKTextViewController alloc] initWithScrollView:self.webView.scrollView];
  }

  [tvc configureMessengerWithCommand:command andCommandDelegate:self.commandDelegate];
    
  NSArray * ors = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UISupportedInterfaceOrientations"];
  NSArray * suppOrientations = [((CDVViewController*)self.viewController) parseInterfaceOrientations:ors];
  [tvc setSupportedInterfaceOrientations:suppOrientations];

    // set the vc backgroundcolor to the color of slackvc (which has a default backgroundcolor of #F7F7F7) because otherwise it looks ugly on iPhone X when the keyboard is closed
    NSString* backgroundColor = options[@"backgroundColor"];
    if (backgroundColor == nil) {
        backgroundColor = @"#F7F7F7";
    }
    self.viewController.view.backgroundColor = [NativeKeyboardHelper colorFromHexString:backgroundColor];

  [tvc setTextInputbarHidden:YES animated:NO];

  // if an AdMob banner is displayed without overlap there will be 2 subviews, but it may have other causes as well
  long nrOfSubviews = [[self.webView.superview subviews] count];

  if (nrOfSubviews == 1) {
    [self.webView insertSubview:tvc.view atIndex:0];
  } else {
    UIView *sub2 = [[self.webView.superview subviews] objectAtIndex:1];
    NSString *classname = NSStringFromClass([sub2 class]);
    if ([classname containsString:@"Banner"]) {
      [self.viewController.view addSubview:tvc.view];
      [self.webView.superview bringSubviewToFront:sub2];
    } else {
      [self.webView insertSubview:tvc.view atIndex:0];
    }
  }

  [tvc setTextInputbarHidden:NO animated:[options[@"animated"] boolValue]];

  if ([options[@"scrollToBottomAfterMessengerShows"] boolValue]) {
    [self.webView.scrollView scrollRectToVisible:CGRectInfinite animated:YES];
  }

  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"ready":@(YES)}];
  pluginResult.keepCallback = [NSNumber numberWithBool:YES];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)hideMessenger:(CDVInvokedUrlCommand*)command {
  if (tvc != nil) {
    NSDictionary* options = [command argumentAtIndex:0];
    [tvc setTextInputbarHidden:YES animated:[options[@"animated"] boolValue]];
//    tvc = nil;
  }
}

- (void)updateMessenger:(CDVInvokedUrlCommand*)command {
  if (tvc != nil) {
    NSDictionary* options = [command argumentAtIndex:0];
    if (options[@"text"]) {
      tvc.textView.text = options[@"text"];
    }

    if ([options[@"showKeyboard"] boolValue]) {
      [tvc presentKeyboard:YES];
    }

    if (options[@"caretIndex"] != nil) {
      int caretIndex = [options[@"caretIndex"] intValue];
      UITextPosition *textPosition = [tvc.textView positionFromPosition:tvc.textView.beginningOfDocument offset:caretIndex];
      [tvc.textView setSelectedTextRange:[tvc.textView textRangeFromPosition:textPosition toPosition:textPosition]];
    }

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  } else {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Call 'showMessenger' first."];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }
}

- (void)hideMessengerKeyboard:(CDVInvokedUrlCommand*)command {
  if (tvc != nil) {
    [tvc dismissKeyboard:YES];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  } else {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Keyboard wasn't showing."];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }
}

/*
 It's a bit hard to find a thing that can run in the background here since it's mainly UI stuff. But if we do, we can use:
  [self.commandDelegate runInBackground:^{
    // and to have something in there run on the main thread (the UI stuff):
    dispatch_async(dispatch_get_main_queue(), ^{
    })
  }];
 */
- (void)show:(CDVInvokedUrlCommand*)command {
  if (![NativeKeyboardHelper checkLicense]) {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No valid license found; usage of the native keyboard plugin is restricted to 5 minutes."];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    return;
  }

  NSDictionary* options = [command argumentAtIndex:0];
  wasTextarea = textarea;
  textarea = [@"textarea" isEqualToString:options[@"type"]];

  UIControl<NKTextInput>* field = [self getActiveTextViewOrField];

  // to make this play nice with the messenger, we need to do:
  if (textarea) {
    if (!wasTextarea) {
      [self.textField hide];
    }
  } else {
    if (wasTextarea) {
      [self.textView hide];
    }
  }
  [field show];
  if (![field isDescendantOfView:self.viewController.view]) {
    [self.viewController.view addSubview:field];
  }

  allowClose = NO;

  CGRect screenBounds = [[UIScreen mainScreen] bounds];

  if (options[@"type"] != nil) {
    if ([NativeKeyboardHelper allowFeature:NKFeatureKeyboardType]) {
      UIKeyboardType keyBoardType = [NativeKeyboardHelper getUIKeyboardType:options[@"type"]];
      [field setKeyboardType:keyBoardType];
    } else {
      // TODO errorcallback
      return;
    }
  }

  NSString *returnKeyType = nil;
  NSDictionary *returnKeyOptions = options[@"returnKey"];
  if (returnKeyOptions != nil) {
    returnKeyType = returnKeyOptions[@"type"];
  }
  if (returnKeyType == nil) {
    if (!textarea) {
      // change the default of an input text field to 'done' (instead of 'return')
      returnKeyType = @"done";
    }
  }
  [field setReturnKeyType:[NativeKeyboardHelper getUIReturnKeyType:returnKeyType]];
  [field setKeyboardAppearance:[NativeKeyboardHelper getUIKeyboardAppearance:options[@"appearance"]]];

  double phoneHeight = screenBounds.size.height;
  // prolly better to grab it like this: https://github.com/driftyco/ionic-plugin-keyboard/blob/master/src/ios/IonicKeyboard.m#L27
  double keyboardHeight = 240;

  NSDictionary *accessorybar = options[@"accessorybar"];
  if (accessorybar == nil) {
    [field setInputAccessoryView:nil];
  } else {
    int toolbarHeight = 44;
    keyboardHeight += toolbarHeight;

    toolBar.frame = CGRectMake(0, 0, screenBounds.size.width, toolbarHeight);

    NSArray *btns = accessorybar[@"buttons"];
    NSMutableArray<UIBarButtonItem*> *buttons = [[NSMutableArray alloc] initWithCapacity:btns.count];
    for (int i = 0; i < (int)btns.count; i++) {
      NSDictionary* btn = btns[i];
      NSString *btnType = btn[@"type"];
      NSString *btnValue = btn[@"value"];
      UIBarButtonItem *button;
      if (btnType == nil) {
        continue;
      }
      if ([btnType isEqualToString:@"system"]) {
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:[NativeKeyboardHelper getUIBarButtonSystemItem:btnValue]
                                                               target:self
                                                               action:@selector(buttonTapped:)];
      } else if ([btnType isEqualToString:@"text"]) {
        button = [[UIBarButtonItem alloc] initWithTitle:btnValue
                                                  style:[NativeKeyboardHelper getUIBarButtonItemStyle:btn[@"style"]]
                                                 target:self
                                                 action:@selector(buttonTapped:)];
      } else if ([btnType isEqualToString:@"fa"] || [btnType isEqualToString:@"fontawesome"]) {
        UIImage* image;
        if (btn[@"fontSize"] == nil) {
          image = [NativeKeyboardHelper getFAImage:btnValue];
        } else {
          image = [NativeKeyboardHelper getFAImage:btnValue withFontSize:[btn[@"fontSize"] intValue]];
        }
        if (image != nil) {
          button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(buttonTapped:)];
        }
      } else if ([btnType isEqualToString:@"ionicon"]) {
        UIImage* image;
        image = [NativeKeyboardHelper getIonImage:btnValue withFontSize:[btn[@"fontSize"] intValue] andColor:btn[@"color"]];
        if (image != nil) {
          button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(buttonTapped:)];
        }
      }
      if (button != nil) {
        button.tag = i;
        NSNumber *width = btn[@"width"];
        if (width != nil) {
          button.width = width.floatValue;
        }
        NSString *color = btn[@"color"];
        if (color != nil) {
          // TODO this only seems to work the first time.. then toolBar.tintColor wins.. TRY ON REAL DEVICE? or we need to move this all the way down - or the entiry accbar stuff
//          button.tintColor = [NativeKeyboardHelper colorFromHexString:color];
        }
        [buttons addObject:button];
      }
    }

    if (buttons.count > 0) {
      [NativeKeyboardHelper setUIBarStyle:accessorybar[@"style"] forToolbar:toolBar];
      [toolBar setItems:buttons];
      [field setInputAccessoryView:toolBar];
      toolBar.tintColor = [NativeKeyboardHelper colorFromHexString:accessorybar[@"color"]];
    } else {
      [field setInputAccessoryView:nil];
    }
  }

  // used elsewhere
  maxlength = [options[@"maxlength"] intValue];
  offsetTop = [options[@"offsetTop"] doubleValue];

  double yCorrection = [field updatePostion:options
                             forPhoneHeight:phoneHeight
                          andKeyboardHeight:keyboardHeight];

  // adjust the scrollposition if needed
  if (yCorrection > 0) {
    // set this to 0 to hide the caret initially
    field.alpha = 0;

    // in case we were already editing, but now hopping to a field lower on the screen
    // enable scrolling and hide the caret for a sec
    if (!self.webView.scrollView.isScrollEnabled) {
      [self.webView.scrollView setScrollEnabled:YES];
      field.alpha = 0;
    }

    [self.webView.scrollView setContentOffset: CGPointMake(0, yCorrection + offsetTop) animated:YES];

    // do this to early and things will crash
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
      [self.webView.scrollView setScrollEnabled:NO];
      self.webView.scrollView.delegate = self;
    });

    // now show the caret
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 300 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
      field.alpha = 1;
    });
  } else {
    [self.webView.scrollView setScrollEnabled:NO];
    self.webView.scrollView.delegate = self;
  }

  [NativeKeyboardHelper applyCaretColor:options[@"caretColor"] toField:field];

  [NativeKeyboardHelper applyFont:[FontResolver fontWithDescription:options[@"font"]]
                 andTextAlignment:options[@"textAlign"]
                           toText:options[@"text"]
                   withLineHeight:[options[@"lineHeight"] doubleValue]
                          toField:field];

  if (field.superview == nil) {
    [self.webView addSubview: field];
  }

  if (!DEBUG_KEYBOARD) {
    [field setTextColor:[UIColor clearColor]];
  }
  [field reloadInputViews];
  [field becomeFirstResponder];

  callbackId = command.callbackId;
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
  pluginResult.keepCallback = [NSNumber numberWithBool:YES];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
  // by setting this to NO you can keep the keyboard open (and handle closing it from JS or accbar buttons)
  return !textarea || allowClose;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
  // by setting this to NO you can keep the keyboard open (and handle closing it from JS or accbar buttons)
  // However, when switching to a textarea now we need to return YES so focus can be set to the textarea
  return textarea || allowClose;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
  return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  return YES;
}

- (void) buttonTapped:(UIBarButtonItem*)button {
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"buttonIndex":@(button.tag)}];
  pluginResult.keepCallback = [NSNumber numberWithBool:YES];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

BOOL allowClose = NO;
- (void)hide:(CDVInvokedUrlCommand*)command {
  allowClose = YES;
  UIControl<NKTextInput>* field = [self getActiveTextViewOrField];
  if (field != nil) {
    [field endEditing:YES];
  }
  [self close:nil];
}

- (void) close:(id)type {
  UIControl<NKTextInput>* field = [self getActiveTextViewOrField];
  [field hide];
  [self.webView.scrollView setScrollEnabled:YES];
  self.webView.scrollView.delegate = nil;

  [self dismissKeyboard:YES];

  // restore the scroll position
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
    [self.webView.scrollView setContentOffset: CGPointMake(0, offsetTop) animated:YES];
  });
}

- (void)dismissKeyboard:(BOOL)animated
{
  // Dismisses the keyboard from any first responder in the window.
  UIControl<NKTextInput>* field = [self getActiveTextViewOrField];
  if (![field isFirstResponder]) {
    [self.webView.window endEditing:NO];
  }
  if (animated) {
    [field resignFirstResponder];
  } else {
    [UIView performWithoutAnimation:^{
      [field resignFirstResponder];
    }];
  }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text {
  // need to escape these to be able to pass to the webview
  if ([text isEqualToString:@"\n"]) {
      // send event to JS
      CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"returnKeyPressed":@(YES)}];
      pluginResult.keepCallback = [NSNumber numberWithBool:NO];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
      // end editing
      allowClose = YES;
      [textField endEditing:YES];
      return NO;
    // ignore the 'tab' character
  } else if ([text isEqualToString:@"\t"]) {
    return NO;
  }

  if (maxlength > 0 && textField.text.length >= maxlength && text.length > 0) {
    return NO;
  }
  return YES;
};

// updated with the added text after every keypress (or empty string if backspace)
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  if ([text isEqualToString:@"\n"]) {
    // need to escape these to be able to pass to the webview
    text = @"\\n";
  } else if ([text isEqualToString:@"\t"]) {
    // ignore the 'tab' character
    return NO;
  }

  if (maxlength > 0 && textView.text.length >= maxlength && text.length > 0) {
    return NO;
  }
  return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"textFieldDidEndEditing":@(YES)}];
  pluginResult.keepCallback = [NSNumber numberWithBool:YES];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
};

- (void)textFieldDidChange :(NSNotification *)notification {
  UITextField *textField = (UITextField*)notification.object;
  NSString *text = [textField text];

  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"text":text}];
  pluginResult.keepCallback = [NSNumber numberWithBool:YES];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

// updated with the entire view content after every keypress
- (void)textViewDidChange:(UITextView *)textView {
  NSString *text = textView.text;
  // need to escape these to be able to pass to the webview
  if ([text isEqualToString:@"\n"]) {
    text = @"\\n";
  }
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"text":text}];
  pluginResult.keepCallback = [NSNumber numberWithBool:YES];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];

  /*
  // this makes sure the textarea scrolls down when the end of the visible area is reached
  CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
  CGFloat overflowY = line.origin.y + line.size.height - ( textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top );
  if ( overflowY > 0 ) {
    // We are at the bottom of the visible text and introduced a line feed, scroll down (iOS 7 does not do it)
    // Scroll caret to visible area
    CGPoint offset = textView.contentOffset;
    offset.y += overflowY + 7; // leave 7 pixels margin
    // Cannot animate with setContentOffset:animated: or caret will not appear
    [UIView animateWithDuration:.2 animations:^{
      [textView setContentOffset:offset];
    }];
  }
   */
}

@end
