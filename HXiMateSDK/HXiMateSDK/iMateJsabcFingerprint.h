//
//  iMateJsabcFingerprint.h
//  支持浙江维尔(江苏农行）
//
//  Created by hxsmart on 13-8-8.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
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

@interface iMateJsabcFingerprint : NSObject

// 获取iMateFingerprint实例
+(iMateJsabcFingerprint *)imateFingerprint:(EADSessionController *)iMateEADSessionController;

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

//更改波特率
-(void)setBaudrate:(long)baudrate;

@end
