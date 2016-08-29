#ifndef __M35PINPADAPI_H__
#define __M35PINPADAPI_H__

#ifdef __cplusplus
extern "C" {
#endif

// 取消密码输入操作，用于取消密码输入
void M35Pinpad_Cancel(void);

// Pinpad复位自检
// in  : initFlag  	: 该参数无效
// ret : 0			: 成功
//		 其它		: 失败， 其中1为设备连接失败
int M35Pinpad_Reset(int initFlag);

// Pinpad固件版本号
// out : firmwareVersion  	: 版本号输出缓冲区，maxlength = 50
//		 versionLength		: 版本号长度
// ret : 0					: 成功
//		 其它				: 失败， 其中1为设备连接失败
int M35Pinpad_GetVersion(unsigned char *firmwareVersion, int *versionLength);

// Pinpad下装主密钥
// in  : is3des  	: 是否采用3DES算法，该参数无效，使用3DES算法
//		 index		: 主密钥索引
//	     mastKey	: 主密钥内容，16字节密钥 + 4字节校验
//		 keyLength	: 主密钥长度, 固定为20字节
// ret : 0			: 成功
//		 其它		: 失败， 其中1为设备连接失败
int M35Pinpad_DownloadMasterKey(int is3des, int index, unsigned char* masterKey, int keyLength);

// Pinpad下装工作密钥
// in  : is3des  		: 是否采用3DES算法，该参数无效，使用3DES算法
//		masterIndex     : 主密钥索引， 该参数无效
//      workingIndex    : 工作密钥索引, 对应密钥类型如下：
//                                      KEYTYPE_PIN     = 0x02,
//                                      KEYTYPE_MAC     = 0x03,
//      workingKey        : workingkey内容，16字节密钥 + 4字节校验
//		keyLength		: 主密钥长度, 固定为20字节
// ret : 0				: 成功
//		 其它			: 失败， 其中1为设备连接失败
int M35Pinpad_DownloadWorkingKey(int is3des, int masterIndex, int workingIndex, unsigned char* workingKey, int keyLength);

// Pinpad输入密码
// in  : is3des  		: 是否采用3DES算法，该参数无效，使用3DES算法
//		 isAutoReturn	: 输入pin长度后，是否自动返回
//	     masterIndex	: 主密钥索引
//	     workingIndex	: 工作密钥索引
//		 cardNo			: 卡号/帐号（最少12位数字）
//		 pinLength		: 需要输入PIN的长度
//		 timeout		: 输入密码等待超时时间 <= 255 秒
// out : pinblock		: pinpad输出的pinblock
// ret : 0				: 成功
//		 其它			: 失败， 其中1为设备连接失败
int M35Pinpad_InputPinblock(int is3des, int isAutoReturn, int masterIndex, int workingIndex, char* cardNo, int pinLength, unsigned char *pinblock, int timeout);
    
    
// Pinpad输入密码
// in  : is3des  		: 是否采用3DES算法，该参数无效，使用3DES算法
//		 isAutoReturn	: 输入pin长度后，是否自动返回
//	     masterIndex	: 主密钥索引
//	     workingIndex	: 工作密钥索引
//		 cardNo			: 卡号/帐号（最少12位数字）
//		 pinLength		: 需要输入PIN的长度
//		 timeout		: 输入密码等待超时时间 <= 255 秒
// out : pinblock		: pinpad输出的pinblock
// ret : 0				: 成功
//		 其它			: 失败， 其中1为设备连接失败
int M35Pinpad_InputPinblockWithAmount(int is3des, int isAutoReturn, int masterIndex, int workingIndex, int amount,char* cardNo, int pinLength, unsigned char *pinblock, int timeout);
    
// Pinpad加密数据
// in  : is3des           : M35 无效，给false即可
//		 algo			 : 算法，取值: ALGO_ENCRYPT 以ECB方式进行加密运算
//		 masterIndex	     : M35 无效，给0即可
//	     workingIndex	    : M35 无效，给0即可
//		 inData			: 加密输入数据
//		 dataLength		: indata数据长度，必须为8的倍数
// out : outData		    : 加解密输出的结果
// ret : 0				: 成功
//		 其它			: 失败
int M35Pinpad_Encrypt(int is3des, int algo, int masterIndex, int workingIndex, unsigned char *  inData, int dataLength, unsigned char * outData);
    
// Pinpad数据MAC运算（ANSIX9.9）
// in  : is3des  		    : 是否采用3DES算法，该参数无效，使用3DES算法
//		 masterIndex	     : 主密钥索引, 该参数无效
//	     workingIndex	     : 工作密钥索引， 该参数无效，自动选择 Mac Key 计算 Mac
//		 inData			: 加解密输入数据
//		 dataLength		: indata数据长度，须为8的倍数
// out : outData		    : MAC计算输出的结果，8字节字节
// ret : 0				: 成功
//		 其它			: 失败， 其中1为设备连接失败
int M35Pinpad_Mac(int is3des, int masterIndex, int workingIndex, unsigned char* data, int dataLength, unsigned char *mac);

#ifdef __cplusplus
}
#endif
#endif  // 结束宏定义
