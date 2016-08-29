//
//  BLESessionController.m
//  HXiMateSDK
//
//  Created by zbh on 15/12/8.
//  Copyright © 2015年 hxsmart. All rights reserved.
//

#import "BLESessionController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>
#import "iMateData.h"
#import "DeviceDefine.h"

#define ICRPLUS_SERVICE                         @"FFE0"
#define SERVICE_READ_CHARACTERISTIC             @"FFE1"
#define SERVICE_WRITE_CHARACTERISTIC            @"FFE1"
#define ICR_SEND_MTU                            20      //超过20字节传送速度就会慢下来
#define CBCHARACTERISTIC_WRITE_TYPE             CBCharacteristicWriteWithoutResponse //写结果不通知

static volatile int sg_sessionStatus = CBSessionStateClosed;
static volatile BOOL sg_isWorking = NO;

@interface BLESessionController () <CBCentralManagerDelegate, CBPeripheralDelegate> {
    volatile BOOL receivedCompleted;
    volatile BOOL readchar;
    volatile BOOL writechar;
    volatile BOOL cancelFlag;
}
@property (nonatomic,strong)  NSTimer                   *findDeviceTimer;
@property (nonatomic, strong) NSString                  *bindingDeviceName;
@property (strong, nonatomic) CBCentralManager          *centralManager;
@property (strong, nonatomic) CBPeripheral              *peripheral;
@property (strong, nonatomic) CBCharacteristic          *read_characteristic;
@property (strong, nonatomic) CBCharacteristic          *write_characteristic;
@property (strong, atomic)    iMateData                 *receivedData;

@end


@implementation BLESessionController

+ (BLESessionController *)getInstance
{
    static BLESessionController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BLESessionController alloc] init];
    });
    return sharedInstance;
}

-(void) OpenSessionWithDelegate:(id<BLESessionControllerDelegate>)delegate
{
    [self setDelegate:delegate];
    if (_centralManager == nil) {
        dispatch_queue_t centralManagerQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralManagerQueue];
        _receivedData = [[iMateData alloc] init];
    }
    if (_centralManager == nil)
        return;
    
    readchar = NO;
    writechar =NO;
    cancelFlag = NO;
    receivedCompleted = NO;
}

- (void)CloseSession
{
    if (_centralManager) {
        [self disconnect];
        _centralManager = nil;
        _receivedData = nil;
        [self setDelegate:nil];
    }
    //取消定时器
    if (_findDeviceTimer) {
        [_findDeviceTimer invalidate];
        _findDeviceTimer = nil;
    }
    sg_sessionStatus = CBSessionStateClosed;
}


-(void)searchBLE:(int)Timeout
{
    _bindingDeviceName = nil;
    [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    if (Timeout < 0 ) {
        return;
    }
    //取消定时器
    if (_findDeviceTimer) {
        [_findDeviceTimer invalidate];
        _findDeviceTimer = nil;
    }
    [NSTimer scheduledTimerWithTimeInterval:Timeout target:self selector:@selector(stopSearch) userInfo:nil repeats:NO];
    return;
}

-(void)stopSearch{
    if (_centralManager){
        if([_centralManager isScanning])
            [self.centralManager stopScan];
    }
}

-(void)connectDevice:(CBPeripheral *)Peripheral
{
    //停止搜索
    if ([_centralManager isScanning]) {
        [self stopSearch];
    }
    if ([self isConnecting]) {//已经连接
        if (_peripheral!=nil && [_peripheral isEqual:Peripheral]) {//判断要连上一个吗？
            return;
        }
        [self disconnect];
    }
    readchar = NO;
    writechar =NO;
    [self.centralManager connectPeripheral:Peripheral
                                   options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                   forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}

//主动断开连接
- (void)disconnect {
    //停止搜索
    if ([_centralManager isScanning]) {
        [self stopSearch];
    }
    // it seems necessary to explicitly unsubscribe before disconnecting
    // if we don't do this, the server still thinks it's connected
    // and subsequent connection attempts fail.
    if (self.read_characteristic) {
        [self.peripheral setNotifyValue:NO forCharacteristic:self.read_characteristic];
    }
    if (self.peripheral) {
        [_centralManager cancelPeripheralConnection:self.peripheral];
        [self setPeripheral:nil];
    }
}

//init之后在Ready状态下，直接调用此接口，则自动连接包含有此deviceName的设备
- (void)bindingDevice:(NSString *)deviceName
{
    
    [self setBindingDeviceName:deviceName];
    //定时器
    if (_findDeviceTimer) {
        [_findDeviceTimer fire];
        return;
    }
    _findDeviceTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(searchNameAndAutoconnect) userInfo:nil repeats:YES];
    [_findDeviceTimer fire];
}

-(NSString*)getBindingDeviceName{
    return _bindingDeviceName;
}


-(void)searchNameAndAutoconnect
{
    [self disconnect];
    [self searchBLE:6];
}

- (BOOL)isConnecting
{
    if (sg_sessionStatus == CBSessionStateOk)
        return YES;
    return NO;
}

- (BOOL)isWorking
{
    return sg_isWorking;
}




#pragma mark - 发送接收数据

-(void)cancelTransferData
{
    cancelFlag=YES;
}


//发送数据
- (CBSessionState)sendData:(NSData *) inData
{
    if (sg_sessionStatus != CBSessionStateOk)
        return sg_sessionStatus;
    
    dispatch_async(dispatch_get_main_queue(), ^{ //解决多线程写数据冲突的问题，使用main_queue进行排队
        @autoreleasepool {
            sg_isWorking = YES;
            int length = (int)inData.length;
            int offset = 0;
            int sendLength = 0;
            
            Byte sendBuff[ICR_SEND_MTU];
            while (length) {
                if (cancelFlag) {
                    cancelFlag = NO;
                    return;
                }
                sendLength = length;
                if (length > ICR_SEND_MTU)
                    sendLength = ICR_SEND_MTU;
                
                memset(sendBuff, 0, sizeof(sendBuff));
                memcpy(sendBuff, inData.bytes + offset, sendLength);
                NSData *data = [NSData dataWithBytes:sendBuff length:ICR_SEND_MTU];
                [self.peripheral writeValue:data
                          forCharacteristic:self.write_characteristic
                                       type:CBCHARACTERISTIC_WRITE_TYPE];
                offset += sendLength;
                length -= sendLength;
            }
            sg_isWorking = NO;
        }
    });
    return CBSessionStateOk;
}


- (CBSessionState)syncSendReceive:(NSData *) inData outData:(NSData **) outData timeout:(int) timeout
{
    sg_isWorking = YES;
    [_receivedData reset];
    receivedCompleted = NO;
    
    _receivedData.sendData = inData;
    NSData *packData = [_receivedData packSendData];
    
    CBSessionState ret;
    ret = [self sendData:packData];
    
    if (ret != CBSessionStateOk){
        sg_isWorking = NO;
        return ret;
    }

    double timeSeconds = [self currentTimeSeconds] + timeout;
    while ([self currentTimeSeconds] < timeSeconds) {
        
        if (cancelFlag) {
            cancelFlag = NO;
            return CBSessionStateCanceltransfer;
        }
        if(receivedCompleted)
            break;
        usleep(2000);
    }
    if (!receivedCompleted) {
        sg_isWorking = NO;
        return CBSessionStateTimeout;
    }
    
    Byte retcode = _receivedData.returnCode;
    NSMutableData *retData = [NSMutableData dataWithBytes:&retcode length:1];
    [retData appendData:_receivedData.receivedData];
    
    *outData = [NSData dataWithData:retData];
    
    sg_isWorking = NO;
    return CBSessionStateOk;
}

-(double)currentTimeSeconds
{
    NSTimeInterval time= [[NSDate date] timeIntervalSince1970];
    return (double)time;
}



#pragma mark  - CBCentralManagerDelegate method

//init中央设备结果回调
- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (_centralManager.state) {
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
        default:
            sg_sessionStatus = CBSessionStateUnknown;
            break;
    }
    [_delegate BLEDelegateInitStatus:sg_sessionStatus];
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
    NSLog(@"peripheral.name: %@", peripheral.name);
#endif
    if (_bindingDeviceName!=nil) {
        if ([peripheral.name containsString:_bindingDeviceName]) {
            [self.centralManager connectPeripheral:peripheral
                                           options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                           forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
        }
    }else{
        //上报发现的设备
        [_delegate BLEDelegateFoundAvailableDevice:peripheral];
    }
}


//发起连接的回调结果
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
#ifdef DEBUG
    NSLog(@"centralManager:didConnectPeripheral:%@", peripheral);
#endif
    
    [self stopSearch];
    // Clear the data that we may already have
    [_receivedData reset];
    [self setPeripheral:peripheral];
    
#ifdef DEBUG
    NSLog(@"discovering services...");
#endif
    // Make sure we get the discovery callbacks
    peripheral.delegate = self; //实现CBPeripheralDelegate的方法
    if (_bindingDeviceName!=nil) {
        if ([peripheral.name containsString:_bindingDeviceName]) {
            [peripheral discoverServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:ICRPLUS_SERVICE]]];
        }
    }else{
        [peripheral discoverServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:ICRPLUS_SERVICE]]];
    }
}


//发起连接的回调结果
- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral
                  error:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"centralManager:didFailToConnectPeripheral:%@ error:%@", aPeripheral, [error localizedDescription]);
#endif
    
    sg_sessionStatus = CBSessionStateDisconnected;
    [_delegate BLEDelegateConnectStatus:BLUETOOTH_CONNECTING_FAIL];
    if (self.read_characteristic && self.peripheral) {
        [self.peripheral setNotifyValue:NO forCharacteristic:self.read_characteristic];
    }
    return;
}

//（主动或者被动）断开连接的回调结果
- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral
                  error:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"centralManager:didDisconnectPeripheral:%@ error:%@", peripheral, [error localizedDescription]);
    
    
    NSLog(@"Peripheral Disconnected");
#endif
    
    sg_sessionStatus = CBSessionStateDisconnected;
    [_delegate BLEDelegateConnectStatus:BLUETOOTH_DISCONNECTED];
    // We're disconnected, so start scanning again
    if (self.peripheral!=nil) {
        [self connectDevice:self.peripheral];
    }
    
#ifdef DEBUG
    NSLog(@"peripheral reconnecting...");
#endif
}


#pragma mark - CBPeripheralDelegate methods

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        sg_sessionStatus = CBSessionStateDisconnected;
        [_delegate BLEDelegateConnectStatus:BLUETOOTH_FOUNDSERVICE_FAIL];
        
        if (self.read_characteristic) {
            [self.peripheral setNotifyValue:NO forCharacteristic:self.read_characteristic];
        }
        return;
    }
#ifdef DEBUG
    NSLog(@"peripheral:%@ didDiscoverServices:%@", peripheral, [error localizedDescription]);
#endif
    
    for (CBService *service in peripheral.services) {
#ifdef DEBUG
        NSLog(@"Service found with UUID: %@", service.UUID);
#endif

        if ([service.UUID isEqual:[CBUUID UUIDWithString:ICRPLUS_SERVICE]]) {
#ifdef DEBUG
            NSLog(@"DEVICE SERVICE FOUND");
#endif
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    if (error) {
#ifdef DEBUG
        NSLog(@"Discovered characteristics for %@ with error: %@",
              service.UUID, [error localizedDescription]);
#endif
        sg_sessionStatus = CBSessionStateDisconnected;
        [_delegate BLEDelegateConnectStatus:BLUETOOTH_FOUNDCHARACTERISTIC_FAIL];
        if (self.read_characteristic) {
            [self.peripheral setNotifyValue:NO forCharacteristic:self.read_characteristic];
        }
        return;
    }
    
    if([service.UUID isEqual:[CBUUID UUIDWithString:ICRPLUS_SERVICE]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
#ifdef DEBUG
            NSLog(@"discovered characteristic %@", characteristic.UUID);
#endif
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:SERVICE_READ_CHARACTERISTIC]]) {
#ifdef DEBUG
                NSLog(@"Found Notify Characteristic %@", characteristic);
#endif
                self.read_characteristic = characteristic;
                [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
                readchar = YES;

            }else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:SERVICE_WRITE_CHARACTERISTIC]]){
#ifdef DEBUG
                NSLog(@"Found WRITE Characteristic %@", characteristic);
#endif
                self.read_characteristic = characteristic;
                writechar =YES;
            }
            
            if (writechar&&readchar) {//发现两个特征值，上报连接成功，保存设备对象
                sg_sessionStatus = CBSessionStateOk;
                [_delegate BLEDelegateConnectStatus:BLUETOOTH_CONNECTED];
            }
        }
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"peripheral:%@ didUpdateValueForCharacteristic:%@ error:%@",peripheral, characteristic, error);
#endif
    
    if (error) {
#ifdef DEBUG
        NSLog(@"Error updating value for characteristic %@ error: %@",characteristic.UUID, [error localizedDescription]);
#endif
        return;
    }
    
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:SERVICE_READ_CHARACTERISTIC]]) {
        [_receivedData appendReceiveData:characteristic.value];
        if ([_receivedData unpackReceivedData] == MATEReceivedDataIsValid)
            receivedCompleted = YES;
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    
    if (error) {
#ifdef DEBUG
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
#endif
    }
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:SERVICE_READ_CHARACTERISTIC]]) {
        return;
    }else{
        // Notification has started
        if (characteristic.isNotifying) {
#ifdef DEBUG
            NSLog(@"Notification began on %@", characteristic);
#endif
        }
        // Notification has stopped
        else {
#ifdef DEBUG
            NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
#endif
        }
    }

}


@end
