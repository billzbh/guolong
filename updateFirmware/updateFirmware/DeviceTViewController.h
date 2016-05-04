//
//  DeviceViewController.h
//  updateFirmware
//
//  Created by zbh on 16/4/27.
//  Copyright © 2016年 hxsmart. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ExternalAccessory/ExternalAccessory.h>

@class EADSessionController;


@interface DeviceTViewController : UITableViewController
{
    NSMutableArray *_accessoryList;
    BOOL isDeviceConnected;
    EAAccessory *_selectedAccessory;
    EADSessionController *_eaSessionController;
}
@end
