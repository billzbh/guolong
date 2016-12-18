//
//  ZCenterManager.m
//  ZeasySDK
//
//  Created by zbh on 16/12/18.
//  Copyright © 2016年 zhangbh. All rights reserved.
//

#import "ZCenterManager.h"

static CBCentralManager *g_centralManager;
static volatile int sg_sessionStatus = CBSessionStateClosed;
@implementation ZCenterManager
{
    NSArray *_UUIDStrings;
    NSArray *_BtNames;
    int TIMEOUT;
}

//获取单例
+ (ZCenterManager *)shareCenterManager
{
    static ZCenterManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ZCenterManager alloc] init];
        
        dispatch_queue_t centralManagerQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);//此队列没有loop,不支持timer
        g_centralManager = [[CBCentralManager alloc] initWithDelegate:sharedInstance queue:centralManagerQueue];
    });
    
    return sharedInstance;
}


//搜全部蓝牙设备
-(void)startSearch:(int)timeout{
    [self startSearch:timeout filterByServiceUUIDs:nil filterByBluetoothName:nil];
}

-(void)startSearch:(int)timeout filterByServiceUUIDs:(NSArray<NSString *> *)UUIDStrings filterByBluetoothName:(NSArray<NSString *> *)Names
{
    
    _UUIDStrings = UUIDStrings;
    _BtNames = Names;
    TIMEOUT = timeout;
    if(sg_sessionStatus != CBSessionStateReady)
    {
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(delaySearch) userInfo:nil repeats:NO];
        return;
    }
    
    NSMutableArray<CBUUID *> *CBUUIDS = nil;
    if (_UUIDStrings!=nil) {
        CBUUIDS = [[NSMutableArray alloc] init];
        for (NSString *uuid in _UUIDStrings) {
            [CBUUIDS addObject:[CBUUID UUIDWithString:uuid]];
        }
    }
    
    if(g_centralManager.isScanning)
        [g_centralManager stopScan];
    
    [g_centralManager scanForPeripheralsWithServices:CBUUIDS options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
    [NSTimer scheduledTimerWithTimeInterval:TIMEOUT target:self selector:@selector(stopSearch) userInfo:nil repeats:NO];
    return;
}

-(void)delaySearch
{
    if(sg_sessionStatus != CBSessionStateReady)
    {
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(delaySearch) userInfo:nil repeats:NO];
        return;
    }
    
    NSMutableArray<CBUUID *> *CBUUIDS = nil;
    if (_UUIDStrings!=nil) {
        CBUUIDS = [[NSMutableArray alloc] init];
        for (NSString *uuid in _UUIDStrings) {
            [CBUUIDS addObject:[CBUUID UUIDWithString:uuid]];
        }
    }
    
    if(g_centralManager.isScanning)
        [g_centralManager stopScan];
    
    [g_centralManager scanForPeripheralsWithServices:CBUUIDS options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
    [NSTimer scheduledTimerWithTimeInterval:TIMEOUT target:self selector:@selector(stopSearch) userInfo:nil repeats:NO];
    return;
}



-(void)stopSearch{
#ifdef DEBUG
    NSLog(@"停止搜索");
#endif
    [g_centralManager stopScan];
}

#pragma mark  - CBCentralManagerDelegate method
//init中央设备结果回调
- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            sg_sessionStatus = CBSessionStateReady;
            break;
        case CBCentralManagerStateUnsupported:
            sg_sessionStatus = CBSessionStateUnsupported;
            break;
        case CBCentralManagerStateUnauthorized:
            sg_sessionStatus = CBSessionStateUnauthorized;
            break;
        case CBCentralManagerStatePoweredOff:
            sg_sessionStatus = CBSessionStatePoweredOff;
            break;
        case CBCentralManagerStateUnknown:
            sg_sessionStatus = CBSessionStateUnknown;
            break;
        case CBCentralManagerStateResetting:
            sg_sessionStatus = CBSessionStateReseting;
            break;
        default:
            sg_sessionStatus = CBSessionStateUnknown;
            break;
    }
}

//启动搜索的结果回调
- (void) centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData
                   RSSI:(NSNumber *)RSSI
{
#ifdef DEBUG
    NSLog(@"centralManager:didDiscoverPeripheral:%@ advertisementData:%@ RSSI %@",
          peripheral,
          [advertisementData description],
          RSSI);
#endif
    //持有peripheral的引用，不然出了这个方法，它会被释放为 nil
    [self setPeripheral:peripheral];
    
    if (_bindingDeviceName!=nil) {
        if ([peripheral.name rangeOfString:_bindingDeviceName].location != NSNotFound) {
            
#ifdef DEBUG
            NSLog(@"找到上一次连接的设备%@...准备连接",peripheral.name);
#endif
            [self stopSearch];
            [self.centralManager connectPeripheral:peripheral
                                           options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                                               forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
        }else
        {
#ifdef DEBUG
            NSLog(@"没找到上一次连接的设备");
#endif
        }
    }else{
        //上报发现的设备
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_MysearchBLEBlock) {
                _MysearchBLEBlock(peripheral);
            }
        });
    }
}


//发起连接的回调结果
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
#ifdef DEBUG
    NSLog(@"centralManager:didConnectPeripheral:%@", peripheral);
#endif
    
    // Clear the data that we may already have
    [_receivedData reset];
    [self setPeripheral:peripheral];
    
#ifdef DEBUG
    NSLog(@"discovering services...");
#endif
    // Make sure we get the discovery callbacks
    self.peripheral.delegate = self; //实现CBPeripheralDelegate的方法
    [self.peripheral discoverServices:[NSArray arrayWithObjects:[CBUUID UUIDWithString:ICRPLUS_SERVICE],[CBUUID UUIDWithString:IMATE_SERVICE], nil]];
}


//发起连接的回调结果(假设远端蓝牙关闭电源，自动连接时可能报这个错)
- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral
                  error:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"centralManager:didFailToConnectPeripheral:%@ error:%@", aPeripheral, [error localizedDescription]);
#endif
    
    sg_sessionStatus = CBSessionStateConnectingFail;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(_MyStatusBlock!=nil)
            _MyStatusBlock(CBSessionStateConnectingFail);
    });
    if (self.read_characteristic && self.peripheral) {
        [self.peripheral setNotifyValue:NO forCharacteristic:self.read_characteristic];
    }
    writechar=NO;
    readchar=NO;
    return;
}

//（被动）断开连接的回调结果
- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral
                  error:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"centralManager:didDisconnectPeripheral:%@ error:%@", peripheral, [error localizedDescription]);
    
    
    NSLog(@"Peripheral Disconnected");
#endif
    
    sg_sessionStatus = CBSessionStateDisconnected;
    writechar=NO;
    readchar=NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        if(_MyStatusBlock!=nil)
            _MyStatusBlock(CBSessionStateDisconnected);
    });
    // We're disconnected, so start scanning again
    if (_bindingDeviceName!=nil) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_findDeviceTimer) {
#ifdef DEBUG
                NSLog(@"开启定时器，并触发");
#endif
                [_findDeviceTimer setFireDate:[NSDate distantPast]];//开启定时器
            }
        });
    }
    
#ifdef DEBUG
    NSLog(@"peripheral reconnecting...");
#endif
}

@end
