//
//  UIImage+LPAdditions.m
//  LetterpressPlayer
//
//  Created by Jean-Pierre Simard on 2/18/13.
//  Copyright (c) 2013 Magnetic Bear Studios. All rights reserved.
//

#import "UIImage+LPAdditions.h"

static CGColorSpaceRef __rgbColorSpace = NULL;

@implementation UIImage (LPAdditions)

#pragma mark - Color Extraction

- (UIColor *)colorAtPoint:(CGPoint)point {
    return [[self colorsAtPoints:@[[NSValue valueWithCGPoint:point]]] lastObject];
}

- (NSArray *)colorsAtPoints:(NSArray *)points {
    
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:points.count];
    
    // First get the image into your data buffer
    CGImageRef imageRef = [self CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = malloc(height * width * 4);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    [points enumerateObjectsUsingBlock:^(NSValue *pointValue, NSUInteger idx, BOOL *stop) {
        // Now your rawData contains the image data in the RGBA8888 pixel format.
        CGPoint point = pointValue.CGPointValue;
        int byteIndex = (bytesPerRow * point.y) + point.x * bytesPerPixel;
        
        CGFloat red   = (rawData[byteIndex]     * 1.0) / 255.0;
        CGFloat green = (rawData[byteIndex + 1] * 1.0) / 255.0;
        CGFloat blue  = (rawData[byteIndex + 2] * 1.0) / 255.0;
        CGFloat alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
        
        [results addObject:[UIColor colorWithRed:red green:green blue:blue alpha:alpha]];
    }];
    
    free(rawData);
    
    return results;
}

- (NSArray *)colorComponentsAtPoints:(NSArray *)points {
    
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:points.count];
    
    // First get the image into your data buffer
    CGImageRef imageRef = [self CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = malloc(height * width * 4);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    [points enumerateObjectsUsingBlock:^(NSValue *pointValue, NSUInteger idx, BOOL *stop) {
        // Now your rawData contains the image data in the RGBA8888 pixel format.
        CGPoint point = pointValue.CGPointValue;
        int byteIndex = (bytesPerRow * point.y) + point.x * bytesPerPixel;
        
        CGFloat red   = (rawData[byteIndex]     * 1.0) / 255.0;
        CGFloat green = (rawData[byteIndex + 1] * 1.0) / 255.0;
        CGFloat blue  = (rawData[byteIndex + 2] * 1.0) / 255.0;
        
        [results addObject:@[@(red), @(green), @(blue)]];
    }];
    
    free(rawData);
    
    return results;
}

#pragma mark - Resizing

- (UIImage *)cropToSize:(CGSize)newSize usingMode:(NYXCropMode)cropMode {
    const CGSize size = self.size;
    CGFloat x, y;
    switch (cropMode)
    {
        case NYXCropModeTopLeft:
            x = y = 0.0f;
            break;
        case NYXCropModeTopCenter:
            x = (size.width - newSize.width) * 0.5f;
            y = 0.0f;
            break;
        case NYXCropModeTopRight:
            x = size.width - newSize.width;
            y = 0.0f;
            break;
        case NYXCropModeBottomLeft:
            x = 0.0f;
            y = size.height - newSize.height;
            break;
        case NYXCropModeBottomCenter:
            x = newSize.width * 0.5f;
            y = size.height - newSize.height;
            break;
        case NYXCropModeBottomRight:
            x = size.width - newSize.width;
            y = size.height - newSize.height;
            break;
        case NYXCropModeLeftCenter:
            x = 0.0f;
            y = (size.height - newSize.height) * 0.5f;
            break;
        case NYXCropModeRightCenter:
            x = size.width - newSize.width;
            y = (size.height - newSize.height) * 0.5f;
            break;
        case NYXCropModeCenter:
            x = (size.width - newSize.width) * 0.5f;
            y = (size.height - newSize.height) * 0.5f;
            break;
        default: // Default to top left
            x = y = 0.0f;
            break;
    }
    
    CGRect cropRect = CGRectMake(x * self.scale, y * self.scale, newSize.width * self.scale, newSize.height * self.scale);
    
    /// Create the cropped image
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect(self.CGImage, cropRect);
    UIImage* cropped = [UIImage imageWithCGImage:croppedImageRef scale:self.scale orientation:self.imageOrientation];
    
    /// Cleanup
    CGImageRelease(croppedImageRef);
    
    return cropped;
}

/* Convenience method to crop the image from the top left corner */
- (UIImage *)cropToSize:(CGSize)newSize {
    return [self cropToSize:newSize usingMode:NYXCropModeTopLeft];
}

- (UIImage *)scaleByFactor:(float)scaleFactor {
    const size_t originalWidth = (size_t)(self.size.width * self.scale * scaleFactor);
    const size_t originalHeight = (size_t)(self.size.height * self.scale * scaleFactor);
    /// Number of bytes per row, each pixel in the bitmap will be represented by 4 bytes (ARGB), 8 bits of alpha/red/green/blue
    const size_t bytesPerRow = originalWidth * kNyxNumberOfComponentsPerARBGPixel;
    
    /// Create an ARGB bitmap context
    CGContextRef bmContext = NYXCreateARGBBitmapContext(originalWidth, originalHeight, bytesPerRow);
    if (!bmContext)
        return nil;
    
    /// Handle orientation
    if (UIImageOrientationLeft == self.imageOrientation)
    {
        CGContextRotateCTM(bmContext, (CGFloat)M_PI_2);
        CGContextTranslateCTM(bmContext, 0, -originalHeight);
    }
    else if (UIImageOrientationRight == self.imageOrientation)
    {
        CGContextRotateCTM(bmContext, (CGFloat)-M_PI_2);
        CGContextTranslateCTM(bmContext, -originalWidth, 0);
    }
    else if (UIImageOrientationDown == self.imageOrientation)
    {
        CGContextTranslateCTM(bmContext, originalWidth, originalHeight);
        CGContextRotateCTM(bmContext, (CGFloat)-M_PI);
    }
    
    /// Image quality
    CGContextSetShouldAntialias(bmContext, true);
    CGContextSetAllowsAntialiasing(bmContext, true);
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = originalWidth, .size.height = originalHeight}, self.CGImage);
    
    /// Create an image object from the context
    CGImageRef scaledImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* scaled = [UIImage imageWithCGImage:scaledImageRef scale:self.scale orientation:self.imageOrientation];
    
    /// Cleanup
    CGImageRelease(scaledImageRef);
    CGContextRelease(bmContext);
    
    return scaled;
}

- (UIImage *)scaleToFitSize:(CGSize)newSize {
    const size_t originalWidth = (size_t)(self.size.width * self.scale);
    const size_t originalHeight = (size_t)(self.size.height * self.scale);
    
    /// Keep aspect ratio
    size_t destWidth, destHeight;
    if (originalWidth > originalHeight)
    {
        destWidth = (size_t)newSize.width;
        destHeight = (size_t)(originalHeight * newSize.width / originalWidth);
    }
    else
    {
        destHeight = (size_t)newSize.height;
        destWidth = (size_t)(originalWidth * newSize.height / originalHeight);
    }
    if (destWidth > newSize.width)
    {
        destWidth = (size_t)newSize.width;
        destHeight = (size_t)(originalHeight * newSize.width / originalWidth);
    }
    if (destHeight > newSize.height)
    {
        destHeight = (size_t)newSize.height;
        destWidth = (size_t)(originalWidth * newSize.height / originalHeight);
    }
    
    /// Create an ARGB bitmap context
    CGContextRef bmContext = NYXCreateARGBBitmapContext(destWidth, destHeight, destWidth * kNyxNumberOfComponentsPerARBGPixel);
    if (!bmContext)
        return nil;
    
    /// Image quality
    CGContextSetShouldAntialias(bmContext, true);
    CGContextSetAllowsAntialiasing(bmContext, true);
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
    /// Draw the image in the bitmap context
    
    UIGraphicsPushContext(bmContext);
    CGContextTranslateCTM(bmContext, 0.0f, destHeight);
    CGContextScaleCTM(bmContext, 1.0f, -1.0f);
    [self drawInRect:(CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = destWidth, .size.height = destHeight}];
    UIGraphicsPopContext();
    
    /// Create an image object from the context
    CGImageRef scaledImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* scaled = [UIImage imageWithCGImage:scaledImageRef scale:self.scale orientation:self.imageOrientation];
    
    /// Cleanup
    CGImageRelease(scaledImageRef);
    CGContextRelease(bmContext);
    
    return scaled;
}

CGContextRef NYXCreateARGBBitmapContext(const size_t width, const size_t height, const size_t bytesPerRow) {
    /// Use the generic RGB color space
    /// We avoid the NULL check because CGColorSpaceRelease() NULL check the value anyway, and worst case scenario = fail to create context
    /// Create the bitmap context, we want pre-multiplied ARGB, 8-bits per component
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8/*Bits per component*/, bytesPerRow, NYXGetRGBColorSpace(), kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    return bmContext;
}

CGColorSpaceRef NYXGetRGBColorSpace(void) {
    if (!__rgbColorSpace)
    {
        __rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    }
    return __rgbColorSpace;
}

@end
