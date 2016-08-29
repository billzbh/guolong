//
//  PinpadFunctions.c
//  HxPinpad
//
//  Created by hxsmart on 15/4/23.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//

#include <stdlib.h>
#include <string.h>
#include "vposface.h"
#include "PinpadFunctions.h"

static int sg_iDebugFlag = 0;

static int iGenWorkingKey(const char *pszWorkingKeyIn, const char *pszDivData, unsigned char * workingKeyOut)
{
    unsigned char masterKey[16];
    unsigned char tmp[16+1], divData[8];
    
    if (pszWorkingKeyIn == NULL || strlen(pszWorkingKeyIn) < 32)
        return -1;
    if (pszDivData && strlen(pszDivData) < 16)
        return -2;
    
    unsigned char *rootKey = malloc(16);
    
    if (sg_iDebugFlag) {
        //for debug
        //7F187E82F2A52F20337DFDD9B53745F1
        memcpy(rootKey, "\x7F\x18\x7E\x82\xF2\xA5\x2F\x20", 8);
        memcpy(rootKey + 8, "\x33\x7D\xFD\xD9\xB5\x37\x45\xF1", 8);
    }
    else {
        //1191AB739A59D05C0933A65A40ED5CD9
        memcpy(rootKey, "\x11\x91\xAB\x73\x9A\x59\xD0\x5C", 8);
        memcpy(rootKey + 8, "\x09\x33\xA6\x5A\x40\xED\x5C\xD9", 8);
    }

    memcpy(masterKey, rootKey, 16);

    int offset = 0;
    if (pszDivData) {
        memset(tmp, 0, sizeof(tmp));
        for (int i = 0 ; i < strlen(pszDivData); i++) {
            if (pszDivData[i] == '-')
                continue;
            tmp[offset ++] = pszDivData[i];
            if (offset == 16)
                break;
        }
        vTwoOne(tmp, 16, divData);
            
        _vDes(TRI_ENCRYPT, divData, rootKey, masterKey);
        for (int i = 0 ; i < 8; i++)
            divData[i] = ~divData[i];
        _vDes(TRI_ENCRYPT, divData, rootKey, masterKey + 8);
    }
    free(rootKey);
    
    vTwoOne((unsigned char *)pszWorkingKeyIn, 32, tmp);
    _vDes(TRI_DECRYPT, tmp, masterKey, workingKeyOut);
    _vDes(TRI_DECRYPT, tmp + 8, masterKey, workingKeyOut + 8);
    
    return 0;
}

void vSetDebugFlag(int iDebugFlag)
{
    sg_iDebugFlag = iDebugFlag;
}

int iCalPinBlock(const char *pszWorkingKeyIn, const char *pszDivData, const char *pszPin, const char *pszCardNo, unsigned char *psCipheredPin)
{
    unsigned int  i,uiLen;
    unsigned char one[9],two[9],three[9],tmps[20], workingKeyOut[16];
    int iRet;
    
    iRet = iGenWorkingKey(pszWorkingKeyIn, pszDivData, workingKeyOut);
    if (iRet)
        return iRet;
    
    memset(one, 0 ,sizeof(one));
    if (pszCardNo) {
        strcpy((char*)tmps, "0000");
        memcpy(tmps+4,pszCardNo+strlen(pszCardNo)-16+3,12);
        vTwoOne(tmps,16,one); //帐号段
    }
    
    uiLen = (unsigned int)strlen((char*)pszPin);
    sprintf((char*)tmps,"%02x",uiLen);	//"04" or "06",Max "0C"
    memcpy(tmps+2,pszPin,uiLen);
    memset(tmps+2+uiLen,'F',16-2-uiLen );
    vTwoOne(tmps,16,two);		//PIN段
    
    for(i=0;i<8;i++)
        three[i]=one[i]^two[i];
    _vDes( TRI_ENCRYPT, three, workingKeyOut, psCipheredPin );
    
    return 0;
}
/* MAC X9.19 */
int iMac_X9_19(const char *pszWorkingKeyIn, const char *pszDivData, unsigned char *psMacData, int uiLength, unsigned char *psMac)
{
    unsigned int uiBlock;
    unsigned char sOutMAC[8], sBuf[8], workingKeyOut[16];
    int iRet;
    
    iRet = iGenWorkingKey(pszWorkingKeyIn, pszDivData, workingKeyOut);
    if (iRet)
        return iRet;
    
    memset(sOutMAC, 0, 8);
    uiBlock=0;

    while(uiLength > uiBlock) {
        if((uiLength - uiBlock) <= 8) {
            if((uiLength - uiBlock) == 8) {
                vXor(sOutMAC, (unsigned char *)&psMacData[uiBlock], uiLength-uiBlock);
                _vDes(TRI_ENCRYPT, sOutMAC, workingKeyOut, sOutMAC);
                memcpy((unsigned char *)psMac, sOutMAC, 4);
                return 0;
            } else {
                memset(sBuf, 0, sizeof(sBuf));
                memcpy(sBuf, &psMacData[uiBlock], (uiLength-uiBlock));
                vXor(sOutMAC, sBuf, 8);
                _vDes(TRI_ENCRYPT, sOutMAC, workingKeyOut, sOutMAC);
                memcpy((unsigned char *)psMac, sOutMAC, 4);
                return 0;
            }
        }
        vXor(sOutMAC, (unsigned char *)&psMacData[uiBlock], 8);
        _vDes(ENCRYPT, sOutMAC, workingKeyOut, sOutMAC);
        uiBlock += 8;
    }
    memcpy((unsigned char *)psMac, sOutMAC, 4);
    
    return 0;
}

int iEncrypt(const char *pszWorkingKeyIn, const char *pszDivData, unsigned char *psInData, int iDataLen, unsigned char *psOutData)
{
    unsigned char workingKeyOut[16];
    int iRet, iLen;
    
    iRet = iGenWorkingKey(pszWorkingKeyIn, pszDivData, workingKeyOut);
    if (iRet)
        return iRet;
    
    iLen = ((iDataLen + 7) / 8) * 8;
    
    unsigned char *sSource = malloc(iLen);
    memset(sSource, 0, iLen);
    memcpy(sSource, psInData, iDataLen);
    
    for (int i = 0 ; i < iLen / 8; i ++) {
        _vDes(TRI_ENCRYPT, sSource + i * 8, workingKeyOut, psOutData + i * 8);
    }
    
    free(sSource);
    
    return 0;
}

