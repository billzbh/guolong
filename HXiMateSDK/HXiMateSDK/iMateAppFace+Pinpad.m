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

static int sg_pinpadModel = PINPAD_MODEL_KMY;


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

-(void)pinPadDownloadMasterKey:(int)algorithm index:(int)index masterKey:(Byte *)masterKey keyLength:(int)length
{
    if([self checkWorkStatus])
        [self.pinPad downloadMasterKey:algorithm index:index masterKey:masterKey keyLength:length];
}

-(void)pinPadDownloadWorkingKey:(int)algorithm masterIndex:(int)masterIndex workingIndex:(int)workingIndex workingKey:(Byte *)workingKey keyLength:(int)keyLength
{
    if([self checkWorkStatus])
        [self.pinPad downloadWorkingKey:algorithm masterIndex:masterIndex workingIndex:workingIndex workingKey:workingKey keyLength:keyLength];
}

-(void)pinPadInputPinblock:(int)algorithm isAutoReturn:(BOOL)isAutoReturn masterIndex:(int)masterIndex workingIndex:(int)workingIndex cardNo:(NSString *)cardNo pinLength:(int)pinLength timeout:(int)timeout
{
    if([self checkWorkStatus])
        [self.pinPad inputPinblock:algorithm isAutoReturn:isAutoReturn masterIndex:masterIndex workingIndex:workingIndex cardNo:cardNo pinLength:pinLength timeout:timeout];
}

-(void)pinPadEncrypt:(int)algorithm cryptoMode:(int)cryptoMode masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength
{
    if (sg_pinpadModel == PINPAD_MODEL_SZB) {
        if ( [(id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [(id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate] pinPadDelegateResponse:999 requestType:PinPadRequestTypeEncrypt responseData:nil error:@"Pinpad不支持该功能"];
        return;
    }
    if([self checkWorkStatus])
        [self.pinPad encrypt:algorithm cryptoMode:cryptoMode masterIndex:masterIndex workingIndex:workingIndex data:data dataLength:dataLength];
}

-(void)pinPadMac:(int)algorithm masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength
{
    if (sg_pinpadModel == PINPAD_MODEL_SZB) {
        if ( [(id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [(id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate] pinPadDelegateResponse:999 requestType:PinPadRequestTypeMac responseData:nil error:@"Pinpad不支持该功能"];
        return;
    }
    if([self checkWorkStatus])
        [self.pinPad mac:algorithm masterIndex:masterIndex workingIndex:workingIndex data:data dataLength:dataLength];
}

-(void)pinPadHash:(int)hashAlgorithm data:(Byte*)data dataLength:(int)dataLength
{
    if (sg_pinpadModel != PINPAD_MODEL_KMY) {
        if ( [(id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [(id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate] pinPadDelegateResponse:999 requestType:PinPadRequestTypeMac responseData:nil error:@"Pinpad不支持该功能"];
        return;
    }
    if([self checkWorkStatus])
        [self.pinPad hash:hashAlgorithm data:data dataLength:dataLength];
}


@end
