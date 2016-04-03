#import "CDVNativeKeyboard.h"
#import "NKSLKTextViewController.h"

@implementation CDVNativeKeyboard

bool DEBUG_KEYBOARD = NO;

NKSLKTextViewController * tvc;
UIToolbar * toolBar;
NSString * callbackId;
double offsetTop;
double lineSpacing;
bool textarea;
int maxlength;

//  - (void)addTarget:(nullable id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

//  [textView addTarget:self
//               action:@selector(textFieldDidChange:)
//     forControlEvents:UIControlEventEditingChanged];

// note that we only need these for the messenger component
- (void)registerForKeyboardNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWasShown:)
                                               name:UIKeyboardDidShowNotification object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillBeHidden:)
                                               name:UIKeyboardWillHideNotification object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
  NSDictionary* info = [aNotification userInfo];
  CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  
  //  UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
  //  self.webView.scrollView.contentInset = contentInsets;
  //  self.webView.scrollView.scrollIndicatorInsets = contentInsets;
  
  // If active text field is hidden by keyboard, scroll it so it's visible
  // Your app might not need or want this behavior.
  //  CGRect aRect = self.webView.frame;
  CGFloat kbHeight = kbSize.height;
  //  aRect.size.height -= kbHeight;
  //  if (!CGRectContainsPoint(aRect, activeField.frame.origin) ) {
  //    [self.webView.scrollView scrollRectToVisible:activeField.frame animated:YES];
  //  }
  
  if (tvc != nil) {
    [tvc updateKeyboardHeight:kbHeight];
  }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
  //  UIEdgeInsets contentInsets = UIEdgeInsetsZero;
  //  self.webView.scrollView.contentInset = contentInsets;
  //  self.webView.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)pluginInitialize
{
  [self registerForKeyboardNotifications];
  
  self.textView = [[UITextView alloc] init];
  
  //    textView.layoutManager.delegate = self;
  toolBar = [[UIToolbar alloc] init];
  
  if (DEBUG_KEYBOARD) {
    self.textView.textColor = [UIColor greenColor];
    self.textView.backgroundColor = [UIColor lightGrayColor];
    self.textView.alpha = 0.5;
  } else {
    self.textView.backgroundColor = [UIColor clearColor];
  }
  
  // we don't want these
  [self.textView setSpellCheckingType:UITextSpellCheckingTypeNo];
  [self.textView setAutocorrectionType:UITextAutocorrectionTypeNo];
  self.textView.delegate = self;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  // this event is triggered implicitly by our code, so override the default impl which scrolls back to top
}

- (void)showMessenger:(CDVInvokedUrlCommand*)command {
  if (![NativeKeyboardHelper allowFeature:NKFeatureMessenger]) {
    return;
  }

  NSDictionary* options = [command argumentAtIndex:0];

  [self.textView removeFromSuperview];

  tvc = [[NKSLKTextViewController alloc] initWithScrollView:self.webView.scrollView
                                                withCommand:command
                                         andCommandDelegate:self.commandDelegate];

  NSArray * ors = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UISupportedInterfaceOrientations"];
  NSArray * suppOrientations = [((CDVViewController*)self.viewController) parseInterfaceOrientations:ors];
  [tvc setSupportedInterfaceOrientations:suppOrientations];
    
  // if a backgroundcolor is passed in use that (TODO), otherwise use the webview bgcolor
  tvc.view.backgroundColor = self.webView.backgroundColor;
  
  [tvc setTextInputbarHidden:YES animated:NO];
  [self.viewController.view addSubview:tvc.view];
  [tvc setTextInputbarHidden:NO animated:[options[@"animated"] boolValue]];
}

- (void)hideMessenger:(CDVInvokedUrlCommand*)command {
  if (tvc != nil) {
    NSDictionary* options = [command argumentAtIndex:0];
    [tvc setTextInputbarHidden:YES animated:[options[@"animated"] boolValue]];
    tvc = nil;
  }
}

/*
 It's a bit hard to find a thing that can run in the background here since it's mainly UI stuff.
 But if we do, we can use:
 [self.commandDelegate runInBackground:^{
 // and to have something in there run on the main thread (the UI stuff):
 dispatch_async(dispatch_get_main_queue(), ^{
 })
 }];
 */
- (void)show:(CDVInvokedUrlCommand*)command {
  NSDictionary* options = [command argumentAtIndex:0];

  // to make this play nice with the messenger, we need to do:
  if (![self.textView isDescendantOfView:self.viewController.view]) {
    [self.viewController.view addSubview:self.textView];
  }
  
  allowClose = NO;
  [self.textView setHidden:NO];
  
  offsetTop = [options[@"offsetTop"] doubleValue];
  
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  
  if (options[@"type"] != nil) {
    if ([NativeKeyboardHelper allowFeature:NKFeatureKeyboardType]) {
      UIKeyboardType keyBoardType = [NativeKeyboardHelper getUIKeyboardType:options[@"type"]];
      [self.textView setKeyboardType:keyBoardType];
    }
  }
  textarea = [@"textarea" isEqualToString:options[@"type"]];

  
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
  [self.textView setReturnKeyType:[NativeKeyboardHelper getUIReturnKeyType:returnKeyType]];
  
  [self.textView setKeyboardAppearance:[NativeKeyboardHelper getUIKeyboardAppearance:options[@"appearance"]]];
  
  double phoneHeight = screenBounds.size.height;
  double keyboardHeight = 240;
  
  NSDictionary *accessorybar = options[@"accessorybar"];
  if (accessorybar == nil) {
    self.textView.inputAccessoryView = nil;
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
      self.textView.inputAccessoryView = toolBar;
      toolBar.tintColor = [NativeKeyboardHelper colorFromHexString:accessorybar[@"color"]];
    } else {
      self.textView.inputAccessoryView = nil;
    }
  }
  
  if (textarea) {
    self.textView.textContainer.maximumNumberOfLines = 0; // no limit, which is not correct perse
  } else {
    self.textView.textContainer.maximumNumberOfLines = 1;
  }

  // used elsewhere
  maxlength = [options[@"maxlength"] intValue];

  NSDictionary *padding = options[@"padding"];
  //  double paddingTop = [padding[@"top"] doubleValue];
  double paddingLeft = [padding[@"left"] doubleValue];
  //  double paddingBottom = [padding[@"bottom"] doubleValue];
  //  double paddingRight = [padding[@"right"] doubleValue];
  // TODO for a textarea the padding is not correct
  //textView.textContainerInset = UIEdgeInsetsMake(paddingTop, paddingLeft, paddingBottom, paddingRight);
  if (textarea) {
    self.textView.textContainerInset = UIEdgeInsetsMake(0, 3, 0, 0);
  } else {
    self.textView.textContainerInset = UIEdgeInsetsZero;
  }
  
  NSDictionary *margin = options[@"margin"];
  double marginTop = [margin[@"top"] doubleValue];
//  double marginLeft = [margin[@"left"] doubleValue];
  //  double marginBottom = [margin[@"bottom"] doubleValue];
  //  double marginRight = [margin[@"right"] doubleValue];
  
  // TODO using this doesn't seem correct..
  // ........... but let's first throw it in an ionic starter
  //  double borderRadius = [options[@"borderRadius"] doubleValue];
  
  NSDictionary *border = options[@"border"];
  double borderLeft = [border[@"left"] doubleValue];
  double borderTop = [border[@"top"] doubleValue];
  //  double borderBottom = [border[@"bottom"] doubleValue];
  //  double borderRight = [border[@"right"] doubleValue];
  
  //  double verticalAlignMiddleCompensation = 6;
  
  //  [textView setContentInset:UIEdgeInsetsMake(topCorrect,0,0,0)];
  
  NSDictionary *box = options[@"box"];
  double left = [box[@"left"] doubleValue] + borderLeft + paddingLeft; // - marginLeft;
  double top = [box[@"top"] doubleValue] + borderTop + marginTop;
  double width = [box[@"width"] doubleValue] - 8 + (textarea ? 3 : 0);
  double height = [box[@"height"] doubleValue];
  
  double setOriginYto = phoneHeight - keyboardHeight - height;
  
  self.textView.frame = CGRectMake(left, top > setOriginYto ? setOriginYto : top, width, height);
  
  NSString *font = options[@"font"];
//  double fontSize = [font[@"size"] doubleValue];
//  NSArray *fontFamilies = [font[@"family"] componentsSeparatedByString:@","];
  
  UIFont *uiFont = [FontResolver fontWithDescription:font];
  
  // adjust the scrollposition if needed
  if (top > setOriginYto) {
    // set this to 0 to hide the caret initially
    self.textView.alpha = 0;

    // in case we were already editing, but now hopping to a field lower on the screen
    // enable scrolling and hide the caret for a sec
    if (!self.webView.scrollView.isScrollEnabled) {
      [self.webView.scrollView setScrollEnabled:YES];
      self.textView.alpha = 0;
    }

    [self.webView.scrollView setContentOffset: CGPointMake(0, (top-setOriginYto)+offsetTop) animated:YES];
    
    // do this to early and things will crash
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
      [self.webView.scrollView setScrollEnabled:NO];
      self.webView.scrollView.delegate = self;
    });
    
    // now show the caret
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 300 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
      self.textView.alpha = 1;
    });
  } else {
    [self.webView.scrollView setScrollEnabled:NO];
    self.webView.scrollView.delegate = self;
  }
  
  NSString *caretColor = options[@"caretColor"];
  if (caretColor != nil) {
    [self.textView setTintColor:[NativeKeyboardHelper colorFromHexString:caretColor]];
  }
  
  NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  double lineHeight = [options[@"lineHeight"] doubleValue];
  
  NSString *align = options[@"textAlign"];
  paragraphStyle.alignment = [NativeKeyboardHelper getNSTextAlignment:align];
  paragraphStyle.minimumLineHeight = lineHeight;
  paragraphStyle.maximumLineHeight = lineHeight;
  paragraphStyle.lineSpacing = lineHeight / 7.3; // it would be very nice to get rid of this magic number
  //  paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
  NSDictionary *attrsDictionary = @{
                                    NSFontAttributeName: uiFont,
                                    NSParagraphStyleAttributeName: paragraphStyle
                                    };
  
  NSString *text = options[@"text"];
  self.textView.textContainer.lineFragmentPadding = 0;
  self.textView.attributedText = [[NSAttributedString alloc] initWithString:text attributes:attrsDictionary];
  
  if (!textarea) {
    double verticalAlignMiddleCompensation = ([box[@"height"] doubleValue] - [self.textView contentSize].height * [self.textView zoomScale])/2.0;
    self.textView.frame = CGRectMake(left, self.textView.frame.origin.y + verticalAlignMiddleCompensation, width, height - verticalAlignMiddleCompensation);
  }
  
  if (self.textView.superview == nil) {
    [self.webView addSubview: self.textView];
  }
  if (!DEBUG_KEYBOARD) {
    self.textView.textColor = [UIColor clearColor];
  } else {
    //    textView.textColor = [UIColor greenColor];
  }
  
//  [self.webView addSubview:self.textView];

  [self.textView reloadInputViews];
  
  [self.textView becomeFirstResponder];
  
  callbackId = command.callbackId;
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
  pluginResult.keepCallback = [NSNumber numberWithBool:YES];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)textFieldDidChange:(NSNotification *)notification {
  //    UITextField *textField = (UITextField*)notification;
  //    NSString *text = [textField text];
  // Do whatever you like to respond to text changes here.
  //  [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"cordova.plugins.Keyboard.updateInput({'text': '%@'})", text]];
}

- (void) doneWriting:(id)x {
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView { // 1 ([self close] is called after this, before (2)
  // by setting this to NO you can keep the keyboard open (and handle closing it from JS or accbar buttons)
  return allowClose;
}

- (void) textViewDidEndEditing:(UITextView *)textView { // 2
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView { // 3
  return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView { // 4
}

- (void) buttonTapped:(UIBarButtonItem*)button {
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"buttonIndex":@(button.tag)}];
  pluginResult.keepCallback = [NSNumber numberWithBool:YES];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

BOOL allowClose = NO;
- (void)hide:(CDVInvokedUrlCommand*)command {
  allowClose = YES;
  if (self.textView != nil) {
    [self.textView endEditing:YES];
  }
  [self close:nil];
}

- (void) close:(id)type {
  //  [textView removeFromSuperview];
  [self.textView setHidden:YES];
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
  if (![self.textView isFirstResponder] /* && self.keyboardHC.constant > 0 */) {
    [self.webView.window endEditing:NO];
  }
  
  if (!animated) {
    [UIView performWithoutAnimation:^{
      [self.textView resignFirstResponder];
    }];
  }
  else {
    [self.textView resignFirstResponder];
  }
}

// updated with the added text after every keypress (or empty string if backspace)
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  NSLog(@"shouldChangeTextInRange: |%@|", text);
  // need to escape these to be able to pass to the webview
  if ([text isEqualToString:@"\n"]) {
    if (textarea) {
      text = @"\\n";
    } else {
      // send event to JS
      CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"returnKeyPressed":@(YES)}];
      pluginResult.keepCallback = [NSNumber numberWithBool:NO];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
      // end editing
      allowClose = YES;
      [textView endEditing:YES];
      return NO;
    }
  // ignore the 'tab' character
  } else if ([text isEqualToString:@"\t"]) {
    return NO;
  }

  if (maxlength > 0 && textView.text.length >= maxlength && text.length > 0) {
    return NO;
  }
  /*
   CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:text];
   pluginResult.keepCallback = [NSNumber numberWithBool:YES];
   [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
   */
  
  //  [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.plugins.toast.updateInput({text:'%@'})", text]];
  return YES;
}

// updated with the entire view content after every keypress
- (void)textViewDidChange:(UITextView *)textView {
  NSString *text = textView.text;
  NSLog(@"textViewDidChange: %@", text);
  // need to escape these to be able to pass to the webview
  if ([text isEqualToString:@"\n"]) {
    text = @"\\n";
  }
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"text":text}];
  pluginResult.keepCallback = [NSNumber numberWithBool:YES];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

@end