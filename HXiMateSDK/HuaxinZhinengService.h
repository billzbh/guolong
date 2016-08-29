//
//  HuaxinZhinengService.h
//  HuaxinZhinengService
//
//  Created by Soul&PuD on 15/5/14.
//  Copyright (c) 2015年 耿健. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef enum
{
    OPEN_DEVICE_ERROR = 2,
    UPDATE_WORKKEY_ERROR = 8,
    DATA_LENGTH_ERROR = 13,
    CARD_COMMUNICATION_TIMEOUT = 14,
    SAM_COMMUNICATION_ERROR = 15,
    TRACK_INFO_ERROR = 16,
    PICC_COM_ERROR = 17,
    TRANSCOMMAND_ERROR = 18,
    USER_INPUT_TIMEOUT = 19,
    USER_CANCEL_OPERATION = 20,
    TERMINAL_ENCRYPTION_FAIlED = 21,
    SWIPE_CARD_ERROR = 22,
    DISPLAY_ERROR = 23,
    
}ErrorType;

typedef enum {
    TY_AUDIO_DEVICE = 1,
    TY_BLE_DEVICE = 2,
} DeviceType;

//代理协议
@protocol HuaxinZhinengServiceDelegate <NSObject>
/**
 *  获取设备连接结果
 *
 *  @param  isSuccess:是否连接成功
 *                YES:连接成功
 *                 NO:连接失败
 */
- (void)onConnectedDevice:(BOOL)isSuccess;

/**
 *  获取设备连接结果
 *
 *  @param  isSuccess:是否连接成功
 *                YES:连接成功
 *                 NO:连接失败
 */
- (void)onConnectedDeviceByName:(BOOL)isSuccess;

/**
 *  获取设备断开结果
 *
 *  @param  isSuccess:是否断开成功
 *                YES:断开成功
 *                 NO:断开失败
 */
- (void)onDisconnectedDevice:(BOOL)isSuccess;

/**
 *  获取商户号终端号
 *
 *  @param  deviceSN:商户号终端号
 */
- (void)onGetDeviceSN:(NSString *)deviceSN;

/**
 *  获取CSN号
 *
 *  @param  CSN:安全芯片号 CSN
 */
- (void)onGetCSN:(NSString *)CSN;


/**
 *  获取更新密钥结果
 *
 *  @param  isSuccess:是否成功更新密钥
 *                YES:更新成功
 *                 NO:更新失败
 */
- (void)onUpdataWorkingKey:(BOOL[])isSuccess;

/**
 *  获取使用MACkey加密后的数据
 *
 *  @param  data:8字节的加密数据
 */
- (void)onUpdataMac:(NSString *)data;

/**
 *  获取更新主密钥结果
 *
 *  @param  isSuccess:是否成功更新主密钥
 *                YES:更新成功
 *                 NO:更新失败
 */
- (void)onUpdataMainKey:(BOOL)isSuccess;

/**
 *  获取刷卡后返回的数据
 *
 *  @param  data:磁道明文
 */
//- (void)onSwipeCard:(NSDictionary *)data;    刷卡改为同步调用

/**
 *  获取pinBlock
 *
 *  @param  pinBlock:加密后的账号
 */
- (void)onPinBlock:(NSString *)pinBlock;

/**
 *  获取卡片的ATR数据
 *
 *  @param  atr:卡片的ATR数据
 */
- (void)onResetCard:(NSString *)atr;

/**
 *  获取打开卡片的结果
 *
 *  @param  isSuccess:是否成功打开卡片
 *                YES:打开成功
 *                 NO:打开失败
 */
- (void)onOpenCard:(BOOL)isSuccess;

/**
 *  获取关闭卡片的结果
 *
 *  @param  isSuccess:是否成功打开卡片
 *                YES:关闭成功
 *                 NO:关闭失败
 */
- (void)onCloseCard:(BOOL)isSuccess;

/**
 *  IC卡透传结果
 *
 *  @param  resBuf:返回的数据
 */
- (void)onTransCommand:(NSString *)resBuf;

/**
 *  获取显示结果
 *
 *  @param  isSuccess:是否显示成功
 *                YES:显示成功
 *                 NO:显示失败
 */
- (void)onDisplay:(BOOL)isSuccess;

/**
 *  获取等待事件结果
 *
 *  @param          result:包含等待事件结果的NSDictionary
 *               swipeCard:刷卡事件，1表示事件发生，0表示未发生
 *              plugInCard:插卡事件，1表示事件发生，0表示未发生
 *          nonContactCard:非接卡事件，1表示事件发生，0表示未发生
 *                  track2:二磁道数据
 *                  track3:三磁道数据
 */
- (void)onWaitEvent:(NSDictionary *)result;

/**
 *  获取返回的错误码
 *
 *  @param errorCode:错误码
 *  @param tradeType:枚举代码
 *  @param   message:交易信息，如无可以为nil
 */
- (void)onReceiveError:(NSString *)errorCode TradeType:(int)tradeType ErrorMessage:(NSString *)message;

/**
 *  获取请求用户输入的金额
 *
 *  @param  amount:用户输入的金额
 */
- (void)onInputAmount:(NSString *)amount;

/**
 *  获取通用输入的数据
 *
 *  @param  message:用户输入的数据
 */
- (void)onInput:(id)message;

/**
 *  获取用户输入按键
 *
 *  @param  ascKey:用户输入的一个按键
 */
- (void)onWaitInput:(NSString *)ascKey;

@end


@interface HuaxinZhinengService : NSObject
@property(nonatomic, assign) id<HuaxinZhinengServiceDelegate> delegate;

/**
 *  初始化通信接口
 *
 *  @param   DeviceType:设备类型
 *        TY_BLE_DEVICE:蓝牙    返回蓝牙列表
 *      TY_AUDIO_DEVICE:音频    返回nil
 */
- (NSArray *)deviceInit:(DeviceType)deviceType;

/**
 *  连接设备
 *  @param  device:设备对象
 *  @return 连接设备的结果
 *          YES:    连接成功
 *          NO :    连接失败
 */
- (BOOL)connectDevice:(id)device;

/**
 *  通过设备名称连接设备
 *
 *  @return 连接设备的结果
 *          YES:    连接成功
 *          NO :    连接失败
 */
- (BOOL)connectDeviceByName:(NSString *)devName;

/**
 *  获取连接音频，蓝牙设备的状态
 *  调用本接口之前，需要先调用initDevice:接口，否则无法正常工作
 *
 *  @return 设备状态
 */
- (int)getDeviceStatus;

/**
 *  断开设备
 *
 */
- (void)disconnectDevice;

/**
 *  获取ADI版本号
 *
 *  @return ADI版本号
 */
- (NSString *)getVersion;

/**
 *  获取MPos-华信智能业务库版本
 *
 *  @return 版本号
 */
- (NSString *)getServiceVersion;

/**
 *  启动蜂鸣器
 *
 */
- (void)beep;

/**
 * 显示界面
 *
 *  @param  rows:行数
 *  @param  cols:列数
 *  @param  content:显示内容，如果为空，可返回待机界面
 *  @param  refresh:是否刷新
 *              YES:刷新
 *               NO:不刷新
 *
 *  @return 是否显示成功
 */
- (void)displayRows:(int)rows Cols:(int)cols Content:(NSString *)content Refresh:(BOOL)refresh;

/**
 *  更新工作密钥
 *
 *  @param  ckey:磁道工作密钥明文tdk
 *  @param  pkey:PIN工作密钥明文pinKey
 *  @param  mkey:MAC工作密钥明文macKey
 */
- (void)updataWorkKey:(NSData *)ckey pinKey:(NSData *)pkey mackey:(NSData *)mkey;

/**
 *  获取外部读卡器设备SN号
 *
 *  @return 读卡器设备SN号
 */
- (void)getDeviceSN;

/**
 *  获取安全芯片卡号
 *
 *  @return PSAM卡号
 */
- (void)getCSN;

/**
 *  确认交易结束
 *
 *  @return 交易结果
 *      YES:交易成功
 *       NO:交易失败
 */
- (BOOL)confirmTransaction;


/**
 *  计算mac
 *
 *  @param  MKIndex 密钥索引，保留，暂未使用
 *  @param  message 用于计算mac的数据
 *
 *  @return Byte[]  Mac的值
 */
- (void)getMacWithMKIndex:(int)MKIndex Message:(NSData *)message;

/**
 *  更新主密钥
 *
 *  @param  value:密钥密文，20字节
 *  @return BOOL:密钥更新结果
 *           YES:密钥更新成功
 *            NO:密钥更新失败
 */
- (void)updataMainKey:(Byte[])value;

/**
 *  刷卡操作
 *
 *  @param  swipeCardType:刷卡模式，1不加密，返回明文；0为加密，返回密文
 *  @param  timeOut:刷卡超时时间
 *
 *  @return NSDictionary:携带的卡片信息
 *                track2:二磁道数据
 *                track3:三磁道数据
 */
- (NSDictionary *)swipeCard:(int)swipeCardType timeOut:(int)iTimeout;

/**
 *  加密账号
 *
 *  @param  account:账号
 *  @param  tips:提示串参数，显示在输入框上方的字符串
 *
 *  @return pinBlock:pinBlock加密
 */
- (NSString *)pinBlock:(NSString *)account Tips:(NSString *)tips;

/**
 *  卡片复位
 *
 *  @param  cardType:卡片类型，0为磁条卡，1为IC卡
 *
 *  @return NSString:卡片的ATR数据
 */
- (void)resetCard:(int)cardType;

/**
 *  打开卡片
 *
 *  @param  cardType:卡片类型，0为磁条卡，1为IC卡
 *
 *  @return BOOL:卡片打开结果
 *           YES:卡片打开成功
 *            NO:卡片打开失败
 */
- (void)openCard:(int)cardType;

/**
 *  关闭卡
 *
 *  @param  cardType:卡片类型，0为磁条卡，1为IC卡
 *
 *  @return BOOL:卡片关闭结果
 *           YES:卡片关闭成功
 *            NO:卡片关闭失败
 */
- (void)closeCard:(int)cardType;

/**
 *  IC卡透传接口，用于发送APDU命令
 *
 *  @param             cmd:apdu指令
 *  @param      cmdDataLen:指令长度
 *  @param          resBuf:指令返回的数据
 *  @param      cmdTimeOut:指令发送超时
 *
 *  @return         int:返回数据状态
 *                   <0:表示指令失败，将返回错误码
 *                   >0:表示指令成功，将返回数据长度
 */
- (NSString *)transCommand:(Byte[])cmd cmdDataLen:(int)cmdLen;

/**
 *  停止发送命令
 *
 */
- (void)cancel;

/**
 *  在给定的时间内等待刷卡、IC卡插卡或非接卡事件
 *
 *  @param           swipeCard:是否等待刷卡
 *  @param          plugInCard:是否等待插卡
 *  @param      nonContactCard:是否等待非接卡事件
 *  @param             timeOut:超时时间
 *
 *  @return       NSDictionary:
 *                   swipeCard:刷卡事件，1表示事件发生，0表示未发生
 *                  plugInCard:插卡事件，1表示事件发生，0表示未发生
 *              nonContactCard:非接卡事件，1表示事件发生，0表示未发生
 *                      track2:二磁道数据
 *                      track3:三磁道数据
 */
- (void)waitEventSC:(BOOL)swipeCard PIC:(BOOL)plugInCard NCC:(BOOL)nonContactCard timeOut:(long)itimeout;

/**
 *  输入金额，返回金额
 *
 *  @param  timeOut:超时时间
 *  @param     tips:提示信息
 *
 *  @return NSString *:金额（以分为单位）
 */
- (void)inputAmount:(int)timeOut Tips:(NSString *)tips;

/**
 *  通用输入
 *
 *  @param  timeOut:超时时间
 *  @param     tips:提示信息
 *
 *  @return NSString *:输入的串
 */
- (void)input:(int)timeOut Num:(int)keyNum Tips:(Byte [])tips;

/**
 *  等待一个按键输入
 *
 *  @param  timeOut:超时时间
 *
 *  @return NSString *:按键值
 */
- (void)waitInput:(int)timeOut Num:(int)keyNum Key:(Byte [])allowKey;


@end
