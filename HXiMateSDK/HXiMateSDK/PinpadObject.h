//
//  PinpadObject.h
//  HXiMateSDK
//
//  Created by hxsmart on 14-6-27.
//  Copyright (c) 2014年 hxsmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iMateAppFace+Pinpad.h"

@interface PinPadObject :NSObject

@property (nonatomic) int algorithm;
@property int  masterIndex;
@property int  masterLength;
@property (nonatomic, strong) NSData *masterKey;
@property int  workingIndex;
@property int  workingLength;
@property (nonatomic, strong) NSData *workingKey;
@property (nonatomic)BOOL isAutoReturn;
@property (nonatomic, strong) NSString *cardNo;
@property int  pinLength;
@property int  timeout;
@property int  cryptoMode;
@property int  dataLength;
@property (nonatomic, strong) NSData *data;

@end

@interface PinPadData : NSObject

@property int retCode;
@property (nonatomic, strong) NSData *responseData;
@property (nonatomic, strong) NSString *errroStr;
@property PinPadRequestType pinPadRequsetType;

@end

