//
//  iMateM35PinPad.m
//  支持凯明扬Pinpad
//
//  Created by hxsmart on 15-1-17.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import "iMateM35PinPad.h"
#import "EADSessionController.h"
#import "iMateAppFacePrivate.h"
#import "iMateAppFace+Pinpad.h"
#import "SyncCommon.h"
#import "PinpadObject.h"
#import "LandiMPOS.h"

static iMateM35PinPad *sg_iMatePinPad = nil;

@interface iMateM35PinPad(){
    volatile BOOL cancelFlag;
}
@property (nonatomic, strong) id<iMateAppFacePinpadDelegate>delegate;
@property (nonatomic, strong) EADSessionController *iMateEADSessionController;
@property (nonatomic, strong) SyncCommon *syncCommon;

@end

@implementation iMateM35PinPad

-(id)initWithEADSession
{
    self = [super init];
    if(self){
        cancelFlag = NO;
    }
    return self;
}

+(iMateM35PinPad *)imatePinPad
{
    if(sg_iMatePinPad == nil){
        sg_iMatePinPad = [[iMateM35PinPad alloc] init];
    }
    return sg_iMatePinPad;
}

-(void)cancel
{
    [[LandiMPOS getInstance] cancelCMD:nil failedBlock:nil];
}

-(void)powerOn
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"密码键盘未连接"];
        return;
    }
    
    if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
        [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypePowerOn responseData:nil error:nil];
    }
}

-(void)powerOff
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"密码键盘未连接"];
        return;
    }
    
    if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
        [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypePowerOff responseData:nil error:nil];
    }
}

-(void)reset:(BOOL)initFlag
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"密码键盘未连接"];
        return;
    }
    
    if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
        [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypeReset responseData:nil error:nil];
    }
}

-(void)pinpadVersion
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"密码键盘未连接"];
        return;
    }
    
    [[LandiMPOS getInstance] getDeviceInfo:^(LDC_DeviceInfo *deviceInfo) {
#ifdef DEBUG
        NSLog(@"***************getDeviceInfo success!****************");
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                
                NSString *version = [NSString stringWithFormat:@"%@,%@", deviceInfo.hardwareVer, deviceInfo.userSoftVer];
                
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypeVersion responseData:[NSData dataWithBytes:version.UTF8String length:version.length] error:nil];
            }
        });
        
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
#ifdef DEBUG
        NSLog(@"***************getDeviceInfo error!****************");
#endif
        //主线程执行
        //用户取消操作，这是弹窗还在，执行没问题
        //app主动取消，弹窗已消失，执行就奔溃,所以做个判断
        
        if([errCode isEqualToString:@"ffff"])
        {
            
#ifdef DEBUG
            NSLog(@"errcode : %@ ,%@",errCode,errInfo);
#endif
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:1 requestType:PinPadRequestTypeVersion responseData:nil error:errInfo];
            });
        }
    }];
}

-(void)downloadMasterKey:(int)is3des index:(int)index masterKey:(Byte *)masterKey keyLength:(int)length
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"密码键盘未连接"];
        return;
    }
    LFC_LoadKey *key = [[LFC_LoadKey alloc] init];
    key.keyType = KEYTYPE_MKEY;
    key.keyData = [iMateAppFace oneTwoData:[NSData dataWithBytes:masterKey length:length]];
    
    [[LandiMPOS getInstance] loadKey:key successBlock:^{
#ifdef DEBUG
        NSLog(@"***************load mkey success!****************");
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypeDownloadMasterKey responseData:nil error:nil];
            }
        });
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
#ifdef DEBUG
        NSLog(@"***************load mkey error!****************");
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:1 requestType:PinPadRequestTypeDownloadMasterKey responseData:nil error:errInfo];
            }
        });
    }];
}

-(void)downloadWorkingKey:(int)is3des masterIndex:(int)masterIndex workingIndex:(int)workingIndex workingKey:(Byte *)workingKey keyLength:(int)keyLength
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"密码键盘未连接"];
        return;
    }
    
    LFC_LoadKey *key = [[LFC_LoadKey alloc] init];
    key.keyType = workingIndex;
    key.keyData = [iMateAppFace oneTwoData:[NSData dataWithBytes:workingKey length:keyLength]];
//    NSLog(@"workingKEY: %@",key.keyData);
    
    [[LandiMPOS getInstance] loadKey:key successBlock:^{
#ifdef DEBUG
        NSLog(@"***************load workingkey success!****************");
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypeDownloadWorkingKey responseData:nil error:nil];
            }
        });
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
#ifdef DEBUG
        NSLog(@"***************load workingkey error!****************");
#endif
        NSLog(@"%@,%@",errCode,errInfo);
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:1 requestType:PinPadRequestTypeDownloadWorkingKey responseData:nil error:errInfo];
            }
        });
    }];
}

-(void)inputPinblock:(int)is3des isAutoReturn:(BOOL)isAutoReturn masterIndex:(int)masterIndex workingIndex:(int)workingIndex cardNo:(NSString *)cardNo pinLength:(int)pinLength timeout:(int)timeout;
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"密码键盘未连接"];
        return;
    }
    LFC_GETPIN * inputPin = [[LFC_GETPIN alloc] init];
    inputPin.panBlock = cardNo;
    inputPin.moneyNum = nil;
    inputPin.timeout = timeout;
    [[LandiMPOS getInstance] inputPin:inputPin successBlock:^(NSData *dateCB) {
#ifdef DEBUG
        NSLog(@"交易密码为：%@",dateCB);
#endif
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            
            [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypeInputPinBlock responseData:dateCB error:nil];
        }
        
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
#ifdef DEBUG
        NSLog(@"错误码：%@ ,错误信息：%@",errCode,errInfo);
#endif
        //主线程执行
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                NSString *err = [NSString stringWithFormat:@"%@:%@",errCode,errInfo];
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:1 requestType:PinPadRequestTypeInputPinBlock responseData:nil error:err];
            }
        });
    }];
}

-(void)encrypt:(int)is3des algo:(int)algo masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength
{
    
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"密码键盘未连接"];
        return;
    }
    
    if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
        
        [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:1 requestType:PinPadRequestTypeEncrypt responseData:[NSData dataWithBytes:data length:dataLength] error:@"不支持该方法"];
    }
}

-(void)mac:(int)is3des masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"密码键盘未连接"];
        return;
    }
    [[LandiMPOS getInstance] calculateMac:[iMateAppFace oneTwoData:[NSData dataWithBytes:data length:dataLength]] successBlock:^(NSData *dateCB) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypeMac responseData:dateCB error:nil];
            }
        });
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                NSString *err = [NSString stringWithFormat:@"%@:%@",errCode,errInfo];
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:1 requestType:PinPadRequestTypeMac responseData:nil error:err];
            }
        });
    }];
}

//获取设备序列号
-(void)pinPadGetProductSN
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"密码键盘未连接"];
        return;
    }
    [[LandiMPOS getInstance] getDeviceInfo:^(LDC_DeviceInfo *deviceInfo) {
#ifdef DEBUG
        NSLog(@"***************getDeviceInfo success!****************");
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                
                NSString *resstring=[NSString stringWithFormat:@"AKPH%@",deviceInfo.pinpadSN];
                
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate])
                 pinPadDelegateResponse:0 requestType:PinPadRequestTypeSN responseData:[resstring dataUsingEncoding:NSUTF8StringEncoding] error:nil];
            }
        });
        
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
#ifdef DEBUG
        NSLog(@"***************getDeviceInfo error!****************");
#endif
        //主线程执行
        //用户取消操作，这是弹窗还在，执行没问题
        //app主动取消，弹窗已消失，执行就奔溃,所以做个判断
        
        if([errCode isEqualToString:@"ffff"])
        {
            
#ifdef DEBUG
            NSLog(@"errcode : %@ ,%@",errCode,errInfo);
#endif
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:1 requestType:PinPadRequestTypeSN responseData:nil error:errInfo];
            });
        }
    }];
}




@end
