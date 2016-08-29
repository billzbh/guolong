//
//  iMateAppCombinedFace.h
//  HXiMateSDK
//
//  Created by hxsmart on 14-7-3.
//  Copyright (c) 2014年 hxsmart. All rights reserved.
//
#import <Foundation/Foundation.h>

typedef enum {
    kProcessErrorNoConnected = -1,          // 设备未连接
    kProcessErrorDeviceBusy,                // 设备忙
    kProcessErrorCommunicationTimeout,      // 与设备通讯超时
    kProcessErrorCommunicationFailure,      // 与设备通讯失败

    kProcessErrorOther = 1,                 // 其它错误
    
}iMateProcessError;

typedef enum {
    // 通用的处理类型
    kProcessTypeSwipeCard = 1,              // 刷卡处理
    kProcessTypeReadIdCard,                 // 读二代证件
    kProcessTypeBatteryLevel,               // 获取iMate的电池电量
    kProcessTypeXMemRead,                   // 读取iMate扩展内存中的数据
    kProcessTypeXMemWrite,                  // 向iMate的扩展内存写数据
    
    // Pboc IC卡的处理类型
    kProcessTypePbocIcInfo,                 // 读Pboc IC卡信息
    kProcessTypePbocIcLog,                  // 读Pboc IC卡日志
    kProcessTypePbocInitCore,               // Pboc卡交易核心初始化
    kProcessTypePbocInitTrans,              // Pboc卡交易初始化（读卡）
    kProcessTypePbocDoTrans,                // Pboc卡交易完成  （写卡）
    
    // 打印机有关的处理类型
    kProcessTypePrinterStatus,              // 获取打印机状态
    kProcessTypePrint,                      // 打印

    // 外接密码键盘有关的处理类型
    kProcessTypePinpadPowerOn,              // 打开外接密码键盘电源
    kProcessTypePinpadPowerOff,             // 关闭外接密码键盘电源
    kProcessTypePinpadVersion,              // 外接密码键盘查询固件版本号
    kProcessTypePinpadDownloadMasterKey,    // 外接密码键盘下载主密钥
    kProcessTypePinpadDownloadWorkingKey,   // 外接密码键盘下载工作密钥
    kProcessTypePinpadInputPin,             // 外接密码键盘输入密码
    
    // 内置指纹模块有关的处理类型
    kProcessTypeFingerprintPowerOn,         // 打开内置指纹模块电源
    kProcessTypeFingerprintPowerOff,        // 关闭内置指纹模块电源
    kProcessTypeFingerprintVersion,         // 内置指纹模块查询固件版本号
    kProcessTypeingerprintFeature,          // 内置指纹模块获取特征值

}iMateProcessType;

// Respond dictionary keys define
#define kSwipeCard_Track2String     @"SwipeCard_Track2String"
#define kSwipeCard_Track3String     @"SwipeCard_Track3String"
#define kReadIdCard_InfoData        @"ReadIdCard_InfoData"
#define kReadIdCard_InfoArray       @"ReadIdCard_InfoArray"
#define kReadIdCard_PhotoData       @"ReadIdCard_PhotoData"
#define kReadIdCard_PhotoImage      @"ReadIdCard_PhotoImage"
#define kBatteryLevel_LevelString   @"BatteryLevel_LevelString"
#define kXMemRead_XMemeData         @"XMemRead_XMemeData"

#define kPrinterStatus_StatusString @"PrinterStatus_StatusString"

#define kPbocIc_ResetAtrData        @"PbocIc_ResetAtrData"
#define kPbocIc_CardInfoArray       @"PbocIc_CardInfoArray"
#define kPbocIc_CardLogArray        @"PbocIc_CardLogArray"
#define kPbocIc_Field55String       @"PbocIc_Field55String"
#define kPbocIc_PanString           @"PbocIc_PanString"
#define kPbocIc_PanSeqNoString      @"PbocIc_PanSeqNoString"
#define kPbocIc_Track2String        @"PbocIc_Track2String"
#define kPbocIc_ExtInfoString       @"PbocIc_ExtInfoString"

#define kPinpad_VersionString       @"Pinpad_VersionString"
#define kPinpad_PinblockString      @"Pinpad_PinblockString"

#define kFingerprint_VersionString  @"Fingerprint_VersionString"
#define kFingerprint_FeatureString  @"Fingerprint_FeatureString"

@protocol iMateAppCombinedFaceDelegate <NSObject>

/* iMateProcessCommit方法的响应, 详细参数结构请参考iMateAppCombinedFace.readme
 * 参数：  returnCode           :    返回码，0表示处理成功, 其它值请参考错误代码
 *        respondDictionary    :    returnCode为0时有内容, 详细请参考iMateAppCombinedFace.readme
 *        error                :    returnCode不为0时有内容
 */
- (void)iMateDelegateCombinedResponse:(int)returnCode
                              requestType:(iMateProcessType)requestType
                            respondData:(NSDictionary *)respondDictionary
                                    error:(NSString *)error;
@optional
// 操作状态信息(后台运行状态报告）
- (void)iMateDelegateCombinedRuningStatus:(NSString *)statusString;

@end

@interface iMateAppCombinedFace : NSObject

@property (strong, nonatomic) id<iMateAppCombinedFaceDelegate> delegate;

// 获取iMateFace实例
+ (iMateAppCombinedFace *)sharedController;

// 打开与iMate的连接会话，返回YES会话建立成功。建议App从进入前台时调用。
- (BOOL)openSession;

// 关闭与iMate的连接会话，建议App从进入后台时调用。
- (void)closeSession;

// 检测iMate蓝牙连接是否正常，返回YES表示连接正常
- (BOOL)connectingTest;

// iMate产品序列号
- (NSString *)deviceSerialNumber;

// 检测iMate是否在工作状态，返回YES表示正在工作中。
- (BOOL)isWorking;

// 中断操作，仅对kProcessTypeSwipeCard，kProcessTypeReadIdCard，kProcessTypePbocIcInfo,kProcessTypePbocIcLog操作有效
- (void)cancel;

// 查询蓝牙打印机是否连接（目前仅支持普瑞特针式打印机）
- (BOOL)printerConnectingTest;

// 打印数据，\n结束
- (void)print:(NSString *)printString;

// 提交iMate处理, 处理的结果由iMateDelegateCombinedResponse响应
- (void)iMateProcessCommit:(iMateProcessType)requestType
         requestDictionary:(NSDictionary *)requestDictionary;

// iMate同步处理，直接返回处理的结果，需要线程中执行
- (NSDictionary *)iMateProcessSync:(iMateProcessType)requestType
                 requestDictionary:(NSDictionary *)requestDictionary;

@end
