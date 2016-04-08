#import <Foundation/Foundation.h>

@protocol NKTextInput <UITextInput>

#pragma custom methods to streamline usage of all implementing classes
- (void) configure:(BOOL)debug;
- (void) show;
- (void) hide;
- (double) updatePostion:(NSDictionary*)options forPhoneHeight:(double)phoneHeight andKeyboardHeight:(double)keyboardHeight;

#pragma setters for already available properties
- (void) setFont:(UIFont*)font;
- (void) setAttributedText:(NSAttributedString*)string;
- (void) setInputAccessoryView:(UIToolbar*) toolBar;
- (void) setTextColor:(UIColor*) color;

@end
