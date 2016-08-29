//
//  iMateTianshiFingerprint.h
//  支持深圳天识
//
//  Created by hxsmart on 15-10-5.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iMateAppFace.h"
#import "iMateData.h"
#import "EADSessionController.h"

#define COMM_NONE   0
#define COMM_EVEN   1
#define COMM_ODD    2

#define FINGERPRINT_BAUDRATE    9600        //指纹模块连接速率
#define FINGERPRINT_PARITY      COMM_NONE   //无奇偶校验

@interface iMateTianshiFingerprint : NSObject

// 获取iMateFingerprint实例
+(iMateTianshiFingerprint *)imateFingerprint:(EADSessionController *)iMateEADSessionController;

//取消 取指纹特征
-(void)cancel;

/**
* Fingerprint上电 (通讯波特率为9600 校验方式 0）
*/
-(void)powerOn;

/**
 * Fingerprint下电
 */
-(void)powerOff;

/**
 * 获取Fingerprint模块的版本号信息
 */
-(void)fingerprintVersion;

/**
 * 采集指纹特征值
 */
-(void)takeFingerprintFeature;


@end
