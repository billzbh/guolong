//
//  ZCenterManager.h
//  ZeasySDK
//
//  Created by zbh on 16/12/18.
//  Copyright © 2016年 zhangbh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ZPeripheral.h"

typedef enum
{
    CBSessionStateOk = 0,           // 连接成功状态
    CBSessionStateReady,            // 蓝牙准备OK的状态
    CBSessionStateDisconnected,     // 未连接状态
    CBSessionStateClosed,           // CBSession处于关闭状态
    CBSessionStatePoweredOff,       // 蓝牙开关未打开, 需要提示打开setup中的蓝牙开关
    CBSessionStateUnsupported,      // 不支持BT4LE
    CBSessionStateUnauthorized,     // App未经授权使用BT4LE
    CBSessionStateTimeout,          // 数据包接收超时
    CBSessionStateCanceltransfer,   // 取消收发数据
    CBSessionStateNotFoundCharacteristic, //发现设备特征失败
    CBSessionStateNotFoundService,        //发现设备服务失败
    CBSessionStateConnectingFail,         //发起连接失败
    CBSessionStateUnknown,                // 未知的状态
    CBSessionStateReseting                // 蓝牙重启
}ZEasySessionState;

@interface ZCenterManager : NSObject <CBCentralManagerDelegate>
//获取单例
+ (ZCenterManager *)shareCenterManager;


//搜索(UUID过滤优先生效,蓝牙名称过滤，可以为nil)带超时
-(void)startSearch:(int)timeout filterByServiceUUIDs:(NSArray<NSString *> *)UUIDStrings filterByBluetoothName:(NSArray<NSString *> *)NAME;

//搜全部蓝牙设备
-(void)startSearch:(int)timeout;


//停止搜索
-(void)stopSearch;


//链接设备
-(void)connectPeripheral:(ZPeripheral *)pheripheral;//需要将搜索到的pheripheral设置写特征，读特征


//主动断开设备
-(void)disconnectPeripheral:(ZPeripheral *)pheripheral;


//设置是否被动断开时重新连接。//如果需要后台有保持可以重连特性，需要xcode设置后台模式
-(void)setAutoConnected:(ZPeripheral *)pheripheral YesOrNo:(BOOL)isAutoConnected;


//后续考虑是否恢复和保存蓝牙状态
@end
