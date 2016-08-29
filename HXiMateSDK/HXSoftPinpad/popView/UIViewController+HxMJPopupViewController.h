//
//  UIViewController+MJPopupViewController.h
//  MJModalViewController
//
//  Created by Martin Juhasz on 11.05.12.
//  Copyright (c) 2012 martinjuhasz.de. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    HxMJPopupViewAnimationSlideBottomTop = 1,
    HxMJPopupViewAnimationSlideRightLeft,
    HxMJPopupViewAnimationSlideBottomBottom,
    HxMJPopupViewAnimationFade
} HxMJPopupViewAnimation;

@interface UIViewController (HxMJPopupViewController)

- (void)presentPopupViewController:(UIViewController*)popupViewController animationType:(HxMJPopupViewAnimation)animationType;
- (void)dismissPopupViewControllerWithanimationType:(HxMJPopupViewAnimation)animationType;

@end