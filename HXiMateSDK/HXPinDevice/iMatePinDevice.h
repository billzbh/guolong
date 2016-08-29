//
//  iMatePinDevice.h
//  HXiMateSDK
//
//  Created by zbh on 14/12/11.
//  Copyright (c) 2014年 hxsmart. All rights reserved.
//

#ifndef __HXiMateSDK__iMatePinDevice__
#define __HXiMateSDK__iMatePinDevice__

//以下函数返回值为
//0  成功。
//2  表示密码器的错误或者蓝牙通讯的错误。可以从pResultMsg得到3个字节的错误信息

//777   iMate单个操作取消
//799   iMate蓝牙通讯错误
//811	接收数据超时
//814	接收数据包头错误
//815	接收数据包长度错误
//816	接收数据包校验错

//密码器返回错误代码：
//001	芯片校验码错误
//002	芯片请求类型错误
//003	芯片请求数据错误
//004	芯片银行主密钥错误
//005	芯片增发签名错误
//006	芯片其他错误（芯片可能已损坏）
//010	数据包接收不完整
//011	数据包校验和错误
//012	支付密码器内存读错误
//013	支付密码器内存写错误
//014	支付密码器内存擦除错误
//020	读支付密码器序列号错
//021	读芯片序列号错
//022	支付密码器账号已满
//023	支付密码器账号已存在
//024	支付密码器未生成密钥对
//025	账号不一致
//026	账号不存在
//027	随机解锁密码不匹配
//052	签发口令错误
//053	签发口令被锁
//054	签发员无此权限
//055	无该签发员
//056	审核口令错误
//057	审核口令被锁
//058	审核员无此权限
//059	无该审核员
//05a	授权口令错误
//05b	授权口令被锁
//05c	授权员无此权限（计算支付密码协议中返回）
//060	无该授权员
//061	授权员授权金额权限不够（计算支付密码协议中返回）
//062	其它错误
//063	机具未发行


#ifdef __cplusplus
extern "C" {
#endif

// pinDevice上电 (通讯波特率为9600 校验方式 0）
int pinDevicePowerOn(void);

// pinDevice下电
int pinDevicePowerOff(void);

// pinDevice取消比较耗时的输入
void pinDeviceCancel(void);

//实现读取密码器机具号的功能
//[in]:
//    nport       密码器连接的端口号
//    cStep       包序号（即SEQ）
//    
//[out]:
//    pResultMsg  密码器回送的结构，如果成功格式是：10位CIID＋4位芯片序列号（没有就补0000），否则返回3个字节的错误信息
//return: 0x00--成功    其他--失败（失败原因具体厂家定义）
int ReadCISN(int nport,unsigned char* pResultMsg, unsigned char cStep);

    
//    调用该函数，可以得到16字节的芯片ID和80字节的VK。
//    nPort[in]：密码器连接的端口号
//    pACC[in]：账号，32字节，不满32位请前补0x30
//    pResultMsg[out]：密码器回送的结构，如果调用成功，返回的格式是：16字节芯片ID＋80字节VK，否则返回3个字节的错误信息
//    cStep：包序号（即SEQ）。
int GenerateKeyPair(int nport,unsigned char* pACC,unsigned char* pResultMsg, unsigned char cStep);

//    用途：
//    调用此函数，可以实现下载AK的功能。
//    nPort[in]：密码器连接的端口号
//    pACC[in]：账号，32字节，不满32位请前补0x30
//    pACCKey[in]：账号密钥，2个字节，（00－49）
//    pAK[in]：账号密钥AK支,16个字节
//    pResultMsg[out]：密码器回送的结果，如果调用成功，无返回信息，否则返回3个字节的错误信息
//    cStep：包序号（即SEQ）。
int DownLoadAK(int nport,unsigned char* pACC,unsigned char* pACCKey,unsigned char* pAK,unsigned char* pResultMsg , unsigned char cStep);
//    用途：
//    调用此函数，可以删除指定账号。
//    nPort[in]：密码器连接的端口号
//    pACC[in]：账号，32字节，不满32位请前补0x30
//    pResultMsg[out]：密码器回送的结果，如果调用成功，无返回信息，否则返回3个字节的错误信息
//    cStep：包序号（即SEQ）。
int DelAcc(int nport,unsigned char* pACC,unsigned char* pResultMsg,unsigned char cStep);
    
//    用途：
//    调用此函数，可以实现增发签名的功能。
//    nPort[in]：密码器连接的端口号
//    pACC[in]：账号，32字节，不满32位请前补0x30
//    pNewChipID[in]：新增支付密码芯片ID，16个字节
//    pNewVK[in]：新增支付密码器VK,80个字节
//    pResultMsg[out]：密码器回送的结果，如果调用成功，返回信息是16个字节的签名，否则返回3个字节的错误信息
//    cStep：包序号（即SEQ）。
int AddMachineSign(int nport,unsigned char* pACC,unsigned char* pNewChipID,unsigned char* pNewVK,unsigned char* pResultMsg , unsigned char cStep);

    
//    用途：
//    调用此函数实现密码器解锁的功能。
//    nPort[in]：密码器连接的端口号
//    pUnlockCode[in]：8个字节的解锁密码
//    pResultMsg[out]：密码器回送的结果，如果调用成功，无返回信息，否则返回3个字节的错误信息
//    cStep：包序号（即SEQ）。
int UnlockCI(int nport,unsigned char* pUnlockCode,unsigned char* pResultMsg , unsigned char cStep);

    
//    用途：
//    调用此函数，实现发行机具的功能。
//    nPort[in]：密码器连接的端口号
//    pUnlockCode[in]：8个字节的解锁密码
//    pResultMsg[out]：密码器回送的结果，如果调用成功，无返回信息，否则返回3个字节的错误信息
//    cStep：包序号（即SEQ）。
int IssueCI(int nport,unsigned char* pUnlockCode,unsigned char* pResultMsg , unsigned char cStep);

    
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
int ConnectCICalculate(int nport,unsigned char* pACC,unsigned char cService,unsigned char* pDate,unsigned char* pTicketNum,unsigned char* pBanlance,unsigned char* pResultMsg , unsigned char cStep);
    
#ifdef __cplusplus
}
#endif

#endif /* defined(__HXiMateSDK__iMatePinDevice__) */
