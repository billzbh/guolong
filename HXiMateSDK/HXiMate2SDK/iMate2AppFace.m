//
//  iMateAppFace.m
//
//  Created by hxsmart on 12-10-17.
//  Copyright (c) 2012年 hxsmart. All rights reserved.
//

#import "iMateAppFace.h"
#import "iMateAppFacePrivate.h"
#import <ExternalAccessory/ExternalAccessory.h>
#import "EADSessionController.h"
#import "CBSessionController.h"
#import "iMateData.h"
#import "vposface.h"
#import "IDLib.h"
#import "iMateAppFace+Pinpad.h"
#import "iMateAppFace+Fingerprint.h"
#import "LandiMPOS.h"
#import "RemoteFunctions.h"

#define DEFULT_TIMEOUT  3
#define PROTOCOL_STRING_IMATE   @"com.imate.bluetooth"
#define PROTOCOL_STRING_PRINTER @"com.issc.datapath"
#define PROTOCOL_STRING_IMFC   @"com.imfc.bluetooth"

#define IMATE            100
#define LIANDIM35        200
#define M35DISCONNECT    300
#define IMATEDISCONNECT  400

#define IMATE_T7_PRINTER   1
#define IMATE_M36_PRINTER  2

typedef enum {
    kRequestNone = 0,
	kRequestSwipeCard,
	kRequestICResetCard,
	kRequestICApdu,
	kRequestIDReadMessage,
	kRequestBatteryLevel,
	kRequestXmemRead,
	kRequestXmemWrite,
    kRequestSync,
    kRequestDeviceVersion,
    kRequestBuzzer,
    kRequestDeviceTest,
    kRequestWaitEvent,
    kRequestWriteTermId,
} MateRequestType;

NSData *gl_masterKeyFromDevice;
unsigned char gl_supportPbocPushApdu;
unsigned char gl_supportPackageSequenceNumberProtocol;
unsigned char gl_thePackageSequenceNumber;
unsigned char gl_theBluetoothWorkMode = 0; // 0:蓝牙2.0 with MFI; 1：蓝牙4.0
unsigned int  gl_theDeviceMode = 100;      // 设备类型，100，300，400
unsigned char gl_support401Bt40AckMode = 0; //iMate401蓝牙4.0 ACK通讯模式

static volatile MateRequestType requestType;

static iMateAppFace *sg_iMateAppFace = nil;

static id sg_self = nil;

extern void vSetCardResetData(uchar *psCardResetData, uint uiLen);
// 设置远程函数调用模式是否支持，0不支持，1支持
extern void vSetRemoteCallMode(uchar ucMode);
extern uchar _ucRcXMemReadReserved(void *pBuf, uint uiOffset, uint uiLen);
extern void vSetWriteLog(int iOnOff);
extern void vSetDeviceType(uchar DeviceType);

@implementation FingerprintObject
@end

@interface iMateAppFace ()

@property (nonatomic) int icResetCardSlot;
@property (nonatomic) int BindingType;
@property(nonatomic,strong) LandiMPOS *manager;
@property(nonatomic,strong) NSTimer *findM35blueTimer;
@property (nonatomic,strong) NSString *BindingMposDeviceName;
@property (nonatomic,strong) NSString *BindingMposDeviceCBUUID;
@property (nonatomic) BOOL isSearching;
@end

@implementation iMateAppFace

- (id)initWithDelegate:(id)delegate
{
	if ((self = [super init])) {
        _delegate = delegate;
        vSetDeviceType(0);
		[self accessoryInit];
	}
	return self;
}

- (void)accessoryInit
{
    //注册接收数据处理
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedDataCompleted:)
                                                 name:@"ReceivedDataCompletedNotification"
                                               object:nil];
    // watch for the accessory being connected
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessoryDidConnect:) name:EAAccessoryDidConnectNotification object:nil];
    // watch for the accessory being disconnected
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessoryDidDisconnect:) name:EAAccessoryDidDisconnectNotification object:nil];
    // watch for received data from the accessory
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionDataReceived:) name:EADSessionDataReceivedNotification object:nil];
    
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    
    self.iMateEADSessionController = [[EADSessionController alloc] init];
    self.printerEADSessionController = [[EADSessionController alloc] init];
    
    self.imateDataObj = [[iMateData alloc] init];

    _syncCommon = [SyncCommon syncCommon:self.iMateEADSessionController];
    
    // Set default pinpad model
    [self pinpadSetModel:PINPAD_MODEL_KMY];
    
    // Set default fingerprint model
    [self fingerprintSetModel:FINGERPRINT_MODEL_JSABC];
    
    requestType = kRequestNone;
    gl_supportPackageSequenceNumberProtocol = NO;
    
#ifdef DEBUG
    vSetWriteLog(1);
#endif
    
    sg_self = self;
}

- (BOOL)openSession
{
#ifdef DEBUG
    NSLog(@"openSession");
#endif
    BOOL lastConnectStatus = _isMateConnected;

    _isMateConnected = NO;
    _isMposConnected = NO;
    NSArray *accessoryList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
    for (EAAccessory *accessory in accessoryList) {
        if ( ![[accessory protocolStrings] count] ) {
            continue;
        }
#ifdef DEBUG
        NSLog(@"%@",[accessory protocolStrings]);
#endif
        if ([[accessory protocolStrings] containsObject:PROTOCOL_STRING_IMATE]) {
            [_iMateEADSessionController setupControllerForAccessory:accessory
                                           withProtocolString:PROTOCOL_STRING_IMATE];
            self.iMateAccessory = [_iMateEADSessionController accessory];

            [_iMateEADSessionController openSession];
            _isMateConnected = YES;
            
            if ( requestType != kRequestNone && !lastConnectStatus ) {
                [self cancel];
                requestType = kRequestNone;
            }
            [self deviceSetup:NO];
        }
        if ([[accessory protocolStrings] containsObject:PROTOCOL_STRING_IMFC]) {
            [_iMateEADSessionController setupControllerForAccessory:accessory
                                                 withProtocolString:PROTOCOL_STRING_IMFC];
            self.iMateAccessory = [_iMateEADSessionController accessory];
            
            [_iMateEADSessionController openSession];
            _isMateConnected = YES;
            
            if ( requestType != kRequestNone && !lastConnectStatus ) {
                [self cancel];
                requestType = kRequestNone;
            }
        }
        if ([[accessory protocolStrings] containsObject:PROTOCOL_STRING_PRINTER]) {
            [_printerEADSessionController setupControllerForAccessory:accessory
                                                 withProtocolString:PROTOCOL_STRING_PRINTER];
            self.printerAccessory = [_printerEADSessionController accessory];
            [_printerEADSessionController openSession];
            _isPrinterConnected = YES;
        }
    }
    
    //联迪M35
    //1 获取实例
    _manager = [LandiMPOS getInstance];
    NSLog(@"logVersion is:%@",[_manager getLibVersion]);
    _findM35blueTimer = [NSTimer scheduledTimerWithTimeInterval:8.0f target:self selector:@selector(checkAndReConnectDevice) userInfo:nil repeats:YES];
    [_findM35blueTimer fire];
    return YES;
}

-(void)checkAndReConnectDevice{
    if (_isMateConnected&&![_manager isConnectToDevice]) {
        [_manager stopSearchDev];
        if (!_isSearching) {
            
            if (_BindingMposDeviceName!=nil) {//如果已经绑定设备
                [_manager startSearchDev:5.0 searchOneDeviceBlcok:^(LDC_DEVICEBASEINFO *deviceInfo){
                    
                    if ([deviceInfo.deviceName hasPrefix:_BindingMposDeviceName]) {
                        [_manager openDevice:deviceInfo.deviceIndentifier channel:CHANNEL_BLUETOOTH mode:COMMUNICATIONMODE_MASTER successBlock:^{
                            _isMposConnected = YES;
                            NSLog(@"绑定设备连接OK");
                        } failedBlock:^(NSString *errCode, NSString *errInfo) {
                            NSLog(@"设备开启失败.失败码：%@,失败描述:%@",errCode,errInfo);
                        }];
                    }
                    
                }completeBlock:^(NSMutableArray *deviceArray){
                }];
            }else{//没有调绑定设备方法
//                [_manager startSearchDev:5.0 searchOneDeviceBlcok:^(LDC_DEVICEBASEINFO *deviceInfo){
//                    
//                    if ([deviceInfo.deviceName hasPrefix:@"M35-"]||[deviceInfo.deviceName hasPrefix:@"M36-"]) {
//                        
//                        [_manager openDevice:deviceInfo.deviceIndentifier channel:CHANNEL_BLUETOOTH mode:COMMUNICATIONMODE_MASTER successBlock:^{
//                            _isMposConnected = YES;
//                            NSLog(@"手柄设备自动连接OK");
//                        } failedBlock:^(NSString *errCode, NSString *errInfo) {
//                            NSLog(@"设备开启失败.失败码：%@,失败描述:%@",errCode,errInfo);
//                        }];
//                    }
//                    
//                }completeBlock:^(NSMutableArray *deviceArray){
//                }];
            }
        }
    }
}

//开始搜索
-(void)startSearchBLE{
    [_findM35blueTimer invalidate];
    [_manager stopSearchDev];
    [_manager closeDevice];
    _isSearching =YES;
    _BindingMposDeviceCBUUID = nil;
    _BindingMposDeviceName = nil;
    
    _findM35blueTimer = [NSTimer scheduledTimerWithTimeInterval:6.0f target:self selector:@selector(checkAndReConnectDevice) userInfo:nil repeats:YES];
    [_findM35blueTimer fire];
    
    [_manager startSearchDev:5000 searchOneDeviceBlcok:^(LDC_DEVICEBASEINFO *deviceInfo){
        if (_delegate && [_delegate respondsToSelector:@selector(MPOSDelegateFoundAvailableDevice:DeviceCBUUID:)] ) {
            [_delegate MPOSDelegateFoundAvailableDevice:deviceInfo.deviceName DeviceCBUUID:deviceInfo.deviceIndentifier];
        }
    }completeBlock:^(NSMutableArray *deviceArray){
        _isSearching =NO;
    }];
}

//停止搜索
-(void)stopSearchBLE{
    [_manager stopSearchDev];
}

// 绑定查找到的设备, 只有绑定设备后，设备才可以正常连接;
- (void)bindingDevice:(NSString *)deviceName DeviceCBUUID:(NSString*)CBUUID
{
    _BindingMposDeviceCBUUID = CBUUID;
    _BindingMposDeviceName = deviceName;
    
    [self stopSearchBLE];
    _isSearching =NO;
    [_manager closeDevice];

}

- (void)closeSession
{
#ifdef DEBUG
    NSLog(@"closeSession");
#endif
    if ( _isMateConnected ) {
        [_iMateEADSessionController closeSession];
        [_iMateEADSessionController setupControllerForAccessory:nil withProtocolString:nil];
        _isMateConnected = NO;
    }
    if ( _isPrinterConnected ) {
        [_printerEADSessionController closeSession];
        [_printerEADSessionController setupControllerForAccessory:nil withProtocolString:nil];
        _isPrinterConnected = NO;
    }
    self.iMateAccessory = nil;
    self.printerAccessory = nil;
    
    //联迪
    [_manager closeDevice];
    _isMposConnected = NO;

    [_findM35blueTimer invalidate];
    _findM35blueTimer = nil;
}

- (BOOL)connectingTest
{
   return _isMateConnected;
}

- (BOOL)M35ConnectingTest
{
    return [_manager isConnectToDevice];
}

- (BOOL)printerConnectingTest
{
    return _isPrinterConnected;
}

- (BOOL)isWorking
{
    if ( requestType != kRequestNone )
        return YES;
    return NO;
}

// 读取iMate序列号
- (NSString *)deviceSerialNumber
{
    if (!_isMateConnected)
        return nil;
    return _deviceSerialNumber;
}

// 查询iMate固件版本号
// 返回：
// nil                    : iMate不支持取版本或通讯错误
// "A.A,B.B.B,termid(12)" : 硬件和固件版本，其中A为硬件版本，B为固件版本, termid(如果存在).
- (NSString *)deviceVersion
{
    return _deviceVersion;
}

// 部件检测。可检测的部件包括二代证模块，射频卡模块。（IMFC还包括指纹模块、SD模块）
// componentsMask的bit来标识检测的部件：
//      0x01 二代证模块
//      0x02 射频模块
//      0x40 IMFC 指纹模块（iMate不支持）
//      0x80 IMFC SD卡模块（iMate不支持）
//      0xFF 全部部件检测
// 检测的结果通过delegate响应
- (void)deviceTest:(Byte)componentsMask
{
    int ret= [self testConnectFunction];
    switch(ret)
    {
        case LIANDIM35:
            if ( [_manager isConnectToDevice] == NO ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                    [_delegate iMateDelegateNoResponse:@"密码键盘未连接"];
                return;
            }
            if ([_delegate respondsToSelector:@selector(iMateDelegateDeviceTest:resultMask:error:)]) {
                [_delegate iMateDelegateDeviceTest:0 resultMask:0x00 error:nil];
            }
            break;
        case IMATE:
        {
            if ( requestType != kRequestNone ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                    [_delegate iMateDelegateNoResponse:@"iMate背夹正在工作状态,无法响应请求"];
                return;
            }
            
            requestType = kRequestDeviceTest;
            
            Byte sendBytes[2];
            sendBytes[0] = 0x6C;
            sendBytes[1] = componentsMask;
            
            _imateDataObj.sendData = [NSData dataWithBytes:sendBytes length:2];
            
            NSData *sendPackData = [_imateDataObj packSendData];
            [_iMateEADSessionController writeData:sendPackData];
            [self setupTimer:DEFULT_TIMEOUT];
            break;
        }
        case M35DISCONNECT:
        {
            if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [_delegate iMateDelegateNoResponse:@"密码键盘未连接"];
            return;
        }
        case IMATEDISCONNECT:
        {
            if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [_delegate iMateDelegateNoResponse:@"iMate背夹未连接"];
            return;
        }
    }
}

// 等待事件，包括磁卡刷卡、Pboc IC插入、放置射频卡。timeout是最长等待时间(秒)
// eventMask的bit来标识检测的部件：
//      0x01    等待刷卡事件
//      0x02    等待插卡事件
//      0x04    等待射频事件
//      0xFF    等待所有事件
// 等待的结果通过delegate响应
- (void)waitEvent:(Byte)eventMask timeout:(NSInteger)timeout
{
    int ret= [self testConnectFunction];
    switch(ret)
    {
        case LIANDIM35:
        {
            if ( [_manager isConnectToDevice] == NO ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                    [_delegate iMateDelegateNoResponse:@"密码键盘未连接"];
                return;
            }
            [_manager waitingCard:@"请选择插卡、刷卡、挥卡" timeOut:(int)timeout CheckCardTp:eventMask&0x07 moneyNum:nil successBlock:^(LDE_CardType cardtype) {
                NSLog(@"cardType ==== %d",cardtype);
                switch (cardtype) {
                        
                    case 0x01:
                    //磁条卡
                    {
                        [_manager getTrackData:TRACKTYPE_PLAIN successCB:^(LDC_TrackDataInfo *trackData) {
                            NSString *TrackData = [NSString stringWithFormat:@"%@=%@",[trackData track2],[trackData track3]];
                            NSData *data = [TrackData dataUsingEncoding:NSUTF8StringEncoding];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSLog(@"===case 0x01: ====");
                                if ([_delegate respondsToSelector:@selector(iMateDelegateWaitEvent:eventId:data:error:)]) {
                                    [_delegate iMateDelegateWaitEvent:0 eventId:cardtype data:data error:nil];
                                }
                            });
                            
                        } failedBlock:^(NSString *errCode, NSString *errInfo) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if ([_delegate respondsToSelector:@selector(iMateDelegateWaitEvent:eventId:data:error:)]) {
                                    [_delegate iMateDelegateWaitEvent:[errCode intValue] eventId:cardtype data:nil error:errInfo];
                                }
                            });
                            
                        }];
                        break;
                    }
                    case 0x02:
                    {
                        [_manager powerUpICC:IC_SLOT_ICC1 successBlock:^(NSString *stringCB) {
                            NSData *ATR = [iMateAppFace twoOneData:stringCB];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if ([_delegate respondsToSelector:@selector(iMateDelegateWaitEvent:eventId:data:error:)]) {
                                    [_delegate iMateDelegateWaitEvent:0 eventId:cardtype data:ATR error:nil];
                                }
                            });
                            
                        } failedBlock:^(NSString *errCode, NSString *errInfo) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if ([_delegate respondsToSelector:@selector(iMateDelegateWaitEvent:eventId:data:error:)]) {
                                    [_delegate iMateDelegateWaitEvent:[errCode intValue] eventId:cardtype data:nil error:errInfo];
                                }
                            });
                        }];
                        break;
                    }
                    case 0x04:
                    {
                        //射频卡
                        NSLog(@"检测到射频卡");
                        [_manager powerUpICC:IC_SLOT_RF successBlock:^(NSString *stringCB) {
                            NSData *ATR = [iMateAppFace twoOneData:stringCB];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if ([_delegate respondsToSelector:@selector(iMateDelegateWaitEvent:eventId:data:error:)]) {
                                    [_delegate iMateDelegateWaitEvent:0 eventId:cardtype data:ATR error:nil];
                                }
                            });
                            
                        } failedBlock:^(NSString *errCode, NSString *errInfo) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if ([_delegate respondsToSelector:@selector(iMateDelegateWaitEvent:eventId:data:error:)]) {
                                    [_delegate iMateDelegateWaitEvent:[errCode intValue] eventId:cardtype data:nil error:errInfo];
                                }
                            });
                            
                        }];
                        break;
                    }
                }
            } failedBlock:^(NSString *errCode, NSString *errInfo) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([_delegate respondsToSelector:@selector(iMateDelegateWaitEvent:eventId:data:error:)]) {
                        [_delegate iMateDelegateWaitEvent:[errCode intValue] eventId:0x77 data:nil error:errInfo];
                    }
                });
                
            }];
            break;
        }
        case IMATE:
        {
            if ( requestType != kRequestNone ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                    [_delegate iMateDelegateNoResponse:@"iMate背夹正在工作状态,无法响应请求"];
                return;
            }
            
            requestType = kRequestWaitEvent;
            
            Byte sendBytes[3];
            sendBytes[0] = 0x6B;
            sendBytes[1] = eventMask;
            sendBytes[2] = timeout;
            
            _imateDataObj.sendData = [NSData dataWithBytes:sendBytes length:3];
            
            NSData *sendPackData = [_imateDataObj packSendData];
            [_iMateEADSessionController writeData:sendPackData];
            [self setupTimer:timeout];
            break;
        }
        case M35DISCONNECT:
        {
            if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [_delegate iMateDelegateNoResponse:@"密码键盘未连接"];
            return;
        }
        case IMATEDISCONNECT:
        {
            if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [_delegate iMateDelegateNoResponse:@"iMate背夹未连接"];
            return;
        }
    }
}

- (NSString *)queryDeviceSerialNumber
{
    Byte sendBytes[2];
    Byte receiveBytes[100+1];
    
    sendBytes[0] = 0x04;
    
    memset(receiveBytes, 0, sizeof(receiveBytes));
    int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:1 ResponseDataBuf:receiveBytes timeout:1];
    if(iRet < 0) {
        return nil;
    }
    if (iRet > 0 && receiveBytes[0]) {
        return @"";
    }
    receiveBytes[1+24] = 0; //在24后面带着MAC地址
    return [NSString stringWithUTF8String:receiveBytes+1];
}

- (NSString *)queryDeviceVersion
{
    Byte sendBytes[1];
    Byte receiveBytes[50+1];
    
    sendBytes[0] = 0x60;
    
    memset(receiveBytes, 0, sizeof(receiveBytes));
    int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:1 ResponseDataBuf:receiveBytes timeout:3];
    if(iRet < 0) {
        return nil;
    }
    if (iRet > 0 && receiveBytes[0]) {
        sendBytes[0] = 0x60;
        memset(receiveBytes, 0, sizeof(receiveBytes));
        int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:1 ResponseDataBuf:receiveBytes timeout:2];
        if(iRet < 0) {
            return nil;
        }
        if (iRet > 0 && receiveBytes[0]) {
            return nil;
        }
    }
    return [NSString stringWithUTF8String:receiveBytes+1];
}

- (void)deviceSetup:(BOOL)responseDelegate
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            /**判断是否支持远程函数调用模式*/
            vSetRemoteCallMode(0);
            gl_supportPackageSequenceNumberProtocol = NO;
            _firmwareVersion = nil;
            _hardwareVersion = nil;
            _deviceVersion = [self queryDeviceVersion];
            if (_deviceVersion == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        NSLog(@"Try reconnecting");
                        [self closeSession];
                        [self openSession];
                    }
                });
                return;
            }
            
            if (_deviceVersion && _deviceVersion.length) {
                NSArray *versionArray = [_deviceVersion componentsSeparatedByString:@","];
                if ([versionArray count] >= 2) {
                    _hardwareVersion = [versionArray objectAtIndex:0];
                    _firmwareVersion = [versionArray objectAtIndex:1];
                    
                    gl_support401Bt40AckMode = 0;
                    if (([_hardwareVersion hasPrefix:@"IMATEIV1.1"] && strcmp(_firmwareVersion.UTF8String, "7.3.0") >= 0)||[_hardwareVersion hasPrefix:@"IMATEIMATEIII3.0"] ) {
                        gl_support401Bt40AckMode = YES;
                    }
                    
                    gl_theDeviceMode = 100;
                    // 设置401的缺省密码键盘
                    if ([_hardwareVersion hasPrefix:@"IMATEIV"]) {
                        gl_theDeviceMode = 400;
                    }
                    else if ([_hardwareVersion hasPrefix:@"IMATEIII"]) {
                        gl_theDeviceMode = 300;
                    }
                    
                    if (_firmwareVersion) {
                        if (strcmp(_firmwareVersion.UTF8String, "3.0.1") >= 0) {
                            vSetRemoteCallMode(1);
                        }
                        _deviceTermId = nil;
                        gl_masterKeyFromDevice = nil;
                        if (strcmp(_firmwareVersion.UTF8String, "3.1.0") >= 0) {
                            unsigned char buffer[30];
                            if (_ucRcXMemReadReserved(buffer, 20, 13+16) == 0) {
                                _deviceTermId = [NSString stringWithFormat:@"%.12s", buffer];
                                gl_masterKeyFromDevice = [NSData dataWithBytes:buffer + 13 length:16];
                            }
                        }
                        if (strcmp(_firmwareVersion.UTF8String, "4.0.0") >= 0)
                            gl_supportPackageSequenceNumberProtocol = YES;
                        if (strcmp(_firmwareVersion.UTF8String, "7.0.0") >= 0) {
                            gl_supportPbocPushApdu = YES;
                        }
                    }
                }
            }
            _deviceSerialNumber = [self queryDeviceSerialNumber];
        }
        
        NSLog(@"_deviceSerialNumber : %@", _deviceSerialNumber);
        NSLog(@"_deviceVersion : %@",_deviceVersion);
        NSLog(@"_hardwareVersion : %@",_hardwareVersion);

        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                _isMateConnected = YES;
                if (responseDelegate && [_delegate respondsToSelector:@selector(iMateDelegateConnectStatus:)] )
                    [_delegate iMateDelegateConnectStatus:YES];
            }
        });
    });
}

// 读取iMate终端号
- (NSString *)deviceTerminalId
{
    if (self.iMateAccessory == nil)
        return nil;
    return _deviceTermId;
}

// 写iMate终端号
/*
- (void)writeDeviceTerminalId:(NSString *)terminalId;
{
    if ( _isMateConnected == NO ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate未连接"];
        return;
    }
    if ( requestType != kRequestNone ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate正在工作状态,无法响应请求"];
        
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            unsigned char sBuf[12+1];
            _ucRcXMemReadReserved(sBuf, 20, 13);
            memcpy(sBuf, terminalId.UTF8String, 12);
            sBuf[12] = 0;
            if (_ucRcXMemWriteReserved(sBuf, 20, 13)) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        if ( [_delegate respondsToSelector:@selector(iMateDelegateWriteDeviceTerminalId:error:)] )
                            [_delegate iMateDelegateWriteDeviceTerminalId:9 error:@"写iMate设备终端号失败"];
                    }
                });
                return;
            }
            _deviceTermId = [NSString stringWithFormat:@"%s", sBuf];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    if ( [_delegate respondsToSelector:@selector(iMateDelegateWriteDeviceTerminalId:error:)] )
                        [_delegate iMateDelegateWriteDeviceTerminalId:0 error:@""];                }
            });
        }
    });
}
 */

- (void)writeDeviceTerminalId:(NSString *)terminalId;
{
    if ( _isMateConnected == NO ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate背夹未连接"];
        return;
    }
    if ( requestType != kRequestNone ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate背夹正在工作状态,无法响应请求"];
        return;
    }
    
    requestType = kRequestWriteTermId;
    
    Byte sendBytes[6];
    sendBytes[0] = 0x68;
    sendBytes[1] = 0x04;
    sendBytes[2] = 0;
    sendBytes[3] = 20;
    sendBytes[4] = 0;
    sendBytes[5] = 13;
    
    Byte buff[13];
    memset(buff, 0, sizeof(buff));
    memcpy(buff, terminalId.UTF8String, terminalId.length);
    
    NSData *data = [NSData dataWithBytes:buff length:13];
    
    NSMutableData *sendData = [NSMutableData dataWithBytes:sendBytes length:6];
    [sendData appendData:data];
    
    _imateDataObj.sendData = sendData;
    NSData *sendPackData = [_imateDataObj packSendData];
    [_iMateEADSessionController writeData:sendPackData];
    [self setupTimer:DEFULT_TIMEOUT];
    
    _deviceTermId = terminalId;
}

// iMate蜂鸣响一声
- (void)buzzer
{
    if ( _isMateConnected == NO ) {
        return;
    }
    if ( requestType != kRequestNone ) {
        return;
    }
    requestType = kRequestBuzzer;
    
    _imateDataObj.sendData = [NSData dataWithBytes:"\x03" length:1];
    NSData *sendPackData = [_imateDataObj packSendData];
    [_iMateEADSessionController writeData:sendPackData];
    [self setupTimer:DEFULT_TIMEOUT];
}

- (void)swipeCard:(NSInteger)timeout
{
    
    int ret= [self testConnectFunction];
    switch(ret)
    {
        case LIANDIM35:
        {
            if ( [_manager isConnectToDevice] == NO ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                    [_delegate iMateDelegateNoResponse:@"密码键盘未连接"];
                return;
            }
            [_manager waitingCard:@"请刷卡..." timeOut:(int)timeout CheckCardTp:SUPPORTCARDTYPE_MAG moneyNum:nil successBlock:^(LDE_CardType cardtype) {
                [_manager getTrackData:TRACKTYPE_PLAIN successCB:^(LDC_TrackDataInfo *trackData) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ( [_delegate respondsToSelector:@selector(iMateDelegateSwipeCard:track2:track3:error:)] )
                            [_delegate iMateDelegateSwipeCard:0 track2:trackData.track2 track3:trackData.track3 error:nil];
                    });
                    
                } failedBlock:^(NSString *errCode, NSString *errInfo) {
                    //主线程执行
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ( [_delegate respondsToSelector:@selector(iMateDelegateSwipeCard:track2:track3:error:)] )
                            [_delegate iMateDelegateSwipeCard:1 track2:nil track3:nil error:errInfo];
                    });
                    
                }];
            } failedBlock:^(NSString *errCode, NSString *errInfo) {
                NSLog(@"%@",errInfo);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ( [_delegate respondsToSelector:@selector(iMateDelegateSwipeCard:track2:track3:error:)] )
                        [_delegate iMateDelegateSwipeCard:2 track2:nil track3:nil error:errInfo];
                });
                
            }];
            break;
        }
        case IMATE:
        {
            if ( requestType != kRequestNone ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                    [_delegate iMateDelegateNoResponse:@"iMate背夹正在工作状态,无法响应请求"];
                return;
            }
            requestType = kRequestSwipeCard;
        
            Byte sendBytes[2];
            sendBytes[0] = 0x61;
            sendBytes[1] = timeout;
        
            _imateDataObj.sendData = [NSData dataWithBytes:sendBytes length:2];
        
            NSData *sendPackData = [_imateDataObj packSendData];
            [_iMateEADSessionController writeData:sendPackData];
        
            [self setupTimer:timeout];
            break;
        }
        case M35DISCONNECT:
        {
            if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [_delegate iMateDelegateNoResponse:@"密码键盘未连接"];
            return;
        }
        case IMATEDISCONNECT:
        {
            if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [_delegate iMateDelegateNoResponse:@"iMate背夹未连接"];
            return;
        }
    }
}

- (void)icResetCard:(NSInteger)slot tag:(NSInteger)tag timeout:(NSInteger)timeout;
{
    int ret= [self testConnectFunction];
    switch(ret)
    {
        case LIANDIM35:
        {
            if ( [_manager isConnectToDevice] == NO ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                    [_delegate iMateDelegateNoResponse:@"密码键盘未连接"];
                return;
            }
            
            [_manager waitingCard:@"请插卡..." timeOut:(int)timeout CheckCardTp:SUPPORTCARDTYPE_IC_RF moneyNum:nil successBlock:^(LDE_CardType cardtype) {
                [_manager powerUpICC:LianDiSlotMap((int)slot) successBlock:^(NSString *stringCB) {
                
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ( [_delegate respondsToSelector:@selector(iMateDelegateICResetCard:resetData:tag:error:)] )
                            [_delegate iMateDelegateICResetCard:0 resetData:[iMateAppFace twoOneData:stringCB] tag:tag error:nil];
                    });
                    
                    
                } failedBlock:^(NSString *errCode, NSString *errInfo) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ( [_delegate respondsToSelector:@selector(iMateDelegateICResetCard:resetData:tag:error:)] )
                            [_delegate iMateDelegateICResetCard:1 resetData:nil tag:tag error:errInfo];
                    });
                }];
                
            } failedBlock:^(NSString *errCode, NSString *errInfo) {
                NSLog(@"%@",errInfo);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ( [_delegate respondsToSelector:@selector(iMateDelegateICResetCard:resetData:tag:error:)] )
                        [_delegate iMateDelegateICResetCard:1 resetData:nil tag:tag error:errInfo];
                });
            }];
            break;
        }
        case IMATE:
        {
            if ( requestType != kRequestNone ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                    [_delegate iMateDelegateNoResponse:@"iMate背夹正在工作状态,无法响应请求"];
                return;
            }
            requestType = kRequestICResetCard;
        
            resetCardTag = tag;
            _icResetCardSlot = (int)slot;
        
            Byte sendBytes[4];
        
            if (slot == 1) { //射频卡
                sendBytes[0] = 0x81;
                sendBytes[1] = 0x01;
                sendBytes[2] = timeout;
                _imateDataObj.sendData = [NSData dataWithBytes:sendBytes length:3];
            }
            else {
                sendBytes[0] = 0x62;
                sendBytes[1] = 0x01;
                sendBytes[2] = slot;
                sendBytes[3] = timeout;
                _imateDataObj.sendData = [NSData dataWithBytes:sendBytes length:4];
            }
        
            NSData *sendPackData = [_imateDataObj packSendData];
            [_iMateEADSessionController writeData:sendPackData];
        
            [self setupTimer:timeout];
            break;
        }
        case M35DISCONNECT:
        {
            if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [_delegate iMateDelegateNoResponse:@"密码键盘未连接"];
            return;
        }
        case IMATEDISCONNECT:
        {
            if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
                [_delegate iMateDelegateNoResponse:@"iMate背夹未连接"];
            return;
        }
    }
}



- (NSData *)icResetCardSync:(NSInteger)slot timeout:(NSInteger)timeout error:(NSString *__autoreleasing *)error;
{
    if ( _isMateConnected == NO ) {
        *error = @"iMate背夹未连接";
        return nil;
    }
    if ( requestType != kRequestNone ) {
        *error = @"iMate背夹正在工作状态,无法响应请求";
        return nil;
    }
    
    Byte sendBytes[4];
    Byte receiveBytes[300];
    
    int len;
    
    if (slot == 1) { //射频卡
        sendBytes[0] = 0x81;
        sendBytes[1] = 0x01;
        sendBytes[2] = timeout;
        len = 3;
    }
    else {
        sendBytes[0] = 0x62;
        sendBytes[1] = 0x01;
        sendBytes[2] = slot;
        sendBytes[3] = timeout;
        len  = 4;
    }
    int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:len ResponseDataBuf:receiveBytes timeout:(int)timeout+1];
    //处理数据
    if (iRet > 0 && receiveBytes[0]) {
        *error = [_syncCommon getErrorString:receiveBytes+1 length:iRet-1];
        return nil;
    }
    if(iRet == -1){
        *error = @"iMate背夹通讯超时";
        return nil;
    }
    
    if (slot == 1) { // mifcpu card
        uchar *atr = "\x3B\x8E\x80\x01\x80\x31\x80\x66\xB0\x84\x0C\x01\x6E\x01\x83\x00\x90\x00\x1D";
        vSetCardResetData(atr, 19);
        return [NSData dataWithBytes:atr length:19];
    }
    vSetCardResetData(receiveBytes+1, iRet-1);
    return [NSData dataWithBytes:receiveBytes+1 length:iRet-1];
}

- (void)icApdu:(NSInteger)slot commandApdu:(NSData *)commandApdu
{
    if ( _isMateConnected == NO ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate背夹未连接"];
        return;
    }
    if ( requestType != kRequestNone ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate背夹正在工作状态,无法响应请求"];
        return;
    }
    
    requestType = kRequestICApdu;

    Byte sendBytes[300];
    
    if (slot == 1) {
        sendBytes[0] = 0x83;
        memcpy(sendBytes+1,[commandApdu bytes],[commandApdu length]);
        _imateDataObj.sendData = [NSData dataWithBytes:sendBytes length:1+[commandApdu length]];
    }
    else {
        memcpy(sendBytes,"\x62\x02",2);
        sendBytes[2] = slot;
        sendBytes[3] = 0; //normal icc type = 0
        memcpy(sendBytes+4,[commandApdu bytes],[commandApdu length]);
        _imateDataObj.sendData = [NSData dataWithBytes:sendBytes length:4+[commandApdu length]];
    }
    NSData *sendPackData = [_imateDataObj packSendData];
    [_iMateEADSessionController writeData:sendPackData];
    
    [self setupTimer:DEFULT_TIMEOUT];
}

- (NSData *)icApduSync:(NSInteger)slot commandApdu:(NSData *)commandApdu error:(NSString *__autoreleasing *)error
{
    if ( _isMateConnected == NO ) {
        *error = @"iMate背夹未连接";
        return nil;
    }
    if ( requestType != kRequestNone ) {
        *error = @"iMate背夹正在工作状态,无法响应请求";
        return nil;
    }
    
    Byte sendBytes[300];
    Byte receiveBytes[300];
    int len;
    
    if (slot == 1) {
        sendBytes[0] = 0x83;
        memcpy(sendBytes+1,[commandApdu bytes],[commandApdu length]);
        len = (int)[commandApdu length] + 1;
    }
    else {
        memcpy(sendBytes,"\x62\x02",2);
        sendBytes[2] = slot;
        sendBytes[3] = 0; //normal icc type = 0
        memcpy(sendBytes+4,[commandApdu bytes],[commandApdu length]);
        len = (int)[commandApdu length] + 4;

    }
    int iRet = [_syncCommon bluetoothSendRecv:sendBytes dataLen:len ResponseDataBuf:receiveBytes timeout:DEFULT_TIMEOUT];
    //处理数据
    if (iRet > 0 && receiveBytes[0]) {
        *error = [_syncCommon getErrorString:receiveBytes+1 length:iRet-1];
        return nil;
    }
    
    if(iRet == -1){
        *error = @"iMate背夹通讯超时";
        return nil;
    }
    return [NSData dataWithBytes:receiveBytes+1 length:iRet-1];
}

- (void)idReadMessage:(NSInteger)timeout
{
    if ( _isMateConnected == NO ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate背夹未连接"];
        return;
    }
    if ( requestType != kRequestNone ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate背夹正在工作状态,无法响应请求"];
        return;
    }
    
    requestType = kRequestIDReadMessage;
    
    if ( timeout < 2 )
        timeout = 2;
    
    Byte sendBytes[3];
    sendBytes[0] = 0x63;
    sendBytes[1] = 0x02;
    sendBytes[2] = timeout;
    
    _imateDataObj.sendData = [NSData dataWithBytes:sendBytes length:3];
    NSData *sendPackData = [_imateDataObj packSendData];
    [_iMateEADSessionController writeData:sendPackData];
    
    [self setupTimer:timeout];
}

- (void)batteryLevel
{
    if ( _isMateConnected == NO ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate背夹未连接"];
        return;
    }
    if ( requestType != kRequestNone ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate背夹正在工作状态,无法响应请求"];
        return;
    }
    
    requestType = kRequestBatteryLevel;
    
    _imateDataObj.sendData = [NSData dataWithBytes:"\x65" length:1];
    NSData *sendPackData = [_imateDataObj packSendData];
    [_iMateEADSessionController writeData:sendPackData];
    [self setupTimer:DEFULT_TIMEOUT];
}

- (void)xmemRead:(NSInteger)offset length:(NSInteger)length
{
    if ( _isMateConnected == NO ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate背夹未连接"];
        return;
    }
    if ( requestType != kRequestNone ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate背夹正在工作状态,无法响应请求"];
        return;
    }
    
    requestType = kRequestXmemRead;
    
    Byte sendBytes[6];
    sendBytes[0] = 0x68;
    sendBytes[1] = 0x01;
    sendBytes[2] = offset/256;
    sendBytes[3] = offset%256;
    sendBytes[4] = length/256;
    sendBytes[5] = length%256;
    
    _imateDataObj.sendData = [NSData dataWithBytes:sendBytes length:6];
    NSData *sendPackData = [_imateDataObj packSendData];
    [_iMateEADSessionController writeData:sendPackData];
    [self setupTimer:DEFULT_TIMEOUT];
}

- (void)xmemWrite:(NSInteger)offset data:(NSData*)data
{
    if ( _isMateConnected == NO ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate背夹未连接"];
        return;
    }
    if ( requestType != kRequestNone ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate背夹正在工作状态,无法响应请求"];
        return;
    }
    
    requestType = kRequestXmemWrite;

    Byte sendBytes[6];
    sendBytes[0] = 0x68;
    sendBytes[1] = 0x02;
    sendBytes[2] = offset/256;
    sendBytes[3] = offset%256;
    sendBytes[4] = [data length]/256;
    sendBytes[5] = [data length]%256;
    
    NSMutableData *sendData = [NSMutableData dataWithBytes:sendBytes length:6];
    [sendData appendData:data];
    
    _imateDataObj.sendData = sendData;
    NSData *sendPackData = [_imateDataObj packSendData];
    [_iMateEADSessionController writeData:sendPackData];
    [self setupTimer:DEFULT_TIMEOUT];
}

- (void)cancel
{
    int ret= [self testConnectFunction];
    switch(ret)
    {
        case LIANDIM35:
        {
            [_manager cancelCMD:^{
                
            } failedBlock:^(NSString *errCode, NSString *errInfo) {
                NSLog(@"%@",errInfo);
            }];
        }
        case IMATE:
        {
            if (requestType == kRequestNone)
                return;
            
            NSData *cancelCommand = [NSData dataWithBytes:"\x18" length:1];
            [_iMateEADSessionController writeData:cancelCommand];
            break;
        }
        case M35DISCONNECT:
        case IMATEDISCONNECT:
        default:
            break;
    }
}

#pragma mark local

- (void)setupTimer:(NSInteger)timeout
{
    if ([_timer isValid])
        [_timer invalidate];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:timeout+0.5
                                                  target:self
                                                selector:@selector(receiveTimeout:)
                                                userInfo:@"imate"
                                            repeats:NO];
}

- (void)setupPrinterStatusTimer
{
    if ([_timer isValid])
        [_timer invalidate];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(receiveTimeout:)
                                                userInfo:@"printer"
                                                 repeats:NO];
}

- (void)receiveTimeout:(NSTimer *)timer
{
    if ([timer.userInfo isEqualToString:@"printer"]) {
        if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
            [_delegate printerDelegateStatusResponse:PRINTER_OFFLINE];
        return;
    }
    
    if ( requestType == kRequestNone )
        return;
    
    if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
        [_delegate iMateDelegateNoResponse:@"iMate背夹通讯超时"];
    
    requestType = kRequestNone;
}

#pragma mark Internal

- (void)accessoryDidConnect:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"accessoryDidConnect");
#endif
    EAAccessory *connectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    
    if ( ![[connectedAccessory protocolStrings] count] ) {
        return;
    }
#ifdef DEBUG
    NSLog(@"%@",[connectedAccessory protocolStrings]);
#endif
    if ([[connectedAccessory protocolStrings] containsObject:PROTOCOL_STRING_IMATE]) {
        if ( _isMateConnected == YES )
            return;

        [_iMateEADSessionController setupControllerForAccessory:connectedAccessory
                                             withProtocolString:PROTOCOL_STRING_IMATE];
        self.iMateAccessory = [_iMateEADSessionController accessory];
        
        [_iMateEADSessionController openSession];
        
        if ( requestType != kRequestNone ) {
            [self cancel];
            requestType = kRequestNone;
        }
        [self deviceSetup:YES];

        //if ( [_delegate respondsToSelector:@selector(iMateDelegateConnectStatus:)] )
          //  [_delegate iMateDelegateConnectStatus:YES];
    }
    if ([[connectedAccessory protocolStrings] containsObject:PROTOCOL_STRING_IMFC]) {
        if ( _isMateConnected == YES )
            return;
        
        [_iMateEADSessionController setupControllerForAccessory:connectedAccessory
                                             withProtocolString:PROTOCOL_STRING_IMFC];
        self.iMateAccessory = [_iMateEADSessionController accessory];
        
        [_iMateEADSessionController openSession];
        _isMateConnected = YES;
        
        if ( requestType != kRequestNone ) {
            [self cancel];
            requestType = kRequestNone;
        }
        if ( [_delegate respondsToSelector:@selector(iMateDelegateConnectStatus:)] )
            [_delegate iMateDelegateConnectStatus:YES];
    }
    if ([[connectedAccessory protocolStrings] containsObject:PROTOCOL_STRING_PRINTER]) {
        if ( _isPrinterConnected == YES )
            return;
        [_printerEADSessionController setupControllerForAccessory:connectedAccessory
                                             withProtocolString:PROTOCOL_STRING_PRINTER];
        self.printerAccessory = [_printerEADSessionController accessory];
        [_printerEADSessionController openSession];
        _isPrinterConnected = YES;
        if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
            [_delegate printerDelegateStatusResponse:PRINTER_CONNECTED];
    }
}

- (void)accessoryDidDisconnect:(NSNotification *)notification
{

    NSLog(@"accessoryDidDisconnect");

    EAAccessory *disconnectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    
    if ([disconnectedAccessory connectionID] == [_iMateAccessory connectionID])
    {
        if ( [disconnectedAccessory.protocolStrings containsObject:PROTOCOL_STRING_IMATE] ||
            [disconnectedAccessory.protocolStrings containsObject:PROTOCOL_STRING_IMFC] ) {
            [_iMateEADSessionController closeSession];
        
            if ( [_delegate respondsToSelector:@selector(iMateDelegateConnectStatus:)] )
                [_delegate iMateDelegateConnectStatus:NO];
            _isMateConnected = NO;
            self.iMateAccessory = nil;
            _deviceTermId = nil;
            gl_masterKeyFromDevice = nil;
            
            [_manager closeDevice];//关闭联迪设备
        }
    }
    if ([disconnectedAccessory connectionID] == [_printerAccessory connectionID])
    {
        if ( [disconnectedAccessory.protocolStrings containsObject:PROTOCOL_STRING_PRINTER] ) {
            [_printerEADSessionController closeSession];
            
            if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                [_delegate printerDelegateStatusResponse:PRINTER_NOT_CONNECTED];
            _isPrinterConnected = NO;
            self.printerAccessory = nil;
        }
    }
}

- (void)sessionDataReceived:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"sessionDataReceived");
#endif
    EADSessionController *sessionController = (EADSessionController *)[notification object];
    
    unsigned long bytesAvailable = 0;

    if ( [sessionController.protocolString isEqualToString:PROTOCOL_STRING_IMATE] ||
        [sessionController.protocolString isEqualToString:PROTOCOL_STRING_IMFC] ) {
#ifdef DEBUG
        NSLog(@"PROTOCOL_STRING_IMATE & PROTOCOL_STRING_IMFC");
#endif
        while ((bytesAvailable = [sessionController readBytesAvailable]) > 0) {
            NSData *data = [sessionController readData:bytesAvailable];
            if (data && _imateDataObj.receivedDataStatus == MATEReceivedDataIsInvalid ) {
                [_imateDataObj appendReceiveData:data];
            }
        }
        if ( _imateDataObj.receivedDataStatus != MATEReceivedDataIsInvalid ) {
#ifdef DEBUG
            NSLog(@"MATEReceivedDataIsInvalid");
#endif
            return;
        }

        MateReceivedDataStatus status = [_imateDataObj unpackReceivedData];
#ifdef DEBUG
        NSLog(@"MateReceivedDataStatus = %d", status);
#endif
        if ( status != MATEReceivedDataIsInvalid ) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"ReceivedDataCompletedNotification" object:nil];
        }
    }
    else {
#ifdef DEBUG
        NSLog(@"PROTOCOL_STRING_PRINTER");
#endif
        NSMutableData *responseData = [[NSMutableData alloc] init];
        while ((bytesAvailable = [sessionController readBytesAvailable]) > 0) {
            NSData *data = [sessionController readData:bytesAvailable];
            if (data) {
                [responseData appendData:data];
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReceivedDataCompletedNotification" object:responseData];
    }
}

- (void)receivedDataCompleted:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"receivedDataCompleted");
#endif
    
    // printer response
    if ( [notification object] ) {
        if ([_timer isValid])
            [_timer invalidate];
        
        NSData *responseData = (NSData*)[notification object];
#ifdef DEBUG
        NSLog(@"response = %@",responseData);
#endif
        if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] ) {
            if (((Byte*)responseData.bytes)[0] != 0x12 )
                [_delegate printerDelegateStatusResponse:PRINTER_OUT_OF_PAPER];
            else
                [_delegate printerDelegateStatusResponse:PRINTER_OK];
        }
        return;
    }
    
    if (gl_supportPackageSequenceNumberProtocol && gl_thePackageSequenceNumber != _imateDataObj.receivedSequenceNumber) {
        NSLog(@"gl_thePackageSequenceNumber = %d, receivedSequenceNumber = %d", gl_thePackageSequenceNumber, _imateDataObj.receivedSequenceNumber);
        return;
    }
    
    if ([_timer isValid])
        [_timer invalidate];
    
    if ( requestType == kRequestNone ) {
#ifdef DEBUG
        NSLog(@"requestType == kRequestNone");
#endif
        return;
    }
    
    if (requestType == kRequestBuzzer) {
        requestType = kRequestNone;
        return;
    }
    
    if ([_imateDataObj receivedDataStatus] == MATEReceivedDataIsFault ) {
        requestType = kRequestNone;
        if ( [_delegate respondsToSelector:@selector(iMateDelegateResponsePackError)] )
            [_delegate iMateDelegateResponsePackError];
#ifdef DEBUG
        NSLog(@"[_imateDataObj receivedDataStatus] == MATEReceivedDataIsFault");
#endif
        return;
    }
    
    NSInteger retCode = [_imateDataObj getReturnCode];
    
    if(requestType == kRequestSync){
        // 同步通讯，将接收到的数据存放在SyncCommon的缓冲里面
        [_syncCommon putData:(int)retCode data:(unsigned char *)_imateDataObj.receivedData.bytes dataLen:(int)_imateDataObj.receivedData.length];
#ifdef DEBUG
        NSLog(@"requestType == kRequestSync");
#endif
        return;
    }
    
    NSString *utf8Error = nil;
    if ( retCode ) {
        utf8Error = [_imateDataObj getErrorString];
    }
    
    
    int type = requestType;
    requestType = kRequestNone;
    
    Byte track2[37+1],track3[104+1];
    unsigned int level;
    switch ( type) {
        case kRequestSwipeCard:
            if ( retCode || [_imateDataObj.receivedData length] != 37+104 ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateSwipeCard:track2:track3:error:)] )
                    [_delegate iMateDelegateSwipeCard:retCode track2:nil track3:nil error:utf8Error];
                break;
            }
            memset(track2, 0 ,sizeof(track2));
            memset(track3, 0 ,sizeof(track3));
            [_imateDataObj.receivedData getBytes:track2 range:(NSRange){0,37}];
            [_imateDataObj.receivedData getBytes:track3 range:(NSRange){37,104}];
            if ( [_delegate respondsToSelector:@selector(iMateDelegateSwipeCard:track2:track3:error:)] )
                [_delegate iMateDelegateSwipeCard:retCode track2:[NSString stringWithUTF8String:(char*)track2] track3:[NSString stringWithUTF8String:(char*)track3] error:nil];
            break;
        case kRequestICResetCard:
            if ( retCode ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateICResetCard:resetData:tag:error:)] )
                    [_delegate iMateDelegateICResetCard:retCode resetData:nil tag:resetCardTag error:utf8Error];
                break;
            }
            if ( [_delegate respondsToSelector:@selector(iMateDelegateICResetCard:resetData:tag:error:)] ) {
                if (_icResetCardSlot == 1) //判断是否mifcpu card
                    _imateDataObj.receivedData = [NSData dataWithBytes:"\x3B\x8E\x80\x01\x80\x31\x80\x66\xB0\x84\x0C\x01\x6E\x01\x83\x00\x90\x00\x1D" length:19];
                vSetCardResetData((uchar*)[_imateDataObj.receivedData bytes], (uint)[_imateDataObj.receivedData length]);
                
                [_delegate iMateDelegateICResetCard:retCode resetData:_imateDataObj.receivedData tag:resetCardTag error:nil];
            }
            break;
        case kRequestICApdu:
            if ( retCode ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateICApdu:responseApdu:error:)] )
                    [_delegate iMateDelegateICApdu:retCode responseApdu:nil error:utf8Error];
                break;
            }
            if ( [_delegate respondsToSelector:@selector(iMateDelegateICApdu:responseApdu:error:)] )
                [_delegate iMateDelegateICApdu:retCode responseApdu:_imateDataObj.receivedData error:nil];
            break;
        case kRequestIDReadMessage:
            if ( retCode ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateIDReadMessage:information:photo:error:)] )
                    [_delegate iMateDelegateIDReadMessage:retCode information:nil photo:nil error:utf8Error];
                break;
            }
            if ( [_delegate respondsToSelector:@selector(iMateDelegateIDReadMessage:information:photo:error:)] )
                [_delegate iMateDelegateIDReadMessage:retCode information:[_imateDataObj.receivedData subdataWithRange:(NSRange){0,256}] photo:[_imateDataObj.receivedData subdataWithRange:(NSRange){256,1024}] error:nil];
            break;
        case kRequestBatteryLevel:
            if ( retCode ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateBatteryLevel:level:error:)] )
                    [_delegate iMateDelegateBatteryLevel:retCode level:0 error:utf8Error];
                break;
            }
            level = (unsigned int)((Byte*)[_imateDataObj.receivedData bytes])[0];
            if ( [_delegate respondsToSelector:@selector(iMateDelegateBatteryLevel:level:error:)] )
                [_delegate iMateDelegateBatteryLevel:retCode level:level error:nil];
            break;
            
    
        case kRequestXmemRead:
            if ( retCode ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateXmemRead:data:error:)] )
                    [_delegate iMateDelegateXmemRead:retCode data:nil error:utf8Error];
                break;
            }
            if ( [_delegate respondsToSelector:@selector(iMateDelegateXmemRead:data:error:)] )
                [_delegate iMateDelegateXmemRead:retCode data:_imateDataObj.receivedData error:nil];
            break;
        case kRequestXmemWrite:
            if ( retCode ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateXmemWrite:error:)] )
                    [_delegate iMateDelegateXmemWrite:retCode error:utf8Error];
                break;
            }
            if ( [_delegate respondsToSelector:@selector(iMateDelegateXmemWrite:error:)] )
                [_delegate iMateDelegateXmemWrite:retCode error:utf8Error];
            break;
        case kRequestWriteTermId:
            if ( retCode ) {
                if ( [_delegate respondsToSelector:@selector(iMateDelegateWriteDeviceTerminalId:error:)] )
                    [_delegate iMateDelegateWriteDeviceTerminalId:retCode error:utf8Error];
                break;
            }
            if ( [_delegate respondsToSelector:@selector(iMateDelegateWriteDeviceTerminalId:error:)] )
                [_delegate iMateDelegateWriteDeviceTerminalId:retCode error:utf8Error];
            
            break;
        case kRequestDeviceVersion:
            if (retCode == 0) {
                _deviceVersion = [NSString stringWithFormat:@"%s",_imateDataObj.receivedData.bytes];
            }
        case kRequestDeviceTest:
            if ([_delegate respondsToSelector:@selector(iMateDelegateDeviceTest:resultMask:error:)]) {
                if ( retCode ) {
                    [_delegate iMateDelegateDeviceTest:retCode resultMask:0 error:utf8Error];
                    break;
                }
                [_delegate iMateDelegateDeviceTest:retCode resultMask:((Byte *)_imateDataObj.receivedData.bytes)[0] error:nil];
            }
            break;
        case kRequestWaitEvent:
            if ( [_delegate respondsToSelector:@selector(iMateDelegateWaitEvent:eventId:data:error:)] ) {
                if ( retCode ) {
                    [_delegate iMateDelegateWaitEvent:retCode eventId:0 data:nil error:utf8Error];
                    break;
                }
                [_delegate iMateDelegateWaitEvent:retCode eventId:((Byte *)_imateDataObj.receivedData.bytes)[0] data:[NSData dataWithBytes:_imateDataObj.receivedData.bytes + 1 length:[_imateDataObj.receivedData length] - 1] error:nil];
            }
            break;
        default:
            break;
    }
}

#pragma mark class method

+ (NSString *)oneTwoData:(NSData *)sourceData
{
    Byte *inBytes = (Byte *)[sourceData bytes];
    NSMutableString *resultData = [[NSMutableString alloc] init];
    
    for(NSInteger counter = 0; counter < [sourceData length]; counter++)
        [resultData appendFormat:@"%02X",inBytes[counter]];
    
    return resultData;
}

+ (NSData *)twoOneData:(NSString *)sourceString
{
    Byte tmp, result;
    Byte *sourceBytes = (Byte *)[sourceString UTF8String];
    
    NSMutableData *resultData = [[NSMutableData alloc] init];
    
    for(NSInteger i=0; i<strlen((char*)sourceBytes); i+=2) {
        tmp = sourceBytes[i];
        if(tmp > '9')
            tmp = toupper(tmp) - 'A' + 0x0a;
        else
            tmp &= 0x0f;
        
        result = tmp <<= 4;
        
        tmp = sourceBytes[i+1];
        if(tmp > '9')
            tmp = toupper(tmp) - 'A' + 0x0a;
        else
            tmp &= 0x0f;
        result += tmp;
        [resultData appendBytes:&result length:1];
    }
    
    return resultData;
}


/**
 * 计算两组byte数组异或后的值。两组的大小要一致。
 * @param bytesData1 NSData1
 * @param bytesData2 NSData2
 * @return    异或后的NSData
 */
+(NSData *)BytesData:(NSData *)bytesData1 XOR:(NSData *)bytesData2
{
    Byte *bytes1 = (Byte *)[bytesData1 bytes];
    Byte *bytes2 = (Byte *)[bytesData2 bytes];
    int len1 = (int)[bytesData1 length];
    int len2 = (int)[bytesData2 length];
    if (len1 != len2) {
        NSLog(@"不能进行模二加！");
        return nil;
    }
    
    Byte ByteXOR[len1];
    Byte temp1;
    Byte temp2;
    Byte temp3;
    for (int i = 0; i < len1; i++) {
        temp1 = bytes1[i];
        temp2 = bytes2[i];
        temp3 = (temp1 ^ temp2);
        ByteXOR[i] = temp3;
    }
    return [NSData dataWithBytes:ByteXOR length:len1];
}


//计算一个NSData逐个字节异或后的值
+(Byte) XOR:(NSData *)sourceData
{
    Byte *inData = (Byte *)[sourceData bytes];
    int len = (int)[sourceData length];
    Byte outData = 0x00;
    for (int i = 0; i < len; i++) {
        outData = (outData^inData[i]);
    }
    return outData;
}

//将两个字节3X 3X 转换--》XX（一个字节）（例如0x31 0x3b ----》 0x1b ）
+(NSData *)twoOneWith3xData:(NSData *)_3xData
{
    int len = (int)[_3xData length];
    Byte *inData = (Byte*)[_3xData bytes];
    if(len%2!=0)
        return nil;
    Byte outData[len/2];
    for (int i = 0,j = 0; i < len; j++,i+=2) {
        outData[j] = (Byte)(((inData[i]&0x0000000f)<<4) |(inData[i+1]&0x0000000f));
    }
    return [NSData dataWithBytes:outData length:len/2];
}

//将XX（一个字节） 转换--》3x 3x （例如 0x1b ----》 0x31 0x3b 并显示成字符"1;"）
+(NSString *)oneTwo3xString:(NSData *)sourceData
{
    int len = (int)[sourceData length];
    Byte *inData = (Byte*)[sourceData bytes];
    Byte outData[len*2+1];
    for (int i =0,j=0; i<len; i++,j+=2) {
        outData[j] = (Byte)(((inData[i]&0x000000f0)>>4)+0x30);
        outData[j+1] = (Byte)((inData[i]&0x0000000f)+0x30);
    }
    outData[len*2]=0;
    return [NSString stringWithCString:outData encoding:NSUTF8StringEncoding];;
}


//将XX（一个字节） 转换--》3x 3x （例如 0x1b ----》 0x31 0x3b ）
+(NSData *)oneTwo3xData:(NSData *)sourceData
{
    int len = (int)[sourceData length];
    Byte *inData = (Byte*)[sourceData bytes];
    Byte outData[len*2];
    for (int i =0,j=0; i<len; i++,j+=2) {
        outData[j] = (Byte)(((inData[i]&0x000000f0)>>4)+0x30);
        outData[j+1] = (Byte)((inData[i]&0x0000000f)+0x30);
    }
    return [NSData dataWithBytes:outData length:len*2];
}


//指纹仪图片数据 --》 bmp 图片数据
+ (NSData *)Raw2Bmp:(NSData *)pRawData X:(int)x Y:(int)y
{
    int num;
    int i, j;
    
    int length = (int)[pRawData length];
    Byte *pRaw =[pRawData bytes];
    
    Byte head[1078];
    Byte pBmp[1078+length];
    
    Byte temp[54] = { 0x42, 0x4d, // file header
        0x0, 0x00, 0x0, 0x00, // file size***
        0x00, 0x00, // reserved
        0x00, 0x00,// reserved
        0x36, 0x4, 0x00, 0x00,// head byte***
        0x28, 0x00, 0x00, 0x00,// struct size
        0x00, 0x00, 0x00, 0x00,// map width***
        0x00, 0x00, 0x00, 0x00,// map height***
        0x01, 0x00,// must be 1
        0x08, 0x00,// color count***  颜色位1，2，4，8，16，24
        0x00, 0x00, 0x00, 0x00, // compression
        0x00, 0x00, 0x00, 0x00,// data size***
        0x00, 0x00, 0x00, 0x00, // dpix
        0x00, 0x00, 0x00, 0x00, // dpiy
        0x00, 0x00, 0x00, 0x00,// color used
        0x00, 0x00, 0x00, 0x00,// color important
    };
    
    memcpy(head, temp, 54);
    // 确定图象宽度数值
    num = x;
    head[18] = (Byte) (num & 0xFF);
    num = num >> 8;
    head[19] = (Byte) (num & 0xFF);
    num = num >> 8;
    head[20] = (Byte) (num & 0xFF);
    num = num >> 8;
    head[21] = (Byte) (num & 0xFF);
    // 确定图象高度数值
    num = y;
    head[22] = (Byte) (num & 0xFF);
    num = num >> 8;
    head[23] = (Byte) (num & 0xFF);
    num = num >> 8;
    head[24] = (Byte) (num & 0xFF);
    num = num >> 8;
    head[25] = (Byte) (num & 0xFF);
    // 确定调色板数值
    j = 0;
    for (i = 54; i < 1078; i = i + 4) {
        head[i] = head[i + 1] = head[i + 2] = (Byte) j;
        head[i + 3] = 0;
        j++;
    }
    // 写入文件头
    memcpy(pBmp, head, 1078);
    // 写入图象数据
    for (i = 0; i < y; i++) {
        memcpy(pBmp + 1078 + (y - 1 - i) * x , pRaw + i * x , x);
    }
    return [NSData dataWithBytes:pBmp length:1078+length];
}


+(NSString *)whiteEndSpace:(NSString*)inStr
{
    int i = (int)inStr.length - 1;
    for(; i >= 0 ; i--){
        NSString *str = [inStr substringWithRange:NSMakeRange(i, 1)];
        if([str isEqualToString:@" "]){
            continue;
        }else{
            i = i + 1;
            break;
        }
    }
    NSString *str = [inStr substringWithRange:NSMakeRange(0, i)];
    if ( !str )
        return @" ";
    return str;
}

+ (iMateAppFace *)sharedController
{
    if (sg_iMateAppFace == nil) {
        sg_iMateAppFace = [[iMateAppFace alloc] initWithDelegate:nil];
    }
    return sg_iMateAppFace;
}

+ (UIImage *)processIdCardPhoto:(NSData *)photoData
{
    NSString *inFileName = [NSHomeDirectory() stringByAppendingString:@"/tmp/id.wlt"];
    NSString *outFileName = [NSHomeDirectory() stringByAppendingString:@"/tmp/id.bmp"];
    [[NSFileManager defaultManager] removeItemAtPath:inFileName error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:outFileName error:nil];
    
    if (![photoData writeToFile: inFileName atomically: NO])
        return nil;
    
    int ret = Unpack(inFileName.UTF8String, outFileName.UTF8String);
    if(ret != 1) {
        [[NSFileManager defaultManager] removeItemAtPath:inFileName error:nil];
        return nil;
    }
    
    UIImage *photoImage = [UIImage imageWithContentsOfFile:outFileName];
    
    [[NSFileManager defaultManager] removeItemAtPath:inFileName error:nil];

    return photoImage;
}

+ (NSArray *)processIdCardInfo:(NSData *)information
{
    NSMutableArray *infoArray = [[NSMutableArray alloc] init];
    size_t segmentArray[9] = {15,1,2,8,35,18,15,16,18};
    NSDictionary *nationDic = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"汉族", @"01",
                               @"蒙古族", @"02",
                               @"回族", @"03",
                               @"藏族", @"04",
                               @"维吾尔族", @"05",
                               @"苗族", @"06",
                               @"彝族", @"07",
                               @"壮族", @"08",
                               @"布依族", @"09",
                               @"朝鲜族", @"10",
                               @"满族",  @"11",
                               @"侗族", @"12",
                               @"瑶族", @"13",
                               @"白族", @"14",
                               @"土家族", @"15",
                               @"哈尼族", @"16",
                               @"哈萨克族", @"17",
                               @"傣族", @"18",
                               @"黎族", @"19",
                               @"傈僳族", @"20",
                               @"佤族", @"21",
                               @"畲族", @"22",
                               @"高山族", @"23",
                               @"拉祜族", @"24",
                               @"水族", @"25",
                               @"东乡族", @"26",
                               @"纳西族", @"27",
                               @"景颇族", @"28",
                               @"柯尔克孜族", @"29",
                               @"土族", @"30",
                               @"达斡尔族", @"31",
                               @"仫佬族", @"32",
                               @"羌族", @"33",
                               @"布朗族", @"34",
                               @"撒拉族", @"35",
                               @"毛难族", @"36",
                               @"仡佬族", @"37",
                               @"锡伯族", @"38",
                               @"阿昌族", @"39",
                               @"普米族", @"40",
                               @"塔吉克族", @"41",
                               @"怒族", @"42",
                               @"乌孜别克族", @"43",
                               @"俄罗斯族", @"44",
                               @"鄂温克族", @"45",
                               @"崩龙族", @"46",
                               @"保安族", @"47",
                               @"裕固族", @"48",
                               @"京族", @"49",
                               @"塔塔尔族", @"50",
                               @"独龙族", @"51",
                               @"鄂伦春族", @"52",
                               @"赫哲族", @"53",
                               @"门巴族", @"54",
                               @"珞巴族", @"55",
                               @"基诺族", @"56", nil];
    unichar unibuff[128];
    memcpy((char*)unibuff,information.bytes,256);
    NSString *idDataString=[NSString stringWithCharacters:unibuff length:128];
    
    NSString *subString;
    NSRange  currRange;
    
    currRange.location = 0;
    currRange.length = segmentArray[0];
    subString = [idDataString substringWithRange:currRange];
    subString = [iMateAppFace whiteEndSpace:subString];
    [infoArray addObject:subString];

    currRange.location += segmentArray[0];
    currRange.length = segmentArray[1];
    NSString *key = [idDataString substringWithRange:currRange];
    if([key isEqualToString:@"1"]) {
        subString = [NSString stringWithUTF8String:"男"];
    }else {
        subString = [NSString stringWithUTF8String:"女"];
    }
    [infoArray addObject:subString];
    
    currRange.location += segmentArray[1];
    currRange.length = segmentArray[2];
    key = [idDataString substringWithRange:currRange];
    subString = [nationDic objectForKey:key];
    if (subString == NULL) {
        subString = @"其他";
    }
    [infoArray addObject:subString];
    
    currRange.location += segmentArray[2];
    currRange.length = segmentArray[3];
    subString = [idDataString substringWithRange:currRange];
    
    [infoArray addObject:[subString substringWithRange:NSMakeRange(0, 4)]];
    [infoArray addObject:[subString substringWithRange:NSMakeRange(4, 2)]];
    [infoArray addObject:[subString substringWithRange:NSMakeRange(6, 2)]];
    
    currRange.location += segmentArray[3];;
    currRange.length = segmentArray[4];
    subString = [idDataString substringWithRange:currRange];
    subString = [iMateAppFace whiteEndSpace:subString];
    [infoArray addObject:subString];

    currRange.location += segmentArray[4];;
    currRange.length = segmentArray[5];
    subString = [idDataString substringWithRange:currRange];
    [infoArray addObject:subString];

    currRange.location += segmentArray[5];;
    currRange.length = segmentArray[6];
    subString = [idDataString substringWithRange:currRange];
    [infoArray addObject:subString];
    
    currRange.location += segmentArray[6];
    currRange.length = segmentArray[7];
    subString = [idDataString substringWithRange:currRange];
    NSString *str = [NSString stringWithFormat:@"%@.%@.%@-%@.%@.%@",[subString substringWithRange:NSMakeRange(0,4)],[subString substringWithRange:NSMakeRange(4,2)],[subString substringWithRange:NSMakeRange(6,2)],[subString substringWithRange:NSMakeRange(8,4)],[subString substringWithRange:NSMakeRange(12,2)],[subString substringWithRange:NSMakeRange(14,2)] ];
    
    [infoArray addObject:str];
    
    currRange.location += segmentArray[7];
    currRange.length = segmentArray[8];
    subString = [idDataString substringWithRange:currRange];

    [infoArray addObject:subString];
    
    return infoArray;
}

#pragma mark printer
#pragma mark printer
- (void)printerStatus
{
    
    if ( [_manager isConnectToDevice] == NO ) {
        if ( !_isPrinterConnected ) {
            if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                [_delegate printerDelegateStatusResponse:PRINTER_NOT_CONNECTED];
            return;
        }
        // 查询纸传感器
        NSData *data = [NSData dataWithBytes:"\x10\x04\x04" length:3];
        [_printerEADSessionController writeData:data];
        [self setupPrinterStatusTimer];
    }else{
        if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
            [_delegate printerDelegateStatusResponse:PRINTER_CONNECTED];
        if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
            [_delegate printerDelegateStatusResponse:PRINTER_OK];
    }
}


/**
 *  @brief    打印普通文本
 *  @param    printString   打印的文本信息
 */
- (void)print:(NSString *)printString
{
    if ( [_manager isConnectToDevice] == NO ) {
        if ( _isPrinterConnected == NO ) {
            if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                [_delegate printerDelegateStatusResponse:PRINTER_NOT_CONNECTED];
            return;
        }
        NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        [_printerEADSessionController writeData:[printString dataUsingEncoding:gbkEncoding]];
        
    }else{
        
        NSMutableArray *printContent = [[NSMutableArray alloc]init];
        LDC_PrintLineStu *oneLine = [[LDC_PrintLineStu alloc]init];
        oneLine.type = PRINTTYPE_TEXT;
        oneLine.ailg = PRINTALIGN_LEFT;
        oneLine.zoom = PRINTZOOM_NORMAL;
        oneLine.position = PRINTPOSITION_ALL;//所有联都打印此行的内容
        oneLine.text = printString;
        [printContent addObject:oneLine];
        
        [_manager printText:1 withPrintContent:printContent successBlock:^{
            if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                ;
        } failedBlock:^(NSString *errCode, NSString *errInfo) {
            NSLog(@"errCode: %@, errInfo:%@",errCode,errInfo);
            dispatch_sync(dispatch_get_main_queue(), ^{
                if ([errCode isEqualToString:@"8e30"]) {
                    if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                        [_delegate printerDelegateStatusResponse:PRINTER_OFFLINE];
                }else if ([errCode isEqualToString:@"8e31"]) {
                    if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                        [_delegate printerDelegateStatusResponse:PRINTER_OUT_OF_PAPER];
                }else if ([errCode isEqualToString:@"8e03"]) {
                    if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                        [_delegate printerDelegateStatusResponse:PRINTER_NOT_SUPPORT];
                };
            });
        }];
    }
}


/**
 *  @brief    打印普通文本
 *  @param    printString   打印的文本信息
 *  @param    mode          打印机类型
 */
- (void)print:(NSString *)printString mode:(int)mode
{
    if (mode == IMATE_T7_PRINTER) {
        if ( _isPrinterConnected == NO ) {
            if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                [_delegate printerDelegateStatusResponse:PRINTER_NOT_CONNECTED];
            return;
        }
        NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        [_printerEADSessionController writeData:[printString dataUsingEncoding:gbkEncoding]];
        
    }else if (mode == IMATE_M36_PRINTER){
        
        if ( [_manager isConnectToDevice] == NO ){
            if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                [_delegate printerDelegateStatusResponse:PRINTER_NOT_CONNECTED];
            return;
        }
        NSMutableArray *printContent = [[NSMutableArray alloc]init];
        LDC_PrintLineStu *oneLine = [[LDC_PrintLineStu alloc]init];
        oneLine.type = PRINTTYPE_TEXT;
        oneLine.ailg = PRINTALIGN_LEFT;
        oneLine.zoom = PRINTZOOM_NORMAL;
        oneLine.position = PRINTPOSITION_ALL;//所有联都打印此行的内容
        oneLine.text = printString;
        [printContent addObject:oneLine];
        
        [_manager printText:1 withPrintContent:printContent successBlock:^{
            if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                ;
        } failedBlock:^(NSString *errCode, NSString *errInfo) {
            NSLog(@"errCode: %@, errInfo:%@",errCode,errInfo);
            dispatch_sync(dispatch_get_main_queue(), ^{
                if ([errCode isEqualToString:@"8e30"]) {
                    if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                        [_delegate printerDelegateStatusResponse:PRINTER_OFFLINE];
                }else if ([errCode isEqualToString:@"8e31"]) {
                    if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                        [_delegate printerDelegateStatusResponse:PRINTER_OUT_OF_PAPER];
                }else if ([errCode isEqualToString:@"8e03"]) {
                    if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                        [_delegate printerDelegateStatusResponse:PRINTER_NOT_SUPPORT];
                };
            });
        }];
    }
}


/**
 *  @brief    M36打印
 *  @param    title            打印居中标题（为nil时表示不打印标题）
 *  @param    printString      打印正文的文本
 *  @param    textFontSize     正文字体大小 （0x00 正常字体  0x01  一倍  0x02 两倍）
 *  @param    Multi            打印几联
 */
-(void)M36Print:(NSString*)title text:(NSString*)printString textFontSize:(int)size Multi:(int)number
{
    NSMutableArray *printContent = [[NSMutableArray alloc]init];
    LDC_PrintLineStu *Title;
    if (title) {
        LDC_PrintLineStu *Title = [[LDC_PrintLineStu alloc]init];
        Title.type = PRINTTYPE_TEXT;
        Title.ailg = PRINTALIGN_MID;
        Title.zoom = PRINTZOOM_3;
        Title.position = PRINTPOSITION_ALL;
        Title.text = title;
    }
    if (Title) {
        [printContent addObject:Title];
    }
    LDC_PrintLineStu *oneLine = [[LDC_PrintLineStu alloc]init];
    oneLine.type = PRINTTYPE_TEXT;
    oneLine.ailg = PRINTALIGN_LEFT;
    oneLine.zoom = size;
    oneLine.position = PRINTPOSITION_ALL;
    oneLine.text = printString;
    [printContent addObject:oneLine];
    
    [_manager printText:number withPrintContent:printContent successBlock:^{
        if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
            ;
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
        NSLog(@"errCode: %@, errInfo:%@",errCode,errInfo);
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([errCode isEqualToString:@"8e30"]) {
                if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                    [_delegate printerDelegateStatusResponse:PRINTER_OFFLINE];
            }else if ([errCode isEqualToString:@"8e31"]) {
                if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                    [_delegate printerDelegateStatusResponse:PRINTER_OUT_OF_PAPER];
            }else if ([errCode isEqualToString:@"8e03"]) {
                if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
                    [_delegate printerDelegateStatusResponse:PRINTER_NOT_SUPPORT];
            };
        });
    }];
}

#pragma mark private methods
-(void)setSyncRequestType:(BOOL)isSync
{
    if(isSync)
        requestType = kRequestSync;
    else
        requestType = kRequestNone;
}

-(BOOL)checkWorkStatus
{

    if ( _isMateConnected == NO ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate背夹未连接"];
        return NO;
    }
    if ( requestType != kRequestNone ) {
        if ( [_delegate respondsToSelector:@selector(iMateDelegateNoResponse:)] )
            [_delegate iMateDelegateNoResponse:@"iMate背夹正在工作状态,无法响应请求"];
        return NO;
    }
    return YES;
}

- (void)iMateDataReset
{
    [_imateDataObj reset];
}

#pragma mark - LIANDI c FUNCTION

LDE_ICC_SLOT_TYPE LianDiSlotMap(int slot)
{
    switch (slot) {
        case 0:
            return IC_SLOT_ICC1;
        case 1:
            return IC_SLOT_RF;
        case 4:
            return IC_SLOT_PSAM1;
        case 5:
            return IC_SLOT_PSAM2;
    }
    return IC_SLOT_ICC1;
}

int LianDiTestCard(void)
{
    if (![[LandiMPOS getInstance] isConnectToDevice]) {
        return 0;
    }
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block int ret = 0;
    [[LandiMPOS getInstance] powerUpICC:IC_SLOT_ICC1 successBlock:^(NSString *stringCB) {
        
        
        NSData *ATR = [iMateAppFace twoOneData:stringCB];
        vSetCardResetData((unsigned char*)ATR.bytes, (unsigned int)ATR.length);
        ret = 1;
        dispatch_semaphore_signal(sem);
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
        ret = 0;
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return ret;
}

int  LianDiExchangeApdu(int iInLen, uchar *pIn, int *piOutLen, uchar *pOut)
{
    if (![[LandiMPOS getInstance] isConnectToDevice]) {
        return 1;
    }
    NSData * inData = [NSData dataWithBytes:pIn length:iInLen];
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block int ret = 1;
    [[LandiMPOS getInstance] sendApduICC:IC_SLOT_ICC1 withApduCmd:[iMateAppFace oneTwoData:inData] successBlock:^(NSString *stringCB) {
        
        NSData *apduOut = [iMateAppFace twoOneData:stringCB];
        memcpy(pOut, apduOut.bytes, apduOut.length);
        *piOutLen = (int)apduOut.length;
        ret = 0;
        dispatch_semaphore_signal(sem);
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
        ret = 1;
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return ret;
}

#define CHONGQING_NONGSHANG

#pragma mark - select M35/36 or IMATE function
- (int)testConnectFunction
{
    if (!_isMateConnected) {
        return IMATEDISCONNECT;
    }
#ifdef CHONGQING_NONGSHANG
    if ([_manager isConnectToDevice]) {
        vSetDeviceType(1);
        gl_supportPbocPushApdu = NO;
        return LIANDIM35;
    }
    else {
        vSetDeviceType(0);
        return IMATE;
    }
#else
    if (!_isMposConnected&&![_manager isConnectToDevice]) {
        if( _hardwareVersion!=nil &&[_hardwareVersion containsString:@"IMATEIII"])
        {
            return M35DISCONNECT;
        }else{
            vSetDeviceType(0);
            return IMATE;
        }
    }else{
        if( _hardwareVersion!=nil &&[_hardwareVersion containsString:@"IMATEIII"])
        {
            vSetDeviceType(1);
            return LIANDIM35;
        }else{
            vSetDeviceType(0);
            return IMATE;
        }
    }
#endif
}



@end
