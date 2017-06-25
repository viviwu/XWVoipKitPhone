//
//  XWCallButton.h
 

#import <UIKit/UIKit.h>

@interface XWCallButton : UIButton

- (instancetype)initWithTitle:(NSString *)title imageName:(NSString *)imageName isVideo:(BOOL)isVideo;

+ (instancetype)callButtonWithTitle:(NSString *)title imageName:(NSString *)imageName isVideo:(BOOL)isVideo;

- (instancetype)initWithTitle:(NSString *)title noHandleImageName:(NSString *)noHandleImageName;

+ (instancetype)callButtonWithTitle:(NSString *)title noHandleImageName:(NSString *)noHandleImageName;

@end
