//
//  iMatePinPad.m
//  支持凯明扬Pinpad
//
//  Created by hxsmart on 13-8-8.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import "iMateKmyPinPad.h"
#import "EADSessionController.h"
#import "iMateAppFacePrivate.h"
#import "iMateAppFace+Pinpad.h"
#import "SyncCommon.h"
#import "PinpadObject.h"

static iMateKmyPinPad *sg_iMatePinPad = nil;

@interface iMateKmyPinPad(){
    volatile BOOL cancelFlag;
}
@property (nonatomic, strong) id<iMateAppFacePinpadDelegate>delegate;
@property (nonatomic, strong) EADSessionController *iMateEADSessionController;
@property (nonatomic, strong) SyncCommon *syncCommon;

@end

@implementation iMateKmyPinPad

-(id)initWithEADSession:(EADSessionController *)iMateEADSessionController
{
    self = [super init];
    if(self){
        _syncCommon = [SyncCommon syncCommon:iMateEADSessionController];
        _iMateEADSessionController = iMateEADSessionController;
        cancelFlag = NO;
    }
    return self;
}

+(iMateKmyPinPad *)imatePinPad:(EADSessionController *)iMateEADSessionController
{
    if(sg_iMatePinPad == nil){
        sg_iMatePinPad = [[iMateKmyPinPad alloc] initWithEADSession:iMateEADSessionController];
    }
    return sg_iMatePinPad;
}

-(void)cancel
{
    cancelFlag = YES;
    [self closePinPad];
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

-(void)pinpadVersion
{
    [self performSelectorInBackground:@selector(versionThread) withObject:nil];
}

-(void)downloadMasterKey:(int)algorithm index:(int)index masterKey:(Byte *)masterKey keyLength:(int)length
{
    PinPadObject *object = [[PinPadObject alloc] init];
    object.algorithm = algorithm;
    object.masterIndex = index;
    object.masterKey = [NSData dataWithBytes:masterKey length:length];
    object.masterLength = length;
    [self performSelectorInBackground:@selector(downloadMasterkeyThread:) withObject:object];
}

-(void)downloadWorkingKey:(int)algorithm masterIndex:(int)masterIndex workingIndex:(int)workingIndex workingKey:(Byte *)workingKey keyLength:(int)keyLength
{
    PinPadObject *object = [[PinPadObject alloc] init];
    object.algorithm = algorithm;
    object.masterIndex = masterIndex;
    object.workingIndex = workingIndex;
    object.workingKey = [NSData dataWithBytes:workingKey length:keyLength];
    object.workingLength = keyLength;
    [self performSelectorInBackground:@selector(downloadWorkingkeyThread:) withObject:object];
}

-(void)inputPinblock:(int)algorithm isAutoReturn:(BOOL)isAutoReturn masterIndex:(int)masterIndex workingIndex:(int)workingIndex cardNo:(NSString *)cardNo pinLength:(int)pinLength timeout:(int)timeout;
{
    PinPadObject *object = [[PinPadObject alloc] init];
    object.algorithm = algorithm;
    object.isAutoReturn = isAutoReturn;
    object.masterIndex = masterIndex;
    object.workingIndex = workingIndex;
    object.cardNo = cardNo;
    object.pinLength = pinLength;
    object.timeout = timeout;
    [self performSelectorInBackground:@selector(inputPinblockThread:) withObject:object];
}

-(void)encrypt:(int)algorithm cryptoMode:(int)cryptoMode masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength
{
    PinPadObject *object = [[PinPadObject alloc] init];
    object.algorithm = algorithm;
    object.cryptoMode = cryptoMode;
    object.masterIndex = masterIndex;
    object.workingIndex = workingIndex;
    object.data = [NSData dataWithBytes:data length:dataLength];
    object.dataLength = dataLength;
    [self performSelectorInBackground:@selector(encryptThread:) withObject:object];
}

-(void)mac:(int)algorithm masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength
{
    PinPadObject *object = [[PinPadObject alloc] init];
    object.algorithm = algorithm;
    object.masterIndex = masterIndex;
    object.workingIndex = workingIndex;
    object.data = [NSData dataWithBytes:data length:dataLength];
    object.dataLength = dataLength;
    [self performSelectorInBackground:@selector(macThread:) withObject:object];
}

-(void)hash:(int)hashAlgorithm data:(Byte *)data dataLength:(int)dataLength
{
    PinPadObject *object = [[PinPadObject alloc] init];
    object.algorithm = hashAlgorithm;
    object.data = [NSData dataWithBytes:data length:dataLength];
    object.dataLength = dataLength;
    [self performSelectorInBackground:@selector(hashThread:) withObject:object];
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
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [self pinPadDelegateResponse:retCode requestType:PinPadRequestTypePowerOff responseData:nil error:nil];
        }
    }
}

-(void)resetThread:(NSObject*)object
{
    @autoreleasepool {
        _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
        Byte sendBytes[2];
        sendBytes[0] = 0x31;
        sendBytes[1] = 0x38;
        int sendLength = 1;
        if(object){
            sendLength = 2;
        }
        int iRet = [self pinpadComm:sendBytes inLen:sendLength outBuff:nil requestType:PinPadRequestTypeReset timeout:2];
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
        Byte sendBytes[1];
        sendBytes[0] = 0x30;
        
        int iRet = [self pinpadComm:sendBytes inLen:1 outBuff:sResponseDataBuff requestType:PinPadRequestTypeVersion timeout:1];
        
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
		if (object.algorithm == 0 && object.masterLength!=8){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:101 requestType:PinPadRequestTypeDownloadMasterKey responseData:nil error:@"主密钥密钥长度错误"];
            }
            return;
        }
        
        Byte sendBytes[50];
        // 设置算法
		sendBytes[0] = 0x46;
		sendBytes[1] = 1;
		if (object.algorithm == 0)
			sendBytes[2] = 0x60; //DES
		else if (object.algorithm == 1)
			sendBytes[2] = 0x70; //3DES
        else if (object.algorithm == 2)
            sendBytes[2] = 0x90; //SM4
        
        int iRet = [self pinpadComm:sendBytes inLen:3 outBuff:nil requestType:PinPadRequestTypeDownloadMasterKey timeout:2];
        
        if(iRet < 0){
            return;
        }
        
        // 下载主密钥
		sendBytes[0] = 0x32;
		sendBytes[1] = (Byte)object.masterIndex;
		for (int i=0; i < object.masterLength; i++){
            
			sendBytes[2+i] = ((Byte*)(object.masterKey.bytes))[i];
        }
        iRet = [self pinpadComm:sendBytes inLen:object.masterLength + 2 outBuff:nil requestType:PinPadRequestTypeDownloadMasterKey timeout:2];
        if(iRet < 0){
            return;
        }
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
        
        Byte sendBytes[50];
        // 设置算法
        sendBytes[0] = 0x46;
        sendBytes[1] = 1;
        if (object.algorithm == 0)
            sendBytes[2] = 0x60; //DES
        else if (object.algorithm == 1)
            sendBytes[2] = 0x70; //3DES
        else if (object.algorithm == 2)
            sendBytes[2] = 0x90; //SM4
        
        int iRet = [self pinpadComm:sendBytes inLen:3 outBuff:nil requestType:PinPadRequestTypeDownloadWorkingKey timeout:2];
        
        if(iRet < 0){
            return;
        }
        
        // 下载工作密钥
		sendBytes[0] = 0x33;
		sendBytes[1] = (Byte)object.masterIndex;
        sendBytes[2] = (Byte)object.workingIndex;
		for (int i=0; i < object.workingLength; i++){
			sendBytes[3+i] = ((Byte*)(object.workingKey.bytes))[i];
        }
        iRet = [self pinpadComm:sendBytes inLen:object.workingLength + 3 outBuff:nil requestType:PinPadRequestTypeDownloadWorkingKey timeout:2];
        if(iRet < 0){
            return;
        }
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
        
		unsigned char sResponseDataBuff[100];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte sendBytes[100];
		// 复位自检
		sendBytes[0] = 0x31;
        int iRet = [self pinpadComm:sendBytes inLen:1 outBuff:sResponseDataBuff requestType:PinPadRequestTypeInputPinBlock timeout:1];
        
        if(iRet < 0){
            return;
        }
        
		//下装帐号
        NSData* byteData = [object.cardNo dataUsingEncoding:NSUTF8StringEncoding];
		Byte *orgAccount = (Byte*)[byteData bytes];
		sendBytes[0] = 0x34;
		for (int i=0; i<12; i++)
			sendBytes[i+1] = orgAccount[object.cardNo.length+i+3-16];
		iRet = [self pinpadComm:sendBytes inLen:13 outBuff:sResponseDataBuff requestType:PinPadRequestTypeInputPinBlock timeout:1];
        
        if(iRet < 0){
            return;
        }
		
        /*
		// 设置加密方式
		sendBytes[0] = 0x46;
		sendBytes[1] = 0x01;
		if (object.algorithm == 0)
			sendBytes[2] = 0x20; //DES
		else if (object.algorithm == 1)
			sendBytes[2] = 0x30; //3DES
        else if (object.algorithm == 2)
            sendBytes[2] = 0x80; //SM4
        */
        
        sendBytes[0] = 0x46;
        sendBytes[1] = 1;
        if (object.algorithm == 0) {
            if (object.workingIndex < 0)
                sendBytes[2] = 0x60;
            else
                sendBytes[2] = 0x20;
        }
        else if (object.algorithm == 1){
            if (object.workingIndex < 0)
                sendBytes[2] = 0x70;
            else
                sendBytes[2] = 0x30;
        }
        else if (object.algorithm == 2){
            if (object.workingIndex < 0)
                sendBytes[2] = 0x90;
            else
                sendBytes[2] = 0x80;
        }
		iRet = [self pinpadComm:sendBytes inLen:3 outBuff:sResponseDataBuff requestType:PinPadRequestTypeInputPinBlock timeout:1];
        
        if(iRet < 0){
            return;
        }
		
		// 不自动加回车
		sendBytes[0] = 0x46;
		sendBytes[1] = 0x05;
		if (object.isAutoReturn)
			sendBytes[2] = 0x01;
		else
			sendBytes[2] = 0x00;
		iRet = [self pinpadComm:sendBytes inLen:3 outBuff:sResponseDataBuff requestType:PinPadRequestTypeInputPinBlock timeout:1];
        
        if(iRet < 0){
            return;
        }
        
		// 激活工作密钥
		sendBytes[0] = 0x43;
		sendBytes[1] = (Byte)object.masterIndex;
		sendBytes[2] = (Byte)object.workingIndex;
		
		iRet = [self pinpadComm:sendBytes inLen:3 outBuff:sResponseDataBuff requestType:PinPadRequestTypeInputPinBlock timeout:1];
        
        if(iRet < 0){
            return;
        }
		
		// 启动密码键盘
		sendBytes[0] = 0x35;
		sendBytes[1] = (Byte)object.pinLength;
		sendBytes[2] = 0x01; //显示*
		sendBytes[3] = 1; //与CardNo一起运算后加密
		sendBytes[4] = 0; //不提示
		sendBytes[5] = (Byte)(object.timeout);
        
		iRet = [self pinpadComm:sendBytes inLen:6 outBuff:sResponseDataBuff requestType:PinPadRequestTypeInputPinBlock timeout:1];
        
        if(iRet < 0){
            [self closePinPad];
            return;
        }
		double tm = [self currentTimeSeconds] + object.timeout+1;
        double tm2 = 0;
        BOOL finished = NO;
		while ([self currentTimeSeconds] < tm) {
            if(cancelFlag){
                cancelFlag = NO;
                [self closePinPad];
                if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                    [self iMateDelegateNoResponse:@"取消操作"];
                return;
            }
			sendBytes[0] = 0x69;
			sendBytes[1] = 0x00;
			sendBytes[2] = 4;
            int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:3 ResponseDataBuf:sResponseDataBuff  timeout:2];
            //处理数据
            if (iRet > 0 && sResponseDataBuff[0]) {
                [self closePinPad];
                if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
                    [self pinPadDelegateResponse:sResponseDataBuff[0] requestType:PinPadRequestTypeInputPinBlock responseData:nil error:[_syncCommon getErrorString:sResponseDataBuff+1 length:iRet-1]];
                return;
            }
            if(iRet == -1){
                [self closePinPad];
                if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                    [self iMateDelegateNoResponse:@"iMate通讯超时"];
                return;
            }
            //下面代码为：输密码时，输密码的间隔时间超过5s就报超时错误
//            if (iRet > 1) {
//                tm2 = [self currentTimeSeconds] + 5;
//            }
//            if (tm2 && [self currentTimeSeconds] > tm2) {
//                [self closePinPad];
//                NSLog(@"iMate通讯超时====================  %f",[self currentTimeSeconds]-tm2);
//                if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
//                    [self iMateDelegateNoResponse:@"每位密码输入间隔时间过长"];
//                return;
//            }
		    for (int i=1; i < iRet; i++) {
		    	if (sResponseDataBuff[i] == 0x1b ) {
                    [self closePinPad];
                    if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                        [self pinPadDelegateResponse:104 requestType:PinPadRequestTypeInputPinBlock responseData:nil error:@"取消"];
                    }
		    		return;
		    	}
		    	if (sResponseDataBuff[i] == 8 ) {
                    tm2 = 0;
		    		continue;
		    	}
		    	if (sResponseDataBuff[i] == 0x0d ) {
		    		finished = YES;
		    		break;
		    	}
//                NSLog(@"%02x", sResponseDataBuff[i]);
		    }
		    if ( finished)
		    	break;
		}        
		if (!finished){
            [self closePinPad];
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:105 requestType:PinPadRequestTypeInputPinBlock responseData:nil error:@"密码输入超时"];
            }
            return;
        }
		
		// 获取密码密文
		sendBytes[0] = 0x42;
		iRet = [self pinpadComm:sendBytes inLen:1 outBuff:sResponseDataBuff requestType:PinPadRequestTypeInputPinBlock timeout:2];
        if(iRet < 0){
            [self closePinPad];
            return;
        }
        //NSLog(@"iRet = %d", iRet);
        
        //for(int i = 0; i < iRet; i++)
        //    NSLog(@"%02x",sResponseDataBuff[i]);
        
		if (iRet < 8){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:106 requestType:PinPadRequestTypeInputPinBlock responseData:nil error:@"Pinblock长度错误"];
            }
            return;
        }
        int blockLen = object.algorithm != 2 ? 8 : 16;
		if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeInputPinBlock responseData:[NSData dataWithBytes:sResponseDataBuff length: blockLen] error:nil];
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
        unsigned char sResponseDataBuff[600];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        // 激活密钥
        Byte sendBytes[600];
		sendBytes[0] = 0x43;
		sendBytes[1] = (Byte)object.masterIndex;
		if (object.workingIndex < 0)
			sendBytes[2] = 0x00;
		else
			sendBytes[2] = (Byte)object.workingIndex;
		int iRet = [self pinpadComm:sendBytes inLen:3 outBuff:sResponseDataBuff requestType:PinPadRequestTypeEncrypt timeout:1];
        if(iRet < 0){
            return;
        }
        
		// 设置算法
		sendBytes[0] = 0x46;
		sendBytes[1] = 1;
		if (object.algorithm == 0) {
			if (object.workingIndex < 0)
				sendBytes[2] = 0x60;
			else
				sendBytes[2] = 0x20;
		}
		else if (object.algorithm == 1){
			if (object.workingIndex < 0)
				sendBytes[2] = 0x70;
			else
				sendBytes[2] = 0x30;
		}
        else if (object.algorithm == 2){
            if (object.workingIndex < 0)
                sendBytes[2] = 0x90;
            else
                sendBytes[2] = 0x80;
        }
		iRet = [self pinpadComm:sendBytes inLen:3 outBuff:sResponseDataBuff requestType:PinPadRequestTypeEncrypt timeout:1];
        if(iRet < 0){
            return;
        }
        
		// 启动加解密
		if (object.cryptoMode == ALGO_ENCRYPT)
			sendBytes[0] = 0x36;
		else
			sendBytes[0] = 0x37;
		for (int i=0; i<object.dataLength; i++) {
			sendBytes[i+1] =  ((Byte*)(object.data.bytes))[i];
		}
        iRet = [self pinpadComm:sendBytes inLen:1 + object.dataLength outBuff:sResponseDataBuff requestType:PinPadRequestTypeEncrypt timeout:4];
        if(iRet < 0){
            return;
        }

		if (iRet < 8 ){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:108 requestType:PinPadRequestTypeEncrypt responseData:nil error:@"加解密数据失败"];
            }
        }
		if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeEncrypt responseData:[NSData dataWithBytes:sResponseDataBuff length:iRet] error:nil];
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
        unsigned char sResponseDataBuff[100];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte sendBytes[600];
        
        sendBytes[0] = 0x46;
        sendBytes[1] = 1;
        if (object.algorithm == 0) {
            if (object.workingIndex < 0)
                sendBytes[2] = 0x60;
            else
                sendBytes[2] = 0x20;
        }
        else if (object.algorithm == 1){
            if (object.workingIndex < 0)
                sendBytes[2] = 0x70;
            else
                sendBytes[2] = 0x30;
        }
        else if (object.algorithm == 2){
            if (object.workingIndex < 0)
                sendBytes[2] = 0x90;
            else
                sendBytes[2] = 0x80;
        }        
        int iRet = [self pinpadComm:sendBytes inLen:3 outBuff:sResponseDataBuff requestType:PinPadRequestTypeMac timeout:1];
        if(iRet < 0){
            return;
        }
		
		// 激活密钥
		sendBytes[0] = 0x43;
		sendBytes[1] = (Byte)object.masterIndex;
		if (object.workingIndex < 0)
			sendBytes[2] = 0x00;
		else
			sendBytes[2] = (Byte)object.workingIndex;
        
        iRet = [self pinpadComm:sendBytes inLen:3 outBuff:sResponseDataBuff requestType:PinPadRequestTypeMac timeout:1];
        if(iRet < 0){
            return;
        }
		
		// 启动计算Mac
		sendBytes[0] = 0x41;
		for (int i=0; i<object.dataLength; i++) {
			sendBytes[i+1] =  ((Byte*)(object.data.bytes))[i];
		}
        
        iRet = [self pinpadComm:sendBytes inLen:1+object.dataLength outBuff:sResponseDataBuff requestType:PinPadRequestTypeMac timeout:4];
        if(iRet < 0){
            return;
        }
        
		if (iRet < 8){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:110 requestType:PinPadRequestTypeMac responseData:nil error:@"计算Mac失败"];
            }
        }
		
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeMac responseData:[NSData dataWithBytes:sResponseDataBuff length:iRet] error:nil];
        }
    }
}

-(void)hashThread:(PinPadObject *)object
{
    @autoreleasepool {
        _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
        if (object.dataLength < 1){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:109 requestType:PinPadRequestTypeMac responseData:nil error:@"计算hash数据长度错误"];
            }
            return;
        }
        unsigned char sResponseDataBuff[100];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte sendBytes[2000];
        
        sendBytes[0] = 0x46;
        sendBytes[1] = 0x08;
        if (object.algorithm == 1) {
            sendBytes[2] = 0x01;
        }
        else {
            sendBytes[2] = 0x03;
        }
        int iRet = [self pinpadComm:sendBytes inLen:3 outBuff:sResponseDataBuff requestType:PinPadRequestTypeMac timeout:1];
        if(iRet < 0){
            return;
        }
        
        Byte head[10];
        
        // Has Init
        head[0] = 0xC4;
        memcpy(head + 1, "0000", 4);

        sendBytes[0] = 0x00;
        sendBytes[1] = 0x00;

        iRet = [self pinpadComm2:head inBuff:sendBytes inLen:2 outBuff:nil requestType:PinPadRequestTypeHash timeout:4];
        if(iRet < 0){
            return;
        }
        
        // Update
        int sentLength = 0;
        while (sentLength < object.dataLength) {

            head[0] = 0xC4;
            int packLen = (object.dataLength - sentLength) > 512 ? 512 : object.dataLength - sentLength;
            sprintf(head + 1, "%04d", packLen);
            
            sendBytes[0] = 0x01;
            sendBytes[1] = 0x00;
            memcpy(sendBytes + 2, object.data.bytes + sentLength, packLen);
            
            iRet = [self pinpadComm2:head inBuff:sendBytes inLen:2 + packLen outBuff:nil requestType:PinPadRequestTypeHash timeout:4];
            if(iRet < 0){
                return;
            }
            sentLength += packLen;
        }
        
        // Final
        head[0] = 0xC4;
        memcpy(head + 1, "0000", 4);
        
        sendBytes[0] = 0x02;
        sendBytes[1] = 0x00;
        
        iRet = [self pinpadComm2:head inBuff:sendBytes inLen:2 outBuff:sResponseDataBuff requestType:PinPadRequestTypeHash timeout:4];
        if(iRet < 0){
            return;
        }
        
        //NSLog(@"iRet = %d", iRet);
        
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeHash responseData:[NSData dataWithBytes:sResponseDataBuff length:iRet] error:nil];
        }
    }
}


-(double)currentTimeSeconds
{
    NSTimeInterval time= [[NSDate date] timeIntervalSince1970];
    return (double)time;
}

-(int)pinpadComm:(unsigned char *)inBuff inLen:(int)len outBuff:(unsigned char *)outBuff requestType:(PinPadRequestType)type timeout:(int)timeout
{
    Byte tempBytes[300];
    Byte bcc = (Byte)len;
    for (int i=0; i<len; i++)
        bcc ^= inBuff[i];
    tempBytes[0] = len;
    memcpy(tempBytes+1, inBuff, len);
    tempBytes[len + 1] = bcc;
    
    _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
    
    NSString *packData = [iMateAppFace oneTwoData:[NSData dataWithBytes:tempBytes length:len + 2]];
    
    //NSLog(@"pinpadComm:%@", packData);
    
    Byte sendBytes[600];
    Byte recvBytes[600];
    
    int packLength = 1+(len+2)*2;
    sendBytes[0] = 0x69;
    sendBytes[1] = 0x00;
    sendBytes[2] = 3;		//发送数据报文命令
    sendBytes[3] = (packLength/256);
    sendBytes[4] = (packLength%256);
    sendBytes[5] = 0x02;
    
    memcpy(sendBytes + 6, packData.UTF8String, packData.length);
    int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:(int)packData.length + 6 ResponseDataBuf:recvBytes  timeout:1];
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
    NSData *data = nil;
    int retLength = 0;
    int pinPadRetCode = -1;
    memset(recvBytes, 0, sizeof(recvBytes));
    while([self currentTimeSeconds] < timeSeconds){
        usleep(2000);
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
        
        if(recvLength < 5){
            continue;
        }
        
        //NSLog(@"recvBytes = %s", recvBytes + 1);

        if (recvBytes[0] == 0x02 ) {
            Byte buff[5];
            memcpy(buff, recvBytes + 1, 4);
            buff[4] = 0;
            NSData *buffData = [iMateAppFace twoOneData:[NSString stringWithUTF8String:(const char *)buff]];
            if(!buffData){
                finish = NO;
                break;
            }
            pinPadRetCode = ((Byte *)(buffData.bytes))[1];
            retLength = ((Byte *)(buffData.bytes))[0];
            if (recvLength >= (retLength+2)*2 + 1) {
                NSData *recvData = [[NSData alloc] initWithBytes:recvBytes + 5 length:(retLength - 1) * 2];
                NSString *aString = [[NSString alloc] initWithData:recvData encoding:NSUTF8StringEncoding];
                data = [iMateAppFace twoOneData:aString];
                finish = YES;
                break;
            }
        }
    }
    
    if(!finish){
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [self pinPadDelegateResponse:111 requestType:type responseData:nil error:@"Pinpad通讯超时"];
        return -2;
    }
    
    if (pinPadRetCode != 4 && pinPadRetCode != 0xa4) { //0xa4
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [self pinPadDelegateResponse:112 requestType:type responseData:nil error:@"Pinpad处理失败"];
        return -3;
    }
    if(outBuff){
        memcpy(outBuff, data.bytes, retLength-1);
    }
    return retLength -1;
}

-(int)pinpadComm2:(unsigned char *)head inBuff:(Byte*)inBuff inLen:(int)len outBuff:(unsigned char *)outBuff requestType:(PinPadRequestType)type timeout:(int)timeout
{
    Byte tempBytes[20];
    Byte bcc = 0x05;
    for (int i=0; i < 5; i++)
        bcc ^= head[i];
    tempBytes[0] = 5;
    memcpy(tempBytes+1, head, 5);
    tempBytes[6] = bcc;
    //memcpy(tempBytes + 7, inBuff, len);
    
    _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
    
    NSString *packData = [iMateAppFace oneTwoData:[NSData dataWithBytes:tempBytes length:7]];
    
    //NSLog(@"pinpadComm:%@", packData);
    
    Byte sendBytes[3000];
    Byte recvBytes[600];
    
    int packLength = 1 + 14 + len;
    sendBytes[0] = 0x69;
    sendBytes[1] = 0x00;
    sendBytes[2] = 3;		//发送数据报文命令
    sendBytes[3] = (packLength/256);
    sendBytes[4] = (packLength%256);
    sendBytes[5] = 0x02;
    memcpy(sendBytes + 6, packData.UTF8String, 14);
    memcpy(sendBytes + 6 + 14, inBuff, len);
    
    int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:14 + len + 6 ResponseDataBuf:recvBytes  timeout:1];
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
    NSData *data = nil;
    int retLength = 0;
    int pinPadRetCode = -1;
    memset(recvBytes, 0, sizeof(recvBytes));
    while([self currentTimeSeconds] < timeSeconds){
        usleep(2000);
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
        
        if(recvLength < 15){
            continue;
        }
        //NSLog(@"(%d)recvBytes = %s", recvLength, recvBytes + 1);
        
        if (recvBytes[0] == 0x02 ) {
            Byte buff[15];
            memcpy(buff, recvBytes + 1, 14);
            buff[14] = 0;
            NSData *buffData = [iMateAppFace twoOneData:[NSString stringWithUTF8String:(const char *)buff]];
            if(!buffData){
                finish = NO;
                break;
            }
            pinPadRetCode = ((Byte *)(buffData.bytes))[1];
            memcpy(buff, buffData.bytes + 2, 4);
            buff[4] = 0;
            //NSLog(@"buff = %s", buff);
            retLength = atoi(buff);
            if (retLength >= recvLength - 15) {
                if (retLength) {
                    data = [[NSData alloc] initWithBytes:recvBytes + 15 length:recvLength];
                }
                finish = YES;
                break;
            }
        }
    }
    
    if(!finish){
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [self pinPadDelegateResponse:111 requestType:type responseData:nil error:@"Pinpad通讯超时"];
        return -2;
    }
    
    if (pinPadRetCode != 4 && pinPadRetCode != 0xa4) { //0xa4
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [self pinPadDelegateResponse:112 requestType:type responseData:nil error:@"Pinpad处理失败"];
        return -3;
    }
    if(outBuff && data){
        memcpy(outBuff, data.bytes, retLength);
    }
    return retLength;
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
