//
//  ZPeripheral.h
//  ZeasySDK
//
//  Created by zbh on 16/12/18.
//  Copyright © 2016年 zhangbh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ZBLEData.h"

@interface ZPeripheral : NSObject

@property (nonatomic,strong) CBPeripheral *CoreBluePeripheral;
@property (nonatomic,strong) ZBLEData *bleData;

//共八个方法
//发送bin，接收bin方法
//发送HexString方法，接收HexString方法
//发送并接收bin带超时方法
//发送并接收HexString带超时方法
//发送bin，接收HexString带超时方法
//发送HexString，接收bin带超时方法

//设置写特征，读特征


@end
