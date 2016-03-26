#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NativeKeyboardHelper : NSObject

typedef NS_ENUM(NSInteger, NKFeature) {
  NKFeatureKeyboardType,
  NKFeatureMessenger,
  NKFeatureMessengerCounter,
  NKFeatureMessengerLeftButton,
  NKFeatureAccessoryBar
};

+ (UIImage*) getFAImage:(NSString*)icon;
+ (void) setFAImage:(NSString*)icon onButton:(UIButton*)button withColor:(NSString*)color;
+ (UIColor *) colorFromHexString:(NSString *)hexString;
+ (UIKeyboardType) getUIKeyboardType:(NSString*)type;
+ (BOOL) allowFeature:(NKFeature)feature;

@end