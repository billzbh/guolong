//
//  iMateTyPinPad.h
//  支持天喻 mPOS
//
//  Created by hxsmart on 15-1-17.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//





@interface iMateTyPinPad : NSObject

// 获取iMatePinPad实例
+(iMateTyPinPad *)imatePinPad;

/**
 * 绑定密码键盘名字
 */
-(void)BindName:(NSString*)TYname;

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
 * is3des		是否采用3DES算法，该参数无效，使用3DES算法
 * @param   index		主密钥索引, 对于改机型，该参数无效
 * @param   mastKey		主密钥
 * @param   keyLength	主密钥长度，20字节长，16字节密钥+4字节校验
 */
-(void)downloadMasterKey:(BOOL)is3des index:(int)index masterKey:(Byte *)masterKey keyLength:(int)length;

/**
 * Pinpad下装工作密钥(主密钥加密）
 * is3des			是否采用3DES算法，该参数无效，使用3DES算法
 * @param   masterIndex		主密钥索引, 对于改机型，该参数无效
 * @param   workingIndex	工作密钥索引, 对应密钥类型如下：    
                                        KEYTYPE_TRACK   = 0x01,
                                        KEYTYPE_PIN     = 0x02,
                                        KEYTYPE_MAC     = 0x03,
 * @param   workingKey		工作密钥
 * @param   keyLength		工作密钥长度，20字节长，16字节密钥+4字节校验
 */
-(void)downloadWorkingKey:(BOOL)is3des masterIndex:(int)masterIndex workingIndex:(int)workingIndex workingKey:(Byte *)workingKey keyLength:(int)keyLength;

/**
 * Pinpad输入密码（PinBlock）
 * is3des			是否采用3DES算法，该参数无效，使用3DES算法
 * isAutoReturn	输入到约定长度时是否自动返回（不需要按Enter)
 * @param   masterIndex		主密钥索引
 * @param   workingIndex	工作密钥索引
 * @param   cardNo			卡号/帐号（最少12位数字）
 * @param   pinLength		需要输入PIN的长度
 * @param   timeout			输入密码等待超时时间 <= 255 秒
 */
-(void)inputPinblock:(BOOL)is3des isAutoReturn:(BOOL)isAutoReturn masterIndex:(int)masterIndex workingIndex:(int)workingIndex cardNo:(NSString *)cardNo pinLength:(int)pinLength timeout:(int)timeout;

/**
 * Pinpad加解密数据, M35不支持该方法
 * is3des			是否采用3DES算法，该参数无效，使用3DES算法
 * algo			算法，取值: ALGO_ENCRYPT, ALGO_DECRYPT, 以ECB方式进行加解密运算
 * @param   masterIndex		主密钥索引
 * @param   workingIndex	工作密钥索引，如果工作密钥索引取值-1，使用主密钥索引指定的主密钥进行加解密
 * @param   data			加解密数据
 * @param   dataLength		加解密数据的长度,要求8的倍数并小于或等于248字节长度
 */
-(void)encrypt:(BOOL)is3des algo:(int)algo masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength;

/**
 * Pinpad数据MAC运算（ANSIX9.9）
 * is3des			是否采用3DES算法，该参数无效，使用3DES算法
 * @param   masterIndex		主密钥索引， 该参数无效
 * @param   workingIndex	工作密钥索引，该参数无效，缺省使用MAC—Key
 * @param   data			计算Mac原数据
 * @param   dataLength		Mac原数据的长度,要求8的倍数并小于或等于246字节长度
 */
-(void)mac:(BOOL)is3des masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength;


@end
