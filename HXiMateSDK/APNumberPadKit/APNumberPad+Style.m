//
//  APNumberPad+Style.m
//
//  Created by Andrew Podkovyrin on 16/05/14.
//  Copyright (c) 2014 Podkovyrin. All rights reserved.
//

#import "APNumberPad+Style.h"

static inline UIColor * APNP_RGBa(int r, int g, int b, CGFloat alpha) {
    return [UIColor colorWithRed:r / 255.f
                           green:g / 255.f
                            blue:b / 255.f
                           alpha:alpha];
}

@implementation APNumberPad (Style)

#pragma mark - Pad

+ (CGRect)numberPadFrame {
    return CGRectMake(0.f, 0.f, 320.f, 216.f);
}

+ (CGFloat)separator {
    return [UIScreen mainScreen].scale == 2.f ? 0.5f : 1.f;
}

+ (UIColor *)numberPadBackgroundColor {
    return APNP_RGBa(38, 43, 46, 1.f);
}

#pragma mark - Number button

+ (UIFont *)numberButtonFont {
    return [UIFont fontWithName:@"HelveticaNeue-Light" size:28.f];
}

+ (UIColor *)numberButtonTextColor {
    return [UIColor blackColor];
}

+ (UIColor *)numberButtonBackgroundColor {
    return APNP_RGBa(252, 252, 252, 1.f);
}

+ (UIColor *)numberButtonHighlightedColor {
    return APNP_RGBa(188, 192, 198, 1.f);
}

#pragma mark - Function button

+ (UIFont *)functionButtonFont {
    return [UIFont boldSystemFontOfSize:18];
}

+ (UIColor *)functionButtonTextColor {
    return [UIColor whiteColor];
}

+ (UIColor *)functionButtonBackgroundColor {
    return APNP_RGBa(188, 192, 198, 1.f);
}

+ (UIColor *)functionButtonHighlightedColor {
    return APNP_RGBa(252, 252, 252, 1.f);
}

+ (UIImage *)clearFunctionButtonImage {
    return [UIImage imageNamed:@"apnumberpad_backspace_icon"];
}

@end
