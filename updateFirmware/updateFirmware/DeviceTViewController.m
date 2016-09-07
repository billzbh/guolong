//
//  DeviceViewController.m
//  updateFirmware
//
//  Created by zbh on 16/4/27.
//  Copyright © 2016年 hxsmart. All rights reserved.
//
#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define PROTOCOL_STRING_IMATE   @"com.insta360.guolong"
#define DBNAME @"guolong.hex"
#define SEND_MTU 32
#define TIMEOUT 5


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioServices.h>
#import "DeviceTViewController.h"
#import "EADSessionController.h"
#import <BmobSDK/Bmob.h>
#import <BmobSDK/BmobProFile.h>
#import "ZBHAlertViewController.h"
#import "MBProgressHUD.h"


static volatile BOOL sg_isWorking = NO;
@interface DeviceTViewController ()
{
    NSString* Lversion;
    NSString* RVersion;
    NSString* DVersion;
    NSString* filename;
    NSString* HexUrl;
    BOOL isUpdating;
    BOOL isDownloading;
    volatile BOOL receivedCompleted;
    int allPackNum;
    int customMTU;
    
    MBProgressHUD *hud;
}

@property (weak, nonatomic) IBOutlet UILabel *productName;
@property (weak, nonatomic) IBOutlet UILabel *serialNum;
@property (weak, nonatomic) IBOutlet UILabel *revision;
@property (weak, nonatomic) IBOutlet UILabel *xxxtitle;

@property (weak, nonatomic) IBOutlet UIButton *updateFirware;

@property (weak, nonatomic) IBOutlet UILabel *statusLog;

@property (strong, nonatomic) IBOutlet UITableView *topTableView;

@property (strong,nonatomic) NSMutableData *recevicedData;

@property (weak, nonatomic) IBOutlet UITextField *packNameSet;
@end

@implementation DeviceTViewController


-(IBAction)Done:(UITextField *)sender {
    customMTU = (int)[[_packNameSet text] integerValue];
}

- (IBAction)Test:(UIButton *)sender {
    
    customMTU = (int)[[_packNameSet text] integerValue];
    [_statusLog setText:[NSString stringWithFormat:@"发送一包，MTU为:%d",customMTU]];
   
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        unsigned char MTUsend[customMTU];
        Byte receiveBytes[50];
        
        
        for (int i = 0; i < customMTU; i++) {
            MTUsend[i]=i+1;
        }
        NSData* sendPackData =[self PackSendData:MTUsend length:customMTU PackNum:1];
        NSLog(@"sendPackData= %@",sendPackData);
        int iRet = [self syncSendReceive:sendPackData receivedBuff:receiveBytes timeout:5];
        if(iRet < 0) {
            //接收数据超时
            dispatch_async(dispatch_get_main_queue(), ^{
                [_statusLog setText:@"接收ACK 5s超时"];
            });
            return;
        }
        
        NSString *str=[NSString stringWithFormat:@"%@",[NSData dataWithBytes:receiveBytes length:iRet]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_statusLog setText:str];
        });
    });
}


//- (void)force2update:(UILongPressGestureRecognizer *)sender {
//    if([(UILongPressGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan){
//        AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
//        [self updateFirmwareFileInApp];
//    }
//}



- (IBAction)updateAction {
    
    [_statusLog setText:@""];
    if (!isDeviceConnected) {
        ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"Disconnected", nil) message:nil viewController:self];
        
        RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
            [self setButtonEnable:YES];
        }];
        [alertView addButton:okItem type:RIButtonItemType_Destructive];
        [alertView show];
        return;
    }
    
    [self setButtonEnable:NO];
    [self check2Update];
}

-(void)check2Update
{
    
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    // Set some text to show the initial status.
    hud.label.text = NSLocalizedString(@"isCheckingRomoteVersion", nil);
//    hud.detailsLabel.text = NSLocalizedString(@"isCheckingRomoteVersion", nil);
    // Will look best, if we set a minimum size.
    hud.minSize = CGSizeMake(300.f, 100.f);
    hud.contentColor = [UIColor colorWithRed:0.f green:0.6f blue:0.7f alpha:1.0f];
    
    //查找GameScore表
    BmobQuery  *bquery = [BmobQuery queryWithClassName:@"GL_Firmware"];
    //查找GameScore表里面id为0c6db13c的数据
    [bquery getObjectInBackgroundWithId:@"LXjr666H" block:^(BmobObject *object,NSError *error){
        if (error){
            //进行错误处理
            //弹窗：请看到远程版本号后再操作！
            [hud hideAnimated:YES];
            ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"checkRemoteVersionFail", nil) message:NSLocalizedString(@"checkNetwork", nil) viewController:self];
            
            RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                [self setButtonEnable:YES];
            }];
            [alertView addButton:okItem type:RIButtonItemType_Destructive];
            [alertView show];
            
        }else{
            //表里有id为LXjr666H的数据
            if (object) {
                //得到version和File
                BmobFile *File = [object objectForKey:@"HexFile"];
                filename = File.name;
                HexUrl = File.url;
                RVersion = [object objectForKey:@"Version"];
                
                hud = [MBProgressHUD HUDForView:self.view];
                hud.label.text = NSLocalizedString(@"CheckRomoteVersionOK", nil);
                
                //判断是否需要升级的逻辑在这里
                if([DVersion isEqualToString:RVersion])
                {
                    [hud hideAnimated:YES];
                    //弹出框，提示本地版本高于远程的版本。如果需要强制升级，请长按
                    ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"LocalHighthanRemote", nil) message:NSLocalizedString(@"forceUpdateTip", nil) viewController:self];
            
                    RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                        [self setButtonEnable:YES];
                    }];
                    [alertView addButton:okItem type:RIButtonItemType_Destructive];
                    [alertView show];
                    return;
                }
                
                usleep(200000);
                [self DownloadHexFile];
            }
        }
    }];
}


-(void)DownloadHexFile
{
    if (isDownloading==YES) {
        return;
    }
    
    hud = [MBProgressHUD HUDForView:self.view];
    hud.label.text = NSLocalizedString(@"downloading", nil);
    usleep(100000);
    isDownloading = YES;
    
    //1. 创建url
    NSURL *url = [NSURL URLWithString:HexUrl];
    // 2. Request
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // 3. Connection
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError == nil) {
            // 网络请求结束之后执行!
            // 更新界面
            dispatch_async(dispatch_get_main_queue(), ^{
                
                hud = [MBProgressHUD HUDForView:self.view];
                hud.label.text = NSLocalizedString(@"downloadOK", nil);
            });
            
            //将Data存在持久化。
            [data writeToFile:[self saveFilePath:DBNAME] atomically:YES];
            isDownloading = NO;
            
            
            usleep(100000);
            dispatch_async(dispatch_get_main_queue(), ^{
                //开始更新
                [self updateFirmware];
            });
            
        }else{
            
            [hud hideAnimated:YES];
            //弹出框，提示本地版本高于远程的版本。如果需要强制升级，请长按
            ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"downloadFail", nil) message:nil viewController:self];
            
            RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                [self setButtonEnable:YES];
            }];
            [alertView addButton:okItem type:RIButtonItemType_Destructive];
            [alertView show];
        }
    }];
    return;
}



-(void)updateFirmware
{
    customMTU = (int)[[_packNameSet text] integerValue];
#ifndef DEBUG
    customMTU = SEND_MTU;
#endif
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        isUpdating = YES;
        
        //读取文件
        NSData* hexData = [NSData dataWithContentsOfFile:[self saveFilePath:DBNAME]];
        Byte *sendData = (Byte*)[hexData bytes];
        int packnum=0;
        
        
        hud = [MBProgressHUD HUDForView:self.view];
        hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
        __block float progress = 0.0f;
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.label.text = NSLocalizedString(@"startCommand", nil);
            hud.progress = progress;
        });
        usleep(100000);
        
        Byte receiveBytes[50];
        Byte sendBytes[2];
        sendBytes[0]=0x41;
        sendBytes[1]=0x42;
        int iRet = [self syncSendReceive:[NSData dataWithBytes:sendBytes length:2] receivedBuff:receiveBytes timeout:TIMEOUT];
        
        if(iRet < 0) {
            //接收数据超时
            NSLog(@"接收数据超时，升级出错");
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [hud hideAnimated:YES];
                
                ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"updateFailbyTimeout", nil) message:NSLocalizedString(@"stopUpdate", nil) viewController:self];
                
                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                    isUpdating = NO;
                    [self setButtonEnable:YES];
                }];
                [alertView addButton:okItem type:RIButtonItemType_Destructive];
                [alertView show];
            });
            return;
        }
        
        int retCode = receiveBytes[2];
        if (retCode != 0x03) {
            //启动升级程序失败
            NSLog(@"启动升级程序失败");
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [hud hideAnimated:YES];
                
                ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"ACKError", nil) message:NSLocalizedString(@"stopUpdate", nil) viewController:self];
                
                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                    
                    isUpdating = NO;
                    [self setButtonEnable:YES];
                    
                }];
                [alertView addButton:okItem type:RIButtonItemType_Destructive];
                [alertView show];
            });
            return;
        }
        
        //获取第一个包号
        packnum = receiveBytes[3]*256+receiveBytes[4];
        //开始发送数据：
        Byte dataBytes[customMTU];
        int sendLength=customMTU;
        int UnsenddataLength=(int)[hexData length];
        
        while (1) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                hud.label.text = NSLocalizedString(@"tranferData", nil);
                progress = (float)((packnum-1)*customMTU)/(float)UnsenddataLength/3.0;
                hud.progress = progress;
            });
            
            if (packnum == (UnsenddataLength+customMTU-1)/customMTU) {
                sendLength = UnsenddataLength-(packnum-1)*customMTU;
                memset(dataBytes, 0xFF, customMTU);
                memcpy(dataBytes, sendData+(packnum-1)*customMTU, sendLength);
            }else
                memcpy(dataBytes, sendData+(packnum-1)*customMTU, customMTU);
            
            memset(receiveBytes, 0, 50);
            NSData* sendPackData =[self PackSendData:dataBytes length:customMTU PackNum:packnum];
            iRet = [self syncSendReceive:sendPackData receivedBuff:receiveBytes timeout:TIMEOUT];
            if(iRet < 0) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [hud hideAnimated:YES];
                    
                    ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"updateFailbyTimeout", nil) message:NSLocalizedString(@"LastACKError", nil) viewController:self];
                    RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                        
                        isUpdating = NO;
                        [self setButtonEnable:YES];
                        
                    }];
                    [alertView addButton:okItem type:RIButtonItemType_Destructive];
                    [alertView show];
                });
                return;
            }
            
            retCode = receiveBytes[2];
            if (retCode!=0x03) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [hud hideAnimated:YES];

                    ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"ACKError", nil) message:NSLocalizedString(@"stopUpdate", nil) viewController:self];
                    
                    RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                        isUpdating = NO;
                        [self setButtonEnable:YES];
                    }];
                    [alertView addButton:okItem type:RIButtonItemType_Destructive];
                    [alertView show];
                });
                return;
            }
            packnum = receiveBytes[3]*256+receiveBytes[4];
            if ( packnum > (UnsenddataLength+customMTU-1)/customMTU ) {
                break;
            }
        }
        
        //发送结束升级包
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.label.text = NSLocalizedString(@"sendFinishCMD", nil);
            hud.progress = progress + 0.01f;
        });
        
        memset(receiveBytes, 0, 50);
        iRet = [self syncSendReceive:[self packFinishData] receivedBuff:receiveBytes timeout:20];
        if (iRet<0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [hud hideAnimated:YES];

                ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"updateFailbyTimeout", nil) message:NSLocalizedString(@"LastACKError", nil) viewController:self];
                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                    
                    isUpdating = NO;
                    [self setButtonEnable:YES];
                    
                }];
                [alertView addButton:okItem type:RIButtonItemType_Destructive];
                [alertView show];
            });
            
            return ;
        }
        
        retCode = receiveBytes[2];
        if(retCode==0x05)//成功
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                hud.label.text = NSLocalizedString(@"updateOK", nil);
                hud.progress = progress + 0.01f;
            });
            usleep(100000);
            
        }else if(retCode==0x06)//失败
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [hud hideAnimated:YES];

                ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"updateFail", nil) message:@"" viewController:self];
                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                    isUpdating = NO;
                    [self setButtonEnable:YES];
                }];
                [alertView addButton:okItem type:RIButtonItemType_Destructive];
                [alertView show];
            });
            
            return;
        }
        
        
        //等待固件升级成功
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.label.text = NSLocalizedString(@"waitForUpdate", nil);
            hud.progress = progress + 0.01f;
        });
        
        memset(receiveBytes, 0, 50);
        iRet = [self waitForRestart:receiveBytes timeout:25];
        if (iRet<0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"updateFailbyTimeout", nil) message:NSLocalizedString(@"reInsert", nil) viewController:self];
                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        
                        Byte receive[50];
                        memset(receive, 0, 50);
                        int iiRet = [self waitForRestart2:receive timeout:25];
                        if (iiRet<0) {
                            
                            [hud hideAnimated:YES];
                            [_statusLog setText:NSLocalizedString(@"updateFirmFail", nil)];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                ZBHAlertViewController *alertView2 = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"updateFailbyTimeout", nil) message:NSLocalizedString(@"reInsert", nil) viewController:self];
                                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                                    isUpdating = NO;
                                    [self setButtonEnable:YES];
                                }];
                                [alertView2 addButton:okItem type:RIButtonItemType_Destructive];
                                [alertView2 show];
                            });
                            return;
                        }
                        
                        progress  = hud.progress;
                        while (progress < 1.0f) {
                            progress += 0.01f;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                hud.progress = progress;
                            });
                            usleep(50000);
                        }
                        
                        Byte retCode = receive[2];
                        if(retCode==0x07)//升级成功
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                                UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                                hud.customView = imageView;
                                hud.mode = MBProgressHUDModeCustomView;
                                hud.label.text = NSLocalizedString(@"firmwareFINSH", nil);
                                [_statusLog setText:NSLocalizedString(@"firmwareFINSH", nil)];
                                
                                [hud.button setTitle:NSLocalizedString(@"makeSure", nil) forState:UIControlStateNormal];
                                [hud.button addTarget:self action:@selector(makeSureWork:) forControlEvents:UIControlEventTouchUpInside];
                                
                            });
                            
                        }else{
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [hud hideAnimated:YES];
                                [_statusLog setText:NSLocalizedString(@"updateFirmFail", nil)];
                                ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"updateFirmFail", nil) message:@"" viewController:self];
                                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                                    isUpdating = NO;
                                    [self setButtonEnable:YES];
                                }];
                                [alertView addButton:okItem type:RIButtonItemType_Destructive];
                                [alertView show];
                            });
                        }
                        return;
                        
                    });
                    
                }];
                [alertView addButton:okItem type:RIButtonItemType_Destructive];
                [alertView show];
            });
            return ;
        }
        
        progress  = hud.progress;
        while (progress < 1.0f) {
            progress += 0.01f;
            dispatch_async(dispatch_get_main_queue(), ^{
                hud.progress = progress;
            });
            usleep(50000);
        }
        
        retCode = receiveBytes[2];
        if(retCode==0x07)//升级成功
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                hud.customView = imageView;
                hud.mode = MBProgressHUDModeCustomView;
                hud.label.text = NSLocalizedString(@"firmwareFINSH", nil);
                [_statusLog setText:NSLocalizedString(@"firmwareFINSH", nil)];
                
                [hud.button setTitle:NSLocalizedString(@"makeSure", nil) forState:UIControlStateNormal];
                [hud.button addTarget:self action:@selector(makeSureWork:) forControlEvents:UIControlEventTouchUpInside];
                
            });
            
        }else{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                [_statusLog setText:NSLocalizedString(@"updateFirmFail", nil)];
                ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"updateFirmFail", nil) message:@"" viewController:self];
                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                    isUpdating = NO;
                    [self setButtonEnable:YES];
                }];
                [alertView addButton:okItem type:RIButtonItemType_Destructive];
                [alertView show];
            });
        }
        return;
    });
 }


-(void)makeSureWork:(id)sender {
    isUpdating = NO;
    [self setButtonEnable:YES];
    [hud hideAnimated:YES];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //可能需要停止更新固件
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    //临时测试，强制升级
//    UILongPressGestureRecognizer *longPress=[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(force2update:)];
//    longPress.minimumPressDuration=0.6;//定义按的时间
//    [_updateFirware addGestureRecognizer:longPress];
    
    
    

    [self.xxxtitle setText:NSLocalizedString(@"xxxxxTitle", nil)];
    isUpdating = NO;
    isDownloading = NO;
    isDeviceConnected = NO;
    _recevicedData = [[NSMutableData alloc] init];
    [_recevicedData setLength:0];
    
    if (!isPad) {
        [_topTableView setSectionHeaderHeight:24.0];
        [_topTableView setSectionFooterHeight:18.0];
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidConnect:) name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidDisconnect:) name:EAAccessoryDidDisconnectNotification object:nil];
    
    // watch for received data from the accessory
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_sessionDataReceived:) name:EADSessionDataReceivedNotification object:nil];
    
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    //查询设备
    _eaSessionController = [EADSessionController sharedController];
    _accessoryList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
    
    if ([_accessoryList count] == 0) {
        //更新UI
        [self updateUI2Zero];
    } else {
        //连接设备
        [self openSession];
    }
}



-(NSData*)PackSendData:(NSData *)data PackNum:(int)num
{
    Byte tmp[3];
    tmp[0]=0xAA;
    tmp[1]=num/256;
    tmp[2]=num%256;
    NSMutableData* resultData = [[NSMutableData alloc] init];
    [resultData appendBytes:tmp length:3];
    [resultData appendData:data];

    return resultData;
}

-(NSData*)PackSendData:(Byte*)data length:(int)length PackNum:(int)num
{
    Byte tmp[3];
    tmp[0]=0xAA;
    tmp[1]=num/256;
    tmp[2]=num%256;
    NSMutableData* resultData = [[NSMutableData alloc] init];
    [resultData appendBytes:tmp length:3];
    [resultData appendBytes:data length:length];
    return resultData;
}

-(NSData*)packFinishData
{
    Byte tmp[8];
    tmp[0]=0xDD;
    tmp[1]=0xCC;
    tmp[2]=0x04;
    tmp[3]=0xFF;
    tmp[4]=0xFF;
    tmp[5]=0xFF;
    tmp[6]=0xFF;
    tmp[7]=0xee;
    NSMutableData* resultData = [[NSMutableData alloc] init];
    [resultData appendBytes:tmp length:8];
    return resultData;
}


-(void)updateUI2Zero
{
    [_productName setText:@"N/A"];
    [_serialNum setText:@"N/A"];
    [_revision setText:@"N/A"];
    [_statusLog setText:NSLocalizedString(@"Disconnected", nil)];
}


// Data was received from the accessory, real apps should do something with this data but currently:
//    1. bytes counter is incremented
//    2. bytes are read from the session controller and thrown away
- (void)_sessionDataReceived:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"_sessionDataReceived");
#endif
    EADSessionController *sessionController = (EADSessionController *)[notification object];
    unsigned long bytesAvailable = 0;
    
    if ( [sessionController.protocolString isEqualToString:PROTOCOL_STRING_IMATE])
    {
        
        while ((bytesAvailable = [sessionController readBytesAvailable]) > 0) {
            NSData *data = [sessionController readData:bytesAvailable];
            if (data) {
                [_recevicedData appendData:data];
                int length = (int)[_recevicedData length];
                Byte *tmp = (Byte*)[_recevicedData bytes];
                if (length == 8 && tmp[length-1]==0xEE) {
                    receivedCompleted = YES;
                }
            }
        }
    }
}


- (void)_accessoryDidConnect:(NSNotification *)notification {
#ifdef DEBUG
    NSLog(@"accessoryDidConnect begin");
#endif
    EAAccessory *connectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    
#ifdef DEBUG
    NSLog(@"connectedAccessory=%@",connectedAccessory);
    NSLog(@"[[connectedAccessory protocolStrings] count]:%lu", (unsigned long)[[connectedAccessory protocolStrings] count]);
#endif
    if ( ![[connectedAccessory protocolStrings] count] ) {
        return;
    }
#ifdef DEBUG
    NSLog(@"protocolStrings ==== %@",[connectedAccessory protocolStrings]);
#endif
    
    if ([[connectedAccessory protocolStrings] containsObject:PROTOCOL_STRING_IMATE]) {
        
        if ( isDeviceConnected == YES )
            return;
        
        [_eaSessionController closeSession];
        [_eaSessionController setupControllerForAccessory:connectedAccessory
                                             withProtocolString:PROTOCOL_STRING_IMATE];
        _selectedAccessory = [_eaSessionController accessory];
        
        DVersion = _selectedAccessory.firmwareRevision;//设备固件版本
        _productName.text = _selectedAccessory.name;
        _serialNum.text = _selectedAccessory.serialNumber;
        _revision.text= _selectedAccessory.hardwareRevision;
        
        
        [_eaSessionController openSession];
        isDeviceConnected = YES;
        
        //更新UI
        [_statusLog setText:NSLocalizedString(@"Connected", nil)];
        
        
//        [self deviceSetup];
    }
}


- (void)_accessoryDidDisconnect:(NSNotification *)notification{
    
#ifdef DEBUG
    NSLog(@"accessoryDidDisconnect begin");
#endif
    EAAccessory *disconnectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    
#ifdef DEBUG
    NSLog(@"disconnectedAccessory:%@", disconnectedAccessory);
#endif
    
    if ([disconnectedAccessory connectionID] == [_selectedAccessory connectionID])
    {
        if ([disconnectedAccessory.protocolStrings containsObject:PROTOCOL_STRING_IMATE] ) {
            [_eaSessionController closeSession];
            
            //更新UI
            [self updateUI2Zero];
            
            isDeviceConnected = NO;
            _selectedAccessory = nil;
            NSLog(@"Device Disconnected");
        }
    }
#ifdef DEBUG
    NSLog(@"accessoryDidDisconnect end");
#endif
    
}

-(void)openSession
{
#ifdef DEBUG
    NSLog(@"openSession");
#endif
    isDeviceConnected = NO;
    
    NSArray *accessoryList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
    for (EAAccessory *accessory in accessoryList) {
        //NSLog(@"accessory = %@",accessory);
        
        if ( ![[accessory protocolStrings] count] ) {
            continue;
        }
#ifdef DEBUG
        NSLog(@"%@",[accessory protocolStrings]);
#endif
        
        if ([[accessory protocolStrings] containsObject:PROTOCOL_STRING_IMATE]) {
            
            [_eaSessionController setupControllerForAccessory:accessory
                                                 withProtocolString:PROTOCOL_STRING_IMATE];
            _selectedAccessory = [_eaSessionController accessory];
            
//            NSLog(@"%@",_selectedAccessory);
            DVersion = _selectedAccessory.firmwareRevision;//设备固件版本
            _productName.text = _selectedAccessory.name;
            _serialNum.text = _selectedAccessory.serialNumber;
            _revision.text= _selectedAccessory.hardwareRevision;
            
            
            [_eaSessionController openSession];
            isDeviceConnected = YES;
            //更新UI
            [_statusLog setText:NSLocalizedString(@"Connected", nil)];
            
//           [self deviceSetup];
        }
    }
}

- (void)closeSession
{
#ifdef DEBUG
    NSLog(@"closeSession");
#endif
    [_eaSessionController closeSession];
    [_eaSessionController setupControllerForAccessory:nil withProtocolString:nil];
    isDeviceConnected = NO;
    _selectedAccessory = nil;
}


/**
 -1 timeout
 -3 一次发送接收未完成
 > 长度
 */
- (int)syncSendReceive:(NSData *)inData outData:(NSData **) outData timeout:(int) timeout
{
    if (sg_isWorking==YES) {
        return -3;//已经在发送接收中，请等待一次发送接收完毕
    }
    sg_isWorking = YES;
    receivedCompleted = NO;
    [_recevicedData resetBytesInRange:NSMakeRange(0,_recevicedData.length)];
    [_recevicedData setLength:0];
    
    dispatch_async(dispatch_get_main_queue(), ^{ //解决多线程写数据冲突的问题，使用main_queue进行排队
        [_eaSessionController writeData:inData];
    });
    
    double timeSeconds = [self currentTimeSeconds] + timeout;
    while ([self currentTimeSeconds] < timeSeconds) {
        if(receivedCompleted)
            break;
        usleep(1000);
    }
    
    if (!receivedCompleted) {
        sg_isWorking = NO;
        return -1;//timeout
    }
    
    if ([_recevicedData length] == 0) {
        return -1;
    }
    
    *outData = [NSData dataWithData:_recevicedData];
    sg_isWorking = NO;
    return (int)[_recevicedData length];
}


/**
 -1 timeout
 -3 一次发送接收未完成
 > 长度
 */
- (int)waitForRestart:(Byte*)outBytes timeout:(int) timeout
{
    if (sg_isWorking==YES) {
        return -3;//已经在发送接收中，请等待一次发送接收完毕
    }
    sg_isWorking = YES;
    receivedCompleted = NO;
    
    //清空数据
    [_recevicedData resetBytesInRange:NSMakeRange(0,_recevicedData.length)];
    [_recevicedData setLength:0];
    
    dispatch_async(dispatch_get_main_queue(), ^{ //解决多线程写数据冲突的问题，使用main_queue进行排队
        [_eaSessionController writeData:nil];
    });
    
    double timeSeconds = [self currentTimeSeconds] + timeout;
    while ([self currentTimeSeconds] < timeSeconds) {
        if(receivedCompleted)
            break;
        usleep(10000);
        dispatch_async(dispatch_get_main_queue(), ^{
            hud = [MBProgressHUD HUDForView:self.view];
            float process = hud.progress;
            process += 0.00025f;
            hud.progress = process;
        });
    }
    
    if (!receivedCompleted) {
        sg_isWorking = NO;
        return -1;//timeout
    }
    
    Byte *tmp = (Byte*)[_recevicedData bytes];
    int length = (int)[_recevicedData length];
    if (length == 0) {
        return -1;
    }
    
    memcpy(outBytes, tmp,length);
    sg_isWorking = NO;
    return length;
}


/**
 -1 timeout
 -3 一次发送接收未完成
 > 长度
 */
- (int)waitForRestart2:(Byte*)outBytes timeout:(int) timeout
{
    if (sg_isWorking==YES) {
        return -3;//已经在发送接收中，请等待一次发送接收完毕
    }
    sg_isWorking = YES;
    receivedCompleted = NO;
    
    //清空数据
    [_recevicedData resetBytesInRange:NSMakeRange(0,_recevicedData.length)];
    [_recevicedData setLength:0];
    
    dispatch_async(dispatch_get_main_queue(), ^{ //解决多线程写数据冲突的问题，使用main_queue进行排队
        [_eaSessionController writeData:nil];
    });
    
    double timeSeconds = [self currentTimeSeconds] + timeout;
    while ([self currentTimeSeconds] < timeSeconds) {
        if(receivedCompleted)
            break;
        usleep(1000);
    }
    
    if (!receivedCompleted) {
        sg_isWorking = NO;
        return -1;//timeout
    }
    
    Byte *tmp = (Byte*)[_recevicedData bytes];
    int length = (int)[_recevicedData length];
    if (length == 0) {
        return -1;
    }
    
    memcpy(outBytes, tmp,length);
    sg_isWorking = NO;
    return length;
}




/**
 -1 timeout
 -3 一次发送接收未完成
 > 长度
 */
- (int)syncSendReceive:(NSData *)inData receivedBuff:(Byte*)outBytes timeout:(int) timeout
{
    if (sg_isWorking==YES) {
        return -3;//已经在发送接收中，请等待一次发送接收完毕
    }
    sg_isWorking = YES;
    receivedCompleted = NO;

    //清空数据
    [_recevicedData resetBytesInRange:NSMakeRange(0,_recevicedData.length)];
    [_recevicedData setLength:0];
    
    dispatch_async(dispatch_get_main_queue(), ^{ //解决多线程写数据冲突的问题，使用main_queue进行排队
        [_eaSessionController writeData:inData];
    });
    
    double timeSeconds = [self currentTimeSeconds] + timeout;
    while ([self currentTimeSeconds] < timeSeconds) {
        if(receivedCompleted)
            break;
        usleep(1000);
    }
    
    if (!receivedCompleted) {
        sg_isWorking = NO;
        return -1;//timeout
    }
    
    Byte *tmp = (Byte*)[_recevicedData bytes];
    int length = (int)[_recevicedData length];
    if (length == 0) {
        return -1;
    }
    
    memcpy(outBytes, tmp,length);
    sg_isWorking = NO;
    return length;
}


-(double)currentTimeSeconds
{
    NSTimeInterval time= [[NSDate date] timeIntervalSince1970];
    return (double)time;
}


-(void)setButtonEnable:(BOOL)enable
{
    if (enable) {
        [_updateFirware setEnabled:YES];
        [_updateFirware setBackgroundColor:[UIColor redColor]];
        [_updateFirware setTitle:NSLocalizedString(@"startUpdate", nil) forState:UIControlStateNormal];
    }else{
        [_updateFirware setEnabled:NO];
        [_updateFirware setBackgroundColor:[UIColor grayColor]];
        [_updateFirware setTitle:NSLocalizedString(@"stopUpdate", nil) forState:UIControlStateNormal];
    }
}


-(NSString*)saveFilePath:(NSString*)Fname
{
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    // 传递 0 代表是找在Documents 目录下的文件。
    NSString *documentDirectory = [directoryPaths objectAtIndex:0];
    // DBNAME 是要查找的文件名字，文件全名
    return [documentDirectory stringByAppendingPathComponent:Fname];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EADSessionDataReceivedNotification object:nil];
    [[EADSessionController sharedController] closeSession];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
