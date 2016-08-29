//
//  iMateZhongZhengFingerprint.h
//  HXiMateSDK
//
//  支持中正指纹模块
//  Created by zbh on 15/4/17.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//

#ifndef HXiMateSDK_iMateZhongZhengFingerprint_h
#define HXiMateSDK_iMateZhongZhengFingerprint_h


#import <Foundation/Foundation.h>
#import "iMateAppFace.h"
#import "iMateData.h"
#import "EADSessionController.h"

#define COMM_NONE   0
#define COMM_EVEN   1
#define COMM_ODD    2

#define BAUDRATE    115200        //指纹模块连接速率
#define FINGERPRINT_PARITY      COMM_NONE   //无奇偶校验
#define IMAGESIZE               152*100

@interface iMateZhongZhengFingerprint : NSObject

// 获取iMateFingerprint实例
+(iMateZhongZhengFingerprint *)imateFingerprint:(EADSessionController *)iMateEADSessionController;

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
 * 采集128字节指纹特征值(默认)
 */
-(void)takeFingerprintFeature;

/**
 * 生成指纹模板
 */
-(void)GenerateFingerTemplate;

/**
 * 采集256字节指纹特征值
 */
-(void)fingerExpInfo;


/**
 * 上传指纹图像
 */
-(void)getFingerImage;


//更改波特率
-(void)setBaudrate:(long)baudrate;

@end

#endif
