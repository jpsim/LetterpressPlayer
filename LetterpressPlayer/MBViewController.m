//
//  MBViewController.m
//  LetterpressPlayer
//
//  Created by Jean-Pierre Simard on 1/23/13.
//  Copyright (c) 2013 Magnetic Bear Studios. All rights reserved.
//

#define kSquareSize         128.0
#define kGenerateDicts      FALSE

#import "MBViewController.h"
#import "UIImage+PixelAdditions.h"
#import "UIColor+ComponentAdditions.h"
#import "LetterpressLetter.h"
#import "UIImage+Resizing.h"
#import <AssetsLibrary/AssetsLibrary.h>

typedef void (^ActionBlock)();
typedef void (^ImageActionBlock)(UIImage *image);

@implementation MBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    masterWordList = [self masterWordList];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicator.center = self.view.center;
    [self.view addSubview:indicator];
    
    activityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, indicator.center.y + 40, 320, 40)];
    activityLabel.backgroundColor = [UIColor blackColor];
    activityLabel.textColor = [UIColor whiteColor];
    activityLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:activityLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshResults) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshResults];
}

- (void)refreshResults {
    if (kGenerateDicts) {
        [self letterArrayFromImage:[UIImage imageNamed:@"l13.png"]];
        return;
    }
    tv.hidden = TRUE;
    
    [indicator startAnimating];
    activityLabel.text = @"Analyzing last photo album image.";
    
    [self getLatestImageFromAlbumWithSuccess:^(UIImage *image) {
        UIImage *screenshot = image;
        
        tv = [[UITextView alloc] initWithFrame:self.view.frame];
        [self.view addSubview:tv];
        tv.editable = NO;
        tv.backgroundColor = [UIColor blackColor];
        tv.textColor = [UIColor whiteColor];
        tv.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        NSArray *letterArray = [self letterArrayFromImage:screenshot];
        tv.text = [[self wordsForletterArray:letterArray] description];
    } failure:^{
        [indicator stopAnimating];
        activityLabel.text = @"Couldn't find your last photo album image. Please take a screenshot of your Letterpress game and return to this app.";
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
    NSMutableArray *letters = @[].mutableCopy;
    NSArray *textColorArray = @[@(0.09411765), @(0.1568628), @(0.1921569), @(1)];
    [[self imageArrayFromImage:image] enumerateObjectsUsingBlock:^(UIImage *image, NSUInteger idx, BOOL *stop) {
        NSInteger grayHorizontal1 = 0;
        for (int i = 0; i < floor(image.size.width); i++) {
            NSArray *color = [[image colorAtPoint:CGPointMake(i, 48)] components];
            if ([self deviationBetweenArray:color andReference:textColorArray] < 1) grayHorizontal1++;
        }
        
        NSInteger grayHorizontal2 = 0;
        for (int i = 0; i < floor(image.size.width); i++) {
            NSArray *color = [[image colorAtPoint:CGPointMake(i, 64)] components];
            if ([self deviationBetweenArray:color andReference:textColorArray] < 1) grayHorizontal2++;
        }
        
        NSInteger grayHorizontal3 = 0;
        for (int i = 0; i < floor(image.size.width); i++) {
            NSArray *color = [[image colorAtPoint:CGPointMake(i, 80)] components];
            if ([self deviationBetweenArray:color andReference:textColorArray] < 1) grayHorizontal3++;
        }
        
        NSInteger grayVertical1 = 0;
        for (int i = 0; i < floor(image.size.height); i++) {
            NSArray *color = [[image colorAtPoint:CGPointMake(48, i)] components];
            if ([self deviationBetweenArray:color andReference:textColorArray] < 1) grayVertical1++;
        }
        
        NSInteger grayVertical2 = 0;
        for (int i = 0; i < floor(image.size.height); i++) {
            NSArray *color = [[image colorAtPoint:CGPointMake(64, i)] components];
            if ([self deviationBetweenArray:color andReference:textColorArray] < 1) grayVertical2++;
        }
        
        NSInteger grayVertical3 = 0;
        for (int i = 0; i < floor(image.size.height); i++) {
            NSArray *color = [[image colorAtPoint:CGPointMake(80, i)] components];
            if ([self deviationBetweenArray:color andReference:textColorArray] < 1) grayVertical3++;
        }
        
        NSInteger qPoint = 0;
        if ([self deviationBetweenArray:[[image colorAtPoint:CGPointMake(73, 73)] components] andReference:textColorArray] < 1) {
            qPoint = 1;
        }
        
        if (kGenerateDicts) {
            NSLog(@"NSArray *%@ = @[@%d, @%d, @%d, @%d, @%d, @%d, @%d];", [@"abcdefghijklmnopqrstuvwxyz" substringWithRange:NSMakeRange(idx, 1)], grayHorizontal1, grayHorizontal2, grayHorizontal3, grayVertical1, grayVertical2, grayVertical3, qPoint);
        } else {
            NSString *letter = [self stringForCellWithTextColorArray:@[@(grayHorizontal1), @(grayHorizontal2), @(grayHorizontal3), @(grayVertical1), @(grayVertical2), @(grayVertical3), @(qPoint)]];
            [letters addObject:letter];
        }
    }];
    
    return letters;
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
    
    NSMutableArray *matchedWords = @[].mutableCopy;
    for (NSString *word in masterWordList) {
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
        if (matchedWords.count > 500) {
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

- (CGFloat)deviationBetweenArray:(NSArray *)array andReference:(NSArray *)reference {
    if (array.count != reference.count) return MAXFLOAT;
    CGFloat deviation = 0;
    for (int i = 0; i < array.count; i++) {
        deviation += fabsf([[array objectAtIndex:i] floatValue] - [[reference objectAtIndex:i] floatValue]);
    }
    return deviation;
}

- (NSString *)stringForCellWithTextColorArray:(NSArray *)textColorArray {
    NSArray *a = @[@18, @20, @21, @26, @19, @25, @1];
    NSArray *b = @[@20, @37, @24, @56, @27, @44, @0];
    NSArray *c = @[@12, @10, @32, @43, @19, @21, @0];
    NSArray *d = @[@22, @21, @28, @57, @18, @43, @0];
    NSArray *e = @[@10, @28, @10, @55, @27, @16, @0];
    NSArray *f = @[@10, @28, @10, @0, @18, @9, @0];
    NSArray *g = @[@12, @28, @34, @36, @19, @29, @0];
    NSArray *h = @[@20, @46, @20, @57, @9, @57, @0];
    NSArray *i = @[@10, @10, @10, @0, @57, @0, @0];
    NSArray *j = @[@10, @10, @24, @16, @19, @0, @1];
    NSArray *k = @[@21, @28, @21, @57, @13, @26, @1];
    NSArray *l = @[@10, @10, @10, @0, @9, @9, @0];
    NSArray *m = @[@36, @38, @20, @19, @11, @17, @0];
    NSArray *n = @[@30, @31, @26, @57, @17, @57, @1];
    NSArray *o = @[@24, @21, @32, @26, @19, @32, @0];
    NSArray *p = @[@20, @35, @10, @56, @17, @28, @0];
    NSArray *q = @[@24, @21, @35, @28, @19, @28, @1];
    NSArray *r = @[@20, @31, @21, @57, @18, @36, @1];
    NSArray *s = @[@10, @19, @26, @26, @31, @21, @1];
    NSArray *t = @[@10, @10, @10, @9, @57, @9, @0];
    NSArray *u = @[@21, @21, @29, @52, @9, @53, @0];
    NSArray *v = @[@22, @20, @17, @26, @12, @26, @1];
    NSArray *w = @[@36, @37, @33, @20, @25, @24, @1];
    NSArray *x = @[@22, @17, @22, @29, @18, @21, @1];
    NSArray *y = @[@21, @11, @10, @16, @35, @12, @0];
    NSArray *z = @[@12, @12, @11, @26, @35, @20, @0];
    
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
    
    NSString *letter = [@"ABCDEFGHIJKLMNOPQRSTUVWXYZ" substringWithRange:NSMakeRange(minIndex, 1)];
    if ([letter isEqualToString:@"O"] && [textColorArray.lastObject integerValue] == 1) {
        letter = @"Q";
    }
    
    return letter;
}

- (void)getLatestImageFromAlbumWithSuccess:(ImageActionBlock)success failure:(ActionBlock)failure {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    // Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        // Within the group enumeration block, filter to enumerate just photos.
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        
        // Chooses the photo at the last index
        [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:([group numberOfAssets] - 1)] options:0 usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop) {
            
            // The end of the enumeration is signaled by asset == nil.
            if (alAsset) {
                ALAssetRepresentation *representation = [alAsset defaultRepresentation];
                UIImage *latestPhoto = [UIImage imageWithCGImage:[representation fullScreenImage]];
                if (success) success(latestPhoto);
            }
        }];
    } failureBlock: ^(NSError *error) {
        if (failure) failure();
    }];
}

@end
