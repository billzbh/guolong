//
//  ViewController.m
//  updateFirmware
//
//  Created by zbh on 16/4/27.
//  Copyright © 2016年 hxsmart. All rights reserved.
//

#import "ViewController.h"
#import "EADSessionController.h"

#define PROTOCOL_STRING_IMATE   @"com.insta360.guolong"


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *text;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [_text setText:NSLocalizedString(@"pleasePluginDevice", nil)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidConnect:) name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidDisconnect:) name:EAAccessoryDidDisconnectNotification object:nil];
    
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    
        //查询是否有 耳机的设备
        NSMutableArray *accessoryList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
        
        for (EAAccessory *accessory in accessoryList) {
            if([[accessory protocolStrings] containsObject:PROTOCOL_STRING_IMATE])
            {
                //跳转
                //转到工作界面
                UIStoryboard *board = [UIStoryboard storyboardWithName: @"Main" bundle: nil];
                UIViewController* childController = [board instantiateViewControllerWithIdentifier: @"tabbarViewcontroller"];
                [self presentViewController:childController animated:YES completion:nil];
            }
        }
        
    });
    
}

- (void)_accessoryDidDisconnect:(NSNotification *)notification{
    
}

- (void)_accessoryDidConnect:(NSNotification *)notification {
    EAAccessory *connectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    if ( ![[connectedAccessory protocolStrings] count] ) {
        return;
    }
    
    if ([[connectedAccessory protocolStrings] containsObject:PROTOCOL_STRING_IMATE]) {
        //跳转
        //转到工作界面
        UIStoryboard *board = [UIStoryboard storyboardWithName: @"Main" bundle: nil];
        UIViewController* childController = [board instantiateViewControllerWithIdentifier: @"tabbarViewcontroller"];
        [self presentViewController:childController animated:YES completion:nil];
    }
}



-(void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidDisconnectNotification object:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
