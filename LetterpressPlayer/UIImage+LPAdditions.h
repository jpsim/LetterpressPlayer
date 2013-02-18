//
//  UIImage+LPAdditions.h
//  LetterpressPlayer
//
//  Created by Jean-Pierre Simard on 2/18/13.
//  Copyright (c) 2013 Magnetic Bear Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

/* Number of components for an ARGB pixel (Alpha / Red / Green / Blue) = 4 */
#define kNyxNumberOfComponentsPerARBGPixel 4

typedef enum {
    NYXCropModeTopLeft,
    NYXCropModeTopCenter,
    NYXCropModeTopRight,
    NYXCropModeBottomLeft,
    NYXCropModeBottomCenter,
    NYXCropModeBottomRight,
    NYXCropModeLeftCenter,
    NYXCropModeRightCenter,
    NYXCropModeCenter
} NYXCropMode;

@interface UIImage (LPAdditions)

// Color Extraction
- (UIColor *)colorAtPoint:(CGPoint)point;
- (NSArray *)colorsAtPoints:(NSArray *)points;

// Resizing
- (UIImage *)cropToSize:(CGSize)newSize usingMode:(NYXCropMode)cropMode;
- (UIImage *)cropToSize:(CGSize)newSize;
- (UIImage *)scaleByFactor:(float)scaleFactor;
- (UIImage *)scaleToFitSize:(CGSize)newSize;

CGContextRef NYXCreateARGBBitmapContext(const size_t width, const size_t height, const size_t bytesPerRow);
CGColorSpaceRef NYXGetRGBColorSpace(void);

@end
