//
//  HXCardReader.m
//  Huaxin Internet Card Reader Kit
//
//  Created by Qingbo Jia on 15-01-07.
//  Copyright (c) 2014年 hxsmart. All rights reserved.
//

#import "HXCardReader.h"
#import "CBSessionController.h"
#include "RemoteFunctions.h"

#ifdef SUPPORT_DEVICE_M35
#import "LandiMPOS.h"
#endif

unsigned char gl_supportPackageSequenceNumberProtocol;
unsigned char gl_thePackageSequenceNumber;
unsigned char gl_isHxDevice = YES;
char gl_icrVersionString[50];

static volatile HXCardReaderStatus sg_hxCardReaderStatus = HXCardReaderStateClosed;

static HXCardReader *sg_hxCardReader = nil;

static id sg_self = nil;

extern void vSetRemoteCallMode(unsigned char ucMode);
//extern void vSetCardResetData(unsigned char *psCardResetData, uint uiLen);

extern void vSetWriteLog(int iOnOff);

@interface HXCardReader () <CBSessionControllerDelegate>

@property (nonatomic, strong) CBSessionController *cbSessionController;

@property (nonatomic, strong) NSString *deviceVersion;
@property (nonatomic, strong) NSString *deviceSerialNumber;
@property (nonatomic, strong) NSString *deviceBluetoothMac;

#ifdef SUPPORT_DEVICE_M35
@property (nonatomic,strong) LandiMPOS *manager;
@property (nonatomic,strong) NSTimer *findM35blueTimer;
@property (nonatomic,strong) NSString *releasedDeviceName;
#endif

@property (nonatomic,strong) NSString *bindingDeviceName;

@end

@implementation HXCardReader

- (id)initWithDelegate:(id)delegate
{
	if ((self = [super init])) {
        _delegate = delegate;
        _cbSessionController = [CBSessionController sharedController];
        _cbSessionController.delegate = self;
        
        gl_supportPackageSequenceNumberProtocol = YES;
        
        
        // 设置远程函数调用模式是否支持，0不支持，1支持
        vSetRemoteCallMode(1);
        
        //vSetWriteLog(1);
        
        sg_self = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cbSessionStatus:) name:@"CBSessionStatusNotification" object:nil];
	}
	return self;
}

- (BOOL)openSession
{
#ifdef DEBUG
    NSLog(@"openSession");
#endif
    memset(gl_icrVersionString, 0, sizeof(gl_icrVersionString));
    return [_cbSessionController openSession];
}

- (void)closeSession
{
#ifdef DEBUG
    NSLog(@"closeSession");
#endif
#ifdef SUPPORT_DEVICE_M35
    if (_manager) {
        if (_findM35blueTimer) {
            [_findM35blueTimer invalidate];
            _findM35blueTimer = nil;
        }
        [_manager closeDevice];
        _manager = nil;
        return;
    }
#endif
    [_cbSessionController closeSession];
}

// 绑定查找到的设备, 只有绑定设备后，设备才可以正常连接
- (void)bindingDevice:(NSString *)deviceName
{
    [_cbSessionController bindingDevice:deviceName];
    
    gl_isHxDevice = YES; //是否华信的设备
    if (![deviceName hasPrefix:@"ICR-"])
        gl_isHxDevice = NO;
    
    _bindingDeviceName = deviceName;
}

// 查询目前绑定的设备名称，返回nil未绑定
- (NSString *)queryBindingDevice
{
    return _bindingDeviceName;
}

// 检测蓝牙连接是否正常，返回HXCardReaderStatusOK表示连接正常
- (HXCardReaderStatus)connectingTest;
{
    return sg_hxCardReaderStatus;
}

- (BOOL)isWorking
{
    return [_cbSessionController isWorking];
}

// 读取iMate序列号
- (NSString *)deviceSerialNumber
{
    return _deviceSerialNumber;
}

// 蓝牙MAC地址
- (NSString *)deviceBluetoothMac
{
    return _deviceBluetoothMac;
}

// 查询iMate固件版本号
// 返回：
// nil                    : iMate不支持取版本或通讯错误
// "A.A,B.B.B,termid(12)" : 硬件和固件版本，其中A为硬件版本，B为固件版本, termid(如果存在).
- (NSString *)deviceVersion
{
    return _deviceVersion;
}

- (void)queryDevice
{
    NSData *receivedData;
    unsigned char sBuf[30];
    
    // try 3 times
    for (int i = 0 ; i < 3; i++) {
        _deviceVersion = nil;
        if ([_cbSessionController syncSendReceive:[NSData dataWithBytes:"\x60" length:1] outData:&receivedData timeout:3] == HXCardReaderStatusOK) {
            _deviceVersion = [NSString stringWithUTF8String:receivedData.bytes + 1];
            break;
        }
    }
    if ([_cbSessionController syncSendReceive:[NSData dataWithBytes:"\x04" length:1] outData:&receivedData timeout:3] == HXCardReaderStatusOK) {
        memset(sBuf, 0, sizeof(sBuf));
        _ucRcXMemReadReserved(sBuf, 128, 29);
        if (strlen(sBuf))
            _deviceSerialNumber = [NSString stringWithFormat:@"%.24s;%s", receivedData.bytes + 1, sBuf];
        else
            _deviceSerialNumber = [NSString stringWithFormat:@"%.24s;00000000", receivedData.bytes + 1];
        _deviceBluetoothMac = [NSString stringWithFormat:@"%.17s", receivedData.bytes + 1 + 24];
    }
    if (_deviceVersion) {
        //NSLog(@"===============================%@", _deviceVersion);
        strcpy(gl_icrVersionString, _deviceVersion.UTF8String);
    }
}

- (void)cardReaderStatusChanged:(id)statusObj
{
    CBSessionState status = ((NSNumber *)statusObj).intValue;
    sg_hxCardReaderStatus = [self getStatus:status];
    
    if (_delegate && [_delegate respondsToSelector:@selector(hxCardReaderDelegateConnectStatus:)] ) {
        [_delegate hxCardReaderDelegateConnectStatus:sg_hxCardReaderStatus];
    }
}

// iMate蜂鸣响一声
- (void)buzzer
{
    [_cbSessionController sendData:[NSData dataWithBytes:"\x11" length:1]];
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

+ (HXCardReader *)sharedController
{
    if (sg_hxCardReader == nil) {
        sg_hxCardReader = [[HXCardReader alloc] initWithDelegate:nil];
    }
    return sg_hxCardReader;
}

#pragma mark - Local methods

- (HXCardReaderStatus)getStatus:(CBSessionState)status
{
    switch (status) {
        case CBSessionStateOk:
            return HXCardReaderStatusOK;
        case CBSessionStateDisconnected:
            return HXCardReaderStatusDisconnected;
        case CBSessionStatePoweredOff:
            return HXCardReaderStatePoweredOff;
        case CBSessionStateUnsupported:
            return HXCardReaderStateUnsupported;
        case CBSessionStateUnauthorized:
            return HXCardReaderStateUnauthorized;
        case CBSessionStateTimeout:
            return HXCardReaderStateTimeout;
        case CBSessionStateClosed:
            return HXCardReaderStateClosed;
        default:
            break;
    }
    return  HXCardReaderStateUnknown;
}

- (void)cbSessionStatus:(NSNotification *)notification
{
    CBSessionState status = (CBSessionState)[(NSNumber *)notification.object intValue];
    
    if (status == CBSessionStateOk) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                [self queryDevice];
                [self performSelectorOnMainThread:@selector(cardReaderStatusChanged:) withObject:notification.object waitUntilDone:YES];
            }
        });
        return;
    }
    else {
        sg_hxCardReaderStatus = [self getStatus:status];
        if (_delegate && [_delegate respondsToSelector:@selector(hxCardReaderDelegateConnectStatus:)] ) {
            [_delegate hxCardReaderDelegateConnectStatus:sg_hxCardReaderStatus];
        }
    }
}

#pragma mark - C SyncComm function

int syncCommon(unsigned char *sendData, int sendLength, unsigned char *receivedData, int *receivedLength, int timeout)
{
    @autoreleasepool {
        CBSessionController *cardReaderSession = [CBSessionController sharedController];
        NSData *send = [NSData dataWithBytes:sendData length:sendLength];
        NSData *received;
        
        CBSessionState status = [cardReaderSession syncSendReceive:send outData:&received timeout:timeout + 1];
        switch (status) {
            case CBSessionStateOk:
                break;
            case CBSessionStateTimeout:
                return -1;
            default:
                return -2;
        }
        memcpy(receivedData, received.bytes, received.length);
        *receivedLength = (int)received.length;
        
        return 0;
    }
}

#pragma mark - CBSessionController Delegate

- (void)cbSessionDelegateFoundAvailableDevice:(NSString *)deviceName
{
    if (_delegate && [_delegate respondsToSelector:@selector(hxCardReaderDelegateFoundAvailableDevice:)] ) {
        [_delegate hxCardReaderDelegateFoundAvailableDevice:deviceName];
    }
}

#ifdef SUPPORT_DEVICE_M35

- (void)cbSessionDelegateReleaseControl:(NSString *)deviceName
{
    [_cbSessionController closeSession];
    
    if ([deviceName hasPrefix:@"M35-"]||[deviceName hasPrefix:@"M36-"]) {
        _manager = [LandiMPOS getInstance];
        NSLog(@"logVersion is:%@",[_manager getLibVersion]);
        
        _releasedDeviceName = deviceName;
        
        //2 搜索设备M35
        [self performSelector:@selector(searchAndOpenM35) withObject:nil afterDelay:0.5];
        
        _findM35blueTimer = [NSTimer scheduledTimerWithTimeInterval:8.0f target:self selector:@selector(timeoutFunc) userInfo:nil repeats:YES];
    }
}

-(void)timeoutFunc
{
    static int lastStatus = -1;
    
    int status = [_manager isConnectToDevice];
    
    if ([_manager isConnectToDevice] == NO) {
#ifdef DEBUG
        NSLog(@"[_manager isConnectToDevice] == NO");
#endif
        [self searchAndOpenM35];
    }
#ifdef DEBUG
    NSLog(@"status = %d, lastStatus = %d", status, lastStatus);
#endif
    if (status != lastStatus && status == NO) {
        if (_delegate && [_delegate respondsToSelector:@selector(hxCardReaderDelegateConnectStatus:)] ) {
            [_delegate hxCardReaderDelegateConnectStatus:HXCardReaderStatusDisconnected];
        }
    }
    lastStatus = status;
}

- (void)searchAndOpenM35
{
    [_manager closeDevice];
    [_manager stopSearchDev];
    
    sg_hxCardReaderStatus = HXCardReaderStatusDisconnected;
    
    [_manager startSearchDev:5 searchOneDeviceBlcok:^(LDC_DEVICEBASEINFO *deviceInfo) {
#ifdef DEBUG
        NSLog(@"Searched deviceInfo.deviceName:%@",deviceInfo.deviceName);
#endif
        if (deviceInfo && [deviceInfo.deviceName hasPrefix:_releasedDeviceName])
        {
            //3 找到了就停止搜索
            [_manager stopSearchDev];
            //4 打开设备
            [_manager openDevice:deviceInfo.deviceIndentifier channel:deviceInfo.deviceChannel mode:COMMUNICATIONMODE_MASTER successBlock:^{
#ifdef DEBUG
                NSLog(@"设备开启OK");
#endif
                [_manager getDeviceInfo:^(LDC_DeviceInfo* deviceInfo){
                    _deviceSerialNumber = [NSString stringWithFormat:@"%@;%@",deviceInfo.pinpadSN,deviceInfo.custormerSN];
                    _deviceVersion = [NSString stringWithFormat:@"M35,%@,%@", deviceInfo.hardwareVer, deviceInfo.userSoftVer];
                    _deviceBluetoothMac = @"00:00:00:00:00";
                    sg_hxCardReaderStatus = HXCardReaderStatusOK;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            if (_delegate && [_delegate respondsToSelector:@selector(hxCardReaderDelegateConnectStatus:)] ) {
                                [_delegate hxCardReaderDelegateConnectStatus:sg_hxCardReaderStatus];
                            }
                        }
                    });
                    
                }failedBlock:^(NSString* errCode,NSString* errInfo){
#ifdef DEBUG
                    NSLog(@"getDeviceInfo失败.失败码：%@,失败描述:%@",errCode,errInfo);
#endif
                    dispatch_async(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            if (_delegate && [_delegate respondsToSelector:@selector(hxCardReaderDelegateConnectStatus:)] ) {
                                [_delegate hxCardReaderDelegateConnectStatus:HXCardReaderStateUnsupported];
                            }
                        }
                    });

                }];
            } failedBlock:^(NSString *errCode, NSString *errInfo) {
#ifdef DEBUG
                NSLog(@"设备开启失败.失败码：%@,失败描述:%@",errCode,errInfo);
#endif
                dispatch_async(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        if (_delegate && [_delegate respondsToSelector:@selector(hxCardReaderDelegateConnectStatus:)] ) {
                            [_delegate hxCardReaderDelegateConnectStatus:HXCardReaderStateUnsupported];
                        }
                    }
                });
            }];
        }
    } completeBlock:^(NSMutableArray *deviceArray) {
#ifdef DEBUG
        NSLog(@"searchCompleteBloc");
#endif
    }];
}

#pragma mark printer
- (void)printerStatus
{
    if ( [_manager isConnectToDevice] == NO ) {
        if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
            [_delegate printerDelegateStatusResponse:PRINTER_NOT_CONNECTED];
        return;
    }else{
        if ( [_delegate respondsToSelector:@selector(printerDelegateStatusResponse:)] )
            [_delegate printerDelegateStatusResponse:PRINTER_CONNECTED];
    }
}


/**
 *  @brief    打印普通文本
 *  @param    printString   打印的文本信息
 *  @param    size           字体大小 （0x00 正常字体  0x01  一倍  0x02 两倍）
 */
- (void)print:(NSString *)printString FontSize:(int)size
{
    NSMutableArray *printContent = [[NSMutableArray alloc]init];
    LDC_PrintLineStu *oneLine = [[LDC_PrintLineStu alloc]init];
    oneLine.type = PRINTTYPE_TEXT;
    oneLine.ailg = PRINTALIGN_LEFT;
    oneLine.zoom = size;
    oneLine.position = PRINTPOSITION_ALL;
    oneLine.text = printString;
    [printContent addObject:oneLine];
    
    [_manager printText:1 withPrintContent:printContent successBlock:^{
        ;
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
        NSLog(@"errCode: %@, errInfo:%@",errCode,errInfo);
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
    }];
}


/**
 *	@brief	 打印大标题
 *	@param    打印的文本信息
 */
- (void)printTitile:(NSString *)printString
{
    NSMutableArray *printContent = [[NSMutableArray alloc]init];
    LDC_PrintLineStu *oneLine = [[LDC_PrintLineStu alloc]init];
    oneLine.type = PRINTTYPE_TEXT;
    oneLine.ailg = PRINTALIGN_MID;
    oneLine.zoom = PRINTZOOM_3;
    oneLine.position = PRINTPOSITION_ALL;
    oneLine.text = printString;
    [printContent addObject:oneLine];
    
    [_manager printText:1 withPrintContent:printContent successBlock:^{
        ;
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
        NSLog(@"errCode: %@, errInfo:%@",errCode,errInfo);
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
    }];
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


/**
 *  @param    PageContent      字典（格式： "1" ：NSArray对象 ,"2":NSArray对象,...）(每个NSArray 按顺序放置【title，正文，正文字体大小】值      
 *                             都是String型，包括字体大小 “0”，“1”，“2”分别是正常，1倍大，2倍大，标题没有给“”空文本)
 */
-(void)M36Print:(NSDictionary *)PageContent
{
    if (PageContent == nil) {
        return;
    }
    //最多4联
    int j = (int)[PageContent count];
    if (j>4) {
        j=4;
    }
    
    NSArray * oneLine;
    
    NSMutableArray *printContent = [[NSMutableArray alloc]init];
    LDC_PrintLineStu *LineTitle;
    LDC_PrintLineStu *LineText;
    
    for (int i = 1; i <= j; i++) {
        oneLine = [PageContent objectForKey:[NSString stringWithFormat:@"%d",i]];
        if ((id)oneLine != [NSNull null]&& oneLine !=nil) {
            
            LineTitle = [[LDC_PrintLineStu alloc]init];
            LineText = [[LDC_PrintLineStu alloc]init];
            
            LineTitle.type = PRINTTYPE_TEXT;
            LineTitle.ailg = PRINTALIGN_MID;
            LineTitle.zoom = PRINTZOOM_3;
            LineTitle.position = i;
            LineTitle.text = [oneLine objectAtIndex:0];
            [printContent addObject:LineTitle];
            
            LineText.type = PRINTTYPE_TEXT;
            LineText.ailg = PRINTALIGN_LEFT;
            LineText.zoom = (int)[[oneLine objectAtIndex:2] integerValue];
            LineText.position = i;
            LineText.text = [oneLine objectAtIndex:1];
            [printContent addObject:LineText];
        }
    }
    
    [_manager printText:j withPrintContent:printContent successBlock:^{
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

// 等待事件，包括磁卡刷卡、Pboc IC插入、放置射频卡。timeout是最长等待时间(秒)
// eventMask的bit来标识检测的部件：
//      0x01    等待刷卡事件
//      0x02    等待插卡事件
//      0x04    等待射频事件
//      0xFF    等待所有事件
// 等待的结果通过block回调

/**
 *	@brief	等待事件结束后，该方法被调用，返回结果
 *
 *	@param 	 returnCode不为0，error有错误信息
 *            eventId ：1检测到刷卡；2检测到IC卡；4检测到射频卡
 *            data    ：刷卡时返回二磁道、三磁道数据；IC返回复位数据；射频卡返回4字节的序列号
 */
- (void)waitEvent:(Byte)eventMask timeout:(NSInteger)timeout completionBlock:(waitEventBlock)handleBlock
{
    if (gl_isHxDevice) {
        //华信代码
        NSData *receivedData;
        Byte sendBytes[3];
        sendBytes[0] = 0x6B;
        sendBytes[1] = eventMask;
        sendBytes[2] = timeout;
        
        if ([_cbSessionController syncSendReceive:[NSData dataWithBytes:sendBytes length:3] outData:&receivedData timeout:(int)timeout] == HXCardReaderStatusOK) {
            handleBlock(0,((Byte *)receivedData.bytes)[0],[NSData dataWithBytes:receivedData.bytes + 1 length:[receivedData length]-1],nil);
        }else{
            char errorBytes[300];
            memset(errorBytes,0,sizeof(errorBytes));
            memcpy(errorBytes,[receivedData bytes],[receivedData length]);
            //将GBK编码的中文转换成UTF8编码
            NSStringEncoding enc =CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
            NSString *utf8Error = [NSString stringWithCString:(const char*)errorBytes encoding:enc];
            handleBlock(-1,((Byte *)receivedData.bytes)[0],nil,utf8Error);
        }
    }else{
        if ([_manager isConnectToDevice]) {
            
            [_manager waitingCard:@"请选择插卡、刷卡、挥卡" timeOut:(int)timeout CheckCardTp:eventMask&0x07 moneyNum:nil successBlock:^(LDE_CardType cardtype) {
                NSLog(@"cardType ==== %d",cardtype);
                switch (cardtype) {
                        
                    case 0x01:
                        //磁条卡
                    {
                        [_manager getTrackData:TRACKTYPE_PLAIN successCB:^(LDC_TrackDataInfo *trackData) {
                            
                            Byte trackDataBytes[34+107];
                            memset(trackDataBytes, 0xff, 34+107);
                            
                            NSData *track2data =[[trackData track2] dataUsingEncoding:NSUTF8StringEncoding];
                            NSData *track3data =[[trackData track3] dataUsingEncoding:NSUTF8StringEncoding];
                            int track2length = (int)[track2data length];
                            int track3length = (int)[track3data length];
                            if (track2length > 37) {
                                track2length = 37;
                            }
                            if (track3length > 104) {
                                track3length = 104;
                            }
                            memcpy(trackDataBytes, [track2data bytes], track2length);
                            memcpy(trackDataBytes+37, [track3data bytes], track3length);
                            
                            NSData *data = [NSData dataWithBytes:trackDataBytes length:141];
                            handleBlock(0,cardtype,data,nil);
                            
                        } failedBlock:^(NSString *errCode, NSString *errInfo) {
                            handleBlock(-1,[errCode intValue],nil,errInfo);
                        }];
                        break;
                    }
                    case 0x02:
                    {
                        [_manager powerUpICC:IC_SLOT_ICC1 successBlock:^(NSString *stringCB) {
                            NSData *ATR = [HXCardReader twoOneData:stringCB];
                            handleBlock(0,cardtype,ATR,nil);
                        } failedBlock:^(NSString *errCode, NSString *errInfo) {
                            handleBlock(-1,[errCode intValue],nil,errInfo);
                        }];
                        break;
                    }
                    case 0x04:
                    {
                        //射频卡
                        NSLog(@"检测到射频卡");
                        [_manager powerUpICC:IC_SLOT_RF successBlock:^(NSString *stringCB) {
                            NSData *ATR = [HXCardReader twoOneData:stringCB];
                            handleBlock(0,cardtype,ATR,nil);
                        } failedBlock:^(NSString *errCode, NSString *errInfo) {
                            handleBlock(-1,[errCode intValue],nil,errInfo);
                        }];
                        break;
                    }
                }
            } failedBlock:^(NSString *errCode, NSString *errInfo) {
                handleBlock(-1,[errCode intValue],nil,errInfo);
            }];
        }
    }
}


#pragma mark -- LIANDI c FUNCTION

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

int LianDiTestCard(int slot)
{
    if (![[LandiMPOS getInstance] isConnectToDevice]) {
        return 0;
    }
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block int ret = 0;
    [[LandiMPOS getInstance] powerUpICC:LianDiSlotMap(slot) successBlock:^(NSString *stringCB) {
        ret = 1;
        dispatch_semaphore_signal(sem);
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
        ret = 0;
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return ret;
}

int LianDiRestCard(int slot, unsigned char *atr)
{
    if (![[LandiMPOS getInstance] isConnectToDevice]) {
        return 0;
    }
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block int ret = 0;
    [[LandiMPOS getInstance] powerUpICC:LianDiSlotMap(slot) successBlock:^(NSString *stringCB) {
        NSData *ATR = [HXCardReader twoOneData:stringCB];
        memcpy(atr, (unsigned char*)ATR.bytes, (unsigned int)ATR.length);
        ret = (int)ATR.length;
        dispatch_semaphore_signal(sem);
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
        ret = 0;
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return ret;
}

int  LianDiExchangeApdu(int slot, int iInLen, unsigned char *pIn, int *piOutLen, unsigned char *pOut)
{
    if (![[LandiMPOS getInstance] isConnectToDevice]) {
        return 1;
    }
    NSData * inData = [NSData dataWithBytes:pIn length:iInLen];
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block int ret = 1;
    [[LandiMPOS getInstance] sendApduICC:LianDiSlotMap(slot) withApduCmd:[HXCardReader oneTwoData:inData] successBlock:^(NSString *stringCB) {
        
        NSData *apduOut = [HXCardReader twoOneData:stringCB];
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

void LianDiCloseCard(int slot)
{
    if (![[LandiMPOS getInstance] isConnectToDevice]) {
        return;
    }
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [[LandiMPOS getInstance] powerDownICC:LianDiSlotMap(slot)  successBlock:^{
        dispatch_semaphore_signal(sem);
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
        dispatch_semaphore_signal(sem);
    }];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}

// Pinpad functions
void _Pinpad_Cancel(void)
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == YES ) {
        [[LandiMPOS getInstance] cancelCMD:nil failedBlock:nil];
    }
}

int _Pinpad_Reset(int initFlag)
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        return 1;
    }
    return 0;
}

int _Pinpad_GetVersion(unsigned char *firmwareVersion, int *versionLength)
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        return 1;
    }
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block int ret = 0;
    __block NSString *version;
    
    [[LandiMPOS getInstance] getDeviceInfo:^(LDC_DeviceInfo *deviceInfo) {
        version = [NSString stringWithFormat:@"%@,%@", deviceInfo.hardwareVer, deviceInfo.userSoftVer];
        dispatch_semaphore_signal(sem);
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
        ret = 2;
        dispatch_semaphore_signal(sem);
    }];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    if (firmwareVersion) {
        strcpy(firmwareVersion, version.UTF8String);
        *versionLength = (int)strlen(firmwareVersion);
    }
    
    return ret;
}

int _Pinpad_DownloadMasterKey(int is3des, int index, unsigned char * masterKey, int keyLength)
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        return 1;
    }
    
    __block int ret = 0;
    __block LFC_LoadKey *key = [[LFC_LoadKey alloc] init];
    key.keyType = KEYTYPE_MKEY;
    key.keyData = [HXCardReader oneTwoData:[NSData dataWithBytes:masterKey length:keyLength]];

    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [[LandiMPOS getInstance] loadKey:key successBlock:^{
        dispatch_semaphore_signal(sem);
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
        ret = 2;
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return ret;
}

int _Pinpad_DownloadWorkingKey(int is3des, int masterIndex, int workingIndex, unsigned char* workingKey, int keyLength)
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        return 1;
    }
    
    __block int ret = 0;
    __block LFC_LoadKey *key = [[LFC_LoadKey alloc] init];
    key.keyType = workingIndex;
    key.keyData = [HXCardReader oneTwoData:[NSData dataWithBytes:workingKey length:keyLength]];
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [[LandiMPOS getInstance] loadKey:key successBlock:^{
        dispatch_semaphore_signal(sem);
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
        ret = 2;
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return ret;
}

int _Pinpad_InputPinblock(int is3des, int isAutoReturn, int masterIndex, int workingIndex, char* cardNo, int pinLength, unsigned char *pinblock, int timeout)
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        return 1;
    }
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    __block int ret = 0;
    __block LFC_GETPIN * inputPin = [[LFC_GETPIN alloc] init];
    inputPin.panBlock = [NSString stringWithFormat:@"%s", cardNo];
    inputPin.moneyNum = nil;
    inputPin.timeout = timeout;

    [[LandiMPOS getInstance] inputPin:inputPin successBlock:^(NSData *dateCB) {
#ifdef DEBUG
        NSLog(@"交易密码为：%@",dateCB);
#endif
        memcpy(pinblock, dateCB.bytes, 8);
        dispatch_semaphore_signal(sem);
        
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
#ifdef DEBUG
        NSLog(@"错误码：%@ ,错误信息：%@",errCode,errInfo);
#endif
        ret = 2;
        dispatch_semaphore_signal(sem);
    }];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return ret;
}


int _Pinpad_InputPinblockWithAmount(int is3des, int isAutoReturn, int masterIndex, int workingIndex,int amount,char* cardNo, int pinLength, unsigned char *pinblock, int timeout)
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        return 1;
    }
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    __block int ret = 0;
    __block LFC_GETPIN * inputPin = [[LFC_GETPIN alloc] init];
    inputPin.panBlock = [NSString stringWithFormat:@"%s", cardNo];
    NSString * amountStr = [NSString stringWithFormat:@"%09d.%02d",amount/100,amount%100];
    inputPin.moneyNum = amountStr;
    inputPin.timeout = timeout;
    
    [[LandiMPOS getInstance] inputPin:inputPin successBlock:^(NSData *dateCB) {
#ifdef DEBUG
        NSLog(@"交易密码为：%@",dateCB);
#endif
        memcpy(pinblock, dateCB.bytes, 8);
        dispatch_semaphore_signal(sem);
        
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
#ifdef DEBUG
        NSLog(@"错误码：%@ ,错误信息：%@",errCode,errInfo);
#endif
        ret = 2;
        dispatch_semaphore_signal(sem);
    }];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return ret;
}


int _Pinpad_Mac(int is3des, int masterIndex, int workingIndex, unsigned char* data, int dataLength, unsigned char *mac)
{
    if ( [[LandiMPOS getInstance] isConnectToDevice] == NO ) {
        return 1;
    }
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    __block int ret = 0;

    [[LandiMPOS getInstance] calculateMac:[HXCardReader oneTwoData:[NSData dataWithBytes:data length:dataLength]] successBlock:^(NSData *dateCB) {
        memcpy(mac, dateCB.bytes, dateCB.length);
        dispatch_semaphore_signal(sem);
    } failedBlock:^(NSString *errCode, NSString *errInfo) {
        ret = 2;
        dispatch_semaphore_signal(sem);
    }];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return ret;
}

#endif //ifdef SUPPORT_DEVICE_M35


@end
