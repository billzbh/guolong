//
//  iMateDevice.h
//  HXiMateSDK
//
//  Created by hxsmart on 14-4-17.
//  Copyright (c) 2014年 hxsmart. All rights reserved.
//

#ifndef HXiMateSDK_iMateDevice_h
#define HXiMateSDK_iMateDevice_h

// SD ICC IO Type
#define SDSC_SCIO_UNKNOWN                    0         // The type of the SCIO is unknown.
#define SDSC_SCIO_7816                       1         // The type of the SCIO is 7816.
#define SDSC_SCIO_SPI_V1                     2         // The type of the SCIO is SPI V1.
#define SDSC_SCIO_SPI_V2                     3         // The type of the SCIO is SPI V2.
#define SDSC_SCIO_SPI_V3                     4         // The type of the SCIO is SPI V3

#define MAXLENGTH_ERRORMSG                  80         //提示信息最大长度

// 打开指纹模块电源，并检测是否连接成功。
// 返回码： 0    :   成功
//        99   :   不支持该功能
//       其它   :   失败或未检测到指纹模块
extern int SFID_RUDLL_FingerprintOpen(void);

// 关闭指纹模块电源
extern void SFID_RUDLL_FingerprintClose(void);

//*******************************************************************
//* 功能：设置USB指纹仪采集超时时间
//* 参数说明：
//* _timeout:超时时间，单位秒
//* 返回值说明：
//*		无
//********************************************************************/
extern void TSFID_RUDLL_SetOverTime(int _timeout);

///*******************************************************************
//* 功能：完成一次采集得到指纹特征，用于柜员指纹验证时进行指纹采集
//* 参数说明：
//* fpflag：指纹仪应用模式
//* 		fpflag[0]：指纹仪类型
//* 			'R'：串口指纹仪
//* 			'A'：内部应用
//* 			'B'：外部应用
//* 		fpflag[1]、fpflag[2]：保留
//* fpminu1：存放采集得到的指纹特征的第一部分（定长200字节）
//* fpminu2：存放采集得到的指纹特征的第二部分（定长100字节）
//* 返回值说明：
//*		返回值=0，表示正常返回
//*		返回值=1，表示采集失败
//*		返回值<0，其他错误，用TSFID_RUDLL_GetErrorMSG(errorno,msgptr)返回错误说明
//*			-1:未找到指纹设备
//*			-2:参数错
//*			-3:指纹模板无效
//********************************************************************/
extern int TSFID_RUDLL_GetFinger(char fpflag[3],unsigned char fpminu1[200],unsigned char fpminu2[100]);

///*******************************************************************
//* 功能：完成三次采集，组合得到一枚指纹模板，用于柜员/客户建立指纹模板
//* 参数说明：
//* fpflag：指纹仪的连接类型
//* 	串口指纹仪：
//* 		fpflag[0]：指纹仪类型
//* 			'R'：串口指纹仪
//* 			'A'：内部应用
//* 			'B'：外部应用
//* 		fpflag[1]、fpflag[2]：保留
//* order ：  三次采集的顺序号，初值为1
//* fpminu1：存放采集得到的指纹模板的第一部分（定长200字节）
//* fpminu2：存放采集得到的指纹模板的第二部分（定长100字节）
//* 返回值说明：
//*		返回值=0，表示三次采集组合模板成功
//*		返回值=1，表示第一次采集失败
//*		返回值=2，表示第二次采集失败
//*		返回值=3，表示第三次采集失败
//*		返回值<0，其他错误，用TSFID_RUDLL_GetErrorMSG(errorno,msgptr)返回错误说明
//*			-1:未找到指纹设备
//*			-2:参数错
//*			-3:指纹模板无效
//*			-4:组合指纹模板失败
//********************************************************************/
extern int TSFID_RUDLL_EnrollFinger(char fpflag[3],int order,unsigned char fpminu1[200],unsigned char fpminu2[100]);

///*******************************************************************
//* 功能：根据指纹仪序列号产生12字节的指纹仪设备号并将设备号写入指纹仪
//* 参数说明：
//* fpflag：指纹仪的连接类型
//* 	串口指纹仪：
//* 		fpflag[0]：指纹仪类型
//* 			'R'：串口指纹仪
//* 			'A'：内部应用
//* 			'B'：外部应用
//* 		fpflag[1]、fpflag[2]：保留
//* deviceno：12字节指纹设备号
//* 返回值说明：
//*		返回值为0，表示成功
//*		返回值<0，其他错误，用TSFID_RUDLL_GetErrorMSG(errorno,msgptr)返回错误说明
//*			-5:写应用设备号失败
//********************************************************************/
extern int TSFID_RUDLL_SetDeviceNo(char fpflag[3],unsigned char deviceno[12]);

///*******************************************************************
//* 功能：读取指纹仪设备号
//* 参数说明：
//* fpflag：指纹仪的连接类型
//* 	串口指纹仪：
//* 		fpflag[0]：指纹仪类型
//* 			'R'：串口指纹仪
//* 			'A'：内部应用
//* 			'B'：外部应用
//* 		fpflag[1]、fpflag[2]：保留
//* deviceno：12字节指纹设备号
//* 返回值说明：
//*		返回值为0，表示成功
//*		返回值<0，其他错误，用TSFID_RUDLL_GetErrorMSG(errorno,msgptr)返回错误说明
//*			-5:写应用设备号失败
//********************************************************************/
extern int TSFID_RUDLL_GetDeviceNo(char fpflag[3],unsigned char deviceno[12]);

///*******************************************************************
//* 功能：根据错误参数返回对应的错误提示信息
//* 参数说明：
//* errorno：错误参数
//* msgptr ：用户分配的MAXLENGTH_ERRORMSG大小的空间
//* 返回值说明：
//*		无
//********************************************************************/
extern void TSFID_RUDLL_GetErrorMSG(int errorno,char msgptr[MAXLENGTH_ERRORMSG]);

///*******************************************************************
//* 功能：设置指纹仪类型
//* fpflag：指纹仪的连接类型
//* 	串口指纹仪：
//* 		fpflag[0]：指纹仪类型
//* 			'R'：串口指纹仪
//* 			'A'：内部应用
//* 			'B'：外部应用
//* 		fpflag[1]、fpflag[2]：保留
//* devicetype：1字节指纹设备类型
//* 返回值说明：
//*		返回值为0，表示成功
//*		返回值<0，其他错误，用TSFID_RUDLL_GetErrorMSG(errorno,msgptr)返回错误说明
//*			-5:写应用设备号失败
//********************************************************************/
extern int TSFID_RUDLL_SetDeviceType(char fpflag[3],unsigned char devicetype);

///*******************************************************************
//* 功能：获取指纹仪类型
//* 参数说明：
//* fpflag：指纹仪的连接类型
//* 	串口指纹仪：
//* 		fpflag[0]：指纹仪类型
//* 			'R'：串口指纹仪
//* 			'A'：内部应用
//* 			'B'：外部应用
//* 		fpflag[1]、fpflag[2]：保留
//* devicetype：1字节指纹设备类型
//* 返回值说明：
//*		返回值为0，表示成功
//*		返回值<0，其他错误，用TSFID_RUDLL_GetErrorMSG(errorno,msgptr)返回错误说明
//*			-5:写应用设备号失败
//********************************************************************/
extern int TSFID_RUDLL_GetDeviceType(char fpflag[3],unsigned char *devicetype);

///*******************************************************************
//* 功能：返回驱动版本号
//* 参数说明：
//* fpflag：指纹仪的连接类型
//* 	串口指纹仪：
//* 		fpflag[0]：指纹仪类型
//* 			'R'：串口指纹仪
//* 			'A'：内部应用
//* 			'B'：外部应用
//* 返回值说明：
//*		无
//********************************************************************/
extern int TSFID_RUDLL_GetDeviceInfo(char fpflag[3], char firmver[10], char deviceinfo[10]);

// TF ICC Functions

// 打开SD卡电源，接口初始化
// 返回码：
//      0       :   成功
//      99      :   不支持该功能
//      其它    :   失败
extern unsigned int uiSD_Init(void);

// 关闭SD卡电源
extern void vSD_DeInit(void);

// 识别SD_ICC，冷复位
// 返回码：
//      0       :   成功
//      其它    :   失败
extern unsigned int uiSDSCConnectDev(void);

// 关闭SD_ICC
// 返回码：
//      0       :   成功
//      其它    :   失败
extern unsigned int uiSDSCDisconnectDev(void);

// 获取SD_ICC固件版本号
// 输入参数 ：
//      puiFirmwareVerLen   :   psFirmwareVer缓冲区长度
// 输出参数 ：
//      psFirmwareVer       :   固件版本缓冲区(需要预先分配空间，maxlength = 20）
//      puiFirmwareVerLen   :   固件版本数据的长度
// 返回码：
//      0                   :   成功
//      其它                :   失败
extern unsigned int uiSDSCGetFirmwareVer(unsigned char *psFirmwareVer, unsigned int *puiFirmwareVerLen);

// SD_ICC热复位
// 输入参数 ：
//      puiAtrLen    :   psAtr缓冲区长度
// 输出参数 :
//      psAtr        :   Atr数据缓冲区（需要预先分配空间，maxlength = 80）
//      puiAtrLen    :   返回复位数据长度
// 返回码   ：
//      0            :   成功
//      其它         :   失败
extern unsigned int uiSDSCResetCard(unsigned char *psAtr, unsigned int *puiAtrLen);


// 转换SD_ICC电源模式
// 返回码：
//      0       :   成功
//      其它    :   失败
extern unsigned int uiSDSCResetController(unsigned int uiSCPowerMode);

// SD_ICC APDU
// 输入参数 :
//      psCommand       :   ICC Apdu命令串
//      uiCommandLen    :   命令串长度
//      uiTimeOutMode   :   超时模式，固定使用0.
//      puiOutDataLen   :   psOutData缓冲区长度
// 输出参数 :
//      psOutData       :   响应串缓冲区（不包括状态字）,需要预分配空间，maxlength = 300
//      puiOutDataLen   :   返回响应数据长度
//      puiCosState     :   卡片执行状态字
// 返回码：
//      0               :   成功
//      其它            :   失败
extern unsigned int uiSDSCTransmit(unsigned char *psCommand, unsigned int uiCommandLen, unsigned int uiTimeOutMode, unsigned char *psOutData, unsigned int *puiOutDataLen, unsigned int *puiCosState);

// SD_ICC APDU EX
// 输入参数 :
//      psCommand       :   ICC Apdu命令串
//      uiCommandLen    :   命令串长度
//      uiTimeOutMode   :   超时模式，固定使用0.
//      puiOutDataLen   :   psOutData缓冲区长度
// 输出参数 :
//      psOutData       :   响应串缓冲区（包括状态字）,需要预分配空间，maxlength = 300
//      puiOutDataLen   :   返回响应数据长度
// 返回码：
//      0               :   成功
//      其它            :   失败
extern unsigned int uiSDSCTransmitEx(unsigned char *psCommand, unsigned int uiCommandLen, unsigned int uiTimeOutMode, unsigned char *psOutData, unsigned int *puiOutDataLen);

// 获取SD_ICC SDK版本号
// 输出参数 ：
//      puiVersionLen :   version缓冲区大小
// 输出参数 ：
//      pszVersion    :   SDK版本号数据缓冲，需要预先分配空间，maxlength = 20
//      puiVersionLen :   SDK版本号数据长度
// 返回码：
//      0             :   成功
//      其它          :   失败
extern unsigned int uiSDSCGetSDKVersion(char *pszVersion, unsigned int *puiVersionLen);

// 获取SD_ICC IO类型
// 输出参数：
//      puiSCIOType     :   IO类型,需预先创建对象：Integer SCIOType = new Integer(0)
//                          请参考：SD ICC IO Type
// 返回码：
//      0               :   成功
//      其它             :   失败
extern unsigned int uiSDSCGetSCIOType(unsigned int *puiSCIOType);

#endif

