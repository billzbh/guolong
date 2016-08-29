//
//  iMateM35PinPad.m
//  支持凯明扬Pinpad
//
//  Created by hxsmart on 15-1-17.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import "iMateGznsPinPad.h"
#import "EADSessionController.h"
#import "iMateAppFacePrivate.h"
#import "iMateAppFace+Pinpad.h"
#import "SyncCommon.h"
#import "PinpadObject.h"
#import "LandiMPOS.h"

#include "VposFace.h"

static iMateGznsPinPad *sg_iMatePinPad = nil;

extern uchar _ucRcXMemReadReserved(void *pBuf, uint uiOffset, uint uiLen);
extern uchar _ucRcXMemWriteReserved(void *pBuf, uint uiOffset, uint uiLen);

extern NSData *gl_masterKeyFromDevice;

@interface iMateGznsPinPad(){
    volatile BOOL cancelFlag;
}
@property (nonatomic, strong) EADSessionController *iMateEADSessionController;
@property (nonatomic, strong) SyncCommon *syncCommon;

@end

@implementation iMateGznsPinPad

-(id)initWithEADSession
{
    self = [super init];
    if(self){
        cancelFlag = NO;
    }
    return self;
}

+(iMateGznsPinPad *)imatePinPad
{
    if(sg_iMatePinPad == nil){
        sg_iMatePinPad = [[iMateGznsPinPad alloc] init];
    }
    return sg_iMatePinPad;
}

// 检测密码键盘是否连接成功
-(BOOL)isConnected
{
    return [[LandiMPOS getInstance] isConnectToDevice] && [[iMateAppFace sharedController] connectingTest];
}

-(void)cancel
{
    [[LandiMPOS getInstance] cancelCMD:nil failedBlock:nil];
}

-(BOOL)testConnecting:(int)requestType
{
    if ( [[iMateAppFace sharedController] connectingTest] == NO ) {
        if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ){
            [_delegate gznsPinPadDelegateResponse:1 requestType:requestType responseData:nil error:@"iMate未连接"];
        }
        return NO;
    }

    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ){
            [_delegate gznsPinPadDelegateResponse:2 requestType:requestType responseData:nil error:@"iMate手柄未连接"];
        }
        return NO;
    }
    return YES;
}

-(void)pinpadVersion
{
    if (![self testConnecting:GznsPinPadRequestTypeVersion])
        return;
    
    [[LandiMPOS getInstance] getDeviceInfo:^(LDC_DeviceInfo *deviceInfo) {
#ifdef DEBUG
        NSLog(@"***************getDeviceInfo success!****************");
#endif
        dispatch_async(dispatch_get_main_queue(), ^{

            if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ){
                NSString *version = [NSString stringWithFormat:@"%@,%@", deviceInfo.hardwareVer, deviceInfo.userSoftVer];
                [_delegate gznsPinPadDelegateResponse:0 requestType:GznsPinPadRequestTypeVersion responseData:version error:nil];
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
                if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ) {
                    [_delegate gznsPinPadDelegateResponse:2 requestType:GznsPinPadRequestTypeVersion responseData:nil error:errInfo];
                }
            });
        }
    }];
}

/*
-(void)downloadPlainMasterKey2:(int)flag masterKey1:(NSString *)masterKey1 masterKey2:(NSString *)masterKey2
{
    if (![self testConnecting:GznsPinPadRequestTypeDownloadPlainMasterKey])
        return;
    
    if (masterKey1.length != 32 || masterKey2.length != 32) {
        if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ){
            [_delegate gznsPinPadDelegateResponse:3 requestType:GznsPinPadRequestTypeDownloadPlainMasterKey responseData:nil error:@"密钥长度错误"];
        }
        return;
    }
    static Byte m1[16], m2[16], tmp[16];
    static char szCheck1[8+1], szCheck2[8+1], szCheck[8+1], szMasterKey[32+1];
    
    vTwoOne(masterKey1.UTF8String, 32, m1);
    vTwoOne(masterKey2.UTF8String, 32, m2);
    
    _vDes(TRI_ENCRYPT, "\x0\x0\x0\x0\x0\x0\x0\x0", m1, tmp);
    vOneTwo0(tmp, 4, szCheck1);
    _vDes(TRI_ENCRYPT, "\x0\x0\x0\x0\x0\x0\x0\x0", m2, tmp);
    vOneTwo0(tmp, 4, szCheck2);
    
    vXor(m1, m2, 16);
    _vDes(TRI_ENCRYPT, "\x0\x0\x0\x0\x0\x0\x0\x0", m1, tmp);
    vOneTwo0(tmp, 4, szCheck);
    vOneTwo0(m1, 16, szMasterKey);
                
    LFC_LoadKey *key = [[LFC_LoadKey alloc] init];
    key.keyType = KEYTYPE_MKEY;
    key.keyData = [NSString stringWithFormat:@"%s%s", szMasterKey, szCheck];
    
    NSLog(@"key.keyData = %@", key.keyData);
    
    [[LandiMPOS getInstance] loadKey:key successBlock:^{
#ifdef DEBUG
        NSLog(@"***************load mkey success!****************");
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString *response = nil;
            if (flag)
                response = [NSString stringWithFormat:@"%s%s%s", szCheck1, szCheck2, szCheck];
            if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ){
                [_delegate gznsPinPadDelegateResponse:0 requestType:GznsPinPadRequestTypeDownloadPlainMasterKey  responseData:response error:nil];
            }
            
        });
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
#ifdef DEBUG
        NSLog(@"***************load mkey error!****************");
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ) {
                [_delegate gznsPinPadDelegateResponse:2 requestType:GznsPinPadRequestTypeDownloadPlainMasterKey  responseData:nil error:errInfo];
            }
        });
    }];
}
*/

-(void)downloadPlainMasterKey2:(int)flag masterKey1:(NSString *)masterKey1 masterKey2:(NSString *)masterKey2
{
    if (![self testConnecting:GznsPinPadRequestTypeDownloadPlainMasterKey])
        return;
    
    if (masterKey1.length != 32 || masterKey2.length != 32) {
        if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ){
            [_delegate gznsPinPadDelegateResponse:3 requestType:GznsPinPadRequestTypeDownloadPlainMasterKey responseData:nil error:@"密钥长度错误"];
        }
        return;
    }
    static Byte m1[16], m2[16], tmp[16];
    static char szCheck1[8+1], szCheck2[8+1], szCheck[8+1], szMasterKey[32+1];
    
    vTwoOne(masterKey1.UTF8String, 32, m1);
    vTwoOne(masterKey2.UTF8String, 32, m2);
    
    _vDes(TRI_ENCRYPT, "\x0\x0\x0\x0\x0\x0\x0\x0", m1, tmp);
    vOneTwo0(tmp, 4, szCheck1);
    _vDes(TRI_ENCRYPT, "\x0\x0\x0\x0\x0\x0\x0\x0", m2, tmp);
    vOneTwo0(tmp, 4, szCheck2);
    
    vXor(m1, m2, 16);
    _vDes(TRI_ENCRYPT, "\x0\x0\x0\x0\x0\x0\x0\x0", m1, tmp);
    vOneTwo0(tmp, 4, szCheck);
    vOneTwo0(m1, 16, szMasterKey);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            if (_ucRcXMemWriteReserved(m1, 20+13, 16)) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ) {
                        [_delegate gznsPinPadDelegateResponse:9 requestType:GznsPinPadRequestTypeDownloadPlainMasterKey  responseData:nil error:@"主密钥下装失败，iMate状态错误"];
                    }
                });
            }
            else {
                gl_masterKeyFromDevice = [NSData dataWithBytes:m1 length:16];
                
                LFC_LoadKey *key = [[LFC_LoadKey alloc] init];
                key.keyType = KEYTYPE_MKEY;
                key.keyData = [NSString stringWithFormat:@"%s%s", szMasterKey, szCheck];
                
                [[LandiMPOS getInstance] loadKey:key successBlock:^{
#ifdef DEBUG
                    NSLog(@"***************load mkey success!****************");
#endif
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSString *response = nil;
                        if (flag)
                            response = [NSString stringWithFormat:@"%s%s%s", szCheck1, szCheck2, szCheck];
                        if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ){
                            [_delegate gznsPinPadDelegateResponse:0 requestType:GznsPinPadRequestTypeDownloadPlainMasterKey  responseData:response error:nil];
                        }
                        
                    });
                } failedBlock:^(NSString *errCode, NSString *errInfo) {
#ifdef DEBUG
                    NSLog(@"***************load mkey error!****************");
#endif
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ) {
                            [_delegate gznsPinPadDelegateResponse:2 requestType:GznsPinPadRequestTypeDownloadPlainMasterKey  responseData:nil error:errInfo];
                        }
                    });
                }];
                
            }
        }
    });
}

-(void)downloadPlainMasterKey:(NSString *)masterKey1 masterKey2:(NSString *)masterKey2
{
    [self downloadPlainMasterKey2:1 masterKey1:masterKey1 masterKey2:masterKey2];
}

/*
-(void)downloadMasterKey:(NSString *)masterKey
{
    if (![self testConnecting:GznsPinPadRequestTypeDownloadMasterKey])
        return;
    
    if (masterKey.length != 40) {
        if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ) {
            [_delegate gznsPinPadDelegateResponse:3 requestType:GznsPinPadRequestTypeDownloadMasterKey responseData:nil error:@"密钥长度错误"];
        }
        return;
    }
    static char szMasterKey[32+1], szCheck[8+1];
    memcpy(szMasterKey, masterKey.UTF8String, 32);
    szMasterKey[32] = 0;
    memcpy(szCheck, masterKey.UTF8String + 32, 8);
    szCheck[8] = 0;
    
    Byte mkey[16];
    vTwoOne(szMasterKey, 32, mkey);
    
    // 解密主密钥
    [[LandiMPOS getInstance] dectyptDataByMpos:[NSData dataWithBytes:mkey length:16] successBlock:^(NSData *dateCB) {
        NSLog(@"dateCB: %@", dateCB);
        Byte tmp[8];
        _vDes(TRI_ENCRYPT, "\x0\x0\x0\x0\x0\x0\x0\x0", (Byte *)dateCB.bytes, tmp);
        char szTmp[8+1];
        vOneTwo0(tmp, 4, szTmp);
        
        if (strcmp(szCheck, szTmp)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ) {
                    [_delegate gznsPinPadDelegateResponse:3 requestType:GznsPinPadRequestTypeDownloadMasterKey responseData:nil error:@"主密钥下载失败，校验码验证错误"];
                }
            });
            return;
        }
        // 明文下载主密钥，第二个分量设置成全0
        [self downloadPlainMasterKey2:0 masterKey1:[iMateAppFace oneTwoData:dateCB] masterKey2:@"00000000000000000000000000000000"];

    } failedBlock:^(NSString *errCode, NSString *errInfo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ){
                NSString *err = [NSString stringWithFormat:@"%@:%@",errCode,errInfo];
                [_delegate gznsPinPadDelegateResponse:2 requestType:GznsPinPadRequestTypeDownloadMasterKey responseData:nil error:err];
            }
        });
    }];
}
 */

-(void)downloadMasterKey:(NSString *)masterKey
{
    if (![self testConnecting:GznsPinPadRequestTypeDownloadMasterKey])
        return;
    
    if (masterKey.length != 40) {
        if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ) {
            [_delegate gznsPinPadDelegateResponse:3 requestType:GznsPinPadRequestTypeDownloadMasterKey responseData:nil error:@"密钥长度错误"];
        }
        return;
    }
    
    if (gl_masterKeyFromDevice == nil) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                Byte buffer[30];
                if (_ucRcXMemReadReserved(buffer, 20, 13+16) == 0) {
                    gl_masterKeyFromDevice = [NSData dataWithBytes:buffer + 13 length:16];
                }
            }
        });
        if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ) {
            [_delegate gznsPinPadDelegateResponse:4 requestType:GznsPinPadRequestTypeDownloadMasterKey responseData:nil error:@"主密钥下载失败, iMate状态错误"];
        }
        return;
    }
    
    char szMasterKey[32+1], szCheck[8+1];
    Byte m[16], plainMasterKey[16];
    
    memcpy(szMasterKey, masterKey.UTF8String, 32);
    szMasterKey[32] = 0;
    memcpy(szCheck, masterKey.UTF8String + 32, 8);
    szCheck[8] = 0;
    
    vTwoOne(szMasterKey, 32, m);
    _vDes(TRI_DECRYPT, m, (Byte*)gl_masterKeyFromDevice.bytes, plainMasterKey);
    _vDes(TRI_DECRYPT, m + 8, (Byte*)gl_masterKeyFromDevice.bytes, plainMasterKey + 8);
    
    char szPlainMasterKey[32+1];
    vOneTwo0(plainMasterKey, 16, szPlainMasterKey);
    
    Byte tmp[8];
    _vDes(TRI_ENCRYPT, "\x0\x0\x0\x0\x0\x0\x0\x0", plainMasterKey, tmp);
    char szTmp[8+1];
    vOneTwo0(tmp, 4, szTmp);
    
    if (strcmp(szCheck, szTmp)) {
        if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ) {
            [_delegate gznsPinPadDelegateResponse:3 requestType:GznsPinPadRequestTypeDownloadMasterKey responseData:nil error:@"主密钥下载失败，主密钥校验码错误"];
        }
        return;
    }
    // 明文下载主密钥，第二个分量设置成全0
    [self downloadPlainMasterKey2:0 masterKey1:[NSString stringWithFormat:@"%s", szPlainMasterKey] masterKey2:@"00000000000000000000000000000000"];
}

-(void)downloadWorkingKey:(NSString *)workingKey
{
    if (![self testConnecting:GznsPinPadRequestTypeDownloadWorkingKey])
        return;
    
    LFC_LoadKey *key = [[LFC_LoadKey alloc] init];
    key.keyType = KEYTYPE_PIN;
    key.keyData = workingKey;
    
    [[LandiMPOS getInstance] loadKey:key successBlock:^{
#ifdef DEBUG
        NSLog(@"***************load workingkey success!****************");
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ){
                [_delegate gznsPinPadDelegateResponse:0 requestType:GznsPinPadRequestTypeDownloadWorkingKey responseData:nil error:nil];
            }
        });
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
#ifdef DEBUG
        NSLog(@"***************load workingkey error!****************");
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ){
                [_delegate gznsPinPadDelegateResponse:2 requestType:GznsPinPadRequestTypeDownloadWorkingKey  responseData:nil error:errInfo];
            }
        });
    }];
}

-(void)inputPinblock:(NSString *)cardNo pinLength:(int)pinLength timeout:(int)timeout;
{
    if (![self testConnecting:GznsPinPadRequestTypeInputPinBlock])
        return;
    
    LFC_GETPIN * inputPin = [[LFC_GETPIN alloc] init];
    inputPin.panBlock = cardNo;
    inputPin.moneyNum = nil;
    inputPin.timeout = timeout;
    [[LandiMPOS getInstance] inputPin:inputPin successBlock:^(NSData *dateCB) {
#ifdef DEBUG
        NSLog(@"交易密码为：%@",dateCB);
#endif
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ){
                [_delegate gznsPinPadDelegateResponse:0 requestType:GznsPinPadRequestTypeInputPinBlock  responseData:[iMateAppFace oneTwoData:dateCB] error:nil];
            }
        });
        
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
#ifdef DEBUG
        NSLog(@"错误码：%@ ,错误信息：%@",errCode,errInfo);
#endif
        //主线程执行
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( _delegate &&  [_delegate respondsToSelector:@selector(gznsPinPadDelegateResponse:requestType:responseData:error:)] ){
                [_delegate gznsPinPadDelegateResponse:2 requestType:GznsPinPadRequestTypeInputPinBlock  responseData:nil error:errInfo];
            }
        });
    }];
}

@end
