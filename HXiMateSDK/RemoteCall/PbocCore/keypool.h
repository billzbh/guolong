/**************************************
File name     : keypool.h
Function      : RSA密钥缓冲池服务程序
Author        : Yu Jun
First edition : Mar 25th, 2011
Modified      : 
**************************************/
#ifndef _KEYPOOL_H
#define _KEYPOOL_H

#include "rsaref.h"

#if defined(WIN32) || defined(WINDOWS)
#undef  UNIX
#else
#undef  UNIX
#define UNIX
#endif


// 密钥池初始化
// in  : iUseKeyPoolFlag : 1:启用Pool 0:不启用Pool
// ret : 0 : OK
//       1 : 错误
// Note: 即使初始化返回错误，后续依然可以调用iRsaKeyPoolGetKey()生成密钥
int iRsaKeyPoolInit(int iUseKeyPoolFlag);

// 生成RSA密钥对
// in  : iRsaKeyLen  : rsa密钥长度
//       lRsaKeyE    : rsa密钥e值，3 or 65537
// out : pPublicKey  : 公钥
//       pPrivateKey : 私钥
// ret : 0 : OK
//       1 : 错误
int iRsaKeyPoolGetKey(int iRsaKeyLen, long lRsaKeyE, 
		      R_RSA_PUBLIC_KEY  *pPublicKey, 
		      R_RSA_PRIVATE_KEY *pPrivateKey);

#endif
