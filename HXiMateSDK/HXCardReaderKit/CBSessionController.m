//
//  CBSessionController.m
//
//  Created by hxsmart on 15/1/7.
//  Copyright (c) 2015年 hxsmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>

#import "CBSessionController.h"
#import "iMateData.h"

#define IMATE_SERVICE                   @"FFE0"
#define SERVICE_CHARACTERISTIC          @"FFE1"
#define ICR_SEND_MTU                    20      //超过20字节传送速度就会慢下来
#define CBCHARACTERISTIC_WRITE_TYPE     CBCharacteristicWriteWithoutResponse


static CBSessionController *sg_sessionController = nil;
static volatile int sg_sessionStatus = CBSessionStateClosed;
static volatile BOOL sg_isWorking = NO;

@interface CBSessionController () <CBCentralManagerDelegate, CBPeripheralDelegate> {
    volatile BOOL receivedCompleted;

}

@property (nonatomic, strong) NSString                  *bindingDeviceName;

@property (strong, nonatomic) CBCentralManager          *centralManager;
@property (strong, nonatomic) CBPeripheral              *peripheral;
@property (strong, nonatomic) CBCharacteristic          *characteristic;
@property (strong, atomic)    iMateData                 *receivedData;
@property (strong, nonatomic) NSMutableArray            *searchedDeviceNamesArray;

@end

@implementation CBSessionController

+ (CBSessionController *)sharedController
{
    if (sg_sessionController == nil) {
        sg_sessionController = [[CBSessionController alloc] init];
    }
    return sg_sessionController;
}

- (BOOL)openSession
{
    if (_searchedDeviceNamesArray == nil)
        _searchedDeviceNamesArray = [[NSMutableArray alloc] init];
    [_searchedDeviceNamesArray removeAllObjects];
    if (_centralManager == nil) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _receivedData = [[iMateData alloc] init];
    }
    if (_centralManager == nil)
        return NO;

    return YES;
}

- (void)closeSession
{
    if (_searchedDeviceNamesArray)
        [_searchedDeviceNamesArray removeAllObjects];
    
    if (_centralManager) {
        [self stopScan];
        [self disconnect];
        
        _centralManager = nil;
        _receivedData = nil;
    }
    sg_sessionStatus = CBSessionStateClosed;
    NSNumber *statusObj = [NSNumber numberWithInt:sg_sessionStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CBSessionStatusNotification" object:statusObj];
}

// 绑定查找到的设备, 只有绑定设备后，设备才可以正常连接
- (void)bindingDevice:(NSString *)deviceName
{
    if (deviceName == nil)
        [_searchedDeviceNamesArray removeAllObjects];

    _bindingDeviceName = deviceName;
    
    [self stopScan];
    [self startScan];
    
#ifdef DEBUG
    NSLog(@"*******bindingDevice:%@******", deviceName);
#endif
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
                sendLength = length;
                if (length > ICR_SEND_MTU)
                    sendLength = ICR_SEND_MTU;
                
                memset(sendBuff, 0, sizeof(sendBuff));
                memcpy(sendBuff, inData.bytes + offset, sendLength);
                NSData *data = [NSData dataWithBytes:sendBuff length:ICR_SEND_MTU];
                [self.peripheral writeValue:data
                          forCharacteristic:self.characteristic
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
    [_receivedData reset];
    receivedCompleted = NO;
    
    _receivedData.sendData = inData;
    NSData *packData = [_receivedData packSendData];
    
    CBSessionState ret;
    ret = [self sendData:packData];
    
    if (ret != CBSessionStateOk)
        return ret;
    
    sg_isWorking = YES;
    double timeSeconds = [self currentTimeSeconds] + timeout;
    while ([self currentTimeSeconds] < timeSeconds) {
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

#pragma mark - Local methods

- (void)startScan
{
    if (_centralManager) {
        //NSArray *services = [NSArray arrayWithObject:[CBUUID UUIDWithString:IMATE_SERVICE]];
        [_centralManager scanForPeripheralsWithServices:nil options:nil];
    }
}

- (void)stopScan
{
    if (_centralManager)
        [_centralManager stopScan];
}

- (void)cleanup
{
    sg_sessionStatus = CBSessionStateDisconnected;

    NSNumber *statusObj = [NSNumber numberWithInt:sg_sessionStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CBSessionStatusNotification" object:statusObj];
    
    // Don't do anything if we're not connected
    if (self.peripheral == nil) {
        return;
    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (self.peripheral.services != nil) {
        for (CBService *service in self.peripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:IMATE_SERVICE]]) {
                        if (characteristic.isNotifying) {
                            // It is notifying, so unsubscribe
                            [self.peripheral setNotifyValue:NO forCharacteristic:characteristic];
                            
                            // And we're done.
                            return;
                        }
                    }
                }
            }
        }
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [_centralManager cancelPeripheralConnection:self.peripheral];
}

- (void) disconnect {
    // it seems necessary to explicitly unsubscribe before disconnecting
    // if we don't do this, the server still thinks it's connected
    // and subsequent connection attempts fail.
    if (self.characteristic) {
        [self.peripheral setNotifyValue:NO forCharacteristic:self.characteristic];
    }
    if (self.peripheral) {
        [_centralManager cancelPeripheralConnection:self.peripheral];
    }
}

-(double)currentTimeSeconds
{
    NSTimeInterval time= [[NSDate date] timeIntervalSince1970];
    return (double)time;
}


#pragma mark - CBCentralManagerDelegate method

- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (_centralManager.state) {
        case CBCentralManagerStatePoweredOn:
            sg_sessionStatus = CBSessionStateDisconnected;
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
    if ([_centralManager state] == CBCentralManagerStatePoweredOn) {
        [self startScan];
#ifdef DEBUG
        NSLog(@"start scan");
#endif
    }
    else {
        NSNumber *statusObj = [NSNumber numberWithInt:sg_sessionStatus];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CBSessionStatusNotification" object:statusObj];
    }
}


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
    
    if (_bindingDeviceName == nil) {
#ifdef DEBUG
        NSLog(@"Found the peripheral %@", peripheral);
#endif
#ifdef SUPPORT_DEVICE_M35
        if (([peripheral.name hasPrefix:@"ICR-"] || [peripheral.name hasPrefix:@"M35-"]|| [peripheral.name hasPrefix:@"M36-"]) && self.peripheral != peripheral) {
#else
        if ([peripheral.name hasPrefix:@"ICR-"] && self.peripheral != peripheral) {
#endif
            for (NSString *deviceName in _searchedDeviceNamesArray) {
                if ([deviceName isEqualToString:peripheral.name])
                    return;
            }
            [_searchedDeviceNamesArray addObject:peripheral.name];
            if (_delegate && [_delegate respondsToSelector:@selector(cbSessionDelegateFoundAvailableDevice:)] ) {
                [_delegate cbSessionDelegateFoundAvailableDevice:peripheral.name];
            }
            return;
        }
    }
    else {
        if ([peripheral.name hasPrefix:_bindingDeviceName] && self.peripheral != peripheral) {
#ifdef SUPPORT_DEVICE_M35
            if ([_bindingDeviceName hasPrefix:@"M35-"]||[_bindingDeviceName hasPrefix:@"M36-"]) {
#ifdef DEBUG
                NSLog(@"Release the control");
#endif
                [_delegate cbSessionDelegateReleaseControl:peripheral.name];
                return;
            }
#endif
            if ([_bindingDeviceName hasPrefix:@"ICR-"]) {
                self.peripheral = peripheral;
    #ifdef DEBUG
                NSLog(@"Connecting to peripheral %@", peripheral);
    #endif
                [_centralManager
                    connectPeripheral:self.peripheral
                    options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                    forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
#ifdef DEBUG
    NSLog(@"centralManager:didRetrievePeripherals:%@", [peripherals description]);
#endif
    [self stopScan];
    
    // If there are any known devices, automatically connect to it.
    if([peripherals count] >= 1) {
#ifdef DEBUG
        NSLog(@"connecting...");
#endif
        self.peripheral = [peripherals objectAtIndex:0];
        [_centralManager connectPeripheral:self.peripheral
                        options:[NSDictionary dictionaryWithObject:
                        [NSNumber numberWithBool:YES]
                        forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    }
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
#ifdef DEBUG
    NSLog(@"centralManager:didConnectPeripheral:%@", peripheral);
#endif
    
    [self stopScan];
#ifdef DEBUG
    NSLog(@"Scanning stopped");
#endif
    
    // Clear the data that we may already have
    [_receivedData reset];
    
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;

#ifdef DEBUG
    NSLog(@"discovering services...");
#endif
    [peripheral discoverServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:IMATE_SERVICE]]];
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral
                  error:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"centralManager:didDisconnectPeripheral:%@ error:%@", peripheral, [error localizedDescription]);
    

    NSLog(@"Peripheral Disconnected");
#endif
    self.peripheral = nil;
    
    sg_sessionStatus = CBSessionStateDisconnected;
    
    NSNumber *statusObj = [NSNumber numberWithInt:sg_sessionStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CBSessionStatusNotification" object:statusObj];
    
    // We're disconnected, so start scanning again
    [self startScan];
#ifdef DEBUG
    NSLog(@"start scan");
#endif
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral
                  error:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"centralManager:didFailToConnectPeripheral:%@ error:%@", aPeripheral, [error localizedDescription]);
#endif
    [self cleanup];
}

#pragma mark - CBPeripheralDelegate methods

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        [self cleanup];
        return;
    }
#ifdef DEBUG
    NSLog(@"peripheral:%@ didDiscoverServices:%@", peripheral, [error localizedDescription]);
#endif
    for (CBService *service in peripheral.services) {
#ifdef DEBUG
        NSLog(@"Service found with UUID: %@", service.UUID);
#endif
        if ([service.UUID isEqual:[CBUUID UUIDWithString:IMATE_SERVICE]]) {
#ifdef DEBUG
            NSLog(@"DEVICE SERVICE FOUND");
#endif
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:SERVICE_CHARACTERISTIC]] forService:service];
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
        [self cleanup];
        return;
    }
    
    if([service.UUID isEqual:[CBUUID UUIDWithString:IMATE_SERVICE]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
#ifdef DEBUG
            NSLog(@"discovered characteristic %@", characteristic.UUID);
#endif
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:SERVICE_CHARACTERISTIC]]) {
#ifdef DEBUG
                NSLog(@"Found Notify Characteristic %@", characteristic);
#endif
                self.characteristic = characteristic;
                [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
                
                sg_sessionStatus = CBSessionStateOk;
                NSNumber *statusObj = [NSNumber numberWithInt:sg_sessionStatus];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CBSessionStatusNotification" object:statusObj];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"peripheral:%@ didUpdateValueForCharacteristic:%@ error:%@",
          peripheral, characteristic, error);
#endif
    
    if (error) {
#ifdef DEBUG
        NSLog(@"Error updating value for characteristic %@ error: %@",
              characteristic.UUID, [error localizedDescription]);
#endif
        return;
    }
    
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:SERVICE_CHARACTERISTIC]]) {
        [_receivedData appendReceiveData:characteristic.value];
        if ([_receivedData unpackReceivedData] == MATEReceivedDataIsValid)
            receivedCompleted = YES;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"peripheral:%@ didWriteValueForCharacteristic:%@ error:%@",
          peripheral, characteristic, [error description]);
#endif
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
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:IMATE_SERVICE]]) {
        return;
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
#ifdef DEBUG
        NSLog(@"Notification began on %@", characteristic);
#endif
    }
    
    // Notification has stopped
    else {
        // so disconnect from the peripheral
#ifdef DEBUG
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
#endif
        [_centralManager cancelPeripheralConnection:peripheral];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"peripheral:%@ didDiscoverDescriptorsForCharacteristic:%@ error:%@",
          peripheral, characteristic, [error localizedDescription]);
#endif
}


@end


