#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FontRegistry : NSObject {
  NSMutableDictionary *fonts;
}

+ (FontRegistry *)instance;
-(NSString *)fontForFamily:(NSString *)fontFamily forBold:(BOOL)isBold andItalic:(BOOL)isItalic;

@end