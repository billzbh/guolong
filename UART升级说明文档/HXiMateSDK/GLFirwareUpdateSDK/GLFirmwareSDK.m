//
//  GLFirmwareSDK.m
//  HXiMateSDK
//
//  Created by zbh on 16/8/29.
//  Copyright © 2016年 hxsmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLFirmwareSDK.h"
#import <ExternalAccessory/ExternalAccessory.h>
#import "EADSessionController.h"

#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define PROTOCOL_STRING_IMATE   @"com.insta360.guolong"
#define DBNAME @"guolong.hex"
#define SEND_MTU 32
#define TIMEOUT 5

@interface GLFirmwareSDK ()
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
    
    NSMutableArray *_accessoryList;
    BOOL isDeviceConnected;
    EAAccessory *_selectedAccessory;
    EADSessionController *_eaSessionController;
    
    NSMutableData *recevicedData;
    
}

@end

@implementation GLFirmwareSDK


+ (GLFirmwareSDK *)getInstance
{
    static GLFirmwareSDK *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GLFirmwareSDK alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        isUpdating = NO;
        isDownloading = NO;
        isDeviceConnected = NO;
        recevicedData = [[NSMutableData alloc] init];
        [recevicedData setLength:0];
        
        //监听通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidConnect:) name:EAAccessoryDidConnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidDisconnect:) name:EAAccessoryDidDisconnectNotification object:nil];
        
        // watch for received data from the accessory
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_sessionDataReceived:) name:EADSessionDataReceivedNotification object:nil];
        
        [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    }
    return self;
}


//耳机设备是否已经建立连接
-(BOOL)isDeviceConnected
{
    return isDeviceConnected;
}

//耳机设备是否已插入
-(BOOL)isDevicePlugIn
{
    //查询设备
    _eaSessionController = [EADSessionController sharedController];
    _accessoryList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
    for (EAAccessory *accessory in _accessoryList) {
        //NSLog(@"accessory = %@",accessory);
        
        if ( ![[accessory protocolStrings] count] ) {
            continue;
        }
#ifdef DEBUG
        NSLog(@"%@",[accessory protocolStrings]);
#endif
        
        if ([[accessory protocolStrings] containsObject:PROTOCOL_STRING_IMATE]) {
            return YES;
        }
    }
    return NO;
}

-(NSDictionary*)getDeviceInfo
{
    //查询设备
    _eaSessionController = [EADSessionController sharedController];
    _accessoryList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
    for (EAAccessory *accessory in _accessoryList) {
        //NSLog(@"accessory = %@",accessory);
        
        if ( ![[accessory protocolStrings] count] ) {
            continue;
        }
#ifdef DEBUG
        NSLog(@"%@",[accessory protocolStrings]);
#endif
        
        if ([[accessory protocolStrings] containsObject:PROTOCOL_STRING_IMATE]) {
            NSDictionary *dict = [[NSDictionary alloc] init];
            [dict ]
            return YES;
        }
    }
    return NO;

}




@end
