//
//  iMateDevice.c
//  HXiMateSDK
//
//  Created by hxsmart on 14-4-17.
//  Copyright (c) 2014年 hxsmart. All rights reserved.
//

#include <stdio.h>
#include "vposface.h"
#include "RemoteFunctions.h"
#include "iMateDevice.h"
#include "WriteLog.h"


int SFID_RUDLL_FingerprintOpen(void)
{
    return iRcTsFingerprintOpen();
}

void SFID_RUDLL_FingerprintClose(void)
{
    vRcTsFingerprintClose();
}

void TSFID_RUDLL_SetOverTime(int _timeout)
{
    vRcTSFID_RUDLL_SetOverTime(_timeout);
}

int TSFID_RUDLL_GetFinger(char fpflag[3],unsigned char fpminu1[200],unsigned char fpminu2[100])
{
    return iRcTSFID_RUDLL_GetFinger(fpflag, fpminu1, fpminu2);
}

int TSFID_RUDLL_EnrollFinger(char fpflag[3],int order,unsigned char fpminu1[200],unsigned char fpminu2[100])
{
    return iRcTSFID_RUDLL_EnrollFinger(fpflag, order, fpminu1, fpminu2);
}

int TSFID_RUDLL_SetDeviceNo(char fpflag[3],unsigned char deviceno[12])
{
    return iRcTSFID_RUDLL_SetDeviceNo(fpflag, deviceno);
}

int TSFID_RUDLL_GetDeviceNo(char fpflag[3],unsigned char deviceno[12])
{
    return iRcTSFID_RUDLL_GetDeviceNo(fpflag, deviceno);
}

void TSFID_RUDLL_GetErrorMSG(int errorno,char msgptr[MAXLENGTH_ERRORMSG])
{
    vRcTSFID_RUDLL_GetErrorMSG(errorno, msgptr);
}

int TSFID_RUDLL_SetDeviceType(char fpflag[3],unsigned char devicetype)
{
    return iRcTSFID_RUDLL_SetDeviceType(fpflag, devicetype);
}

int TSFID_RUDLL_GetDeviceType(char fpflag[3],unsigned char *devicetype)
{
    return iRcTSFID_RUDLL_GetDeviceType(fpflag, devicetype);
}

int TSFID_RUDLL_GetDeviceInfo(char fpflag[3], char firmver[10], char deviceinfo[10])
{
    return iRcTSFID_RUDLL_GetDeviceInfo(fpflag, firmver, deviceinfo);
}

// TF ICC Functions
uint uiSD_Init(void)
{
    return _uiRcSD_Init();
}

void vSD_DeInit(void)
{
    _vRcSD_DeInit();
}

uint uiSDSCConnectDev(void)
{
    return _uiRcSDSCConnectDev();
}

uint uiSDSCDisconnectDev(void)
{
     return _uiRcSDSCDisconnectDev();
}

uint uiSDSCGetFirmwareVer(uchar *psFirmwareVer, uint *puiFirmwareVerLen)
{
    return _uiRcSDSCGetFirmwareVer(psFirmwareVer, puiFirmwareVerLen);
}

uint uiSDSCResetCard(uchar *psAtr, uint *puiAtrLen)
{
    return _uiRcSDSCResetCard(psAtr, puiAtrLen);
}

uint uiSDSCResetController(uint uiSCPowerMode)
{
    return _uiRcSDSCResetController(uiSCPowerMode);
}

uint uiSDSCTransmit(uchar *psCommand, uint uiCommandLen, uint uiTimeOutMode, uchar *psOutData, uint *puiOutDataLen, uint *puiCosState)
{
    return _uiRcSDSCTransmit(psCommand, uiCommandLen, uiTimeOutMode, psOutData, puiOutDataLen, puiCosState);
}

uint uiSDSCTransmitEx(uchar *psCommand, uint uiCommandLen, uint uiTimeOutMode, uchar *psOutData, uint *puiOutDataLen)
{
    return _uiRcSDSCTransmitEx(psCommand, uiCommandLen, uiTimeOutMode, psOutData, puiOutDataLen);
}

uint uiSDSCGetSDKVersion(char *pszVersion, uint *puiVersionLen)
{
    return _uiRcSDSCGetSDKVersion(pszVersion, puiVersionLen);
}

uint uiSDSCGetSCIOType(uint *puiSCIOType)
{
    return _uiRcSDSCGetSCIOType(puiSCIOType);
}
