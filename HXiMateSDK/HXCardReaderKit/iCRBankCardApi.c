//
//  iCRBankCardApi.c
//  HXiMateSDK
//
//  Created by hxsmart on 15/1/9.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//

#include "BankCardApi.h"
#include "iMateExt.h"

// 检测卡片是否存在
//  iSlot   :   0：芯片读卡器；1:MifCard 4:SAM卡
int  SmartCardTestCard(int iSlot)
{
    vSetCardReaderType(iSlot);
    return iIMateTestCard();
}

// 卡片复位
// ret : <=0 : 复位错误
//       >0  : 复位成功, 返回值为ATR长度
int  SmartCardResetCard(int iSlot, unsigned char *psResetData)
{
    vSetCardReaderType(iSlot);
    return iIMateResetCard(psResetData);
}

// 关闭卡片
// ret : 不关心
int  SmartCardCloseCard(int iSlot)
{
    vSetCardReaderType(iSlot);
    return iIMateCloseCard();
}

// 执行APDU指令
// in  : iInLen   	: Apdu指令长度
// 		 pIn     	: Apdu指令, 格式: Cla Ins P1 P2 Lc DataIn Le
// out : piOutLen 	: Apdu应答长度
//       pOut    	: Apdu应答, 格式: DataOut Sw1 Sw2
// ret : 0          : 卡操作成功
//       1          : 卡操作错
int  SmartCardExchangeApdu(int iSlot, int iInLen, unsigned char *pIn, int *piOutLen, unsigned char *pOut)
{
    vSetCardReaderType(iSlot);
    return iIMateExchangeApdu(iInLen, pIn, piOutLen, pOut);
}

