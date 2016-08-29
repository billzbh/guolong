#ifndef __HXPINPADAPI_H__
#define __HXPINPADAPI_H__

#ifdef __cplusplus
extern "C" {
#endif

#define PINPAD_MODEL_ICR        0       //iCR
#define PINPAD_MODEL_LIANDI     1       //联迪mPos

// 查询Pinpad型号，返回PINPAD_MODEL_LIANDI和PINPAD_MODEL_ICR, 在设备连接成功后返回值才有效
// PINPAD_MODEL_LIANDI  : 支持密码输入, 不支持计算pinblock
// PINPAD_MODEL_ICR     : 支持计算pinblock，不支持密码输入
int HxPinpad_Model(void);
    

// 取消密码输入操作，用于取消密码输入
void HxPinpad_Cancel(void);

// Pinpad复位自检
// in  : initFlag  	: 该参数无效
// ret : 0			: 成功
//		 其它		: 失败， 其中1为设备连接失败
int HxPinpad_Reset(int initFlag);

// Pinpad固件版本号
// out : firmwareVersion  	: 版本号输出缓冲区，maxlength = 50
//		 versionLength		: 版本号长度
// ret : 0					: 成功
//		 其它				: 失败， 其中1为设备连接失败
int HxPinpad_GetVersion(unsigned char *firmwareVersion, int *versionLength);

// Pinpad下装主密钥
// in  : is3des  	: 是否采用3DES算法，该参数无效，使用3DES算法
//		 index		: 主密钥索引, 固定使用0
//	     mastKey	: 主密钥内容，16字节密钥 + 4字节校验
//		 keyLength	: 主密钥长度, 固定为20字节
// ret : 0			: 成功
//		 其它		: 失败， 其中1为设备连接失败
int HxPinpad_DownloadMasterKey(int is3des, int index, unsigned char* masterKey, int keyLength);

// Pinpad下装工作密钥
// in  : is3des  		: 是否采用3DES算法，该参数无效，使用3DES算法
//		masterIndex     : 主密钥索引, 固定使用0
//      workingIndex    : 工作密钥索引, 对应密钥类型如下：
//                              KEYTYPE_PIN     = 0x00,
//                              KEYTYPE_MAC     = 0x01,
//      workingKey        : workingkey内容，16字节密钥 + 4字节校验
//		keyLength		: 主密钥长度, 固定为20字节
// ret : 0				: 成功
//		 其它			: 失败， 其中1为设备连接失败
int HxPinpad_DownloadWorkingKey(int is3des, int masterIndex, int workingIndex, unsigned char* workingKey, int keyLength);
    
// 计算Pinblock
// in  : is3des  		: 是否采用3DES算法，该参数无效，使用3DES算法
//	     masterIndex	: 主密钥索引, 固定使用0
//	     workingIndex	: 工作密钥索引, workingIndex = 0x00
//		 cardNo			: 卡号/帐号（最少12位数字）
//		 pinLength		: 需要输入PIN的长度
// out : pinblock		: pinpad输出的pinblock
// ret : 0				: 成功
//		 其它			: 失败， 其中1为设备连接失败
int HxPinpad_CalPinblock(int is3des, int masterIndex, int workingIndex, char* cardNo, unsigned char* pin, int pinLength, unsigned char *pinblock);

// Pinpad输入密码
// in  : is3des  		: 是否采用3DES算法，该参数无效，使用3DES算法
//		 isAutoReturn	: 输入pin长度后，是否自动返回
//	     masterIndex	: 主密钥索引, 固定使用0
//	     workingIndex	: 工作密钥索引, workingIndex = 0x00
//		 cardNo			: 卡号/帐号（最少12位数字）
//		 pinLength		: 需要输入PIN的长度
//		 timeout		: 输入密码等待超时时间 <= 255 秒
// out : pinblock		: pinpad输出的pinblock
// ret : 0				: 成功
//		 其它			: 失败， 其中1为设备连接失败
int HxPinpad_InputPinblock(int is3des, int isAutoReturn, int masterIndex, int workingIndex, char* cardNo, int pinLength, unsigned char *pinblock, int timeout);
    
    
// Pinpad输入密码
// in  : is3des  		: 是否采用3DES算法，该参数无效，使用3DES算法
//		 isAutoReturn	: 输入pin长度后，是否自动返回
//	     masterIndex	: 主密钥索引, 固定使用0
//	     workingIndex	: 工作密钥索引, workingIndex = 0x00
//		 cardNo			: 卡号/帐号（最少12位数字）
//		 pinLength		: 需要输入PIN的长度
//		 timeout		: 输入密码等待超时时间 <= 255 秒
// out : pinblock		: pinpad输出的pinblock
// ret : 0				: 成功
//		 其它			: 失败， 其中1为设备连接失败
int HxPinpad_InputPinblockWithAmount(int is3des, int isAutoReturn, int masterIndex, int workingIndex, int amount,char* cardNo, int pinLength, unsigned char *pinblock, int timeout);
    
// Pinpad加密数据
// in  : is3des         : M35 无效，给false即可
//		 algo			: 算法，取值: ALGO_ENCRYPT 以ECB方式进行加密运算
//		 masterIndex	: 主密钥索引, 固定使用0
//	     workingIndex	: workingIndex = 0x01
//		 inData			: 加密输入数据
//		 dataLength		: indata数据长度，必须为8的倍数
// out : outData		    : 加解密输出的结果
// ret : 0				: 成功
//		 其它			: 失败
int HxPinpad_Encrypt(int is3des, int algo, int masterIndex, int workingIndex, unsigned char *  inData, int dataLength, unsigned char * outData);
    
// Pinpad数据MAC运算（ANSIX9.9）
// in  : is3des  		: 是否采用3DES算法，该参数无效，使用3DES算法
//		 masterIndex	: 主密钥索引, 固定使用0
//	     workingIndex	: workingIndex = 0x01
//		 inData			: 加解密输入数据
//		 dataLength		: indata数据长度，须为8的倍数
// out : outData		    : MAC计算输出的结果，8字节字节
// ret : 0				: 成功
//		 其它			: 失败， 其中1为设备连接失败
int HxPinpad_Mac(int is3des, int masterIndex, int workingIndex, unsigned char* data, int dataLength, unsigned char *mac);

#ifdef __cplusplus
}
#endif
#endif  // 结束宏定义
