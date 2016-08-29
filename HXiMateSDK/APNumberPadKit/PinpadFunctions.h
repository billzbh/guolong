//
//  PinpadFunctions.h
//  HxPinpad
//
//  Created by hxsmart on 15/4/23.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//

#ifndef __HxPinpad__PinpadFunctions__
#define __HxPinpad__PinpadFunctions__

#include <stdio.h>

void vSetDebugFlag(int iDebugFlag);

int iCalPinBlock(const char *pszWorkingKeyIn, const char *pszDivData, const char *pszPin, const char *pszCardNo, unsigned char *psCipheredPin);

/* MAC X9.19 */
int iMac_X9_19(const char *pszWorkingKeyIn, const char *pszDivData, unsigned char *psMacData, int iDataLen, unsigned char *psMac);

/* 加密 */
int iEncrypt(const char *pszWorkingKeyIn, const char *pszDivData, unsigned char *psInData, int iDataLen, unsigned char *psOutData);

#endif /* defined(__HxPinpad__PinpadFunctions__) */
