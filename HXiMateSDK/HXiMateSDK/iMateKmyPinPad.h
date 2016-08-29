//
//  iMatePinPad.h
//  支持凯明扬Pinpad
//
//  Created by hxsmart on 13-8-8.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iMateAppFace.h"
#import "iMateData.h"
#import "EADSessionController.h"

@interface iMateKmyPinPad : NSObject

// 获取iMatePinPad实例
+(iMateKmyPinPad *)imatePinPad:(EADSessionController *)iMateEADSessionController;

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
 * @param   algorithm   算法，0：DES，1：3DES，2：SM4
 * @param   index		主密钥索引
 * @param   mastKey		主密钥
 * @param   keyLength	主密钥长度
 */
-(void)downloadMasterKey:(int)algorithm index:(int)index masterKey:(Byte *)masterKey keyLength:(int)length;

/**
 * Pinpad下装工作密钥(主密钥加密）
 * @param   algorithm       算法，0：DES，1：3DES，2：SM4
 * @param   masterIndex		主密钥索引
 * @param   workingIndex	工作密钥索引
 * @param   workingKey		工作密钥
 * @param   keyLength		工作密钥长度
 */
-(void)downloadWorkingKey:(int)algorithm masterIndex:(int)masterIndex workingIndex:(int)workingIndex workingKey:(Byte *)workingKey keyLength:(int)keyLength;

/**
 * Pinpad输入密码（PinBlock）
 * @param   algorithm       算法，0：DES，1：3DES，2：SM4
 * @param   isAutoReturn	输入到约定长度时是否自动返回（不需要按Enter)
 * @param   masterIndex		主密钥索引
 * @param   workingIndex	工作密钥索引
 * @param   cardNo			卡号/帐号（最少12位数字）
 * @param   pinLength		需要输入PIN的长度
 * @param   timeout			输入密码等待超时时间 <= 255 秒
 */
-(void)inputPinblock:(int)algorithm isAutoReturn:(BOOL)isAutoReturn masterIndex:(int)masterIndex workingIndex:(int)workingIndex cardNo:(NSString *)cardNo pinLength:(int)pinLength timeout:(int)timeout;

/**
 * Pinpad加解密数据
 * @param   algorithm       算法，0：DES，1：3DES，2：SM4
 * @param   cryptoMode      加解密方式，取值: ALGO_ENCRYPT, ALGO_DECRYPT, 以ECB方式进行加解密运算
 * @param   masterIndex		主密钥索引
 * @param   workingIndex	工作密钥索引，如果工作密钥索引取值-1，使用主密钥索引指定的主密钥进行加解密
 * @param   data			加解密数据
 * @param   dataLength		加解密数据的长度,要求8的倍数并小于或等于248字节长度
 */
-(void)encrypt:(int)algorithm cryptoMode:(int)cryptoMode masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength;

/**
 * Pinpad数据MAC运算（ANSIX9.9）
 * @param   algorithm       算法，0：DES，1：3DES，2：SM4
 * @param   masterIndex		主密钥索引
 * @param   workingIndex	工作密钥索引，如果工作密钥索引取值-1，使用主密钥索引指定的主密钥进行加解密
 * @param   data			计算Mac原数据
 * @param   dataLength		Mac原数据的长度,要求8的倍数并小于或等于246字节长度
 */
-(void)mac:(int)algorithm masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength;

// Pinpad计算数据散列值（散列结果，SHA1算法，长度为20字节，SM3长度为32字节）
// hashAlgorithm	散列算法，0：SHA1，1：SM3
// data			    计算Mac原数据
// dataLength		摘要原数据的长度
-(void)hash:(int)hashAlgorithm data:(Byte*)data dataLength:(int)dataLength;


//获取设备序列号
-(void)pinPadGetProductSN;

@end
