//
//  ZBHAlertViewController.h
//  ktvDEMO
//
//  Created by zbh on 16/4/26.
//  Copyright © 2016年 hxsmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RIButtonItem.h"
#import <UIKit/UIKit.h>

typedef enum {
    RIButtonItemType_Cancel         = 1,
    RIButtonItemType_Destructive       ,
    RIButtonItemType_Other
}RIButtonItemType;

typedef enum {
    BOAlertControllerType_AlertView    = 1,
    BOAlertControllerType_ActionSheet
}BOAlertControllerType;

#define isIOS8  ([[[UIDevice currentDevice]systemVersion]floatValue]>=8)


@interface ZBHAlertViewController : NSObject
- (id)initWithTitle:(NSString *)title message:(NSString *)message viewController:(UIViewController *)inViewController;
- (void)addButton:(RIButtonItem *)button type:(RIButtonItemType)itemType;

//Show ActionSheet in all versions
- (void)showInView:(UIView *)view;

//Show AlertView in all versions
- (void)show;
@end
