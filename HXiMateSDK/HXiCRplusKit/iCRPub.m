//
//  iCRPub.m
//  HXiMateSDK
//
//  Created by zbh on 15/12/8.
//  Copyright © 2015年 hxsmart. All rights reserved.
//

#import "iCRPub.h"

@implementation iCRPub

+ (NSString *)oneTwoData:(NSData *)sourceData
{
    Byte *inBytes = (Byte *)[sourceData bytes];
    NSMutableString *resultData = [[NSMutableString alloc] init];
    
    for(NSInteger counter = 0; counter < [sourceData length]; counter++)
        [resultData appendFormat:@"%02X",inBytes[counter]];
    
    return resultData;
}

+ (NSData *)twoOneData:(NSString *)sourceString
{
    Byte tmp, result;
    Byte *sourceBytes = (Byte *)[sourceString UTF8String];
    
    NSMutableData *resultData = [[NSMutableData alloc] init];
    
    for(NSInteger i=0; i<strlen((char*)sourceBytes); i+=2) {
        tmp = sourceBytes[i];
        if(tmp > '9')
            tmp = toupper(tmp) - 'A' + 0x0a;
        else
            tmp &= 0x0f;
        
        result = tmp <<= 4;
        
        tmp = sourceBytes[i+1];
        if(tmp > '9')
            tmp = toupper(tmp) - 'A' + 0x0a;
        else
            tmp &= 0x0f;
        result += tmp;
        [resultData appendBytes:&result length:1];
    }
    
    return resultData;
}

/**
 * 计算两组byte数组异或后的值。两组的大小要一致。
 * @param bytesData1 NSData1
 * @param bytesData2 NSData2
 * @return    异或后的NSData
 */
+(NSData *)BytesData:(NSData *)bytesData1 XOR:(NSData *)bytesData2
{
    Byte *bytes1 = (Byte *)[bytesData1 bytes];
    Byte *bytes2 = (Byte *)[bytesData2 bytes];
    int len1 = (int)[bytesData1 length];
    int len2 = (int)[bytesData2 length];
    if (len1 != len2) {
        NSLog(@"不能进行模二加！");
        return nil;
    }
    
    Byte ByteXOR[len1];
    Byte temp1;
    Byte temp2;
    Byte temp3;
    for (int i = 0; i < len1; i++) {
        temp1 = bytes1[i];
        temp2 = bytes2[i];
        temp3 = (temp1 ^ temp2);
        ByteXOR[i] = temp3;
    }
    return [NSData dataWithBytes:ByteXOR length:len1];
}


//计算一个NSData逐个字节异或后的值
+(Byte) XOR:(NSData *)sourceData
{
    Byte *inData = (Byte *)[sourceData bytes];
    int len = (int)[sourceData length];
    Byte outData = 0x00;
    for (int i = 0; i < len; i++) {
        outData = (outData^inData[i]);
    }
    return outData;
}

//将两个字节3X 3X 转换--》XX（一个字节）（例如0x31 0x3b ----》 0x1b ）
+(NSData *)twoOneWith3xData:(NSData *)_3xData
{
    int len = (int)[_3xData length];
    Byte *inData = (Byte*)[_3xData bytes];
    if(len%2!=0)
        return nil;
    Byte outData[len/2];
    for (int i = 0,j = 0; i < len; j++,i+=2) {
        outData[j] = (Byte)(((inData[i]&0x0000000f)<<4) |(inData[i+1]&0x0000000f));
    }
    return [NSData dataWithBytes:outData length:len/2];
}

//将XX（一个字节） 转换--》3x 3x （例如 0x1b ----》 0x31 0x3b 并显示成字符"1;"）
+(NSString *)oneTwo3xString:(NSData *)sourceData
{
    int len = (int)[sourceData length];
    Byte *inData = (Byte*)[sourceData bytes];
    Byte outData[len*2+1];
    for (int i =0,j=0; i<len; i++,j+=2) {
        outData[j] = (Byte)(((inData[i]&0x000000f0)>>4)+0x30);
        outData[j+1] = (Byte)((inData[i]&0x0000000f)+0x30);
    }
    outData[len*2]=0;
    return [NSString stringWithCString:outData encoding:NSUTF8StringEncoding];;
}


//将XX（一个字节） 转换--》3x 3x （例如 0x1b ----》 0x31 0x3b ）
+(NSData *)oneTwo3xData:(NSData *)sourceData
{
    int len = (int)[sourceData length];
    Byte *inData = (Byte*)[sourceData bytes];
    Byte outData[len*2];
    for (int i =0,j=0; i<len; i++,j+=2) {
        outData[j] = (Byte)(((inData[i]&0x000000f0)>>4)+0x30);
        outData[j+1] = (Byte)((inData[i]&0x0000000f)+0x30);
    }
    return [NSData dataWithBytes:outData length:len*2];
}


//指纹仪图片数据 --》 bmp 图片数据
+ (NSData *)Raw2Bmp:(NSData *)pRawData X:(int)x Y:(int)y
{
    int num;
    int i, j;
    
    int length = (int)[pRawData length];
    Byte *pRaw =(Byte *)[pRawData bytes];
    
    Byte head[1078];
    Byte pBmp[1078+length];
    
    Byte temp[54] = { 0x42, 0x4d, // file header
        0x00, 0x00, 0x00, 0x00, // file size***
        0x00, 0x00, // reserved
        0x00, 0x00,// reserved
        0x36, 0x04, 0x00, 0x00,// head byte***
        0x28, 0x00, 0x00, 0x00,// struct size
        0x00, 0x00, 0x00, 0x00,// map width***
        0x00, 0x00, 0x00, 0x00,// map height***
        0x01, 0x00,// must be 1
        0x08, 0x00,// color count***  颜色位1，2，4，8，16，24
        0x00, 0x00, 0x00, 0x00, // compression
        0x00, 0x00, 0x00, 0x00,// data size***
        0x00, 0x00, 0x00, 0x00, // dpix
        0x00, 0x00, 0x00, 0x00, // dpiy
        0x00, 0x00, 0x00, 0x00,// color used
        0x00, 0x00, 0x00, 0x00,// color important
    };
    
    memcpy(head, temp, 54);
    // 确定图象宽度数值
    num = x;
    head[18] = (Byte) (num & 0x000000FF);
    num = num >> 8;
    head[19] = (Byte) (num & 0x000000FF);
    num = num >> 8;
    head[20] = (Byte) (num & 0x000000FF);
    num = num >> 8;
    head[21] = (Byte) (num & 0x000000FF);
    // 确定图象高度数值
    num = y;
    head[22] = (Byte) (num & 0x000000FF);
    num = num >> 8;
    head[23] = (Byte) (num & 0x000000FF);
    num = num >> 8;
    head[24] = (Byte) (num & 0x000000FF);
    num = num >> 8;
    head[25] = (Byte) (num & 0x000000FF);
    // 确定调色板数值
    j = 0;
    for (i = 54; i < 1078; i = i + 4) {
        head[i] = head[i + 1] = head[i + 2] = (Byte) j;
        head[i + 3] = 0;
        j++;
    }
    // 写入文件头
    memcpy(pBmp, head, 1078);
    // 写入图象数据
    for (i = 0; i < y; i++) {
        memcpy(pBmp + 1078 + (y - 1 - i) * x , pRaw + i * x , x);
    }
    return [NSData dataWithBytes:pBmp length:1078+length];
}

@end
