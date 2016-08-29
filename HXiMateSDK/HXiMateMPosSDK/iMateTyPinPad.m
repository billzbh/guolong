//
//  iMateTyPinPad.m
//  支持凯明扬Pinpad
//
//  Created by hxsmart on 15-1-17.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import "iMateTyPinPad.h"
//#import "EADSessionController.h"
//#import "iMateAppFacePrivate.h"
#import "iMateAppFace+Pinpad.h"
//#import "PinpadObject.h"
#import "HuaxinZhinengService.h"
#import "vPosFace.h"

static iMateTyPinPad *sg_iMatePinPad = nil;
#define TIANYU_DEVICE_PREFIX1 @"TY" 
#define TIANYU_DEVICE_PREFIX2 @"Suppay"
#define TIANYU_DEVICE_PREFIX3 @"HXMP-"

static NSString* bindName = nil;

@interface iMateTyPinPad () <HuaxinZhinengServiceDelegate> {
    volatile BOOL cancelFlag;
    int macOrEncryptFlag; // 0 : Mac, 1 : Encrypt
}

@property (nonatomic, weak) id<iMateAppFacePinpadDelegate>delegate;

@property (nonatomic, strong) HuaxinZhinengService *tyPinpadService;

@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic,strong) NSString* lastSearchName;

@end

@implementation iMateTyPinPad

-(id)init
{
    self = [super init];
    if(self){
        cancelFlag = NO;
        
        _tyPinpadService = [[HuaxinZhinengService alloc] init];
        _tyPinpadService.delegate = self;
    }
    return self;
}

+(iMateTyPinPad *)imatePinPad
{
    if(sg_iMatePinPad == nil){
        sg_iMatePinPad = [[iMateTyPinPad alloc] init];
    }
    
    return sg_iMatePinPad;
}

-(void)cancel
{
    [_tyPinpadService cancel];
}

- (CBPeripheral *)searchTianyuPinpad:(int)timeOut
{
    NSArray *deviceArray = [_tyPinpadService deviceInit:2];
    
    usleep(500000);
    double timeSeconds = [[NSDate date] timeIntervalSince1970] + timeOut;

    while ([[NSDate date] timeIntervalSince1970] < timeSeconds) {
        if (deviceArray && deviceArray.count) {
            for (CBPeripheral *peripheral in deviceArray) {
                if ([peripheral.name containsString:TIANYU_DEVICE_PREFIX1]||[peripheral.name containsString:TIANYU_DEVICE_PREFIX2]||[peripheral.name containsString:TIANYU_DEVICE_PREFIX3])
                    //上报TY的设备
                    if (bindName == nil) {
                        return peripheral;
                    }else{
                        if ([peripheral.name containsString:bindName])
                        {
                            return peripheral;
                        }
                    }
            }
        }
        deviceArray = [_tyPinpadService deviceInit:2];
        usleep(100000);
    }
    return nil;
}

-(void)BindName:(NSString*)TYname
{
    bindName = TYname;
}

-(void)powerOn
{
    if ([_tyPinpadService getDeviceStatus] != 4 /*设备已连接*/ ) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                [_tyPinpadService disconnectDevice];
                _peripheral = [self searchTianyuPinpad:5];
                if (_peripheral == nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"未搜索到iMate手柄，请确保手柄已经开机"];
                    });
                    return;
                }
                if (![_tyPinpadService connectDevice:_peripheral]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"iMate手柄连接失败"];
                    });
                    return;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                        [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypePowerOn responseData:nil error:nil];
                    }
                });
            }
        });
    }
    else {
        if ([[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypePowerOn responseData:nil error:nil];
        }
    }
}

-(void)powerOff
{
    if ([_tyPinpadService getDeviceStatus] == 4 /*设备已连接*/ )
        [_tyPinpadService disconnectDevice];
    
    if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
        [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypePowerOff responseData:nil error:nil];
    }
}

-(void)reset:(BOOL)initFlag
{
    if ([_tyPinpadService getDeviceStatus] != 4) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"iMate手柄未连接"];
        return;
    }
    
    if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
        [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypeReset responseData:nil error:nil];
    }
}

-(void)pinpadVersion
{
    if ([_tyPinpadService getDeviceStatus] != 4) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"iMate手柄未连接"];
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_tyPinpadService getCSN];
    });
}

-(void)downloadMasterKey:(BOOL)is3des index:(int)index masterKey:(Byte *)masterKey keyLength:(int)length
{
    static Byte masterKeySave[20];
    
    if ([_tyPinpadService getDeviceStatus] != 4) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"iMate手柄未连接"];
        return;
    }
    if (length != 20) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:102 requestType:PinPadRequestTypeDownloadMasterKey responseData:nil error:@"主密钥长度错误"];
        }
        return;
        
    }
    memcpy(masterKeySave, masterKey, 20);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            [_tyPinpadService updataMainKey:masterKeySave];
        }
    });
}

-(void)downloadWorkingKey:(BOOL)is3des masterIndex:(int)masterIndex workingIndex:(int)workingIndex workingKey:(Byte *)workingKey keyLength:(int)keyLength
{
    static Byte workingKeySave[20];
    if ([_tyPinpadService getDeviceStatus] != 4) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"iMate手柄未连接"];
        return;
    }
    if (keyLength != 20) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:102 requestType:PinPadRequestTypeDownloadWorkingKey responseData:nil error:@"工作密钥长度错误"];
        }
        return;
        
    }
    memcpy(workingKeySave, workingKey, 20);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSData *cKey, *pinKey, *macKey;
            switch (workingIndex) {
                case 0:
                    pinKey = [NSData dataWithBytes:workingKeySave length:20];
                    break;
                case 1:
                    macKey = [NSData dataWithBytes:workingKeySave length:20];
                    break;
                default:
                    cKey = [NSData dataWithBytes:workingKeySave length:20];
            }
            [_tyPinpadService updataWorkKey:cKey pinKey:pinKey mackey:macKey];
        }
    });
}

-(void)inputPinblock:(BOOL)is3des isAutoReturn:(BOOL)isAutoReturn masterIndex:(int)masterIndex workingIndex:(int)workingIndex cardNo:(NSString *)cardNo pinLength:(int)pinLength timeout:(int)timeout;
{
    static NSString *cardNOcopy;
    cardNOcopy = cardNo;
    if ([_tyPinpadService getDeviceStatus] != 4) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"iMate手柄未连接"];
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            [_tyPinpadService pinBlock:cardNOcopy Tips:@"请输入卡密码:"];
        }
    });
    
}

-(void)encrypt:(BOOL)is3des algo:(int)algo masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength
{
    static Byte dataSave[8];
    
    if ([_tyPinpadService getDeviceStatus] != 4) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"iMate手柄未连接"];
        return;
    }
    if (dataLength != 8) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:104 requestType:PinPadRequestTypeEncrypt responseData:nil error:@"加密的数据必须8字节长度"];
        }
        return;
    }
    
    macOrEncryptFlag = 1;
    memcpy(dataSave, data, dataLength);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSData *macData = [NSData dataWithBytes:dataSave length:8];
                [_tyPinpadService getMacWithMKIndex:0 Message:macData];
        }
    });
}

-(void)mac:(BOOL)is3des masterIndex:(int)masterIndex workingIndex:(int)workingIndex data:(Byte*)data dataLength:(int)dataLength
{
    static Byte dataSave[1024];
    if ([_tyPinpadService getDeviceStatus] != 4) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:@"iMate手柄未连接"];
        return;
    }
    if (dataLength % 8) {
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
            [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:104 requestType:PinPadRequestTypeMac responseData:nil error:@"计算Mac的数据长度必须8的倍数"];
        }
        return;
    }
    
    macOrEncryptFlag = 0;
    memcpy(dataSave, data, dataLength);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSData *macData = [NSData dataWithBytes:dataSave length:dataLength];
            [_tyPinpadService getMacWithMKIndex:0 Message:macData];
        }
    });
}

#pragma mark - 代理方法

- (void)onConnectedDevice:(BOOL)isSuccess
{
    NSLog(@"连接设备结果 = %i",isSuccess);
}

- (void)onConnectedDeviceByName:(BOOL)isSuccess
{
    NSLog(@"通过名称连接设备结果 = %i",isSuccess);
}
- (void)onDisconnectedDevice:(BOOL)isSuccess
{
    NSLog(@"断开连接结果 = %i",isSuccess);
}

- (void)onGetDeviceSN:(NSString *)deviceSN
{
    NSLog(@"获取的DeviceSN为 = %@",deviceSN);
}

- (void)onGetCSN:(NSString *)CSN
{
    NSLog(@"获取的CSN为 = %@",CSN);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (CSN == nil) {
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:1 requestType:PinPadRequestTypeVersion responseData:nil error:@"获取手柄版本号失败"];
            }
        }
        else {
            if ([[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypeVersion responseData:[NSData dataWithBytes:CSN.UTF8String length:CSN.length] error:nil];
            }
        }
    });
    
}
- (void)onUpdataWorkingKey:(BOOL [])isSuccess
{
    NSLog(@"更新ckey结果 = %i",isSuccess[0]);
    NSLog(@"更新pkey结果 = %i",isSuccess[1]);
    NSLog(@"更新mkey结果 = %i",isSuccess[2]);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL result = NO;
        for (int i = 0 ; i < 3; i++) {
            if (isSuccess[i] == YES)
                result = YES;
        }
        if (result) {
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypeDownloadWorkingKey responseData:nil error:nil];
            }
        }
        else {
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:105 requestType:PinPadRequestTypeDownloadWorkingKey responseData:nil error:@"工作密钥下载失败"];
            }
        }
    });
}

- (void)onUpdataMainKey:(BOOL)isSuccess
{
    NSLog(@"更新主密钥结果 = %i",isSuccess);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!isSuccess) {
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:106 requestType:PinPadRequestTypeDownloadMasterKey responseData:nil error:@"更新主密钥失败"];
            }
        }
        else {
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypeDownloadMasterKey responseData:nil error:nil];
            }
        }
    });
}

- (void)onUpdataMac:(NSString *)data
{
    NSLog(@"使用MACKey加密后的结果 = %@",data);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (data == nil) {
            if (macOrEncryptFlag == 0) {
                if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
                    [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:100 requestType:PinPadRequestTypeMac responseData:nil error:@"计算Mac失败"];
                }
            }
            else {
                if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
                    [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:100 requestType:PinPadRequestTypeEncrypt responseData:nil error:@"数据加密失败"];
                }
            }
        }
        else {
            Byte dataByte[8];
            vTwoOne(data.UTF8String, 16, dataByte);
            NSData *result = [NSData dataWithBytes:dataByte length:8];
            if (macOrEncryptFlag == 0) {
                if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
                    [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypeMac responseData:result error:nil];
                }
            }
            else {
                if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
                    [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypeEncrypt responseData:result error:nil];
                }
            }
        }
    });
}

- (void)onPinBlock:(NSString *)pinBlock
{
    NSLog(@"PINBlock之后的结果为[%@]",pinBlock);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (pinBlock == nil) {
            if ([[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ){
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:106 requestType:PinPadRequestTypeInputPinBlock responseData:nil error:@"输入pinblock失败"];
            }
        }else if ([pinBlock length]<=0) {
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:180 requestType:PinPadRequestTypeInputPinBlock responseData:nil error:@"密码为空!"];
            }
        }else if ([pinBlock containsString:@"PinBlock_Error"]) {
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:108 requestType:PinPadRequestTypeInputPinBlock responseData:nil error:@"超时或取消"];
            }
        }
        else {
            Byte dataByte[8];
            vTwoOne(pinBlock.UTF8String, 16, dataByte);
            NSData *result = [NSData dataWithBytes:dataByte length:8];
            if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(pinPadDelegateResponse:requestType:responseData:error:)] ) {
                [(id<iMateAppFacePinpadDelegate>)([[iMateAppFace sharedController] delegate]) pinPadDelegateResponse:0 requestType:PinPadRequestTypeInputPinBlock responseData:result error:nil];
            }
        }
    });
}

- (void)onResetCard:(NSString *)atr
{
    NSLog(@"重置卡片结果 = %@",atr);
}

- (void)onOpenCard:(BOOL)isSuccess
{
    NSString *result = nil;
    if (isSuccess == 1) {
        result = @"成功";
    }
    else
    {
        result = @"失败";
    }
    NSLog(@"打开卡结果:%@",result);
}

- (void)onCloseCard:(BOOL)isSuccess
{
    NSString *result = nil;
    if (isSuccess == 1) {
        result = @"成功";
    }
    else
    {
        result = @"失败";
    }
    NSLog(@"关闭卡结果:%@",result);
}

- (void)onTransCommand:(NSString *)resBuf
{
    NSLog(@"transcommand返回数据 = %@",resBuf);
}
- (void)onDisplay:(BOOL)isSuccess
{
    NSString *result = nil;
    if (isSuccess == 1) {
        result = @"成功";
    }
    else
    {
        result = @"失败";
    }
    NSLog(@"显示结果:%@",result);
}

- (void)onWaitEvent:(NSDictionary *)result
{
    NSLog(@"等待插卡事件结果 = %@",result);
}

- (void)onInputAmount:(NSString *)amount
{
    NSLog(@"输入的金额为 = %@",amount);
}

- (void)onInput:(id)message
{
    NSLog(@"输入的内容为 = %@",message);
}

- (void)onWaitInput:(NSString *)ascKey
{
//    NSData *keyData = nil;
//    NSString *resKey = nil;
//    keyData = [HuaxinZhinengUtils hexStringToBytes:ascKey];
//    NSLog(@"kdata = %@",keyData);
//    int i  = 0;
//    [keyData getBytes:&i length:1];
//    switch (i) {
//        case 0x31:    resKey = @"按键1";    break;
//        case 0x32:    resKey = @"按键2";    break;
//        case 0x33:    resKey = @"按键3";    break;
//        case 0x34:    resKey = @"按键4";    break;
//        case 0x35:    resKey = @"按键5";    break;
//        case 0x36:    resKey = @"按键6";    break;
//        case 0x37:    resKey = @"按键7";    break;
//        case 0x38:    resKey = @"按键8";    break;
//        case 0x39:    resKey = @"按键9";    break;
//        case 0x51:    resKey = @"按键Q取消";    break;
//        case 0x45:    resKey = @"按键E确认";    break;
//        case 0x43:    resKey = @"按键C清除";    break;
//        case 0x4d:    resKey = @"按键M菜单";    break;
//        default:      resKey = @"不允许的按键";  break;
//            
//    }
//    
//    NSLog(@"您按下的按键为：%@",resKey);
}

- (void)onReceiveError:(NSString *)errorCode TradeType:(int)tradeType ErrorMessage:(NSString *)message
{
    NSLog(@"ErrorCode = %@,错误编号 = %i,错误详情 = %@",errorCode,tradeType,message);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( [[[iMateAppFace sharedController] delegate] respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [[[iMateAppFace sharedController] delegate] iMateDelegateNoResponse:message];
    });
}


@end
