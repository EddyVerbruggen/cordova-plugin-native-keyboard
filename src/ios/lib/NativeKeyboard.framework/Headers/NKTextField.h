#import <UIKit/UIKit.h>
#import "NKTextInput.h"

@interface NKTextField : UITextField<NKTextInput>

@property (nonatomic, assign) UIEdgeInsets edgeInsets;

@end