#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <time.h>

#include "unsigned.h"

static int sg_iLogFlag = 0;

static void vOneTwo(const uchar *psIn, int iLength, uchar *psOut)
{
    static const uchar aucHexToChar[17] = "0123456789ABCDEF";
    int iCounter=0;

    for(iCounter = 0; iCounter < iLength; iCounter++){
        psOut[2*iCounter] = aucHexToChar[((psIn[iCounter] >> 4)) & 0x0F];
        psOut[2*iCounter+1] = aucHexToChar[(psIn[iCounter] & 0x0F)];
    }
}
static void vOneTwo0(const uchar *psIn, int iLength, uchar *pszOut)
{
    vOneTwo(psIn, iLength, pszOut);
	if(iLength < 0)
		iLength = 0;
    pszOut[2*iLength]=0;
}

void vSetWriteLog(int iOnOff)
{
	sg_iLogFlag = iOnOff;
}

void vWriteLogHex(char *pszTitle, void *pLog, int iLength)
{
    char szBuf[2048];

	if(sg_iLogFlag == 0)
		return;

    memset(szBuf,0,sizeof(szBuf));
    if(pszTitle) {
        sprintf(szBuf, "%s(%3d) : ", pszTitle, iLength);
    }
	vOneTwo0(pLog, (ushort)iLength, szBuf+strlen(szBuf));
    printf("%s\n",szBuf);
}

void vWriteLogTxt(char *pszFormat, ...)
{
    va_list args;
    char buff[2048];

	if(sg_iLogFlag == 0)
		return;

    va_start(args, pszFormat);
    sprintf(buff, "%lu ", time(NULL));
    vsprintf(buff + strlen(buff), pszFormat, args);
    //vprintf(pszFormat, args);
	printf("%s\n", buff);
    va_end(args);
}
