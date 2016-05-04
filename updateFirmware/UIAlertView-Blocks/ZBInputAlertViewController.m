//
//  ZBInputAlertViewController.m
//  ktvDEMO
//
//  Created by zbh on 16/4/26.
//  Copyright © 2016年 hxsmart. All rights reserved.
//

#import "ZBInputAlertViewController.h"

@interface ZBInputAlertViewController()<UIAlertViewDelegate>{
    actionText actionForText;
}

@property (nonatomic, strong) NSString              *title;
@property (nonatomic, strong) NSString              *message;
@property (nonatomic, strong) NSString              *hint;
@property (nonatomic, strong) NSString              *text;
@property (nonatomic, weak) UIViewController        *inViewController;

@end

@implementation ZBInputAlertViewController

- (id)initWithTitle:(NSString *)title message:(NSString *)message TextFieldHint:(NSString*)hint TextFieldcontentText:(NSString*)contentText viewController:(UIViewController *)inViewController
{
    if (self = [super init]) {
        self.title = title;
        self.message = message;
        self.text = contentText;
        self.hint = hint;
        self.inViewController = inViewController;
    }
    return self;
}

- (void)showWithAction:(actionText)action
{
    actionForText = action;
    if (isIOS8) {
        [self showIOS8WithAction:action];
        
    } else {
        [self showIOS7WithAction:action];
    }
}

- (void)showIOS7WithAction:(actionText)actionT
{
    
    UIAlertView *customAlertView = [[UIAlertView alloc] initWithTitle:self.title message:self.message delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定",nil];
    
    [customAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    
    UITextField *nameField = [customAlertView textFieldAtIndex:0];
    [nameField setText:_text];
    nameField.placeholder = _hint;
    nameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [customAlertView show];
}

- (void)showIOS8WithAction:(actionText)actionT
{
    if (self.inViewController == nil) {
        return;
    }
    
    UIAlertController *alertController = nil;
    
    alertController = [UIAlertController alertControllerWithTitle:self.title message:self.message preferredStyle:UIAlertControllerStyleAlert];
    
    
    UIAlertAction *DoneAction = [UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        UITextField *TextField = alertController.textFields.firstObject;
        actionT(TextField.text);
        
    }];
    [alertController addAction:DoneAction];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = _hint;
        [textField setText:_text];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType=UIReturnKeyDefault;
    }];
    
    [self.inViewController presentViewController:alertController animated:YES completion:nil];
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        UITextField *nameField = [alertView textFieldAtIndex:0];
        actionForText(nameField.text);
    }
}

@end
