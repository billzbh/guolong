//
//  iMateGznsPinPad.h
//  支持联迪M35 mPOS，广州农商定制接口
//
//  Created by hxsmart on 15-10-25.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iMateAppFace.h"

// Pinpad操作类型枚举
typedef enum {
    GznsPinPadRequestTypeVersion = 0,
    GznsPinPadRequestTypeDownloadPlainMasterKey,
    GznsPinPadRequestTypeDownloadMasterKey,
    GznsPinPadRequestTypeDownloadWorkingKey,
    GznsPinPadRequestTypeInputPinBlock,
}GznsPinPadRequestType;

@protocol iMateGznsPinpadDelegate <iMateAppFaceDelegate>

// PinPad返回数据处理
-(void)gznsPinPadDelegateResponse:(NSInteger)returnCode
                  requestType:(GznsPinPadRequestType)type
                 responseData:(NSString *)data
                        error:(NSString *)error;

@end

@interface iMateGznsPinPad : NSObject

@property (assign, nonatomic) id<iMateGznsPinpadDelegate> delegate;

// 获取iMatePinPad实例
+(iMateGznsPinPad *)imatePinPad;

// 检测密码键盘是否连接成功
-(BOOL)isConnected;

/**
 * 获取Pinpad的版本号信息
 * 结果会通过gznsPinPadDelegateResponse获得，returnCode = 0 为成功，否则error有错误信息
 * -- data的输出数据为Pinpad的版本信息
 */
-(void)pinpadVersion;

/**
 * 取消Pinpad操作
 */
-(void)cancel;

/**
 * Pinpad明文下装主密钥，两个分量
 * masterKey1   主密钥分量1,长度为32个字符，0~9,A~F
 * masterKey2   主密钥分量2,长度为32个字符，0~9,A~F
 * 下载的结果会通过gznsPinPadDelegateResponse获得，returnCode = 0 为成功，否则error有错误信息
 * -- data的输出数据包括8字节masterKey1的验证码+8字节masterKey2的验证码+8字节masterKey的验证码
 */
-(void)downloadPlainMasterKey:(NSString *)masterKey1 masterKey2:(NSString *)masterKey2;

/**
 * Pinpad下装主密钥
 * masterKey    主密钥密文(用原主密钥加密),长度为40个字符(0~9,A~F)。包括32长度的密钥以及8字节的验证码。
 */
-(void)downloadMasterKey:(NSString *)masterKey;

/**
 * Pinpad下装工作密钥(主密钥加密）
 * masterKey    工作密钥密文(用主密钥加密),长度为40个字符(0~9,A~F)。包括32长度的密钥以及8字节的验证码。
 * 下载的结果会通过gznsPinPadDelegateResponse获得，returnCode = 0 为成功，否则error有错误信息
 */
-(void)downloadWorkingKey:(NSString *)workingKey;

/**
 * Pinpad输入密码（PinBlock）
 * cardNo			卡号/帐号（最少13位数字）
 * pinLength		需要输入PIN的长度
 * timeout			输入密码等待超时时间 <= 255 秒
 * 下载的结果会通过gznsPinPadDelegateResponse获得，returnCode = 0 为成功，否则error有错误信息
 * -- data的输出数据包括16个字符长度的PinBlock。
 */
-(void)inputPinblock:(NSString *)cardNo pinLength:(int)pinLength timeout:(int)timeout;

@end
