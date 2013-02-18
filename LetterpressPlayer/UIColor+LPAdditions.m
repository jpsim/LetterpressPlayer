//
//  UIColor+LPAdditions.m
//  LetterpressPlayer
//
//  Created by Jean-Pierre Simard on 1/23/13.
//  Copyright (c) 2013 Magnetic Bear Studios. All rights reserved.
//

#import "UIColor+LPAdditions.h"

@implementation UIColor (LPAdditions)

- (NSArray *)components {
    CGColorRef color = [self CGColor];
    
    int numComponents = CGColorGetNumberOfComponents(color);
    
    if (numComponents == 4) {
        const CGFloat *components = CGColorGetComponents(color);
        CGFloat red = components[0];
        CGFloat green = components[1];
        CGFloat blue = components[2];
        return @[@(red), @(green), @(blue)];
    }
    
    return nil;
}

@end
