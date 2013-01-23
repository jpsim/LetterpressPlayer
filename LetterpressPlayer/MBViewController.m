//
//  MBViewController.m
//  LetterpressPlayer
//
//  Created by Jean-Pierre Simard on 1/23/13.
//  Copyright (c) 2013 Magnetic Bear Studios. All rights reserved.
//

#define kSquareSize         128.0

#import "MBViewController.h"
#import "UIImage+PixelAdditions.h"
#import "UIColor+ComponentAdditions.h"
#import "LetterpressLetter.h"
#import "UIImage+Resizing.h"

@implementation MBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *screenshot = [[UIImage imageNamed:@"l5.png"] cropToSize:CGSizeMake(5*kSquareSize, 5*kSquareSize) usingMode:NYXCropModeBottomLeft];
//    NSLog(@"colorArray: %@", [self colorArrayFromImage:screenshot]);
//    NSLog(@"letterArray: %@", [self letterArrayFromImage:screenshot]);
//    NSLog(@"words: %@", [self wordsForletterArray:[self letterArrayFromImage:screenshot]]);
//    NSLog(@"imageArray: %@", [self imageArrayFromImage:screenshot]);
//    UITextView *tv = [[UITextView alloc] initWithFrame:self.view.frame];
//    [self.view addSubview:tv];
//    tv.editable = NO;
//    tv.text = [[self wordsForletterArray:[self letterArrayFromImage:screenshot]] description];
//
    [[self imageArrayFromImage:screenshot] enumerateObjectsUsingBlock:^(UIImage *image, NSUInteger idx, BOOL *stop) {
        NSInteger grayAmount1 = 0;
        for (int i = 0; i < floor(image.size.width); i++) {
            NSArray *color = [[image colorAtPoint:CGPointMake(i, 48)] components];
            if ([self deviationBetweenArray:color andReference:@[@(0.09411765), @(0.1568628), @(0.1921569), @(1)]] < 1) grayAmount1++;
        }
        
        NSInteger grayAmount2 = 0;
        for (int i = 0; i < floor(image.size.width); i++) {
            NSArray *color = [[image colorAtPoint:CGPointMake(i, 64)] components];
            if ([self deviationBetweenArray:color andReference:@[@(0.09411765), @(0.1568628), @(0.1921569), @(1)]] < 1) grayAmount2++;
        }
        
        NSInteger grayAmount3 = 0;
        for (int i = 0; i < floor(image.size.width); i++) {
            NSArray *color = [[image colorAtPoint:CGPointMake(i, 80)] components];
            if ([self deviationBetweenArray:color andReference:@[@(0.09411765), @(0.1568628), @(0.1921569), @(1)]] < 1) grayAmount3++;
        }
        
        NSInteger grayAmount4 = 0;
        for (int i = 0; i < floor(image.size.height); i++) {
            NSArray *color = [[image colorAtPoint:CGPointMake(48, i)] components];
            if ([self deviationBetweenArray:color andReference:@[@(0.09411765), @(0.1568628), @(0.1921569), @(1)]] < 1) grayAmount4++;
        }
        
        NSInteger grayAmount5 = 0;
        for (int i = 0; i < floor(image.size.height); i++) {
            NSArray *color = [[image colorAtPoint:CGPointMake(64, i)] components];
            if ([self deviationBetweenArray:color andReference:@[@(0.09411765), @(0.1568628), @(0.1921569), @(1)]] < 1) grayAmount5++;
        }
        
        NSInteger grayAmount6 = 0;
        for (int i = 0; i < floor(image.size.height); i++) {
            NSArray *color = [[image colorAtPoint:CGPointMake(80, i)] components];
            if ([self deviationBetweenArray:color andReference:@[@(0.09411765), @(0.1568628), @(0.1921569), @(1)]] < 1) grayAmount6++;
        }
        
        NSString *letter = [self stringForCellWithTextColorArray:@[@(grayAmount1), @(grayAmount2), @(grayAmount3), @(grayAmount4), @(grayAmount5), @(grayAmount6)]];
        NSLog(@"letter: %@", letter);
        
//        NSLog(@"%d: \@[\@%d, \@%d, \@%d, \@%d, \@%d, \@%d]", idx, grayAmount1, grayAmount2, grayAmount3, grayAmount4, grayAmount5, grayAmount6);
//        int64_t delayInSeconds = 1.0;
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, idx * delayInSeconds * NSEC_PER_SEC);
//        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//            UIImageView *img = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 34, 34)];
//            img.image = image;
//            [self.view addSubview:img];
//        });
    }];
}

- (NSArray *)colorArrayFromImage:(UIImage *)image {
    __block NSMutableArray *colorArray = @[].mutableCopy;
    NSArray *points = [self pointsForBucketColors];
    
    [points enumerateObjectsUsingBlock:^(NSValue *pointValue, NSUInteger idx, BOOL *stop) {
        NSInteger type = [self letterTypeForColor:[image colorAtPoint:[pointValue CGPointValue]]];
        [colorArray addObject:@(type)];
    }];
    return colorArray;
}

- (NSArray *)pointsForBucketColors {
    NSMutableArray *points = @[].mutableCopy;
    CGPoint offset = CGPointMake(2, 2);
    for (int i = 0; i < 25; i++) {
        CGFloat x = offset.x + ((i % 5) * kSquareSize);
        CGFloat y = offset.y + (floor(i/5) * kSquareSize);
        CGPoint point = CGPointMake(x, y);
        NSValue *pointValue = [NSValue valueWithCGPoint:point];
        [points addObject:pointValue];
    }
    return points;
}

- (kLetterType)letterTypeForColor:(UIColor *)color {
    NSArray *components = [color components];
    
    NSArray *lightBlue = @[@(0.4705882), @(0.7843137), @(0.9607843), @(1)];
    NSArray *darkBlue = @[@(0), @(0.6352941), @(1), @(1)];
    NSArray *gray1 = @[@(0.9019608), @(0.8980392), @(0.8862745), @(1)];
    NSArray *gray2 = @[@(0.9137255), @(0.9098039), @(0.8980392), @(1)];
    NSArray *lightRed = @[@(0.9686275), @(0.6), @(0.5529412), @(1)];
    NSArray *darkRed = @[@(1), @(0.2627451), @(0.1843137), @(1)];
    
    __block CGFloat lightBlueDeviation = 0;
    __block CGFloat darkBlueDeviation = 0;
    __block CGFloat gray1Deviation = 0;
    __block CGFloat gray2Deviation = 0;
    __block CGFloat lightRedDeviation = 0;
    __block CGFloat darkRedDeviation = 0;
    
    [components enumerateObjectsUsingBlock:^(NSNumber *component, NSUInteger idx, BOOL *stop) {
        lightBlueDeviation += fabsf(component.floatValue - [[lightBlue objectAtIndex:idx] floatValue]);
        darkBlueDeviation += fabsf(component.floatValue - [[darkBlue objectAtIndex:idx] floatValue]);
        gray1Deviation += fabsf(component.floatValue - [[gray1 objectAtIndex:idx] floatValue]);
        gray2Deviation += fabsf(component.floatValue - [[gray2 objectAtIndex:idx] floatValue]);
        lightRedDeviation += fabsf(component.floatValue - [[lightRed objectAtIndex:idx] floatValue]);
        darkRedDeviation += fabsf(component.floatValue - [[darkRed objectAtIndex:idx] floatValue]);
    }];
    
    if (lightBlueDeviation < darkBlueDeviation
        && lightBlueDeviation < gray1Deviation
        && lightBlueDeviation < gray2Deviation
        && lightBlueDeviation < lightRedDeviation
        && lightBlueDeviation < darkRedDeviation) {
        return kLetterTypeLightBlue;
    }
    
    if (darkBlueDeviation < gray1Deviation
        && darkBlueDeviation < gray2Deviation
        && darkBlueDeviation < lightRedDeviation
        && darkBlueDeviation < darkRedDeviation) {
        return kLetterTypeDarkBlue;
    }
    
    if (gray1Deviation < gray2Deviation
        && gray1Deviation < lightRedDeviation
        && gray1Deviation < darkRedDeviation) {
        return kLetterTypeGray;
    }
    
    if (gray2Deviation < lightRedDeviation
        && gray2Deviation < darkRedDeviation) {
        return kLetterTypeGray;
    }
    
    if (lightRedDeviation < darkRedDeviation) {
        return kLetterTypeLightRed;
    }
    
    if (darkRedDeviation) {
        return kLetterTypeDarkRed;
    }
    
    return kLetterTypeUnknown;
}

- (NSArray *)letterArrayFromImage:(UIImage *)image {
    return @[@"K", @"K", @"O", @"P", @"W", @"Q", @"H", @"V", @"A", @"I", @"A", @"E", @"D", @"R", @"L", @"S", @"H", @"K", @"E", @"W", @"L", @"X", @"E", @"A", @"V"];
}

- (NSArray *)masterWordList {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"en_longest_to_shortest" ofType:@"txt"];
    NSString *wordlist = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    NSArray *words = [wordlist componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return words;
}

- (NSArray *)wordsForletterArray:(NSArray *)letterArray {
    NSMutableString *letterArrayString = @"".mutableCopy;
    for (NSString *letter in letterArray) {
        [letterArrayString appendString:letter.lowercaseString];
    }
    NSCharacterSet *blockSet = [NSCharacterSet characterSetWithCharactersInString:letterArrayString];
    NSArray *words = [self masterWordList];
    
    NSMutableArray *matchedWords = @[].mutableCopy;
    for (NSString *word in words) {
        if ([blockSet isSupersetOfSet:[NSCharacterSet characterSetWithCharactersInString:word]]) {
            NSMutableArray *charactersLeft = letterArray.mutableCopy;
            for (NSString *c in [self charactersFromString:word]) {
                NSString *uppercaseLetter = c.uppercaseString;
                NSUInteger indexOfLetter = [charactersLeft indexOfObject:uppercaseLetter];
                if (indexOfLetter != NSNotFound) {
                    [charactersLeft removeObjectAtIndex:indexOfLetter];
                } else {
                    break;
                }
            }
            if (charactersLeft.count == letterArray.count - word.length) {
                [matchedWords addObject:word];
            }
        }
        if (matchedWords.count > 100) {
            break;
        }
    }
    return matchedWords;
}

- (NSArray *)charactersFromString:(NSString *)string {
    NSMutableArray *characters = [[NSMutableArray alloc] initWithCapacity:string.length];
    for (int i = 0; i < string.length; i++) {
        NSString *ichar  = [NSString stringWithFormat:@"%c", [string characterAtIndex:i]];
        [characters addObject:ichar];
    }
    return characters;
}

- (NSArray *)imageArrayFromImage:(UIImage *)image {
    NSMutableArray *imagesArray = @[].mutableCopy;
    UIImage *gameSquare = [image cropToSize:CGSizeMake(5*kSquareSize, 5*kSquareSize) usingMode:NYXCropModeBottomLeft];
    for (int i = 0; i < 25; i++) {
        [imagesArray addObject:[self squareImage:gameSquare index:i]];
    }
    return imagesArray;
}

- (UIImage *)squareImage:(UIImage *)image index:(NSInteger)index {
    switch (index) {
        case 0:
            return [image cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeTopLeft];
            break;
            
        case 1:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(3*kSquareSize, 3*kSquareSize) usingMode:NYXCropModeTopLeft];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeTopCenter];
            break;
        }
            
        case 2:
            return [image cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeTopCenter];
            break;
            
        case 3:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(3*kSquareSize, 3*kSquareSize) usingMode:NYXCropModeTopRight];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeTopCenter];
            break;
        }
            
        case 4:
            return [image cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeTopRight];
            break;
            
        case 5:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(2*kSquareSize, 2*kSquareSize) usingMode:NYXCropModeTopLeft];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeBottomLeft];
            break;
        }
            
        case 6:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(2*kSquareSize, 2*kSquareSize) usingMode:NYXCropModeTopLeft];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeBottomRight];
            break;
        }
            
        case 7:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(3*kSquareSize, 3*kSquareSize) usingMode:NYXCropModeTopLeft];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeRightCenter];
            break;
        }
            
        case 8:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(2*kSquareSize, 2*kSquareSize) usingMode:NYXCropModeTopRight];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeBottomLeft];
            break;
        }
            
        case 9:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(2*kSquareSize, 2*kSquareSize) usingMode:NYXCropModeTopRight];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeBottomRight];
            break;
        }
            
        case 10:
            return [image cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeLeftCenter];
            break;
            
        case 11:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(3*kSquareSize, 3*kSquareSize) usingMode:NYXCropModeBottomLeft];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeTopCenter];
            break;
        }
            
        case 12:
            return [image cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeCenter];
            break;
            
        case 13:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(3*kSquareSize, 3*kSquareSize) usingMode:NYXCropModeBottomRight];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeTopCenter];
            break;
        }
            
        case 14:
            return [image cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeRightCenter];
            break;
            
        case 15:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(2*kSquareSize, 2*kSquareSize) usingMode:NYXCropModeBottomLeft];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeTopLeft];
            break;
        }
            
        case 16:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(2*kSquareSize, 2*kSquareSize) usingMode:NYXCropModeBottomLeft];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeTopRight];
            break;
        }
            
        case 17:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(3*kSquareSize, 3*kSquareSize) usingMode:NYXCropModeBottomRight];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeLeftCenter];
            break;
        }
            
        case 18:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(2*kSquareSize, 2*kSquareSize) usingMode:NYXCropModeBottomRight];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeTopLeft];
            break;
        }
            
        case 19:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(2*kSquareSize, 2*kSquareSize) usingMode:NYXCropModeBottomRight];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeTopRight];
            break;
        }
            
        case 20:
            return [image cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeBottomLeft];
            break;
            
        case 21:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(3*kSquareSize, 3*kSquareSize) usingMode:NYXCropModeBottomLeft];
            partial = [partial cropToSize:CGSizeMake(2*kSquareSize, 2*kSquareSize) usingMode:NYXCropModeBottomRight];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeBottomLeft];
            break;
        }
            
        case 22:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(3*kSquareSize, 3*kSquareSize) usingMode:NYXCropModeBottomRight];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeBottomLeft];
            break;
        }
            
        case 23:
        {
            UIImage *partial = [image cropToSize:CGSizeMake(3*kSquareSize, 3*kSquareSize) usingMode:NYXCropModeBottomRight];
            partial = [partial cropToSize:CGSizeMake(2*kSquareSize, 2*kSquareSize) usingMode:NYXCropModeBottomRight];
            return [partial cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeBottomLeft];
            break;
        }
            
        case 24:
            return [image cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeBottomRight];
            break;
            
        default:
            return [image cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeCenter];
            break;
    }
    
    return [image cropToSize:CGSizeMake(kSquareSize, kSquareSize) usingMode:NYXCropModeCenter];
}

- (NSArray *)amountOfTextColorPerLetterBoxSection {
    return nil;
}

- (CGFloat)deviationBetweenArray:(NSArray *)array andReference:(NSArray *)reference {
    if (array.count != reference.count) return MAXFLOAT;
    CGFloat deviation = 0;
    for (int i = 0; i < array.count; i++) {
        deviation += fabsf([[array objectAtIndex:i] floatValue] - [[reference objectAtIndex:i] floatValue]);
    }
    return deviation;
}

- (NSString *)stringForCellWithTextColorArray:(NSArray *)textColorArray {
    NSArray *a = @[@18, @20, @21, @26, @19, @25];
    NSArray *b = @[@20, @37, @24, @56, @27, @44];
    NSArray *c = @[@12, @10, @32, @43, @19, @21];
    NSArray *d = @[@22, @21, @28, @57, @18, @43];
    NSArray *e = @[@10, @28, @10, @55, @27, @16];
    NSArray *f = @[@10, @28, @10, @0, @18, @9];
    NSArray *g = @[@12, @28, @34, @36, @19, @29];
    NSArray *h = @[@20, @46, @20, @57, @9, @57];
    NSArray *i = @[@10, @10, @10, @0, @57, @0];
    NSArray *j = @[@10, @10, @24, @16, @19, @0];
    NSArray *k = @[@21, @28, @21, @57, @13, @26];
    NSArray *l = @[@10, @10, @10, @0, @9, @9];
    NSArray *m = @[@36, @38, @20, @19, @11, @17];
    NSArray *n = @[@30, @31, @26, @57, @17, @57];
    NSArray *o = @[@24, @21, @32, @26, @19, @32];
    NSArray *p = @[@20, @35, @10, @56, @17, @28];
    NSArray *q = @[@24, @21, @35, @28, @19, @28];
    NSArray *r = @[@20, @31, @21, @57, @18, @36];
    NSArray *s = @[@10, @19, @26, @26, @31, @21];
    NSArray *t = @[@10, @10, @10, @9, @57, @9];
    NSArray *u = @[@21, @21, @29, @52, @9, @53];
    NSArray *v = @[@22, @20, @17, @26, @12, @26];
    NSArray *w = @[@36, @37, @33, @20, @25, @24];
    NSArray *x = @[@22, @17, @22, @29, @18, @21];
    NSArray *y = @[@21, @11, @10, @16, @35, @12];
    NSArray *z = @[@12, @12, @11, @26, @35, @20];
    
    NSMutableArray *deviations = @[].mutableCopy;
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:a])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:b])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:c])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:d])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:e])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:f])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:g])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:h])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:i])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:j])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:k])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:l])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:m])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:n])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:o])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:p])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:q])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:r])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:s])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:t])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:u])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:v])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:w])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:x])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:y])];
    [deviations addObject:@([self deviationBetweenArray:textColorArray andReference:z])];
    
    __block CGFloat min = MAXFLOAT;
    __block NSInteger minIndex = 0;
    [deviations enumerateObjectsUsingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        if (number.floatValue < min) {
            min = number.floatValue;
            minIndex = idx;
        }
    }];
    
    return [@"ABCDEFGHIJKLMNOPQRSTUVWXYZ" substringWithRange:NSMakeRange(minIndex, 1)];
}

@end
