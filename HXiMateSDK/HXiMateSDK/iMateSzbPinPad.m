//
//  iMateKeyuPinPad.m
//  支持苏州银行定制Pinpad
//
//  Created by hxsmart on 13-8-8.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import "iMateSzbPinPad.h"
#import "EADSessionController.h"
#import "iMateAppFacePrivate.h"
#import "iMateAppFace+Pinpad.h"
#import "SyncCommon.h"
#import "PinpadObject.h"

static iMateSzbPinPad *sg_iMatePinPad = nil;

@interface iMateSzbPinPad() {
    volatile BOOL cancelFlag;
}
@property (nonatomic, strong) id<iMateAppFacePinpadDelegate>delegate;
@property (nonatomic, strong) EADSessionController *iMateEADSessionController;
@property (nonatomic, strong) SyncCommon *syncCommon;

@end

@implementation iMateSzbPinPad

-(id)initWithEADSession:(EADSessionController *)iMateEADSessionController
{
    self = [super init];
    if(self){
        _syncCommon = [SyncCommon syncCommon:iMateEADSessionController];
        _iMateEADSessionController = iMateEADSessionController;
    }
    return self;
}

+(iMateSzbPinPad *)imatePinPad:(EADSessionController *)iMateEADSessionController
{
    if(sg_iMatePinPad == nil){
        sg_iMatePinPad = [[iMateSzbPinPad alloc] initWithEADSession:iMateEADSessionController];
    }
    return sg_iMatePinPad;
}

//获取设备序列号
-(void)pinPadGetProductSN
{
    
}

-(void)cancel
{
    cancelFlag = YES;
    [self cancelThread];
}

-(void)powerOn
{
    cancelFlag = YES;
    [self performSelectorInBackground:@selector(powerOnThread) withObject:nil];
}

-(void)powerOff
{
    cancelFlag = YES;
    [self performSelectorInBackground:@selector(powerOffThread) withObject:nil];
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

/**
 * Pinpad输入密码（PinBlock）
 * is3des               是否采用3DES算法，false表示使用DES算法
 * isAutoReturn         输入到约定长度时是否自动返回（不需要按Enter)
 * masterIndex          主密钥索引, 当 masterIndex < 0, 将获取明文Pin
 * workingIndex         工作密钥索引
 * cardNo               卡号/帐号（最少12位数字, 如果cardNo为nil，语音提示为"请再输入一次"，使用上次传入的卡号。
 *                      --- 如获取明文密码，cardNo也需要，使用规则和Pinblock相同。
 * pinLength            需要输入PIN的长度
 * timeout              输入密码等待超时时间 <= 255 秒
 */
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

-(void)cancelThread
{
    @autoreleasepool {
        unsigned char sResponseDataBuff[20];
        Byte sendBytes[7];
        sendBytes[0] = 0x69;
        sendBytes[1] = 0x00;
        sendBytes[2] = 3;		//发送数据报文命令
        sendBytes[3] = 0;
        sendBytes[4] = 2;
        sendBytes[5] = 0x1b;
        sendBytes[6] = 0x30;
        [_syncCommon bluetoothSendRecv:sendBytes dataLen:7 ResponseDataBuf:sResponseDataBuff timeout:1];
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

-(void)versionThread
{
    @autoreleasepool {
        _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
        
        unsigned char sResponseDataBuff[100];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte sendBytes[4];
        sendBytes[0] = 0x1b;
        sendBytes[1] = 0x56;
        sendBytes[2] = 0x0d;
        sendBytes[3] = 0x0a;
        
        int iRet = [self pinpadComm:sendBytes inLen:4 outBuff:sResponseDataBuff requestType:PinPadRequestTypeVersion timeout:1];
        
        if(iRet < 0){
            return;
        }
        
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
            [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeVersion responseData:[NSData dataWithBytes:sResponseDataBuff length:iRet] error:nil];
        }
    }
}

-(void)downloadMasterkeyThread:(PinPadObject *)object
{
    @autoreleasepool {
        _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
        
        if (!object.algorithm){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:101 requestType:PinPadRequestTypeDownloadMasterKey responseData:nil error:@"不支持单DES算法"];
            }
            return;
        }
        if (object.masterLength != 16 && object.masterLength != 24){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:100 requestType:PinPadRequestTypeDownloadMasterKey responseData:nil error:@"主密钥密钥长度错误, 应为16字节或24字节"];
            }
            return;
        }
        if (object.masterIndex < 0 || object.masterIndex > 7){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:102 requestType:PinPadRequestTypeDownloadMasterKey responseData:nil error:@"主密钥索引错误"];
            }
            return;
        }
        
        Byte receivedBytes[50];
        Byte sendBytes[50];
        // 下载主密钥
		sendBytes[0] = 0x1b;
		sendBytes[1] = 0x6d;
		sendBytes[2] = 0x30;
		sendBytes[3] = [self oneTwoByte:object.masterIndex hight:NO];
		sendBytes[4] = [self oneTwoByte:object.masterLength hight:YES];
		sendBytes[5] = [self oneTwoByte:object.masterLength hight:NO];
        for (int i = 0; i < object.masterLength; i++) {
            sendBytes[6 + i * 2] = [self oneTwoByte:((Byte*)(object.masterKey.bytes))[i] hight:YES];
            sendBytes[6 + i * 2 + 1] = [self oneTwoByte:((Byte*)(object.masterKey.bytes))[i] hight:NO];
        }
		sendBytes[6 + object.masterLength * 2] = 0x0d;
		sendBytes[6 + object.masterLength * 2 + 1] = 0x0a;
        
        memset(receivedBytes, 0, sizeof(receivedBytes));
        int iRet = [self pinpadComm:sendBytes inLen:object.masterLength*2 + 8 outBuff:receivedBytes requestType:PinPadRequestTypeDownloadMasterKey timeout:2];
        if(iRet < 0){
            return;
        }
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeDownloadMasterKey responseData:[NSData dataWithBytes:receivedBytes length:iRet] error:nil];
        }
    }
}

-(void)downloadWorkingkeyThread:(PinPadObject *)object
{
    @autoreleasepool {
        _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
        
        if (!object.algorithm){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:101 requestType:PinPadRequestTypeDownloadWorkingKey responseData:nil error:@"不支持单DES算法"];
            }
            return;
        }
        if (object.workingLength != 16 + 4 && object.workingLength != 24 + 4){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:102 requestType:PinPadRequestTypeDownloadWorkingKey responseData:nil error:@"工作密钥长度错误, 应为16+4字节长度"];
            }
            return;
        }
        if (object.masterIndex < 0 || object.masterIndex > 7){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:103 requestType:PinPadRequestTypeDownloadMasterKey responseData:nil error:@"主密钥索引错误"];
            }
            return;
        }
        if (object.workingIndex < 0 || object.workingIndex > 7){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:104 requestType:PinPadRequestTypeDownloadMasterKey responseData:nil error:@"工作密钥索引错误"];
            }
            return;
        }
        
        Byte receivedBytes[50];
        Byte sendBytes[50];
		sendBytes[0] = 0x1b;
		sendBytes[1] = 0x6b;
		sendBytes[2] = 0x30;
		sendBytes[3] = [self oneTwoByte:object.masterIndex hight:NO];
		sendBytes[4] = 0x30;
		sendBytes[5] = [self oneTwoByte:object.workingIndex hight:NO];
		sendBytes[6] = [self oneTwoByte:object.workingLength - 4 hight:YES];
		sendBytes[7] = [self oneTwoByte:object.workingLength - 4 hight:NO];
        for (int i = 0; i < object.workingLength; i++) {
            sendBytes[8 + i * 2] = [self oneTwoByte:((Byte*)(object.workingKey.bytes))[i] hight:YES];
            sendBytes[8 + i * 2 + 1] = [self oneTwoByte:((Byte*)(object.workingKey.bytes))[i] hight:NO];
        }
		sendBytes[8 + object.workingLength * 2] = 0x0d;
		sendBytes[8 + object.workingLength * 2 + 1] = 0x0a;
        
        memset(receivedBytes, 0, sizeof(receivedBytes));
        int iRet = [self pinpadComm:sendBytes inLen:object.workingLength*2 + 10 outBuff:receivedBytes requestType:PinPadRequestTypeDownloadWorkingKey timeout:2];
        if(iRet < 0){
            return;
        }
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeDownloadWorkingKey responseData:nil error:nil];
        }
    }
}

-(void)inputPinblockThread:(PinPadObject *)object
{
    static NSString *lastCardNo = @"0000000000000";
    @autoreleasepool {
        _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
        
        if (object.cardNo && object.cardNo.length < 13){
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:103 requestType:PinPadRequestTypeInputPinBlock responseData:nil error:@"卡号/帐号长度错误"];
            }
            return;
        }
        Byte receivedBytes[50];
        Byte sendBytes[50];
        
        BOOL retryPrompt = YES;
        if (object.cardNo) {
            lastCardNo = object.cardNo;
            retryPrompt = NO;
        }
        
        int iRet = -1;
        if (object.masterIndex >= 0) {
            //设置密钥长度
            sendBytes[0] = 0x1b;
            sendBytes[1] = 0x4e;
            sendBytes[2] = 0x30;
            sendBytes[3] = [self oneTwoByte:object.pinLength hight:NO];
            sendBytes[4] = 0x0d;
            sendBytes[5] = 0x0a;
            iRet = [self pinpadComm:sendBytes inLen:6 outBuff:receivedBytes requestType:PinPadRequestTypeInputPinBlock timeout:1];
            if(iRet < 0) {
                return;
            }
            // X9.8pinblock
            sendBytes[0] = 0x1b;
            sendBytes[1] = 0x4a;
            sendBytes[2] = 0x30; //masterkey index
            sendBytes[3] = [self oneTwoByte:object.masterIndex hight:NO];
            sendBytes[4] = 0x30; //workingkey index
            sendBytes[5] = [self oneTwoByte:object.workingIndex hight:NO];
            if (!retryPrompt) {
                sendBytes[6] = 0x30;
                sendBytes[7] = 0x30;
            }
            else {
                sendBytes[6] = 0x30;
                sendBytes[7] = 0x31;
            }
            
            NSData* byteData = [lastCardNo dataUsingEncoding:NSUTF8StringEncoding];
            Byte *orgAccount = (Byte*)[byteData bytes];
            for (int i=0; i<12; i++)
                sendBytes[8 + i] = orgAccount[lastCardNo.length+i+3-16];
            
            sendBytes[8 + 12] = 0x0d;
            sendBytes[8 + 12 + 1] = 0x0a;
            
            memset(receivedBytes, 0, sizeof(receivedBytes));
            iRet = [self pinpadComm:sendBytes inLen:22 outBuff:receivedBytes requestType:PinPadRequestTypeInputPinBlock timeout:object.timeout + 1];
            if(iRet < 0){
                [self cancel];
                return;
            }
            NSData *pinblock = [iMateAppFace twoOneData:[NSString stringWithFormat:@"%s", receivedBytes + 2]];
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeInputPinBlock responseData:pinblock error:nil];
            }
        }
        else {
            if (object.cardNo) {
                // 语音提示：请输入密码
                sendBytes[0] = 0x1b;
                sendBytes[1] = 0x49;
            }
            else {
                // 语音提示：再输入一次
                sendBytes[0] = 0x1b;
                sendBytes[1] = 0x45;
            }
            
            memset(receivedBytes, 0, sizeof(receivedBytes));
            iRet = [self pinpadComm:sendBytes inLen:2 outBuff:receivedBytes requestType:PinPadRequestTypeInputPinBlock timeout:object.timeout + 1];
            if(iRet < 0) {
                [self cancel];
                return;
            }
            NSData *pinData = [NSData dataWithBytes:receivedBytes length: iRet];
            
            if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [self pinPadDelegateResponse:0 requestType:PinPadRequestTypeInputPinBlock responseData:pinData error:nil];
            }
        }
    }
}
            
- (Byte)oneTwoByte:(Byte)theByte hight:(BOOL)hight
{
    Byte ch;
    if (hight)
        ch = theByte >> 4;
    else
        ch = theByte & 0x0F;
    
    if (ch >= 0x0a)
        return 0x37 + ch;
    return 0x30 + ch;
}

-(double)currentTimeSeconds
{
    NSTimeInterval time= [[NSDate date] timeIntervalSince1970];
    return (double)time;
}

-(int)pinpadComm:(unsigned char *)inBuff inLen:(int)len outBuff:(unsigned char *)outBuff requestType:(PinPadRequestType)type timeout:(int)timeout
{
    _delegate = (id<iMateAppFacePinpadDelegate>)[[iMateAppFace sharedController] delegate];
    
    Byte sendBytes[600];
    Byte recvBytes[600];
    
    sendBytes[0] = 0x69;
    sendBytes[1] = 0x00;
    sendBytes[2] = 3;		//发送数据报文命令
    sendBytes[3] = (len/256);
    sendBytes[4] = (len%256);
    memcpy(sendBytes + 5,inBuff, len);
    int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:len + 5 ResponseDataBuf:recvBytes  timeout:timeout + 1];
    if (iRet > 0 && recvBytes[0]) {
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [self pinPadDelegateResponse:recvBytes[0] requestType:type responseData:nil error:[_syncCommon getErrorString:recvBytes+1 length:iRet-1]];
        return -1;
    }
    if(iRet < 0) {
        if ([_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [self iMateDelegateNoResponse:@"iMate通讯超时"];
        return -1;
    }
    
    double timeSeconds = [self currentTimeSeconds] + timeout + 1;
    int recvLength = 0;
    BOOL finish = NO;
    int retLength = 0;
    cancelFlag = NO;
    int offset = 0;
    while([self currentTimeSeconds] < timeSeconds){
        if (cancelFlag) {
            if ([_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [self iMateDelegateNoResponse:@"Pinpad取消输入密码"];
            return -3;
        }
        //usleep(2000);
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
        if(iRet < 0) {
            if ([_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [self iMateDelegateNoResponse:@"iMate通讯超时"];
            return -1;
        }else if(iRet == 1) {
            continue;
        }
        memcpy(recvBytes + recvLength, pinPadBytes + 1, iRet -1);
        recvLength += iRet-1;
        
        if (recvLength == 1 && recvBytes[0] == 0x80){ //pinpad timeout
            if ([_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [self iMateDelegateNoResponse:@"Pinpad输入密码超时"];
            return -2;
        }

        if(recvLength ==0 || recvBytes[recvLength-1] != 0x03){
            continue;
        }
        
        finish = YES;
        break;
    }
    
    if (!finish) {
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [self pinPadDelegateResponse:111 requestType:type responseData:nil error:@"Pinpad通讯超时"];
        return -2;
    }

    for (int i = 0; i < recvLength; i++) {
        if (recvBytes[i] == 0x02) {
            offset = i;
            break;
        }
    }
    retLength = recvLength - offset -2;
    if (memcmp(recvBytes + 1 + offset, "ER", 2) == 0) {
        if ( [_delegate respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] )
            [self pinPadDelegateResponse:113 requestType:type responseData:nil error:@"Pinpad处理失败"];
        return -3;
    }
    if(outBuff) {
        memcpy(outBuff, recvBytes + 1 + offset, retLength);
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
        if(!dataObject) {
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
