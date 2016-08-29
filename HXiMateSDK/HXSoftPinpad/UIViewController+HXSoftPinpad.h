//
//  UIViewController+HXSoftPinpad.h
//  HXiMateSDK
//
//  Created by hxsmart on 14-6-17.
//  Copyright (c) 2014年 hxsmart. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HXSoftPinpadDelegate <NSObject>
@optional

/**
 *  操作软键盘回调结果
 *
 *  @param flag 是否完成软键盘输入
 *  @param data 当 falg 为YES时，data为软键盘加密数据, 否则为错误信息
 */
- (void)hxSoftPinpadFinished:(BOOL)flag data:(NSString *)data;

@end


@interface UIViewController (HXSoftPinpad)

@property (nonatomic) id<HXSoftPinpadDelegate>pinpadDelegate;

/*
 显示软键盘并输入密码，由 hxSoftPinpadFinished 返回输入的结果，输出的密文 Pinblock 使用X9.8算法。
 @param placeholderText 输入栏提示内容
 @param minLength       最少输入位数
 @param maxLength       最多输入位数
 @param workingKey      签到时获得的工作密钥或PinKey(密文), 32字节长度, 当为nil时，输出明文pin。
 @param cardNo          卡号或帐号，最少13位。如果nil，默认为13个'0'。
 
 */
- (void)showHXSoftPinpad:(NSString *)placeholderText minLength:(int)minLength maxLength:(int)maxlength workingKey:(NSString *)workingKey cardNo:(NSString *)cardNo;

@end
