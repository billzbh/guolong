//
//  iCRPub.h
//  HXiMateSDK
//
//  Created by zbh on 15/12/8.
//  Copyright © 2015年 hxsmart. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface iCRPub : NSObject

+ (NSData *)twoOneData:(NSString *)sourceString;

+ (NSString *)oneTwoData:(NSData *)sourceData;

+(NSData *)twoOneWith3xData:(NSData *)_3xData;

+(NSData *)oneTwo3xData:(NSData *)sourceData;

+(NSString *)oneTwo3xString:(NSData *)sourceData;

+(NSData *)BytesData:(NSData *)bytesData1 XOR:(NSData *)bytesData2;

+(Byte) XOR:(NSData *)sourceData;

+ (NSData *)Raw2Bmp:(NSData *)pRawData X:(int)x Y:(int)y;

@end
