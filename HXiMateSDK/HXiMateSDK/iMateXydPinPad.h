//
//  iMatePinPad.h
//  支持信雅达Pinpad
//
//  Created by hxsmart on 13-8-8.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iMateAppFace.h"
#import "iMateData.h"
#import "EADSessionController.h"

#define DECRYPT_KEY_MODE        0
#define ENCRYPT_KEY_MODE        1
#define PIN_KEY_MODE            2

@interface iMateXydPinPad : NSObject

// 获取iMatePinPad实例
+(iMateXydPinPad *)imatePinPad:(EADSessionController *)iMateEADSessionController;

/**
* Pinpad上电 (通讯波特率为9600 校验方式 0）
*/
-(void)powerOn;

/**
 * Pinpad下电
 */
-(void)powerOff;

/**
 * Pinpad复位自检
 * @param   initFlag 	YES清除Pinpad中的密钥，NO不清除密钥
 */
-(void)reset:(BOOL)initFlag;

/**
 * 获取Pinpad的版本号信息
 */
-(void)pinpadVersion;

/**
 * 取消Pinpad操作
 */
-(void)cancel;

/**
 * Pinpad下装主密钥
 * is3des		是否采用3DES算法，false表示使用DES算法
 * @param   index		主密钥索引
 * @param   mastKey		主密钥
 * @param   keyLength	主密钥长度
 */
-(void)downloadMasterKey:(int)is3des index:(int)index masterKey:(Byte *)masterKey keyLength:(int)length;

/**
 * Pinpad下装工作密钥(主密钥加密）
 * is3des			是否采用3DES算法，false表示使用DES算法
 * @param   masterIndex		主密钥索引
 * @param   workingIndex	工作密钥索引
 * @param   workingKey		工作密钥
 * @param   keyLength		工作密钥长度
 */
-(void)downloadWorkingKey:(int)is3des masterIndex:(int)masterIndex workingIndex:(int)workingIndex workingKey:(Byte *)workingKey keyLength:(int)keyLength;

/**
 * Pinpad输入密码（PinBlock）
 * is3des			是否采用3DES算法，false表示使用DES算法
 * isAutoReturn	输入到约定长度时是否自动返回（不需要按Enter)
 * @param   masterIndex		主密钥索引
 * @param   workingIndex	工作密钥索引
 * @param   cardNo			卡号/帐号（最少12位数字）
 * @param   pinLength		需要输入PIN的长度
 * @param   timeout			输入密码等待超时时间 <= 255 秒
 */
-(void)inputPinblock:(int)is3des isAutoReturn:(BOOL)isAutoReturn masterIndex:(int)masterIndex workingIndex:(int)workingIndex cardNo:(NSString *)cardNo pinLength:(int)pinLength timeout:(int)timeout;

/**
 * Pinpad加解密数据
 * is3des			是否采用3DES算法，false表示使用DES算法
 * algo			算法，取值: ALGO_ENCRYPT, ALGO_DECRYPT, 以ECB方式进行加解密运算
 * @param   masterIndex		主密钥索引
 * @param   workingIndex	工作密钥索引，如果工作密钥索引取值-1，使用主密钥索引指定的主密钥进行加解密
 * @param   data			加解密数据
 * @param   dataLength		加解密数据的长度,要求8的倍数并小于或等于248字节长度
 */
-(void)encrypt:(int)is3des algo:(int)algo masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength;

/**
 * Pinpad数据MAC运算（ANSIX9.9）
 * is3des			是否采用3DES算法，false表示使用DES算法
 * @param   masterIndex		主密钥索引
 * @param   workingIndex	工作密钥索引，如果工作密钥索引取值-1，使用主密钥索引指定的主密钥进行加解密
 * @param   data			计算Mac原数据
 * @param   dataLength		Mac原数据的长度,要求8的倍数并小于或等于246字节长度
 */
-(void)mac:(int)is3des masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength;


/**
 * 设置密码键盘参数
 * key 	:	参数名称
 * 			"AuthCode"	:   认证密钥, 16字节长度, 缺省值为16个0x00
 * 			"UID"		:	Pinpad UID, 长度为16字节，缺省值为
 *                             {'1','2','3','4','5','6','7','8','9','0','1','2','3','4','5'}
 * 			"WorkDirNum	:	子目录编号, 缺省值为0x01，长度为一个字节;
 */
-(void)pinpadSetup:(NSString *)key value:(Byte *)value;

/**
 * 设置密钥类型， 用于下载masterkey或workingkey之前调用
 * @param	mode		主密钥类型包括 :
 * 					DECRYPT_KEY_MODE, ENCRYPT_KEY_MODE, PIN_KEY_MODE
 */
-(void)setKeyMode:(int)mode;


//获取设备序列号
-(void)pinPadGetProductSN;
@end
