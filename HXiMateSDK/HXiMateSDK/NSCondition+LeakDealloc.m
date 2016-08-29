//
//  NSCondition+LeakDealloc.m
//  HXiMateSDK
//
//  Created by hxsmart on 13-1-22.
//  Copyright (c) 2013年 hxsmart. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSCondition+LeakDealloc.h"
#import <objc/runtime.h>

@implementation NSCondition (LeakDealloc)

- (void)safeDealloc
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0)
    {
        [self safeDealloc];
    }
}

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(dealloc)), class_getInstanceMethod(self, @selector(safeDealloc)));
}

@end
