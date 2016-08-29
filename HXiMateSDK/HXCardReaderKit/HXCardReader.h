//
//  HXCardReader.m
//  Huaxin Internet Card Reader Kit
//
//  Created by Qingbo Jia on 15-01-07.
//  Copyright (c) 2014年 hxsmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 打印机状态
#define PRINTER_OK                      0
#define PRINTER_CONNECTED               1
#define PRINTER_NOT_CONNECTED           2
#define PRINTER_OUT_OF_PAPER            3
#define PRINTER_OFFLINE                 4
#define PRINTER_NOT_SUPPORT             5

typedef enum {
    HXCardReaderStatusOK = 0,          // 成功状态
    HXCardReaderStatusDisconnected,    // 未连接状态
    HXCardReaderStateClosed,           // CBSession处于关闭状态, 未执行openSession
    HXCardReaderStatePoweredOff,       // Setup中蓝牙开关未打开
    HXCardReaderStateUnsupported,      // iPhone或iPad不支持BT4.0 LE
    HXCardReaderStateUnauthorized,     // App未经授权使用BT4.0 LE
    HXCardReaderStateTimeout,          // 与ICR通讯时，数据包接收超时
    HXCardReaderStateUnknown,          // 未知的状态
} HXCardReaderStatus;

@protocol HXCardReaderDelegate <NSObject>

@optional

// 当openSession时或蓝牙连接连通或者中断时(ICR断电)，该方法被调用，通知目前的蓝牙连接状态
- (void)hxCardReaderDelegateConnectStatus:(HXCardReaderStatus)status;

// 当openSession时, 将自动查找支持的设备，查找到设备后，通过该delegate返回设备名称
- (void)hxCardReaderDelegateFoundAvailableDevice:(NSString *)deviceName;

/*
 打印机有关Delegate
 */
// 当打印机蓝牙连接连通或者中断时，该方法被调用，通知目前的蓝牙连接状态
- (void)printerDelegateStatusResponse:(NSInteger)status;

@end

@interface HXCardReader : NSObject

@property (assign, nonatomic) id<HXCardReaderDelegate> delegate;

// 获取HXCardReader实例
+ (HXCardReader *)sharedController;

// 打开与iCR的连接会话，返回YES会话建立成功
- (BOOL)openSession;

// 关闭与iCR的连接会话
- (void)closeSession;

// 绑定查找到的设备, 只有绑定设备后，设备才可以正常连接; 也可以在openSession之前调用
- (void)bindingDevice:(NSString *)deviceName;

// 查询目前绑定的设备名称，返回nil未绑定
- (NSString *)queryBindingDevice;

// 检测蓝牙连接是否正常，返回HXCardReaderStatusOK表示连接正常
- (HXCardReaderStatus)connectingTest;

// 检测iCR是否在工作状态，返回YES表示正在工作中。
- (BOOL)isWorking;

// iCR产品序列号
- (NSString *)deviceSerialNumber;

// 蓝牙MAC地址
- (NSString *)deviceBluetoothMac;


/**
 *	@brief	等待事件结束后，该方法被调用，返回结果
 *
 *	@param 	 returnCode不为0，error有错误信息
 *            eventId ：1检测到刷卡；2检测到IC卡；4检测到射频卡
 *            data    ：刷卡时返回二磁道、三磁道数据；IC返回复位数据；射频卡返回4字节的序列号
 */
typedef void (^waitEventBlock)(int returnCode,int eventId,NSData * data,NSString * error);

// 等待事件，包括磁卡刷卡、Pboc IC插入、放置射频卡。timeout是最长等待时间(秒)
// eventMask的bit来标识检测的部件：
//      0x01    等待刷卡事件
//      0x02    等待插卡事件
//      0x04    等待射频事件
//      0xFF    等待所有事件
// 等待的结果通过delegate响应
- (void)waitEvent:(Byte)eventMask timeout:(NSInteger)timeout completionBlock:(waitEventBlock)waitEventBlock;

// 查询iCR固件版本号
// 返回：
// nil         : iCR不支持取版本或通讯错误
// "A.A,B.B.B,C" : 硬件和固件版本，其中A为硬件版本，B为固件版本,C为蓝牙版本
- (NSString *)deviceVersion;

// iCR蜂鸣响一声
- (void)buzzer;

// 查询打印机状态, 打印机的状态通过Delegate获取
- (void)printerStatus;

/**
 *  @brief    打印普通文本
 *  @param    printString   打印的文本信息
 *  @param    size          字体大小 （0x00 正常字体  0x01  一倍  0x02 两倍）
 */
- (void)print:(NSString *)printString FontSize:(int)size;

//打印大标题,居中
- (void)printTitile:(NSString *)printString;


/**
 *  @brief    M36打印
 *  @param    title            打印居中标题（为nil时表示不打印标题）
 *  @param    printString      打印正文的文本
 *  @param    textFontSize     正文字体大小 （0x00 正常字体  0x01  一倍  0x02 两倍）
 *  @param    Multi            打印几联
 */
-(void)M36Print:(NSString*)title text:(NSString*)printString textFontSize:(int)size Multi:(int)number;


/**
 *  @param    PageContent      字典（格式： "1" ：NSArray对象 ,"2":NSArray对象,...）(每个NSArray 按顺序放置【title，正文，正文字体大小】值
 *                             都是String型，包括字体大小 “0”，“1”，“2”分别是正常，1倍大，2倍大，标题没有给“”空文本)
 *  @param    Multi            打印几联（最多4联）
 */
-(void)M36Print:(NSDictionary *)PageContent;



+ (NSData *)twoOneData:(NSString *)sourceString;

+ (NSString *)oneTwoData:(NSData *)sourceData;

@end
