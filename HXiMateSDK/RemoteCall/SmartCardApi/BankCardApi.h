//
//  BankCardApi.h
//  CPU卡有关函数接口
//
//  Created by hxsmart on 15/1/9.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//

#ifndef __HXiMateSDK__SmartCardApi__
#define __HXiMateSDK__SmartCardApi__

#ifdef __cplusplus
extern "C" {
#endif

// 检测卡片是否存在
//  iSlot   :   0：用户卡；4:SAM卡
int  SmartCardTestCard(int iSlot);

// 卡片复位
// ret : <=0 : 复位错误
//       >0  : 复位成功, 返回值为ATR长度
int  SmartCardResetCard(int iSlot, unsigned char *psResetData);

// 关闭卡片
// ret : 不关心
int  SmartCardCloseCard(int iSlot);

// 执行APDU指令
// in  : iInLen   	: Apdu指令长度
// 		 pIn     	: Apdu指令, 格式: Cla Ins P1 P2 Lc DataIn Le
// out : piOutLen 	: Apdu应答长度
//       pOut    	: Apdu应答, 格式: DataOut Sw1 Sw2
// ret : 0          : 卡操作成功
//       1          : 卡操作错
int  SmartCardExchangeApdu(int iSlot, int iInLen, unsigned char *pIn, int *piOutLen, unsigned char *pOut);
    
//设置IC卡片类型，默认为0
// in  :   cardType   : IC卡片类型
//                      0 --> 普通   IC卡类型
//                      1 --> PBOC  IC卡类型
void setCardType(unsigned char cardType);

#ifdef __cplusplus
}
#endif
#endif /* defined(__HXiMateSDK__SmartCardApi__) */
