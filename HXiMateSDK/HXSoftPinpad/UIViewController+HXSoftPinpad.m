//
//  UIViewController+HXSoftPinpad.m
//  HXiMateSDK
//
//  Created by hxsmart on 14-6-17.
//  Copyright (c) 2014年 hxsmart. All rights reserved.
//

#import "UIViewController+HXSoftPinpad.h"
#import "UIViewController+HxMJPopupViewController.h"
#import <objc/runtime.h>
#import "SoftKeyboard.h"

extern NSData *gl_masterKeyFromDevice;

@implementation UIViewController (HXSoftPinpad)

@dynamic pinpadDelegate;

- (id<HXSoftPinpadDelegate>)pinpadDelegate
{
    return objc_getAssociatedObject(self, @"pinpadDelegate");
}

- (void)setPinpadDelegate:(id<HXSoftPinpadDelegate>)delegate
{
    objc_setAssociatedObject(self, @"pinpadDelegate", delegate,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/*
 显示软键盘并输入密码，由 hxSoftPinpadFinished 返回输入的结果，输出的密文 Pinblock 使用X9.8算法。
 @param placeholderText 输入栏提示内容
 @param minLength       最少输入位数
 @param maxLength       最多输入位数
 @param workingKey      签到时获得的工作密钥或PinKey(密文), 32字节长度, 当为nil时，输出明文pin。
 @param cardNo          卡号或帐号，最少13位。如果nil，默认为13个'0'。
 
 @ret   0               成功
        1               参数错误
        2               无法解密WorkingKey
 */
- (void)showHXSoftPinpad:(NSString *)placeholderText minLength:(int)minLength maxLength:(int)maxlength workingKey:(NSString *)workingKey cardNo:(NSString *)cardNo
{
    static SoftKeyboard *softKeyboard = nil;
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@(maxlength), @"maxLength", @(minLength), @"minLength", placeholderText, @"text", workingKey, @"workingKey", cardNo, @"cardNo", nil];
    
    softKeyboard = [[SoftKeyboard alloc] init];
	[softKeyboard setDelegate:(id<SoftKeyboardDelegate>)self];
    
	if ([softKeyboard showSoftKeyboard:dict]) {
        [self presentPopupViewController:softKeyboard animationType:HxMJPopupViewAnimationFade];
    }
}

#pragma mark -- SoftKeyboardDelegate
- (void)softKeyboardFinish:(BOOL)flag data:(NSString *)data
{
    [self dismissPopupViewControllerWithanimationType:HxMJPopupViewAnimationFade];

    if([self.pinpadDelegate respondsToSelector:@selector(hxSoftPinpadFinished:data:)]){
        [self.pinpadDelegate hxSoftPinpadFinished:flag data:data];
    }
}




@end
