//
//  iMateAppFace+Pinpad.m
//  HXiMateSDK
//  目前支持KMY、Keyu
//
//  Created by hxsmart on 13-12-23.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import "iMateAppFacePrivate.h"
#import "iMateAppFace+Pinpad.h"
#import "iMateKmyPinPad.h"
#import "iMateXydPinPad.h"
#import "iMateSzbPinPad.h"
#import "iMateM35PinPad.h"

static int sg_pinpadModel = PINPAD_MODEL_M35;

@implementation iMateAppFace (Pinpad)

#pragma mark Pinpad methods

-(void)pinpadSetModel:(int)pinpadModel
{
    sg_pinpadModel = pinpadModel;
    if (pinpadModel == PINPAD_MODEL_KMY)
        self.pinPad = [iMateKmyPinPad imatePinPad:self.iMateEADSessionController];
    if (pinpadModel == PINPAD_MODEL_XYD)
        self.pinPad = [iMateXydPinPad imatePinPad:self.iMateEADSessionController];
    if (pinpadModel == PINPAD_MODEL_SZB)
        self.pinPad = [iMateSzbPinPad imatePinPad:self.iMateEADSessionController];
    if (pinpadModel == PINPAD_MODEL_M35)
        self.pinPad = [iMateM35PinPad imatePinPad];
}

-(void)pinPadPowerOn
{
    if([self checkWorkStatus])
        [self.pinPad powerOn];
}

-(void)pinPadPowerOff
{
    if([self checkWorkStatus])
        [self.pinPad powerOff];
}

- (void)pinPadCancel
{
    [self.pinPad cancel];
}

-(void)pinPadReset:(BOOL)initFlag
{
    if (sg_pinpadModel == PINPAD_MODEL_SZB) {
        if ( [(id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [(id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate] pinPadDelegateResponse:999 requestType:PinPadRequestTypeReset responseData:nil error:@"Pinpad不支持该功能"];
        return;
    }
    if([self checkWorkStatus])
        [self.pinPad reset:initFlag];
}

-(void)pinPadVersion
{
    if([self checkWorkStatus])
        [self.pinPad pinpadVersion];
}

//获取设备序列号
-(void)pinPadGetProductSN
{
    if([self checkWorkStatus])
        [self.pinPad pinPadGetProductSN];
}

-(void)pinPadDownloadMasterKey:(int)is3des index:(int)index masterKey:(Byte *)masterKey keyLength:(int)length
{
    if([self checkWorkStatus])
        [self.pinPad downloadMasterKey:is3des index:index masterKey:masterKey keyLength:length];
}

-(void)pinPadDownloadWorkingKey:(int)is3des masterIndex:(int)masterIndex workingIndex:(int)workingIndex workingKey:(Byte *)workingKey keyLength:(int)keyLength
{
    if([self checkWorkStatus])
        [self.pinPad downloadWorkingKey:is3des masterIndex:masterIndex workingIndex:workingIndex workingKey:workingKey keyLength:keyLength];
}

-(void)pinPadInputPinblock:(int)is3des isAutoReturn:(BOOL)isAutoReturn masterIndex:(int)masterIndex workingIndex:(int)workingIndex cardNo:(NSString *)cardNo pinLength:(int)pinLength timeout:(int)timeout
{
//    NSLog(@"card NO ===%@",cardNo);
    if([self checkWorkStatus])
        [self.pinPad inputPinblock:is3des isAutoReturn:isAutoReturn masterIndex:masterIndex workingIndex:workingIndex cardNo:cardNo pinLength:pinLength timeout:timeout];
}

-(void)pinPadEncrypt:(int)is3des algo:(int)algo masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength
{
    if (sg_pinpadModel == PINPAD_MODEL_SZB) {
        if ( [(id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [(id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate] pinPadDelegateResponse:999 requestType:PinPadRequestTypeEncrypt responseData:nil error:@"Pinpad不支持该功能"];
        return;
    }
    if([self checkWorkStatus])
        [self.pinPad encrypt:is3des algo:algo masterIndex:masterIndex workingIndex:workingIndex data:data dataLength:dataLength];
}

-(void)pinPadMac:(int)is3des masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength
{
    if (sg_pinpadModel == PINPAD_MODEL_SZB) {
        if ( [(id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [(id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate] pinPadDelegateResponse:999 requestType:PinPadRequestTypeMac responseData:nil error:@"Pinpad不支持该功能"];
        return;
    }
    if([self checkWorkStatus])
        [self.pinPad mac:is3des masterIndex:masterIndex workingIndex:workingIndex data:data dataLength:dataLength];
}


@end
