//
//  MifareCardApi.h
//  HXiMateSDK
//
//  Created by hxsmart on 15/1/13.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//

#ifndef __HXiMateSDK__MifareCardApi__
#define __HXiMateSDK__MifareCardApi__

#ifdef __cplusplus
extern "C" {
#endif


// 检测射频卡
// 输出参数：psSerialNo : 返回卡片系列号
// 返    回：>0         : 成功, 卡片系列号字节数
//           0         : 失败
unsigned int MifareCard_Card(unsigned char *psSerialNo);

// MIF CPU卡激活
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_Active(void);

// 关闭射频信号
// 返    回：0			；成功
//   		 其它		：失败
unsigned int MifareCard_Close(void);

// MIF移除
// 返    回：0          : 移除
//           其它       : 未移除
unsigned int MifareCard_Removed(void);

// M1卡扇区认证
// 输入参数：  ucSecNo	：扇区号
//			 ucKeyAB	：密钥类型，0x00：A密码，0x04: B密码
//			 psKey		: 6字节的密钥
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_Auth(unsigned char ucSecNo, unsigned char ucKeyAB, unsigned char *psKey);

// M1卡读数据块
// 			 ucSecNo	：扇区号
//			 ucBlock	: 块号
// 输出参数：psData		：16字节的数据
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_ReadBlock(unsigned char ucSecNo, unsigned char ucBlock, unsigned char *psData);

// M1卡写数据块
// 输入参数：  ucSecNo	：扇区号
//			 ucBlock	: 块号
//			 psData		：16字节的数据
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_WriteBlock(unsigned char ucSecNo, unsigned char ucBlock, unsigned char *psData);


// M1钱包加值
// 输入参数：  ucSecNo	：扇区号
//			 ucBlock	: 块号
//			 ulValue	：值
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_Increment(unsigned char ucSecNo,unsigned char ucBlock,unsigned long ulValue);

// M1钱包减值
// 输入参数：  ucSecNo	：扇区号
//			 ucBlock	: 块号
//			 ulValue	：值
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_Decrement(unsigned char ucSecNo,unsigned char ucBlock,unsigned long ulValue);

// M1卡块拷贝
// 输入参数： ucSrcSecNo	：源扇区号
//			 ucSrcBlock	: 源块号
//			 ucDesSecNo	: 目的扇区号
//			 ucDesBlock	: 目的块号
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_Copy(unsigned char ucSrcSecNo, unsigned char ucSrcBlock, unsigned char ucDesSecNo, unsigned char ucDesBlock);

// MIF CPU 卡 APDU
// 输入参数：psApduIn	：apdu命令串
//			 uiInLen	: apdu命令串长度
//			 psApduOut	: apdu返回串
//			 puiOutLen	: apdu返回串长度
// 返    回：0          : 成功
//           其它       : 失败
unsigned int MifareCard_Apdu(unsigned char *psApduIn, unsigned int uiInLen, unsigned char *psApduOut, unsigned int *puiOutLen);

    
#ifdef __cplusplus
}
#endif
#endif /* defined(__HXiMateSDK__MifareCardApi__) */
