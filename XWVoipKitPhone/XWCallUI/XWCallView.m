//
//  XWCallView.m
 

#import <AVFoundation/AVFoundation.h>
#import "XWCallView.h"
#import "XWCallButton.h"

NSString *const kXWCallActionNotification = @"kXWCallActionNotification";
 
#define kScreenW       [UIScreen mainScreen].bounds.size.width
#define kScreenH      [UIScreen mainScreen].bounds.size.height

#define kScaleRate        ([UIScreen mainScreen].bounds.size.width / 320.0)
// 底部按钮容器的高度
#define kContainerH     (162 * kScaleRate)
// 每个按钮的宽度
#define kBtnW           (60 * kScaleRate)
// 视频聊天时，小窗口的宽
#define kMicVideoW      (80 * kScaleRate)
// 视频聊天时，小窗口的高
#define kMicVideoH      (120 * kScaleRate)

@interface XWCallView ()

/** 是否是视频聊天 */
@property (assign, nonatomic)BOOL  isVideo;
/** 是否是被呼叫方 */
@property (assign, nonatomic)BOOL  callee;
/** 本地是否开启摄像头  */
@property (assign, nonatomic)BOOL  localCamera;
/** 是否是外放模式 */
@property (assign, nonatomic)BOOL  loudSpeaker;

/** 语音聊天背景视图 */
@property (strong, nonatomic)UIImageView  *bgImageView;
/** 自己的视频画面 */
@property (strong, nonatomic)UIImageView  *ownImageView;
/** 对方的视频画面 */
@property (strong, nonatomic)UIImageView  *adverseImageView;
/** 头像 */
@property (strong, nonatomic)UIImageView  *avatarImageView;
/** 昵称 */
@property (strong, nonatomic) UILabel  *nickNameLabel;
/** 连接状态，如等待对方接听...、对方已拒绝、语音电话、视频电话 */
@property (strong, nonatomic) UILabel  *connectLabel;
/** 网络状态提示，如对方网络良好、网络不稳定等 */
@property (strong, nonatomic) UILabel  *netStateLabel;
/** 前置、后置摄像头切换按钮 */
@property (strong, nonatomic) XWCallButton *swichBtn;
/** 底部按钮容器视图 */
@property (strong, nonatomic) UIView  *btnContainerView;
/** 静音按钮 */
@property (strong, nonatomic) XWCallButton *muteBtn;
/** 摄像头按钮 */
@property (strong, nonatomic) XWCallButton *cameraBtn;
/** 扬声器按钮 */
@property (strong, nonatomic) XWCallButton *loudspeakerBtn;
/** 邀请成员按钮 */
@property (strong, nonatomic) XWCallButton *inviteBtn;
/** 消息回复按钮 */
@property (strong, nonatomic) UIButton *msgReplyBtn;
/** 收到视频通话时，语音接听按钮 */
@property (strong, nonatomic) XWCallButton *voiceAnswerBtn;
/** 挂断按钮 */
@property (strong, nonatomic) XWCallButton *hangupBtn;
/** 接听按钮 */
@property (strong, nonatomic) XWCallButton *answerBtn;
/** 收起按钮 */
@property (strong, nonatomic) XWCallButton *packupBtn;
/** 视频通话缩小后的按钮 */
@property (strong, nonatomic) UIButton *videoMicroBtn;
/** 音频通话缩小后的按钮 */
@property (strong, nonatomic) XWCallButton *microBtn;
/** 遮罩视图 */
@property (strong, nonatomic) UIView  *coverView;
/** 动画用的layer */
@property (strong, nonatomic) CAShapeLayer  *shapeLayer;

@end

@implementation XWCallView

- (instancetype)initWithIsVideo:(BOOL)isVideo isCallee:(BOOL)isCallee
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];

    if (self) {
        self.isVideo = isVideo;
        self.callee = isCallee;
        self.isHanged = YES;
        self.clipsToBounds = YES;
        
        [self setupUI];
    }
    
    return self;
}

/**
 *  初始化UI
 */
- (void)setupUI
{
    self.adverseImageView.backgroundColor = [UIColor lightGrayColor];
    self.ownImageView.backgroundColor = [UIColor grayColor];
    self.avatarImageView.backgroundColor = [UIColor clearColor];

    if (self.isVideo && !self.callee) {
        // 视频通话时，呼叫方的UI初始化
        [self initUIForVideoCaller];
        
//        // 模拟对方点击通话后的动画效果
        [self performSelector:@selector(connected) withObject:nil afterDelay:3.0];
        _answered = YES;
        _oppositeCamera = YES;
        _localCamera = YES;

    } else if (!self.isVideo && !self.callee) {
        
        [self initUIForAudioCaller];
        
        [self performSelector:@selector(connected) withObject:nil afterDelay:3.0];
        _answered = YES;
        _oppositeCamera = NO;
        _localCamera = NO;
        
    } else if (!self.isVideo && self.callee) {
        
        [self initUIForAudioCallee];
    } else {
        
        [self initUIForVideoCallee];
    }
}

- (void)initUIForVideoCaller
{
    self.adverseImageView.frame = self.frame;
    [self addSubview:_adverseImageView];
    
    self.ownImageView.frame = self.frame;
    [self addSubview:_ownImageView];
    
    CGFloat switchBtnW = 45 * kScaleRate;
    CGFloat topOffset = 30 * kScaleRate;
    self.swichBtn.frame = CGRectMake(kScreenW - switchBtnW - 10, topOffset, switchBtnW, switchBtnW);
    [self addSubview:_swichBtn];
    
    self.nickNameLabel.frame = CGRectMake(20, topOffset, kScreenW - 20 * 3 - switchBtnW, 30);
    self.nickNameLabel.textColor = [UIColor whiteColor];
    self.nickNameLabel.textAlignment = NSTextAlignmentLeft;
    self.nickNameLabel.text = self.nickName ?: @"viviwu";
    [self addSubview:_nickNameLabel];
    
    self.connectLabel.frame = CGRectMake(20, CGRectGetMaxY(self.nickNameLabel.frame), CGRectGetWidth(self.nickNameLabel.frame), 20);
    self.connectLabel.textColor = [UIColor whiteColor];
    self.connectLabel.textAlignment = NSTextAlignmentLeft;
    self.connectLabel.text = self.connectState;
    [self addSubview:_connectLabel];
    
    self.btnContainerView.frame = CGRectMake(0, kScreenH - kContainerH, kScreenW, kContainerH);
    self.btnContainerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    [self addSubview:_btnContainerView];
    
    [self initUIForBottomBtns];
    self.cameraBtn.enabled = NO;
    self.inviteBtn.enabled = NO;
    
    self.coverView.frame = self.frame;
    self.coverView.hidden = YES;
    [self addSubview:_coverView];
    
    [self loudspeakerClick];
}

- (void)initUIForVideoCallee
{
    [self initUIForTopCommonViews];
    
    CGFloat btnW = kBtnW;
    CGFloat btnH = kBtnW + 20;
    CGFloat paddingX = (kScreenW - btnW * 2) / 3;
    self.hangupBtn.frame = CGRectMake(paddingX, kContainerH - btnH - 5, btnW, btnH);
    [self.btnContainerView addSubview:_hangupBtn];
    
    self.answerBtn.frame = CGRectMake(paddingX * 2 + btnW, kContainerH - btnH - 5, btnW, btnH);
    [self.btnContainerView addSubview:_answerBtn];
    
    
    self.msgReplyBtn.frame = CGRectMake(paddingX, 5, btnW, btnW);
    [self.btnContainerView addSubview:_msgReplyBtn];
    
    self.voiceAnswerBtn.frame = CGRectMake(paddingX * 2 + btnW, 5, btnW, btnW);
    [self.btnContainerView addSubview:_voiceAnswerBtn];
    
    self.coverView.frame = self.frame;
    self.coverView.hidden = YES;
    [self addSubview:_coverView];
}

- (void)initUIForAudioCaller
{
    [self initUIForTopCommonViews];
    
    [self initUIForBottomBtns];

    self.cameraBtn.enabled = NO;
    self.inviteBtn.enabled = NO;
    
    self.coverView.frame = self.frame;
    self.coverView.hidden = YES;
    [self addSubview:_coverView];
}

- (void)initUIForAudioCallee
{
    
    [self initUIForTopCommonViews];
    
    CGFloat btnW = kBtnW;
    CGFloat btnH = kBtnW + 20;
    CGFloat paddingX = (kScreenW - btnW * 2) / 3;
    self.hangupBtn.frame = CGRectMake(paddingX, kContainerH - btnH - 5, btnW, btnH);
    [self.btnContainerView addSubview:_hangupBtn];
    
    self.answerBtn.frame = CGRectMake(paddingX * 2 + btnW, kContainerH - btnH - 5, btnW, btnH);
    [self.btnContainerView addSubview:_answerBtn];
    
    CGFloat replyW = 110 * kScaleRate;
    CGFloat replyH = 45 * kScaleRate;
    
    CGFloat centerX = self.center.x;
    self.msgReplyBtn.frame = CGRectMake(centerX - replyW * 0.5, 20, replyW, replyH);
    [self.btnContainerView addSubview:_msgReplyBtn];
    
    self.coverView.frame = self.frame;
    self.coverView.hidden = YES;
    [self addSubview:_coverView];
}


- (void)initUIForTopCommonViews
{
    CGFloat centerX = self.center.x;
    
    self.bgImageView.frame = self.frame;
    [self addSubview:_bgImageView];
    
    CGFloat portraitW = 130 * kScaleRate;
    self.avatarImageView.frame = CGRectMake(0, 0, portraitW, portraitW);
    self.avatarImageView.center = CGPointMake(centerX, portraitW);
    self.avatarImageView.layer.cornerRadius = portraitW * 0.5;
    self.avatarImageView.layer.masksToBounds = YES;
    [self addSubview:_avatarImageView];
    
    self.nickNameLabel.frame = CGRectMake(0, 0, kScreenW, 30);
    self.nickNameLabel.center = CGPointMake(centerX, CGRectGetMaxY(self.avatarImageView.frame) + 40);
    self.nickNameLabel.text = self.nickName ? :@"viviwu";
    [self addSubview:_nickNameLabel];
    
    self.connectLabel.frame = CGRectMake(0, 0, kScreenW, 30);
    self.connectLabel.center = CGPointMake(centerX, CGRectGetMaxY(self.nickNameLabel.frame) + 10);
    self.connectLabel.text = self.connectState;
    [self addSubview:_connectLabel];
    
    self.netStateLabel.frame = CGRectMake(0, 0, kScreenW, 30);
    self.netStateLabel.center = CGPointMake(centerX, CGRectGetMaxY(self.connectLabel.frame) + 40);
    [self addSubview:_netStateLabel];
    
    self.btnContainerView.frame = CGRectMake(0, kScreenH - kContainerH, kScreenW, kContainerH);
    [self addSubview:_btnContainerView];
}

/**
 *  添加底部6个按钮
 */
- (void)initUIForBottomBtns
{
    CGFloat btnW = kBtnW;
    CGFloat paddingX = (self.frame.size.width - btnW*3) / 4;
    CGFloat paddingY = (kContainerH - btnW *2) / 3;
    self.muteBtn.frame = CGRectMake(paddingX, paddingY, btnW, btnW);
    [self.btnContainerView addSubview:_muteBtn];
    
    self.cameraBtn.frame = CGRectMake(paddingX * 2 + btnW, paddingY, btnW, btnW);
    [self.btnContainerView addSubview:_cameraBtn];
    
    self.loudspeakerBtn.frame = CGRectMake(paddingX * 3 + btnW * 2, paddingY, btnW, btnW);
    self.loudspeakerBtn.selected = self.loudSpeaker;
    [self.btnContainerView addSubview:_loudspeakerBtn];
    
    self.inviteBtn.frame = CGRectMake(paddingX, paddingY * 2 + btnW, btnW, btnW);
    [self.btnContainerView addSubview:_inviteBtn];
    
    self.hangupBtn.frame = CGRectMake(paddingX * 2 + btnW, paddingY * 2 + btnW, btnW, btnW);
    [self.btnContainerView addSubview:_hangupBtn];
    
    self.packupBtn.frame = CGRectMake(paddingX * 3 + btnW * 2, paddingY * 2 + btnW, btnW, btnW);
    [self.btnContainerView addSubview:_packupBtn];
}

- (void)show
{
    if (self.isVideo && self.callee) {
        self.connectLabel.text = @"Video";
    } else if (!self.isVideo && self.callee) {
        self.connectLabel.text = @"Audio";
    }
    
    _avatarImageView.transform = CGAffineTransformMakeTranslation(0, -CGRectGetMaxY(_avatarImageView.frame));
    _nickNameLabel.transform = CGAffineTransformMakeTranslation(0, -CGRectGetMaxY(_nickNameLabel.frame));
    _connectLabel.transform = CGAffineTransformMakeTranslation(0, -CGRectGetMaxY(_connectLabel.frame));
    _swichBtn.transform = CGAffineTransformMakeTranslation(0, -CGRectGetMaxY(_swichBtn.frame));
    _btnContainerView.transform = CGAffineTransformMakeTranslation(0, kContainerH);
    
    self.alpha = 0;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1 animations:^{
            _avatarImageView.transform = CGAffineTransformIdentity;
            _nickNameLabel.transform = CGAffineTransformIdentity;
            _connectLabel.transform = CGAffineTransformIdentity;
            _swichBtn.transform = CGAffineTransformIdentity;
            _btnContainerView.transform = CGAffineTransformIdentity;

        }];
    }];
}

- (void)dismiss
{
    [UIView animateWithDuration:1.0 animations:^{
        _avatarImageView.transform = CGAffineTransformMakeTranslation(0, -CGRectGetMaxY(_avatarImageView.frame));
        _nickNameLabel.transform = CGAffineTransformMakeTranslation(0, -CGRectGetMaxY(_nickNameLabel.frame));
        _connectLabel.transform = CGAffineTransformMakeTranslation(0, -CGRectGetMaxY(_connectLabel.frame));
        _swichBtn.transform = CGAffineTransformMakeTranslation(0, -CGRectGetMaxY(_swichBtn.frame));
        _btnContainerView.transform = CGAffineTransformMakeTranslation(0, kContainerH);
        
    } completion:^(BOOL finished) {
        [self clearAllSubViews];
        [self removeFromSuperview];
    }];
}

- (void)connected
{
    if (self.isVideo) {
        // 视频通话，对方接听以后
        self.cameraBtn.enabled = YES;
        self.loudspeakerBtn.selected = YES;
        self.cameraBtn.selected = YES;
        self.inviteBtn.enabled = YES;
        [UIView animateWithDuration:0.5 animations:^{
            self.ownImageView.frame = CGRectMake(kScreenW - kMicVideoW - 5 , kScreenH - kContainerH - kMicVideoH - 5, kMicVideoW, kMicVideoH);
        } completion:^(BOOL finished) {
            
        }];
    } else {
        self.cameraBtn.enabled = YES;
        self.inviteBtn.enabled = YES;
        self.btnContainerView.alpha = 1.0;
    }
}

- (void)clearAllSubViews
{
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _bgImageView = nil;
//    _ownImageView = nil;
//    _adverseImageView = nil;
//    _avatarImageView = nil;
    _nickNameLabel = nil;
    _connectLabel = nil;
    _netStateLabel = nil;
    _swichBtn = nil;
    
    [self clearBottomViews];
    
    _coverView = nil;
}

- (void)clearBottomViews
{
    _btnContainerView = nil;
    _muteBtn = nil;
    _cameraBtn = nil;
    _loudspeakerBtn = nil;
    _inviteBtn = nil;
    _hangupBtn = nil;
    _packupBtn = nil;
    _msgReplyBtn = nil;
    _voiceAnswerBtn = nil;
    _answerBtn = nil;
}

- (void)dealloc
{
     NSLog(@"%s",__func__);
    [self clearAllSubViews];
}

+ (void) postCallNotificationWithAction:(id)action{
    [[NSNotificationCenter defaultCenter] postNotificationName:kXWCallActionNotification object: action];
}

#pragma mark - 按钮点击事件

- (void)switchClick
{
    [XWCallView postCallNotificationWithAction:nil];
}

- (void)muteClick
{
    NSLog(@"静音%s",__func__);
    if (!self.muteBtn.selected) {
        self.muteBtn.selected = YES;
    } else {
        self.muteBtn.selected = NO;
    }
    NSDictionary * action = @{@"type":@(XWCallActionMCMute), @"Value":@(self.muteBtn.selected)};
    [XWCallView postCallNotificationWithAction:action];
}

- (void)cameraClick
{
    self.localCamera = !self.localCamera;
    if (self.localCamera) {
        self.isVideo = YES;
        [self clearAllSubViews];
        
        [self initUIForVideoCaller];
         /*
          
          */
        NSDictionary * action = @{@"type":@(XWCallActionVedioOn), @"Value":@(YES)};
        [XWCallView postCallNotificationWithAction:action];
        // 对方和本地都开了摄像头
        if (self.oppositeCamera) {
            self.ownImageView.frame = CGRectMake(kScreenW - kMicVideoW - 5 , kScreenH - kContainerH - kMicVideoH - 5, kMicVideoW, kMicVideoH);
            [self addSubview:self.ownImageView];
            self.cameraBtn.enabled = YES;
            self.inviteBtn.enabled = YES;
            self.cameraBtn.selected = YES;
        } else {
            // 本地开启，对方未开摄像头
            [self.adverseImageView removeFromSuperview];
            self.cameraBtn.enabled = YES;
            self.inviteBtn.enabled = YES;
            self.cameraBtn.selected = YES;
        }
        
    } else {
        // 在这里添加 关闭本地视频采集 的代码
        NSDictionary * action = @{@"type":@(XWCallActionVedioOn), @"Value":@(NO)};
        [XWCallView postCallNotificationWithAction:action];
        if (self.oppositeCamera) {
            // 本地未开，对方开了摄像头
            [self clearAllSubViews];
            
            [self initUIForVideoCaller];
            
            [self.ownImageView removeFromSuperview];
            self.cameraBtn.enabled = YES;
            self.inviteBtn.enabled = YES;
            
        } else {
            // 本地和对方都未开始摄像头
            self.isVideo = NO;
            [self clearAllSubViews];
            
            [self initUIForAudioCaller];
            
            [self connected];
        }
    }
}

- (void)loudspeakerClick
{
    NSLog(@"外放声音%s",__func__);
    if (!self.loudspeakerBtn.selected) {
        self.loudspeakerBtn.selected = YES;
        self.loudSpeaker = YES;
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    } else {
        self.loudspeakerBtn.selected = NO;
        self.loudSpeaker = NO;
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    }
    NSDictionary * action = @{@"type":@(XWCallActionSpeaker), @"Value":@(self.loudspeakerBtn.selected)};
    [XWCallView postCallNotificationWithAction:action];
}

- (void)inviteClick
{
    NSLog(@"邀请成员%s",__func__);
//    #warning 这里需要发送邀请成员的通知
}

- (void)hangupClick
{
    if (self.isHanged) {
        self.coverView.hidden = NO;
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:2.0];
    } else {
        [self dismiss];
    }
//    self.answered?
    NSDictionary * action = @{@"type":@(XWCallActionConnect), @"Value":@(self.isHanged), @"Video":@(self.isVideo)};
    [XWCallView postCallNotificationWithAction:action];
}

- (void)packupClick
{
    // 如果是语音通话的收起
    if (!self.isVideo) {
        // 1.获取动画缩放结束时的圆形
        UIBezierPath *endPath = [UIBezierPath bezierPathWithOvalInRect:self.avatarImageView.frame];
        
        // 2.获取动画缩放开始时的圆形
        CGSize startSize = CGSizeMake(self.frame.size.width * 0.5, self.frame.size.height - self.avatarImageView.center.y);
        CGFloat radius = sqrt(startSize.width * startSize.width + startSize.height * startSize.height);
        CGRect startRect = CGRectInset(self.avatarImageView.frame, -radius, -radius);
        UIBezierPath *startPath = [UIBezierPath bezierPathWithOvalInRect:startRect];
        
        // 3.创建shapeLayer作为视图的遮罩
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = endPath.CGPath;
        self.layer.mask = shapeLayer;
        self.shapeLayer = shapeLayer;
        
        // 添加动画
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        pathAnimation.fromValue = (id)startPath.CGPath;
        pathAnimation.toValue = (id)endPath.CGPath;
        pathAnimation.duration = 0.5;
        pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        pathAnimation.delegate = (id)self;
        pathAnimation.removedOnCompletion = NO;
        pathAnimation.fillMode = kCAFillModeForwards;
        
        [shapeLayer addAnimation:pathAnimation forKey:@"packupAnimation"];
    } else {
        // 视频通话的收起动画
        _nickNameLabel.transform = CGAffineTransformMakeTranslation(0, -CGRectGetMaxY(_nickNameLabel.frame));
        _connectLabel.transform = CGAffineTransformMakeTranslation(0, -CGRectGetMaxY(_connectLabel.frame));
        _swichBtn.transform = CGAffineTransformMakeTranslation(0, -CGRectGetMaxY(_swichBtn.frame));
        _btnContainerView.transform = CGAffineTransformMakeTranslation(0, kContainerH);
        
        if (self.answered) {
            [UIView animateWithDuration:1.0 animations:^{
                self.frame = CGRectMake(kScreenW - kMicVideoW - 10 , 74, kMicVideoW, kMicVideoH);
                if (self.oppositeCamera && self.localCamera) {
                    _ownImageView.hidden = YES;
                    self.adverseImageView.frame = CGRectMake(0, 0, kMicVideoW, kMicVideoH);
                } else if (!self.oppositeCamera && self.localCamera) {
                    self.ownImageView.frame = CGRectMake(0, 0, kMicVideoW, kMicVideoH);
                } else {
                    self.adverseImageView.frame = CGRectMake(0, 0, kMicVideoW, kMicVideoH);
                }
            } completion:^(BOOL finished) {
                self.videoMicroBtn.frame = self.adverseImageView.frame;
                [self addSubview:_videoMicroBtn];
            }];
        } else {
            [UIView animateWithDuration:1.0 animations:^{
                self.frame = CGRectMake(kScreenW - kMicVideoW - 10 , 74, kMicVideoW, kMicVideoH);
                self.ownImageView.frame = CGRectMake(0, 0, kMicVideoW, kMicVideoH);
            } completion:^(BOOL finished) {
                self.videoMicroBtn.frame = self.ownImageView.frame;
                [self addSubview:_videoMicroBtn];
            }];
        }
    }
}

- (void)msgReplyClick
{
    NSLog(@"%s",__func__);

    NSArray *messages = @[@"现在不方便接听，稍后给你回复。",@"现在不方便接听，有什么事吗",@"马上到"];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:@"取消" destructiveButtonTitle: nil otherButtonTitles:nil];
    for (NSString *message  in messages) {
        [sheet addButtonWithTitle:message];
    }
    [sheet showInView:self];
}

/**
 *  接听按钮操作
 */
- (void)answerClick
{
    self.answered = YES;
    NSDictionary * action = nil;
    // 接听按钮只在接收方出现，分语音接听和视频接听两种情况
    if (self.isVideo) {
        _localCamera = YES;
        _oppositeCamera = YES;

        [self clearAllSubViews];
        // 视频通话接听之后，UI布局与呼叫方一样
        [self initUIForVideoCaller];
        // 执行一个小动画
        [self connected];
        action = @{@"type":@(XWCallActionConnect), @"Value":@(NO), @"Video":@(YES)};
    } else {
        _localCamera = NO;
        _oppositeCamera = NO;
        
        [UIView animateWithDuration:1 animations:^{
            self.btnContainerView.alpha = 0;
        } completion:^(BOOL finished) {
            [self clearAllSubViews];
            
            [self initUIForAudioCaller];
            self.connectLabel.text = @"正在通话中...";
            
            [self connected];
        }];
        action = @{@"isVideo":@(NO),@"audioAccept":@(YES)};
        action = @{@"type":@(XWCallActionConnect), @"Value":@(YES), @"Video":@(NO)};
    }
    
    [XWCallView postCallNotificationWithAction:action];
}

// 视频通话时的语音接听按钮
- (void)voiceAnswerClick
{
    self.answered = YES;
    self.isVideo = YES;
    _localCamera = NO;
    _oppositeCamera = YES;
    
    [self clearAllSubViews];
    
    [self initUIForVideoCaller];
    
    [self.ownImageView removeFromSuperview];
    self.cameraBtn.enabled = YES;
    self.inviteBtn.enabled = YES;
    
    // 只有视频通话的语音接听，传一个参数NO。
    NSDictionary * action = @{@"type":@(XWCallActionConnect), @"Value":@(YES), @"video":@(YES)};
    [XWCallView postCallNotificationWithAction:action];
}

// 语音通话，缩小后的按钮点击事件
- (void)microClick
{
    [self.microBtn removeFromSuperview];
    self.microBtn = nil;
    
    [UIView animateWithDuration:1.0 animations:^{
        self.center = self.avatarImageView.center;
        self.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.bounds = [UIScreen mainScreen].bounds;
        self.frame = self.bounds;
        
        CAShapeLayer *shapeLayer = self.shapeLayer;
        
        // 1.获取动画缩放开始时的圆形
        UIBezierPath *startPath = [UIBezierPath bezierPathWithOvalInRect:self.avatarImageView.frame];
        
        // 2.获取动画缩放结束时的圆形
        CGSize endSize = CGSizeMake(self.frame.size.width * 0.5, self.frame.size.height - self.avatarImageView.center.y);
        CGFloat radius = sqrt(endSize.width * endSize.width + endSize.height * endSize.height);
        CGRect endRect = CGRectInset(self.avatarImageView.frame, -radius, -radius);
        UIBezierPath *endPath = [UIBezierPath bezierPathWithOvalInRect:endRect];
        
        // 3.创建shapeLayer作为视图的遮罩
        shapeLayer.path = endPath.CGPath;
        
        // 添加动画
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        pathAnimation.fromValue = (id)startPath.CGPath;
        pathAnimation.toValue = (id)endPath.CGPath;
        pathAnimation.duration = 0.5;
        pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        pathAnimation.delegate = (id)self;
        pathAnimation.removedOnCompletion = NO;
        pathAnimation.fillMode = kCAFillModeForwards;
        
        [shapeLayer addAnimation:pathAnimation forKey:@"showAnimation"];
    }];
}

- (void)videoMicroClick
{
    [self.videoMicroBtn removeFromSuperview];
    _ownImageView.hidden = NO;
    
    if (self.answered) {
        [UIView animateWithDuration:1.0 animations:^{
            self.frame = [UIScreen mainScreen].bounds;
            if (!self.oppositeCamera && self.localCamera) {
                self.ownImageView.frame = [UIScreen mainScreen].bounds;
            } else {
                self.adverseImageView.frame = [UIScreen mainScreen].bounds;
            }
            
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:1 animations:^{
                self.nickNameLabel.transform = CGAffineTransformIdentity;
                self.connectLabel.transform = CGAffineTransformIdentity;
                self.swichBtn.transform = CGAffineTransformIdentity;
                self.btnContainerView.transform = CGAffineTransformIdentity;
            }];
        }];
    } else {
        [UIView animateWithDuration:1.0 animations:^{
            self.frame = [UIScreen mainScreen].bounds;
            self.ownImageView.frame = [UIScreen mainScreen].bounds;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:1 animations:^{
                self.nickNameLabel.transform = CGAffineTransformIdentity;
                self.connectLabel.transform = CGAffineTransformIdentity;
                self.swichBtn.transform = CGAffineTransformIdentity;
                self.btnContainerView.transform = CGAffineTransformIdentity;
            }];
        }];
    }
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if ([anim isEqual:[self.shapeLayer animationForKey:@"packupAnimation"]]) {
        CGRect rect = self.frame;
        rect.origin = self.avatarImageView.frame.origin;
        self.bounds = rect;
        rect.size = self.avatarImageView.frame.size;
        self.frame = rect;
        
        [UIView animateWithDuration:1.0 animations:^{
            self.center = CGPointMake(kScreenW - 60, kScreenH - 80);
            self.transform = CGAffineTransformMakeScale(0.5, 0.5);
            
        } completion:^(BOOL finished) {
            self.microBtn.frame = self.frame;
            self.microBtn.layer.cornerRadius = self.microBtn.bounds.size.width * 0.5;
            self.microBtn.layer.masksToBounds = YES;
            [self.superview addSubview:_microBtn];
        }];
    } else if ([anim isEqual:[self.shapeLayer animationForKey:@"showAnimation"]]) {
        self.layer.mask = nil;
        self.shapeLayer = nil;
    }
}

#pragma mark - 懒加载
- (UIImageView *)bgImageView
{
    if (!_bgImageView) {
        _bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"im_skin_icon_audiocall_bg.jpg"]];
    }
    
    return _bgImageView;
}

- (UIImageView *)adverseImageView
{
    if (!_adverseImageView) {
        _adverseImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wpb.jpg"]];
    }
    
    return _adverseImageView;
}

- (UIImageView *)ownImageView
{
    if (!_ownImageView) {
        _ownImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wpb.jpg"]];
    }
    
    return _ownImageView;
}

- (UIImageView *)avatarImageView
{
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar.jpg"]];
    }
    
    return _avatarImageView;
}

- (UILabel*)nickNameLabel
{
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.text = @"viviwu";
        _nickNameLabel.font = [UIFont systemFontOfSize:17.0f];
        _nickNameLabel.textColor = [UIColor darkGrayColor];
        _nickNameLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return _nickNameLabel;
}

- (UILabel*)connectLabel
{
    if (!_connectLabel) {
        _connectLabel = [[UILabel alloc] init];
        _connectLabel.text = @"等待对方接听...";
        _connectLabel.font = [UIFont systemFontOfSize:15.0f];
        _connectLabel.textColor = [UIColor grayColor];
        _connectLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return _connectLabel;
}

- (XWCallButton *)swichBtn
{
    if (!_swichBtn) {
        _swichBtn = [[XWCallButton alloc] initWithTitle:nil noHandleImageName:@"icon_avp_camera_white"];
        [_swichBtn addTarget:self action:@selector(switchClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _swichBtn;
}

- (UILabel*)netStateLabel
{
    if (!_netStateLabel) {
        _netStateLabel = [[UILabel alloc] init];
        _netStateLabel.text = @"对方网络良好";
        _netStateLabel.font = [UIFont systemFontOfSize:13.0f];
        _netStateLabel.textColor = [UIColor grayColor];
        _netStateLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return _netStateLabel;
}

- (UIView *)btnContainerView
{
    if (!_btnContainerView) {
        _btnContainerView = [[UIView alloc] init];
    }
    return _btnContainerView;
}

- (XWCallButton *)muteBtn
{
    if (!_muteBtn) {
        _muteBtn = [[XWCallButton alloc] initWithTitle:@"静音" imageName:@"icon_avp_mute" isVideo:_isVideo];
        [_muteBtn addTarget:self action:@selector(muteClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _muteBtn;
}

- (XWCallButton *)cameraBtn
{
    if (!_cameraBtn) {
        _cameraBtn = [[XWCallButton alloc] initWithTitle:@"摄像头" imageName:@"icon_avp_video" isVideo:_isVideo];
        [_cameraBtn addTarget:self action:@selector(cameraClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _cameraBtn;
}

- (XWCallButton *)loudspeakerBtn
{
    if (!_loudspeakerBtn) {
        _loudspeakerBtn = [[XWCallButton alloc] initWithTitle:@"扬声器" imageName:@"icon_avp_loudspeaker" isVideo:_isVideo];
        [_loudspeakerBtn addTarget:self action:@selector(loudspeakerClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _loudspeakerBtn;
}

- (XWCallButton *)inviteBtn
{
    if (!_inviteBtn) {
        _inviteBtn = [[XWCallButton alloc] initWithTitle:@"邀请成员" imageName:@"icon_avp_invite" isVideo:_isVideo];
        [_inviteBtn addTarget:self action:@selector(inviteClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _inviteBtn;
}

- (XWCallButton *)hangupBtn
{
    if (!_hangupBtn) {
        if (_callee && !_answered) {
            _hangupBtn = [[XWCallButton alloc] initWithTitle:@"reject"  noHandleImageName:@"icon_call_reject_normal"];
        } else {
            _hangupBtn = [[XWCallButton alloc] initWithTitle:nil noHandleImageName:@"icon_call_reject_normal"];
        }
        
        [_hangupBtn addTarget:self action:@selector(hangupClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _hangupBtn;
}

- (XWCallButton *)packupBtn
{
    if (!_packupBtn) {
        _packupBtn = [[XWCallButton alloc] initWithTitle:@"Packup" imageName:@"icon_avp_reduce" isVideo:_isVideo];
        [_packupBtn addTarget:self action:@selector(packupClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _packupBtn;
}

- (UIButton *)msgReplyBtn
{
    if (!_msgReplyBtn) {
        if (self.isVideo) {
            _msgReplyBtn = [[XWCallButton alloc] initWithTitle:@"MsgReply" noHandleImageName:@"icon_av_reply_message_normal"];
        } else {
            _msgReplyBtn = [[UIButton alloc] init];
            [_msgReplyBtn setTitle:@"MsgReply" forState:UIControlStateNormal];
            _msgReplyBtn.titleLabel.font = [UIFont systemFontOfSize:12.0f];
            [_msgReplyBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [_msgReplyBtn setImage:[UIImage imageNamed:@"icon_av_reply_message_normal"] forState:UIControlStateNormal];
            [_msgReplyBtn setBackgroundImage:[UIImage imageNamed:@"view_audio_reply_message_bg"] forState:UIControlStateNormal];
        }
        
        [_msgReplyBtn addTarget:self action:@selector(msgReplyClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _msgReplyBtn;
}

- (XWCallButton *)voiceAnswerBtn
{
    if (!_voiceAnswerBtn) {
        _voiceAnswerBtn = [[XWCallButton alloc] initWithTitle:@"Audio" noHandleImageName:@"icon_av_audio_receive_normal"];
        [_voiceAnswerBtn addTarget:self action:@selector(voiceAnswerClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _voiceAnswerBtn;
}

- (XWCallButton *)answerBtn
{
    if (!_answerBtn) {
        _answerBtn = [[XWCallButton alloc] initWithTitle:@"Answer" noHandleImageName:@"icon_audio_receive_normal"];
        [_answerBtn addTarget:self action:@selector(answerClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _answerBtn;
}

- (XWCallButton *)microBtn
{
    if (!_microBtn) {
        _microBtn = [[XWCallButton alloc] initWithTitle:@"Connecting" noHandleImageName:@"icon_av_audio_micro_normal"];
        [_microBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _microBtn.titleLabel.font = [UIFont systemFontOfSize:12.0f];
        _microBtn.backgroundColor = [UIColor orangeColor];
        [_microBtn addTarget:self action:@selector(microClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _microBtn;
}

- (UIButton *)videoMicroBtn
{
    if (!_videoMicroBtn) {
        _videoMicroBtn = [[UIButton alloc] init];
        [_videoMicroBtn addTarget:self action:@selector(videoMicroClick) forControlEvents:UIControlEventTouchDown];
    }
    
    return _videoMicroBtn;
}

- (UIView *)coverView
{
    if (!_coverView) {
        _coverView = [[UIView alloc] init];
        _coverView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    }
    
    return _coverView;
}

#pragma mark - property setter
- (void)setNickName:(NSString *)nickName
{
    _nickName = nickName;
    self.nickNameLabel.text = _nickName;
}

- (void)setConnectState:(NSString *)connectState
{
    _connectState = connectState;
    self.connectLabel.text = connectState;
    
    [self.microBtn setTitle:connectState forState:UIControlStateNormal];
}

- (void)setNetworkState:(NSString *)networkState
{
    _networkState = networkState;
    self.netStateLabel.text = _networkState;
}

- (void)setAnswered:(BOOL)answered
{
    _answered = answered;
    if (!self.callee) {
        [self connected];
    }
}

- (void)setOppositeCamera:(BOOL)oppositeCamera
{
    _oppositeCamera = oppositeCamera;
    
//    [self cameraClick];
    self.isVideo = YES;
    // 如果对方开启摄像头
    if (oppositeCamera) {
        [self clearAllSubViews];
        
        [self initUIForVideoCaller];
        
        if (self.localCamera) {
            [self connected];
        } else {
            [self.ownImageView removeFromSuperview];
        }
    } else { // 对方关闭
        if (self.localCamera) {

            [self.adverseImageView removeFromSuperview];
            
            [UIView animateWithDuration:1.0 animations:^{
                self.ownImageView.frame = self.frame;
            }];
        } else {
            // 本地和对方都未开始摄像头
            self.isVideo = NO;
            [self clearAllSubViews];
            
            [self initUIForAudioCaller];
            
            [self connected];
        }
    }
}

@end
