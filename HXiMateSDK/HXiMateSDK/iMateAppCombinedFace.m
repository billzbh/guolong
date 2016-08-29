//
//  iMateAppCombinedFace.m
//  HXiMateSDK
//
//  Created by hxsmart on 14-7-3.
//  Copyright (c) 2014年 hxsmart. All rights reserved.
//

#import "iMateAppCombinedFace.h"
#import "iMateAppFace.h"
#import "iMateAppFace+Pinpad.h"
#import "iMateAppFace+Fingerprint.h"
#import "iMateAppFace+Pboc.h"
#import "PbocHigh.h"

static iMateAppCombinedFace *sg_imateAppCombinedFace;

@interface iMateAppCombinedFace () <iMateAppFaceDelegate, iMateAppFacePinpadDelegate, iMateAppFaceFingerprintDelegate, iMateAppFacePbocDelegate>

@property (nonatomic) int requestType;
@property(strong, nonatomic) iMateAppFace *imateAppFace;
@property (strong, nonatomic) NSData *pbocCardResetAtrData;

@end

@implementation iMateAppCombinedFace

// 获取iMateFace实例
+ (iMateAppCombinedFace *)sharedController
{
    if (sg_imateAppCombinedFace == nil) {
        sg_imateAppCombinedFace =[[iMateAppCombinedFace alloc] init];
        sg_imateAppCombinedFace.imateAppFace = [iMateAppFace sharedController];
    }
    return sg_imateAppCombinedFace;
}

// 打开与iMate的连接会话，返回YES会话建立成功
- (BOOL)openSession
{
    _imateAppFace.delegate = self;
    return [_imateAppFace openSession];
}

// 关闭与iMate的连接会话
- (void)closeSession
{
    [_imateAppFace closeSession];
}

// 检测蓝牙连接是否正常，返回YES表示连接正常
- (BOOL)connectingTest
{
    return [_imateAppFace connectingTest];
}

// iMate产品序列号
- (NSString *)deviceSerialNumber
{
    return [_imateAppFace deviceSerialNumber];
}

// 中断操作，仅对kProcessTypeSwipeCard，kProcessTypeReadIdCard，kProcessTypePbocIcInfo,kProcessTypePbocIcLog操作有效
- (void)cancel
{
    [_imateAppFace cancel];
}

// 检测iMate是否在工作状态，返回YES表示正在工作中。
- (BOOL)isWorking
{
    return [_imateAppFace isWorking];
}

// 查询蓝牙打印机是否连接（目前仅支持普瑞特针式打印机）
- (BOOL)printerConnectingTest
{
    return [_imateAppFace printerConnectingTest];
}

// 打印数据，\n结束
- (void)print:(NSString *)printString
{
    [_imateAppFace print:printString];
}

// 提交iMate处理, 处理的结果由iMateDelegateCombinedResponse响应
- (void)iMateProcessCommit:(iMateProcessType)requestType
         requestDictionary:(NSDictionary *)requestDictionary
{
    
}

// iMate同步处理，直接返回处理的结果，需要线程中执行
- (NSDictionary *)iMateProcessSync:(iMateProcessType)requestType
                 requestDictionary:(NSDictionary *)requestDictionary
{
    return nil;
}

#pragma mark iMateAppFaceDelegate

- (void)iMateDelegateConnectStatus:(BOOL)isConnecting
{
}

- (void)iMateDelegateNoResponse:(NSString *)error
{
    [_delegate iMateDelegateCombinedResponse:kProcessErrorCommunicationTimeout
                                     requestType:_requestType
                                      respondData:nil
                                           error:@"与设备通讯超时"];
}

- (void)iMateDelegateResponsePackError
{
    [_delegate iMateDelegateCombinedResponse:kProcessErrorCommunicationFailure
                                     requestType:_requestType
                                      respondData:nil
                                           error:@"与设备通讯失败"];
}

- (void)iMateDelegateSwipeCard:(NSInteger)returnCode track2:(NSString*)track2 track3:(NSString *)track3 error:(NSString *)error
{
    if (returnCode) {
        [_delegate iMateDelegateCombinedResponse:kProcessErrorOther
                                         requestType:kProcessTypeSwipeCard
                                          respondData:nil
                                               error:error];
        return;
    }
    NSDictionary *respondDictionary = @{kSwipeCard_Track2String : track2 ,
                                         kSwipeCard_Track3String : track3};
    [_delegate iMateDelegateCombinedResponse:0
                                     requestType:kProcessTypeSwipeCard
                                      respondData:respondDictionary
                                           error:nil];
}

- (void)iMateDelegateICResetCard:(NSInteger)returnCode resetData:(NSData *)resetData tag:(NSInteger)tag error:(NSString *)error
{
    //如果复位失败，不再继续
    if ( returnCode ) {
        [_delegate iMateDelegateCombinedResponse:kProcessErrorOther
                                         requestType:(int)tag
                                          respondData:nil
                                               error:error];
        return;
    }
    _pbocCardResetAtrData = resetData;
    
    switch (tag) {
        case kProcessTypePbocIcInfo:
            [_imateAppFace pbocReadInfo];
            break;
        case kProcessTypePbocIcLog:
            [_imateAppFace pbocReadLog];
            break;
        case kProcessTypePbocInitTrans:
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // 耗时的操作
                //int ret = iTest();
                dispatch_async(dispatch_get_main_queue(), ^{
                });
            });
            break;
        case kProcessTypePbocDoTrans:
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // 耗时的操作
                //int ret = iTest();
                dispatch_async(dispatch_get_main_queue(), ^{
                });
            });
            break;
    }
}

- (void)iMateDelegateIDReadMessage:(NSInteger)returnCode information:(NSData *)information photo:(NSData*)photo error:(NSString *)error
{
    if ( returnCode ) {
        [_delegate iMateDelegateCombinedResponse:kProcessErrorOther
                                         requestType:(int)kProcessTypeReadIdCard
                                         respondData:nil
                                               error:error];
        return;
    }
    NSDictionary *respondDictionary = @{kReadIdCard_InfoData : information,
                                        kReadIdCard_PhotoData : photo ,
                                        kReadIdCard_InfoArray : [iMateAppFace processIdCardInfo:information],
                                        kReadIdCard_PhotoImage : [iMateAppFace processIdCardPhoto:photo]};
    [_delegate iMateDelegateCombinedResponse:0
                                     requestType:kProcessTypeSwipeCard
                                     respondData:respondDictionary
                                           error:nil];
}

- (void)iMateDelegateBatteryLevel:(NSInteger)returnCode level:(NSInteger)level error:(NSString *)error
{
    if ( returnCode ) {
        [_delegate iMateDelegateCombinedResponse:kProcessErrorOther
                                         requestType:(int)kProcessTypeBatteryLevel
                                         respondData:nil
                                               error:error];
        return;
    }
    NSDictionary *respondDictionary = @{kBatteryLevel_LevelString : [NSString stringWithFormat:@"%03d", (int)level]};
    
    [_delegate iMateDelegateCombinedResponse:0
                                     requestType:kProcessTypeBatteryLevel
                                     respondData:respondDictionary
                                           error:nil];
}

- (void)iMateDelegateXmemRead:(NSInteger)returnCode data:(NSData *)data error:(NSString *)error
{
    if ( returnCode ) {
        [_delegate iMateDelegateCombinedResponse:kProcessErrorOther
                                         requestType:(int)kProcessTypeXMemRead
                                         respondData:nil
                                               error:error];
        return;
    }
    NSDictionary *respondDictionary = @{kXMemRead_XMemeData : data};
    [_delegate iMateDelegateCombinedResponse:0
                                     requestType:kProcessTypeXMemRead
                                     respondData:respondDictionary
                                           error:nil];
}

- (void)iMateDelegateXmemWrite:(NSInteger)returnCode error:(NSString *)error
{
    if ( returnCode ) {
        [_delegate iMateDelegateCombinedResponse:kProcessErrorOther
                                         requestType:(int)kProcessTypeXMemWrite
                                         respondData:nil
                                               error:error];
        return;
    }
    [_delegate iMateDelegateCombinedResponse:0
                                     requestType:kProcessTypeXMemWrite
                                     respondData:nil
                                           error:nil];
}

- (void)iMateDelegatePbocReadInfo:(NSInteger)returnCode
                         cardInfo:(NSString *)cardInfo
                            error:(NSString *)error
{
    if ( returnCode ) {
        [_delegate iMateDelegateCombinedResponse:kProcessErrorOther
                                         requestType:(int)kProcessTypePbocIcInfo
                                         respondData:nil
                                               error:error];
        return;
    }
    [_delegate iMateDelegateCombinedResponse:0
                                     requestType:kProcessTypePbocIcInfo
                                     respondData:@{kPbocIc_CardInfoArray : [cardInfo componentsSeparatedByString:@","]}
                                           error:nil];
}

- (void)iMateDelegatePbocReadLog:(NSInteger)returnCode cardLog:(NSArray *)cardLog error:(NSString *)error
{
    if ( returnCode ) {
        [_delegate iMateDelegateCombinedResponse:kProcessErrorOther
                                         requestType:(int)kProcessTypePbocIcInfo
                                         respondData:nil
                                               error:error];
        return;
    }
    [_delegate iMateDelegateCombinedResponse:0
                                     requestType:kProcessTypePbocIcInfo
                                     respondData:@{kPbocIc_CardLogArray : cardLog}
                                           error:nil];
}

- (void)iMateDelegatePbocIssCard:(NSInteger)returnCode error:(NSString *)error
{

}

- (void)iMateDelegateRuningStatus:(NSString *)statusString
{
    if ( [_delegate respondsToSelector:@selector(iMateDelegateCombinedRuningStatus:)] )
        [_delegate iMateDelegateCombinedRuningStatus:statusString];
}

#pragma mark printer delegate
- (void)printerDelegateStatusResponse:(NSInteger)status
{
    NSDictionary *respondDictionary;
    switch (status) {
        case PRINTER_OK:
            respondDictionary = @{@"kPrinterStatus_StatusString":@"ok"};
            break;
        case PRINTER_CONNECTED:
            respondDictionary = @{@"kPrinterStatus_StatusString":@"connected"};
            break;
        case PRINTER_NOT_CONNECTED:
            respondDictionary = @{@"kPrinterStatus_StatusString":@"disconnected"};
            break;
        case PRINTER_OUT_OF_PAPER:
            respondDictionary = @{@"kPrinterStatus_StatusString":@"out_of_paper"};
            break;
        case PRINTER_OFFLINE:
            respondDictionary = @{@"kPrinterStatus_StatusString":@"offline"};
            break;
    }
    [_delegate iMateDelegateCombinedResponse:0
                                 requestType:kProcessTypePrinterStatus
                                 respondData:@{kPbocIc_CardLogArray : respondDictionary}
                                       error:nil];
}

#pragma mark pinpad delegate
- (void)pinPadDelegateResponse:(NSInteger)returnCode  requestType:(PinPadRequestType)type responseData:(NSData *)responseData error:(NSString *)error
{
    if ( returnCode ) {
        [_delegate iMateDelegateCombinedResponse:kProcessErrorOther
                                     requestType:_requestType
                                     respondData:nil
                                           error:error];
        return;
    }
    switch (type) {
        case PinPadRequestTypePowerOn:
        case PinPadRequestTypePowerOff:
        case PinPadRequestTypeDownloadMasterKey:
        case PinPadRequestTypeDownloadWorkingKey:
            [_delegate iMateDelegateCombinedResponse:0
                                         requestType:_requestType
                                         respondData:nil
                                               error:nil];
            return;
        case PinPadRequestTypeVersion:
            [_delegate iMateDelegateCombinedResponse:0
                                         requestType:_requestType
                                         respondData:@{kPinpad_VersionString:[NSString stringWithFormat:@"%s",responseData.bytes]}
                                               error:nil];
            break;
        case PinPadRequestTypeInputPinBlock:
            [_delegate iMateDelegateCombinedResponse:0
                                         requestType:_requestType
                                         respondData:@{kPinpad_PinblockString:[iMateAppFace oneTwoData:responseData]}
                                               error:nil];
            break;
        default:
            return;
    }
}

#pragma mark fingerprint delegate
- (void)fingerprintDelegateResponse:(NSInteger)returnCode  requestType:(FingerprintRequestType)type responseData:(NSString *)responseData error:(NSString *)error
{
    if ( returnCode ) {
        [_delegate iMateDelegateCombinedResponse:kProcessErrorOther
                                     requestType:_requestType
                                     respondData:nil
                                           error:error];
        return;
    }
    switch (type) {
        case FingerprintRequestTypePowerOn:
        case FingerprintRequestTypePowerOff:
            [_delegate iMateDelegateCombinedResponse:0
                                         requestType:_requestType
                                         respondData:nil
                                               error:nil];
            break;
        case FingerprintRequestTypeVersion:
            [_delegate iMateDelegateCombinedResponse:0
                                         requestType:_requestType
                                         respondData:@{kFingerprint_VersionString:responseData}
                                               error:nil];
            break;
        case FingerprintRequestTypeFeature:
            [_delegate iMateDelegateCombinedResponse:0
                                         requestType:_requestType
                                         respondData:@{kFingerprint_FeatureString:responseData}
                                               error:nil];
            break;
    }
}


@end
