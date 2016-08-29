//
//  SoftKeyboard.m
//  SoftKeyboard
//
//  Created by liuym on 14-6-13.
//  Copyright (c) 2014年 liuym. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <Security/Security.h>

#import "SoftKeyboard.h"
#import "Toast.h"
static SoftKeyboard *softKeyboard = nil;

@interface SoftKeyboard()<UITextFieldDelegate>{
	int maxLength;
	int minLength;
    int buttonValue[10];
    BOOL randkeyboard;
}

@property (nonatomic, strong) IBOutlet UITextField *inputText;

@property (nonatomic, strong) NSString *workingKey;
@property (nonatomic, strong) NSString *cardNo;
@property (nonatomic, strong) NSString *placeholder;
@property (atomic) BOOL isPinblock;

@property (nonatomic, strong) IBOutlet UIButton *button0;
@property (nonatomic, strong) IBOutlet UIButton *button1;
@property (nonatomic, strong) IBOutlet UIButton *button2;
@property (nonatomic, strong) IBOutlet UIButton *button3;
@property (nonatomic, strong) IBOutlet UIButton *button4;
@property (nonatomic, strong) IBOutlet UIButton *button5;
@property (nonatomic, strong) IBOutlet UIButton *button6;
@property (nonatomic, strong) IBOutlet UIButton *button7;
@property (nonatomic, strong) IBOutlet UIButton *button8;
@property (nonatomic, strong) IBOutlet UIButton *button9;

@end

@implementation SoftKeyboard

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    randkeyboard = YES;
    for (int i = 0; i < 10; i++)
        buttonValue[i] = i;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	_inputText.placeholder = _placeholder;
    
    if (randkeyboard) [self genRandArray];

    [_button0 setTitle:[NSString stringWithFormat:@"%d", buttonValue[0]] forState:UIControlStateNormal];
    [_button1 setTitle:[NSString stringWithFormat:@"%d", buttonValue[1]] forState:UIControlStateNormal];
    [_button2 setTitle:[NSString stringWithFormat:@"%d", buttonValue[2]] forState:UIControlStateNormal];
    [_button3 setTitle:[NSString stringWithFormat:@"%d", buttonValue[3]] forState:UIControlStateNormal];
    [_button4 setTitle:[NSString stringWithFormat:@"%d", buttonValue[4]] forState:UIControlStateNormal];
    [_button5 setTitle:[NSString stringWithFormat:@"%d", buttonValue[5]] forState:UIControlStateNormal];
    [_button6 setTitle:[NSString stringWithFormat:@"%d", buttonValue[6]] forState:UIControlStateNormal];
    [_button7 setTitle:[NSString stringWithFormat:@"%d", buttonValue[7]] forState:UIControlStateNormal];
    [_button8 setTitle:[NSString stringWithFormat:@"%d", buttonValue[8]] forState:UIControlStateNormal];
    [_button9 setTitle:[NSString stringWithFormat:@"%d", buttonValue[9]] forState:UIControlStateNormal];
}

+ (SoftKeyboard *)shareSoftKeyboard
{
	if(softKeyboard == nil) {
		//NSArray *nib = [[NSBundle mainBundle]loadNibNamed:@"SoftKeyboard" owner:self options:nil];
		//UIView *tmpCustomView = [nib objectAtIndex:0];
		//[self.]
		//softKeyboard = (SoftKeyboard *)tmpCustomView;//[[SoftKeyboard alloc] init];
		softKeyboard = [[SoftKeyboard alloc] init];
	}
	return softKeyboard;
}

- (void)setRandkeyboard:(BOOL)mode
{
    randkeyboard = mode;
}

- (IBAction)operatorPress:(UIButton *)button
{
	switch (button.tag) {
		case 1010:
			break;
		case 1011:
			[_inputText setText:@""];
			break;
		case 1020:
			[_inputText setText:@""];
			[self.delegate softKeyboardFinish:NO data:@"输入取消"];
			break;
		case 1021:{
			if(_inputText.text.length > minLength && _inputText.text.length < maxLength){
				//NSLog(@"输入合法的长度");
				[Toast showWithText:self.view text:@"输入密码长度不合法" duration:1.0f];
				return;
			}
			NSString *pin = _inputText.text;
			[_inputText setText:@""];
			[self enterButton:pin];
			break;
		}
		default:
			break;
	}
}

- (IBAction)numKeyPress:(UIButton *)button
{
	if(_inputText.text.length >= maxLength) {
		NSLog(@"最大长度");
		return;
	}
    [_inputText setText:[NSString stringWithFormat:@"%@%@", _inputText.text, button.titleLabel.text]];
    NSLog(@"%@", _inputText.text);

    /*
	switch (button.tag) {
		case 1000:
			[_inputText setText:[NSString stringWithFormat:@"%@0", _inputText.text]];
			break;
		case 1001:
			[_inputText setText:[NSString stringWithFormat:@"%@1", _inputText.text]];
			break;
		case 1002:
			[_inputText setText:[NSString stringWithFormat:@"%@2", _inputText.text]];
			break;
		case 1003:
			[_inputText setText:[NSString stringWithFormat:@"%@3", _inputText.text]];
			break;
		case 1004:
			[_inputText setText:[NSString stringWithFormat:@"%@4", _inputText.text]];
			break;
		case 1005:
			[_inputText setText:[NSString stringWithFormat:@"%@5", _inputText.text]];
			break;
		case 1006:
			[_inputText setText:[NSString stringWithFormat:@"%@6", _inputText.text]];
			break;
		case 1007:
			[_inputText setText:[NSString stringWithFormat:@"%@7", _inputText.text]];
			break;
		case 1008:
			[_inputText setText:[NSString stringWithFormat:@"%@8", _inputText.text]];
			break;
		case 1009:
			[_inputText setText:[NSString stringWithFormat:@"%@9", _inputText.text]];
			break;
		default:
			break;
	}
     */
}

- (void)enterButton:(NSString *)text
{
	NSData *key = [self twoOneData:_workingKey];
	NSData *data = [self threeDes:kCCEncrypt data:[text dataUsingEncoding:NSUTF8StringEncoding] key:key];
	if(data){
		[self.delegate softKeyboardFinish:YES data:[self oneTwoData:data]];
	}else{
		[self.delegate softKeyboardFinish:NO data:@"加密失败"];
	}
}

- (void)genRandArray
{
    int a[10];
    for (int i = 0; i < 10; i++)
        a[i] = i;
    srand((unsigned)time(0));
    for (int i = 0; i < 10;) {
        int index=rand()%10;
        if (a[index] != -1) {
            buttonValue[i] = a[index];
            a[index] = -1;
            i++;
        }
    }
}


- (void)showSoftKeyboard:(NSDictionary *)dict
{
	if([self isContainsKey:dict.allKeys key:@"minLength, maxLength, text, workingKey"]){
		maxLength = [[dict objectForKey:@"maxLength"] intValue];
		minLength = [[dict objectForKey:@"minLength"] intValue];
		_workingKey = [dict objectForKey:@"workingKey"];
		_isPinblock = false;
		if([self isContainsKey:dict.allKeys key:@"cardNo"]){
			NSString *cardNum = [dict objectForKey:@"cardNo"];
			if(cardNum.length >= 13){
				_cardNo = [NSString stringWithFormat:@"0000%@", [cardNum substringWithRange:NSMakeRange(cardNum.length - 12 - 1, 12)]];
				_isPinblock = true;
			}else{
				[self.delegate showKeyboard:NO data:@"卡号长度错误"];
				return;
			}
		}
		_placeholder = [dict objectForKey:@"text"];
		[self.delegate showKeyboard:YES data:nil];
	}else{
		[self.delegate showKeyboard:NO data:@"参数错误"];
	}
}

- (void)finish:(BOOL)flag data:(NSString *)data
{
	if([_delegate respondsToSelector:@selector(softKeyboardFinish:data:)]){
		[_delegate softKeyboardFinish:flag data:data];
	}
}

- (BOOL)isContainsKey:(NSArray *)allKeys key:(NSString *)multieKey
{
    NSString *str = [multieKey stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSArray *array = [str componentsSeparatedByString:@","];
    if(array.count){
        for(NSString *key in array){
            if(![allKeys containsObject:key]){
                return NO;
            }
        }
    }
    return YES;
}

- (NSData *)threeDes:(CCOperation )encryptType data:(NSData *)data key:(NSData *)key
{
	NSMutableData *threeDesData = [NSMutableData data];
	if(_isPinblock == true && encryptType == kCCEncrypt){
		NSString *pinStr = [NSString stringWithFormat:@"%02X", data.length];
		pinStr = [NSString stringWithFormat:@"%@%@", pinStr, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
		for(int i = pinStr.length; i < 16; i++){
			pinStr = [NSString stringWithFormat:@"%@F", pinStr];
		}
		Byte *cardNoByte = (Byte *)[[self twoOneData:_cardNo] bytes];
		Byte *pinStrByte = (Byte *)[[self twoOneData:pinStr] bytes];
		Byte pinBytes[8];
		for(int i = 0; i < 8; i++){
			pinBytes[i] = (cardNoByte[i] ^ pinStrByte[i]);
		}
		[threeDesData appendBytes:pinBytes length:8];
	}else{
		[threeDesData appendData:data];
		for(int i = data.length; i < (data.length == 0 ? 8 : ((data.length - 1)/8 + 1) * 8); i++){
			[threeDesData appendBytes:(const void *)"\x00" length:1];
		}
	}
	size_t inDataLength = [threeDesData length];
	const void *inText = (const void *)[threeDesData bytes];
	
	NSMutableData *threeDesKey = [[NSMutableData alloc] init];
	[threeDesKey appendData:key];
	[threeDesKey appendBytes:[key bytes] length:8];
	
	const void *desKey = [threeDesKey bytes];
	//const void *vinitVec = (const void *) [@"01234567" UTF8String];
	
	CCCryptorStatus ccStatus;
	uint8_t *outBuffer = NULL;
    size_t outBufferLength = 0;
    size_t outBytesLength = 0;
    
    outBufferLength = (inDataLength + kCCBlockSize3DES) & ~(kCCBlockSize3DES - 1);
    outBuffer = malloc( outBufferLength * sizeof(uint8_t));
    memset((void *)outBuffer, 0x0, outBufferLength);
	ccStatus = CCCrypt(encryptType,
                       kCCAlgorithm3DES,
                       kCCOptionECBMode,
                       desKey,
                       kCCKeySize3DES,
                       nil,
                       inText,
                       inDataLength,
                       (void *)outBuffer,
                       outBufferLength,
                       &outBytesLength);
	if(ccStatus == kCCSuccess)
		return [NSData dataWithBytes:(const void *)outBuffer length:(NSUInteger)outBytesLength];
	return nil;
}

/*- (NSData *)decrypt:(NSData *)decData withKey:(NSData *)key
{
    size_t decDataLength = [decData length];
    const void *decText = (const void *)[decData bytes];
	
	NSMutableData *threeDesKey = [[NSMutableData alloc] init];
	[threeDesKey appendData:key];
	[threeDesKey appendBytes:[key bytes] length:8];
	
	const void *desKey = [threeDesKey bytes];
	//const void *vinitVec = (const void *) [@"01234567" UTF8String];
	
	CCCryptorStatus ccStatus;
	uint8_t *decOutBuffer = NULL;
    size_t decOutBufferLength = 0;
    size_t decOutBytesLength = 0;
    
    decOutBufferLength = (decDataLength + kCCBlockSize3DES) & ~(kCCBlockSize3DES - 1);
    decOutBuffer = malloc( decOutBufferLength * sizeof(uint8_t));
    memset((void *)decOutBuffer, 0x0, decOutBufferLength);
	
	ccStatus = CCCrypt(kCCDecrypt,
                       kCCAlgorithm3DES,
                       kCCOptionECBMode,
                       desKey,
                       kCCKeySize3DES,
                       nil,
                       decText,
                       decDataLength,
                       (void *)decOutBuffer,
                       decOutBufferLength,
                       &decOutBytesLength);
	if(ccStatus == kCCSuccess)
		return [NSData dataWithBytes:(const void *)decOutBuffer length:(NSUInteger)decOutBytesLength];
	return nil;
}*/

-(NSString *)oneTwoData:(NSData *)sourceData
{
    Byte *inBytes = (Byte *)[sourceData bytes];
    NSMutableString *resultData = [[NSMutableString alloc] init];
    
    for(NSInteger counter = 0; counter < [sourceData length]; counter++)
        [resultData appendFormat:@"%02X",inBytes[counter]];
    
    return resultData;
}

-(NSData *)twoOneData:(NSString *)sourceString
{
    Byte tmp, result;
    Byte *sourceBytes = (Byte *)[sourceString UTF8String];
    
    NSMutableData *resultData = [[NSMutableData alloc] init];
    
    for(NSInteger i=0; i<strlen((char*)sourceBytes); i+=2) {
        tmp = sourceBytes[i];
        if(tmp > '9')
            tmp = toupper(tmp) - 'A' + 0x0a;
        else
            tmp &= 0x0f;
        
        result = tmp <<= 4;
        
        tmp = sourceBytes[i+1];
        if(tmp > '9')
            tmp = toupper(tmp) - 'A' + 0x0a;
        else
            tmp &= 0x0f;
        result += tmp;
        [resultData appendBytes:&result length:1];
    }
    
    return resultData;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	NSLog(@"should = %d,%d, string = %@", range.length, range.location, string);
	return YES;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	NSLog(@"textFieldDidBeginEditing");
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	NSLog(@"textFieldDidEndEditing");
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	NSLog(@"textFieldShouldBeginEditing");
	return NO;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
	NSLog(@"textFieldShouldEndEditing");
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	NSLog(@"textFieldShouldClear");
	return YES;
}

@end
