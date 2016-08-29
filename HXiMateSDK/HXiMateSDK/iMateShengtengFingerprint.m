//
//  iMateShengtengFingerprint.m
//  支持升腾定制（天诚盛业指纹模块）
//
//  Created by hxsmart on 13-8-8.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import "iMateShengtengFingerprint.h"
#import "EADSessionController.h"
#import "iMateAppFacePrivate.h"
#import "iMateAppFace+Fingerprint.h"
#import "SyncCommon.h"

#define FINGER_MOVE_POSITION  5002  //按压位置不好，需要轻移手指位置的通知
#define FINGER_DATA_SAVE      5003  //指纹数据已读取并保存
#define FINGER_RESEND_PACK    5004  //指纹数据重发一包
#define FINGER_START          5005  //开始按压指纹
#define FINGER_SEND_DONE      0     //分包数据发送完毕

static iMateShengtengFingerprint *sg_iMateFingerprint = nil;

@interface iMateShengtengFingerprint() {
    volatile BOOL cancelFlag;
    int FINGERPRINT_COMM_PORT;      //3           //指纹模块连接iMate内部端口号-通讯编号
    int FINGERPRINT_POWER_PORT;     //2           //指纹模块连接iMate内部端口号-电源编号
    long baund;
}

@property (nonatomic, strong) id<iMateAppFaceFingerprintDelegate>delegate;
@property (nonatomic, strong) EADSessionController *iMateEADSessionController;
@property (nonatomic, strong) SyncCommon *syncCommon;

@end

@implementation iMateShengtengFingerprint

-(id)initWithEADSession:(EADSessionController *)iMateEADSessionController
{
    self = [super init];
    if(self){
        _syncCommon = [SyncCommon syncCommon:iMateEADSessionController];
        _iMateEADSessionController = iMateEADSessionController;
        cancelFlag = NO;
        
        FINGERPRINT_COMM_PORT = 4;           //缺省值：iMate指纹模块连接iMate内部端口号-通讯编号
        FINGERPRINT_POWER_PORT = 4;          //缺省值：iMate指纹模块连接iMate内部端口号-电源编号
        baund = FINGERPRINT_BAUDRATE;
    }
    return self;
}

+(iMateShengtengFingerprint *)imateFingerprint:(EADSessionController *)iMateEADSessionController
{
    if(sg_iMateFingerprint == nil){
        sg_iMateFingerprint = [[iMateShengtengFingerprint alloc] initWithEADSession:iMateEADSessionController];
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


//更改波特率  （天诚盛业指纹仪模块必须上电后才能更改波特率）
-(void)setBaudrate:(long)baudrate
{
    baund = baudrate;
    [self performSelectorInBackground:@selector(powerOnThreadBySetBaudrate) withObject:nil];
}

-(void)powerOnThreadBySetBaudrate
{
    @autoreleasepool {
        
        _delegate = (id<iMateAppFaceFingerprintDelegate>)[[iMateAppFace sharedController] delegate];
        unsigned char sResponseDataBuff[20];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        
        //变为115200波特率
        Byte *setBaund = (Byte*)"\x7E\x42\x62\x00\x00\x00\x01\x07\x26";
        Byte received[100];
        int ret = [self fingerprintComm:setBaund inLen:9 outBuff:received requestType:FingerprintRequestTypeSetBaudrate timeout:1];
        if (ret<0) {
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
                [self fingerprintDelegateResponse:ret requestType:FingerprintRequestTypeSetBaudrate responseData:nil error:@"指纹仪更改波特率失败"];
            return;
        }

        //重新上电
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
                [self fingerprintDelegateResponse:sResponseDataBuff[0] requestType:FingerprintRequestTypeSetBaudrate responseData:nil error:[_syncCommon getErrorString:sResponseDataBuff+1 length:iRet-1]];
            [self powerOff];
            return;
        }
        if(iRet == -1){
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
                [self fingerprintDelegateResponse:-1 requestType:FingerprintRequestTypeSetBaudrate responseData:nil error:@"iMate背夹通讯超时"];
            }
            [self powerOff];
            return;
        }
        int retCode = sResponseDataBuff[0];
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            [self fingerprintDelegateResponse:retCode requestType:FingerprintRequestTypeSetBaudrate responseData:nil error:nil];
        }
    }
}

//取消 取指纹特征
-(void)cancel
{
    cancelFlag = YES;
}

-(void)powerOn
{
    baund = 9600;
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
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
                [self fingerprintDelegateResponse:-1 requestType:FingerprintRequestTypePowerOn responseData:nil error:@"iMate背夹通讯超时"];
            }
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
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
                [self fingerprintDelegateResponse:-1 requestType:FingerprintRequestTypePowerOff responseData:nil error:@"iMate背夹通讯超时"];
            }
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
    cancelFlag = NO;
    @autoreleasepool {
        _delegate = (id<iMateAppFaceFingerprintDelegate>)[[iMateAppFace sharedController] delegate];
        
        unsigned char sResponseDataBuff[100];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte *sendBytes = (Byte*)"\x7E\x42\x61\x00\x00\x00\x01\x00\x22";
        
        int iRet = [self fingerprintComm:sendBytes inLen:9 outBuff:sResponseDataBuff requestType:FingerprintRequestTypeVersion timeout:1];
        
        if(iRet < 0){
            return;
        }
        
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            [self fingerprintDelegateResponse:0 requestType:FingerprintRequestTypeVersion responseData:[NSData dataWithBytes:sResponseDataBuff length:iRet] error:nil];
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
        
        [self buzzer];
        
        unsigned char sResponseDataBuff[600];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte *sendBytes = "\x7E\x42\x64\x00\x00\x00\x01\x02\x25";//库中不比对，直接返回特征值
        
        int iRet = [self fingerprintComm:sendBytes inLen:9 outBuff:sResponseDataBuff requestType:FingerprintRequestTypeFeature timeout:6];
        if(iRet < 0 || iRet == 111) {
            return;
        }
        
        if (iRet <= 16) {
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
                [self fingerprintDelegateResponse:1 requestType:FingerprintRequestTypeFeature responseData:nil error:@"采集指纹出错或超时"];
            return;
        }
        
        int userDataLen = 	sResponseDataBuff[0]&0x000000ff;
        int FingerDataLen = sResponseDataBuff[1]&0x000000ff;
        if(iRet != 2 + userDataLen + FingerDataLen)
        {
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
                [self fingerprintDelegateResponse:1 requestType:FingerprintRequestTypeFeature responseData:nil error:@"指纹数据大小出错"];
            return;
        }
        iRet = iRet - (2+userDataLen);
        Byte out[iRet];
        memcpy(out, sResponseDataBuff+2+userDataLen, iRet);
        
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            [self fingerprintDelegateResponse:0 requestType:FingerprintRequestTypeFeature responseData:[NSData dataWithBytes:out length:iRet] error:nil];
        }
    }
}

-(double)currentTimeSeconds
{
    NSTimeInterval time= [[NSDate date] timeIntervalSince1970];
    return (double)time;
}

- (NSString *)returnErrorString:(int)retCode
{
    switch (retCode) {
        case 1:
            return @"失败结果";
        case 2:
            return @"校验错误";
        case 3:
            return @"操作超时";
        case 4:
            return @"未连光头";
        case 5:
            return @"写闪存错";
        case 6:
            return @"未按好指纹";
        case 7:
            return @"值不相关";
        case 8:
            return @"值不匹配";
        case 9:
            return @"库链为空";
        case 10:
            return @"请抬起手";
        case 255:
            return @"指纹模块忙";
    }
    return [NSString stringWithFormat: @"指纹模块其它错误:%d", retCode];
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
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            [self fingerprintDelegateResponse:-1 requestType:type responseData:nil error:@"iMate背夹通讯超时"];
        }
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
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
                [self fingerprintDelegateResponse:-1 requestType:type responseData:nil error:@"iMate背夹通讯超时"];
            }
            return -1;
        }else if(iRet == 1){
            continue;
        }
        memcpy(recvBytes + recvLength, tmpBytes + 1, iRet - 1);
        recvLength += iRet - 1;
        
        if (recvBytes[0] != 0x7E || recvBytes[1] != 0x42)
            recvLength = 0;
        
        if(recvLength < 9){//指纹仪应答数据，除DATA区域，其他区域合起来有9个字节，小于9说明还没收全
            continue;
        }
        
        int dataLen = (recvBytes[4]&0x000000ff << 24) | (recvBytes[5]&0x000000ff << 16) | (recvBytes[6]&0x000000ff << 8) | (recvBytes[7]&0x000000ff);
        if (recvLength == dataLen + 9) {
            finish = true;
            recvLength = dataLen;
            break;
        }
    }
    
    if(!finish){
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
            [self fingerprintDelegateResponse:111 requestType:type responseData:nil error:@"指纹仪通讯超时"];
        return 111;
    }
    int cmdRet = recvBytes[3];
    if (cmdRet) {
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
            [self fingerprintDelegateResponse:cmdRet requestType:type responseData:nil error:[self returnErrorString:cmdRet]];
        return -3;
    }
    
    if(outBuff) {
        memcpy(outBuff, recvBytes + 8, recvLength);
    }
    return recvLength;
}



#pragma --mark upload finger image

-(int)ImagefingerprintComm:(unsigned char *)inBuff inLen:(int)len outBuff:(unsigned char *)outBuff requestType:(FingerprintRequestType)type timeout:(int)timeout
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
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            [self fingerprintDelegateResponse:-1 requestType:type responseData:nil error:@"iMate背夹通讯超时"];
        }
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
        
        Byte tmpBytes[1024];
        iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:3 ResponseDataBuf:tmpBytes timeout:1];
        if (iRet > 0 && tmpBytes[0]) {
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
                [self fingerprintDelegateResponse:tmpBytes[0] requestType:type responseData:nil error:[_syncCommon getErrorString:tmpBytes+1 length:iRet-1]];
            return -1;
        }
        if(iRet < 0){
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
                [self fingerprintDelegateResponse:-1 requestType:type responseData:nil error:@"iMate背夹通讯超时"];
            }
            return -1;
        }else if(iRet == 1){
            continue;
        }
        memcpy(recvBytes + recvLength, tmpBytes + 1, iRet - 1);
        recvLength += iRet - 1;
    
        
        if (recvBytes[0] != 0x7E || recvBytes[1] != 0x42)
            recvLength = 0;
        
        if(recvLength < 9){//指纹仪应答数据，除DATA区域，其他区域合起来有9个字节，小于9说明还没收全
            continue;
        }
        
        int dataLen = (recvBytes[6]&0x000000ff)*256 + (recvBytes[7]&0x000000ff);
        if (recvLength == dataLen + 9) {
            finish = true;
            recvLength = dataLen;
            break;
        }
    }
    
    
    static int num = 1;
    if(!finish){
        if (num < 3) {
            num++;
            return 0;
        }else{
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
                [self fingerprintDelegateResponse:111 requestType:type responseData:nil error:@"指纹仪通讯超时"];
            num = 1;
            return 111;
        }
    }else{
        num = 1;
    }

    int cmdRet = recvBytes[3];
    if (cmdRet) {
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
            if(cmdRet == 6)
            {
                
            }else{
                [self fingerprintDelegateResponse:cmdRet requestType:type responseData:nil error:[self returnErrorString:cmdRet]];
                return -3;
            }
    }
    
    if(outBuff) {
        memcpy(outBuff, recvBytes + 8, recvLength);
    }
    return recvLength;
}


/**
 * 上传指纹图像
 */
-(void)getFingerImage
{
    [self setupComport];
    [self performSelectorInBackground:@selector(getFingerImageThread) withObject:nil];
}


-(void)getFingerImageThread
{
    cancelFlag = NO;
    @autoreleasepool {
        
        _delegate = (id<iMateAppFaceFingerprintDelegate>)[[iMateAppFace sharedController] delegate];
        //内置的中正指纹仪没有蜂鸣器
        [self buzzer];
        
        //图像数据长度为 152*200，28是头
        unsigned char allReceiveByte[IMAGESIZE2];
        int allLength = 0;
        
        Byte size[4]={0x00,0x00,0x03,0xC0};
        int packSize=size[2]*256+size[3];
        int numbers = IMAGESIZE2/packSize;
        if (IMAGESIZE2%packSize==0) {
            numbers--;
        }
        
        Byte cmdbytes[30];
        Byte recBytes[packSize];
        
        for (int i = 0; i<=numbers; i++) {
            NSLog(@"第%d次收包",i);
            int length =0;
            int offsetInt = packSize * i;
            Byte offset[4];
            offset[0] = (Byte)(offsetInt >> 24);
            offset[1] = (Byte)((offsetInt & 0x00ff0000) >> 16);
            offset[2] = (Byte)((offsetInt & 0x0000ff00) >> 8);
            offset[3] = (Byte)((offsetInt & 0x000000ff));
            
            int len = [self buildFingerCommandWithOffset:offset OffsetLen:4 Size:size SizeLen:4 OutBytes:cmdbytes];
            
            int timeout = 5;
            if (i!=0) {
                timeout = 1;
            }
            
            length = [self ImagefingerprintComm:cmdbytes inLen:len outBuff:recBytes requestType:FingerprintRequestTypeUploadImage timeout:timeout];
            while (length == 0) {
                NSLog(@"重复第%d次收包",i);
                if(i==0){
                    if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
                        [self fingerprintDelegateResponse:FINGER_START requestType:FingerprintRequestTypeUploadImage responseData:nil error:@"请按压手指"];
                        timeout = 8;
                    }
                }else{
                    timeout = 1;
                }
                length = [self ImagefingerprintComm:cmdbytes inLen:len outBuff:recBytes requestType:FingerprintRequestTypeUploadImage timeout:timeout];
            }
            
            if(length < 0) {
                [self powerOff];
                return;
            }
            
            //取指纹仪图像数据OK，响一声
            if(i == 0)
            {
                [self buzzer];
                //第一包含有28字节的头，去掉
                memcpy(allReceiveByte, recBytes+28, length-28);
                length -=28;
                allLength += length;
                //数据已经保存OK，通知用户抬起手指
                if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
                    [self fingerprintDelegateResponse:FINGER_DATA_SAVE requestType:FingerprintRequestTypeUploadImage responseData:nil error:@"获取指纹成功,分包上送数据中..."];
                }
            }else{
                
                memcpy(allReceiveByte+allLength, recBytes, length);
                allLength += length;
            }
        }
        
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            [self fingerprintDelegateResponse:FINGER_SEND_DONE requestType:FingerprintRequestTypeUploadImage responseData:[[NSData alloc] initWithBytes:allReceiveByte length:allLength] error:nil];
        }
        

    }
}

//组装分包获取命令
-(int)buildFingerCommandWithOffset:(Byte*)offset OffsetLen:(int)Offsetlen Size:(Byte*)size SizeLen:(int)sizelen OutBytes:(Byte*)outbytes
{
    //不包含包号和长度，这三个字节，需要组
    Byte command[]={0x7e,0x42,0x84,0x00,0x00,0x00,0x0c,0x00,0x00,0x0b,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};
    //放置size
    memcpy(command+15, size, sizelen);
    //放置offset
    memcpy(command+11, offset, Offsetlen);
    
    //算CHK值
    Byte tmp[18];
    memcpy(tmp, command+1, 18);
    Byte xorChk[1];
    [self XOR:tmp inlen:18 out:xorChk];
    command[19] = xorChk[0];
    
    memcpy(outbytes, command, 20);
    return 20;
}

//计算inData数组的异或值
-(void) XOR:(Byte*)inData inlen:(int)len out:(Byte*)outData
{
    outData[0] = 0x00;
    for (int i = 0; i < len; i++) {
        outData[0] = (Byte)(outData[0]^inData[i]);
    }
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
