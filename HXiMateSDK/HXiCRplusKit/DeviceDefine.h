//
//  DeviceDefine.h
//  HXiMateSDK
//
//  Created by zbh on 15/12/8.
//  Copyright © 2015年 hxsmart. All rights reserved.
//

#ifndef DeviceDefine_h
#define DeviceDefine_h

#define         DEVICE_HXSMARTIMATE 	 		0 // 华信iCR
#define         DEVICE_LANDIREADER 				1 // 联迪M35/M36
#define         DEVICE_WUHANTIANYU 		 		2 // 武汉天喻mPos

//- (void)BLEDelegateConnectStatus:(int)status; 可能返回的值
#define         BLUETOOTH_FOUNDCHARACTERISTIC_FAIL  9 //发现设备服务失败
#define         BLUETOOTH_FOUNDSERVICE_FAIL         10 //发现设备服务失败
#define         BLUETOOTH_DISCONNECTED              11 //蓝牙设备已断开
#define         BLUETOOTH_CONNECTED                 12 //蓝牙设备已连接
#define         BLUETOOTH_CONNECTING_FAIL           14 //连接失败

//-(void)BLEDelegateInitStatus:(int)Initstatus; 蓝牙中央设备返回的初始化结果
//只有返回CBSessionStateReady，才能开始调用蓝牙搜索，连接等
typedef enum
{
    CBSessionStateOk = 0,           // 连接成功状态
    CBSessionStateReady,            // 准备状态
    CBSessionStateDisconnected,     // 未连接状态
    CBSessionStateClosed,           // CBSession处于关闭状态, 未执行startSearch
    CBSessionStatePoweredOff,       // 蓝牙开关未打开, 需要提示打开setup中的蓝牙开关
    CBSessionStateUnsupported,      // 不支持BT4LE
    CBSessionStateUnauthorized,     // App未经授权使用BT4LE
    CBSessionStateTimeout,          // 数据包接收超时
    CBSessionStateCanceltransfer,   // 取消收发数据
    CBSessionStateUnknown,          // 未知的状态
}CBSessionState;


//具体接口的错误宏
#define         ERROR_DEVICE_NOT_CONNECTED          -1 //"设备未连接"
#define         ERROR_DEVICE_BUSY                   -2 //"设备忙"
#define         ERROR_DEVICE_COMM_FAULT             -3 //"与设备通讯失败"
#define         ERROR_BLUETOOTH_DISABLE             -4 //"蓝牙未开启"

#define         ERROR_TIMEOUT                       -10 //"操作超时"
#define         ERROR_CANCEL                        -11 //"操作被取消"
#define         ERROR_FAULT                         -12 //"操作失败"
#define         ERROR_NOT_SUPPORTED                 -19 //"不支持的功能"

#define         ERROR_XMEMORY_LENGTH                -20 //"数据长度超过512"
#define         ERROR_XMEMORY_LENGTH_DATABUFF       -21 //"dataBuff实际的大小不等于datalen"

#define         ERROR_OTHER                         -99 //"其它错误"



//功能的设置参数宏
#define         EVENT_TYPE_MAGCARD				"1" //刷卡事件
#define         EVENT_TYPE_ICCARD				"2" //插IC卡事件
#define         EVENT_TYPE_MIFCARD				"3" //射频卡事件

#define         IC_CARD_APDU_TYPE_NORMAL  		0	//普通IC卡类型
#define         IC_CARD_APDU_TYPE_PBOC 	  	1	//PBOC IC卡类型

#define         USER_SLOT   0 			//用户卡座
#define         MIF_SLOT    1 			//射频卡读卡器
#define         SAM1_SLOT   4 			//第一SAM卡座
#define         SAM2_SLOT   5 			//第二SAM卡座



typedef void (^OperationBlock)(NSDictionary *dict);


#endif /* DeviceDefine_h */
