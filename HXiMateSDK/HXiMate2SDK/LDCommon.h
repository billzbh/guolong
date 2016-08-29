//
//  LDCommon.h
//  readerDemo
//
//  Created by huangzq on 14-3-28.
//  Copyright (c) 2014年 landi. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - TYPE_DEFINE
typedef Byte OneByeInt;
typedef unsigned short twoByeInt;
typedef unsigned long long  LDULongLong;
typedef NSInteger LDREADERCMDNO;

#pragma mark - ENUM_VALUE

#define USE_GB2312_CODING CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)
/*
 *	@brief	指令类别
 *	@param 	QPBOC_FIRST_RECORD     第一个记录（最早的）
 *	@param 	QPBOC_LAST_RECORD      最后一个记录（最新的）
 */
typedef enum {
    QPBOC_FIRST_RECORD              = 0x00,
    QPBOC_LAST_RECORD               = 0x01,
}LDE_QPBOCRECORDTYPE;
/*
  *	@brief	指令类别
 *	@param 	CLA_COMMON              通用指令
 *	@param 	CLA_MANUFACTOREXTERN_1  用于各厂商扩展指令
 *	@param 	CLA_NORMALPLAIN         用于封装普通明文指令，提供指明文指令加密、验证MAC等功能
 *	@param 	CLA_MANUFACTOREXTERN_2  用于各厂商扩展指令
 */
typedef enum {
    CLA_COMMON              = 0xFF,
    CLA_MANUFACTOREXTERN_1  = 0xFE,
    CLA_NORMALPLAIN         = 0xFD,
    CLA_MANUFACTOREXTERN_2  = 0xFC,
}LDE_CLATYPE;

/**
 *	@brief	报文包装方式
 *	@param 	INSTYPE_PLAIN       明文
 *	@param 	INSTYPE_PLAIN_MAC   明文MAC验证
 *	@param 	INSTYPE_CIPHER      密文
 *	@param 	INSTYPE_CIPHER_MAC  密文MAC验证
 */
typedef enum {
    INSTYPE_PLAIN       = 0x00,
    INSTYPE_PLAIN_MAC   = 0x01,
    INSTYPE_CIPHER      = 0x02,
    INSTYPE_CIPHER_MAC  = 0x03,
}LDE_INSTYPE;

/**
 *	@brief	厂商代码
 *	@param 	MFCODE_LANDI            联迪
 *	@param 	MFCODE_TONGLIAN         通联
 *	@param 	MFCODE_SHENGFUTONG      富友
 *	@param 	MFCODE_LAKALA           盛付通
 *	@param 	MFCODE_ZHIFUBAO         支付宝
 */
typedef enum  {
    MFCODE_LANDI        = 0x00,
    MFCODE_TONGLIAN     = 0x01,
    MFCODE_FUYOU        = 0x02,
    MFCODE_SHENGFUTONG  = 0x03,
    MFCODE_LAKALA       = 0x04,
    MFCODE_ZHIFUBAO     = 0x05,
}LDE_MANUFACTURERCODE;

/**
 *	@brief	日志开关状态值
  *	@param 	LOGSTATE_CLOSE_LOG          关闭日志
 *	@param 	LOGSTATE_OPEN_TRADE_LOG     打开交易库日志
 *	@param 	LOGSTATE_OPEN_COM_LOG       打开通讯库日志
 *	@param 	LOGSTATE_OPEN_COM_TRADE_LOG 打开交易库和通讯库日志
 */
typedef enum {
    LOGSTATE_CLOSE_LOG          = 0x00,
    LOGSTATE_OPEN_TRADE_LOG     = 0x01,
    LOGSTATE_OPEN_COM_LOG       = 0x02,
    LOGSTATE_OPEN_COM_TRADE_LOG = 0x03,
}LDE_LOGSTATE;

typedef enum {
    IC_SLOT_ICC1        = 0x00,
    IC_SLOT_PSAM1       = 0x01,
    IC_SLOT_ICC2        = 0x02,
    IC_SLOT_PSAM2       = 0x03,
    IC_SLOT_RF          = 0x04,
}LDE_ICC_SLOT_TYPE;
/**
 *	@brief	公钥类型
  *	@param 	PKEYTYPE_ALL    所有公钥
 *	@param 	PKEYTYPE_RSA    RSA公钥
 *	@param 	PKEYTYPE_CSA    国密公钥
 */
typedef enum {
    PKEYTYPE_ALL = 0x00,
    PKEYTYPE_RSA = 0x01,
    PKEYTYPE_CSA = 0x02,
}LDE_PKEYTYPE;

/**
 *	@brief	DOL类型的描述
 *	@param 	DOLTYPE_ONLINE                  PIN-PAD联机DOL
 *	@param 	DOLTYPE_RESPONSE                PIN-PAD响应DOL
 */
typedef enum {
    DOLTYPE_ONLINE              = 0x01,
    DOLTYPE_RESPONSE            = 0x02,
}LDE_DOLTYPE;

/**
 *	@brief	数据发送的模式
 *	@param 	COMMUNICATIONMODE_MASTER    主从模式
 *	@param 	COMMUNICATIONMODE_DUPLEX    双工模式
 */
typedef enum {
    COMMUNICATIONMODE_MASTER = 0x00,
    COMMUNICATIONMODE_DUPLEX = 0x01,
}LDE_COMMUNICATIONMODE;

/**
 *	@brief	背光控制标志
 *	@param 	 SCREENCONTROLLER_CLEARANDCLOSE     清屏关背光
 *	@param 	SCREENCONTROLLER_BACKLIGHTCONTROL   背光亮度控制
 *	@param 	SCREENCONTROLLER_BACKLIGHTOFF       关背光
 *	@param 	SCREENCONTROLLER_BACKLIGHTON        开背光
 *	@param 	SCREENCONTROLLER_CLEAR              清屏
 */
typedef enum  {
    SCREENCONTROLLER_CLEARANDCLOSE      = 0x00,
    SCREENCONTROLLER_BACKLIGHTCONTROL   = 0x01,
    SCREENCONTROLLER_BACKLIGHTOFF       = 0x02,
    SCREENCONTROLLER_BACKLIGHTON        = 0x03,
    SCREENCONTROLLER_CLEAR              = 0x04,
}LDE_SCREENCONTROLLER;

/**
 *	@brief	密钥类型
 *	@param 	KEYTYPE_TRACK   磁道密钥
 *	@param 	KEYTYPE_PIN     PIN密钥
 *	@param 	KEYTYPE_MAC     MAC密钥
 *	@param 	KEYTYPE_MKEY    主密钥
 */
typedef enum  {
    KEYTYPE_TRACK   = 0x01,
    KEYTYPE_PIN     = 0x02,
    KEYTYPE_MAC     = 0x03,
    KEYTYPE_MKEY    = 0xEF,
}LDE_KEYTYPE;

/**
 *	@brief	强制刷卡的标志
 *	@param 	FORCESWIP_NO    不强制刷卡
 *	@param 	FORCESWIP_YES   强制刷卡
 */
typedef enum {
    FORCESWIP_NO   = 0x00,
    FORCESWIP_YES  = 0x01,
}LDE_FORCESWIP;

/**
 *	@brief	强制联机的标志
 *	@param 	FORCEONLINE_NO  不强制联机
 *	@param 	FORCEONLINE_YES 强制联机
*/
typedef enum {
    FORCEONLINE_NO  = 0x00,
    FORCEONLINE_YES = 0x01,
}LDE_FORCEONLINE;

/**
 *	@brief	持卡人验证结果
  *	@param 	CHVRETCODE_CANCEL       取消
 *	@param 	CHVRETCODE_COMPLETE     完成（对于PIN是完成，对于证件是正确）
 *	@param 	CHVRETCODE_ERROR        证件验证错误
 */
typedef enum {
    CHVRETCODE_CANCEL       = 0X00,
    CHVRETCODE_COMPLETE     = 0X01,
    CHVRETCODE_ERROR        = 0X02,
}LDE_CHVRETCODE;

/**
 *	@brief	通讯方式
 *	@param 	CHANNEL_AUDIOJACK   音频方式
 *	@param 	CHANNEL_BLUETOOTH   蓝牙方式
 */
typedef enum {
    CHANNEL_AUDIOJACK = 0x00,
    CHANNEL_BLUETOOTH = 0x01,
}LDE_CHANNEL;

/**
 *	@brief	EMV开始交易禁止卡种
 *	@param 	 FORBIDECARDTYPE_MAGCARD        禁止磁条卡
 *	@param 	FORBIDECARDTYPE_NONCONTACT      禁止非接触卡
 *	@param 	FORBIDECARDTYPE_CONTACT         禁止接触芯片卡
 */
typedef enum {
    FORBIDECARDTYPE_MAGCARD     = 0x04,
    FORBIDECARDTYPE_NONCONTACT  = 0x02,
    FORBIDECARDTYPE_CONTACT     = 0x01,
}LDE_FORBIDECARDTYPE;

/**
 *	@brief	EMV联机交易结果
 *	@param 	ONLINETRADERET_YES      联机交易成功
 *	@param 	ONLINETRADERET_NO       联机交易失败
 */
typedef enum {
    ONLINETRADERET_YES  = 0x01,
    ONLINETRADERET_NO   = 0x02,
}LDE_ONLINETRADERET;

/**
 *	@brief	EMV交易结果代码
 *	@param 	EMVTRADERETCODE_PERMISION       交易批准
 *	@param 	EMVTRADERETCODE_REJECT          交易拒绝
 *	@param 	EMVTRADERETCODE_REQONLINE       请求联机
 *	@param 	EMVTRADERETCODE_CONTINUE        交易继续
 *	@param 	EMVTRADERETCODE_QPBOC_FULL      QPBOC消费流水已经满
 *	@param 	EMVTRADERETCODE_FALLBACK        FALLBACK
 *	@param 	EMVTRADERETCODE_EXCEPTION       EMV处理异常
 */
typedef enum {
    EMVTRADERETCODE_PERMISION   = 0x00,
    EMVTRADERETCODE_REJECT      = 0x01,
    EMVTRADERETCODE_REQONLINE   = 0x02,
    EMVTRADERETCODE_CONTINUE    = 0xA0,
    EMVTRADERETCODE_QPBOC_FULL  = 0xFD,
    EMVTRADERETCODE_FALLBACK    = 0xFE,
    EMVTRADERETCODE_EXCEPTION   = 0xFF,
}LDE_EMVTRADERETCODE;

/**
 *	@brief	持卡人认证方式
 *	@param 	CERTIFYTYPE_ONLINE_PIN          联机PIN
 *	@param 	CERTIFYTYPE_OFFLINE_PIN         脱机PIN
 *	@param 	CERTIFYTYPE_CREDENCE            证件验证
 */
typedef enum {
    CERTIFYTYPE_ONLINE_PIN  = 0x01,
    CERTIFYTYPE_OFFLINE_PIN = 0x02,
    CERTIFYTYPE_CREDENCE    = 0x05,
}LDE_CERTIFYTYPE;

/**
 *	@brief	支持的卡种
 *	@param 	SUPPORTCARDTYPE_MAG         支持磁条卡
 *	@param 	SUPPORTCARDTYPE_IC          支持IC卡
 *	@param 	SUPPORTCARDTYPE_RF          非接卡
 */
typedef enum {
    SUPPORTCARDTYPE_MAG         = 0x01,
    SUPPORTCARDTYPE_IC          = 0x02,
    SUPPORTCARDTYPE_RF          = 0x04,
    SUPPORTCARDTYPE_IC_RF       = SUPPORTCARDTYPE_IC|SUPPORTCARDTYPE_RF,
    SUPPORTCARDTYPE_MAG_IC      = SUPPORTCARDTYPE_MAG|SUPPORTCARDTYPE_IC,
    SUPPORTCARDTYPE_MAG_IC_RF   = SUPPORTCARDTYPE_MAG|SUPPORTCARDTYPE_IC|SUPPORTCARDTYPE_RF
}LDE_SUPPORTCARDTYPE;

/**
 *	@brief	AID类型
 *	@param 	AIDTYPE_TOUCH       接触式AID
 *	@param 	AIDTYPE_NOTOUCH     非接触AID
 *	@param 	AIDTYPE_ALL         全部
 */
typedef enum {
    AIDTYPE_TOUCH   = 0x00,
    AIDTYPE_NOTOUCH = 0x01,
    AIDTYPE_ALL     = 0x02,
}LDE_AIDTYPE;

/**
 *	@brief	清除屏幕的标志
 *	@param 	CLEARFLAG_NO    不清空屏幕
 *	@param 	CLEARFLAG_YES   晴空屏幕
 */
typedef enum {
    CLEARFLAG_NO    = 0x00,
    CLEARFLAG_YES   = 0x01,
}LDE_CLEARFLAG;

/**
 *	@brief	获取磁道数据类型
 *	@param 	TRACKTYPE_PLAIN     明文
 *	@param 	TRACKTYPE_ENCRYPT   密文
*/
typedef enum {
    TRACKTYPE_PLAIN     = 0x00,
    TRACKTYPE_ENCRYPT   = 0x01,
}LDE_TRACKTYPE;

/**
 *	@brief	获取PAN数据类型
 *	@param 	PANDATATYPE_PLAIN     明文
 *	@param 	PANDATATYPE_ENCRYPT   密文
*/
typedef enum {
    PANDATATYPE_PLAIN     = 0x00,
    PANDATATYPE_ENCRYPT   = 0x01,
}LDE_PANDATATYPE;

/**
 *	@brief	刷卡、插卡返回的卡片类型
 *	@param 	CARDTYPE_MAGNETIC   磁条卡
 *	@param 	CARDTYPE_ICC        IC卡
 *	@param 	CARDTYPE_PENDING    冲正
 */
typedef enum {
    CARDTYPE_MAGNETIC   = 0x01,
    CARDTYPE_ICC        = 0x02,
    CARDTYPE_RF         = 0x04,
}LDE_CardType;

/**
 *	@brief	电池电量的等级
 *	@param 	BATTERYLEVEL_BAD            未知
 *	@param 	BATTERYLEVEL_NEEDCHARGE     需要充电
 *	@param 	BATTERYLEVEL_LOW            电量不足
 *	@param 	BATTERYLEVEL_NORMAL         电量正常
 *	@param 	BATTERYLEVEL_HIGH           电量高
 *	@param 	BATTERYLEVEL_FULL           电量满
 */
typedef enum {
    BATTERYLEVEL_BAD            = 0x00,
    BATTERYLEVEL_NEEDCHARGE     = 0x01,
    BATTERYLEVEL_LOW            = 0x02,
    BATTERYLEVEL_NORMAL         = 0x03,
    BATTERYLEVEL_HIGH           = 0x04,
    BATTERYLEVEL_FULL           = 0x05,
}LDE_BatteryLevel;

/**
 *	@brief	显示文字的格式
 *	@param 	DISPLAYSTYLE_CENTER     居中显示
 *	@param 	DISPLAYSTYLE_LEFT       左对齐
 *	@param 	DISPLAYSTYLE_RIGHT      右对齐
 */
typedef enum {
    DISPLAYSTYLE_CENTER     = 0x00,
    DISPLAYSTYLE_LEFT       = 0x01,
    DISPLAYSTYLE_RIGHT      = 0x02,
}LDE_DISPLAYSTYLE;

/**
 *	@brief	显示文字的格式
 *	@param 	PRINTERSTATUS_NORMAL     正常
 *	@param 	PRINTERSTATUS_NOPAPER    缺纸
 *	@param 	PRINTERSTATUS_BUSY       打印机忙
 *	@param 	PRINTERSTATUS_NORESPON   打印机无响应
 *	@param 	PRINTERSTATUS_ELSEERR    未知错误
 */
typedef enum {
    PRINTERSTATUS_NORMAL        = 0x00,
    PRINTERSTATUS_NOPAPER       = 0x01,
    PRINTERSTATUS_BUSY          = 0x02,
    PRINTERSTATUS_NORESPON      = 0x03,
    PRINTERSTATUS_ELSEERR       = 0x04,
}LDE_PrinterStatus;

/**
 *	@brief	汉字格式
 *	@param 	PrinterFormateHZ_16X16  16*16点阵
 *	@param 	PrinterFormateHZ_24X24  24*24点阵
 */
typedef enum {
    PrinterFormateHZ_16X16 = 0x00,
    PrinterFormateHZ_24X24 = 0x01,
}LDE_PrinterFormateHZ;

/**
 *	@brief	西文格式
 *	@param 	PrinterFormateXW_5X7    5*7点阵
 *	@param 	PrinterFormateXW_7X7    7*7点阵
 *	@param 	PrinterFormateXW_16X18  16*18点阵
 *	@param 	PrinterFormateXW_24X12  24*12点阵
*/
typedef enum {
    PrinterFormateXW_5X7    = 0x00,
    PrinterFormateXW_7X7    = 0x01,
    PrinterFormateXW_16X18  = 0x02,
    PrinterFormateXW_24X12  = 0x03,
}LDE_PrinterFormateXW;

/**
 *	@brief	蓝牙打开返回码描述
 *	@param 	BLEOPENRET_SUCCESS               表示成功
 *	@param 	BLEOPENRETPAR_INVAL              表示参数无效
 *	@param 	BLEOPENRETCONNECT_BLEERR         表示建立蓝牙连接发生错误
 *	@param 	BLEOPENRETNOT_SUPPORT_BLE        表示当前设备不支持BLE
 *	@param 	BLEOPENRETNO_OPEN_BLE            表示当前设备未开启蓝牙
 *	@param 	BLEOPENRETUNKNOWN_ERR            表示发生了不可预料的错误
 */
typedef enum{
    BLEOPENRET_SUCCESS           = 0,
    BLEOPENRETPAR_INVAL          = -1,
    BLEOPENRETCONNECT_BLEERR     = -2,
    BLEOPENRETNOT_SUPPORT_BLE    = -4,
    BLEOPENRETNO_OPEN_BLE        = -5,
    BLEOPENRETUNKNOWN_ERR        = -6,
}LDE_BLEOPENRET;

/**
 *	@brief	音频打开返回码描述
 *	@param 	AUDIOOPENRET_SUCCESS                    表示成功
 *	@param 	AUDIOOPENRET_INIT_PLAY_REC_FAIL         表示初始化播放资源失败
 *	@param 	AUDIOOPENRET_INIT_RECODE_REC_FAIL       表示初始化录音资源失败
 *	@param 	AUDIOOPENRET_CONNECT_FAIL               表示通信失败，可能是唤醒失败或者与设备端的数据交互错误
 *	@param 	AUDIOOPENRET_NO_DEVICE                  表示未检测到可通信的设备，通常由于音频口未接入设备造成
 */
typedef enum{
    AUDIOOPENRET_SUCCESS                = 0,
    AUDIOOPENRET_INIT_PLAY_REC_FAIL     = -1,
    AUDIOOPENRET_INIT_RECODE_REC_FAIL   = -2,
    AUDIOOPENRET_CONNECT_FAIL           = -3,
    AUDIOOPENRET_NO_DEVICE              = -4,
} LDE_AUDIOOPENRET;

/**
 *	@brief	交易类型
 *	@param 	TRADETYPE_PURCHASE    消费
 *	@param 	TRADETYPE_REVOKE      消费撤销
 *	@param 	TRADETYPE_QUERY       查余额
 *	@param 	TRADETYPE_TRANSFER    转账
 */
typedef enum{
    TRADETYPE_PURCHASE      = 0x00,
    TRADETYPE_REVOKE        = 0x20,
    TRADETYPE_QUERY         = 0x30,
    TRADETYPE_TRANSFER      = 0x40,
} LDE_TradeType;



#pragma mark - COMMON_PAREMETE
/**
 *	@brief	发送数据的默认超时（单位：秒）
 */
static const NSUInteger DEVICE_EXCHANGE_DATA_TIMEOUT_DEF = 60;

#pragma mark - ERRCODE&ERRINFO
static NSInteger RETURN_NODATA_CODE             = 10000;
static NSInteger RETURN_PARASERERR_CODE         = 10001;
static NSInteger RETURN_EXCHANGETIMEOUT_CODE    = 10002;
static NSInteger RETURN_EXCHANGEFAILED_CODE     = 10003;
static NSInteger ERRCODE_TIMEOUT                = 10004;
static NSInteger ERRCODE_MESSAGEERR             = 10005;
static NSInteger ERR_INPUTPARAMETE              = 10006;
static NSInteger ERR_CANCELCMD                  = 10007;
static NSInteger ERR_EMVPROCESS                 = 10008;

static NSString* RETURN_NODATA_MESSAGE          = @"返回数据为空";
static NSString* RETURN_PARASERERR_MESSAGE      = @"解析指令错误";
static NSString* RETURN_MESSAGEERR_MESSAGE      = @"报文错误返回，详见报文错误列表！";
static NSString* RETURN_EXCHANGETIMEOUT_MESSAGE = @"从设备接收数据超时";
static NSString* RETURN_EXCHANGEFAILED_MESSAGE  = @"数据发送失败";
static NSString* MESSAGE_ERR_INPUTPARAMETE      = @"输入参数有误！";

#pragma mark - CLASS_DEFINE
/**
 *	@brief	AID信息
 *	@param 	aidType         AID类型
 *	@param 	aidVersion      AID参数版本
 *	@param 	aid             AID
 *	@param 	asi             应用选择标识符
 *	@param 	appVer          应用版本号
 *	@param 	TACDefault      TAC缺省
 *	@param 	TACOnline       TAC联机
 *	@param 	TACDenial       TAC拒绝
 *	@param 	floorLmt        终端最低限额
 *	@param 	randomLmt       随机选择阈值
 *	@param 	randomPerMax    随机选择的最大目标百分数
 *	@param 	randomPer       随机选择的目标百分数
 *	@param 	DDOL            缺省DDOL
 */
@interface LDC_AID : NSObject
@property (nonatomic) LDE_AIDTYPE aidType;
@property (nonatomic,copy) NSString *aidVersion;
@property (nonatomic,copy) NSString *aid;
@property (nonatomic) Byte asi;
@property (nonatomic,copy) NSString *appVer;
@property (nonatomic,copy) NSString *TACDefault;
@property (nonatomic,copy) NSString *TACOnline;
@property (nonatomic,copy) NSString *TACDenial;
@property (nonatomic,copy) NSString *floorLmt;
@property (nonatomic,copy) NSString *randomLmt;
@property (nonatomic) Byte randomPerMax;
@property (nonatomic) Byte randomPer;
@property (nonatomic,copy) NSString *DDOL;
@end

/**
 *	@brief	公钥信息
 *	@param 	pubKeyType      公钥类型
 *	@param 	pubKeyIndex     公钥索引
 *	@param 	rid             注册应用提供商（长度5位）
 *	@param 	expireDate      公钥失效日期，YYYYMMDD
 *	@param 	mod             CA公钥模
 *	@param 	exp             CA公钥指数
 *	@param 	hash            CA公钥校验值
 *	@param 	publicVersion   公钥版本
 */
@interface LDC_PublickKey : NSObject
@property (nonatomic) LDE_PKEYTYPE pubKeyType;
@property (nonatomic) Byte pubKeyIndex;
@property (nonatomic,copy) NSString *rid;
@property (nonatomic,copy) NSString *expireDate;
@property (nonatomic,copy) NSString *mod;
@property (nonatomic,copy) NSString *exp;
@property (nonatomic,copy) NSString *hash;
@property (nonatomic,copy) NSString *publicVersion;
@end

/**
 *	@brief	设备基础信息
 *	@param 	deviceIndentifier       识别号
 *	@param 	deviceName              设备名
 *	@param 	deviceChannel           通讯类型
 */
@interface LDC_DEVICEBASEINFO : NSObject
@property (nonatomic,copy) NSString* deviceIndentifier;
@property (nonatomic,copy) NSString* deviceName;
@property (nonatomic) LDE_CHANNEL  deviceChannel;
@end

/**
 *	@brief	磁道数据
 *	@param 	isCipher   是否加密
 *	@param 	track1     1磁道数据
 *	@param 	track2     2磁道数据
 *	@param 	track3     3磁道数据
 */
@interface LDC_TrackDataInfo :NSObject
@property (nonatomic) BOOL isCipher;
@property (nonatomic, copy)NSString* track1;
@property (nonatomic, copy)NSString* track2;
@property (nonatomic, copy)NSString* track3;
-(id)initWithData:(NSData*)data;
-(id)initWithClearData:(NSData*)data;
@end

/**
 *	@brief	主密钥获取数据
 *	@param 	hasMasterKey   是否已加载主密钥
 *	@param 	masterKeyIndex 主密钥索引
 */
@interface LDC_MasterKey :NSObject
@property (nonatomic) BOOL hasMasterKey;
@property (nonatomic) Byte masterKeyIndex;
@end

/**
 *	@brief	EMV交易完成数据
 *	@param 	responseCode  授权响应码, 联机完成时此域必须存在
 *	@param 	authCode      授权码, 可选存在
 *	@param 	cardIden      发卡行认证
 *	@param 	script71      71脚本
 *	@param 	script72      72脚本
 */
@interface LDC_EMVTradeComplete : NSObject
@property (nonatomic,copy) NSString *responseCode;
@property (nonatomic,copy) NSString *authCode;
@property (nonatomic,copy) NSString *cardIden;
@property (nonatomic,copy) NSString *script71;
@property (nonatomic,copy) NSString *script72;
@end

/**
 *	@brief	设备信息
 *	@param 	deviceType      硬件产品类别
 *	@param 	deviceModel     硬件产品型号
 *	@param 	productSN       产品SN
  *	@param 	custormerSN     客户自定义SN
 *	@param 	pinpadSN        pinpad序列号
 *	@param 	bootSoftVer     BOOT版本
 *	@param 	ctrlSoftVer     CTRL版本
 *	@param 	userSoftVer     USER版本
 *	@param 	fileSysVer      FILESYS版本
 *	@param 	hardwareVer     硬件版本
 *	@param 	hardwareSN      硬件序列号
 *	@param 	AIDParamVersion AID参数版本号
 *	@param 	publicKeyVer    公钥版本
 *	@param 	powerPercent     电池百分比
 *	@param 	ESSSFlag        电子签名存储空间标识
 *	@param 	SKeyDownFlag    MPOS密钥下装标志
 */
@interface LDC_DeviceInfo :NSObject
@property (nonatomic, copy)NSString *deviceType;
@property (nonatomic, copy)NSString *deviceModel;
@property (nonatomic, copy)NSString *productSN;
@property (nonatomic, copy)NSString *custormerSN;
@property (nonatomic, copy)NSString *pinpadSN;
@property (nonatomic, copy)NSString *bootSoftVer;
@property (nonatomic, copy)NSString *ctrlSoftVer;
@property (nonatomic, copy)NSString *userSoftVer;
@property (nonatomic, copy)NSString *fileSysVer;
@property (nonatomic, copy)NSString *hardwareVer;
@property (nonatomic, copy)NSString *hardwareSN;
@property (nonatomic, copy)NSString *AIDParamVersion;
@property (nonatomic, copy)NSString *publicKeyVer;
@property (nonatomic)int powerPercent;
@property (nonatomic)Byte ESSSFlag;
@property (nonatomic)Byte SKeyDownFlag;
-(id)initWithData:(NSData*)data;
@end

/**
 *	@brief	EMV开始交易结果
 *	@param 	AIDArray        AID候选列表
 *	@param 	result          EMV处理结果
 */
@interface LDC_EMVStartResult : NSObject
@property (nonatomic,copy) NSMutableArray *AIDArray;
@property (nonatomic,assign) LDE_EMVTRADERETCODE result;
-(id)initWithData:(NSData*)data;
@end

/**
 *	@brief	EMV交易处理返回数据
 *	@param 	type       持卡人认证方式
 *	@param 	track2data  二磁道等价数据
 *	@param 	cardExpired 卡片有效期
 *	@param 	panSerialNO IC卡序列号
 *	@param 	pan        IC卡卡号
 *	@param 	cardType   证件类型（证件验证时存在）
 *	@param 	cardNum    证件号码（证件验证时存在）
 *	@param 	result     EMV处理结果(
 */
@interface LDC_EMVProgress : NSObject
@property (nonatomic) LDE_CERTIFYTYPE type;
@property (nonatomic,copy) NSString *track2data;
@property (nonatomic,copy) NSString *cardExpired;
@property (nonatomic,copy) NSString *panSerialNO;
@property (nonatomic,copy) NSString *pan;
@property (nonatomic,copy) NSString *cardType;
@property (nonatomic,copy) NSString *cardNum;
@property (nonatomic,copy) NSString *cardHolderName;
@property (nonatomic,assign) LDE_EMVTRADERETCODE result;
-(id)initWithData:(NSData*)data;
@end

/**
 *	@brief	QPOBC读取流水
 *	@param 	result     EMV处理结果(
 */
@interface LDC_QPOBCReadRecord : NSObject
@property (nonatomic,copy) NSData* record;
@property (nonatomic,copy) NSString* amount;
@property (nonatomic,copy) NSString* pan;
@property (nonatomic,copy) NSString* panSn;
@property (nonatomic,copy) NSString* time;
@property (nonatomic,copy) NSString* date;
-(id)initWithData:(NSData*)data;
@end

/**
 *	@brief	EMV交易处理返回数据
 *	@param 	type       持卡人认证方式
 *	@param 	pan        IC卡卡号
 *	@param 	cardType   证件类型（证件验证时存在）
 *	@param 	cardNum    证件号码（证件验证时存在）
 *	@param 	result     EMV处理结果(
 */
@interface LDC_EMVResult : NSObject
@property (nonatomic) LDE_EMVTRADERETCODE result;
@property (nonatomic, copy) NSString* dol;
-(id)initWithData:(NSData*)data;
@end

/**
 *	@brief	终端参数信息
 *	@param 	merchantNO   商户号
 *	@param 	merchantName 商户名称
 *	@param 	terminalNO   终端号
 *	@param 	serialNO     流水号
 *	@param 	bathcNO      批次号
 *	@param 	customParam  自定义数据区
 */
@interface LDC_TerminalBasePara : NSObject
@property (nonatomic,copy) NSString* merchantNO,*merchantName,*terminalNO,*serialNO,*bathcNO,*customParam;
-(id)initWithData:(NSData*)data;
@end

/**
 *	@brief	EMV交易信息
 *	@param 	code        要禁用的卡种
 *	@param 	flag        强制联机标识
 *	@param 	type        交易类型
 *	@param 	amount      授权金额
 *	@param 	otherAmount 其它金额
 *	@param 	date        交易日期
 *	@param 	time        交易时间
 */
@interface LDC_EMVTradeInfo : NSObject
@property (nonatomic) LDE_FORBIDECARDTYPE code;
@property (nonatomic) LDE_FORCEONLINE flag;
@property (nonatomic) LDE_TradeType type;
@property (nonatomic) LDULongLong amount;
@property (nonatomic) LDULongLong otherAmount;
@property (nonatomic,copy) NSString* date;
@property (nonatomic,copy) NSString* time;
@end

/**
 *	@brief	读取磁道信息传入的数据
 *	@param 	trackDT     磁道数据类型
 *	@param 	code        厂商代码
 *	@param 	random      加密随机数
 *	@param 	TKIndex     磁道密钥索引
 *	@param 	timeout     刷卡超时（单位：秒）
 *	@param 	panSF       PAN缓存标识
 */
@interface LDC_TrackInfo : NSObject
@property (nonatomic) LDE_TRACKTYPE trackDT;
@property (nonatomic) LDE_MANUFACTURERCODE mfCode;
@property (nonatomic, copy) NSString* random;
@property (nonatomic) Byte tkIndex;
@property (nonatomic) Byte timeout;
@end

/**
 *	@brief	导入密钥的信息
 *	@param 	type    密钥类型
 *	@param 	index   主密钥索引
 *	@param 	ID      密钥ID
 *	@param 	key     密钥数据
 */
@interface LDC_LoadKey : NSObject
@property (nonatomic) LDE_KEYTYPE keyType;
@property (nonatomic) Byte mKeyIndex;
@property (nonatomic) Byte keyIndex;
@property (nonatomic, copy) NSString* keyData;
@property (nonatomic, copy) NSString* checkKey;
@end

/**
 *	@brief	MAC计算
 *	@param 	mfCode      厂商编码
 *	@param 	macBlock    由原始MAC输入数据计算出的8字节MAC BLOCK（8字节）
 *	@param 	macData     需要计算MAC的原始数据
 *	@param 	random      加密随机数（盛付通：随机数为8字节 其他厂商：未使用）
 *	@param 	macKeyIndex MAC密钥索引
 */
@interface LDC_CalculateMAC : NSObject
@property (nonatomic)  LDE_MANUFACTURERCODE mfCcode;
@property (nonatomic, copy)  NSString* macBlock;
@property (nonatomic, copy)  NSString* macData;
@property (nonatomic, copy)  NSString* random;
@property (nonatomic) Byte macKeyIndex;
@end

/**
 *	@brief	读取PIN密文输入数据
 *	@param 	mfCode      厂商编码
 *	@param 	panBlock    ANSI X9.8 Format PAN Block，固定8字节
 *	@param 	amount      交易金额（6字节）
 *	@param 	random      加密随机数（盛付通：随机数为8字节 其他厂商：未使用）
 *	@param 	pinKeyIndex PIN密钥索引
 *	@param 	timeout     PIN输入超时时间（单位：秒）
 */
@interface LDC_GETPIN : NSObject
@property (nonatomic) LDE_MANUFACTURERCODE mfCode;
@property (nonatomic, copy) NSString* panBlock;
@property (nonatomic) LDULongLong amount;
@property (nonatomic, copy) NSString* random;
@property (nonatomic) Byte pinKeyIndex;
@property (nonatomic) OneByeInt timeout;
@end

@interface LFC_EMVResult : NSObject
@property (nonatomic) LDE_EMVTRADERETCODE result;
@property (nonatomic,copy)  NSData* password;
@property (nonatomic,copy)  NSString* dol;
@end

/**
 *	@brief	导入密钥的信息
 *	@param 	type    密钥类型
 *	@param 	key     密钥数据
 */
@interface LFC_LoadKey : NSObject
@property (nonatomic) LDE_KEYTYPE keyType;
@property (nonatomic, copy) NSString* keyData;
@end

/**
 *	@brief	读取PIN密文输入数据
 *	@param 	panBlock    卡号
 *	@param 	amount      交易金额（6字节）
 *	@param 	timeout     PIN输入超时时间（单位：秒）
 */
@interface LFC_GETPIN : NSObject
@property (nonatomic, copy) NSString* panBlock;
@property (nonatomic, copy) NSString* moneyNum;
@property (nonatomic) OneByeInt timeout;
@end

/**
 *	@brief	EMV交易信息
 *	@param 	flag        强制联机标识
 *	@param 	type        交易类型
 *	@param 	moneyNum    授权金额
 *	@param 	date        交易日期
 *	@param 	time        交易时间
 */
@interface LFC_EMVTradeInfo : NSObject
@property (nonatomic) LDE_FORCEONLINE flag;
@property (nonatomic) LDE_TradeType type;
@property (nonatomic,copy) NSString* moneyNum;
@property (nonatomic,copy) NSString* date;
@property (nonatomic,copy) NSString* time;
@end

/**
 *	@brief	EMV交易处理返回数据
 *	@param 	track2data  二磁道等价数据
 *	@param 	cardExpired 卡片有效期
 *	@param 	panSerialNO IC卡序列号
 *	@param 	pan        IC卡卡号
 */
@interface LFC_EMVProgress : NSObject
@property (nonatomic,copy) NSString *track2data;
@property (nonatomic,copy) NSString *cardExpired;
@property (nonatomic,copy) NSString *panSerialNO;
@property (nonatomic,copy) NSString *pan;
@property (nonatomic,copy) NSString *cardHolderName;
@end

/**
 *	@brief	EMV交易完成数据
 *	@param 	responseCode  授权响应码, 联机完成时此域必须存在，即39域数据
 *	@param 	onlineData    联机请求返回数据，即55域数据
 */
@interface LFC_EMVOnlineData : NSObject
@property (nonatomic,copy) NSString *responseCode;
@property (nonatomic,copy) NSString *onlineData;
@end

/**
 *	@brief	查询到一个设备的成功block
 *
 *	@param 	 	查询到的设备信息
 */
typedef void (^onSearchOneDeviceCB)(LDC_DEVICEBASEINFO *deviceInfo);

/**
 *	@brief	查询设备完成的block
 *
 *	@param 	 	设备信息列表
 */
typedef void (^onSearchCompleteCB)(NSMutableArray *deviceArray);

/**
 *	@brief	打开设备失败block
 *
 *	@param 	 	void
 */
typedef void (^onErrorCB)(NSString* errCode,NSString* errInfo);

/**
 *	@brief	返回BOOL值的成功返回
 *
 *	@param 	 	返回的结果BOOL类型值
 */
typedef void (^onBOOLCB)(BOOL isSuccess);

/**
 *	@brief	返回NSString值的成功返回
 *
 *	@param 	返回接口的NSString类型值
 */
typedef void (^onNSStringCB)(NSString* stringCB);

/**
 *	@brief	获取设备信息的成功返回
 *
 *	@param 	 	设备信息
 */
typedef void (^onGetDeviceCB)(LDC_DeviceInfo* deviceInfo);

/**
 *	@brief	返回NSData值的成功返回
 *
 *	@param 	返回接口的NSData类型值
 */
typedef void (^onNSDataCB)(NSData* dateCB);

/**
 *	@brief	等待插卡、刷卡的成功返回
 *
 *	@param 	 	刷卡的类型
 */
typedef void (^onLDE_CardTypeCB)(LDE_CardType cardtype);

typedef void (^onLDE_PrinterStatusCB)(LDE_PrinterStatus printerStatues);

/**
 *	@brief	查询设备电量的成功返回
 *
 *	@param 	 	电池当前的电量等级
 */
typedef void (^onLDE_BatteryLevelCB)(LDE_BatteryLevel batteryLevel);

/**
 *	@brief	查询主密钥的成功返回
 *
 *	@param 	 	返回的主密钥的值
 */
typedef void (^onQueryMKeyCB)(LDC_MasterKey* keyData);

/**
 *	@brief	查询磁道信息的成功返回
 *
 *	@param 	 	查询到的磁道信息
 */
typedef void (^onQueryTrackCB)(LDC_TrackDataInfo* trackData);

/**
 *	@brief	EMV交易处理的成功返回
 *
 *	@param 	 	返回的处理结果
 */
typedef void (^onEMVProcessCB)(LDC_EMVProgress* emvProgress);

/**
 *	@brief	EMV开始交易的成功返回
 *
 *	@param 	 	开始交易的返回结果
 */
typedef void (^onEMVStartAppCB)(LDC_EMVStartResult* emvResult);

/**
 *	@brief	EMV交易处理的成功返回
 *
 *	@param 	 	EMV交易处理的结果
 */
typedef void (^onEMVTradeResultCB)(LDC_EMVResult* emvResult);

/**
 *	@brief	QPBOC交易处理的成功返回
 *
 *	@param 	 	QPBOC交易处理的结果
 */
typedef void (^onQPBOCReadRecord)(LDC_QPOBCReadRecord* qpbocRecord);

/**
 *	@brief	无参数的回调
 *
 *	@param 	void
 */
typedef void (^onVoidCB)();

/**
 *	@brief	终端基本参数的回调
 *
 *	@param 	void
 */
typedef void (^onLDC_TerminalBaseParaCB)(LDC_TerminalBasePara* terminalPara);

/**
 *	@brief	下载固件进程中
 *
 *	@param 	 	current:当前流程值
 *	@param 	 	total:总共的流程值
 */
typedef void (^onDownloadProcessCB)(unsigned int current,unsigned int total);

/**
 *	@brief	下载固件失败
 *
 *	@param 	 	code:下载固件的错误码
 */
typedef void (^onDownloadErrCB)(int code);

typedef void (^onGetBNSNCB)(NSString* batchNO,NSString*serialNO);

typedef void (^onLFEMVStartCB)(LFC_EMVResult* emvResult);

typedef void (^onLFEMVProgressCB)(LFC_EMVProgress* emvProgress);

typedef void (^onConfirmCB)(BOOL inputConfirm,BOOL inputCancel);

typedef void (^onGetUserInputDataBlock)(NSString *data);

/**
 *	@brief	打印在哪一联
 *	@param 	PRINTPOSITION_ALL           所有联
 *	@param 	PRINTPOSITION_PAGE1         第一联
 *	@param 	PRINTPOSITION_PAGE1         第二联
 *	@param 	PRINTPOSITION_PAGE1         第三联
 *	@param 	PRINTPOSITION_PAGE1         第四联
 */
typedef enum {
    PRINTPOSITION_ALL       = 0x00,
    PRINTPOSITION_PAGE1     = 0x01,
    PRINTPOSITION_PAGE2     = 0x02,
    PRINTPOSITION_PAGE3     = 0x03,
    PRINTPOSITION_PAGE4     = 0x04,
}LDE_PRINTPOSITION;

/**
 *	@brief	打印位置
 *	@param 	PRINTALIGN_MID              居中
 *	@param 	PRINTALIGN_LEFT             左对齐
 *	@param 	PRINTALIGN_RIGHT            右对齐
 */
typedef enum {
    PRINTALIGN_MID      = 0x00,
    PRINTALIGN_LEFT     = 0x01,
    PRINTALIGN_RIGHT    = 0x02,
}LDE_PRINTALIGN;

/**
 *	@brief	打印类型
 *	@param 	PRINTTYPE_TEXT               普通文本
 *	@param 	PRINTTYPE_QRCODE             二维码
 *  @param 	PRINTTYPE_SINGE             电子签名
 */
typedef enum {
    PRINTTYPE_TEXT      = 0x00,
    PRINTTYPE_QRCODE    = 0x01,
    PRINTTYPE_SINGE     = 0x02,
}LDE_PRINTTYPE;

/**
 *	@brief	文本放大
 *	@param 	PRINTZOOM_NORMAL            正常字体
 *	@param 	PRINTZOOM_2                 二倍
 *	@param 	PRINTZOOM_3                 三倍
 */
typedef enum {
    PRINTZOOM_NORMAL   = 0x00,
    PRINTZOOM_2        = 0x01,
    PRINTZOOM_3        = 0x02,
}LDE_PRINTZOOM;

/**
 *	@brief	打印一行的格式数据
 *	@param 	position        打印在哪一联
 *	@param 	ailg            对齐方式
 *	@param 	type            文本，二维码
 *	@param 	zoom            放大几倍
 *	@param 	text            打印内容
 */
@interface LDC_PrintLineStu : NSObject
@property (nonatomic) LDE_PRINTPOSITION position;
@property (nonatomic) LDE_PRINTALIGN ailg;
@property (nonatomic) LDE_PRINTTYPE type;
@property (nonatomic) LDE_PRINTZOOM zoom;
@property (nonatomic) NSString* text;
@end
