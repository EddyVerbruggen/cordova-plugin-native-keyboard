#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NKTextInput.h"

@interface NativeKeyboardHelper : NSObject

typedef NS_ENUM(NSInteger, NKFeature) {
  NKFeatureKeyboardType,
  NKFeatureMessenger,
  NKFeatureMessengerCounter,
  NKFeatureMessengerLeftButton,
  NKFeatureAccessoryBar
};

+ (BOOL) checkLicense;

+ (BOOL) allowFeature:(NKFeature)feature;

+ (UIColor *) colorFromHexString:(NSString *)hexString;

+ (UIImage*) getFAImage:(NSString*)icon;
+ (UIImage*) getFAImage:(NSString*)icon withFontSize:(int)fontSize;
+ (void) setFAImage:(NSString*)icon onButton:(UIButton*)button withColor:(NSString*)color;

+ (UIImage*) getIonImage:(NSString*)icon;
+ (UIImage*) getIonImage:(NSString*)icon withFontSize:(int)fontSize;
+ (UIImage*) getIonImage:(NSString*)icon withFontSize:(int)fontSize andColor:(NSString*)color;
+ (void) setIonImage:(NSString*)icon onButton:(UIButton*)button withColor:(NSString*)color;

+ (void) setUIBarStyle:(NSString*)style forToolbar:(UIToolbar*)toolBar;

+ (UIKeyboardType) getUIKeyboardType:(NSString*)type;
+ (UIBarButtonItemStyle) getUIBarButtonItemStyle:(NSString*)style;
+ (UIKeyboardAppearance) getUIKeyboardAppearance:(NSString*)appearance;
+ (UIReturnKeyType) getUIReturnKeyType:(NSString*)type;
+ (UIBarButtonSystemItem) getUIBarButtonSystemItem:(NSString*)type;
+ (NSTextAlignment) getNSTextAlignment:(NSString*)type;

+ (void) applyCaretColor:(NSString*)hexColor toField:(UIControl<NKTextInput>*)field;
+ (void) applyFont:uiFont andTextAlignment:(NSString*)align toText:(NSString*)text withLineHeight:(double)lineHeight toField:(UIControl<NKTextInput>*)field;

@end