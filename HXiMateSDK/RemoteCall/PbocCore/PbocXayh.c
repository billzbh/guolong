/**************************************
File name     : PbocXayh.c
Function      : 西安银行接口
Author        : Yu Jun
First edition : Jun 10th, 2014
**************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "EmvProc.h"
#include "PbocXayh.h"
#include "iMateExt.h"

static unsigned int sg_uiCurrencyCode = 156; // 参数设置时传入的交易货币代码

// 核心初始化
// in  : pszMerchantId   : 商户号[15]
//		 pszTermId       : 终端号[8]
//		 pszMerchantName : 商户名字[40]
//		 uiCountryCode   : 终端国家代码, 1-999
//		 uiCurrencyCode  : 交易货币代码, 1-999
int iHxPbocXayhInitCore(char *pszMerchantId, char *pszTermId, char *pszMerchantName, unsigned int uiCountryCode, unsigned int uiCurrencyCode)
{
	stHxTermParam HxTermParam;
	stHxTermAid   *pAidPara;
	stHxTermAid   aHxTermAid[20];
	int  i;
	int  iRet;

	// 参数检查
	if(strlen(pszMerchantId) != 15)
		return(HXPBOC_HIGH_PARA);
	if(strlen(pszTermId) != 8)
		return(HXPBOC_HIGH_PARA);
	if(strlen(pszMerchantName) > 40)
		return(HXPBOC_HIGH_PARA);
	if(uiCountryCode<1 || uiCountryCode>999)
		return(HXPBOC_HIGH_PARA);
	if(uiCurrencyCode<1 || uiCurrencyCode>999)
		return(HXPBOC_HIGH_PARA);
	sg_uiCurrencyCode = uiCurrencyCode;

	// 初始化核心
	iRet = iHxEmvInit(iIMateTestCard, iIMateResetCard, iIMateExchangeApdu, iIMateCloseCard);
	if(iRet != HXEMV_OK)
		return(HXPBOC_HIGH_OTHER);

	// 设置终端参数
	memset(&HxTermParam, 0, sizeof(HxTermParam));
	HxTermParam.ucTermType = 0x11; // T9F35, 终端类型, Financial, Online only, Attended
	memcpy(HxTermParam.sTermCapability, "\x60\x48\x00", 3); // T9F33, 终端能力
	memcpy(HxTermParam.sAdditionalTermCapability, "\xEF\x80\xF0\xF0\x00", 5); // T9F40, 终端能力扩展
	strcpy(HxTermParam.szMerchantId, pszMerchantId); // T9F16, 商户号
	strcpy(HxTermParam.szTermId, pszTermId); // T9F1C, 终端号
	strcpy(HxTermParam.szMerchantNameLocation, pszMerchantName); // T9F4E, 商户名字地址, 0-254
	HxTermParam.uiTermCountryCode = uiCountryCode; // T9F1A, 终端国家代码, 156=中国
	strcpy(HxTermParam.szAcquirerId, "666666"); // T9F01, 收单行标识符, 6-11
	HxTermParam.iMerchantCategoryCode = -1; // T9F15, -1:无此数据 0-9999:有效数据
	HxTermParam.ucPinBypassBehavior = 0; // PIN bypass特性 0:每次bypass只表示该次bypass 1:一次bypass,后续都认为bypass
	HxTermParam.ucAppConfirmSupport = 1; // 1:支持应用确认 0:不支持应用确认(TAG_DFXX_AppConfirmSupport)

	pAidPara = &HxTermParam.AidCommonPara; // 终端通用参数与AID相关参数公共部分
	memcpy(pAidPara->sTermAppVer, "\x00\x20", 2); // T9F09, 终端应用版本号, "\xFF\xFF"表示不存在
	pAidPara->ulFloorLimit = 0xFFFFFFFEL; // T9F1B, 终端限额, 单位为分, 0xFFFFFFFF表示不存在
	pAidPara->iMaxTargetPercentage = -1; // 随机选择最大百分比，-1:不存在
	pAidPara->iTargetPercentage = -1; // 随机选择目标百分比，-1:不存在
	pAidPara->ulThresholdValue = 0xFFFFFFFF; // 随机选择阈值, 0xFFFFFFFF表示不存在
	pAidPara->ucECashSupport = 1; // 1:支持电子现金 0:不支持电子现金, 0xFF表示不存在
	strcpy(pAidPara->szTermECashTransLimit, "100000");  // T9F7B, 终端电子现金交易限额, 空表示不存在
	pAidPara->ucTacDefaultExistFlag = 1;        // 1:TacDefault存在, 0:TacDefault不存在
	memcpy(pAidPara->sTacDefault, "\xFF\xFF\xFF\xFF\xFF", 5);       // TAC-Default, 参考TVR结构
	pAidPara->ucTacDenialExistFlag = 1;         // 1:TacDenial存在, 0:TacDenial不存在
	memcpy(pAidPara->sTacDenial, "\x00\x00\x00\x00\x00", 5);		// TAC-Denial, 参考TVR结构
	pAidPara->ucTacOnlineExistFlag = 0;         // 1:TacOnline存在, 0:TacOnline不存在
	memcpy(pAidPara->sTacOnline, "\xFF\xFF\xFF\xFF\xFF", 5);		// TAC-Online, 参考TVR结构
	pAidPara->iDefaultDDOLLen = 0;              // Default DDOL长度,-1表示无
	pAidPara->iDefaultTDOLLen = 0;              // Default TDOL长度,-1表示无
	iRet = iHxEmvSetParam(&HxTermParam);
	if(iRet)
		return(HXPBOC_HIGH_OTHER);

	// 装载支持的AID
	// 支持A000000333, A000000333010101-A000000333010107
	memset(aHxTermAid, 0, sizeof(aHxTermAid));
	for(i=0; i<8; i++) {
		aHxTermAid[i].ucAidLen = 8;
		memcpy(aHxTermAid[i].sAid, "\xA0\x00\x00\x03\x33\x01\x01\xFF", 8);
		aHxTermAid[i].sAid[7] = i;
		aHxTermAid[i].ucASI = 1; // 应用选择指示器, 0:部分名字匹配，1:全部名字匹配
		aHxTermAid[i].cOnlinePinSupport = 1; // 1:该Aid支持联机密码 0:该Aid不支持联机密码, -1表示无
		if(i == 0) {
			aHxTermAid[i].ucAidLen = 5;
			aHxTermAid[i].ucASI = 0; // 应用选择指示器, 0:部分名字匹配，1:全部名字匹配
		}
		memcpy(aHxTermAid[i].sTermAppVer, "\xFF\xFF", 2);
		aHxTermAid[i].ulFloorLimit = 0xFFFFFFFFL;
		aHxTermAid[i].iMaxTargetPercentage = -1;
		aHxTermAid[i].iTargetPercentage = -1;
		aHxTermAid[i].ulThresholdValue = 0xFFFFFFFFL;
		aHxTermAid[i].ucECashSupport = 0xFF;
		aHxTermAid[i].iDefaultDDOLLen = -1;
		aHxTermAid[i].iDefaultTDOLLen = -1;
	}
	iRet = iHxEmvLoadAid(&aHxTermAid[0], 8);
	if(iRet)
		return(HXPBOC_HIGH_OTHER);

	// 装载CA公钥
	// 不支持

	return(0);
}

static void vOneTwo(void *pFrom, int iFromLen, void *pTo)
{
   static unsigned char usHexToChar[16]= "0123456789ABCDEF";
   int i;

   for(i=0; i<iFromLen; i++)
   {
      ((unsigned char *)pTo)[2*i]= usHexToChar[((unsigned char *)pFrom)[i] >> 4];
      ((unsigned char *)pTo)[2*i+1]= usHexToChar[((unsigned char *)pFrom)[i] & 0x0F];
   }
   return;
}

static void vOneTwo0(void *pFrom, int iFromLen, void *pTo)
{
   vOneTwo(pFrom, iFromLen, pTo);
   ((unsigned char *)pTo)[2*iFromLen] = 0;
}

static void vTwoOne(void *pFrom, int iFromLen, void *pTo)
{
   unsigned char ucTmp;
   unsigned char *pusFrom, *pusTo;
   int i;

   pusFrom = (unsigned char *)pFrom;
   pusTo   = (unsigned char *)pTo;
   for(i=0; i<iFromLen; i+=2)
   {
      ucTmp= pusFrom[i];
      if (ucTmp==0x00)   ucTmp= 0x00;
      else if (ucTmp<'A')
         ucTmp= ucTmp - '0';
	  else if (ucTmp < 'a')
         ucTmp= ucTmp - 'A' + 0x0A;
      else
         ucTmp = ucTmp - 'a' + 0x0A;

      ucTmp<<= 4;
      pusTo[i/2]= ucTmp;

      ucTmp= pusFrom[i+1];
      if(ucTmp == 0x00)   ucTmp= 0x00;
      else if (ucTmp<'A')
         ucTmp= ucTmp - '0';
      else if (ucTmp < 'a')
         ucTmp= ucTmp - 'A' + 0x0A;
      else
         ucTmp = ucTmp - 'a' + 0x0A;

      pusTo[i/2]= pusTo[i/2] + ucTmp;
   }
}

// 交易初始化
// in  : pszDateTime  : 交易日期时间[14], YYYYMMDDhhmmss
//       ulAtc        : 终端交易流水号, 1-999999
//       ucTransType  : 交易类型, 0x00 - 0xFF
//       pszAmount    : 交易金额[12]
// out : pszField55   : 组装好的55域内容, 十六进制可读格式, 预留513字节长度
//       pszPan       : 主账号[19], 可读格式
//       piPanSeqNo   : 主账号序列号, 0-99, -1表示不存在
//       pszTrack2    : 二磁道等效数据[37], 3x格式, 长度为0表示不存在
//       pszExtInfo   : 其它数据, 保留
int iHxPbocXayhInitTrans(char *pszDateTime, unsigned long ulAtc, unsigned char ucTransType, unsigned char *pszAmount,
						 char *pszField55, char *pszPan, int *piPanSeqNo, char *pszTrack2, char *pszExtInfo)
{
	stHxAdfInfo aHxAdfInfo[3];
	unsigned char sBuf[100], sField55[256], *psField55;
	int  iField55Len;
	int  iNeedCheckCrlFlag;
	int  iOutTlvDataLen, iOutDataLen;
	int  iCardAction;
	int  i;
	int  iRet;

	// 检查参数
	if(strlen(pszDateTime) != 14)
		return(HXPBOC_HIGH_PARA);
	if(ulAtc<1 || ulAtc>999999L)
		return(HXPBOC_HIGH_PARA);
	if(strlen(pszAmount) > 12)
		return(HXPBOC_HIGH_PARA);

	// 交易初始化
	iRet = iHxEmvTransInit(0); // 参数为保留以后使用
	if(iRet==HXEMV_NO_CARD || iRet==HXEMV_CARD_REMOVED)
		return(HXPBOC_HIGH_NO_CARD);
	if(iRet == HXEMV_CARD_OP)
		return(HXPBOC_HIGH_CARD_IO);
	if(iRet)
		return(HXPBOC_HIGH_OTHER);

	while(1) {
		// 获取支持的应用
		int  iHxAdfNum;
		iHxAdfNum = sizeof(aHxAdfInfo) / sizeof(aHxAdfInfo[0]);
		iRet = iHxEmvGetSupportedApp(0/*0:不忽略应用锁定*/, &aHxAdfInfo[0], &iHxAdfNum);
		if(iRet==HXEMV_CARD_OP || iRet==HXEMV_CARD_REMOVED)
			return(HXPBOC_HIGH_CARD_IO);
		if(iRet == HXEMV_CARD_SW)
			return(HXPBOC_HIGH_CARD_SW);
		if(iRet == HXEMV_NO_APP)
			return(HXPBOC_HIGH_NO_APP);
		if(iRet == HXEMV_TERMINATE)
			return(HXPBOC_HIGH_TERMINATE);
		if(iRet!=HXEMV_OK && iRet!=HXEMV_AUTO_SELECT)
			return(HXPBOC_HIGH_OTHER);

		// 选择应用, 自动选择第一个应用
		iRet = iHxEmvAppSelect(0/*0:不忽略应用锁定*/, aHxAdfInfo[0].ucAdfNameLen, aHxAdfInfo[0].sAdfName);
		if(iRet==HXEMV_CARD_OP || iRet==HXEMV_CARD_REMOVED)
			return(HXPBOC_HIGH_CARD_IO);
		if(iRet == HXEMV_TERMINATE)
			return(HXPBOC_HIGH_TERMINATE);
		if(iRet!=HXEMV_OK && iRet!=HXEMV_AUTO_SELECT)
			return(HXPBOC_HIGH_OTHER);
		if(iRet == HXEMV_RESELECT)
			continue;
		if(iRet)
			return(HXPBOC_HIGH_OTHER);

		// GPO需要(日期时间、金额、货币代码、终端交易流水号)
		iRet = iHxEmvGPO(pszDateTime, ulAtc, ucTransType, pszAmount, sg_uiCurrencyCode);
		if(iRet==HXEMV_CARD_OP || iRet==HXEMV_CARD_REMOVED)
			return(HXPBOC_HIGH_CARD_IO);
		if(iRet == HXEMV_CARD_SW)
			return(HXPBOC_HIGH_CARD_SW);
		if(iRet == HXEMV_TERMINATE)
			return(HXPBOC_HIGH_TERMINATE);
		if(iRet!=HXEMV_OK && iRet!=HXEMV_AUTO_SELECT)
			return(HXPBOC_HIGH_OTHER);
		if(iRet == HXEMV_RESELECT)
			continue;
		if(iRet)
			return(HXPBOC_HIGH_OTHER);
		break; // 不再需要重新选择应用了
	} // while(1)

	// 读应用记录
	iRet = iHxEmvReadRecord();
	if(iRet==HXEMV_CARD_OP || iRet==HXEMV_CARD_REMOVED)
		return(HXPBOC_HIGH_CARD_IO);
	if(iRet == HXEMV_CARD_SW)
		return(HXPBOC_HIGH_CARD_SW);
	if(iRet == HXEMV_TERMINATE)
		return(HXPBOC_HIGH_TERMINATE);
	if(iRet)
		return(HXPBOC_HIGH_OTHER);

	// 脱机数据认证
	iRet = iHxEmvOfflineDataAuth(&iNeedCheckCrlFlag, NULL, NULL, NULL);
	if(iRet)
		return(HXPBOC_HIGH_OTHER);

	// 处理限制
	iRet = iHxEmvProcRistrictions();
	if(iRet)
		return(HXPBOC_HIGH_OTHER);

	// 终端风险管理
	iRet = iHxEmvTermRiskManage();
	if(iRet)
		return(HXPBOC_HIGH_OTHER);

	// 持卡人验证
	for(;;) {
		int  iCvm, iCvmProc, iBypassFlag;
		char sCvmData[20];
		int  iPromptFlag;
		// 获取持卡人验证
		// iCvm : HXCVM_PLAIN_PIN、HXCVM_CIPHERED_ONLINE_PIN、HXCVM_HOLDER_ID、HXCVM_CONFIRM_AMOUNT
		iRet = iHxEmvGetCvmMethod(&iCvm, &iBypassFlag);
		if(iRet == HXEMV_NO_DATA)
			break;
		if(iRet)
			return(HXPBOC_HIGH_OTHER);

		if(iCvm == HXCVM_CIPHERED_ONLINE_PIN)
			iCvmProc = HXCVM_PROC_OK;
		else
			iCvmProc = HXCVM_BYPASS;

		// 执行持卡人验证
		// iCvmProc : HXCVM_PROC_OK or HXCVM_BYPASS or HXCVM_FAIL or HXCVM_CANCEL or HXCVM_TIMEOUT
		iRet = iHxEmvDoCvmMethod(HXCVM_BYPASS, (unsigned char *)sCvmData, &iPromptFlag);
		if(iRet)
			return(HXPBOC_HIGH_OTHER);
	} // for(;;) 持卡人验证

	// 终端行为分析
	iRet = iHxEmvTermActionAnalysis();
	if(iRet)
		return(HXPBOC_HIGH_OTHER);

	// Gac1
	iRet = iHxEmvGac1(1/*1:Force online*/, &iCardAction);
	if(iRet==HXEMV_CARD_OP || iRet==HXEMV_CARD_REMOVED)
		return(HXPBOC_HIGH_CARD_IO);
	if(iRet == HXEMV_CARD_SW)
		return(HXPBOC_HIGH_CARD_SW);
	if(iRet==HXEMV_TERMINATE || iRet==HXEMV_NOT_ACCEPTED || iRet==HXEMV_NOT_ALLOWED)
		return(HXPBOC_HIGH_TERMINATE);
	if(iRet)
		return(HXPBOC_HIGH_OTHER);
	if(iCardAction == GAC_ACTION_TC)
		return(HXPBOC_HIGH_OTHER); // 不能生成TC
	if(iCardAction != GAC_ACTION_ARQC)
		return(HXPBOC_HIGH_DENIAL);

	// 组织返回数据
	{
		// 55域返回Tag列表, 山东城商行提供的数据分析而出
		unsigned char aszTagList[][3] = {
			"\x9F\x26",
			"\x9F\x27",
			"\x9F\x10",
			"\x9F\x37",
			"\x9F\x36",
			"\x95",
			"\x9A",
			"\x9C",
			"\x9F\x02",
			"\x5F\x2A",
            "\x5A",
            "\x5F\x34",
            "\x9F\x13",
			"\x82",
			"\x9F\x1A",
			"\x9F\x03",
			"\x9F\x33",
		}; // aszTagList[] = {
		
		psField55 = sField55;
		iField55Len = 0;
		for(i=0; i<sizeof(aszTagList)/sizeof(aszTagList[0]); i++) {
			iOutTlvDataLen = 200;
			iRet = iHxEmvGetData(aszTagList[i], &iOutTlvDataLen, psField55, NULL, NULL);
			if(iRet == HXEMV_NO_DATA) {
    			if(memcmp(aszTagList[i], "\x9F\x13", 2) == 0) {
	    		    // 该项目如果不存在, 需要从卡片里面读出来
        			iRet = iHxEmvGetCardNativeData(aszTagList[i], &iOutTlvDataLen, psField55, NULL, NULL);
					if(iRet != HXEMV_OK)
						continue;
				} else if(memcmp(aszTagList[i], "\x9F\x03", 2) == 0) {
					// 该项目如果不存在, 组装0值
					memcpy(psField55, "\x9F\x03\x06\x00\x00\x00\x00\x00\x00", 9);
					iField55Len += 9;
					psField55 += 9;
					continue;
				} else
					continue;
			}
			if(iRet)
				return(HXPBOC_HIGH_OTHER);
			iField55Len += iOutTlvDataLen;
			psField55 += iOutTlvDataLen;
		}
	} // 组织返回数据
	vOneTwo0(sField55, iField55Len, pszField55);

	iOutDataLen = sizeof(sBuf);
	iRet = iHxEmvGetData("\x5A", NULL, NULL, &iOutDataLen, sBuf);
	if(iRet)
		return(HXPBOC_HIGH_OTHER);
	strcpy(pszPan, sBuf);
	iOutDataLen = sizeof(sBuf);
	iRet = iHxEmvGetData("\x5F\x34", NULL, NULL, &iOutDataLen, sBuf);
	if(iRet)
		*piPanSeqNo = -1;
	else
		*piPanSeqNo = atoi(sBuf);
	iOutDataLen = sizeof(sBuf);
	iRet = iHxEmvGetData("\x57", NULL, NULL, &iOutDataLen, sBuf);
	if(iRet)
		strcpy(pszTrack2, "");
	else {
		char szTrack2[41];
		memset(szTrack2, 0, sizeof(szTrack2));
		for(i=0; i<iOutDataLen; i++) {
			szTrack2[i*2] = 0x30 | ((sBuf[i]>>4) & 0x0F);
			szTrack2[i*2+1] = 0x30 | (sBuf[i] & 0x0F);
		}
		for(i=iOutDataLen*2-1; i>0; i--) {
			if(szTrack2[i] == 0x3F) {
				szTrack2[i] = 0;
				break;
			}
		}
		strcpy(pszTrack2, szTrack2);
	}

	if(pszExtInfo)
		pszExtInfo[0] = 0;
	return(0);
}

// 完成交易
// in  : pszIssuerData  : 后台数据, 十六进制可读格式
//       iIssuerDataLen : 后台数据长度
// out : pszField55     : 组装好的55域内容, 二进制格式, 预留513字节长度
// Note: 除了返回HXPBOC_HIGH_OK外, 返回HXPBOC_HIGH_DENIAL也会返回脚本结果
int iHxPbocXayhDoTrans(char *pszIssuerData, char *pszField55)
{
	unsigned char sField55[256], *psField55;
	unsigned char sIssuerData[256];
	int  iIssuerDataLen;
	int  iField55Len;
	int  iOutTlvDataLen;
	int  iCardAction;
	int  i;
	int  iRet;

	iIssuerDataLen = (int)strlen(pszIssuerData);
	if(iIssuerDataLen>512 || iIssuerDataLen%2)
		return(HXPBOC_HIGH_PARA);
	vTwoOne(pszIssuerData, iIssuerDataLen*2, sIssuerData);
	iIssuerDataLen /= 2;

	// Gac2
	iRet = iHxEmvGac2 ("00", NULL, sIssuerData, iIssuerDataLen, &iCardAction);
	if(iRet==HXEMV_CARD_OP || iRet==HXEMV_CARD_REMOVED)
		return(HXPBOC_HIGH_CARD_IO);
	if(iRet == HXEMV_CARD_SW)
		return(HXPBOC_HIGH_CARD_SW);
	if(iRet==HXEMV_TERMINATE || iRet==HXEMV_NOT_ACCEPTED || iRet==HXEMV_NOT_ALLOWED)
		return(HXPBOC_HIGH_TERMINATE);
	if(iRet)
		return(HXPBOC_HIGH_OTHER);

	// 关闭卡片
	iHxEmvCloseCard();

	// 组织返回数据
	{
		// 55域返回Tag列表
		unsigned char aszTagList[][3] = {
			"\x9F\x26",
			"\x9F\x27",
			"\x9F\x10",
			"\x9F\x37",
			"\x9F\x36",
			"\x95",
			"\x9A",
			"\x9F\x1A",
			"\x9F\x1E",
			"\x9F\x33",
			"\xDF\x31"
		}; // aszTagList[] = {
		psField55 = sField55;
		iField55Len = 0;
		for(i=0; i<sizeof(aszTagList)/sizeof(aszTagList[0]); i++) {
			iOutTlvDataLen = 200;
			iRet = iHxEmvGetData(aszTagList[i], &iOutTlvDataLen, psField55, NULL, NULL);
			if(iRet == HXEMV_NO_DATA) {
				if(memcmp(aszTagList[i], "\xDF\x31", 2) == 0) {
					// 该项目如果不存在, 组装0值
					memcpy(psField55, "\xDF\x31\x05\x00\x00\x00\x00\x00", 8);
					iField55Len += 8;
					psField55 += 8;
				}
				continue;
			}
			if(iRet)
				return(HXPBOC_HIGH_OTHER);
			iField55Len += iOutTlvDataLen;
			psField55 += iOutTlvDataLen;
		}
	} // 组织返回数据
	vOneTwo0(sField55, iField55Len, pszField55);

	if(iCardAction != GAC_ACTION_TC)
		return(HXPBOC_HIGH_DENIAL);

	return(HXPBOC_HIGH_OK);
}