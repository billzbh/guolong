//
//  iMateData.m
//  iMateTest
//
//  Created by hxsmart on 12-10-15.
//
//

#import "iMateData.h"

@implementation iMateData

- (void)reset
{
    self.receivedDataStatus = MATEReceivedDataIsInvalid;
    if (self.receivedPackData == nil || [self.receivedPackData length])
        self.receivedPackData = [[NSMutableData alloc] init];
}

- (NSData *)packSendData
{
    NSMutableData *resultData = [[NSMutableData alloc] init];

#ifdef DEBUG
    NSLog(@"send length = %d", (int)[self.sendData length]);
#endif
    if (gl_supportPackageSequenceNumberProtocol) {
        Byte tmpBytes[6];
        tmpBytes[0]=0x02;                           //开始字符
        tmpBytes[1]=0x00;                           //长度1
        tmpBytes[2]=0xFF;                           //序列号协议标志
        tmpBytes[3]=++gl_thePackageSequenceNumber;  //报文序列号
        tmpBytes[4]=([self.sendData length])/256;   //长度2
        tmpBytes[5]=([self.sendData length])%256;   //长度3
        [resultData appendBytes:tmpBytes length:6];
    }
    else {
        // 报文头
        if ( [self.sendData length] <= 255 ) {
            //一字节长度报文
            Byte tmpBytes[2];
            tmpBytes[0]=0x02;                        //开始字符
            tmpBytes[1]=[self.sendData length];      //长度
            [resultData appendBytes:tmpBytes length:2];
        }
        else {
            //三字节长度报文
            Byte tmpBytes[4];
            tmpBytes[0]=0x02;           //开始字符
            tmpBytes[1]=0x00;           //长度1
            tmpBytes[2]=([self.sendData length])/256;   //长度2
            tmpBytes[3]=([self.sendData length])%256;   //长度3
            [resultData appendBytes:tmpBytes length:4];
        }
    }
    
    [resultData appendData:self.sendData];
    [resultData appendBytes:"\x03" length:1];
    
    //计算检查和
    Byte checkCode=0x03;
    for (NSInteger i=0;i<[self.sendData length];i++)
        checkCode ^= ((Byte *)[self.sendData bytes])[i];

    [resultData appendBytes:&checkCode length:1];
    
    self.receivedDataStatus = MATEReceivedDataIsInvalid;
    if (self.receivedPackData == nil || [self.receivedPackData length])
        self.receivedPackData = [[NSMutableData alloc] init];
   
#ifdef DEBUG
    NSLog(@"packSendData:%@", resultData);
#endif
    
    return resultData;
}

- (MateReceivedDataStatus)unpackReceivedData
{
    _receivedSequenceNumber = 0;
    self.receivedDataStatus = MATEReceivedDataIsInvalid;
    NSInteger packDataLen = [self.receivedPackData length];
    if ( packDataLen < 4)
        return MATEReceivedDataIsInvalid;
    
#ifdef DEBUG
    NSLog(@"unpackReceivedData:%@ length:%lu",self.receivedPackData,(unsigned long)[self.receivedPackData length]);
#endif
    
    NSInteger dataLen;
    Byte *startDataPotint;
    while (1) {
        Byte *packBytes = (Byte *)[self.receivedPackData bytes];
        while (_receivedPackData.length && packBytes[0] != 0x02) {
            [self.receivedPackData replaceBytesInRange:NSMakeRange(0, 1) withBytes:NULL length:0];
            packBytes = (Byte *)[self.receivedPackData bytes];
        }
        packDataLen = [self.receivedPackData length];
        if (packDataLen < 4) {
            return MATEReceivedDataIsInvalid;
        }
        
        if ( packBytes[1] == 0x00 ) {
            if(packBytes[2] == 0xFF) {
                if ( packDataLen < 6)
                    return MATEReceivedDataIsInvalid;
                _receivedSequenceNumber = packBytes[3];
                dataLen = packBytes[4]*256+packBytes[5];
                if ( dataLen + 8 > packDataLen ) {
                    return MATEReceivedDataIsInvalid;
                }
                startDataPotint = &packBytes[6];
            }
            else {
                dataLen = packBytes[2]*256+packBytes[3];
                if ( dataLen + 6 > packDataLen ) {
                    return MATEReceivedDataIsInvalid;
                }
                startDataPotint = &packBytes[4];
            }
        }
        else {
            dataLen = packBytes[1];
            if ( dataLen + 4 > packDataLen ) {
                return MATEReceivedDataIsInvalid;
            }
            startDataPotint = &packBytes[2];
        }
        
        if (startDataPotint[dataLen] != 0x03) {
            self.receivedDataStatus = MATEReceivedDataIsFault;
            return MATEReceivedDataIsFault;
        }
        
        Byte checkCode=0;
        for ( NSInteger i=0;i<dataLen+2;i++ )
            checkCode^=startDataPotint[i];
        if ( checkCode ) {
            self.receivedDataStatus = MATEReceivedDataIsFault;
            return MATEReceivedDataIsFault;
        }
        if (gl_supportPackageSequenceNumberProtocol == NO || (gl_supportPackageSequenceNumberProtocol == YES && _receivedSequenceNumber == gl_thePackageSequenceNumber)) {
            break;
        }
#ifdef DEBUG
        NSLog(@"_receivedSequenceNumber != gl_thePackageSequenceNumber:%d,%d", _receivedSequenceNumber, gl_thePackageSequenceNumber);
#endif
        [self.receivedPackData replaceBytesInRange:NSMakeRange(0, (startDataPotint - packBytes) + dataLen + 2) withBytes:NULL length:0];
    }
    
    self.returnCode = startDataPotint[0];
    
    self.receivedData = [[NSData alloc] initWithBytes:startDataPotint+1 length:dataLen-1];
    
    self.receivedDataStatus = MATEReceivedDataIsValid;
    
    return MATEReceivedDataIsValid;
}

- (void)appendReceiveData:(NSData *)receivedSubData
{
#ifdef DEBUG
    NSLog(@"appendReceiveData:%@",receivedSubData);
#endif
    [self.receivedPackData appendData:receivedSubData];
}

-(int)getReceiveDataLength{
    return (int)[self.receivedPackData length];
}

- (NSInteger)getReturnCode
{
    return (unsigned int)_returnCode;
}

- (NSString *)getErrorString
{
    char errorBytes[300];
    
    if ( _returnCode ) {
        memset(errorBytes,0,sizeof(errorBytes));
        memcpy(errorBytes,[_receivedData bytes],[_receivedData length]);
                
        //将GBK编码的中文转换成UTF8编码
        NSStringEncoding enc =CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        NSString *utf8Error = [NSString stringWithCString:(const char*)errorBytes
                                                     encoding:enc];
        
        return utf8Error;
    }
    return nil;
}

@end
