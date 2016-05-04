//
//  ZBInputAlertViewController.h
//  ktvDEMO
//
//  Created by zbh on 16/4/26.
//  Copyright © 2016年 hxsmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define isIOS8  ([[[UIDevice currentDevice]systemVersion]floatValue]>=8)

typedef void (^actionText)(NSString *PlainText);

@interface ZBInputAlertViewController : NSObject

//Show AlertView with inputTextField in all versions
- (void)showWithAction:(actionText)action;

- (id)initWithTitle:(NSString *)title message:(NSString *)message TextFieldHint:(NSString*)hint TextFieldcontentText:(NSString*)contentText viewController:(UIViewController *)inViewController;


@end
