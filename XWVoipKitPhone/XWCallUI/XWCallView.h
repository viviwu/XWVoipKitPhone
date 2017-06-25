//
//  XWCallView.h
 

#import <UIKit/UIKit.h>

UIKIT_EXTERN NSString *const kXWCallActionNotification;

typedef NS_ENUM(NSUInteger, XWCallActionType) {
    XWCallActionConnect, //YES:answer/hangup
    XWCallActionMCMute,   //YES:
    XWCallActionSpeaker, //YES:Hands-free
    XWCallActionVedioOn,  //YES:vedio on/off
    XWCallActionDTMFkeys,
    XWCallActionHoldon,
    XWCallActionNone
};

@interface XWCallView : UIView

#pragma mark - properties
@property (copy, nonatomic) NSString *nickName;
@property (copy, nonatomic) NSString *connectState;
@property (copy, nonatomic) NSString *networkState;
/** 是否是被挂断 */
@property (assign, nonatomic) BOOL isHanged;
/** 是否已接听 */
@property (assign, nonatomic) BOOL answered;
/** 对方是否开启了摄像头 */
@property (assign, nonatomic) BOOL oppositeCamera;

/** 头像 */
@property (strong, nonatomic, readonly)UIImageView  *avatarImageView;
/** 自己的视频画面 */
@property (strong, nonatomic, readonly)UIImageView  *ownImageView;
/** 对方的视频画面 */
@property (strong, nonatomic, readonly)UIImageView  *adverseImageView;

 
#pragma mark - method

+ (void) postCallNotificationWithAction:(id)action;

- (instancetype)initWithIsVideo:(BOOL)isVideo isCallee:(BOOL)isCallee;

- (void)show;

- (void)dismiss;

@end
