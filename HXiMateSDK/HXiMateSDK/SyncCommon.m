//
//  SyncCommon.m
//  HXiMateSDK
//
//  Created by hxsmart on 13-12-18.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import "SyncCommon.h"
#import "iMateAppFace.h"
#import "iMateAppFacePrivate.h"

static SyncCommon *sg_syncCommon = nil;

@interface SyncCommon () {
    int sg_iResponseDataLength;
    unsigned char sg_sResponseDataBuffer[2048];
}

@property (nonatomic, strong) NSLock  *dataLock;
@property (nonatomic, strong) EADSessionController *iMateEADSessionController;

@end

@implementation SyncCommon

-(id)initWithEADSessionController:(EADSessionController *)sessionController
{
    self = [super init];
    if(self) {
        _iMateEADSessionController = sessionController;
        _dataLock = [[NSLock alloc] init];
    }
    return self;
}

+(SyncCommon *)syncCommon:(EADSessionController *)sessionController
{
    if(sg_syncCommon == nil){
        sg_syncCommon = [[SyncCommon alloc] initWithEADSessionController:sessionController];
    }
    return sg_syncCommon;
}

-(void)clearData
{
    [_dataLock lock];
    sg_iResponseDataLength = 0;
    [_dataLock unlock];
}

-(void)putData:(int)iRetCode data:(unsigned char *) psResponseDataBuff dataLen:(int)iResponseDataLen
{
    [_dataLock lock];
    sg_sResponseDataBuffer[0] = iRetCode;
    sg_iResponseDataLength = 1;
    if ( psResponseDataBuff ) {
        memcpy(sg_sResponseDataBuffer +1,psResponseDataBuff,iResponseDataLen);
        sg_iResponseDataLength += iResponseDataLen;
    }
    [_dataLock unlock];
#ifdef DEBUG
    NSLog(@"put data : %d", sg_iResponseDataLength);
#endif
}

-(int)getData:(unsigned char *)psResponseDataBuff
{
    int iRetLen = 0;
    
    [_dataLock lock];
    memcpy(psResponseDataBuff, sg_sResponseDataBuffer,sg_iResponseDataLength);
    iRetLen = sg_iResponseDataLength;
    sg_iResponseDataLength = 0;
    [_dataLock unlock];
    
    return iRetLen;
}

-(double)currentTimeSeconds
{
    NSTimeInterval time= [[NSDate date] timeIntervalSince1970];
    return (double)time;
}

// ret > 0 接收成功
// ret < 0 接收超时
-(int)bluetoothSendRecv:(unsigned char *)psRequestDataBuff dataLen:(int)iRequestDataLen ResponseDataBuf:(unsigned char *)psResponseDataBuf timeout:(int)timeout
{
    int receviedLength = 0;
    
    [self clearData];
    sg_iResponseDataLength = 0;
    
    while ([self getData:psResponseDataBuf])
        ;;
    
    NSData *sendPackData = [self packSendData:[NSData dataWithBytes:psRequestDataBuff length:iRequestDataLen]];
    [[iMateAppFace sharedController] iMateDataReset];
    [[iMateAppFace sharedController] setSyncRequestType:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{ //解决多线程写数据冲突的问题，使用main_queue进行排队
        [_iMateEADSessionController writeData:sendPackData];
    });
    
    double timeSeconds = [self currentTimeSeconds] + timeout;
    
    while ([self currentTimeSeconds] < timeSeconds) {
        receviedLength = [self getData:psResponseDataBuf];
        if(receviedLength > 0)
            break;
        usleep(1000);
    }
    [[iMateAppFace sharedController] setSyncRequestType:NO];
    
    if (receviedLength == 0) {
        return -1;
    }
    return receviedLength;
}

#pragma mark private mathods

- (NSData *)packSendData:(NSData *)sendData
{
    NSMutableData *resultData = [[NSMutableData alloc] init];
    
#ifdef DEBUG
    NSLog(@"send length = %ld", (unsigned long)[sendData length]);
#endif
    
    if (gl_supportPackageSequenceNumberProtocol) {
        Byte tmpBytes[6];
        tmpBytes[0]=0x02;           //开始字符
        tmpBytes[1]=0x00;           //长度1
        tmpBytes[2]=0xFF;           //序列号协议标志
        tmpBytes[3]=++gl_thePackageSequenceNumber;  //报文序列号
        tmpBytes[4]=([sendData length])/256;   //长度2
        tmpBytes[5]=([sendData length])%256;   //长度3
        [resultData appendBytes:tmpBytes length:6];
    }
    else {
        // 报文头
        if ( [sendData length] <= 255 ) {
            //一字节长度报文
            Byte tmpBytes[2];
            tmpBytes[0]=0x02;           //开始字符
            tmpBytes[1]=[sendData length];         //长度
            [resultData appendBytes:tmpBytes length:2];
        }
        else {
            //三字节长度报文
            Byte tmpBytes[4];
            tmpBytes[0]=0x02;           //开始字符
            tmpBytes[1]=0x00;           //长度1
            tmpBytes[2]=([sendData length])/256;   //长度2
            tmpBytes[3]=([sendData length])%256;   //长度3
            [resultData appendBytes:tmpBytes length:4];
        }
    }
    
    [resultData appendData:sendData];
    [resultData appendBytes:"\x03" length:1];
    
    //计算检查和
    Byte checkCode=0x03;
    for (NSInteger i=0;i<[sendData length];i++)
        checkCode ^= ((Byte *)[sendData bytes])[i];
    
    [resultData appendBytes:&checkCode length:1];
    
#ifdef DEBUG
    NSLog(@"packSendData:%@", resultData);
#endif
    
    return resultData;
}

- (NSString *)getErrorString:(Byte *)errorBytes length:(int)length
{
    //将GBK编码的中文转换成UTF8编码
    NSStringEncoding enc =CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString *utf8Error = [NSString stringWithCString:(const char*)errorBytes
                                             encoding:enc];
        
    return utf8Error;
}


@end
