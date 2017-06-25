//
//  XWCallViewController.m
//  XWCall
//
//  Created by Qway on 2017/6/21.
//  Copyright © 2017年 viviwu. All rights reserved.
//

#import <XWVoipKit/XWVoipCenter.h>
#import "XWCallViewController.h"
#import "XWCallView.h"

#define kUserDef  [NSUserDefaults standardUserDefaults]
#define kUserDefObj(key) [[NSUserDefaults standardUserDefaults] objectForKey:key]
@interface XWCallViewController ()
{
    NSString * sipServer;
    NSString * username;
    NSString * password;
    
    NSString * callNumber;
    
    XWCallView * presentView;
}
@property XWVoipCenter * voipCenter;

@property (weak, nonatomic) IBOutlet UIView *configProxyView;
@property (weak, nonatomic) IBOutlet UITextField *sipServerTF;
@property (weak, nonatomic) IBOutlet UITextField *usernameTF;
@property (weak, nonatomic) IBOutlet UITextField *passwordTF;

@property (weak, nonatomic) IBOutlet UIView *callDialView;
@property (weak, nonatomic) IBOutlet UILabel *accountLabel;
@property (weak, nonatomic) IBOutlet UITextField *numberTF;
@property (weak, nonatomic) IBOutlet UIButton *callBtn;


@end

@implementation XWCallViewController



- (IBAction)congfigSipProxy:(id)sender {
    
     [self.view endEditing:YES];
    
    if (self.sipServerTF.text.length<8 ||self.usernameTF.text.length<6 || self.passwordTF.text.length<6)  return;
    
    sipServer= self.sipServerTF.text;
    password = self.passwordTF.text;
    username = self.usernameTF.text;
    
    [XWVoipCenter addProxyConfig:username
                        password:password
                          domain:sipServer
                       transport:XWVoipTransportUdp];
    
    [kUserDef setObject:sipServer forKey:@"sipServer"];
    [kUserDef setObject:username forKey:@"username"];
    [kUserDef setObject:password forKey:@"password"];
    [kUserDef synchronize];
}

- (IBAction)makeVoipCall:(id)sender {
    
    [self.view endEditing:YES];
    
    callNumber = self.numberTF.text;
    if(callNumber.length<3) return;
    
    [self.voipCenter call: callNumber
              displayName: @"vivi"
                 transfer: NO ];
    XWCallView* callView = [[XWCallView alloc]initWithIsVideo:NO isCallee:NO];
    callView.nickName = callNumber ?: @"vivi wu";
    callView.connectState = @"voip call";
    callView.networkState = @"Connecting ...";
    
    [callView show];
    presentView = callView;
}

- (IBAction)tapScreenToHideKeyboard:(id)sender {
    
    [self.view endEditing:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.voipCenter=[XWVoipCenter instance];
    
    username = kUserDefObj(@"username");
    password = kUserDefObj(@"password");
    sipServer= kUserDefObj(@"sipServer");
    
    self.usernameTF.text = username;
    self.passwordTF.text = password;
    self.sipServerTF.text=sipServer;
    
    if(username.length>=6 && password.length>=6 && sipServer.length>=8)
    {
        [XWVoipCenter addProxyConfig:username
                            password:password
                              domain:sipServer
                           transport:XWVoipTransportTcp];
    }
    

    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.configProxyView.hidden=NO;
    self.callDialView.hidden=YES; 
  
//    // 检测 sip注册状态
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(registrationUpdate:)  name: kXWVoipRegistrationUpdate
                                               object: nil];

//    //检测voip来电状态
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(callUpdateWithCallNotification:)
                                                 name: kXWCallUpdate
                                               object: nil];
    //检测通话操作
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(callUpdateWithActionNotification:)
                                                 name: kXWCallActionNotification
                                               object: nil];
}

-(void)callUpdateWithActionNotification:(NSNotification*)notif{
    NSDictionary * action = notif.userInfo;
    NSLog(@"action==%@", action);
}

- (void)registrationUpdate:(NSNotification*)notif
{
    XWVoipRegistrationState state = [[notif.userInfo objectForKey: @"state"] intValue];
    NSString * message=[notif.userInfo objectForKey: @"message"];
    NSString * connectState=message;
    //    NSLog(@"registrationUpdate:------>\n%@", notif.userInfo);
    switch (state) {
        case XWVoipRegistrationNone:
            connectState=@"CallRegistration None";
            break;
            
        case XWVoipRegistrationProgress:
            connectState=@"CallRegistration Progress";
            break;
            
        case XWVoipRegistrationOk:
            connectState=@"CallRegistration Ok";
            self.accountLabel.text=kUserDefObj(@"username");
            self.accountLabel.textColor=[UIColor greenColor];
            self.view.backgroundColor=[UIColor groupTableViewBackgroundColor];
            
            self.configProxyView.hidden=YES;
            self.callDialView.hidden=NO;
            break;
            
        case XWVoipRegistrationCleared:
            connectState=@"CallRegistration Cleared";
            break;
            
        case XWVoipRegistrationFailed:
            connectState=@"CallRegistration Failed";
            self.configProxyView.hidden=NO;
            self.callDialView.hidden=YES;
            self.view.backgroundColor=[UIColor brownColor];
            break;
            
        default:
            break;
    }
    self.title=connectState;
}


- (void)callUpdateWithCallNotification:(NSNotification*)notify
{
    XWCallState state = [[notify.userInfo objectForKey: @"state"] intValue];
    NSString * userName =notify.userInfo[@"handle"];
    NSLog(@"%@== %@", notify.userInfo[@"message"], userName);
    
    switch (state)
    {
        case XWCallOutgoingInit:
        case XWCallOutgoingProgress:
        case XWCallOutgoingRinging:
        case XWCallOutgoingEarlyMedia:
        {
            presentView.connectState=@"Outgoing call";
        }
            break;
            
        case XWCallIncomingReceived:
        {
            XWCallView *callView = [[XWCallView alloc]initWithIsVideo:NO isCallee:YES];
            callView.nickName = userName ?: @"vivi wu";
            callView.connectState = @"Incoming Call";
            callView.networkState = @"voip call";
            
            [callView show];
            presentView = callView;
        }
            break;
            
        case XWCallPausedByRemote:
        { /**<The call is paused by remote end*/
            presentView.connectState=@"Call Paused";
        }
        case XWCallConnected:
        case XWCallStreamsRunning:
        {
            presentView.connectState=@"Streams Running...";
        }
            break;
            
        case XWCallUpdatedByRemote:
        {/**<like:when video is added by remote */
            presentView.connectState=@"Call Updated";
        }
            break;
            
        case XWCallError:
        {//Busy Here
            NSString * errorMsg = [notify.userInfo objectForKey:@"message"];
            presentView.connectState=@"Call Error";
            presentView.networkState=errorMsg;
            [presentView dismiss];
        }
        case XWCallEnd:
        {
            presentView.connectState=@"call ended normally";
            [presentView dismiss];
        }
            break;
            
        case XWCallReleased:
            
            presentView.connectState=@"XWCall Released";
            [presentView dismiss];
            break;
            
        default:
            break;
    }
    
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    removeObserver
}

- (void)dealloc
{
    NSLog(@"%s-->removeObserver", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
