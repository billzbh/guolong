//
//  DeviceViewController.m
//  updateFirmware
//
//  Created by zbh on 16/4/27.
//  Copyright © 2016年 hxsmart. All rights reserved.
//
#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//#define StrAccExtProNameInfo  @"com.insta360.guolong"
//#define PROTOCOL_STRING_IMATE   @"com.imate.bluetooth"
#define PROTOCOL_STRING_IMATE   @"com.insta360.guolong"
#define DBNAME @"guolong.hex"
#define SEND_MTU 32
#define TIMEOUT 5


unsigned char gl_supportUpdateProtocol;

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioServices.h>
#import "DeviceTViewController.h"
#import "EADSessionController.h"
#import <BmobSDK/Bmob.h>
#import <BmobSDK/BmobProFile.h>
#import "ZBHAlertViewController.h"


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
}

@property (weak, nonatomic) IBOutlet UILabel *productName;
@property (weak, nonatomic) IBOutlet UILabel *manufacturer;

@property (weak, nonatomic) IBOutlet UILabel *model;


@property (weak, nonatomic) IBOutlet UILabel *serialNum;

@property (weak, nonatomic) IBOutlet UILabel *revision;
@property (weak, nonatomic) IBOutlet UILabel *LocalVersion;
@property (weak, nonatomic) IBOutlet UILabel *remoteVersion;

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

    

//    allPackNum = (int)[[_packNameSet text] integerValue];
//    [_statusLog setText:@"等待请求包，20s"];
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        
//        int iRet;
//        Byte dataBytes[12*allPackNum];
//        int num = 0;
//        Byte receiveBytes[50];
//        
//        iRet = [self syncSendReceive:nil receivedBuff:receiveBytes timeout:20];
//        if(iRet<0)
//        {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [_statusLog setText:@"20s等待请求包超时"];
//            });
//            return;
//        }
//            
//        num = receiveBytes[3]*256+receiveBytes[4];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSString *str = [NSString stringWithFormat:@"接收ACK 包号：%d,",num];
//            [_statusLog setText:str];
//        });
//        
//        double timeSeconds = [self currentTimeSeconds];
//        
//        int UnsenddataLength=allPackNum*12;
//        while (1) {
//            int mlength = 12;
//            memset(receiveBytes, 0, 50);
//            memset(dataBytes+(num-1)*mlength, num, mlength);//每一包的内容刚好是包号
//            NSData* sendPackData =[self PackSendData:dataBytes+(num-1)*mlength length:mlength PackNum:num];
//            iRet = [self syncSendReceive:sendPackData receivedBuff:receiveBytes timeout:5];
//            if(iRet < 0) {
//                //接收数据超时
//                NSLog(@"接收数据超时");
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [_statusLog setText:@"接收ACK 5s超时了"];
//                });
//                return;
//            }
//            
//            num = receiveBytes[3]*256+receiveBytes[4];
//            if ( num > (UnsenddataLength+mlength-1)/mlength ) {
//                
//                timeSeconds = [self currentTimeSeconds] - timeSeconds;
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    NSString *str = [NSString stringWithFormat:@"包号：%d,需要发的包数目：%d,用时:%f s",num,(UnsenddataLength+mlength-1)/mlength,timeSeconds];
//                    [_statusLog setText:str];
//                });
//                break;
//            }
//            dispatch_async(dispatch_get_main_queue(), ^{
//                NSString *str = [NSString stringWithFormat:@"接收ACK 包号：%d,",num];
//                [_statusLog setText:str];
//            });
//        }
//    });
}


- (void)force2update:(UILongPressGestureRecognizer *)sender {
    if([(UILongPressGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan){
        AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
        [self updateFirmwareFileInApp];
    }
}



- (IBAction)updateAction {
    
        
    [self setButtonEnable:NO];
    if (RVersion==nil) {
        //查询远程远程服务器版本
        [self check2Update];
        ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"RemoteVersionIsNil", nil) message:NSLocalizedString(@"clickAgain", nil) viewController:self];
        
        RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
            
        }];
        [alertView addButton:okItem type:RIButtonItemType_Destructive];
        [alertView show];
        return;
    }
    
    //比较版本号。如果没有设备版本号或者远程版本 <= 设备版本号，直接return并弹出警告。
    if(DVersion==nil)
    {
        //弹出框提示读不到设备号，不能升级。
        ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"checkLocalVersionFail", nil) message:NSLocalizedString(@"makeSureDeviceConnect", nil) viewController:self];
        
        RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
            [self setButtonEnable:YES];
            isUpdating = NO;
        }];
        [alertView addButton:okItem type:RIButtonItemType_Destructive];
        [alertView show];
        return;
    }

    if([DVersion floatValue] >= [RVersion floatValue])
    {
        //弹出框，提示本地版本高于远程的版本。如果需要强制升级，请长按
        ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"LocalHighthanRemote", nil) message:NSLocalizedString(@"forceUpdateTip", nil) viewController:self];
        
        RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
            [self setButtonEnable:YES];
            isUpdating = NO;
        }];
        [alertView addButton:okItem type:RIButtonItemType_Destructive];
        [alertView show];
        return;
    }
    
    [self updateFirmware];
}


-(void)updateFirmwareFileInApp
{
    customMTU = (int)[[_packNameSet text] integerValue];
#ifndef DEBUG
    customMTU = SEND_MTU;
#endif
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (isUpdating==YES) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"Upating", nil) message:NSLocalizedString(@"UpatingTip2Next", nil) viewController:self];
                
                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                    
                }];
                [alertView addButton:okItem type:RIButtonItemType_Destructive];
                [alertView show];
            });
            
            return;
        }
        
        isUpdating = YES;
        
        //读取文件
        //1. 先读取本地下载的文件
        NSData* hexData = [NSData dataWithContentsOfFile:[self saveFilePath:DBNAME]];
        if(hexData==nil)//为nil则从app本地资源读取。
        {
            NSString *bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"guolong.bundle"];
            NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
            hexData = [NSData dataWithContentsOfFile:[bundle pathForResource:@"UART" ofType:@"bin"]];
        }
        Byte *sendData = (Byte*)[hexData bytes];
        
    
        int packnum=1;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_statusLog setText:NSLocalizedString(@"startCommand", nil)];
        });
        
        int iRet,retCode;
        Byte receiveBytes[50];
        Byte sendBytes[2];
        sendBytes[0]=0x41;
        sendBytes[1]=0x42;
        iRet = [self syncSendReceive:[NSData dataWithBytes:sendBytes length:2] receivedBuff:receiveBytes timeout:TIMEOUT];

        if(iRet < 0) {
            //接收数据超时
            NSLog(@"接收数据超时，升级出错");
            dispatch_async(dispatch_get_main_queue(), ^{
                [_statusLog setText:NSLocalizedString(@"stopUpdate", nil)];
                ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"updateFailbyTimeout", nil) message:NSLocalizedString(@"stopUpdate", nil) viewController:self];
                
                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                    
                }];
                [alertView addButton:okItem type:RIButtonItemType_Destructive];
                [alertView show];
            });
            
            
            isUpdating = NO;
            return;
        }
        
        retCode = receiveBytes[2];
        if (retCode != 0x03) {
            //启动升级程序失败
            NSLog(@"启动升级程序失败");
            dispatch_async(dispatch_get_main_queue(), ^{
                [_statusLog setText:NSLocalizedString(@"stopUpdate", nil)];
                ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"ACKError", nil) message:NSLocalizedString(@"stopUpdate", nil) viewController:self];
                
                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                    
                }];
                [alertView addButton:okItem type:RIButtonItemType_Destructive];
                [alertView show];
            });
            
            isUpdating = NO;
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
                NSString *str = [NSString stringWithFormat:@"%@ [进度:%%%d]",NSLocalizedString(@"tranferData", nil),(int)((float)((packnum-1)*customMTU)/(float)UnsenddataLength*100)];
                [_statusLog setText:str];
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
                //接收数据超时
                NSLog(@"接收数据超时");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_statusLog setText:@"接收ACK 5s超时了"];
                });
                isUpdating = NO;
                return;
            }
            
            retCode = receiveBytes[2];
            if (retCode!=0x03) {

                dispatch_async(dispatch_get_main_queue(), ^{
                    [_statusLog setText:NSLocalizedString(@"stopUpdate", nil)];
                    ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"ACKError", nil) message:NSLocalizedString(@"stopUpdate", nil) viewController:self];
                    
                    RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                        
                    }];
                    [alertView addButton:okItem type:RIButtonItemType_Destructive];
                    [alertView show];
                });
                
                isUpdating = NO;
                return;
            }
            
            
            
            packnum = receiveBytes[3]*256+receiveBytes[4];
            if ( packnum > (UnsenddataLength+customMTU-1)/customMTU ) {
                break;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *str = [NSString stringWithFormat:@"接收ACK 包号：%d,",packnum];
                [_statusLog setText:str];
            });
        }

        //发送结束升级包
        dispatch_async(dispatch_get_main_queue(), ^{
            [_statusLog setText:[NSString stringWithFormat:@"%@",NSLocalizedString(@"sendFinishCMD", nil)]];
        });
        
        memset(receiveBytes, 0, 50);
        iRet = [self syncSendReceive:[self packFinishData] receivedBuff:receiveBytes timeout:20];
        if (iRet<0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_statusLog setText:NSLocalizedString(@"stopUpdate", nil)];
                ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"updateFailbyTimeout", nil) message:NSLocalizedString(@"LastACKError", nil) viewController:self];
                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                    
                }];
                [alertView addButton:okItem type:RIButtonItemType_Destructive];
                [alertView show];
            });
            
            isUpdating = NO;
            return ;
        }
        
        retCode = receiveBytes[2];
        if(retCode==0x05)//成功
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_statusLog setText:NSLocalizedString(@"updateOK", nil)];
                ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"updateOK", nil) message:@"" viewController:self];
                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                    
                }];
                [alertView addButton:okItem type:RIButtonItemType_Cancel];
                [alertView show];
            });
            
        }else if(retCode==0x06)//失败
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_statusLog setText:NSLocalizedString(@"updateFail", nil)];
                ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"updateFail", nil) message:@"" viewController:self];
                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                    
                }];
                [alertView addButton:okItem type:RIButtonItemType_Destructive];
                [alertView show];
            });
        }
        isUpdating = NO;
    });
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [_statusLog setText:NSLocalizedString(@"startCommand", nil)];
        });
        
        Byte receiveBytes[50];
        Byte sendBytes[2];
        sendBytes[0]=0x41;
        sendBytes[1]=0x42;
        int iRet = [self syncSendReceive:[NSData dataWithBytes:sendBytes length:2] receivedBuff:receiveBytes timeout:TIMEOUT];
        
        if(iRet < 0) {
            //接收数据超时
            NSLog(@"接收数据超时，升级出错");
            dispatch_async(dispatch_get_main_queue(), ^{
                [_statusLog setText:NSLocalizedString(@"stopUpdate", nil)];
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
                [_statusLog setText:NSLocalizedString(@"stopUpdate", nil)];
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
                NSString *str = [NSString stringWithFormat:@"%@ [进度:%%%d]",NSLocalizedString(@"tranferData", nil),(int)((float)((packnum-1)*customMTU)/(float)UnsenddataLength*100)];
                [_statusLog setText:str];
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
                //接收数据超时
                NSLog(@"接收数据超时");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_statusLog setText:@"接收ACK 5s超时了"];
                });
                isUpdating = NO;
                [self setButtonEnable:YES];
                return;
            }
            
            retCode = receiveBytes[2];
            if (retCode!=0x03) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_statusLog setText:NSLocalizedString(@"stopUpdate", nil)];
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
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *str = [NSString stringWithFormat:@"接收ACK 包号：%d,",packnum];
                [_statusLog setText:str];
            });
        }
        
        //发送结束升级包
        dispatch_async(dispatch_get_main_queue(), ^{
            [_statusLog setText:[NSString stringWithFormat:@"%@",NSLocalizedString(@"sendFinishCMD", nil)]];
        });
        
        memset(receiveBytes, 0, 50);
        iRet = [self syncSendReceive:[self packFinishData] receivedBuff:receiveBytes timeout:20];
        if (iRet<0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_statusLog setText:NSLocalizedString(@"stopUpdate", nil)];
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
                [_statusLog setText:NSLocalizedString(@"updateOK", nil)];
                ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"updateOK", nil) message:@"" viewController:self];
                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                    
                }];
                [alertView addButton:okItem type:RIButtonItemType_Cancel];
                [alertView show];
            });
            
        }else if(retCode==0x06)//失败
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_statusLog setText:NSLocalizedString(@"updateFail", nil)];
                ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"updateFail", nil) message:@"" viewController:self];
                RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                    
                }];
                [alertView addButton:okItem type:RIButtonItemType_Destructive];
                [alertView show];
            });
        }
        isUpdating = NO;
        [self setButtonEnable:YES];
    });
 }

-(BOOL)DownloadHexFile
{
    if (isDownloading==YES) {
        return NO;
    }
    [_statusLog setText:NSLocalizedString(@"downloading", nil)];
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
                [_statusLog setText:NSLocalizedString(@"downloadOK", nil)];
            });
            
            //将Data存在持久化。
            [data writeToFile:[self saveFilePath:DBNAME] atomically:YES];
            [[NSUserDefaults standardUserDefaults] setObject:RVersion forKey:@"Lversion"];//更新本地文件为远程文件版本
            Lversion = RVersion;
            isDownloading = NO;
        }
    }];
    return NO;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //可能需要停止更新固件
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    UILongPressGestureRecognizer *longPress=[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(force2update:)];
    longPress.minimumPressDuration=0.6;//定义按的时间
    [_updateFirware addGestureRecognizer:longPress];
    
    Lversion = [[NSUserDefaults standardUserDefaults] objectForKey:@"Lversion"];
    if (Lversion==nil) {
        Lversion = @"0.0";
    }

    gl_supportUpdateProtocol = 1;
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

-(void)check2Update
{
    //查询远程远程服务器版本
    [_statusLog setText:NSLocalizedString(@"isCheckingRomoteVersion", nil)];
    
    //查找GameScore表
    BmobQuery  *bquery = [BmobQuery queryWithClassName:@"GL_Firmware"];
    //查找GameScore表里面id为0c6db13c的数据
    [bquery getObjectInBackgroundWithId:@"LXjr666H" block:^(BmobObject *object,NSError *error){
        if (error){
            //进行错误处理
            
            //弹窗：请看到远程版本号后再操作！
            ZBHAlertViewController *alertView = [[ZBHAlertViewController alloc] initWithTitle:NSLocalizedString(@"checkRemoteVersionFail", nil) message:NSLocalizedString(@"checkNetwork", nil) viewController:self];
            
            RIButtonItem *okItem = [RIButtonItem itemWithLabel:NSLocalizedString(@"makeSure", nil) action:^{
                [_statusLog setText:NSLocalizedString(@"checkRemoteVersionFail", nil)];
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
                
                //更新UI
                [_statusLog setText:NSLocalizedString(@"CheckRomoteVersionOK", nil)];
                [_remoteVersion setText:RVersion];
                
                if ([RVersion floatValue]>[Lversion floatValue]) {
                    [self DownloadHexFile];
                }
            }
        }
        [self setButtonEnable:YES];
        
    }];
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
    [_manufacturer setText:@"N/A"];
    [_model setText:@"N/A"];
    [_serialNum setText:@"N/A"];
    [_revision setText:@"N/A"];
    [_LocalVersion setText:@"N/A"];
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
                int length = [_recevicedData length];
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
        _LocalVersion.text = _selectedAccessory.firmwareRevision;
        _productName.text = _selectedAccessory.name;
        _manufacturer.text = _selectedAccessory.manufacturer;
        _model.text = _selectedAccessory.modelNumber;
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
            _LocalVersion.text = _selectedAccessory.firmwareRevision;
            DVersion = _selectedAccessory.firmwareRevision;//设备固件版本
            _productName.text = _selectedAccessory.name;
            _manufacturer.text = _selectedAccessory.manufacturer;
            _model.text = _selectedAccessory.modelNumber;
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
    // Dispose of any resources that can be recreated.
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
