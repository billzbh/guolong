//
//  MifareCardApi.c
//  HXiMateSDK
//
//  Created by hxsmart on 15/1/13.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//

#include <stdio.h>
#include "RemoteFunctions.h"
#include "MifareCardApi.h"


// 检测射频卡
// 输出参数：psSerialNo : 返回卡片系列号
// 返    回：>0        : 成功, 卡片系列号字节数
//           0        : 失败
unsigned int MifareCard_Card(unsigned char *psSerialNo)
{
    return _uiRcMifCard(psSerialNo);
}

// MIF CPU卡激活
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_Active(void)
{
    return _uiRcMifActive();
}

// 关闭射频信号
// 返    回：0			；成功
//   		 其它		：失败
unsigned int MifareCard_Close(void)
{
    return _uiRcMifClose();
}

// MIF移除
// 返    回：0          : 移除
//           其它       : 未移除
unsigned int MifareCard_Removed(void)
{
    return _uiRcMifRemoved();
}

// M1卡扇区认证
// 输入参数：  ucSecNo	：扇区号
//			 ucKeyAB	：密钥类型，0x00：A密码，0x04: B密码
//			 psKey		: 6字节的密钥
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_Auth(unsigned char ucSecNo, unsigned char ucKeyAB, unsigned char *psKey)
{
    return _uiRcMifAuth(ucSecNo, ucKeyAB, psKey);
}

// M1卡读数据块
// 			 ucSecNo	：扇区号
//			 ucBlock	: 块号
// 输出参数：psData		：16字节的数据
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_ReadBlock(unsigned char ucSecNo, unsigned char ucBlock, unsigned char *psData)
{
    return _uiRcMifReadBlock(ucSecNo, ucBlock, psData);
}

// M1卡写数据块
// 输入参数：  ucSecNo	：扇区号
//			 ucBlock	: 块号
//			 psData		：16字节的数据
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_WriteBlock(unsigned char ucSecNo, unsigned char ucBlock, unsigned char *psData)
{
    return _uiRcMifWriteBlock(ucSecNo, ucBlock, psData);
}


// M1钱包加值
// 输入参数：  ucSecNo	：扇区号
//			 ucBlock	: 块号
//			 ulValue	：值
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_Increment(unsigned char ucSecNo,unsigned char ucBlock,unsigned long ulValue)
{
    return _uiRcMifIncrement(ucSecNo, ucBlock, ulValue);
}

// M1钱包减值
// 输入参数：  ucSecNo	：扇区号
//			 ucBlock	: 块号
//			 ulValue	：值
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_Decrement(unsigned char ucSecNo,unsigned char ucBlock,unsigned long ulValue)
{
    return _uiRcMifDecrement(ucSecNo, ucBlock, ulValue);
}

// M1卡块拷贝
// 输入参数： ucSrcSecNo	：源扇区号
//			 ucSrcBlock	: 源块号
//			 ucDesSecNo	: 目的扇区号
//			 ucDesBlock	: 目的块号
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_Copy(unsigned char ucSrcSecNo, unsigned char ucSrcBlock, unsigned char ucDesSecNo, unsigned char ucDesBlock)
{
    return _uiRcMifCopy(ucSrcSecNo, ucSrcBlock, ucDesSecNo, ucDesBlock);
}

// MIF CPU 卡 APDU
// 输入参数：psApduIn	：apdu命令串
//			 uiInLen	: apdu命令串长度
//			 psApduOut	: apdu返回串
//			 puiOutLen	: apdu返回串长度
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_Apdu(unsigned char *psApduIn, unsigned int uiInLen, unsigned char *psApduOut, unsigned int *puiOutLen)
{
    return _uiRcMifApdu(psApduIn, uiInLen, psApduOut, puiOutLen);
}

