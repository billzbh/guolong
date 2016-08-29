//
//  CBSessionController.h
//
//  Created by hxsmart on 15/1/7.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//

#ifndef CBSessionController_h
#define CBSessionController_h

typedef enum
{
    CBSessionStateOk = 0,           // 连接成功状态
    CBSessionStateDisconnected,     // 未连接状态
    CBSessionStateClosed,           // CBSession处于关闭状态, 未执行openSession
    CBSessionStatePoweredOff,       // 蓝牙开关未打开, 需要提示打开setup中的蓝牙开关
    CBSessionStateUnsupported,      // 不支持BT4LE
    CBSessionStateUnauthorized,     // App未经授权使用BT4LE
    CBSessionStateTimeout,          // 数据包接收超时
    CBSessionStateUnknown,          // 未知的状态
}CBSessionState;

@protocol CBSessionControllerDelegate <NSObject>

@optional

// 当openSession时, 将自动查找支持的设备，查找到设备后，通过该delegate返回设备名称
- (void)cbSessionDelegateFoundAvailableDevice:(NSString *)deviceName;

#ifdef SUPPORT_DEVICE_M35
// 非iCR设备，移交控制，可调第三方的SDK来实现设备的控制
- (void)cbSessionDelegateReleaseControl:(NSString *)deviceName;
#endif

@end

@interface CBSessionController : NSObject

@property (assign, nonatomic) id<CBSessionControllerDelegate> delegate;


+ (CBSessionController *)sharedController;

- (BOOL)openSession;

- (void)closeSession;

// 绑定查找到的设备, 只有绑定设备后，设备才可以正常连接; deviceName = nil则解除绑定
- (void)bindingDevice:(NSString *)deviceName;

- (BOOL)isConnecting;

- (BOOL)isWorking;

// 发送数据(发送原始数据)
// 返回码：
//  CBSessionStateOk : 成功
//  其它              : 失败
- (CBSessionState)sendData:(NSData *) inData;

// 发送数据包并同步接收数据包，该方法必须在后台线程中执行（非main线程）
// 返回码：
//  CBSessionStateOk : 成功
//  其它              : 失败
- (CBSessionState)syncSendReceive:(NSData *) inData outData:(NSData **) outData timeout:(int) timeout;

@end


#endif
