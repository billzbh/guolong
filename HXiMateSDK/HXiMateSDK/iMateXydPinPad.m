//
//  iMatePinPad.m
//  支持信雅达Pinpad
//
//  Created by hxsmart on 13-8-8.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import "iMateXydPinPad.h"
#import "EADSessionController.h"
#import "iMateAppFacePrivate.h"
#import "iMateAppFace+Pinpad.h"
#import "SyncCommon.h"
#import "PinpadObject.h"
#include "vposface.h"

static iMateXydPinPad *sg_iMatePinPad = nil;

@interface iMateXydPinPad(){
    volatile BOOL cancelFlag;
    
    int workDirNum;
    int keyMode;
    unsigned char transferKey[16];
	unsigned char authCodeKey[16];
	unsigned char uid[16];
}
@property (nonatomic, strong) id<iMateAppFacePinpadDelegate>delegate;
@property (nonatomic, strong) EADSessionController *iMateEADSessionController;
@property (nonatomic, strong) SyncCommon *syncCommon;

@end

@implementation iMateXydPinPad

-(id)initWithEADSession:(EADSessionController *)iMateEADSessionController
{
    self = [super init];
    if(self){
        _syncCommon = [SyncCommon syncCommon:iMateEADSessionController];
        _iMateEADSessionController = iMateEADSessionController;

        cancelFlag = NO;
        workDirNum = 1;
        keyMode = PIN_KEY_MODE;
        memset(transferKey, 0, 16);
        memset(authCodeKey, 0, 16);
        memcpy(uid,"0123456789012345", 16);
    }
    return self;
}

+(iMateXydPinPad *)imatePinPad:(EADSessionController *)iMateEADSessionController
{
    if(sg_iMatePinPad == nil){
        sg_iMatePinPad = [[iMateXydPinPad alloc] initWithEADSession:iMateEADSessionController];
    }
    return sg_iMatePinPad;
}

-(void)cancel
{
    cancelFlag = YES;
}

//获取设备序列号
-(void)pinPadGetProductSN
{
    
}

-(void)powerOn
{
    [self performSelectorInBackground:@selector(powerOnThread) withObject:nil];
}

-(void)powerOff
{
    [self performSelectorInBackground:@selector(powerOffThread) withObject:nil];
}

-(void)reset:(BOOL)initFlag
{
    NSObject *object = nil;
    if(initFlag)
        object = [[NSObject alloc] init];
    
    [self performSelectorInBackground:@selector(resetThread:) withObject:object];
}

-(void)pinpadSetup:(NSString *)key value:(Byte *)value
{
    if ([key isEqualToString:@"AuthCode"]) {
        memcpy(authCodeKey, value, 16);
    }
    if ([key isEqualToString:@"UID"]) {
        memcpy(uid, value, 16);
    }
    if ([key isEqualToString:@"WorkDirNum"]) {
        workDirNum = value[0];
    }
}

/**
 * 设置密钥类型， 用于下载masterkey或workingkey之前调用
 * @param	mode		主密钥类型包括 :
 * 					DECRYPT_KEY_MODE, ENCRYPT_KEY_MODE, PIN_KEY_MODE
 */
-(void)setKeyMode:(int)mode
{
    keyMode = mode;
}

-(void)pinpadVersion
{
    [self performSelectorInBackground:@selector(versionThread) withObject:nil];
}

-(void)downloadMasterKey:(int)is3des index:(int)index masterKey:(Byte *)masterKey keyLength:(int)length
{
    PinPadObject *object = [[PinPadObject alloc] init];
    object.algorithm = is3des;
    object.masterIndex = index;
    object.masterKey = [NSData dataWithBytes:masterKey length:length];
    object.masterLength = length;
    [self performSelectorInBackground:@selector(downloadMasterkeyThread:) withObject:object];
}

-(void)downloadWorkingKey:(int)is3des masterIndex:(int)masterIndex workingIndex:(int)workingIndex workingKey:(Byte *)workingKey keyLength:(int)keyLength
{
    PinPadObject *object = [[PinPadObject alloc] init];
    object.algorithm = is3des;
    object.masterIndex = masterIndex;
    object.workingIndex = workingIndex;
    object.workingKey = [NSData dataWithBytes:workingKey length:keyLength];
    object.workingLength = keyLength;
    [self performSelectorInBackground:@selector(downloadWorkingkeyThread:) withObject:object];
}

-(void)inputPinblock:(int)is3des isAutoReturn:(BOOL)isAutoReturn masterIndex:(int)masterIndex workingIndex:(int)workingIndex cardNo:(NSString *)cardNo pinLength:(int)pinLength timeout:(int)timeout;
{
    PinPadObject *object = [[PinPadObject alloc] init];
    object.algorithm = is3des;
    object.isAutoReturn = isAutoReturn;
    object.masterIndex = masterIndex;
    object.workingIndex = workingIndex;
    object.cardNo = cardNo;
    object.pinLength = pinLength;
    object.timeout = timeout;
    [self performSelectorInBackground:@selector(inputPinblockThread:) withObject:object];
}

-(void)encrypt:(int)is3des algo:(int)algo masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength
{
    PinPadObject *object = [[PinPadObject alloc] init];
    object.algorithm = is3des;
    object.cryptoMode = algo;
    object.masterIndex = masterIndex;
    object.workingIndex = workingIndex;
    object.data = object.workingKey = [NSData dataWithBytes:data length:dataLength];
    object.dataLength = dataLength;
    [self performSelectorInBackground:@selector(encryptThread:) withObject:object];
}

-(void)mac:(int)is3des masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength
{
    PinPadObject *object = [[PinPadObject alloc] init];
    object.algorithm = is3des;
    object.masterIndex = masterIndex;
    object.workingIndex = workingIndex;
    object.data = object.data = object.workingKey = [NSData dataWithBytes:data length:dataLength];
    object.dataLength = dataLength;
    [self performSelectorInBackground:@selector(macThread:) withObject:object];
}

-(void)powerOnThread
{
    @autoreleasepool {
        _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
        unsigned char sResponseDataBuff[20];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte sendBytes[6];
        sendBytes[0] = 0x69;
        sendBytes[1] = 0x00;
        sendBytes[2] = 0x01;
        sendBytes[3] = 9600/256;
        sendBytes[4] = 9600%256;
        sendBytes[5] = 0x00;
        int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:6 ResponseDataBuf:sResponseDataBuff timeout:1];
        //处理数据
        if (iRet > 0 && sResponseDataBuff[0]) {
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
                [self pinPadDelegateResponse:sResponseDataBuff[0] requestType:PinPadRequestTypePowerOn responseData:nil error:[_syncCommon getErrorString:sResponseDataBuff+1 length:iRet-1]];
            return;
        }
        if(iRet == -1){
            if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [self iMateDelegateNoResponse:@"iMate通讯超时"];
            return;
        }
        usleep(500000);
        int retCode = sResponseDataBuff[0];
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [self pinPadDelegateResponse:retCode requestType:PinPadRequestTypePowerOn responseData:nil error:nil];
        }
    }
}

-(void)powerOffThread
{
    @autoreleasepool {
        _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
        unsigned char sResponseDataBuff[20];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte sendBytes[3];
        sendBytes[0] = 0x69;
        sendBytes[1] = 0x00;
        sendBytes[2] = 0x02;
        int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:3 ResponseDataBuf:sResponseDataBuff timeout:1];
        //处理数据
        if (iRet > 0 && sResponseDataBuff[0] != 0) {
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
                [self pinPadDelegateResponse:sResponseDataBuff[0] requestType:PinPadRequestTypePowerOff responseData:nil error:[_syncCommon getErrorString:sResponseDataBuff+1 length:iRet-1]];
            return;
        }
        if(iRet == -1){
            if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [self iMateDelegateNoResponse:@"iMate通讯超时"];
            return;
        }
        int retCode = sResponseDataBuff[0];
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
            [self pinPadDelegateResponse:retCode requestType:PinPadRequestTypePowerOff responseData:nil error:nil];
        }
    }
}

-(void)resetThread:(NSObject*)object
{
    @autoreleasepool {
        _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
        Byte sendBytes[2];
        sendBytes[0] = 0xd5;
        sendBytes[1] = 0x00;
        int iRet = [self pinpadComm:sendBytes inLen:2 outBuff:nil requestType:PinPadRequestTypeReset timeout:2];
        if(iRet < 0){
            return;
        }
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeReset responseData:nil error:nil];
        }
    }
}

-(void)versionThread
{
    @autoreleasepool {
        _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
        
        unsigned char sResponseDataBuff[100];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte sendBytes[2];
        sendBytes[0] = 0x90;
        sendBytes[1] = 0x00;
        
        int iRet = [self pinpadComm:sendBytes inLen:2 outBuff:sResponseDataBuff requestType:PinPadRequestTypeVersion timeout:1];
        
        if(iRet < 0){
            return;
        }
        
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeVersion responseData:[NSData dataWithBytes:sResponseDataBuff length:iRet] error:nil];
        }
    }
}

-(void)downloadMasterkeyThread:(PinPadObject *)object
{
    @autoreleasepool {
        _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
        
        if (object.masterLength != 8 && object.masterLength != 16 && object.masterLength != 24){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:100 requestType:PinPadRequestTypeDownloadMasterKey responseData:nil error:@"主密钥密钥长度错误"];
            }
            return;
        }		
		if (!object.algorithm && object.masterLength!=8){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:101 requestType:PinPadRequestTypeDownloadMasterKey responseData:nil error:@"主密钥密钥长度错误"];
            }
            return;
        }
        
        if ([self changeDir:workDirNum requestType:PinPadRequestTypeDownloadMasterKey])
            return;
        
        Byte downloadMode = keyMode;
        if (object.masterLength > 8)
            downloadMode |= 0x80;
        
        Byte sendBytes[50];
        
        int count = 0;
        //下载主密钥
        sendBytes[count++] = 0x80;
        sendBytes[count++] = (10 + object.masterLength);
        sendBytes[count++] = object.masterIndex;
        sendBytes[count++] = downloadMode;
        
        Byte cipherMasterKey[30];
        
        for (int i = 0; i < object.masterLength/8; i++)
            _vDes(TRI_ENCRYPT, (unsigned char*)object.masterKey.bytes + i * 8, transferKey, cipherMasterKey + i * 8);
        
        memcpy(sendBytes + count, cipherMasterKey, object.masterLength);
        count += object.masterLength;
        
        Byte *authCode = [self genAuthCode:sendBytes startIndex:2 dataLength:sendBytes[1] - 8 mode:1 requestType:PinPadRequestTypeDownloadMasterKey];
        if (authCode == nil)
            return;
        
        memcpy(sendBytes + count, authCode, 8);
        count += 8;
        
        if ([self pinpadComm:sendBytes inLen:count outBuff:nil requestType:PinPadRequestTypeDownloadMasterKey timeout:1] < 0)
            return;
        
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeDownloadMasterKey responseData:nil error:nil];
        }
    }
}

-(void)downloadWorkingkeyThread:(PinPadObject *)object
{
    @autoreleasepool {
        _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
        
        if (object.workingLength != 8 && object.workingLength != 16 && object.workingLength != 24){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:102 requestType:PinPadRequestTypeDownloadWorkingKey responseData:nil error:@"工作密钥长度错误"];
            }
            return;
        }
        
        if ([self changeDir:workDirNum requestType:PinPadRequestTypeDownloadWorkingKey])
            return;
		
		Byte downloadMode = keyMode;
		if (object.algorithm)
			downloadMode |= 0x10;
		if (object.workingLength > 8)
			downloadMode |= 0x80;
    
		Byte sendBytes[50];
		
		int count = 0;
		//下载工作密钥
		sendBytes[count++] = 0x81;
		sendBytes[count++] = (13 + object.workingLength);
		sendBytes[count++] = object.masterIndex;
		sendBytes[count++] = object.workingIndex;
		sendBytes[count++] = downloadMode;
        
        memcpy(sendBytes + count, object.workingKey.bytes, object.workingLength);
        count += object.workingLength;
		
		//useNo
		sendBytes[count++] = 0x7f;
		sendBytes[count++] = 0xff;
        
        Byte *authCode = [self genAuthCode:sendBytes startIndex:2 dataLength:sendBytes[1] - 8 mode:1 requestType:PinPadRequestTypeDownloadWorkingKey];
        if (authCode == nil)
            return;
        
        memcpy(sendBytes + count, authCode, 8);
        count += 8;
        
        if ([self pinpadComm:sendBytes inLen:count outBuff:nil requestType:PinPadRequestTypeDownloadWorkingKey timeout:1] < 0)
            return;
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeDownloadWorkingKey responseData:nil error:nil];
        }
    }
}

//启动密码键盘加密后，错误需要关闭密码键盘
-(void)closePinPad
{
    Byte sendBytes[2];
    // 复位自检
    sendBytes[0] = 0x45;
    sendBytes[1] = 0x00;
    [self pinpadComm:sendBytes inLen:2 outBuff:nil requestType:PinPadRequestTypeInputPinBlock timeout:1];
}

-(void)inputPinblockThread:(PinPadObject *)object
{
    @autoreleasepool {
        cancelFlag = NO;
        _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
        
        if (object.cardNo.length < 13){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:103 requestType:PinPadRequestTypeInputPinBlock responseData:nil error:@"卡号/帐号长度错误"];
            }
            return;
        }
        
        if ([self changeDir:workDirNum requestType:PinPadRequestTypeInputPinBlock])
            return;
    
        Byte receivedBytes[50];
		Byte sendBytes[50];
		
		int count = 0;
		//pin输入
		sendBytes[count++] = 0x8A;
		
		//数据长度
		sendBytes[count++] = 0x1e;
		
		//加密类型
		if (object.algorithm)
			sendBytes[count++] = 0x82;
		else
			sendBytes[count++] = 0x02;
		
		//pin key id
		sendBytes[count++] = object.workingIndex;
		
		//use cnt
		sendBytes[count++] = (object.timeout / 255);
		sendBytes[count++] = (object.timeout % 255);
		
		//input min length
		sendBytes[count++] = object.pinLength;
		
		//input max length
		sendBytes[count++] = object.pinLength;
		
		//card no
		Byte *orgAccount =(Byte*)[object.cardNo dataUsingEncoding:NSUTF8StringEncoding].bytes;
		int accLen = (int)object.cardNo.length;
		int accOffset = 0;
		if (accLen > 13)
			accOffset = accLen - 13;
		
		for(int i = 0; i < 16; i++) {
			if (i >= 4)
				sendBytes[count++] =  orgAccount[accOffset++];
			else
				sendBytes[count++] = '1';
		}
        
        Byte *authCode = [self genAuthCode:sendBytes startIndex:2 dataLength:sendBytes[1] - 8 mode:1 requestType:PinPadRequestTypeDownloadMasterKey];
        if (authCode == nil)
            return;
        
        memcpy(sendBytes + count, authCode, 8);
        count += 8;
        
        int receivedLength = [self pinpadComm:sendBytes inLen:count outBuff:nil requestType:PinPadRequestTypeDownloadMasterKey timeout:1];
        if (receivedLength <= 0)
            return;
				
		if (receivedLength <= 8) {
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:104 requestType:PinPadRequestTypeInputPinBlock responseData:nil error:@"取消"];
            }
            return;
        }
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeInputPinBlock responseData:[NSData dataWithBytes:receivedBytes length:receivedLength - 8] error:nil];
        }
    }
}

-(void)encryptThread:(PinPadObject *)object
{
    @autoreleasepool {
        _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
        if (object.dataLength%8 != 0 || object.dataLength > 248 ){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:107 requestType:PinPadRequestTypeEncrypt responseData:nil error:@"加解密数据长度错误"];
            }
            return;
        }
        if ([self changeDir:workDirNum requestType:PinPadRequestTypeEncrypt])
            return;
        
        Byte receivedBytes[50];
		Byte sendBytes[50];
		
		Byte encMode = 0;
        
		if (object.cryptoMode == ALGO_DECRYPT)
			encMode = 0x80;
		if (object.algorithm) {
			encMode |= 0x03;
		}
		else {
			encMode |= 0x01;
		}
		
		// DES/3DES 加解密
		int retLength = 0;
        Byte retBytes[300];
		for(int j = 0; j < object.dataLength; j += 8){
			int count = 0;
			sendBytes[count++] = 0x87;
			sendBytes[count++] = 0x0A;
			sendBytes[count++] = object.workingIndex;
			sendBytes[count++] = encMode;
			for(int i = 0; i < 8; i++){
                Byte *p = (Byte*)object.data.bytes;
				sendBytes[count++] = p[j+i];
				
			}
            int recvLength = [self pinpadComm:sendBytes inLen:count outBuff:receivedBytes requestType:PinPadRequestTypeEncrypt timeout:2];
            if (recvLength <= 0)
                return;
            
			if(encMode != 0x82){
				if (recvLength % 8  != 0) {
                    if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                        [self pinPadDelegateResponse:108 requestType:PinPadRequestTypeEncrypt responseData:nil error:@"加解密数据失败"];
                        
                    }
                    return;
                }
			}else{
				if (recvLength % 18  != 0) {
                    if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                        [self pinPadDelegateResponse:108 requestType:PinPadRequestTypeEncrypt responseData:nil error:@"dukpt 加解密数据失败"];
                        
                    }
                    return;
                }
			}
			for (int i=0; i<recvLength; i++){
				retBytes[i + retLength] = receivedBytes[i];
			}
			retLength += recvLength;
		}
		if(retLength == 0){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:108 requestType:PinPadRequestTypeEncrypt responseData:nil error:@"加解密数据失败"];
                
            }
            return;
		}
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeEncrypt responseData:[NSData dataWithBytes:retBytes length:retLength] error:nil];
        }
    }
}

-(void)macThread:(PinPadObject *)object
{
    @autoreleasepool {
        _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
        if (object.dataLength <4 || object.dataLength > 246 ){
			if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:109 requestType:PinPadRequestTypeMac responseData:nil error:@"算MAC数据长度错误"];
            }
            return;
        }
        if ([self changeDir:workDirNum requestType:PinPadRequestTypeMac])
            return;
        
        Byte receivedBytes[30];
		Byte sendBytes[300];
		
		Byte encMode = 0x01;
		if (object.algorithm)
			encMode = 0x03;
		
		int count = 0;
		sendBytes[count++] = 0x85;
		sendBytes[count++] = (10 + object.dataLength);
		sendBytes[count++] = (object.workingIndex);
		sendBytes[count++] = encMode;
        
        memcpy(sendBytes + count, (Byte*)object.data.bytes, object.dataLength);
        count += object.dataLength;
        
        Byte *authCode = [self genAuthCode:sendBytes startIndex:2 dataLength:sendBytes[1] - 8 mode:1 requestType:PinPadRequestTypeMac];
        if (authCode == nil)
            return;
        
        memcpy(sendBytes + count, authCode, 8);
        count += 8;
				
        int recvLength = [self pinpadComm:sendBytes inLen:count outBuff:receivedBytes requestType:PinPadRequestTypeMac timeout:2];
        if (recvLength < 0)
            return;
        
		if (recvLength < 8){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:110 requestType:PinPadRequestTypeMac responseData:nil error:@"计算Mac失败"];
            }
        }
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeMac responseData:[NSData dataWithBytes:receivedBytes length:8] error:nil];
        }
    }
}

-(double)currentTimeSeconds
{
    NSTimeInterval time= [[NSDate date] timeIntervalSince1970];
    return (double)time;
}

- (NSString *)pinpadError:(Byte)errorCode
{
    NSString *retStr = nil;
    switch(errorCode){
		case 0x01:
			retStr = @"协议的长度错误";
			break;
		case 0x02:
			retStr = @"密钥校验错误";
			break;
		case 0x03:
			retStr = @"打开失败";
			break;
		case 0x04:
			retStr = @"关闭失败";
			break;
		case 0x05:
			retStr = @"设备操作失败";
			break;
		case 0x06:
			retStr = @"超时";
			break;
		case 0x07:
			retStr = @"参数错";
			break;
		case 0x08:
			retStr = @"认证失败";
			break;
		case 0x09:
			retStr = @"连续认证失败次数超过30次，密码键盘被锁定";
			break;
		case 0x0A:
			retStr = @"非法初始化";
			break;
		case 0x0B:
			retStr = @"非法探测保护";
			break;
		case 0x0D:
			retStr = @"EDC错误";
			break;
		case 0x0E:
			retStr = @"ESAM操作错误";
			break;
		case 0x0F:
			retStr = @"无卡";
			break;
		case 0x21:
			retStr = @"执行复位指令操作失败";
			break;
		case 0x31:
			retStr = @"错误目录号";
			break;
		case 0x41:
			retStr = @"随机数发生错误";
			break;
		case 0x51:
			retStr = @"非法主密钥ID或mode";
			break;
		case 0x52:
			retStr = @"当前目录错误";
			break;
		case 0x53:
			retStr = @"主密钥下载错误";
			break;
		case 0x54:
			retStr = @"写数据错";
			break;
		case 0x55:
			retStr = @"读数据错";
			break;
		case 0x56:
		case 0x57:
			retStr = @"超出存储空间";
			break;
		case 0x61:
			retStr = @"工作密钥ID错误";
			break;
		case 0x62:
			retStr = @"模式错误";
			break;
		case 0x63:
			retStr = @"指定的主密钥模式或ID错";
			break;
		case 0x64:
			retStr = @"密钥发散错";
			break;
		case 0x65:
			retStr = @"主密钥类型错误";
			break;
		case 0x66:
			retStr = @"主密钥截取错";
			break;
		case 0x67:
			retStr = @"密钥已经存在";
			break;
		case 0x68:
			retStr = @"密钥模式错";
			break;
		case 0x71:
			retStr = @"PIN加密密钥超过指定的使用次数";
			break;
		case 0x72:
			retStr = @"模式错误";
			break;
		case 0x73:
			retStr = @"PIN密钥ID非法";
			break;
		case 0x74:
			retStr = @"PIN的位数设置错";
			break;
		case 0x75:
			retStr = @"PIN加密错";
			break;
		case 0x76:
			retStr = @"PIN输入超时";
			break;
		case 0x77:
			retStr = @"用户取消PIN输入";
			break;
		case 0x78:
			retStr = @"第一次输入PIN与第二次输入PIN不相同";
			break;
		case 0x79:
			retStr = @"PINBLOCK算法设置错";
			break;
		case 0x7A:
			retStr = @"PIN输入相邻按键超时";
			break;
		case 0x7B:
			retStr = @"PIN 输入长度为0";
			break;
		case 0x7C:
			retStr = @"单位小时运算次数超过110次";
			break;
		case 0x7D:
			retStr = @"设置使用次数超出最大限制";
			break;
		case 0x81:
			retStr = @"加密ID或 mode非法";
			break;
		case 0x82:
			retStr = @"数据不是8的整数倍";
			break;
		case 0x83:
			retStr = @"MAC计算错误";
			break;
		case 0x91:
			retStr = @"模式错误";
			break;
		case 0x92:
			retStr = @"加解密失败";
			break;
		case 0xA1:
			retStr = @"DUKPT Load错";
			break;
		case 0xA2:
			retStr = @"计算器溢出";
			break;
		case 0xA3:
			retStr = @"更新DUKPT 21个新密钥错误";
			break;
		case 0xA4:
			retStr = @"存储DUKPT错误";
			break;
		case 0xA5:
			retStr = @"LoadinitKey 错误";
			break;
		case 0xA9:
			retStr = @"RTC 设置非法";
			break;
		case 0xAA:
			retStr = @"数据长度校验错";
			break;
		case 0xAB:
			retStr = @"接收数据内容校验错误";
			break;
		case 0xB1:
			retStr = @"RTC 设置失败";
			break;
		case 0xD1:
			retStr = @"LOG 操作越界";
			break;
		case 0xE1:
			retStr = @"UID 已经下载过了";
			break;
		case 0xFF:
			retStr = @"执行错误";
			break;
		default:
			retStr = [NSString stringWithFormat:@"未识别错误(%d)",errorCode];
    }
    return retStr;
}
- (NSString *)piccError:(Byte)errorCode
{
    NSString *retStr = nil;
    switch(errorCode){
        case 0x01:
            retStr = @"协议的长度错误";
            break;
        case 0x02:
            retStr = @"激活(上电)前未执行检测卡操作";
            break;
        case 0x03:
            retStr = @"感应区中有多于一张的Type PICC卡";
            break;
        case 0x04:
            retStr = @"Type A 卡 RATS 失败";
            break;
        case 0x05:
            retStr = @"设备操作失败";
            break;
        case 0x06:
            retStr = @"无卡";
            break;
        case 0x07:
            retStr = @"B 卡激活失败";
            break;
        case 0x0A:
            retStr = @"A 卡激活失败(可能多张卡存在)";
            break;
        case 0x0B:
            retStr = @"B 卡冲突(可能多张卡存在)";
            break;
        case 0x0C:
            retStr = @"A、B卡同时存在";
            break;
        case 0x0F:
            retStr = @"不支持 ISO14443-4 协议的卡, 比如 Mifare-1卡";
            break;
        case 0xFF:
            retStr = @"执行错误";
            break;
        default:
			retStr = [NSString stringWithFormat:@"未识别错误(%d)",errorCode];
    }
    return retStr;
}

/**
 * Pinpad取随机数
 * @param
 * @throws  Exception
 */
- (Byte *)getRand:(PinPadRequestType)type
{
    static Byte rand[8];
    
    Byte sendBytes[2];
    Byte receivedBytes[20];
    
    sendBytes[0] = 0xD0;
    sendBytes[1] = 0x00;
    
    int receivedLength = [self pinpadComm:sendBytes inLen:2 outBuff:receivedBytes requestType:type timeout:1];
    
    if (receivedLength <= 0)
        return nil;
    memcpy(rand, receivedBytes, 8);
    return rand;
}

-(Byte *)genAuthCode:(Byte *)data startIndex:(int)startIndex dataLength:(int)dataLength mode:(Byte)mode requestType:(PinPadRequestType)type
{
    static Byte authCode[8];
    
    Byte authMac[8];
    //异或 长度后到authcode前的数据
    memset(authMac, 0, sizeof(authMac));
    for(int i = 0; i < dataLength; i++){
        authMac[i % 8] ^= data[startIndex + i];
    }
    
    //byte[] random = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08};
    Byte *random = [self getRand:type];
    if (random == nil)
        return nil;
    
    //异或随机数
    for(int i = 0; i < 8; i++){
        authMac[i] ^= random[i];
    }
	
    //初始化时不需要异或uid
    if(mode == 0x01){
        for(int i = 0; i < 16; i++){
            authMac[i % 8] ^= uid[i];
        }
    }
    
    //3DES加密
    _vDes(TRI_ENCRYPT, authMac, authCodeKey, authCode);
    
    return authCode;
    
}

/**
 * Pinpad屏幕行显示
 * @param   clearScreen  0x01 清屏  0x00 不清屏
 * @param   alignment    0x01 左对齐  0x02 中间对齐  0x03 右对齐
 * @param   antiShow     0x00 正常显示  0x01 反显
 * @param   lineNum      行号
 * @param   displayString         显示数据
 * @throws  Exception
 */
-(int)pinpadDisp:(int)clearScreen alignment:(int)alignment antiShow:(int)antiShow lineNum:(int)lineNum displayString:(NSString*)displayString requestType:(PinPadRequestType)type
{
    
    Byte sendBytes[60];
    
    int count = 0;
    sendBytes[count++] = 0xE3;
    sendBytes[count++] = 0x00;
    sendBytes[count++] = 0x05 + displayString.length;
    sendBytes[count++] = 0x00;
    sendBytes[count++] = clearScreen;
    sendBytes[count++] = alignment;
    sendBytes[count++] = antiShow;
    sendBytes[count++] = lineNum;

    memcpy(sendBytes + count, [displayString cStringUsingEncoding:NSASCIIStringEncoding],displayString.length);
    count += displayString.length;
    
    if ([self pinpadComm:sendBytes inLen:count outBuff:nil requestType:type timeout:1] < 0)
        return 1;
    return 0;
}

- (int)changeDir:(int)dirNum requestType:(PinPadRequestType)type
{
    
    Byte sendBytes[3];
    
    sendBytes[0] = 0xD6;
    sendBytes[1] = 0x01;
    sendBytes[2] = dirNum;
    
    if ([self pinpadComm:sendBytes inLen:2 outBuff:nil requestType:type timeout:1] < 0)
        return 1;
    
    return 0;
}

-(void)pininputCancel
{
    Byte sendBytes[20];
    
    sendBytes[0] = 0x69;
    sendBytes[1] = 0x00;
    sendBytes[2] = 3;		//发送数据报文命令
    
    sendBytes[3] = 0;
    sendBytes[4] = 3;
    sendBytes[5] = 0x8E; //cancel command
    sendBytes[6] = 0x00; //data length
    sendBytes[7] = 0x8E; //bcc
    if ([_syncCommon bluetoothSendRecv:sendBytes dataLen:8 ResponseDataBuf:nil timeout:1])
        return;
    
    sendBytes[0] = 0x69;
    sendBytes[1] = 0x00;
    sendBytes[2] = 4;
    if ([_syncCommon bluetoothSendRecv:sendBytes dataLen:3 ResponseDataBuf:nil timeout:1])
        return;
}

-(int)pinpadComm:(unsigned char *)inBuff inLen:(int)len outBuff:(unsigned char *)outBuff requestType:(PinPadRequestType)type timeout:(int)timeout
{
    Byte chkCMD = inBuff[0];
    
    _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
    
    Byte sendBytes[600];
    Byte recvBytes[600];
    
    int packLength = 1+(len+2)*2;
    sendBytes[0] = 0x69;
    sendBytes[1] = 0x00;
    sendBytes[2] = 3;		//发送数据报文命令
    sendBytes[3] = (packLength/256);
    sendBytes[4] = (packLength%256);
    int bcc = 0;
    for (int i=0; i<len; i++) {
        bcc ^= inBuff[i];
        sendBytes[i+5] = inBuff[i];
    }
    sendBytes[5 + len] = bcc;
    
    int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:len + 6 ResponseDataBuf:recvBytes  timeout:timeout + 1];
    if (iRet > 0 && recvBytes[0]) {
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [self pinPadDelegateResponse:recvBytes[0] requestType:type responseData:nil error:[_syncCommon getErrorString:recvBytes+1 length:iRet-1]];
        return -1;
    }
    if(iRet < 0){
        if ([_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [self iMateDelegateNoResponse:@"iMate通讯超时"];
        return -1;
    }
    
    double timeSeconds = [self currentTimeSeconds] + timeout + 1;
    int recvLength = 0;
    BOOL finish = NO;
    while([self currentTimeSeconds] < timeSeconds){
        usleep(2000);
        if (cancelFlag) {
            [self pininputCancel];
            cancelFlag = NO;
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
                [self pinPadDelegateResponse:108 requestType:type responseData:nil error:@"取消输入密码"];
            return -2;
        }
        sendBytes[0] = 0x69;
        sendBytes[1] = 0x00;
        sendBytes[2] = 4;
        Byte pinPadBytes[600];
        iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:3 ResponseDataBuf:pinPadBytes timeout:1];
        if (iRet > 0 && pinPadBytes[0]) {
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
                [self pinPadDelegateResponse:pinPadBytes[0] requestType:type responseData:nil error:[_syncCommon getErrorString:pinPadBytes+1 length:iRet-1]];
            return -1;
        }
        if(iRet < 0){
            if ([_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [self iMateDelegateNoResponse:@"iMate通讯超时"];
            return -1;
        }else if(iRet == 1){
            continue;
        }
        memcpy(recvBytes + recvLength, pinPadBytes +1, iRet -1);
        recvLength += iRet-1;
        
        if((chkCMD >= (Byte)0xB0 && chkCMD <= (Byte)0xB5) || (chkCMD >= (Byte)0xE0 && chkCMD <= (Byte)0xE8)){
            if (recvLength != recvBytes[1] *256 + recvBytes[2] + 4)
                continue;
        }else{
            if (recvLength != recvBytes[1] + 3)
                continue;
        }
        finish = YES;
        break;
    }
    
    if(!finish){
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [self pinPadDelegateResponse:111 requestType:type responseData:nil error:@"Pinpad通讯超时"];
        return -2;
    }
    if(recvBytes[0] != chkCMD){
        Byte errorCode;
        NSString *error = nil;
        if((chkCMD >= (Byte)0xB0 && chkCMD <= (Byte)0xB5) || (chkCMD >= (Byte)0xE0 && chkCMD <= (Byte)0xE8)){
            errorCode = recvBytes[3];
            if(chkCMD == (Byte)0xB4 || chkCMD == (Byte)0xB3){
                error = [self piccError:errorCode];
            }else{
                error = [self pinpadError:errorCode];
            }
        }else{
            errorCode = recvBytes[2];
            error = [self pinpadError:errorCode];
        }
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [self pinPadDelegateResponse:112 requestType:type responseData:nil error:error];
        return -3;
    }
    
    if(outBuff) {
        if((chkCMD >= (Byte)0xB0 && chkCMD <= (Byte)0xB5) || (chkCMD >= (Byte)0xE0 && chkCMD <= (Byte)0xE8)){
            recvLength = recvBytes[1] * 256 + recvBytes[2];
            for(int i = 0; i < recvLength; i++){
                outBuff[i] = recvBytes[i + 3];
            }
        }else{
            recvLength = recvBytes[1];
            for(int i = 0; i < recvLength; i++){
                outBuff[i] = recvBytes[i + 2];
            }	
        }
    }
    return recvLength;
}

-(void)iMateDelegateNoResponse:(NSString *)error
{
    PinPadData *dataObject = [[PinPadData alloc] init];
    dataObject.retCode = -1;
    dataObject.errroStr = error;
    [self performSelectorOnMainThread:@selector(pinPadDelegateResponse:) withObject:dataObject waitUntilDone:YES];
}

-(void)pinPadDelegateResponse:(int)retCode requestType:(PinPadRequestType)type responseData:(NSData *)responseData error:(NSString *)error
{
    PinPadData *dataObject = [[PinPadData alloc] init];
    dataObject.retCode = retCode;
    dataObject.pinPadRequsetType = type;
    dataObject.responseData = responseData;
    dataObject.errroStr = error;
    [self performSelectorOnMainThread:@selector(pinPadDelegateResponse:) withObject:dataObject waitUntilDone:YES];
}

-(void)pinPadDelegateResponse:(PinPadData *)dataObject
{
    @autoreleasepool {
        if(!dataObject){
            return;
        }
        if(dataObject.retCode == -1){
            [_delegate iMateDelegateNoResponse:dataObject.errroStr];
        }else{
            [_delegate pinPadDelegateResponse:dataObject.retCode requestType:dataObject.pinPadRequsetType responseData:dataObject.responseData error:dataObject.errroStr];
        }        
    }
}

@end
