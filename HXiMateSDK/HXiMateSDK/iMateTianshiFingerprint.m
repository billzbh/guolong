//
//  iMateJsabcFingerprint.m
//  支持浙江维尔(江苏农行）
//
//  Created by hxsmart on 13-8-8.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import "iMateTianshiFingerprint.h"
#import "EADSessionController.h"
#import "iMateAppFacePrivate.h"
#import "iMateAppFace+Fingerprint.h"
#import "SyncCommon.h"

static iMateTianshiFingerprint *sg_iMateFingerprint = nil;

@interface iMateTianshiFingerprint() {
    volatile BOOL cancelFlag;
    int FINGERPRINT_COMM_PORT;      //3           //指纹模块连接iMate内部端口号-通讯编号
    int FINGERPRINT_POWER_PORT;     //2           //指纹模块连接iMate内部端口号-电源编号
    NSString* COMPANY_VERSION;
    NSString* DEVICE_VERSION;
}

@property (nonatomic, strong) id<iMateAppFaceFingerprintDelegate>delegate;
@property (nonatomic, strong) EADSessionController *iMateEADSessionController;
@property (nonatomic, strong) SyncCommon *syncCommon;

@end

@implementation iMateTianshiFingerprint

-(id)initWithEADSession:(EADSessionController *)iMateEADSessionController
{
    self = [super init];
    if(self){
        _syncCommon = [SyncCommon syncCommon:iMateEADSessionController];
        _iMateEADSessionController = iMateEADSessionController;
        cancelFlag = NO;
        
        FINGERPRINT_COMM_PORT = 4;           //缺省值：iMate指纹模块连接iMate内部端口号-通讯编号
        FINGERPRINT_POWER_PORT = 4;          //缺省值：iMate指纹模块连接iMate内部端口号-电源编号
        
        DEVICE_VERSION = @"HXSMART_TS36EBG";
    }
    return self;
}

+(iMateTianshiFingerprint *)imateFingerprint:(EADSessionController *)iMateEADSessionController
{
    if(sg_iMateFingerprint == nil){
        sg_iMateFingerprint = [[iMateTianshiFingerprint alloc] initWithEADSession:iMateEADSessionController];
    }
    return sg_iMateFingerprint;
}

- (void)setupComport
{
    
    //deviceVersion 有可能为 nil ，这将会导致C函数 memcmp 终止，导致程序闪退。所以加判断。如果为nil，直接返回，使用缺省的端口号。by zbh 2015.1.29
    
    if ([iMateAppFace sharedController].deviceVersion == nil || [iMateAppFace sharedController].hardwareVersion == nil) {
        return;
    }
    //2015.1.29
    
    if (memcmp([iMateAppFace sharedController].deviceVersion.UTF8String, "IMATEMINI", 9) == 0 ||
        memcmp([iMateAppFace sharedController].hardwareVersion.UTF8String, "IMATE5.0", 8) == 0) {
        FINGERPRINT_COMM_PORT = 4;           //iMate指纹模块连接iMate内部端口号-通讯编号 = UART3_FP
        FINGERPRINT_POWER_PORT = 4;          //iMate指纹模块连接iMate内部端口号-电源编号 = Vuart_FP
    }
    else if (memcmp([iMateAppFace sharedController].deviceVersion.UTF8String, "IMATEIII", 8) == 0) {
        FINGERPRINT_COMM_PORT = 5;           //缺省值：iMate301指纹模块连接iMate内部端口号-通讯编号
        FINGERPRINT_POWER_PORT = 4;          //缺省值：iMate301指纹模块连接iMate内部端口号-电源编号
    }
    else if (memcmp([iMateAppFace sharedController].deviceVersion.UTF8String, "IMATE", 5) == 0) {
        FINGERPRINT_COMM_PORT = 3;           //缺省值：iMate指纹模块连接iMate内部端口号-通讯编号
        FINGERPRINT_POWER_PORT = 2;          //缺省值：iMate指纹模块连接iMate内部端口号-电源编号
    }
}

//取消 取指纹特征
-(void)cancel
{
    cancelFlag = YES;
}

-(void)powerOn
{
    [self setupComport];
    [self performSelectorInBackground:@selector(powerOnThread) withObject:nil];
}

-(void)powerOff
{
    [self setupComport];
    [self performSelectorInBackground:@selector(powerOffThread) withObject:nil];
}

-(void)fingerprintVersion
{
    [self setupComport];
    //[self performSelectorInBackground:@selector(versionThread) withObject:nil];
    if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
        [self fingerprintDelegateResponse:0 requestType:FingerprintRequestTypeVersion responseData:[DEVICE_VERSION dataUsingEncoding:NSUTF8StringEncoding] error:nil];
        //NSLog(@"%@", DEVICE_VERSION);
    }
}

-(void)takeFingerprintFeature
{
    [self setupComport];
    [self performSelectorInBackground:@selector(fingerprintFeatureThread) withObject:nil];
}

-(void)powerOnThread
{
    @autoreleasepool {
        _delegate = (id<iMateAppFaceFingerprintDelegate>)[[iMateAppFace sharedController] delegate];
        unsigned char sResponseDataBuff[100];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte sendBytes[9];
        
        // 先关闭指纹模块电源
        sendBytes[0] = 0x6A;
        sendBytes[1] = FINGERPRINT_COMM_PORT;
        sendBytes[2] = 0x02;
        sendBytes[3] = FINGERPRINT_POWER_PORT;
        if ([_syncCommon bluetoothSendRecv:sendBytes dataLen:4 ResponseDataBuf:sResponseDataBuff timeout:1] < 0) {
            return;
        }
        
        // 打开指纹模块电源
		sendBytes[0] = 0x6A;
		sendBytes[1] = FINGERPRINT_COMM_PORT;
		sendBytes[2] = 1;
		sendBytes[3] = ((FINGERPRINT_BAUDRATE >> 24) % 256);
		sendBytes[4] = ((FINGERPRINT_BAUDRATE >> 16) % 256);
		sendBytes[5] = ((FINGERPRINT_BAUDRATE >> 8) % 256);
		sendBytes[6] = (FINGERPRINT_BAUDRATE % 256);
		sendBytes[7] = FINGERPRINT_PARITY;
		sendBytes[8] = FINGERPRINT_POWER_PORT;
        
        int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:9 ResponseDataBuf:sResponseDataBuff timeout:1];
        //处理数据
        if (iRet > 0 && sResponseDataBuff[0]) {
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
                [self fingerprintDelegateResponse:sResponseDataBuff[0] requestType:FingerprintRequestTypePowerOn responseData:nil error:[_syncCommon getErrorString:sResponseDataBuff+1 length:iRet-1]];
            return;
        }
        if(iRet == -1){
            if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [self iMateDelegateNoResponse:@"iMate通讯超时"];
            return;
        }
        sleep(1);
        double timeSeconds = [self currentTimeSeconds] + 2;
        BOOL finish = NO;
        while([self currentTimeSeconds] < timeSeconds) {
            
            memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
            Byte *sendBytes = (Byte*)"\x61";
            int iRet = [self fingerprintComm:sendBytes inLen:1 outBuff:sResponseDataBuff requestType:FingerprintRequestTypePowerOn timeout:1];
            if(iRet < 0){
                continue;
            }
            //NSLog(@"%02x,%02x", sResponseDataBuff[0], sResponseDataBuff[1]);
            if (memcmp(sResponseDataBuff, "\x61\x00", 2) == 0) {
                finish = YES;
                break;
            }
        }
        int retCode = 0;
        NSString *error = nil;
        if (!finish) {
            retCode = 2;
            error = @"指纹模块检测失败";
        }
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            [self fingerprintDelegateResponse:retCode requestType:FingerprintRequestTypePowerOn responseData:nil error:error];
        }
    }
}

-(void)powerOffThread
{
    @autoreleasepool {
        _delegate = (id<iMateAppFaceFingerprintDelegate>)[[iMateAppFace sharedController] delegate];
        unsigned char sResponseDataBuff[20];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte sendBytes[4];
		sendBytes[0] = 0x6A;
		sendBytes[1] = FINGERPRINT_COMM_PORT;
		sendBytes[2] = 0x02;
		sendBytes[3] = FINGERPRINT_POWER_PORT;
        int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:4 ResponseDataBuf:sResponseDataBuff timeout:1];
        //处理数据
        if (iRet > 0 && sResponseDataBuff[0] != 0) {
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
                [self fingerprintDelegateResponse:sResponseDataBuff[0] requestType:FingerprintRequestTypePowerOff responseData:nil error:[_syncCommon getErrorString:sResponseDataBuff+1 length:iRet-1]];
            return;
        }
        if(iRet == -1){
            if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [self iMateDelegateNoResponse:@"iMate通讯超时"];
            return;
        }
        int retCode = sResponseDataBuff[0];
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ) {
            [self fingerprintDelegateResponse:retCode requestType:FingerprintRequestTypePowerOff responseData:nil error:nil];
        }
    }
}

-(void)versionThread
{
    @autoreleasepool {
        _delegate = (id<iMateAppFaceFingerprintDelegate>)[[iMateAppFace sharedController] delegate];
        
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            [self fingerprintDelegateResponse:0 requestType:FingerprintRequestTypeVersion responseData:[DEVICE_VERSION dataUsingEncoding:NSUTF8StringEncoding] error:nil];
            //NSLog(@"%@", DEVICE_VERSION);
        }
    }
}

-(int)buzzer
{
    Byte sendBytes[10];
    Byte recvBytes[10];
    
    sendBytes[0] = 0x03;
    return [_syncCommon bluetoothSendRecv:sendBytes dataLen:1 ResponseDataBuf:recvBytes  timeout:1];
}

-(void)fingerprintFeatureThread
{
    int ret, result;
    cancelFlag = NO;
    @autoreleasepool {
        _delegate = (id<iMateAppFaceFingerprintDelegate>)[[iMateAppFace sharedController] delegate];
        
        double timeSeconds = [self currentTimeSeconds] + 8;
        BOOL finish = NO;
        Byte sendBytes[10];
        Byte recvBytes[1024];
        Byte tmpBytes[1024];
        
        [self buzzer];
        memcpy(sendBytes, "\x83\x00", 2);
        ret = [self fingerprintComm:sendBytes inLen:2 outBuff:recvBytes requestType:FingerprintRequestTypeFeature timeout:3];
        if (ret <= 0) {
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
                [self fingerprintDelegateResponse:111 requestType:FingerprintRequestTypeFeature responseData:nil error:@"设备通讯失败"];

        }
        NSString *error = @"采样超时";
        result = 0x30;
        int recvLength = 0, skipLength = 0;
        while([self currentTimeSeconds] < timeSeconds){
            sendBytes[0] = 0x6A;
            sendBytes[1] = FINGERPRINT_COMM_PORT;
            sendBytes[2] = 4;
            
            ret = [_syncCommon bluetoothSendRecv:sendBytes dataLen:3 ResponseDataBuf:tmpBytes timeout:1];
            if (ret > 0 && tmpBytes[0]) {
                 if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
                 [self fingerprintDelegateResponse:tmpBytes[0] requestType:FingerprintRequestTypeFeature responseData:nil error:[_syncCommon getErrorString:tmpBytes+1 length:ret-1]];
                return;
            }
            if(ret < 0){
                 if ([_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                     [self iMateDelegateNoResponse:@"iMate通讯超时"];
                return;
            }else if(ret == 1){
                continue;
            }
            memcpy(recvBytes + recvLength, tmpBytes +1, ret - 1);
            recvLength += ret - 1;
            
            ret = [self unPackData:recvBytes + skipLength inLength:recvLength-skipLength outBuff:tmpBytes];
            if (ret < 0) {
                result = 0x34;
                error = @"采样数据错误";
                break;
            }
            if (ret > 0) {
                skipLength += (ret + 6) * 2;
                //NSLog(@"=====%02x,%02x", tmpBytes[0], tmpBytes[1]);
                if (memcmp(tmpBytes, "\x83\x30", 2) == 0) {
                    result = 0x30;
                    error = @"采样超时";
                    break;
                }
                if (memcmp(tmpBytes, "\x83\x33", 2) == 0) {
                    result = 0x33;
                    error = @"采样错误";
                    break;
                }
                if (memcmp(tmpBytes, "\x83\x00", 2)) {
                    continue;
                }
                finish = true;
                recvLength = ret;
                break;
            }
        }
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ) {
            if (finish) {
                NSData *data = [NSData dataWithBytes:tmpBytes+2 length:ret-2];
                [self fingerprintDelegateResponse:0 requestType:FingerprintRequestTypeFeature responseData:data error:nil];
            }
            else
                [self fingerprintDelegateResponse:result requestType:FingerprintRequestTypeFeature responseData:nil error:error];
            
        }
    }
}

-(double)currentTimeSeconds
{
    NSTimeInterval time= [[NSDate date] timeIntervalSince1970];
    return (double)time;
}

-(int)packData:(unsigned char *)inBuff inLength:(int)inLength outBuff:(unsigned char*)outBuff
{
    unsigned char sBuf[1024], crc = 0;
    int len = 0;
    
    memcpy(sBuf, "\x1B\x72\x73", 3);
    len += 3;
    
    sBuf[len++] = ((inLength + 1) >> 8);
    sBuf[len++] = inLength + 1;
    
    memcpy(sBuf + len, inBuff, inLength);
    len += inLength;
    
    for (int i = 0 ; i < len; i++) {
        crc += sBuf[i];
        outBuff[i * 2] = ((sBuf[i] >> 4) | 0x30);
        outBuff[i * 2 + 1] = ((sBuf[i] & 0x0f)|0x30);
    }
    outBuff[len * 2] = ((crc >> 4) | 0x30);
    outBuff[len * 2 + 1] = ((crc & 0x0f)|0x30);
    len ++;
    
    return len * 2;
}

-(int)unPackData:(unsigned char *)inBuff inLength:(int)inLength outBuff:(unsigned char*)outBuff
{
    int len = 0;
    
    if (inLength < 5)
        return 0;
    if (memcmp(inBuff, "\x31\x3B\x37\x32\x37\x33", 6)) {
        NSLog(@"Response pack head error: %s", inBuff);
        return -1;
    }
    len = ((inBuff[6]&0x0F)<<4) + (inBuff[7]&0x0F) * 256 + ((inBuff[8]&0x0F)<<4) + (inBuff[9]&0x0F);
    
    //NSLog(@"%02x,%02x,%02x,%02x", inBuff[6], inBuff[7], inBuff[8], inBuff[9]);
    //NSLog(@"len = %d", len);
    
    if (((len + 5) * 2) > inLength) {
        //NSLog(@"the_len = %d, inLength = %d", (len + 5) * 2, inLength);
        return 0;
    }
    
    for (int i = 0 ; i < len - 1; i++) {
        outBuff[i] = (inBuff[10 + i * 2]<<4) + (inBuff[10 + i * 2 + 1]&0x0F);
    }
    
    return len -1;
}



-(int)fingerprintComm:(unsigned char *)inBuff inLen:(int)len outBuff:(unsigned char *)outBuff requestType:(FingerprintRequestType)type timeout:(int)timeout
{
    _delegate = (id<iMateAppFaceFingerprintDelegate>)[[iMateAppFace sharedController] delegate];
    
    Byte sendBytes[600];
    Byte recvBytes[1500];
    Byte tmpBytes[600];
    
    int sendLen = [self packData:inBuff inLength:len outBuff:tmpBytes];
    
    sendBytes[0] = 0x6A;
    sendBytes[1] = FINGERPRINT_COMM_PORT; 	// iMate与指纹模块相连的通讯端口
    sendBytes[2] = 0x03;					// 发送数据报文命令
    sendBytes[3] = sendLen/256;
    sendBytes[4] = sendLen%256;
    
    memcpy(sendBytes + 5, tmpBytes, sendLen);
    
    int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:5 + sendLen ResponseDataBuf:recvBytes  timeout:1];
    if (iRet > 0 && recvBytes[0]) {
        /*
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
            [self fingerprintDelegateResponse:recvBytes[0] requestType:type responseData:nil error:[_syncCommon getErrorString:recvBytes+1 length:iRet-1]];
         */
        return -1;
    }
    if(iRet < 0){
        /*
        if ([_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [self iMateDelegateNoResponse:@"iMate通讯超时"];
         */
        return -2;
    }
    
    double timeSeconds = [self currentTimeSeconds] + timeout;
    int recvLength = 0;
    BOOL finish = NO;
    memset(recvBytes, 0, sizeof(recvBytes));
    while([self currentTimeSeconds] < timeSeconds){

        if(cancelFlag){
            cancelFlag = NO;
            [self performSelectorInBackground:@selector(powerOffThread) withObject:nil];
            /*
            if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [self iMateDelegateNoResponse:@"取消操作"];
             */
            return -3;
        }
        usleep(2000);
        sendBytes[0] = 0x6A;
        sendBytes[1] = FINGERPRINT_COMM_PORT;
        sendBytes[2] = 4;
        
        iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:3 ResponseDataBuf:tmpBytes timeout:1];
        if (iRet > 0 && tmpBytes[0]) {
            /*
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
                [self fingerprintDelegateResponse:tmpBytes[0] requestType:type responseData:nil error:[_syncCommon getErrorString:tmpBytes+1 length:iRet-1]];
             */
            return -1;
        }
        if(iRet < 0){
            /*
            if ([_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [self iMateDelegateNoResponse:@"iMate通讯超时"];
             */
            return -2;
        }else if(iRet == 1){
            continue;
        }
        memcpy(recvBytes + recvLength, tmpBytes +1, iRet - 1);
        recvLength += iRet - 1;
        //NSLog(@"[%s]", recvBytes);
        
        iRet = [self unPackData:recvBytes inLength:recvLength outBuff:tmpBytes];
        if (iRet < 0)
            break;
        if (iRet > 0) {
            finish = true;
            recvLength = iRet;
            break;
        }
    }
    
    if(!finish){
        /*
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
            [self fingerprintDelegateResponse:111 requestType:type responseData:nil error:@"Fingerprint通讯错误"];
         */
        return -2;
    }
    
    if(outBuff){
        memcpy(outBuff, tmpBytes, recvLength);
    }
    return recvLength;
}

-(void)iMateDelegateNoResponse:(NSString *)error
{
    FingerprintObject *dataObject = [[FingerprintObject alloc] init];
    dataObject.retCode = -1;
    dataObject.error = error;
    [self performSelectorOnMainThread:@selector(fingerprintDelegateResponse:) withObject:dataObject waitUntilDone:YES];
}

-(void)fingerprintDelegateResponse:(int)retCode requestType:(FingerprintRequestType)type responseData:(NSData *)responseData error:(NSString *)error
{
    FingerprintObject *dataObject = [[FingerprintObject alloc] init];
    dataObject.retCode = retCode;
    dataObject.requestType = type;
    dataObject.responseData = responseData;
    dataObject.error = error;
    [self performSelectorOnMainThread:@selector(fingerprintDelegateResponse:) withObject:dataObject waitUntilDone:YES];
}

-(void)fingerprintDelegateResponse:(FingerprintObject *)dataObject
{
    @autoreleasepool {
        if(!dataObject){
            return;
        }
        if(dataObject.retCode == -1) {
            [_delegate iMateDelegateNoResponse:dataObject.error];
        }else{
            [_delegate fingerprintDelegateResponse:dataObject.retCode requestType:dataObject.requestType responseData:dataObject.responseData error:dataObject.error];
        }        
    }
}

@end
