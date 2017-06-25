//
//  XWVoipCenter.h
//  XWVoipCenter
//
//  Created by viviwu on 2013/10/13.
//  Copyright © 2013年 viviwu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreTelephony/CTCallCenter.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/SCNetworkReachability.h>
//#import <Availability.h>

#if defined(__APPLE__)
#include "TargetConditionals.h"
#endif

#ifndef XW_DEPRECATED
  #if defined(_XWC_VER)
  #define XW_DEPRECATED __declspec(deprecated)
  #else
  #define XW_DEPRECATED __attribute__ ((deprecated))
  #endif
#endif

#define XW_UNUSED(x) ((void)(x))

#if defined(_XWC_VER)
    #define XW_PUBLIC	__declspec(dllexport)
    #define XW_VAR_PUBLIC extern __declspec(dllexport)
#else
    #define XW_PUBLIC
    #define XW_VAR_PUBLIC extern
#endif

extern NSString *const kVoipCoreUpdate;
extern NSString *const kXWCallUpdate;
extern NSString *const kXWVoipRegistrationUpdate;
extern NSString *const kXWCallGlobalStateUpdate;
extern NSString *const kXWVoipConfiguringStateUpdate;
extern NSString *const kXWCallBluetoothAvailabilityUpdate;
extern NSString *const kXWCallNotifyReceived;
extern NSString *const kXWCallEncryptionChanged;


typedef enum _XWCallState{
    XWCallIdle,	/**<Initial call state */
    XWCallIncomingReceived, /**<This is a new incoming call */
    XWCallOutgoingInit, /**<An outgoing call is started */
    XWCallOutgoingProgress, /**<An outgoing call is in progress */
    XWCallOutgoingRinging, /**<An outgoing call is ringing at remote end */
    XWCallOutgoingEarlyMedia, /**<An outgoing call is proposed early media */
    XWCallConnected, /**<Connected, the call is answered */
    XWCallStreamsRunning, /**<The media streams are established and running*/
    XWCallPausing, /**<The call is pausing at the initiative of local end */
    XWCallPaused, /**< The call is paused, remote end has accepted the pause */
    XWCallResuming, /**<The call is being resumed by local end*/
    XWCallRefered, /**<The call is being transfered to another party, resulting in a new outgoing call to follow immediately*/
    XWCallError, /**<The call encountered an error*/
    XWCallEnd, /**<The call ended normally*/
    XWCallPausedByRemote, /**<The call is paused by remote end*/
    XWCallUpdatedByRemote, /**<The call's parameters change is requested by remote end, used for example when video is added by remote */
    XWCallIncomingEarlyMedia, /**<We are proposing early media to an incoming call */
    XWCallUpdating, /**<A call update has been initiated by us */
    XWCallReleased, /**< The call object is no more retained by the core */
    XWCallEarlyUpdatedByRemote, /**< call is updated by remote while not yet answered (early dialog SIP UPDATE received).*/
    XWCallEarlyUpdating /**< are updating the call while not yet answered (early dialog SIP UPDATE sent)*/
} XWCallState;

typedef enum _XWVoipRegistrationState{
    XWVoipRegistrationNone, /**<Initial state for registrations */
    XWVoipRegistrationProgress, /**<Registration is in progress */
    XWVoipRegistrationOk,	/**< Registration is successful */
    XWVoipRegistrationCleared, /**< Unregistration succeeded */
    XWVoipRegistrationFailed	/**<Registration failed */
}XWVoipRegistrationState;

typedef enum _XWVoipConfiguringState {
    XWVoipConfiguringSuccessful,
    XWVoipConfiguringFailed,
    XWVoipConfiguringSkipped
} XWVoipConfiguringState;

//TransportType
typedef enum _XWVoipTransportType {
  XWVoipTransportTcp,
  XWVoipTransportUdp,
//  TLSTransport  /*TLS is unavailable currently*/
//  DTLSTransport /*DTLS is unavailable currently*/
} XWVoipTransportType;

//***********************************

#pragma mark--********XWVoipCenter

/*
 @any questions, please contact：vivi705@qq.com
 New feature in v1216:
 1.Enable 3 codecs：ilbc/8kHz,g729/8kHz,silk/16kHz ，default is ilbc
 2.Enable new notification callback format，attention to change！
 3.Fixed problem on call reservation \ pause operation invalid;
 4.Fix bugs about crash when logout to terminate sometimes;
 5.Support "https-only" ;
*/
@interface XWVoipCenter : NSObject

@property(nonatomic, assign)BOOL shouldDropWhenCTCallIn;
@property (copy, nonatomic) NSString * apnsToken;
@property (copy, nonatomic) NSString * voipToken;

XW_PUBLIC + (XWVoipCenter*)instance;

XW_PUBLIC + (void)addProxyConfig:(NSString*)username
                        password:(NSString*)password
                          domain:(NSString*)sipserver
                       transport:(XWVoipTransportType)dtp;

XW_PUBLIC + (BOOL)isProxyParameterAvailable;

#pragma mark--VoipCore Life Cycle
XW_PUBLIC - (void)resetVoipCore;
XW_PUBLIC - (void)startVoipCore;
XW_PUBLIC + (BOOL)isVoipCoreReady;

#pragma markk--ProxyConfig

XW_PUBLIC + (void)removeAllAccountsData;
XW_PUBLIC - (void)destroyVoipCore;

//called when applicationWillResignActive
XW_PUBLIC + (void)VoipCallWillResignActive;//!!!
XW_PUBLIC + (void)VoipCallWillTerminate;
XW_PUBLIC - (void)becomeActive;
XW_PUBLIC - (void)activeIncaseOfIncommingCall;
XW_PUBLIC - (BOOL)enterBackgroundMode;

XW_PUBLIC + (const char*)getCurrentCallAddress;
XW_PUBLIC + (const char*)getCurrentCallAddressRemoteAddress;

XW_PUBLIC - (void)call:(NSString *)address
           displayName:(NSString*)displayName
              transfer:(BOOL)transfer;

XW_PUBLIC - (void)fixRing;
XW_PUBLIC - (BOOL)allowSpeaker;

XW_PUBLIC - (void)answerCallWithVideo:(BOOL)video;
XW_PUBLIC - (void)declineCall;
XW_PUBLIC - (void)hangupCall;
XW_PUBLIC - (void)sendDigitForDTMF:(const char)digit;
XW_PUBLIC - (void)voipMicMute:(BOOL)mute;
XW_PUBLIC - (void)setSpeakerEnabled:(BOOL)enable;
XW_PUBLIC - (void)holdOnCall:(BOOL)holdOn;//pause call
XW_PUBLIC - (void)setBluetoothEnabled:(BOOL)enable;//default is enable

XW_PUBLIC - (NSString*)updateStatsWithTimer:(NSTimer *)timer;
//you may need a timer to invoke

XW_PUBLIC - (int)getCallDuration;
 

@end



