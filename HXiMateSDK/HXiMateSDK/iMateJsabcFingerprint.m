//
//  iMateJsabcFingerprint.m
//  支持浙江维尔(江苏农行）
//
//  Created by hxsmart on 13-8-8.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import "iMateJsabcFingerprint.h"
#import "EADSessionController.h"
#import "iMateAppFacePrivate.h"
#import "iMateAppFace+Fingerprint.h"
#import "SyncCommon.h"

static iMateJsabcFingerprint *sg_iMateFingerprint = nil;

@interface iMateJsabcFingerprint() {
    volatile BOOL cancelFlag;
    int FINGERPRINT_COMM_PORT;      //3           //指纹模块连接iMate内部端口号-通讯编号
    int FINGERPRINT_POWER_PORT;     //2           //指纹模块连接iMate内部端口号-电源编号
    NSString* CLASSIC_VERSION;
    NSString* JSABC_VERSION;
    BOOL isABCVersion;      //是否是  农行通用协议
    long baund;
}

@property (nonatomic, strong) id<iMateAppFaceFingerprintDelegate>delegate;
@property (nonatomic, strong) EADSessionController *iMateEADSessionController;
@property (nonatomic, strong) SyncCommon *syncCommon;

@end

@implementation iMateJsabcFingerprint

-(id)initWithEADSession:(EADSessionController *)iMateEADSessionController
{
    self = [super init];
    if(self){
        _syncCommon = [SyncCommon syncCommon:iMateEADSessionController];
        _iMateEADSessionController = iMateEADSessionController;
        cancelFlag = NO;
        
        FINGERPRINT_COMM_PORT = 4;           //缺省值：iMate指纹模块连接iMate内部端口号-通讯编号
        FINGERPRINT_POWER_PORT = 4;          //缺省值：iMate指纹模块连接iMate内部端口号-电源编号
        
        CLASSIC_VERSION = @"TYPICAL_ALL";
        JSABC_VERSION = @"ABC-NJDW";
        isABCVersion = NO;
        baund = FINGERPRINT_BAUDRATE;
    }
    return self;
}

+(iMateJsabcFingerprint *)imateFingerprint:(EADSessionController *)iMateEADSessionController
{
    if(sg_iMateFingerprint == nil){
        sg_iMateFingerprint = [[iMateJsabcFingerprint alloc] initWithEADSession:iMateEADSessionController];
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
        NSLog(@"setupComport");
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

//更改波特率
-(void)setBaudrate:(long)baudrate{}

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
    [self performSelectorInBackground:@selector(versionThread) withObject:nil];
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
        unsigned char sResponseDataBuff[20];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte sendBytes[9];
        
		sendBytes[0] = 0x6A;
		sendBytes[1] = FINGERPRINT_COMM_PORT;
		sendBytes[2] = 1;
		sendBytes[3] = ((baund >> 24) % 256);
		sendBytes[4] = ((baund >> 16) % 256);
		sendBytes[5] = ((baund >> 8) % 256);
		sendBytes[6] = (baund % 256);
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
        int retCode = sResponseDataBuff[0];
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            [self fingerprintDelegateResponse:retCode requestType:FingerprintRequestTypePowerOn responseData:nil error:nil];
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
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            [self fingerprintDelegateResponse:retCode requestType:FingerprintRequestTypePowerOff responseData:nil error:nil];
        }
    }
}

-(void)versionThread
{
    @autoreleasepool {
        _delegate = (id<iMateAppFaceFingerprintDelegate>)[[iMateAppFace sharedController] delegate];
        
        unsigned char sResponseDataBuff[100];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte *sendBytes = (Byte*)"\x1A\x56";
        
        int iRet = [self fingerprintComm:sendBytes inLen:2 outBuff:sResponseDataBuff requestType:FingerprintRequestTypeVersion timeout:2];
        
        if(iRet < 0){
            return;
        }
        
        isABCVersion = NO;
//        NSString *version = [NSString stringWithUTF8String:sResponseDataBuff];
        NSString *version = [[NSString alloc] initWithBytes:sResponseDataBuff length:iRet encoding:NSUTF8StringEncoding];
        if(version==nil)
        {
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
                [self fingerprintDelegateResponse:-2 requestType:FingerprintRequestTypeVersion responseData:nil error:@"解析指纹仪版本失败"];
            }
            return;
        }

#ifdef DEBUG
        NSLog(@"指纹仪版本:=======[  %@   ]==========",version);
#endif
        if ([version containsString:CLASSIC_VERSION]) {
            isABCVersion = YES;
        }
        if ([version containsString:JSABC_VERSION]) {//如果是JSABC 也认为是通用协议
            isABCVersion = YES;
        }
        
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            NSData *fingerData = [NSData dataWithBytes:sResponseDataBuff length:iRet];
            [self fingerprintDelegateResponse:0 requestType:FingerprintRequestTypeVersion responseData:fingerData error:nil];
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
    cancelFlag = NO;
    @autoreleasepool {
        _delegate = (id<iMateAppFaceFingerprintDelegate>)[[iMateAppFace sharedController] delegate];
        
        Byte *sendBytes0 = (Byte*)"\x1A\x56";
        if ([self fingerprintComm:sendBytes0 inLen:2 outBuff:nil requestType:FingerprintRequestTypeFeature timeout:1] < 0) {
            return;
        }
        
        [self buzzer];
        
        unsigned char sResponseDataBuff[600];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte *sendBytes = "\x02\x41\x41\x4d\x33\x62\x4e\x45\x76\x33\x67\x3d\x3d\x03";
        int lenght=14;
        if (!isABCVersion) {//江苏银行版本的指令
            sendBytes = "\x02\x30\x30\x30\x34\x30\x3c\x30\x30\x30\x30\x30\x30\x30\x38\x03";
            lenght = 16;
        }
        
        int iRet = [self fingerprintComm:sendBytes inLen:lenght outBuff:sResponseDataBuff requestType:FingerprintRequestTypeFeature timeout:6];
        if(iRet < 0) {
            return;
        }
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            
            
            NSData *fingerData = nil;
            if(isABCVersion)
            {
                //提取指纹仪的数据格式中的特征值。 by zbh 2014.12.18
                fingerData = [self parseFingerData:[NSData dataWithBytes:sResponseDataBuff length:iRet]];
                
            }else
            {
                fingerData = [NSData dataWithBytes:sResponseDataBuff+8 length:512];
            }
            [self fingerprintDelegateResponse:0 requestType:FingerprintRequestTypeFeature responseData:fingerData error:nil];

        }
    }
}

-(double)currentTimeSeconds
{
    NSTimeInterval time= [[NSDate date] timeIntervalSince1970];
    return (double)time;
}


-(int)fingerprintComm:(unsigned char *)inBuff inLen:(int)len outBuff:(unsigned char *)outBuff requestType:(FingerprintRequestType)type timeout:(int)timeout
{
    _delegate = (id<iMateAppFaceFingerprintDelegate>)[[iMateAppFace sharedController] delegate];
    
    Byte sendBytes[600];
    Byte recvBytes[600];
    
    sendBytes[0] = 0x6A;
    sendBytes[1] = FINGERPRINT_COMM_PORT; 	// iMate与指纹模块相连的通讯端口
    sendBytes[2] = 0x03;					// 发送数据报文命令
    sendBytes[3] = len/256;
    sendBytes[4] = len%256;
    memcpy(sendBytes + 5, inBuff, len);
    
    int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:5 + len ResponseDataBuf:recvBytes  timeout:1];
    if (iRet > 0 && recvBytes[0]) {
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
            [self fingerprintDelegateResponse:recvBytes[0] requestType:type responseData:nil error:[_syncCommon getErrorString:recvBytes+1 length:iRet-1]];
        return -1;
    }
    if(iRet < 0){
        if ([_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [self iMateDelegateNoResponse:@"iMate通讯超时"];
        return -1;
    }
    
    double timeSeconds = [self currentTimeSeconds] + timeout;
    int recvLength = 0;
    BOOL finish = NO;
    while([self currentTimeSeconds] < timeSeconds){

        if(cancelFlag){
            cancelFlag = NO;
            if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [self iMateDelegateNoResponse:@"取消操作"];
            return -1;
        }
        usleep(2000);
        sendBytes[0] = 0x6A;
        sendBytes[1] = FINGERPRINT_COMM_PORT;
        sendBytes[2] = 4;
        
        Byte tmpBytes[600];
        iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:3 ResponseDataBuf:tmpBytes timeout:1];
        if (iRet > 0 && tmpBytes[0]) {
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
                [self fingerprintDelegateResponse:tmpBytes[0] requestType:type responseData:nil error:[_syncCommon getErrorString:tmpBytes+1 length:iRet-1]];
            return -1;
        }
        if(iRet < 0){
            if ([_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [self iMateDelegateNoResponse:@"iMate通讯超时"];
            return -1;
        }else if(iRet == 1){
            continue;
        }
        memcpy(recvBytes + recvLength, tmpBytes +1, iRet - 1);
        recvLength += iRet - 1;
        
        if(recvLength < 2){
            continue;
        }
        if (recvBytes[recvLength - 1] == 0x03 ) {
            finish = true;
            recvLength -= 2;
            break;
        }
    }
    
    if(!finish){
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
            [self fingerprintDelegateResponse:111 requestType:type responseData:nil error:@"Fingerprint通讯超时"];
        return -2;
    }
    
    if(outBuff){
        memcpy(outBuff, recvBytes + 1, recvLength);
    }
    return recvLength;
}

//提取浙江维尔指纹仪（农行通用版）的数据格式中的特征值。
-(NSData*)parseFingerData:(NSData *)fingerData
{
    NSString *base64Encoded = [NSString stringWithUTF8String:fingerData.bytes];
    
    //解码成NSDATA
    NSData *nsdataFromBase64String = [[NSData alloc]
                                      initWithBase64EncodedString:base64Encoded options:0];
    
    Byte *bytesdata =(Byte *)[nsdataFromBase64String bytes];
    
    //截取256字节
    NSData * DATA = [NSData dataWithBytes:bytesdata+6 length:256];
    
    //对256字节编码base64
    return [DATA base64EncodedDataWithOptions:0];
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
