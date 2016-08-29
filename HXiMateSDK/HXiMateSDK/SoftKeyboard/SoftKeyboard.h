//
//  SoftKeyboard.h
//  SoftKeyboard
//
//  Created by liuym on 14-6-13.
//  Copyright (c) 2014年 liuym. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SoftKeyboardDelegate <NSObject>
@optional

/**
 *  操作软键盘回调结果
 *
 *  @param flag 是否完成软键盘输入
 *  @param data 当 falg 为YES时，data为软键盘加密数, 否则data为错误信息
 */
- (void)softKeyboardFinish:(BOOL)flag data:(NSString *)data;

/**
 *  当flag为YES时, 显示软键盘
 *
 *  @param flag 是否显示软键盘
 *  @param data 当 falg 为YES时，data为nil, 否则data为错误信息
 */
- (void)showKeyboard:(BOOL)flag data:(NSString *)data;

@end

@interface SoftKeyboard : UIViewController

/**
 *  单例对象
 *
 *  @return SoftKeyboard对象
 */
+ (SoftKeyboard *)shareSoftKeyboard;

@property (nonatomic) id<SoftKeyboardDelegate>delegate;


/**
 *  设置软键盘参数
 *
 *  @param dict dict的key值为 maxLength, minLength, text, working和 cardNo(可选)
 */
- (void)showSoftKeyboard:(NSDictionary *)dict;

@end
