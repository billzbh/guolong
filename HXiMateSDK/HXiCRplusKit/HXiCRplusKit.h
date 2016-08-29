//
//  HXiCRplusKit.h
//  HXiMateSDK
//
//  Created by zbh on 15/12/8.
//  Copyright © 2015年 hxsmart. All rights reserved.
//
#import "DeviceDefine.h"
#import <Foundation/Foundation.h>


@interface HXiCRplusKit : NSObject

@property (weak,nonatomic) id<HXiCRplusDelegate> delegate;

- (void)test:(OperationBlock)oppp;

@end
