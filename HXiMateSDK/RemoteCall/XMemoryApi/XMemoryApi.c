//
//  XMemory.c
//  HXiMateSDK
//
//  Created by hxsmart on 15/1/13.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//

#include "XMemoryApi.h"
#include "RemoteFunctions.h"

#ifndef __HXiMateSDK__XMemoryApi__
#define __HXiMateSDK__XMemoryApi__

#ifdef __cplusplus
extern "C" {
#endif

int XMemory_Read(void *pBuf, unsigned int uiOffset, unsigned int uiLen)
{
    return _ucRcXMemRead(pBuf, uiOffset, uiLen);
}

int XMemory_Write(void *pBuf, unsigned int uiOffset, unsigned int uiLen)
{
    return _ucRcXMemWrite(pBuf, uiOffset, uiLen);
}

#ifdef __cplusplus
}
#endif

#endif