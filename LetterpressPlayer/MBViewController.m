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

@implementation MBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *screenshot = [UIImage imageNamed:@"sample.png"];
//    NSLog(@"colorBlock: %@", [self colorBlockFromImage:screenshot]);
//    NSLog(@"letterBlock: %@", [self letterBlockFromImage:screenshot]);
//    NSLog(@"words: %@", [self wordsForLetterBlock:[self letterBlockFromImage:screenshot]]);
    UITextView *tv = [[UITextView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:tv];
    tv.editable = NO;
    tv.text = [[self wordsForLetterBlock:[self letterBlockFromImage:screenshot]] description];
}

- (NSArray *)colorBlockFromImage:(UIImage *)image {
    __block NSMutableArray *colorBlock = @[].mutableCopy;
    NSArray *points = [self pointsForBucketColors];
    
    [points enumerateObjectsUsingBlock:^(NSValue *pointValue, NSUInteger idx, BOOL *stop) {
        NSInteger type = [self letterTypeForColor:[image colorAtPoint:[pointValue CGPointValue]]];
        [colorBlock addObject:@(type)];
    }];
    return colorBlock;
}

- (NSArray *)pointsForBucketColors {
    NSMutableArray *points = @[].mutableCopy;
    CGPoint offset = CGPointMake(2, 498);
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

- (NSArray *)letterBlockFromImage:(UIImage *)image {
    return @[@"K", @"K", @"O", @"P", @"W", @"Q", @"H", @"V", @"A", @"I", @"A", @"E", @"D", @"R", @"L", @"S", @"H", @"K", @"E", @"W", @"L", @"X", @"E", @"A", @"V"];
}

- (NSArray *)masterWordList {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"en_longest_to_shortest" ofType:@"txt"];
    NSString *wordlist = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    NSArray *words = [wordlist componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return words;
}

- (NSArray *)wordsForLetterBlock:(NSArray *)letterBlock {
    NSMutableString *letterBlockString = @"".mutableCopy;
    for (NSString *letter in letterBlock) {
        [letterBlockString appendString:letter.lowercaseString];
    }
    NSCharacterSet *blockSet = [NSCharacterSet characterSetWithCharactersInString:letterBlockString];
    NSArray *words = [self masterWordList];
    
    NSMutableArray *matchedWords = @[].mutableCopy;
    for (NSString *word in words) {
        if ([blockSet isSupersetOfSet:[NSCharacterSet characterSetWithCharactersInString:word]]) {
            NSMutableArray *charactersLeft = letterBlock.mutableCopy;
            for (NSString *c in [self charactersFromString:word]) {
                NSString *uppercaseLetter = c.uppercaseString;
                NSUInteger indexOfLetter = [charactersLeft indexOfObject:uppercaseLetter];
                if (indexOfLetter != NSNotFound) {
                    [charactersLeft removeObjectAtIndex:indexOfLetter];
                } else {
                    break;
                }
            }
            if (charactersLeft.count == letterBlock.count - word.length) {
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

@end
