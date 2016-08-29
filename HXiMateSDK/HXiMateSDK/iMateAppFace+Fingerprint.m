//
//  iMateAppFace+Fingerprint.m
//  HXiMateSDK
//  目前支持iMate内置指纹阅读器
//
//  Created by hxsmart on 13-12-23.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import "iMateAppFacePrivate.h"
#import "iMateAppFace+Fingerprint.h"
#import "iMateJsabcFingerprint.h"
#import "iMateShengtengFingerprint.h"
#import "iMateZhongZhengFingerprint.h"
#import "iMateTianshiFingerprint.h"

static int sg_fingerprintModel = FINGERPRINT_MODEL_JSABC;

@implementation iMateAppFace (Fingerprint)

#pragma mark Fingerprint methods

-(void)fingerprintSetModel:(int)fingerprintModel
{
    sg_fingerprintModel = fingerprintModel;
    if (fingerprintModel == FINGERPRINT_MODEL_JSABC)
        self.fingerprint = [iMateJsabcFingerprint imateFingerprint:self.iMateEADSessionController];
    if (fingerprintModel == FINGERPRINT_MODEL_SHENGTENG)
        self.fingerprint = [iMateShengtengFingerprint imateFingerprint:self.iMateEADSessionController];
    if (fingerprintModel == FINGERPRINT_MODEL_ZHONGZHENG)
        self.fingerprint = [iMateZhongZhengFingerprint imateFingerprint:self.iMateEADSessionController];
    if (fingerprintModel == FINGERPRINT_MODEL_TIANSHI)
        self.fingerprint = [iMateTianshiFingerprint imateFingerprint:self.iMateEADSessionController];
}

-(void)fingerprintCancel
{
    [self.fingerprint cancel];
}

-(void)fingerprintPowerOn
{
    if([self checkWorkStatus])
        [self.fingerprint powerOn];
}

-(void)fingerprintPowerOff
{
    if([self checkWorkStatus])
        [self.fingerprint powerOff];
}

-(void)fingerprintVersion
{
    if([self checkWorkStatus])
        [self.fingerprint fingerprintVersion];
}

// 读取指纹特征值, 指纹模块超时时间为6秒
-(void)fingerprintFeature
{
    if([self checkWorkStatus])
        [self.fingerprint takeFingerprintFeature];
}


//目前只支持 中正指纹仪
-(void)fingerprint256FeatureForZHONGZHENG
{
    if (sg_fingerprintModel == FINGERPRINT_MODEL_ZHONGZHENG )
    {
        if([self checkWorkStatus])
            [self.fingerprint fingerExpInfo];
    }
}


// 读取指纹特征值, 指纹模块超时时间为6秒  //目前只支持 中正指纹仪
-(void)fingerprintImage
{
    if (sg_fingerprintModel == FINGERPRINT_MODEL_ZHONGZHENG || sg_fingerprintModel == FINGERPRINT_MODEL_SHENGTENG )
    {
        if([self checkWorkStatus])
            [self.fingerprint getFingerImage];
    }

}

//更改波特率
-(void)setBaudrate:(long)baudrate
{
    if([self checkWorkStatus])
        [self.fingerprint setBaudrate:baudrate];
}

@end
