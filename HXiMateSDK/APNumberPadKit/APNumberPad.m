//
//  APNumberPad.m
//
//
//  Modified by Qingbo Jia at 24/4/15.
//  Created by Andrew Podkovyrin on 16/05/14.
//  Copyright (c) 2014 Podkovyrin. All rights reserved.
//

#import "APNumberPad.h"

#import "APNumberButton.h"
#import "APNumberPad+Style.h"
#import "PinpadFunctions.h"
#import "VposFace.h"

static char sg_APNumberPadSecurityPin[15];

@interface APNumberPad () {
    BOOL _clearButtonLongPressGesture;
    BOOL _functionButtonActionFlag;
	struct {
        unsigned int textInputSupportsShouldChangeTextInRange:1;
		unsigned int delegateSupportsTextFieldShouldChangeCharactersInRange:1;
		unsigned int delegateSupportsTextViewShouldChangeTextInRange:1;
	} _delegateFlags;
}

/**
 *  Array of APNumberButton
 */
@property (copy, readwrite, nonatomic) NSArray *numberButtons;

/**
 *  Left function button
 */
@property (strong, readwrite, nonatomic) APNumberButton *leftButton;

/**
 *  Right function button
 */
@property (strong, readwrite, nonatomic) APNumberButton *clearButton;

/**
 *  clearImageView
 */
@property (strong, nonatomic) UIImageView *clearImageView;

/**
 *  APNumberPad delegate
 */
@property (weak, readwrite, nonatomic) id<APNumberPadDelegate> delegate;

/**
 *  Auto-detected text input
 */
@property (weak, readwrite, nonatomic) UIResponder<UITextInput> *textInput;

/**
 *  Last touch on view. For support tap by tap entering text
 */
@property (weak, readwrite, nonatomic) UITouch *lastTouch;

@property (strong, nonatomic) NSString *workingKeyString;
@property (strong, nonatomic) NSString *divDataString;
@property (strong, nonatomic) NSString *accountString;

@end


@implementation APNumberPad

+ (instancetype)numberPadWithDelegate:(id<APNumberPadDelegate>)delegate {
    return [[self alloc] initWithDelegate:delegate];
}

+ (NSData *)mac_x_9_19:(NSData *)dataSource workingKey:(NSString *)workingKeyString masterKeyDivData:(NSString *)divDataString
{
    if (workingKeyString == nil || workingKeyString.length != 32) {
        return nil;
    }
    
//    Byte workingKeyOut[16];
//    if (iGenWorkingKey(workingKeyString.UTF8String, divDataString.UTF8String, workingKeyOut)) {
//        return nil;
//    }
    
//    [APNumberPad writeHexLog:@"workingKeyOut" hexData:workingKeyOut length:16];
    
    Byte macOut[8];
    if (iMac_X9_19(workingKeyString.UTF8String, divDataString.UTF8String, (unsigned char*)dataSource.bytes, (int)dataSource.length, macOut))
        return nil;
    
    return [NSData dataWithBytes:macOut length:4];
}

+ (NSData *)encrypt:(NSData *)dataSource workingKey:(NSString *)workingKeyString masterKeyDivData:(NSString *)divDataString
{
    if (workingKeyString == nil || workingKeyString.length != 32) {
        return nil;
    }
    
//    Byte workingKeyOut[16];
//    if (iGenWorkingKey(workingKeyString.UTF8String, divDataString.UTF8String, workingKeyOut)) {
//        return nil;
//    }
//    
//    [APNumberPad writeHexLog:@"workingKeyOut" hexData:workingKeyOut length:16];
    
    int outLength = (int)((dataSource.length + 7) / 8) * 8;
    Byte dataOut[outLength];
    if (iEncrypt(workingKeyString.UTF8String, divDataString.UTF8String, (unsigned char*)dataSource.bytes, (int)dataSource.length, dataOut))
        return nil;
    
    return [NSData dataWithBytes:dataOut length:outLength];
}

+ (void)setDebugFlag:(int)debugFlag
{
    vSetDebugFlag(debugFlag);
}

- (instancetype)initWithDelegate:(id<APNumberPadDelegate>)delegate {
    self = [super initWithFrame:[[self class] numberPadFrame]];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight; // for support rotation
        self.backgroundColor = [[self class] numberPadBackgroundColor];
        
        [self addNotificationsObservers];
        
        self.delegate = delegate;
        
        // Number buttons (0-9)
        //
        NSMutableArray *numberButtons = [NSMutableArray array];
        for (int i = 0; i < 11; i++) {
            APNumberButton *numberButton = [[self class] numberButton:i];
            [self addSubview:numberButton];
            [numberButtons addObject:numberButton];
        }
        for (int i = 0; i < 10; i++) {
            int r = arc4random() % 9;
            [numberButtons exchangeObjectAtIndex:i withObjectAtIndex:r];
        }
        
        self.numberButtons = numberButtons;
        
        //titleLab
        self.titleLab = [[UILabel alloc]init];
        self.titleLab.textColor = [UIColor whiteColor];
        self.titleLab.font = [UIFont boldSystemFontOfSize:18];
        self.titleLab.text = NSLocalizedString(@"银行安全输入", nil);
        self.titleLab.textAlignment = NSTextAlignmentCenter;
        
        [self addSubview:self.titleLab];
        
        // Function button
        //
        self.leftButton = [[self class] functionButton];
        self.leftButton.titleLabel.font = [[self class] functionButtonFont];
        [self.leftButton setTitleColor:[[self class] functionButtonTextColor] forState:UIControlStateNormal];
        [self.leftButton addTarget:self action:@selector(functionButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.leftButton setBackgroundImage:[UIImage imageNamed:@"APNumberPadKitResources.bundle/apnnumberpad_keyboard_done"] forState:UIControlStateNormal];
        [self.leftButton setBackgroundImage:[UIImage imageNamed:@"APNumberPadKitResources.bundle/apnnumberpad_keyboard_done_press"] forState:UIControlStateHighlighted];
        [self addSubview:self.leftButton];
        
        // Clear button
        //
        self.clearButton = [[self class] functionButton];
        [self.clearButton setImage:[[self class] clearFunctionButtonImage] forState:UIControlStateNormal];
        [self.clearButton addTarget:self action:@selector(clearButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [self.clearButton setBackgroundImage:[UIImage imageNamed:@"APNumberPadKitResources.bundle/apnnumberpad_keyboard_delete"] forState:UIControlStateNormal];
        [self.clearButton setBackgroundImage:[UIImage imageNamed:@"APNumberPadKitResources.bundle/apnnumberpad_keyboard_delete_press"] forState:UIControlStateHighlighted];
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]
                                                                    initWithTarget:self action:@selector(longPressGestureRecognizerAction:)];
        longPressGestureRecognizer.cancelsTouchesInView = NO;
        [self.clearButton addGestureRecognizer:longPressGestureRecognizer];
        [self addSubview:self.clearButton];
        
        // Clear ImageView
        self.clearImageView = [[UIImageView alloc]init];
        //        self.clearImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.clearImageView.image = [UIImage imageNamed:@"APNumberPadKitResources.bundle/apnnumberpad_icn_delete"];
        [self addSubview:self.clearImageView];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    int rows = 4;
    int sections = 3;
    CGFloat titleLabHeight = 30;
    CGFloat sep = [[self class] separator] * 10;
    CGFloat left = sep;
    CGFloat top = sep + titleLabHeight;
    
    self.titleLab.frame = CGRectMake(left, 0, self.bounds.size.width, titleLabHeight);
#if defined(__LP64__) && __LP64__
    CGFloat buttonHeight = trunc((CGRectGetHeight(self.bounds) - titleLabHeight - sep * (rows + 1)) / rows) ;
#else
    CGFloat buttonHeight = truncf((CGRectGetHeight(self.bounds)- titleLabHeight - sep * (rows + 1)) / rows) ;
#endif
    
    CGSize buttonSize = CGSizeMake((CGRectGetWidth(self.bounds) - sep * (sections + 1)) / sections, buttonHeight);
    
    // Number buttons (1-9)
    //
    for (int i = 1; i < self.numberButtons.count - 1; i++) {
        APNumberButton *numberButton = self.numberButtons[i];
        numberButton.frame = CGRectMake(left, top, buttonSize.width, buttonSize.height);
        
        if (i % sections == 0) {
            left = sep;
            top += buttonSize.height + sep;
        } else {
            left += buttonSize.width + sep;
        }
    }
    
    //titleLab
    
    // Function button
    //
    left = sep;
    self.leftButton.frame = CGRectMake(left, top, buttonSize.width, buttonSize.height);
    
    // Number buttons (0)
    //
    left += buttonSize.width + sep;
    UIButton *zeroButton = self.numberButtons.firstObject;
    zeroButton.frame = CGRectMake(left, top, buttonSize.width, buttonSize.height);
    
    // Clear button
    //
    left += buttonSize.width + sep;
    self.clearButton.frame = CGRectMake(left, top, buttonSize.width, buttonSize.height);
    
    self.clearImageView.frame = CGRectMake(0, 0, 20, 15);
    self.clearImageView.center = self.clearButton.center;
}

#pragma mark - Notifications

- (void)addNotificationsObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidBeginEditing:)
                                                 name:UITextFieldTextDidBeginEditingNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidBeginEditing:)
                                                 name:UITextViewTextDidBeginEditingNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidEndEditing:)
                                                 name:UITextFieldTextDidEndEditingNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidEndEditing:)
                                                 name:UITextViewTextDidEndEditingNotification
                                               object:nil];
}

- (void)textDidBeginEditing:(NSNotification *)notification {
    if (![notification.object conformsToProtocol:@protocol(UITextInput)]) {
        return;
    }
    
    UIResponder<UITextInput> *textInput = notification.object;
    
    if (textInput.inputView && self == textInput.inputView) {
        self.textInput = textInput;
        
        if (![self.textInput hasText]) {
            memset(sg_APNumberPadSecurityPin, 0, sizeof(sg_APNumberPadSecurityPin));
        }
        
        _delegateFlags.textInputSupportsShouldChangeTextInRange = NO;
        _delegateFlags.delegateSupportsTextFieldShouldChangeCharactersInRange = NO;
        _delegateFlags.delegateSupportsTextViewShouldChangeTextInRange = NO;
        
        if ([self.textInput respondsToSelector:@selector(shouldChangeTextInRange:replacementText:)]) {
            _delegateFlags.textInputSupportsShouldChangeTextInRange = YES;
        } else if ([self.textInput isKindOfClass:[UITextField class]]) {
            id<UITextFieldDelegate> delegate = [(UITextField *)self.textInput delegate];
            if ([delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
                _delegateFlags.delegateSupportsTextFieldShouldChangeCharactersInRange = YES;
            }
        } else if ([self.textInput isKindOfClass:[UITextView class]]) {
            id<UITextViewDelegate> delegate = [(UITextView *)self.textInput delegate];
            if ([delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
                _delegateFlags.delegateSupportsTextViewShouldChangeTextInRange = YES;
            }
        }
    }
}

- (void)textDidEndEditing:(NSNotification *)notification {
    self.textInput = nil;

    if (!_functionButtonActionFlag)
        [self doFunctionButtonAction];
}
        


- (void)encryptParameterConfig:(NSString *)workingKeyString masterKeyDivData:(NSString *)divDataString cardNumber:(NSString *)cardNumber
{
    _workingKeyString = workingKeyString;
    _divDataString  = divDataString;
    _accountString = cardNumber;
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[UIDevice currentDevice] playInputClick];
    
    // Perform number button action for previous `self.lastTouch`
    //
    if (self.lastTouch) {
        [self performLastTouchAction];
    }

    // `touches` contains only one UITouch (self.multipleTouchEnabled == NO)
    //
    self.lastTouch = [touches anyObject];
    
    // Update highlighted state for number buttons, cancel `touches` for everything but the catched
    //
    CGPoint location = [self.lastTouch locationInView:self];
    for (APNumberButton *b in self.numberButtons) {
        if (CGRectContainsPoint(b.frame, location)) {
            b.highlighted = YES;
        } else {
            b.highlighted = NO;
            [b np_touchesCancelled:touches withEvent:event];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.lastTouch || ![touches containsObject:self.lastTouch]) {
        return; // ignore old touches movings
    }
    
    CGPoint location = [self.lastTouch locationInView:self];
    
    // Forget highlighted state for functional buttons after move
    //
    if (!CGRectContainsPoint(self.clearButton.frame, location)) {
        [self.clearButton np_touchesCancelled:touches withEvent:event];
        
        // Disable long gesture action for clear button
        //
        _clearButtonLongPressGesture = NO;
    }
    
    if (!CGRectContainsPoint(self.leftButton.frame, location)) {
        [self.leftButton np_touchesCancelled:touches withEvent:event];
    }
    
    // Update highlighted state for number buttons
    //
    for (APNumberButton *b in self.numberButtons) {
        b.highlighted = CGRectContainsPoint(b.frame, location);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.lastTouch || ![touches containsObject:self.lastTouch]) {
        return; // ignore old touches
    }
    
    [self performLastTouchAction];
    
    self.lastTouch = nil;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    // Reset hightlighted state for all buttons, forget `self.lastTouch`
    //
    self.leftButton.highlighted = NO;
    self.clearButton.highlighted = NO;
    
    for (APNumberButton *b in self.numberButtons) {
        b.highlighted = NO;
    }
    
    self.lastTouch = nil;
}

- (void)performLastTouchAction {
    // Reset highlighted state for all buttons, perform action for catched button
    //
    CGPoint location = [self.lastTouch locationInView:self];
    for (APNumberButton *b in self.numberButtons) {
        b.highlighted = NO;
        if (CGRectContainsPoint(b.frame, location)) {
            [self numberButtonAction:b];
        }
    }
}

#pragma mark - Left function button

- (UIButton *)leftFunctionButton {
    return self.leftButton;
}

#pragma mark - Actions

- (void)numberButtonAction:(UIButton *)sender {
    if (!self.textInput) {
        return;
    }
    
    NSString *text = sender.currentTitle;
    
    char lastChar = text.UTF8String[0];
    
    if (_isEncryptInput) {
        int pinLength = (int)strlen(sg_APNumberPadSecurityPin);
        
        if (pinLength >= sizeof(sg_APNumberPadSecurityPin) - 1)
            return;
        
        sg_APNumberPadSecurityPin[pinLength++] = lastChar;
        sg_APNumberPadSecurityPin[pinLength] = 0;
        
        text = @"●";
    }
    
    if (_delegateFlags.textInputSupportsShouldChangeTextInRange) {
        if ([self.textInput shouldChangeTextInRange:self.textInput.selectedTextRange replacementText:text]) {
            [self.textInput insertText:text];
        }
    } else if (_delegateFlags.delegateSupportsTextFieldShouldChangeCharactersInRange) {
        NSRange selectedRange = [[self class] selectedRange:self.textInput];
        UITextField *textField = (UITextField *)self.textInput;
        if ([textField.delegate textField:textField shouldChangeCharactersInRange:selectedRange replacementString:text]) {
            [self.textInput insertText:text];
        }
    } else if (_delegateFlags.delegateSupportsTextViewShouldChangeTextInRange) {
        NSRange selectedRange = [[self class] selectedRange:self.textInput];
        UITextView *textView = (UITextView *)self.textInput;
        if ([textView.delegate textView:textView shouldChangeTextInRange:selectedRange replacementText:text]) {
            [self.textInput insertText:text];
        }
    } else {
        [self.textInput insertText:text];
    }
    if (_isEncryptInput) {
        if (((UITextField *)self.textInput).text.length == 1) {
            memset(sg_APNumberPadSecurityPin, 0, sizeof(sg_APNumberPadSecurityPin));
            sg_APNumberPadSecurityPin[0] = lastChar;
        }
    }
}

- (void)clearButtonAction {
    if (!self.textInput) {
        return;
    }
    
    if (_isEncryptInput) {
        int pinLength = (int)strlen(sg_APNumberPadSecurityPin);
        if (pinLength == 0)
            return;
        sg_APNumberPadSecurityPin[pinLength - 1] = 0;
    }
    
    if (_delegateFlags.textInputSupportsShouldChangeTextInRange) {
        UITextRange *textRange = self.textInput.selectedTextRange;
        if ([textRange.start isEqual:textRange.end]) {
            UITextPosition *newStart = [self.textInput positionFromPosition:textRange.start inDirection:UITextLayoutDirectionLeft offset:1];
            textRange = [self.textInput textRangeFromPosition:newStart toPosition:textRange.end];
        }
        if ([self.textInput shouldChangeTextInRange:textRange replacementText:@""]) {
            [self.textInput deleteBackward];
        }
    } else if (_delegateFlags.delegateSupportsTextFieldShouldChangeCharactersInRange) {
        NSRange selectedRange = [[self class] selectedRange:self.textInput];
        if (selectedRange.length == 0 && selectedRange.location > 0) {
            selectedRange.location--;
            selectedRange.length = 1;
        }
        UITextField *textField = (UITextField *)self.textInput;
        if ([textField.delegate textField:textField shouldChangeCharactersInRange:selectedRange replacementString:@""]) {
            [self.textInput deleteBackward];
        }
    } else if (_delegateFlags.delegateSupportsTextViewShouldChangeTextInRange) {
        NSRange selectedRange = [[self class] selectedRange:self.textInput];
        if (selectedRange.length == 0 && selectedRange.location > 0) {
            selectedRange.location--;
            selectedRange.length = 1;
        }
        UITextView *textView = (UITextView *)self.textInput;
        if ([textView.delegate textView:textView shouldChangeTextInRange:selectedRange replacementText:@""]) {
            [self.textInput deleteBackward];
        }
    } else {
        [self.textInput deleteBackward];
    }
}

- (void)functionButtonAction:(id)sender {
    if (!self.textInput) {
        return;
    }
    
    _functionButtonActionFlag = YES;
    [self doFunctionButtonAction];
}

- (void)doFunctionButtonAction
{
    NSString *inputText;
    if ([self.textInput isKindOfClass:[UITextField class]]) {
        inputText = ((UITextField *)self.textInput).text;
    }
    if ([self.textInput isKindOfClass:[UITextView class]]) {
        inputText = ((UITextView *)self.textInput).text;
    }
    if (!_isEncryptInput) {
        [self.delegate numberPad:self textInput:inputText];
        return;
    }
    
    //gen pinblock
    Byte pinBlock[8];
    
    //NSLog(@"%s", sg_APNumberPadSecurityPin);
    
    if ([self.delegate respondsToSelector:@selector(numberPad:pinBlock:)]) {
        if ((_accountString && _accountString.length < 13) ||
            iCalPinBlock(_workingKeyString.UTF8String, _divDataString.UTF8String, sg_APNumberPadSecurityPin, (char *)_accountString.UTF8String, pinBlock)) {
            [self.delegate numberPad:self pinBlock:nil];
            return;
        }
        
        char szPinBlock[16+1];
        vOneTwo0(pinBlock, 8, (Byte *)szPinBlock);
        [self.delegate numberPad:self pinBlock:[NSString stringWithFormat:@"%s", szPinBlock]];
    }
}

#pragma mark - Clear button long press

- (void)longPressGestureRecognizerAction:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        _clearButtonLongPressGesture = YES;
        [self clearButtonActionLongPress];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        _clearButtonLongPressGesture = NO;
    }
}

- (void)clearButtonActionLongPress {
    if (_clearButtonLongPressGesture) {
        if ([self.textInput hasText]) {
            [[UIDevice currentDevice] playInputClick];
            
            [self clearButtonAction];
            [self performSelector:@selector(clearButtonActionLongPress) withObject:nil afterDelay:0.1f]; // delay like in iOS keyboard
        } else {
            _clearButtonLongPressGesture = NO;
        }
    }
}

#pragma mark - UIInputViewAudioFeedback

- (BOOL)enableInputClicksWhenVisible {
    return YES;
}

#pragma mark - Additions

+ (NSRange)selectedRange:(id<UITextInput>)textInput {
    UITextRange *textRange = [textInput selectedTextRange];
    
    NSInteger startOffset = [textInput offsetFromPosition:textInput.beginningOfDocument toPosition:textRange.start];
    NSInteger endOffset = [textInput offsetFromPosition:textInput.beginningOfDocument toPosition:textRange.end];
    
    return NSMakeRange(startOffset, endOffset - startOffset);
}

#pragma mark - Button fabric

+ (APNumberButton *)numberButton:(int)number {
    APNumberButton *b = [APNumberButton buttonWithBackgroundColor:[self numberButtonBackgroundColor]highlightedColor:[self numberButtonHighlightedColor]];
    [b setBackgroundImage:[UIImage imageNamed:@"APNumberPadKitResources.bundle/apnnumberpad_keyboard_number"] forState:UIControlStateNormal];
        [b setBackgroundImage:[UIImage imageNamed:@"APNumberPadKitResources.bundle/apnnumberpad_keyboard_number_press"] forState:UIControlStateHighlighted];
    [b setTitleColor:[self numberButtonTextColor] forState:UIControlStateNormal];
    [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    b.titleLabel.font = [self numberButtonFont];
    [b setTitle:[NSString stringWithFormat:@"%d", number] forState:UIControlStateNormal];
    return b;
}

+ (APNumberButton *)functionButton {
    APNumberButton *b = [APNumberButton buttonWithBackgroundColor:[self functionButtonBackgroundColor]highlightedColor:[self functionButtonHighlightedColor]];
    b.exclusiveTouch = YES;
    return b;
}

+ (void)writeHexLog:(NSString *)prompt hexData:(Byte *)hexData length:(int)length
{
//    unsigned char forLog[length * 2 + 1];
//    vOneTwo0(hexData, 16, forLog);
//    NSLog(@"%@ = [%s]", prompt, forLog);
}

@end
