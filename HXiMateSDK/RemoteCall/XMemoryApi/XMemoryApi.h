//
//  XMemory.h
//  HXiMateSDK
//
//  Created by hxsmart on 15/1/13.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//

#ifndef __HXiMateSDK__XMemory__
#define __HXiMateSDK__XMemory__

#include <stdio.h>

// 从iMate XMem中读取数据
// 输入参数：pBuf         : 读取数据缓冲区
//          uiOffset    : 数据偏移量
//          uiLen       : 数据长度
// 返    回：0           : 成功
//          其它         : 失败
extern int XMemory_Read(void *pBuf, unsigned int uiOffset, unsigned int uiLen);

// 向iMate XMem中写数据
// 输入参数：pBuf         : 数据缓冲区
//          uiOffset    : 数据偏移量
//          uiLen       : 数据长度
// 返    回：0           : 成功
//          其它         : 失败
extern int XMemory_Write(void *pBuf, unsigned int uiOffset, unsigned int uiLen);

#endif /* defined(__HXiMateSDK__XMemory__) */
