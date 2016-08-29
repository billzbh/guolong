//
//  iMateAppFace+Pboc.m
//  HXiMateSDK
//
//  Created by hxsmart on 13-12-23.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import "iMateAppFacePrivate.h"
#import "iMateAppFace+Pboc.h"
#import "vposface.h"
#import "EmvProc.h"
#import "IssFace.h"
#import "iMateExt.h"
#import "PbocHigh.h"

@interface ResponsePboc : NSObject
@property NSInteger retCode;
@property (nonatomic, strong) NSString *cardInfo;
@property (nonatomic, strong) NSString *error;
@property NSInteger logNum;
@property (nonatomic, strong) NSArray *cardLog;
@end

@implementation ResponsePboc

- (void)responsePbocCardInfo:(NSInteger)retCode info:(NSString *)cardInfo error:(NSString *)error
{
    _retCode = retCode;
    _cardInfo = cardInfo;
    _error = error;
}
- (void)responsePbocCardLog:(NSInteger)retCode logInfo:(NSString *)logInfo logNum:(NSInteger)logNum error:(NSString *)error
{
    _retCode = retCode;
    _error = error;
    _cardLog = nil;
    
    if ( logInfo && logNum ) {
        unsigned long recordLength = [logInfo length]/logNum;
        NSMutableArray *logArray = [[NSMutableArray alloc] initWithCapacity:logNum];
        for (int i=0; i<logNum; i++)
            [logArray addObject:[logInfo substringWithRange:(NSMakeRange(i*recordLength, recordLength))]];
        _cardLog = logArray;
    }
}
- (void)responsePbocIssCard:(NSInteger)retCode error:(NSString *)error
{
    _retCode = retCode;
    _error = error;
}

@end

@implementation iMateAppFace (Pboc)

// 设置IC读卡器类型，cardReaderType: 0 芯片读卡器；1 射频读卡器
- (void)pbocIcCardReaderType:(int)cardReaderType;
{
    vSetCardReaderType(cardReaderType);
}

- (void)pbocReadInfo
{
    if(![self checkWorkStatus])
        return;
    
    //start pboc read card thread
    [self performSelectorInBackground:@selector(pbocReadInfoThread) withObject:nil];
    
}

- (void)pbocReadInfoEx:(int)outType
{
    if(![self checkWorkStatus])
        return;
    
    //start pboc read card thread
    [self performSelectorInBackground:@selector(pbocReadInfoThreadEx:) withObject:[NSNumber numberWithInt:outType]];
}

- (void)pbocReadLog
{
    if(![self checkWorkStatus])
        return;
    
    //start pboc read card thread
    [self performSelectorInBackground:@selector(pbocReadLogThread) withObject:nil];
    
}

- (void)pbocIssCard:(NSData *)issData
{
    if(![self checkWorkStatus])
        return;
    
    //start pboc read card thread
    [self performSelectorInBackground:@selector(pbocIssCardThread:) withObject:issData];
}

- (NSString *)pbocError:(NSInteger)retCode
{
    switch (retCode) {
		case HXEMV_OK:
			return nil;
		case HXEMV_NA:
			return @"不可用";
		case HXEMV_PARA:
			return @"参数错误";
		case HXEMV_LACK_MEMORY:
			return @"存储空间不足";
		case HXEMV_CORE:
			return @"内部错误";
		case HXEMV_NO_SLOT:
			return @"不支持的卡座";
		case HXEMV_NO_CARD:
			return @"卡片不存在";
		case HXEMV_CANCEL:
			return @"用户取消";
		case HXEMV_TIMEOUT:
			return @"超时";
		case HXEMV_NO_APP:
			return @"无支持的应用";
		case HXEMV_AUTO_SELECT:
			return @"获取的应用可自动选择";
		case HXEMV_CARD_REMOVED:
			return @"卡被取走";
		case HXEMV_CARD_OP:
			return @"卡操作错";
		case HXEMV_CARD_SW:
			return @"非法卡指令状态字";
		case HXEMV_NO_DATA:
			return @"无数据";
		case HXEMV_NO_RECORD:
			return @"无记录";
		case HXEMV_NO_LOG:
			return @"卡片不支持交易流水记录";
		case HXEMV_TERMINATE:
			return @"满足拒绝条件，交易终止";
		case HXEMV_USE_MAG:
			return @"请使用磁条卡";
		case HXEMV_RESELECT:
			return @"需要重新选择应用";
		case HXEMV_NOT_SUPPORTED:
			return @"不支持";
		case HXEMV_DENIAL:
			return @"交易拒绝";
		case HXEMV_DENIAL_ADVICE:
			return @"交易拒绝, 有Advice";
		case HXEMV_NOT_ALLOWED:
			return @"服务不允许";
		case HXEMV_TRANS_NOT_ALLOWED:
			return @"交易不允许";
		case HXEMV_FLOW_ERROR:
			return @"EMV流程错误";
		case HXEMV_CALLBACK_METHOD:
			return @"回调与非回调核心接口调用错误";
		case HXEMV_NOT_ACCEPTED:
			return @"不接受";
    }
    return @"其它错误";
}

- (int)pbocInterfaceInit
{
    // 接口初始化
    int retCode = iHxEmvInit(iIMateTestCard, iIMateResetCard, iIMateExchangeApdu, iIMateCloseCard);
    if (retCode)
        return retCode;

    stHxTermParam hxTermParam;
    
    memset(&hxTermParam, 0, sizeof(hxTermParam));
    hxTermParam.ucTermType = 0x22;
    memcpy(hxTermParam.sTermCapability, "\xA0\xE9\xC8", 3);
    memcpy(hxTermParam.sAdditionalTermCapability, "\xEF\x80\xF0\x30\x00", 5);
    strcpy(hxTermParam.szMerchantId,"123456789000001");
    strcpy(hxTermParam.szTermId, "12345678");
    strcpy(hxTermParam.szMerchantNameLocation, "福田泰然212栋401");
    hxTermParam.uiTermCountryCode = 156;
    strcpy(hxTermParam.szAcquirerId, "99999999999");
    hxTermParam.iMerchantCategoryCode = -1;
	hxTermParam.ucPinBypassBehavior = 0;
	hxTermParam.ucAppConfirmSupport = 0;
    
    // Set AidCommonPara in hxTermParam
    memcpy(hxTermParam.AidCommonPara.sTermAppVer, "\x00\x30", 2);
    hxTermParam.AidCommonPara.ulFloorLimit = 200000;
    hxTermParam.AidCommonPara.iMaxTargetPercentage = 90;
    hxTermParam.AidCommonPara.iTargetPercentage = 40;
    hxTermParam.AidCommonPara.ulThresholdValue = 50000;
    hxTermParam.AidCommonPara.ucECashSupport = 1;
    strcpy(hxTermParam.AidCommonPara.szTermECashTransLimit, "200000");
    hxTermParam.AidCommonPara.ucTacDefaultExistFlag = 1;
    //memcpy(hxTermParam.AidCommonPara.sTacDefault, "\xFC\x70\xF8\xD8\x00", 5);
    memcpy(hxTermParam.AidCommonPara.sTacDefault, "\xFF\xFF\xFF\xFF\xFF", 5);
    hxTermParam.AidCommonPara.ucTacDenialExistFlag = 1;
    //memcpy(hxTermParam.AidCommonPara.sTacDenial, "\x00\x00\xB8\x00\x00", 5);
    memcpy(hxTermParam.AidCommonPara.sTacDenial, "\x00\x00\x00\x00\x00", 5);
    hxTermParam.AidCommonPara.ucTacOnlineExistFlag = 1;
    memcpy(hxTermParam.AidCommonPara.sTacOnline, "\xFF\xFF\xFF\xFF\xFF", 5);
    hxTermParam.AidCommonPara.iDefaultDDOLLen = -1;
    hxTermParam.AidCommonPara.iDefaultTDOLLen = -1;

    retCode = iHxEmvSetParam(&hxTermParam);
    if (retCode)
        return retCode;
    
    stHxTermAid hxTermAidNull;
    memset(&hxTermAidNull, 0, sizeof(hxTermAidNull));
    
    hxTermAidNull.ucAidLen = 0;
    hxTermAidNull.ucASI = 0;
    hxTermAidNull.cOnlinePinSupport = -1;
    
    memcpy(hxTermAidNull.sTermAppVer, "\xff\xff", 2);
    hxTermAidNull.ulFloorLimit = 0xFFFFFFFF;
    hxTermAidNull.iMaxTargetPercentage = -1;
    hxTermAidNull.iTargetPercentage = -1;
    hxTermAidNull.ulThresholdValue = 0xFFFFFFFF;
    hxTermAidNull.ucECashSupport = 0xff;
    strcpy(hxTermAidNull.szTermECashTransLimit, "");
    hxTermAidNull.ucTacDefaultExistFlag = 0;
    hxTermAidNull.ucTacDenialExistFlag = 0;
    hxTermAidNull.ucTacOnlineExistFlag = 0;
    hxTermAidNull.iDefaultDDOLLen = -1;
    hxTermAidNull.iDefaultTDOLLen = -1;
    
    stHxTermAid hxTermAid[9];
    
    memset(&hxTermAid, 0, sizeof(hxTermAid));
    for (int i = 0; i < 9; i++) {
        memcpy(&hxTermAid[i], &hxTermAidNull, sizeof(stHxTermAid));
        switch (i) {
            case 0:
                hxTermAid[i].ucAidLen = 5;
                memcpy(hxTermAid[i].sAid, "\xA0\x00\x00\x03\x33", 5);
                hxTermAid[i].ucASI = 0;
                break;
            case 1:
                hxTermAid[i].ucAidLen = 8;
                memcpy(hxTermAid[i].sAid, "\xA0\x00\x00\x03\x33\x01\x01\x01", 8);
                hxTermAid[i].ucASI = 1;
                break;
            case 2:
                hxTermAid[i].ucAidLen = 8;
                memcpy(hxTermAid[i].sAid, "\xA0\x00\x00\x03\x33\x01\x01\x02", 8);
                hxTermAid[i].ucASI = 1;
                break;
            case 3:
                hxTermAid[i].ucAidLen = 8;
                memcpy(hxTermAid[i].sAid, "\xA0\x00\x00\x03\x33\x01\x01\x03", 8);
                hxTermAid[i].ucASI = 1;
                break;
            case 4:
                hxTermAid[i].ucAidLen = 8;
                memcpy(hxTermAid[i].sAid, "\xA0\x00\x00\x03\x33\x01\x01\x04", 8);
                hxTermAid[i].ucASI = 1;
                break;
            case 5:
                hxTermAid[i].ucAidLen = 8;
                memcpy(hxTermAid[i].sAid, "\xA0\x00\x00\x03\x33\x01\x01\x05", 8);
                hxTermAid[i].ucASI = 1;
                break;
            case 6:
                hxTermAid[i].ucAidLen = 8;
                memcpy(hxTermAid[i].sAid, "\xA0\x00\x00\x03\x33\x01\x01\x06", 8);
                hxTermAid[i].ucASI = 1;
                break;
            case 7:
                hxTermAid[i].ucAidLen = 8;
                memcpy(hxTermAid[i].sAid, "\xA0\x00\x00\x03\x33\x01\x01\x07", 8);
                hxTermAid[i].ucASI = 1;
                break;
            case 8:
                hxTermAid[i].ucAidLen = 8;
                memcpy(hxTermAid[i].sAid, "\xA0\x00\x00\x03\x33\x01\x01\x08", 8);
                hxTermAid[i].ucASI = 1;
                break;
        }
        
    }
    retCode = iHxEmvLoadAid(&hxTermAid[0], 9);
    return retCode;
}

#pragma mark pboc2.0 thread

- (void)pbocReadInfoThread
{
    @autoreleasepool {
        
        char szAccountNo[20+1];
        char szHolderName[45+1];
        char szHolderId[40+1];
        char szExpDate[8+1];
        char szPanSequence[2+1];
        
        NSString *error = nil;
        NSString *info = nil;
        
        memset(szAccountNo, 0, sizeof(szAccountNo));
        memset(szHolderName, 0, sizeof(szHolderName));
        memset(szHolderId, 0, sizeof(szHolderId));
        memset(szExpDate, 0, sizeof(szExpDate));
        memset(szPanSequence, 0, sizeof(szPanSequence));
        
        //Pboc核心初始化，设置交易参数
        iHxPbocHighInitCore("123456789000001", "12345601", "building 212", 156, 156);
        
        unsigned char szDateTime[14+1];
        _vGetTime(szDateTime);
        
        char szField55[513]; //55域缓冲
        char szPan[20], szTrack2[40];
        int  iPanSeqNo;
        char szExtInfo[513];
        int retCode = iHxPbocHighInitTrans(szDateTime, 1L, 0x00, (unsigned char *)"0",
                                       szField55, szPan, &iPanSeqNo, szTrack2, szExtInfo);
        if (retCode == HXEMV_OK) {
            unsigned char sOutTlvData[256];
            unsigned char sOutData[256];
            int iOutTlvDataLen = sizeof(sOutTlvData);
            int iOutDataLen = sizeof(sOutData);

            memset(sOutData, 0, sizeof(sOutData));
            retCode = iHxEmvGetData("\x5A", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
            if (retCode == HXEMV_OK) {
                strcpy(szAccountNo, sOutData);
            }

            iOutTlvDataLen = sizeof(sOutTlvData);
            iOutDataLen = sizeof(sOutData);
            memset(sOutData, 0, sizeof(sOutData));
            retCode = iHxEmvGetData("\x9F\x0B", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
            if (retCode != HXEMV_OK) {
                retCode = iHxEmvGetData("\x5F\x20", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
            }
            if (retCode == HXEMV_OK) {
                strcpy(szHolderName, sOutData);
            }

            iOutTlvDataLen = sizeof(sOutTlvData);
            iOutDataLen = sizeof(sOutData);
            memset(sOutData, 0, sizeof(sOutData));
            retCode = iHxEmvGetData("\x9F\x61", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
            if (retCode == HXEMV_OK) {
                strcpy(szHolderId, sOutData);
            }

            iOutTlvDataLen = sizeof(sOutTlvData);
            iOutDataLen = sizeof(sOutData);
            memset(sOutData, 0, sizeof(sOutData));
            retCode = iHxEmvGetData("\x5F\x24", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
            if (retCode == HXEMV_OK) {
                strcpy(szExpDate, sOutData);
            }

            iOutTlvDataLen = sizeof(sOutTlvData);
            iOutDataLen = sizeof(sOutData);
            memset(sOutData, 0, sizeof(sOutData));
            retCode = iHxEmvGetData("\x5F\x34", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
            if (retCode == HXEMV_OK) {
                strcpy(szPanSequence, sOutData);
            }
            info = [NSString stringWithFormat:@"%s,%s,%s,%s,%s",szAccountNo,szHolderName,szHolderId,szExpDate, szPanSequence];
            
            retCode = HXEMV_OK;
        }
        error = [self pbocError:retCode];
        ResponsePboc *cardInfoObject = [[ResponsePboc alloc] init];
        [cardInfoObject responsePbocCardInfo:retCode info:info error:error];
        [self performSelectorOnMainThread:@selector(delegatePbocReadInfoResponse:) withObject:cardInfoObject waitUntilDone:YES];
        
//        int retCode = [self pbocInterfaceInit];
//        if (retCode == HXEMV_OK) {
//            retCode = iHxEmvTransInit(0);
//            if (retCode == HXEMV_OK) {
//                stHxAdfInfo hxAdfInfo;
//                int iHxAdfNum = 1;
//                retCode = iHxEmvGetSupportedApp(1, &hxAdfInfo, &iHxAdfNum);
//                if (retCode == HXEMV_OK || retCode == HXEMV_AUTO_SELECT) {
//                    retCode = iHxEmvAppSelect(1, hxAdfInfo.ucAdfNameLen, hxAdfInfo.sAdfName);
//                    if (retCode == HXEMV_OK) {
//                        unsigned char szDateTime[14+1];
//                        _vGetTime(szDateTime);
//                        retCode = iHxEmvGPO(szDateTime, 1L, 0x00, "0", 156);
//                        retCode = HXEMV_OK;
//                        if (retCode == HXEMV_OK) {
//                            retCode = iHxEmvReadRecord();
//                            if (retCode == HXEMV_OK) {
//                                unsigned char sOutTlvData[256];
//                                unsigned char sOutData[256];
//                                int iOutTlvDataLen = sizeof(sOutTlvData);
//                                int iOutDataLen = sizeof(sOutData);
//                                
//                                memset(sOutData, 0, sizeof(sOutData));
//                                retCode = iHxEmvGetData("\x5A", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
//                                if (retCode == HXEMV_OK) {
//                                    strcpy(szAccountNo, sOutData);
//                                }
//                                
//                                iOutTlvDataLen = sizeof(sOutTlvData);
//                                iOutDataLen = sizeof(sOutData);
//                                memset(sOutData, 0, sizeof(sOutData));
//                                retCode = iHxEmvGetData("\x9F\x0B", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
//                                if (retCode != HXEMV_OK) {
//                                    retCode = iHxEmvGetData("\x5F\x20", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
//                                }
//                                if (retCode == HXEMV_OK) {
//                                    strcpy(szHolderName, sOutData);
//                                }
//                                
//                                iOutTlvDataLen = sizeof(sOutTlvData);
//                                iOutDataLen = sizeof(sOutData);
//                                memset(sOutData, 0, sizeof(sOutData));
//                                retCode = iHxEmvGetData("\x9F\x61", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
//                                if (retCode == HXEMV_OK) {
//                                    strcpy(szHolderId, sOutData);
//                                }
//                                
//                                iOutTlvDataLen = sizeof(sOutTlvData);
//                                iOutDataLen = sizeof(sOutData);
//                                memset(sOutData, 0, sizeof(sOutData));
//                                retCode = iHxEmvGetData("\x5F\x24", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
//                                if (retCode == HXEMV_OK) {
//                                    strcpy(szExpDate, sOutData);
//                                }
//                                
//                                iOutTlvDataLen = sizeof(sOutTlvData);
//                                iOutDataLen = sizeof(sOutData);
//                                memset(sOutData, 0, sizeof(sOutData));
//                                retCode = iHxEmvGetData("\x5F\x34", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
//                                if (retCode == HXEMV_OK) {
//                                    strcpy(szPanSequence, sOutData);
//                                }
//                                info = [NSString stringWithFormat:@"%s,%s,%s,%s,%s",szAccountNo,szHolderName,szHolderId,szExpDate, szPanSequence];
//                                
//                                retCode = HXEMV_OK;
//                            }
//                        }
//                    }
//                }
//            }
//            error = [self pbocError:retCode];
//            ResponsePboc *cardInfoObject = [[ResponsePboc alloc] init];
//            [cardInfoObject responsePbocCardInfo:retCode info:info error:error];
//            [self performSelectorOnMainThread:@selector(delegatePbocReadInfoResponse:) withObject:cardInfoObject waitUntilDone:YES];
//        }
    }
#ifdef DEBUG
        NSLog(@"pbocReadInfoThread end");
#endif
}

- (void)pbocReadInfoThreadEx:(NSNumber *)outType
{
    @autoreleasepool {
        char szAccountNo[20+1];
        char szHolderName[45+1];
        char szHolderId[40+1];
        char szExpDate[8+1];
        char szPanSequence[2+1];
        char szTrack1[200+1], szTrack2[37+1];
        char szIdType[2+1];
        char szEcBalance[12+1], szEcBalanceLimit[12+1];
        
        NSString *error = nil;
        NSString *info = nil;
        
        memset(szAccountNo, 0, sizeof(szAccountNo));
        memset(szHolderName, 0, sizeof(szHolderName));
        memset(szHolderId, 0, sizeof(szHolderId));
        memset(szExpDate, 0, sizeof(szExpDate));
        memset(szPanSequence, 0, sizeof(szPanSequence));
        memset(szTrack1, 0, sizeof(szTrack1));
        memset(szTrack2, 0, sizeof(szTrack2));
        memset(szIdType, 0, sizeof(szIdType));
        memset(szEcBalance, 0, sizeof(szEcBalance));
        memset(szEcBalanceLimit, 0, sizeof(szEcBalanceLimit));
        
        int retCode = [self pbocInterfaceInit];
        if (retCode == HXEMV_OK) {
            retCode = iHxEmvTransInit(0);
            if (retCode == HXEMV_OK) {
                stHxAdfInfo hxAdfInfo;
                int iHxAdfNum = 1;
                retCode = iHxEmvGetSupportedApp(1, &hxAdfInfo, &iHxAdfNum);
                if (retCode == HXEMV_OK || retCode == HXEMV_AUTO_SELECT) {
                    retCode = iHxEmvAppSelect(1, hxAdfInfo.ucAdfNameLen, hxAdfInfo.sAdfName);
                    if (retCode == HXEMV_OK) {
                        unsigned char szDateTime[14+1];
                        _vGetTime(szDateTime);
                        retCode = iHxEmvGPO(szDateTime, 1L, 0x00, "0", 156);
                        if (retCode == HXEMV_OK) {
                            retCode = iHxEmvReadRecord();
                            if (retCode == HXEMV_OK) {
                                unsigned char sOutTlvData[256];
                                unsigned char sOutData[256];
                                int iOutTlvDataLen = sizeof(sOutTlvData);
                                int iOutDataLen = sizeof(sOutData);
                                
                                memset(sOutData, 0, sizeof(sOutData));
                                retCode = iHxEmvGetData("\x5A", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
                                if (retCode == HXEMV_OK) {
                                    strcpy(szAccountNo, sOutData);
                                    iReformString(1, szAccountNo);
                                }
                                
                                iOutTlvDataLen = sizeof(sOutTlvData);
                                iOutDataLen = sizeof(sOutData);
                                memset(sOutData, 0, sizeof(sOutData));
                                retCode = iHxEmvGetData("\x9F\x0B", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
                                if (retCode != HXEMV_OK) {
                                    retCode = iHxEmvGetData("\x5F\x20", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
                                }
                                if (retCode == HXEMV_OK) {
                                    strcpy(szHolderName, sOutData);
                                }
                                
                                iOutTlvDataLen = sizeof(sOutTlvData);
                                iOutDataLen = sizeof(sOutData);
                                memset(sOutData, 0, sizeof(sOutData));
                                retCode = iHxEmvGetData("\x9F\x62", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
                                if (retCode == HXEMV_OK) {
                                    sprintf(szIdType, "%d", sOutData[0]);
                                }
                                
                                iOutTlvDataLen = sizeof(sOutTlvData);
                                iOutDataLen = sizeof(sOutData);
                                memset(sOutData, 0, sizeof(sOutData));
                                retCode = iHxEmvGetData("\x9F\x61", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
                                if (retCode == HXEMV_OK) {
                                    strcpy(szHolderId, sOutData);
                                }
                                
                                iOutTlvDataLen = sizeof(sOutTlvData);
                                iOutDataLen = sizeof(sOutData);
                                memset(sOutData, 0, sizeof(sOutData));
                                retCode = iHxEmvGetData("\x5F\x24", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
                                if (retCode == HXEMV_OK) {
                                    strcpy(szExpDate, sOutData);
                                }
                                
                                iOutTlvDataLen = sizeof(sOutTlvData);
                                iOutDataLen = sizeof(sOutData);
                                memset(sOutData, 0, sizeof(sOutData));
                                retCode = iHxEmvGetData("\x5F\x34", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
                                if (retCode == HXEMV_OK) {
                                    strcpy(szPanSequence, sOutData);
                                    iReformString(0/*0:去除头部'0'*/, szPanSequence);
                                }

                                iOutTlvDataLen = sizeof(sOutTlvData);
                                iOutDataLen = sizeof(sOutData);
                                memset(sOutData, 0, sizeof(sOutData));
                                retCode = iHxEmvGetData("\x57", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
                                if (retCode == HXEMV_OK) {
                                    vOneTwoX0(sOutData, iOutDataLen, szTrack2);
                                    iReformString(1, szTrack2);
                                }
                                
                                iOutTlvDataLen = sizeof(sOutTlvData);
                                iOutDataLen = sizeof(sOutData);
                                memset(sOutData, 0, sizeof(sOutData));
                                retCode = iHxEmvGetData("\x9F\x1F", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
                                if (retCode == HXEMV_OK) {
                                    strcpy(szTrack1, sOutData);
                                }
                                
                                iOutTlvDataLen = sizeof(sOutTlvData);
                                iOutDataLen = sizeof(sOutData);
                                memset(sOutData, 0, sizeof(sOutData));
                                retCode = iHxEmvGetCardNativeData("\x9F\x79", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
                                if (retCode == HXEMV_OK) {
                                    strcpy(szEcBalance, sOutData);
                                    iReformString(0/*0:去除头部'0'*/, szEcBalance);
                                }
                                
                                iOutTlvDataLen = sizeof(sOutTlvData);
                                iOutDataLen = sizeof(sOutData);
                                memset(sOutData, 0, sizeof(sOutData));
                                retCode = iHxEmvGetCardNativeData("\x9F\x77", &iOutTlvDataLen, sOutTlvData, &iOutDataLen, sOutData);
                                if (retCode == HXEMV_OK) {
                                    strcpy(szEcBalanceLimit, sOutData);
                                    iReformString(0/*0:去除头部'0'*/, szEcBalanceLimit);
                                }
                                
                                if (outType.intValue == 0) {
                                    info = [NSString stringWithFormat:
                                            @"<AccountNo>%s</AccountNo>"
                                            "<HolderName>%s</HolderName>"
                                            "<HolderIdType>%s</HolderIdType>"
                                            "<HolderId>%s</HolderId>"
                                            "<Track2>%s</Track2>"
                                            "<Track1>%s</Track1>"
                                            "<EcBalance>%s</EcBalance>"
                                            "<EcBalanceLimit>%s</EcBalanceLimit>"
                                            "<ExpDate>%s</ExpDate>"
                                            "<PanSequence>%s</PanSequence>", szAccountNo, szHolderName, szIdType, szHolderId, szTrack2, szTrack1, szEcBalance, szEcBalanceLimit, szExpDate, szPanSequence];

                                }
                                else {
                                    info = [NSString stringWithFormat:
                                            @"%s,%s,%s,%s,%s,%s,%s,%s,%s,%s", szAccountNo, szHolderName, szIdType, szHolderId, szTrack2, szTrack1, szEcBalance, szEcBalanceLimit, szExpDate, szPanSequence];
                                    
                                }

                                //卡号、姓名、证件类型、证件号、二磁道数据、一磁道数据、现金余额、余额上限、应用失效日期、卡序列号
                                retCode = HXEMV_OK;
                            }
                        }
                    }
                }
            }
            error = [self pbocError:retCode];
            ResponsePboc *cardInfoObject = [[ResponsePboc alloc] init];
            [cardInfoObject responsePbocCardInfo:retCode info:info error:error];
            [self performSelectorOnMainThread:@selector(delegatePbocReadInfoResponse:) withObject:cardInfoObject waitUntilDone:YES];
        }
    }
#ifdef DEBUG
    NSLog(@"pbocReadInfoThreadEx end");
#endif
}

- (void)pbocReadLogThread
{
    @autoreleasepool {
        int iLogNum = 0;
        NSString *error = nil;
        NSMutableString *info = [[NSMutableString alloc] init];
        
        int retCode = [self pbocInterfaceInit];
        if (retCode == HXEMV_OK) {
            retCode = iHxEmvTransInit(0);
            if (retCode == HXEMV_OK) {
                stHxAdfInfo hxAdfInfo;
                int iHxAdfNum = 1;
                retCode = iHxEmvGetSupportedApp(1, &hxAdfInfo, &iHxAdfNum);
                if (retCode == HXEMV_OK || retCode == HXEMV_AUTO_SELECT) {
                    retCode = iHxEmvAppSelect(1, hxAdfInfo.ucAdfNameLen, hxAdfInfo.sAdfName);
                    if (retCode == HXEMV_OK) {
                        int iMaxRecNum = 0;
                        retCode = iHxEmvGetLogInfo(0/*0:交易流水*/, &iMaxRecNum);
                        if (retCode == HXEMV_OK) {
                            if (iMaxRecNum > 10)
                                iMaxRecNum = 10;
                            for (int i = 1; i <= iMaxRecNum; i++) {
                                unsigned char sLog[300];
                                int iLogLen = sizeof(sLog);
                                int ret = iHxEmvReadLog(0/*交易流水*/, i, &iLogLen, sLog);
                                if (ret != HXEMV_OK)
                                    break;
                                unsigned char szLog[600];
                                vOneTwo0(sLog, iLogLen, szLog);
                                [info appendString:[NSString stringWithFormat:@"%s", szLog]];
                                iLogNum++;
                            }
                        }
                    }
                }
            }
            error = [self pbocError:retCode];
            ResponsePboc *logInfoObject = [[ResponsePboc alloc] init];
            [logInfoObject responsePbocCardLog:retCode logInfo:info logNum:iLogNum error:error];
            [self performSelectorOnMainThread:@selector(delegatePbocReadLogResponse:) withObject:logInfoObject waitUntilDone:YES];
        }
#ifdef DEBUG
        NSLog(@"pbocReadLogThread");
#endif
    }
}

- (void)pbocIssCardThread:(NSData *)issData
{
    @autoreleasepool {
        char szErrMsg[80+1];
        memset(szErrMsg, 0, sizeof(szErrMsg));
        
        NSStringEncoding enc =CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF8);
        ResponsePboc *issCardObject = [[ResponsePboc alloc] init];
        
        iIssSetCardCtrlFunc(iIMateTestCard, iIMateResetCard,iIMateExchangeApdu,iIMateCloseCard);
        iIssSetStatusShowFunc(showSatausInUI);
        
#ifdef DEBUG
        int iRet = iIssSetEnv(0, NULL, 0, 1, szErrMsg);
#else
        int iRet = iIssSetEnv(0, NULL, 0, 0, szErrMsg);
#endif
        if ( iRet ) {
            NSString *error = [NSString stringWithCString:szErrMsg encoding:enc];
#ifdef DEBUG
            NSLog(@"iIssSetEnv retCode = %d, Error:%@", iRet, error);
#endif
            [issCardObject responsePbocIssCard:iRet error:error];
            [self performSelectorOnMainThread:@selector(delegatePbocIssCardResponse:) withObject:issCardObject waitUntilDone:YES];
            
            return;
        }
        stIssData IssData;
        
        if (sizeof(IssData) != issData.length) {
            NSString *error = @"发卡数据错误, 需要采用新的数据结构";
#ifdef DEBUG
            NSLog(@"iIssSetData retCode = %d, Error:%@", iRet, error);
#endif
            [issCardObject responsePbocIssCard:-1 error:error];
            [self performSelectorOnMainThread:@selector(delegatePbocIssCardResponse:) withObject:issCardObject waitUntilDone:YES];
            return;
        }
        memcpy(&IssData, issData.bytes, issData.length);
        
        //0:用于发卡 1:用于删除应用
        iRet = iIssSetData(0, &IssData, szErrMsg);
        if ( iRet ) {
            NSString *error = [NSString stringWithCString:szErrMsg encoding:enc];
#ifdef DEBUG
            NSLog(@"iIssSetData retCode = %d, Error:%@", iRet, error);
#endif
            [issCardObject responsePbocIssCard:iRet error:error];
            [self performSelectorOnMainThread:@selector(delegatePbocIssCardResponse:) withObject:issCardObject waitUntilDone:YES];
            return;
        }
        
        iRet = iIssCard(szErrMsg);
        if ( iRet ) {
            NSString *error = [NSString stringWithCString:szErrMsg encoding:enc];
#ifdef DEBUG
            NSLog(@"iIssCard retCode = %d, Error:%@", iRet, error);
#endif
            [issCardObject responsePbocIssCard:iRet error:error];
            [self performSelectorOnMainThread:@selector(delegatePbocIssCardResponse:) withObject:issCardObject waitUntilDone:YES];
            return;
        }
        
        [self performSelectorOnMainThread:@selector(delegatePbocIssCardResponse:) withObject:issCardObject waitUntilDone:YES];
#ifdef DEBUG
        NSLog(@"pbocIssCardThread end");
#endif
    }
}

- (void)delegatePbocReadInfoResponse:(ResponsePboc*)cardInfoObject
{
    if ( [(id<iMateAppFacePbocDelegate>)self.delegate respondsToSelector:@selector(iMateDelegatePbocReadInfo:cardInfo:error:)] ) {
        [(id<iMateAppFacePbocDelegate>)self.delegate iMateDelegatePbocReadInfo:cardInfoObject.retCode cardInfo:cardInfoObject.cardInfo error:cardInfoObject.error];
    }
}

- (void)delegatePbocReadLogResponse:(ResponsePboc*)logInfoObject
{
    if ( [(id<iMateAppFacePbocDelegate>)self.delegate respondsToSelector:@selector(iMateDelegatePbocReadLog:cardLog:error:)] ) {
        [(id<iMateAppFacePbocDelegate>)self.delegate iMateDelegatePbocReadLog:logInfoObject.retCode cardLog:logInfoObject.cardLog error:logInfoObject.error];
    }
}

- (void)delegatePbocIssCardResponse:(ResponsePboc*)logInfoObject
{
    if ( [(id<iMateAppFacePbocDelegate>)self.delegate respondsToSelector:@selector(iMateDelegatePbocIssCard:error:)] ) {
        [(id<iMateAppFacePbocDelegate>)self.delegate iMateDelegatePbocIssCard:logInfoObject.retCode error:logInfoObject.error];
    }
}

- (void)runingStatus:(NSString *)status
{
    @autoreleasepool {
        if ( [(id<iMateAppFacePbocDelegate>)self.delegate respondsToSelector:@selector(iMateDelegateRuningStatus:)] ) {
            [(id<iMateAppFacePbocDelegate>)self.delegate iMateDelegateRuningStatus:status];
        }
    }
}

#pragma mark Call by C

void showSatausInUI(char *pszStatus)
{
    @autoreleasepool {
        iMateAppFace *appFace = [iMateAppFace sharedController];
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF8);
        NSString *status = [NSString stringWithCString:pszStatus encoding:enc];
        
        [appFace performSelectorOnMainThread:@selector(runingStatus:) withObject:status waitUntilDone:NO];
    }
}

int syncCommon(unsigned char *sendData, int sendLength, unsigned char *receivedData, int *receivedLength, int timeout)
{
    @autoreleasepool {
        iMateAppFace *appFace = [iMateAppFace sharedController];
        int iRet = [appFace.syncCommon bluetoothSendRecv:sendData dataLen:sendLength ResponseDataBuf:receivedData timeout:timeout+1];
        if(iRet <= 0) {
            return -1;
        }
        //return [NSData dataWithBytes:receiveBytes+1 length:iRet-1];
        *receivedLength = iRet;
        
        return 0;
    }
}

// 整理字符串
// in  : iFlag   : 标志, 0:去除头部'0' 1:去除尾部'F'
//     : pszData : 待整理字符串
// out : pszData : 整理好的字符串
static int iReformString(int iFlag, uchar *pszData)
{
	int   iLen, i;
	uchar szData[256];
    
	iLen = (int)strlen((char *)pszData);
	switch(iFlag) {
        case 0: // 去除头部'0'
            for(i=0; i<iLen; i++)
                if(pszData[i] != '0')
                    break;
            if(i >= iLen) {
                strcpy((char *)pszData, "0"); // 全是'0'
                break;
            }
            strcpy((char *)szData, (char *)pszData+i);
            strcpy((char *)pszData, (char *)szData);
            break;
        case 1: // 去除尾部'F'
            for(i=iLen-1; i>=0; i--) {
                if(pszData[i]!='F' && pszData[i]!='f')
                    break;
                pszData[i] = 0;
            }
            break;
        default:
            break; // 不整理
	}
	return((int)strlen((char *)pszData));
}


@end
