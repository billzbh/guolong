//
//  iMateKeyuPinPad.h
//  支持苏州银行定制Pinpad
//
//  Created by hxsmart on 13-8-8.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iMateAppFace.h"
#import "iMateData.h"
#import "EADSessionController.h"

@interface iMateSzbPinPad : NSObject

// 获取iMatePinPad实例
+(iMateSzbPinPad *)imatePinPad:(EADSessionController *)iMateEADSessionController;

/**
* Pinpad上电 (通讯波特率为9600 校验方式 0）
*/
-(void)powerOn;

/**
 * Pinpad下电
 */
-(void)powerOff;

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
 * is3des           是否采用3DES算法，false表示使用DES算法
 * masterIndex      主密钥索引
 * workingIndex     工作密钥索引
 * workingKey       工作密钥
 * keyLength        工作密钥长度
 */
-(void)downloadWorkingKey:(int)is3des masterIndex:(int)masterIndex workingIndex:(int)workingIndex workingKey:(Byte *)workingKey keyLength:(int)keyLength;

/**
 * Pinpad输入密码（PinBlock）
 * is3des			是否采用3DES算法，false表示使用DES算法（本pinpad无效）
 * isAutoReturn		输入到约定长度时是否自动返回（不需要按Enter) （本pinpad无效）
 * masterIndex 		主密钥索引,   当 masterIndex < 0, 将获取明文Pin
 * workingIndex     工作密钥索引
 * cardNo 			卡号/帐号（最少12位数字,如果cardNo为nil，语音提示为"请再输入一次"，使用上次传入的卡号。
 *                  --如果获取明文密码，cardNo也需要，使用规则和Pinblock相同。
 * pinLength		需要输入PIN的长度， 输入明文密码时无效
 * timeout          输入密码等待超时时间 <= 255 秒
 */
-(void)inputPinblock:(int)is3des isAutoReturn:(BOOL)isAutoReturn masterIndex:(int)masterIndex workingIndex:(int)workingIndex cardNo:(NSString *)cardNo pinLength:(int)pinLength timeout:(int)timeout;


//获取设备序列号
-(void)pinPadGetProductSN;

@end
