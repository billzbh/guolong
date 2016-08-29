//
//  DeviceInterface.h
//  HXiMateSDK
//
//  Created by zbh on 15/12/8.
//  Copyright © 2015年 hxsmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "DeviceDefine.h"


@protocol HXiCRplusDelegate <NSObject>

@required

//初始化蓝牙中央设备的结果回调,只有返回Ready状态,才能继续操作
-(void)HXiCRplusDelegateInitStatus:(int)Initstatus;

@optional
// 启动搜索后，找到设备后，通过该delegate返回设备
- (void)HXiCRplusDelegateFoundAvailableDevice:(CBPeripheral *)device;

// 1. 启动连接时，通过此delegate返回连接状态
// 2.（主动还是被动）断开连接时，通过此delegate返回连接状态
- (void)HXiCRplusDelegateConnectStatus:(int)status;

@end


@interface DeviceInterface : NSObject

//初始化并设置delegate
- (void)OpenSessionWithDelegate:(id<HXiCRplusDelegate>)delegate;

//关闭连接(与OpenSessionWithDelegate)
- (void)CloseSession;

//OpenSessionWithDelegate之后通过HXiCRplusDelegateInitStatus回调结果，只有放回Ready时，才能直接调用此接口，自动连接包含有此deviceName的设备
- (void)bindingDevice:(NSString *)deviceName;

//OpenSessionWithDelegate之后通过HXiCRplusDelegateInitStatus回调结果，只有放回Ready时，才能直接调用此接口，搜索设备
- (void)searchBLE:(int)Timeout;

//停止搜索
- (void)stopSearch;

//- (void)searchBLE:(int)Timeout调用后，通过HXiCRplusDelegateFoundAvailableDevice返回设备，再调用此接口
- (void)connectDevice:(CBPeripheral*)Peripheral;

//主动断开连接，并且不会自动再次连接
- (void)disconnect;

//蓝牙是否连接
- (BOOL)isConnecting;

//是否发送接收数据中
- (BOOL)isWorking;

//查询已匹配的蓝牙名称
-(NSString*)getBindingDeviceName;

//获取设备信息
-(void)getDeviceInfo:(OperationBlock)deviceInfoBlock;

//取消耗时操作
-(void)cancel;

//鸣叫一声
-(void)Buzzer;

//显示屏显示文字
-(void)displayAtLine:(int)line Col:(int)col Message:(NSString*)message ClearScreen:(BOOL)refresh;


//等待事件
-(void)waitEvent:(Byte)eventMask timeout:(NSInteger)timeout callback:(OperationBlock)deviceInfoBlock;

//刷卡
-(void)swipeCard:(NSInteger)timeout callback:(OperationBlock)deviceInfoBlock;

//测试卡片是否存在
-(BOOL)pbocTestCard:(int)slot;

//关闭卡片
-(BOOL)pbocCloseCard:(int)slot;



@end
