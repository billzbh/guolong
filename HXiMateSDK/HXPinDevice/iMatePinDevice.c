//
//  iMatePinDevice.c
//  HXiMateSDK
//
//  Created by zbh on 14/12/11.
//  Copyright (c) 2014年 hxsmart. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "iMatePinDevice.h"
#include "iMatePinpadApi.h"

#ifndef __FOR_IOS__
#include "SyncCommon.h"
#else
extern int syncCommonEx(unsigned char *sendData, int sendLength, unsigned char *receivedData, int *receivedLength, int timeout);
extern void vOneTwo(const unsigned char *psIn, int iLength, unsigned char *psOut);
extern void vTwoOne(const unsigned char *psIn, int iLength, unsigned char *psOut);
#endif

#define COMM_NONE 			0
#define COMM_EVEN  			1
#define COMM_ODD  			2

#define PINPAD_BAUDRATE		9600L
#define PINPAD_PARITY		COMM_NONE

#ifdef DEBUG
extern void vSetWriteLog(int iOnOff);
extern void vWriteLogHex(char *pszTitle, void *pLog, int iLength);
extern void vWriteLogTxt(char *pszFormat, ...);
#endif

static volatile int sg_CancelFlag = 0;
static int PinDeviceComm(unsigned char *in, int inLength, unsigned char *out, int *outLength, int timeout);


//LRC数据验证，针对密码器，in 数据是One 格式的。
//返回的是两个字节的验证码
static void LRCcheck(unsigned char* inMsg,int iLength,unsigned char *outMsg)
{
    
    unsigned short Q=0,S=0;
    for (int i = 0; i < iLength; i++) {
        Q = (Q + inMsg[i]);
        S = (S + Q);
    }
    *outMsg = (char)((S & 0xff00) >> 8);
    *(outMsg+1) = (char)S & 0x00ff;
}

int pinDevicePowerOn(void)
{
    unsigned char sendBytes[6];
    
    sendBytes[0] = 0x69;
    sendBytes[1] = 0x00;
    sendBytes[2] = 1;
    sendBytes[3] = PINPAD_BAUDRATE/256;
    sendBytes[4] = PINPAD_BAUDRATE%256;
    sendBytes[5] = PINPAD_PARITY;
    return syncCommonEx(sendBytes, 6, NULL, NULL, 1);
}
// pinDevice下电
int pinDevicePowerOff(void)
{
    unsigned char sendBytes[3];
    
    sendBytes[0] = 0x69;
    sendBytes[1] = 0x00;
    sendBytes[2] = 2;
    
    return syncCommonEx(sendBytes, 6, NULL, NULL, 1);
}

//cancel
void pinDeviceCancel(void)
{
    sg_CancelFlag = 1;
}

//实现读取密码器机具号的功能
//[in]:
//    nport       密码器连接的端口号
//    cStep       包序号（即SEQ）
//
//[out]:
//    pResultMsg  密码器回送的数据，如果成功格式是：10位CIID＋4位芯片序列号，否则返回3个字节的错误信息。
//return: 0x00--成功    其他--失败（失败原因具体厂家定义）
int ReadCISN(int nport,unsigned char* pResultMsg, unsigned char cStep)
{
    //指令（不含校验的指令）
    unsigned char inValidData[20]={cStep,0x31,0x00,0x00};
    //生成校验
    unsigned char twoLRCBytes[2];
    LRCcheck(inValidData,4, twoLRCBytes);
    //组成指令
    inValidData[4] = twoLRCBytes[0];
    inValidData[5] = twoLRCBytes[1];
    
    int len = 6;
    //将指令 oneTwo
    unsigned char sendbytes[100];
    vOneTwo(inValidData, len, sendbytes);
    
    unsigned char reciveBytes[200];
    int Length;
    int ret = PinDeviceComm(sendbytes,len*2,reciveBytes,&Length,1);
    if(ret == -1 || ret == 1)
    {
        ret = 799;
        //蓝牙通讯错误
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }else if(ret != 0){
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }
    
    //对串口数据中Data区域作处理，以便上送(成功或者错误)
    if(reciveBytes[0]==0)
    {
        memcpy(pResultMsg, reciveBytes+1, Length-1);
        pResultMsg[Length-1]=0;
        ret = 0;
    }
    else
    {
        unsigned char errorNum[2];
        pResultMsg[0]=0x30;
        vOneTwo(reciveBytes,1, errorNum);
        pResultMsg[1]=errorNum[0];
        pResultMsg[2]=errorNum[1];
        pResultMsg[3]=0;
        ret = 2;
    }
    return ret;
}


//    调用该函数，可以得到16字节的芯片ID和80字节的VK。
//    nPort[in]：密码器连接的端口号
//    pACC[in]：账号，32字节，不满32位请前补0x30
//    pResultMsg[out]：密码器回送的结构，如果调用成功，返回的格式是：16字节芯片ID＋80字节VK，否则返回3个字节       的错误信息
//    cStep：包序号（即SEQ）。
int GenerateKeyPair(int nport,unsigned char* pACC,unsigned char* pResultMsg, unsigned char cStep)
{
    //指令（不含校验的指令）
    unsigned char inValidData[200]={cStep,0x32,0x00,0x10};
    unsigned char oneData[200];
    
    //账号长度
    unsigned char tmpBytes[32];
    memcpy(tmpBytes,pACC,32);
    vTwoOne(tmpBytes, 32, oneData);
    
    //拷贝16字节
    memcpy(inValidData+4, oneData, 16);
    
    //生成校验
    unsigned char twoLRCBytes[2];
    LRCcheck(inValidData,4+16, twoLRCBytes);
    //组成指令
    inValidData[4+16] = twoLRCBytes[0];
    inValidData[5+16] = twoLRCBytes[1];
    
    int len = 22;
    //将指令 oneTwo
    unsigned char sendbytes[200];
    vOneTwo(inValidData, len, sendbytes);
    
    unsigned char reciveBytes[200];
    int Length;
    //密码器超时时间为2秒 //pResultMsg 大小为 200
    int ret = PinDeviceComm(sendbytes,len*2,reciveBytes,&Length,5);
    if(ret == -1 || ret == 1)
    {
        ret = 799;
        //蓝牙通讯错误
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }else if(ret != 0){
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }
    
    //对串口数据中Data区域作处理，以便上送(成功或者错误)
    if(reciveBytes[0]==0)
    {
        memcpy(pResultMsg, reciveBytes+1, Length-1);
        pResultMsg[Length-1]=0;
        ret = 0;
    }
    else
    {
        unsigned char errorNum[2];
        pResultMsg[0]=0x30;
        vOneTwo(reciveBytes,1, errorNum);
        pResultMsg[1]=errorNum[0];
        pResultMsg[2]=errorNum[1];
        pResultMsg[3]=0;
        ret = 2;
    }
    return ret;
}

//    用途：
//    调用此函数，可以实现下载AK的功能。
//    nPort[in]：密码器连接的端口号
//    pACC[in]：账号，32字节，不满32位请前补0x30
//    pACCKey[in]：账号密钥，2个字节，（00－49）
//    pAK[in]：账号密钥AK支,16个字节
//    pResultMsg[out]：密码器回送的结果，如果调用成功，无返回信息，否则返回3个字节的错误信息
//    cStep：包序号（即SEQ）。
int DownLoadAK(int nport,unsigned char* pACC,unsigned char* pACCKey,unsigned char* pAK,unsigned char* pResultMsg , unsigned char cStep)
{
    //指令（不含校验的指令）
    unsigned char inValidData[200]={cStep,0x33,0x00,0x21};
    unsigned char onetwoData[200];
    unsigned char twoOneData[200];
    
    
    //pAcc
    unsigned char tmpBytes[32];
    memcpy(tmpBytes,pACC,32);
    vTwoOne(tmpBytes,32,twoOneData);
    //拷贝16字节
    memcpy(inValidData+4, twoOneData, 16);
    
    //key
    memcpy(tmpBytes,pACCKey,2);
    vTwoOne(tmpBytes, 2, twoOneData);
    memcpy(inValidData+20, twoOneData, 1);
    
    //AK支   //21+16=37
    memcpy(inValidData+21, pAK, 16);
    
    //生成校验
    unsigned char twoLRCBytes[2];
    LRCcheck(inValidData,37, twoLRCBytes);
    //组成指令
    inValidData[37] = twoLRCBytes[0];
    inValidData[38] = twoLRCBytes[1];
    
    int len = 39;
    //将指令 oneTwo
    vOneTwo(inValidData, len, onetwoData);
    
    unsigned char reciveBytes[200];
    int Length;
    int ret = PinDeviceComm(onetwoData,len*2,reciveBytes,&Length,5);
    
    if(ret == -1 || ret == 1)
    {
        ret = 799;
        //蓝牙通讯错误
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }else if(ret != 0){
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }
    
    //对串口数据中Data区域作处理，以便上送(成功或者错误)
    if(reciveBytes[0]==0)
    {
        pResultMsg[0]=0;
        ret = 0;
    }
    else
    {
        unsigned char errorNum[2];
        pResultMsg[0]=0x30;
        vOneTwo(reciveBytes,1, errorNum);
        pResultMsg[1]=errorNum[0];
        pResultMsg[2]=errorNum[1];
        pResultMsg[3]=0;
        ret = 2;
    }
    return ret;
}
//    用途：
//    调用此函数，可以删除指定账号。
//    nPort[in]：密码器连接的端口号
//    pACC[in]：账号，32字节，不满32位请前补0x30
//    pResultMsg[out]：密码器回送的结果，如果调用成功，无返回信息，否则返回3个字节的错误信息
//    cStep：包序号（即SEQ）。
int DelAcc(int nport,unsigned char* pACC,unsigned char* pResultMsg,unsigned char cStep)
{
    //指令（不含校验的指令）
    unsigned char inValidData[200]={cStep,0x34,0x00,0x10};
    unsigned char oneData[200];
    
    
    //账号长度
    unsigned char tmpBytes[32];
    memcpy(tmpBytes,pACC,32);
    vTwoOne(tmpBytes, 32, oneData);
    
    //拷贝16字节
    memcpy(inValidData+4, oneData, 16);
    
    //生成校验
    unsigned char twoLRCBytes[2];
    LRCcheck(inValidData,4+16, twoLRCBytes);
    //组成指令
    inValidData[4+16] = twoLRCBytes[0];
    inValidData[5+16] = twoLRCBytes[1];
    
    int len = 22;
    //将指令 oneTwo
    unsigned char sendbytes[200];
    vOneTwo(inValidData, len, sendbytes);
    
    unsigned char reciveBytes[200];
    int Length;
    int ret = PinDeviceComm(sendbytes,len*2,reciveBytes,&Length,5);
    if(ret == -1 || ret == 1)
    {
        ret = 799;
        //蓝牙通讯错误
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }else if(ret != 0){
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }
    
    //对串口数据中Data区域作处理，以便上送(成功或者错误)
    if(reciveBytes[0]==0)
    {
        pResultMsg[0]=0;
        ret = 0;
    }
    else
    {
        unsigned char errorNum[2];
        pResultMsg[0]=0x30;
        vOneTwo(reciveBytes,1, errorNum);
        pResultMsg[1]=errorNum[0];
        pResultMsg[2]=errorNum[1];
        pResultMsg[3]=0;
        ret = 2;
    }
    return ret;
}

//    用途：
//    调用此函数，可以实现增发签名的功能。
//    nPort[in]：密码器连接的端口号
//    pACC[in]：账号，32字节，不满32位请前补0x30
//    pNewChipID[in]：新增支付密码芯片ID，16个字节
//    pNewVK[in]：新增支付密码器VK,80个字节
//    pResultMsg[out]：密码器回送的结果，如果调用成功，返回信息是16个字节的签名，否则返回3个字节的错误信息
//    cStep：包序号（即SEQ）。
int AddMachineSign(int nport,unsigned char* pACC,unsigned char* pNewChipID,unsigned char* pNewVK,unsigned char* pResultMsg , unsigned char cStep)
{
    //指令（不含校验的指令）
    unsigned char inValidData[200]={cStep,0x35,0x00,0x70};
    unsigned char twoOneData[200];
    
    //pAcc
    unsigned char tmpBytes[32];
    memcpy(tmpBytes,pACC,32);
    vTwoOne(tmpBytes,32,twoOneData);
    //拷贝16字节 pAcc
    memcpy(inValidData+4, twoOneData, 16);
    
    
    //pNewChipID
    //拷贝16字节
    memcpy(inValidData+20, pNewChipID, 16);
    
    //拷贝VK 80字节
    memcpy(inValidData+36, pNewVK, 80);

    //生成校验
    unsigned char twoLRCBytes[2];
    LRCcheck(inValidData,116, twoLRCBytes);
    //组成指令
    inValidData[116] = twoLRCBytes[0];
    inValidData[117] = twoLRCBytes[1];
    
    int len = 118;
    //将指令 oneTwo
    unsigned char sendbytes[300];
    vOneTwo(inValidData, len, sendbytes);
    
    unsigned char reciveBytes[200];
    int Length;
    int ret = PinDeviceComm(sendbytes,len*2,reciveBytes,&Length,5);
    if(ret == -1 || ret == 1)
    {
        ret = 799;
        //蓝牙通讯错误
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }else if(ret != 0){
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }
    
    //对串口数据中Data区域作处理，以便上送(成功或者错误)
    if(reciveBytes[0]==0)
    {
        memcpy(pResultMsg, reciveBytes+1, Length-1);
        pResultMsg[Length-1]=0;
        ret = 0;
    }
    else
    {
        unsigned char errorNum[2];
        pResultMsg[0]=0x30;
        vOneTwo(reciveBytes,1, errorNum);
        pResultMsg[1]=errorNum[0];
        pResultMsg[2]=errorNum[1];
        pResultMsg[3]=0;
        ret = 2;
    }
    return ret;
}


//    用途：
//    调用此函数实现密码器解锁的功能。
//    nPort[in]：密码器连接的端口号
//    pUnlockCode[in]：8个字节的解锁密码
//    pResultMsg[out]：密码器回送的结果，如果调用成功，无返回信息，否则返回3个字节的错误信息
//    cStep：包序号（即SEQ）。
int UnlockCI(int nport,unsigned char* pUnlockCode,unsigned char* pResultMsg , unsigned char cStep)
{
    //指令（不含校验的指令）
    unsigned char inValidData[200]={cStep,0x36,0x00,0x08};

    //拷贝8字节解锁密码
    memcpy(inValidData+4, pUnlockCode, 8);
    
    //生成校验
    unsigned char twoLRCBytes[2];
    LRCcheck(inValidData,12, twoLRCBytes);
    //组成指令
    inValidData[12] = twoLRCBytes[0];
    inValidData[13] = twoLRCBytes[1];
    
    int len = 14;
    //将指令 oneTwo
    unsigned char sendbytes[200];
    vOneTwo(inValidData, len, sendbytes);
    
    unsigned char reciveBytes[200];
    int Length;
    int ret = PinDeviceComm(sendbytes,len*2,reciveBytes,&Length,5);
    if(ret == -1 || ret == 1)
    {
        ret = 799;
        //蓝牙通讯错误
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }else if(ret != 0){
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }
    
    
    //对串口数据中Data区域作处理，以便上送(成功或者错误)
    if(reciveBytes[0]==0)
    {
        pResultMsg[0]=0;
        ret = 0;
    }
    else
    {
        unsigned char errorNum[2];
        pResultMsg[0]=0x30;
        vOneTwo(reciveBytes,1, errorNum);
        pResultMsg[1]=errorNum[0];
        pResultMsg[2]=errorNum[1];
        pResultMsg[3]=0;
        ret = 2;
    }
    return ret;
}


//    用途：
//    调用此函数，实现发行机具的功能。
//    nPort[in]：密码器连接的端口号
//    pUnlockCode[in]：8个字节的解锁密码
//    pResultMsg[out]：密码器回送的结果，如果调用成功，无返回信息，否则返回3个字节的错误信息
//    cStep：包序号（即SEQ）。
int IssueCI(int nport,unsigned char* pUnlockCode,unsigned char* pResultMsg, unsigned char cStep)
{
    //指令（不含校验的指令）
    unsigned char inValidData[200]={cStep,0x37,0x00,0x08};
    
    //拷贝8字节解锁密码
    memcpy(inValidData+4, pUnlockCode, 8);
    
    //生成校验
    unsigned char twoLRCBytes[2];
    LRCcheck(inValidData,12, twoLRCBytes);
    //组成指令
    inValidData[12] = twoLRCBytes[0];
    inValidData[13] = twoLRCBytes[1];
    
    int len = 14;
    //将指令 oneTwo
    unsigned char sendbytes[200];
    vOneTwo(inValidData, len, sendbytes);
    
    unsigned char reciveBytes[200];
    int Length;
    int ret = PinDeviceComm(sendbytes,len*2,reciveBytes,&Length,5);
    if(ret == -1 || ret == 1)
    {
        ret = 799;
        //蓝牙通讯错误
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }else if(ret != 0){
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }
    
    
    //对串口数据中Data区域作处理，以便上送(成功或者错误)
    if(reciveBytes[0]==0)
    {
        pResultMsg[0]=0;
        ret = 0;
    }
    else
    {
        unsigned char errorNum[2];
        pResultMsg[0]=0x30;
        vOneTwo(reciveBytes,1, errorNum);
        pResultMsg[1]=errorNum[0];
        pResultMsg[2]=errorNum[1];
        pResultMsg[3]=0;
        ret = 2;
    }
    return ret;
}


//    用途：
//    调用此函数，实现联机计算支付密码的功能。
//    nPort[in]：密码器连接的端口号
//    pACC[in]：账号，32字节，不满32位请前补0x30
//    cService [in]：一个字节的业务种类
//    pDate [in]：日期，8个字节
//    pTicketNum[in]：凭证号码，8个字节
//    pBanlance[in]：金额，16个字节
//    pResultMsg[out]：密码器回送的结果，如果调用成功，返回信息是20个字节的支付密码（前4字节暂不使用），否则返回3个字节的错误信息
//    cStep：包序号（即SEQ）。
int ConnectCICalculate(int nport,unsigned char* pACC,unsigned char cService,unsigned char* pDate,unsigned char* pTicketNum,unsigned char* pBanlance,unsigned char* pResultMsg , unsigned char cStep)
{
    
    //指令（不含校验的指令）
    unsigned char inValidData[200]={cStep,0x38,0x00,0x30};
    unsigned char twoOneData[200];
    
    unsigned char tmpBytes[32];
    memcpy(tmpBytes,pACC,32);
    vTwoOne(tmpBytes,32,twoOneData);
    
    //指令后面15个字节补0，所以从19下标开始复制
    //拷贝pAcc
    memcpy(inValidData+4+15, twoOneData, 16);
    
    //业务种类
    inValidData[35]=cService;
    
    //拷贝日期字节
    memcpy(tmpBytes,pDate,8);
    vTwoOne(tmpBytes,8,twoOneData);
    memcpy(inValidData+36, twoOneData, 4);
    
    //拷贝凭证号码
    memcpy(tmpBytes,pTicketNum,8);
    vTwoOne(tmpBytes,8,twoOneData);
    memcpy(inValidData+40, twoOneData, 4);
    
    //拷贝金额数据
    memcpy(tmpBytes,pBanlance,16);
    vTwoOne(tmpBytes,16,twoOneData);
    memcpy(inValidData+44, twoOneData, 8);
    
    //生成校验
    unsigned char twoLRCBytes[2];
    LRCcheck(inValidData,52, twoLRCBytes);
    //组成指令
    inValidData[52] = twoLRCBytes[0];
    inValidData[53] = twoLRCBytes[1];
    
    int len = 54;
    //将指令 oneTwo
    unsigned char sendbytes[200];
    vOneTwo(inValidData, len, sendbytes);
    
    unsigned char reciveBytes[200];
    int Length;
    int ret = PinDeviceComm(sendbytes,len*2,reciveBytes,&Length,5);
    if(ret == -1 || ret == 1)
    {
        ret = 799;
        //蓝牙通讯错误
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }else if(ret != 0){
        sprintf(pResultMsg, "%03d",ret);
        return 2;
    }
    
    //对串口数据中Data区域作判断，以便上送(成功或者错误)
    if(reciveBytes[0]==0)
    {
        memcpy(pResultMsg, reciveBytes+1, Length-1);
        pResultMsg[Length-1]=0;
        ret = 0;
    }
    else
    {
        unsigned char errorNum[2];
        pResultMsg[0]=0x30;
        vOneTwo(reciveBytes,1, errorNum);
        pResultMsg[1]=errorNum[0];
        pResultMsg[2]=errorNum[1];
        pResultMsg[3]=0;
        ret = 2;
    }
    return ret;
}



//0 成功  > 0 失败   <0 syncCommonEx失败
static int PinDeviceComm(unsigned char *in, int inLength, unsigned char *out, int *outLength, int timeout)
{
    sg_CancelFlag = 0;
    
    unsigned char receivedBytes[600];
    unsigned char sendBytes[600];

    inLength=inLength+2;
    sendBytes[0] = 0x69;
    sendBytes[1] = 0x00;
    sendBytes[2] = 3; //发送数据报文命令
    sendBytes[3] = inLength/256;
    sendBytes[4] = inLength%256;
    sendBytes[5] = 0x02;
    
    int i;
    for (i=0; i<inLength-2; i++)
        sendBytes[i+6] = in[i];
    
    sendBytes[4+inLength] = 0x03;
    
    int ret = syncCommonEx(sendBytes, 5+inLength, NULL, NULL, 1);
    if (ret)
        return ret;
    
    long m = time(NULL) + timeout;
    int receivedLength = 0;
    int finished = 0;
    int receiveDataLength = 0;
    while (time(NULL) < m) {
        
        if (sg_CancelFlag) {
            sg_CancelFlag = 0;
            return 777;
        }
        
        sendBytes[0] = 0x69;
        sendBytes[1] = 0x00;
        sendBytes[2] = 4;
        
        unsigned char tmpBytes[600];
        int theLen;
        int ret = syncCommonEx(sendBytes, 3, tmpBytes, &theLen, 1);
        if (ret)
            return ret;
        
        if (tmpBytes[0] != 0)
            return 1;
        
//        usleep(1000*200);
#ifdef DEBUG
        vSetWriteLog(1);
        vWriteLogHex("every receviced data:",tmpBytes,theLen);
#endif
        if (theLen <= 1) {
            continue;
        }
        
        for (i=0; i<theLen-1; i++) {
            receivedBytes[receivedLength+i] = tmpBytes[i+1];
        }
        receivedLength += theLen-1;

        if (receivedLength < 14)
            continue;
        
        
        //包头
        if (receivedBytes[0] != 0x02 )
            return 814;
        
        //包接收结束
        if (tmpBytes[theLen-1] == 0x03 ) {
            finished = 1;
            break;
        }
    }
    if (!finished)
        return 811;//超时

#ifdef DEBUG
    vWriteLogHex("ALL receviced data:",receivedBytes,receivedLength);
#endif

    unsigned char tempBytes[600];
    //掐头去尾（0x02,0x03）
    memcpy(tempBytes, receivedBytes+1, receivedLength-2);
    
#ifdef DEBUG
    vWriteLogHex("cut (0x02,0x03) and data is :",tempBytes,receivedLength-2);
#endif
    
    //定义twoOne后的长度和buffer （SEQ(1),TAG(1),LENTGH(2),DATA(n) ,LRC(2)）
    int twoOneLenth =(receivedLength-2)/2;
    unsigned char twoOneData[twoOneLenth];
    
    //数据twoOne
    vTwoOne(tempBytes,receivedLength-2,twoOneData);
#ifdef DEBUG
    vWriteLogHex("After twoOne, data is :",twoOneData,twoOneLenth);
#endif
    
    //接收包data长度校验
    receiveDataLength = twoOneLenth-6;
    if ( (twoOneData[2]*256+twoOneData[3]) != receiveDataLength)
        return 815;
    
    //接受包校验错误
    unsigned char twobytes[2];
    LRCcheck(twoOneData,(twoOneLenth-2),twobytes);
    if(twobytes[0]!=twoOneData[twoOneLenth-2]&&twobytes[1]!=twoOneData[twoOneLenth-1])
        return 816;
    
    //截取data区域
    memcpy(out, twoOneData+4, receiveDataLength);
    *outLength = receiveDataLength;
    out[receiveDataLength]='\0';
#ifdef DEBUG
    vWriteLogHex("out data:",out,receiveDataLength);
#endif

//    memcpy(out, tempBytes+8, receiveDataLength*2);
//    *outLength = receiveDataLength*2;
//    out[receiveDataLength*2]='\0';
//    printf("上送的数据:%s\n",out);
    return 0;
}

