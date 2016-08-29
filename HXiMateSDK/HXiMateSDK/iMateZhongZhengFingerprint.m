//
//  iMateZhongZhengFingerprint.m
//  HXiMateSDK
//
//  支持中正指纹模块
//  Created by zbh on 15/4/17.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//

#import "iMateZhongZhengFingerprint.h"
#import "EADSessionController.h"
#import "iMateAppFacePrivate.h"
#import "iMateAppFace+Fingerprint.h"
#import "SyncCommon.h"

static iMateZhongZhengFingerprint *sg_iMateFingerprint = nil;

#define FINGER_MOVE_POSITION  5002  //按压位置不好，需要轻移手指位置的通知
#define FINGER_DATA_SAVE      5003  //指纹数据已读取并保存
#define FINGER_RESEND_PACK    5004  //指纹数据重发一包
#define FINGER_SEND_DONE      0     //分包数据发送完毕

@interface iMateZhongZhengFingerprint() {
    volatile BOOL cancelFlag;
    int FINGERPRINT_COMM_PORT;      //3           //指纹模块连接iMate内部端口号-通讯编号
    int FINGERPRINT_POWER_PORT;     //2           //指纹模块连接iMate内部端口号-电源编号
    long baund;
}

@property (nonatomic, strong) id<iMateAppFaceFingerprintDelegate>delegate;
@property (nonatomic, strong) EADSessionController *iMateEADSessionController;
@property (nonatomic, strong) SyncCommon *syncCommon;

@end

@implementation iMateZhongZhengFingerprint

-(id)initWithEADSession:(EADSessionController *)iMateEADSessionController
{
    self = [super init];
    if(self){
        _syncCommon = [SyncCommon syncCommon:iMateEADSessionController];
        _iMateEADSessionController = iMateEADSessionController;
        cancelFlag = NO;
        
        FINGERPRINT_COMM_PORT = 4;           //缺省值：iMate指纹模块连接iMate内部端口号-通讯编号
        FINGERPRINT_POWER_PORT = 4;          //缺省值：iMate指纹模块连接iMate内部端口号-电源编号
        baund = BAUDRATE;
    }
    return self;
}

+(iMateZhongZhengFingerprint *)imateFingerprint:(EADSessionController *)iMateEADSessionController
{
    if(sg_iMateFingerprint == nil){
        sg_iMateFingerprint = [[iMateZhongZhengFingerprint alloc] initWithEADSession:iMateEADSessionController];
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
    NSString *deviceString = [iMateAppFace sharedController].deviceVersion;
    NSString *hardwareString = [iMateAppFace sharedController].hardwareVersion;
    if ([deviceString hasPrefix:@"IMATEMINI"]||[hardwareString hasPrefix:@"IMATE5.0"]) {
        FINGERPRINT_COMM_PORT = 4;           //iMate指纹模块连接iMate内部端口号-通讯编号 = UART3_FP
        FINGERPRINT_POWER_PORT = 4;          //iMate指纹模块连接iMate内部端口号-电源编号 = Vuart_FP
    }
    else if ([deviceString hasPrefix:@"IMATEIII"]) {
        FINGERPRINT_COMM_PORT = 5;           //缺省值：iMate301指纹模块连接iMate内部端口号-通讯编号
        FINGERPRINT_POWER_PORT = 4;          //缺省值：iMate301指纹模块连接iMate内部端口号-电源编号
    }
    else if ([deviceString hasPrefix:@"IMATE"]) {
        FINGERPRINT_COMM_PORT = 3;           //缺省值：iMate指纹模块连接iMate内部端口号-通讯编号
        FINGERPRINT_POWER_PORT = 2;          //缺省值：iMate指纹模块连接iMate内部端口号-电源编号
    }
}


//更改波特率
-(void)setBaudrate:(long)baudrate
{
    baund = baudrate;
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


-(int)reset
{
    [self setupComport];
    Byte *inBuff = (Byte*)"\x02\x30\x30\x30\x34\x30\x34\x30\x30\x30\x30\x30\x30\x30\x31\x03";
    Byte sendBytes[30];
    Byte recvBytes[30];
    int len = 16;
    sendBytes[0] = 0x6A;
    sendBytes[1] = FINGERPRINT_COMM_PORT; 	// iMate与指纹模块相连的通讯端口
    sendBytes[2] = 0x03;					// 发送数据报文命令
    sendBytes[3] = len/256;
    sendBytes[4] = len%256;
    memcpy(sendBytes + 5, inBuff, len);
    return [_syncCommon bluetoothSendRecv:sendBytes dataLen:5 + len ResponseDataBuf:recvBytes  timeout:1];
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

-(void)GenerateFingerTemplate
{
    [self setupComport];
    [self performSelectorInBackground:@selector(GenerateFingerTemplateThread) withObject:nil];
}

-(void)fingerExpInfo
{
    [self setupComport];
    [self performSelectorInBackground:@selector(fingerExpInfoThread) withObject:nil];

}

-(void)getFingerImage
{
    [self setupComport];
    [self performSelectorInBackground:@selector(getFingerImageThread) withObject:nil];
}


#pragma run Thread in background

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
        Byte *sendBytes = (Byte*)"\x02\x30\x30\x30\x34\x30\x39\x30\x30\x30\x30\x30\x30\x30\x3d\x03";
        
        int iRet = [self fingerprintComm:sendBytes inLen:16 outBuff:sResponseDataBuff requestType:FingerprintRequestTypeVersion timeout:1];
        
        if(iRet < 0){
            [self reset];
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
        //内置的中正指纹仪没有蜂鸣器
        [self buzzer];
        
        unsigned char sResponseDataBuff[600];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte *sendBytes = (Byte*)"\x02\x30\x30\x30\x34\x31\x3c\x30\x30\x30\x30\x30\x30\x31\x38\x03";
        
        int iRet = [self fingerprintComm:sendBytes inLen:16 outBuff:sResponseDataBuff requestType:FingerprintRequestTypeFeature timeout:8];
        if(iRet < 0) {
            [self reset];
            return;
        }
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            
            Byte outbytes[iRet*2];
            [self oneTwo3x:sResponseDataBuff inLen:iRet outData:outbytes outLen:2*iRet];
            
            [self fingerprintDelegateResponse:0 requestType:FingerprintRequestTypeFeature responseData:[NSData dataWithBytes:outbytes length:iRet*2] error:nil];
        }
    }
}

-(void)GenerateFingerTemplateThread
{
    cancelFlag = NO;
    @autoreleasepool {
        
        _delegate = (id<iMateAppFaceFingerprintDelegate>)[[iMateAppFace sharedController] delegate];
        //内置的中正指纹仪没有蜂鸣器
        [self buzzer];
        
        unsigned char sResponseDataBuff[600];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte *sendBytes = (Byte*)"\x02\x30\x30\x30\x34\x30\x3b\x30\x30\x30\x30\x30\x30\x30\x3f\x03";
        
        int iRet = [self fingerprintComm:sendBytes inLen:16 outBuff:sResponseDataBuff requestType:FingerprintRequestTypeTemplate timeout:10];
        if(iRet < 0) {
            [self reset];
            return;
        }
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            
            Byte outbytes[iRet*2];
            [self oneTwo3x:sResponseDataBuff inLen:iRet outData:outbytes outLen:2*iRet];
            
            [self fingerprintDelegateResponse:0 requestType:FingerprintRequestTypeTemplate responseData:[NSData dataWithBytes:outbytes length:iRet*2] error:nil];
        }
    }
}

-(void)fingerExpInfoThread
{
    cancelFlag = NO;
    @autoreleasepool {
        
        _delegate = (id<iMateAppFaceFingerprintDelegate>)[[iMateAppFace sharedController] delegate];
        //内置的中正指纹仪没有蜂鸣器
        [self buzzer];
        
        unsigned char sResponseDataBuff[600];
        memset(sResponseDataBuff, 0, sizeof(sResponseDataBuff));
        Byte *sendBytes = (Byte*)"\x02\x30\x30\x30\x34\x30\x3c\x30\x30\x30\x30\x30\x30\x30\x38\x03";
        
        int iRet = [self fingerprintComm:sendBytes inLen:16 outBuff:sResponseDataBuff requestType:FingerprintRequestType256Feature timeout:8];
        if(iRet < 0) {
            [self reset];
            return;
        }
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            
            Byte outbytes[iRet*2];
            [self oneTwo3x:sResponseDataBuff inLen:iRet outData:outbytes outLen:2*iRet];
            
            [self fingerprintDelegateResponse:0 requestType:FingerprintRequestType256Feature responseData:[NSData dataWithBytes:outbytes length:iRet*2] error:nil];
        }
    }

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
            [self reset];
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
        memcpy(recvBytes + recvLength, tmpBytes + 1, iRet - 1);
        recvLength += iRet - 1;
        
        if(tmpBytes[iRet - 1]==0x03){
            finish = true;
            recvLength -= 8;
            break;
        }
    }
    //包中间的数据长度   （receivedLength - 2）/2 - 5 [（总长- 包头包尾）/2 - 2个长度 - 2个保留 - 1个chk ]
    int realLength = recvLength/2-2;
    
    if(!finish){
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
            [self fingerprintDelegateResponse:111 requestType:type responseData:nil error:@"Fingerprint通讯超时"];
        return -2;
    }
    
    if(outBuff) {
        //解析数据，将两个字节353a --》 5a
        Byte retbyte[recvLength/2];
        for(int i=0,j=0; i<recvLength;j++,i +=2)
        {
            retbyte[j]=(Byte)(((recvBytes[5+i]&0x0000000f)<<4)|(recvBytes[6+i]&0x0000000f));
        }
        //判断第一个字节
        if (retbyte[0]!=0x00) {
            if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
                [self fingerprintDelegateResponse:retbyte[0] requestType:type responseData:nil error:[self returnErrorString:retbyte[0]]];
            return -3;
        }
        //去掉前面2个字节
        memcpy(outBuff, retbyte + 2, realLength);
    }
    return realLength;
}


#pragma --mark upload finger image

-(int)ImagefingerprintComm:(unsigned char *)inBuff inLen:(int)len outBuff:(unsigned char *)outBuff requestType:(FingerprintRequestType)type timeout:(int)timeout
{
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
                [self reset];
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
            memcpy(recvBytes + recvLength, tmpBytes + 1, iRet - 1);
            recvLength += iRet - 1;
            
            //图像数据的字节长度
            if(recvLength -9 ==(recvBytes[1]*256+recvBytes[2]-4)){
                finish = true;
                recvLength -= 9;
                break;
            }
            if(recvLength -9 != (recvBytes[1]*256 + recvBytes[2] - 4) && tmpBytes[iRet-1] == 0x03)
            //重新发起一次请求 获取分包数据,专门针对中正指纹仪写的，中正方面说，有可能是波特率不匹配引起的。
            {
                finish = true;
                recvLength = 0;//receivedLength 由外面再次调用分包取图像数据
                break;
            }
        }
        //包中间的数据长度   （receivedLength - 2）/2 - 5 [（总长- 包头包尾）/2 - 2个长度 - 2个保留 - 1个chk ]
        int realLength = recvLength;
        
        static int num = 1;
        if(!finish){
            if (num < 3) {
                num++;
                [self reset];
                NSLog(@"reset once =================");
                //通知用户对准手指（稍微移动手指以便对准）
                if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
                    [self fingerprintDelegateResponse:FINGER_MOVE_POSITION requestType:FingerprintRequestTypeUploadImage responseData:nil error:@"按压不正确,轻移手指以便对准"];
                }
                
                return 0;
            }else{
                if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] )
                    [self fingerprintDelegateResponse:111 requestType:type responseData:nil error:@"Fingerprint通讯超时"];
                return -2;
            }
        }else{
            num = 1;
        }
        
        if(outBuff) {
            //去掉前面2个字节
            memcpy(outBuff, recvBytes + 7, realLength);
        }
//        NSLog(@"数据长度：%d",realLength);
        return realLength;
    }

}

-(void)getFingerImageThread
{
    cancelFlag = NO;
    @autoreleasepool {
        
        _delegate = (id<iMateAppFaceFingerprintDelegate>)[[iMateAppFace sharedController] delegate];
        //内置的中正指纹仪没有蜂鸣器
        [self buzzer];
        
        //图像数据长度为 152*100
        unsigned char allReceiveByte[IMAGESIZE];
        int allLength = 0;
        
        Byte packNum[1] ={0x00};
        Byte size[2]={0x04,0x00};
        
        int packSize=size[0]*256+size[1];
        int numbers = IMAGESIZE/packSize;
        if (IMAGESIZE%packSize==0) {
            numbers--;
        }
        
        Byte cmdbytes[30];
        Byte recBytes[packSize];
        int length =0;
        for (int i = 0; i<=numbers; i++) {
            NSLog(@"第%d次收包",i);
            int len = [self buildFingerCommand:packNum packNumLen:1 Size:size SizeLen:2 OutBytes:cmdbytes];
            
            length = [self ImagefingerprintComm:cmdbytes inLen:len outBuff:recBytes requestType:FingerprintRequestTypeUploadImage timeout:6];
            while (length == 0) {
                NSLog(@"重复第%d次收包",i);

                int timeout = 4;
                if (0==i) {
                    timeout = 2;
                }
                length = [self ImagefingerprintComm:cmdbytes inLen:len outBuff:recBytes requestType:FingerprintRequestTypeUploadImage timeout:timeout];
            }
            if(length < 0) {
                [self reset];
                return;
            }
            
            //取指纹仪图像数据OK，响一声
            if(i == 0)
            {
                [self buzzer];
                //数据已经保存OK，通知用户抬起手指
                if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
                    [self fingerprintDelegateResponse:FINGER_DATA_SAVE requestType:FingerprintRequestTypeUploadImage responseData:nil error:@"获取指纹成功,分包上送数据中..."];
                }
            }
            memcpy(allReceiveByte+allLength, recBytes, length);
            allLength += length;
            packNum[0] +=1;
        }
        
        Byte DecodeimageData[allLength * 2];
        for (int i = 0, j = 0; i < allLength; i++, j += 2) {
            DecodeimageData[j] =(allReceiveByte[i] & 0xf0);
            DecodeimageData[j + 1] = ((allReceiveByte[i] & 0x0f) << 4);
        }
        
        if ( [_delegate respondsToSelector:@selector(fingerprintDelegateResponse:requestType:responseData:error:)] ){
            [self fingerprintDelegateResponse:FINGER_SEND_DONE requestType:FingerprintRequestTypeUploadImage responseData:[NSData dataWithBytes:DecodeimageData length:allLength*2] error:nil];
        }
    }
}

#pragma --mark useful some methods
-(double)currentTimeSeconds
{
    NSTimeInterval time= [[NSDate date] timeIntervalSince1970];
    return (double)time;
}

- (NSString *)returnErrorString:(Byte)retCode
{
    switch (retCode) {
        case 0x01:
            return @"指令执行失败";
        case 0x0a:
            return @"指纹模块忙";
        case 0x0c:
            return @"未按好指纹";
    }
    return [NSString stringWithFormat: @"指纹模块其它错误:%x", retCode];
}

//计算inData数组的异或值
-(void) XOR:(Byte*)inData inlen:(int)len out:(Byte*)outData
{
    outData[0] = 0x00;
    for (int i = 0; i < len; i++) {
        outData[0] = (Byte)(outData[0]^inData[i]);
    }
}

//将两个字节3X 3X 转换--》XX（一个字节）（例如0x31 0x3b ----》 0x1b ）
-(int)twoOne3x:(Byte *)inData inLen:(int)len outData:(Byte *)outData outLen:(int)outLength
{
    if(len!=outLength*2)
        return 1;
    for (int i = 0,j = 0; i < len; j++,i+=2) {
        outData[j] = (Byte)(((inData[i]&0x0000000f)<<4) |(inData[i+1]&0x0000000f));
    }
    return 0;
}

//将XX（一个字节） 转换--》3x 3x （例如 0x1b ----》 0x31 0x3b ）
-(int)oneTwo3x:(Byte *)inData inLen:(int)len outData:(Byte *)outData outLen:(int)outLength
{
    if (len*2!=outLength) {
        return 1;
    }
    for (int i =0,j=0; i<len; i++,j+=2) {
        outData[j] = (Byte)(((inData[i]&0x000000f0)>>4)+0x30);
        outData[j+1] = (Byte)((inData[i]&0x0000000f)+0x30);
    }
    return 0;
}

//传入包号（数组为1个字节大小），包大小(数组为2个字节大小)，生成图像分包获取指令
-(int)buildFingerCommand:(Byte*)packNum packNumLen:(int)numLen Size:(Byte*)size SizeLen:(int)sizelen OutBytes:(Byte*)outbytes
{
    //不包含包号和长度，这三个字节，需要组
    Byte requestCHK[18]={0x30,0x30,0x30,0x37,0x32,0x3e,0x30,0x30,0x30,0x30,0x30,0x30,0x00,0x00,0x00,0x00,0x00,0x00};
//    (Byte*)"\x30\x30\x30\x37\x32\x3e\x30\x30\x30\x30\x30\x30\x00\x00\x00\x00\x00\x00";
    //组包号
    Byte tmpNUM[numLen*2];
    [self oneTwo3x:packNum inLen:numLen outData:tmpNUM outLen:numLen*2];
    memcpy(requestCHK+12, tmpNUM, numLen*2);
    
    //组长度
    Byte tmpSize[sizelen*2];
    [self oneTwo3x:size inLen:sizelen outData:tmpSize outLen:sizelen*2];
    memcpy(requestCHK+14, tmpSize, sizelen*2);
    
    //算CHK值
    Byte tmp[9];//大小为 requestCHK的一半
    [self twoOne3x:requestCHK inLen:18 outData:tmp outLen:9];
    Byte xorChk[1];
    [self XOR:tmp inlen:9 out:xorChk];
    Byte CHK[2];//需要的chk值
    [self oneTwo3x:xorChk inLen:1 outData:CHK outLen:2];
    
    //组成  0x02+requestCHK+CHK值+0x03
    //长度是 22字节
    outbytes[0]=0x02;
    memcpy(outbytes+1, requestCHK, 18);
    outbytes[19]=CHK[0];
    outbytes[20]=CHK[1];
    outbytes[21]=0x03;
    
    return 22;
}

#pragma -- mark iMateDelegateRespone

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