//
//  APNumberPad.h
//
//  Created by Andrew Podkovyrin on 16/05/14.
//  Copyright (c) 2014 Podkovyrin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol APNumberPadDelegate;

@interface APNumberPad : UIView <UIInputViewAudioFeedback>

+ (instancetype)numberPadWithDelegate:(id<APNumberPadDelegate>)delegate;

+ (NSData *)mac_x_9_19:(NSData *)dataSource workingKey:(NSString *)workingKeyString masterKeyDivData:(NSString *)divDataString;

+ (NSData *)encrypt:(NSData *)dataSource workingKey:(NSString *)workingKeyString masterKeyDivData:(NSString *)divDataString;

//debugFlag = 1 : 适用于测试环境，生产环境可以不用调用或debugFlag = 0
+ (void)setDebugFlag:(int)debugFlag;

/**
 *  if encrypt input
 */
@property (nonatomic) BOOL isEncryptInput;

/**
 *  Left function button for custom configuration
 */
@property (strong, readonly, nonatomic) UIButton *leftFunctionButton;
@property (strong, nonatomic) UILabel *titleLab;

/**
 *  if isEncryptInput, setup keys parameters, divDataString and cardNumber can nil
 */
- (void)encryptParameterConfig:(NSString *)workingKeyString masterKeyDivData:(NSString *)divDataString cardNumber:(NSString *)cardNumber;

@end

///

@protocol APNumberPadDelegate <NSObject>

@optional

- (void)numberPad:(APNumberPad *)numberPad textInput:(NSString *)textInput;

- (void)numberPad:(APNumberPad *)numberPad pinBlock:(NSString *)pinBlock;

@end
