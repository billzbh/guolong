//
//  iMateAppFacePrivate.h
//  HXSmartSDKDebug
//
//  Created by hxsmart on 13-8-10.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#ifndef _iMateAppFacePrivate_h
#define _iMateAppFacePrivate_h

#import "SyncCommon.h"
#import "PinpadObject.h"
#import "iMateData.h"
#import "EADSessionController.h"

@interface FingerprintObject : NSObject

@property (nonatomic) int retCode;
@property (nonatomic) int requestType;
@property (nonatomic, strong) NSData *responseData;
@property (nonatomic, strong) NSString *error;

@end

@interface iMateAppFace () {
    NSInteger resetCardTag;
}

@property BOOL isMateConnected;
@property BOOL isPrinterConnected;
@property BOOL isMposConnected;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) EADSessionController *iMateEADSessionController;
@property (nonatomic, strong) EADSessionController *printerEADSessionController;
@property (nonatomic, strong) iMateData *imateDataObj;
@property (nonatomic, strong) EAAccessory *iMateAccessory;
@property (nonatomic, strong) EAAccessory *printerAccessory;
@property (nonatomic, strong) SyncCommon *syncCommon;

@property (nonatomic, strong) id pinPad;
@property (nonatomic, strong) id fingerprint;
@property (nonatomic, strong) id printer;

@property (strong, nonatomic) NSString *deviceVersion;
@property (strong, nonatomic) NSString *deviceTermId;
@property (strong, nonatomic) NSString *deviceSerialNumber;

@property (strong, nonatomic) NSString *firmwareVersion;
@property (strong, nonatomic) NSString *hardwareVersion;


-(void)setSyncRequestType:(BOOL)isSync;
-(void)iMateDataReset;
-(BOOL)checkWorkStatus;
- (void)accessoryWriteData:(NSData *)data;

@end

#endif
