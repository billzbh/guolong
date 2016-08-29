//
//  SyncCommon.h
//  HXiMateSDK
//
//  Created by hxsmart on 13-12-18.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EADSessionController.h"

@interface SyncCommon : NSObject

+(SyncCommon *)syncCommon:(EADSessionController *)sessionController;

-(void)putData:(int)iRetCode data:(unsigned char *) psResponseDataBuff dataLen:(int)iResponseDataLen;

-(int)bluetoothSendRecv:(unsigned char *)psRequestDataBuff
                dataLen:(int)iRequestDataLen
        ResponseDataBuf:(unsigned char *)psResponseDataBuf
                timeout:(int)timeout;

- (NSString *)getErrorString:(Byte *)errorBytes length:(int)length;

@end
