//
//  SmartCardApi.c
//  HXiMateSDK
//
//  Created by hxsmart on 15/1/9.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//

#include "BankCardApi.h"
#include "RemoteFunctions.h"

static uchar sg_ucCardType = 1; //0:normal icc type; 1:pboc icc type

//设置IC卡片类型，
//0 --> 普通   IC卡类型
//1 --> PBOC  IC卡类型
void setCardType(unsigned char cardType)
{
    sg_ucCardType = cardType;
}

// 检测卡片是否存在
//  iSlot   :   0：芯片读卡器；4:SAM卡
int  SmartCardTestCard(int iSlot)
{
    return _uiRcTestCard(iSlot);
}

// 卡片复位
// ret : <=0 : 复位错误
//       >0  : 复位成功, 返回值为ATR长度
int  SmartCardResetCard(int iSlot, unsigned char *psResetData)
{
    return _uiRcResetCard(iSlot, psResetData);
}

// 关闭卡片
// ret : 不关心
int  SmartCardCloseCard(int iSlot)
{
    return _uiRcCloseCard(iSlot);
}
//
/*
① 情形1
CLA INS P1 P2 00
② 情形2
CLA INS P1 P2 Le
③ 情形3
CLA INS P1 P2 Lc Data
④ 情形4
CLA INS P1 P2 Lc Data Le
*/
 // 执行APDU指令
// in  : iInLen   	: Apdu指令长度
// 		 pIn     	: Apdu指令, 格式: Cla Ins P1 P2 Lc DataIn Le
// out : piOutLen 	: Apdu应答长度
//       pOut    	: Apdu应答, 格式: DataOut Sw1 Sw2
// ret : 0          : 卡操作成功
//       1          : 卡操作错
int  SmartCardExchangeApdu(int iSlot, int iInLen, unsigned char *pIn, int *piOutLen, unsigned char *pOut)
{
    return _uiRcExchangeApduEx(iSlot, sg_ucCardType, pIn, iInLen, pOut, piOutLen);
}
