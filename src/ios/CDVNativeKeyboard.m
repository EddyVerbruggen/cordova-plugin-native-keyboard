#import "CDVNativeKeyboard.h"
#import "NKSLKTextViewController.h"

@implementation CDVNativeKeyboard

bool DEBUG_KEYBOARD = NO;

UITextView *textView;
UIToolbar *toolBar;
NSString *_callbackId;
double _offsetTop;
double _lineSpacing;
NKSLKTextViewController *tvc;


//  - (void)addTarget:(nullable id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

//  [textView addTarget:self
//               action:@selector(textFieldDidChange:)
//     forControlEvents:UIControlEventEditingChanged];

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
  
  textView = [[UITextView alloc] init];

  //    textView.layoutManager.delegate = self;
  toolBar = [[UIToolbar alloc] init];
  
  if (DEBUG_KEYBOARD) {
    textView.textColor = [UIColor greenColor];
    textView.backgroundColor = [UIColor lightGrayColor];
    textView.alpha = 0.5;
  } else {
    textView.backgroundColor = [UIColor clearColor];
  }
  
  textView.delegate = self;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  // this is the default btw, so we might as well remove this method
  [scrollView setContentOffset: CGPointZero];
}

- (void)showMessenger:(CDVInvokedUrlCommand*)command {
  if (![NativeKeyboardHelper allowFeature:NKFeatureMessenger]) {
    return;
  }
  if (tvc != nil) {
    [tvc setTextInputbarHidden:NO animated:YES];
    [tvc updateWithCommand:command andCommandDelegate:self.commandDelegate];
  } else {
    tvc = [[NKSLKTextViewController alloc] initWithScrollView:self.webView.scrollView
                                                  withCommand:command
                                           andCommandDelegate:self.commandDelegate];
    [self.viewController.view.window setRootViewController:tvc];
//    [self.viewController.view.window makeKeyAndVisible];
  }
}

- (void)hideMessenger:(CDVInvokedUrlCommand*)command {
  if (tvc != nil) {
    [tvc setTextInputbarHidden:YES animated:YES];
  }
}

- (void)show:(CDVInvokedUrlCommand*)command {
  NSDictionary* options = [command argumentAtIndex:0];
  
  allowHide = NO;
  
  // TODO
//  textView.returnKeyType = UIReturnKeyJoin;
  
  _offsetTop = [options[@"offsetTop"] doubleValue];
  
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  
  if (options[@"type"] != nil) {
    if ([NativeKeyboardHelper allowFeature:NKFeatureKeyboardType]) {
      UIKeyboardType keyBoardType = [NativeKeyboardHelper getUIKeyboardType:options[@"type"]];
      [textView setKeyboardType:keyBoardType];
    }
  }

  // TODO pass in these preferences (based on html5 tag autocorrect=false)
  [textView setSpellCheckingType:UITextSpellCheckingTypeNo];
  [textView setAutocorrectionType:UITextAutocorrectionTypeNo];
  
  // nice candidate for the paid version
  [textView setKeyboardAppearance:UIKeyboardAppearanceDefault];

  double phoneHeight = screenBounds.size.height;
  double keyboardHeight = 230;
  
  // TODO done vs trash, etc - pass in from webview
  NSDictionary *accessorybar = options[@"accessorybar"];
  if (accessorybar == nil) {
    textView.inputAccessoryView = nil;
  } else {
    int toolbarHeight = 44; // TODO depends on what's passed in, this is the default
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
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:[self getUIBarButtonSystemItem:btnValue]
                                                               target:self
                                                               action:@selector(buttonTapped:)];
      } else if ([btnType isEqualToString:@"text"]) {
        button = [[UIBarButtonItem alloc] initWithTitle:btnValue
                                                  style:[self getUIBarButtonItemStyle:btn[@"style"]]
                                                 target:self
                                                 action:@selector(buttonTapped:)];
      } else if ([btnType isEqualToString:@"fa"] || [btnType isEqualToString:@"fontawesome"]) {
        UIImage* image = [NativeKeyboardHelper getFAImage:btnValue];
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
          button.tintColor = [NativeKeyboardHelper colorFromHexString:color];
        }
        [buttons addObject:button];
      }
    }
    
    if (buttons.count > 0) {
      toolBar.barStyle = UIBarStyleDefault;
      toolBar.translucent = YES;
      [toolBar setItems:buttons];
      textView.inputAccessoryView = toolBar;
//      toolBar.tintColor = [UIColor orangeColor]; // TODO pass in
    } else {
      textView.inputAccessoryView = nil;
    }
  }
  
  NSDictionary *padding = options[@"padding"];
//  double paddingTop = [padding[@"top"] doubleValue];
  double paddingLeft = [padding[@"left"] doubleValue];
//  double paddingBottom = [padding[@"bottom"] doubleValue];
//  double paddingRight = [padding[@"right"] doubleValue];
  // TODO for a textarea the padding is not correct
  //textView.textContainerInset = UIEdgeInsetsMake(paddingTop, paddingLeft, paddingBottom, paddingRight);
  textView.textContainerInset = UIEdgeInsetsZero;
//  textView.textContainerInset = UIEdgeInsetsMake(6, 0, 0, 0);
  

  
  
  NSDictionary *margin = options[@"margin"];
  double marginTop = [margin[@"top"] doubleValue];
  double marginLeft = [margin[@"left"] doubleValue];
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
  double left = [box[@"left"] doubleValue] + borderLeft + paddingLeft - marginLeft;
  double top = [box[@"top"] doubleValue] + borderTop + marginTop;
  double width = [box[@"width"] doubleValue] - 8; // TODO
  double height = [box[@"height"] doubleValue];
  
  double setOriginYto = phoneHeight - keyboardHeight - height;
  
  textView.frame = CGRectMake(left, top > setOriginYto ? setOriginYto : top, width, height);
  
  NSDictionary *font = options[@"font"];
  double fontSize = [font[@"size"] doubleValue];
  NSArray *fontFamilies = [font[@"family"] componentsSeparatedByString:@","];
  
  // TODO font
  UIFont *uiFont = nil;
  for (int i = 0; i < (int)fontFamilies.count; i++) {
    NSString* fontFamily = [fontFamilies[i] stringByReplacingOccurrencesOfString:@"'" withString:@""];
    // TODO there's also -apple-system-something-else..
    if ([fontFamily isEqualToString:@"-apple-system"]) {
      uiFont = [UIFont systemFontOfSize:fontSize];
    } else {
      uiFont = [UIFont fontWithName:fontFamily size:fontSize];
    }
    if (uiFont != nil) {
      break;
    }
  }
  // fall back to this, otherwise the app will crash
  if (uiFont == nil) {
    uiFont = [UIFont systemFontOfSize:fontSize];
  }
  
  //    uiFont = [NativeKeyboard fontWithName:fontFamily sizeInPixels:fontSize*1.26];
  
  // adjust the scrollposition if needed
  if (top > setOriginYto) {
    if (!DEBUG_KEYBOARD) {
      // set this to 0 to hide the caret initially
      textView.alpha = 0;
    }
    [self.webView.scrollView setContentOffset: CGPointMake(0, (top-setOriginYto)+_offsetTop) animated:YES];
    
    // do this to early and things will crash
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
      [self.webView.scrollView setScrollEnabled:NO];
      self.webView.scrollView.delegate = self;
    });
    
    // now show the caret
    if (!DEBUG_KEYBOARD) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 300 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        textView.alpha = 1;
      });
    }
  } else {
    [self.webView.scrollView setScrollEnabled:NO];
    self.webView.scrollView.delegate = self;
  }
  
  NSString *caretColor = options[@"caretColor"]; // TODO add an if
  [[UITextView appearance] setTintColor:[NativeKeyboardHelper colorFromHexString:caretColor]];
  
  NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  double lineHeight = [options[@"lineHeight"] doubleValue];
  
  NSString *align = options[@"textAlign"];
  paragraphStyle.alignment = [self getNSTextAlignment:align];
  paragraphStyle.minimumLineHeight = lineHeight;
  paragraphStyle.maximumLineHeight = lineHeight;
  paragraphStyle.lineSpacing = lineHeight / 7.3;
  //  paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
  // there are many more attrs, e.g NSFontAttributeName
  NSDictionary *attrsDictionary = @{
                                    NSFontAttributeName: uiFont,
                                    NSParagraphStyleAttributeName: paragraphStyle
                                    };
  
  NSString *text = options[@"text"];
  textView.textContainer.lineFragmentPadding = 0;
  textView.attributedText = [[NSAttributedString alloc] initWithString:text attributes:attrsDictionary];
  
  if (![options[@"type"] isEqualToString:@"textarea"]) {
    double verticalAlignMiddleCompensation = ([box[@"height"] doubleValue] - [textView contentSize].height * [textView zoomScale])/2.0;
    textView.frame = CGRectMake(left, textView.frame.origin.y + verticalAlignMiddleCompensation, width, height - verticalAlignMiddleCompensation);
  }
  

  //NSURL *htmlString = [[NSBundle mainBundle]  URLForResource: @"string"     withExtension:@"html"];
  
  //  NSString *html = @"<html>\
  <head>\
  <style type=\"text/css\">\
  html, body {\
  width: 100%;\
  height: 100%;\
  }\
  input {\
  font-family: \"-apple-system\", \"Helvetica Neue\", \"Roboto\", \"Segoe UI\", sans-serif;\
  width: 100%;\
  display: block;\
  padding-top: 2px;\
  padding-left: 0;\
  height: 34px;\
  color: #111;\
  vertical-align: middle;\
  font-size: 14px;\
  line-height: 16px;\
  padding-right: 24px;\
  background-color: yellow\
  }\
  </style>\
  </head>\
  <body>\
  <input type=\"text\" value=\"This is the text\"/>\
  </body>\
  </html>";
  
  //  NSData* data = [html dataUsingEncoding:NSUTF8StringEncoding];
  //  NSAttributedString *stringWithHTMLAttributes = [[NSAttributedString alloc] initWithData:data
  // options:@{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType} documentAttributes:nil error:nil];
  //  textView.attributedText = stringWithHTMLAttributes; // attributedText field!
  
  if (textView.superview == nil) {
    [self.viewController.view addSubview: textView];
  } else {
  }
  if (!DEBUG_KEYBOARD) {
    textView.textColor = [UIColor clearColor];
  } else {
    //    textView.textColor = [UIColor greenColor];
  }
  
  [textView reloadInputViews];
  
  [textView becomeFirstResponder];
  
  _callbackId = command.callbackId;
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
  pluginResult.keepCallback = [NSNumber numberWithBool:YES];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
}

/*
 - (CGFloat)layoutManager:(NSLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect {
 return _lineSpacing;
 }
 */

- (void)textFieldDidChange:(NSNotification *)notification {
  //    UITextField *textField = (UITextField*)notification;
  //    NSString *text = [textField text];
  // Do whatever you like to respond to text changes here.
  //  [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"cordova.plugins.Keyboard.updateInput({'text': '%@'})", text]];
}

- (NSTextAlignment) getNSTextAlignment:(NSString*)type {
  if (type == nil) {
    return NSTextAlignmentLeft;
  }
  type = type.lowercaseString;
  if ([type isEqualToString:@"center"]) {
    return NSTextAlignmentCenter;
  } else {
    return NSTextAlignmentLeft;
  }
}

- (UIBarButtonItemStyle) getUIBarButtonItemStyle:(NSString*)style {
  if (style == nil) {
    return UIBarButtonItemStylePlain;
  }
  style = style.lowercaseString;
  if ([style isEqualToString:@"done"]) {
    return UIBarButtonItemStyleDone;
  } else {
    return UIBarButtonItemStylePlain;
  }
}

- (UIBarButtonSystemItem) getUIBarButtonSystemItem:(NSString*)type {
  if (type == nil) {
    return -1;
  }
  type = type.lowercaseString;
  if ([type isEqualToString:@"done"]) {
    return UIBarButtonSystemItemDone;
  } else if ([type isEqualToString:@"cancel"]) {
    return UIBarButtonSystemItemCancel;
  } else if ([type isEqualToString:@"edit"]) {
    return UIBarButtonSystemItemEdit;
  } else if ([type isEqualToString:@"save"]) {
    return UIBarButtonSystemItemSave;
  } else if ([type isEqualToString:@"add"]) {
    return UIBarButtonSystemItemAdd;
  } else if ([type isEqualToString:@"flexiblespace"]) {
    return UIBarButtonSystemItemFlexibleSpace;
  } else if ([type isEqualToString:@"fixedspace"]) {
    return UIBarButtonSystemItemFixedSpace;
  } else if ([type isEqualToString:@"compose"]) {
    return UIBarButtonSystemItemCompose;
  } else if ([type isEqualToString:@"reply"]) {
    return UIBarButtonSystemItemReply;
  } else if ([type isEqualToString:@"action"]) {
    return UIBarButtonSystemItemAction;
  } else if ([type isEqualToString:@"organize"]) {
    return UIBarButtonSystemItemOrganize;
  } else if ([type isEqualToString:@"bookmarks"]) {
    return UIBarButtonSystemItemBookmarks;
  } else if ([type isEqualToString:@"search"]) {
    return UIBarButtonSystemItemSearch;
  } else if ([type isEqualToString:@"refresh"]) {
    return UIBarButtonSystemItemRefresh;
  } else if ([type isEqualToString:@"stop"]) {
    return UIBarButtonSystemItemStop;
  } else if ([type isEqualToString:@"camera"]) {
    return UIBarButtonSystemItemCamera;
  } else if ([type isEqualToString:@"trash"]) {
    return UIBarButtonSystemItemTrash;
  } else if ([type isEqualToString:@"play"]) {
    return UIBarButtonSystemItemPlay;
  } else if ([type isEqualToString:@"pause"]) {
    return UIBarButtonSystemItemPause;
  } else if ([type isEqualToString:@"rewind"]) {
    return UIBarButtonSystemItemRewind;
  } else if ([type isEqualToString:@"fastforward"]) {
    return UIBarButtonSystemItemFastForward;
  } else if ([type isEqualToString:@"undo"]) {
    return UIBarButtonSystemItemUndo;
  } else if ([type isEqualToString:@"redo"]) {
    return UIBarButtonSystemItemRedo;
  } else if ([type isEqualToString:@"pagecurl"]) {
    return UIBarButtonSystemItemPageCurl;
  } else {
    NSLog(@"Unknown type passed to UIBarButtonSystemItem: %@", type);
    return -1;
  }
}

+(UIFont *) fontWithName:(NSString *) fontName sizeInPixels:(CGFloat) pixels {
  static NSMutableDictionary *fontDict; // to hold the font dictionary
  if ( fontName == nil ) {
    // we default to @"HelveticaNeue-Medium" for our default font
    fontName = @"HelveticaNeue-Medium";
  }
  if ( fontDict == nil ) {
    fontDict = [ @{} mutableCopy ];
  }
  // create a key string to see if font has already been created
  //
  NSString *strFontHash = [NSString stringWithFormat:@"%@-%f", fontName , pixels];
  UIFont *fnt = fontDict[strFontHash];
  if ( fnt != nil ) {
    return fnt; // we have already created this font
  }
  // lets play around and create a font that falls near the point size needed
  CGFloat pointStart = pixels/4;
  CGFloat lastHeight = -1;
  UIFont * lastFont = [UIFont fontWithName:fontName size:.5];\
  
  NSMutableDictionary * dictAttrs = [ @{ } mutableCopy ];
  NSString *fontCompareString = @"Mgj^";
  for ( CGFloat pnt = pointStart ; pnt < 1000 ; pnt += .5 ) {
    UIFont *font = [UIFont fontWithName:fontName size:pnt];
    if ( font == nil ) {
      NSLog(@"Unable to create font %@" , fontName );
      NSAssert(font == nil, @"font name not found in fontWithName:sizeInPixels" ); // correct the font being past in
    }
    dictAttrs[NSFontAttributeName] = font;
    CGSize cs = [fontCompareString sizeWithAttributes:dictAttrs];
    CGFloat fheight =  cs.height;
    if ( fheight == pixels  ) {
      // that will be rare but we found it
      fontDict[strFontHash] = font;
      return font;
    }
    if ( fheight > pixels ) {
      if ( lastFont == nil ) {
        fontDict[strFontHash] = font;
        return font;
      }
      // check which one is closer last height or this one
      // and return the user
      CGFloat fc1 = fabs( fheight - pixels );
      CGFloat fc2 = fabs( lastHeight  - pixels );
      // return the smallest differential
      if ( fc1 < fc2 ) {
        fontDict[strFontHash] = font;
        return font;
      } else {
        fontDict[strFontHash] = lastFont;
        return lastFont;
      }
    }
    lastFont = font;
    lastHeight = fheight;
  }
  NSAssert( false, @"Hopefully should never get here");
  return nil;
}

- (void) doneWriting:(id)x {
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
  return YES;
}

BOOL allowHide = NO;
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
  if (allowHide) {
    [self close:textView];
  }
  return allowHide; // by setting this to NO you can keep the keyboard on open
}

- (void) buttonTapped:(UIBarButtonItem*)button {
  // if we send this index back to JS then it knows the index'd passed in item has been tapped
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"buttonIndex":@(button.tag)}];
  pluginResult.keepCallback = [NSNumber numberWithBool:YES];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
  // TODO would be cool if we can pass this preference in - perhaps use a category on UIBarButtonItem ?
  if (allowHide) {
    [textView endEditing:YES];
  }
}

- (void)hide:(CDVInvokedUrlCommand*)command {
  if (textView != nil) {
    allowHide = YES;
    [textView endEditing:YES];
  }
}

- (void) close:(id)type {
  [textView removeFromSuperview];
  [self.webView.scrollView setScrollEnabled:YES];
  self.webView.scrollView.delegate = nil;
  
  // restore the scroll position
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 40 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
    [self.webView.scrollView setContentOffset: CGPointMake(0, _offsetTop) animated:YES];
  });
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
//  int i=0;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
//  int i=0;
}

// updated with the added text after every keypress (or empty string if backspace)
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  NSLog(@"shouldChangeTextInRange: |%@|", text);
  // need to escape these to be able to pass to the webview
  if ([text isEqualToString:@"\n"]) {
    text = @"\\n";
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
  [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
}

/*
 - (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
 {
 int i=0;
 }
 */

@end