//
//  MBViewController.m
//  LetterpressPlayer
//
//  Created by Jean-Pierre Simard on 1/23/13.
//  Copyright (c) 2013 Magnetic Bear Studios. All rights reserved.
//

#import "MBViewController.h"
#import "UIImage+LPAdditions.h"
#import "UIColor+LPAdditions.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "SVProgressHUD.h"

#define kSquareSize         128.0
#define kGenerateArrays     FALSE
#define kRunTests           FALSE
#define kSortStrategyKill   TRUE

typedef enum {
    kLetterTypeDarkRed,
    kLetterTypeLightRed,
    kLetterTypeGray,
    kLetterTypeLightBlue,
    kLetterTypeDarkBlue,
    kLetterTypeUnknown
} kLetterType;

typedef void (^ActionBlock)();
typedef void (^ImageBlock)(UIImage *image);

@implementation MBViewController

#pragma mark - UI

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (kGenerateArrays) {
        [self generateArrays];
        return;
    } else if (kRunTests) {
        [self runTests];
        return;
    } else {
        [self setupUI];
    }
}

- (void)setupUI {
    finalWords = @[];
    masterWordList = [self masterWordList];
    
    self.title = @"LetterCheater";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Analyze" style:UIBarButtonItemStylePlain target:self action:@selector(analyze)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStylePlain target:self action:@selector(refreshCount)];
    self.navigationItem.rightBarButtonItem.enabled = FALSE;
}

#pragma mark - Actions

- (void)analyze {
    [self refreshWordList:NO];
}

- (void)refreshCount {
    [self refreshWordList:YES];
}

- (void)refreshWordList:(BOOL)update {
    if (!possibleWords.count) update = NO;
    
    [SVProgressHUD showWithStatus:update ? @"Refreshing counts for last image." : @"Analyzing last photo album image." maskType:SVProgressHUDMaskTypeGradient];
    
    double delayInSeconds = 0.001;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self getLatestImageFromAlbumWithSuccess:^(UIImage *image) {
            ActionBlock successBlock = ^{
                [self.tableView reloadData];
                self.navigationItem.leftBarButtonItem.enabled = TRUE;
                self.navigationItem.rightBarButtonItem.enabled = TRUE;
            };
            if (update) {
                [self updatedWordsFromImage:image success:successBlock];
            } else {
                [self finalWordsFromImage:image success:successBlock];
            }
        } failure:^{
            [SVProgressHUD showErrorWithStatus:@"Couldn't find Letterpress screenshot"];
            self.navigationItem.rightBarButtonItem.enabled = FALSE;
        }];
    });
}

#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return finalWords.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.textLabel.text = [finalWords objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - Global

- (void)finalWordsFromImage:(UIImage *)image success:(ActionBlock)success {
    [SVProgressHUD showWithStatus:@"Extracting Colors" maskType:SVProgressHUDMaskTypeGradient];
    double delayInSeconds = 0.001;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSArray *colors = [self colorArrayFromImage:image];
        [SVProgressHUD showWithStatus:@"Extracting Letters" maskType:SVProgressHUDMaskTypeGradient];
        double delayInSeconds = 0.001;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            currentLetters = [self letterArrayFromImage:image];
            [SVProgressHUD showWithStatus:@"Generating Words" maskType:SVProgressHUDMaskTypeGradient];
            double delayInSeconds = 0.001;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                possibleWords = [self wordsForLetterArray:currentLetters];
                [SVProgressHUD showWithStatus:@"Sorting Words" maskType:SVProgressHUDMaskTypeGradient];
                double delayInSeconds = 0.001;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    finalWords = [self wordsSortedByScores:possibleWords letters:currentLetters colors:colors];
                    [SVProgressHUD showSuccessWithStatus:[self scoreFromColors:colors]];
                    if (success) success();
                });
            });
        });
    });
}

- (void)updatedWordsFromImage:(UIImage *)image success:(ActionBlock)success {
    [SVProgressHUD showWithStatus:@"Extracting Colors" maskType:SVProgressHUDMaskTypeGradient];
    double delayInSeconds = 0.01;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSArray *colors = [self colorArrayFromImage:image];
        [SVProgressHUD showWithStatus:@"Sorting Words" maskType:SVProgressHUDMaskTypeGradient];
        double delayInSeconds = 0.01;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            finalWords = [self wordsSortedByScores:possibleWords letters:currentLetters colors:colors];
            [SVProgressHUD showSuccessWithStatus:[self scoreFromColors:colors]];
            if (success) success();
        });
    });
}

#pragma mark - Screenshot Parsing

- (void)getLatestImageFromAlbumWithSuccess:(ImageBlock)success failure:(ActionBlock)failure {
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

#pragma mark - Letters

- (NSArray *)letterArrayFromImage:(UIImage *)screenshot {
    NSMutableArray *letters = @[].mutableCopy;
    NSArray *textColorArray = @[@(0.09411765), @(0.1568628), @(0.1921569)];
    [[self imageArrayFromImage:screenshot] enumerateObjectsUsingBlock:^(UIImage *image, NSUInteger idx, BOOL *stop) {
        NSInteger widthInt = floor(image.size.width);
        NSInteger heightInt = floor(image.size.height);
        
        NSInteger grayHorizontal1 = 0;
        NSMutableArray *grayHorizontalPoints1 = [[NSMutableArray alloc] initWithCapacity:widthInt];
        for (int i = 0; i < widthInt; i++) {
            [grayHorizontalPoints1 addObject:[NSValue valueWithCGPoint:CGPointMake(i, 48)]];
        }
        NSArray *grayHorizontalColors1 = [image colorComponentsAtPoints:grayHorizontalPoints1];
        for (NSArray *components in grayHorizontalColors1) {
            if ([self deviationBetweenArray:components andReference:textColorArray] < 1) grayHorizontal1++;
        }
        
        NSInteger grayHorizontal2 = 0;
        NSMutableArray *grayHorizontalPoints2 = [[NSMutableArray alloc] initWithCapacity:widthInt];
        for (int i = 0; i < widthInt; i++) {
            [grayHorizontalPoints2 addObject:[NSValue valueWithCGPoint:CGPointMake(i, 64)]];
        }
        NSArray *grayHorizontalColors2 = [image colorComponentsAtPoints:grayHorizontalPoints2];
        for (NSArray *components in grayHorizontalColors2) {
            if ([self deviationBetweenArray:components andReference:textColorArray] < 1) grayHorizontal2++;
        }
        
        NSInteger grayHorizontal3 = 0;
        NSMutableArray *grayHorizontalPoints3 = [[NSMutableArray alloc] initWithCapacity:widthInt];
        for (int i = 0; i < widthInt; i++) {
            [grayHorizontalPoints3 addObject:[NSValue valueWithCGPoint:CGPointMake(i, 80)]];
        }
        NSArray *grayHorizontalColors3 = [image colorComponentsAtPoints:grayHorizontalPoints3];
        for (NSArray *components in grayHorizontalColors3) {
            if ([self deviationBetweenArray:components andReference:textColorArray] < 1) grayHorizontal3++;
        }
        
        NSInteger grayVertical1 = 0;
        NSMutableArray *grayVerticalPoints1 = [[NSMutableArray alloc] initWithCapacity:heightInt];
        for (int i = 0; i < heightInt; i++) {
            [grayVerticalPoints1 addObject:[NSValue valueWithCGPoint:CGPointMake(48, i)]];
        }
        NSArray *grayVerticalColors1 = [image colorComponentsAtPoints:grayVerticalPoints1];
        for (NSArray *components in grayVerticalColors1) {
            if ([self deviationBetweenArray:components andReference:textColorArray] < 1) grayVertical1++;
        }
        
        NSInteger grayVertical2 = 0;
        NSMutableArray *grayVerticalPoints2 = [[NSMutableArray alloc] initWithCapacity:heightInt];
        for (int i = 0; i < heightInt; i++) {
            [grayVerticalPoints2 addObject:[NSValue valueWithCGPoint:CGPointMake(64, i)]];
        }
        NSArray *grayVerticalColors2 = [image colorComponentsAtPoints:grayVerticalPoints2];
        for (NSArray *components in grayVerticalColors2) {
            if ([self deviationBetweenArray:components andReference:textColorArray] < 1) grayVertical2++;
        }
        
        NSInteger grayVertical3 = 0;
        NSMutableArray *grayVerticalPoints3 = [[NSMutableArray alloc] initWithCapacity:heightInt];
        for (int i = 0; i < heightInt; i++) {
            [grayVerticalPoints3 addObject:[NSValue valueWithCGPoint:CGPointMake(80, i)]];
        }
        NSArray *grayVerticalColors3 = [image colorComponentsAtPoints:grayVerticalPoints3];
        for (NSArray *components in grayVerticalColors3) {
            if ([self deviationBetweenArray:components andReference:textColorArray] < 1) grayVertical3++;
        }
        
        NSInteger qPoint = 0;
        if ([self deviationBetweenArray:[[image colorAtPoint:CGPointMake(88, 88)] components] andReference:textColorArray] < 1) {
            qPoint = 1;
        }
        
        if (kGenerateArrays) {
            NSLog(@"NSArray *%@ = @[@%d, @%d, @%d, @%d, @%d, @%d, @%d];", [@"abcdefghijklmnopqrstuvwxyz" substringWithRange:NSMakeRange(idx, 1)], grayHorizontal1, grayHorizontal2, grayHorizontal3, grayVertical1, grayVertical2, grayVertical3, qPoint);
        } else {
            NSString *letter = [self stringForCellWithTextColorArray:@[@(grayHorizontal1), @(grayHorizontal2), @(grayHorizontal3), @(grayVertical1), @(grayVertical2), @(grayVertical3), @(qPoint)]];
            [letters addObject:letter];
        }
    }];
    
    return letters;
}

- (NSString *)stringForCellWithTextColorArray:(NSArray *)textColorArray {
    NSArray *a = @[@18, @20, @21, @26, @19, @25, @0];
    NSArray *b = @[@20, @37, @24, @56, @27, @44, @0];
    NSArray *c = @[@12, @10, @32, @43, @19, @21, @0];
    NSArray *d = @[@22, @21, @28, @57, @18, @43, @0];
    NSArray *e = @[@10, @28, @10, @55, @27, @16, @0];
    NSArray *f = @[@10, @28, @10, @0, @18, @9, @0];
    NSArray *g = @[@12, @28, @34, @36, @19, @29, @1];
    NSArray *h = @[@20, @46, @20, @57, @9, @57, @0];
    NSArray *i = @[@10, @10, @10, @0, @57, @0, @0];
    NSArray *j = @[@10, @10, @24, @16, @19, @0, @0];
    NSArray *k = @[@21, @28, @21, @57, @13, @26, @0];
    NSArray *l = @[@10, @10, @10, @0, @9, @9, @0];
    NSArray *m = @[@36, @38, @20, @19, @11, @17, @1];
    NSArray *n = @[@30, @31, @26, @57, @17, @57, @0];
    NSArray *o = @[@24, @21, @32, @26, @19, @32, @0];
    NSArray *p = @[@20, @35, @10, @56, @17, @28, @0];
    NSArray *q = @[@24, @21, @35, @28, @19, @28, @1];
    NSArray *r = @[@20, @31, @21, @57, @18, @36, @0];
    NSArray *s = @[@10, @19, @26, @26, @31, @21, @0];
    NSArray *t = @[@10, @10, @10, @9, @57, @9, @0];
    NSArray *u = @[@21, @21, @29, @52, @9, @53, @0];
    NSArray *v = @[@22, @20, @17, @26, @12, @26, @0];
    NSArray *w = @[@36, @37, @33, @20, @25, @24, @0];
    NSArray *x = @[@22, @17, @22, @29, @18, @21, @0];
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
    
    NSString *letter = [@"abcdefghijklmnopqrstuvwxyz" substringWithRange:NSMakeRange(minIndex, 1)];
    if ([letter isEqualToString:@"o"] && [textColorArray.lastObject integerValue] == 1) {
        letter = @"q";
    }
    
    return letter;
}

- (CGFloat)deviationBetweenArray:(NSArray *)array andReference:(NSArray *)reference {
    if (array.count != reference.count) return MAXFLOAT;
    CGFloat deviation = 0;
    for (int i = 0; i < array.count; i++) {
        deviation += fabsf([[array objectAtIndex:i] floatValue] - [[reference objectAtIndex:i] floatValue]);
    }
    return deviation;
}

#pragma mark - Colors

- (NSArray *)colorArrayFromImage:(UIImage *)image {
    NSMutableArray *colorArray = @[].mutableCopy;
    NSArray *squareImages = [self imageArrayFromImage:image];
    for (UIImage *squareImage in squareImages) {
        NSInteger type = [self letterTypeForColor:[squareImage colorAtPoint:CGPointMake(10, 10)]];
        [colorArray addObject:@(type)];
    }
    
    return colorArray;
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

#pragma mark - Score

- (NSString *)scoreFromColors:(NSArray *)colors {
    NSInteger me = 0;
    NSInteger opponent = 0;
    for (NSNumber *n in colors) {
        switch (n.integerValue) {
            case kLetterTypeDarkBlue:
                me++;
                break;
                
            case kLetterTypeLightBlue:
                me++;
                break;
                
            case kLetterTypeDarkRed:
                opponent++;
                break;
                
            case kLetterTypeLightRed:
                opponent++;
                
            default:
                break;
        }
    }
    
    return [NSString stringWithFormat:@"Current Score\nMe: %d\nOpponent: %d", me, opponent];
}

#pragma mark - Words

- (NSArray *)masterWordList {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"en_longest_to_shortest" ofType:@"txt"];
    NSString *wordlist = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    NSArray *words = [wordlist componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return words;
}

- (NSArray *)wordsForLetterArray:(NSArray *)letterArray {
    NSMutableString *letterArrayString = @"".mutableCopy;
    for (NSString *letter in letterArray) {
        [letterArrayString appendString:letter];
    }
    NSCharacterSet *blockSet = [NSCharacterSet characterSetWithCharactersInString:letterArrayString];
    
    NSMutableArray *matchedWords = @[].mutableCopy;
    for (NSString *word in masterWordList) {
        if ([blockSet isSupersetOfSet:[NSCharacterSet characterSetWithCharactersInString:word]]) {
            NSMutableArray *charactersLeft = letterArray.mutableCopy;
            for (NSString *c in [self charactersFromString:word]) {
                NSUInteger indexOfLetter = [charactersLeft indexOfObject:c];
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
    }
    return matchedWords;
}

- (NSArray *)wordsSortedByScores:(NSArray *)words letters:(NSArray *)letters colors:(NSArray *)colors {
    NSMutableArray *wordScores = [[NSMutableArray alloc] initWithCapacity:words.count];
    NSMutableArray *actualWordScores = [[NSMutableArray alloc] initWithCapacity:words.count];
    NSMutableArray *letterScores = [[NSMutableArray alloc] initWithCapacity:colors.count];
    NSMutableArray *mWords = [[NSMutableArray alloc] initWithCapacity:words.count];
    
    for (NSNumber *n in colors) {
        NSInteger letterScore = 0;
        if (n.integerValue == kLetterTypeGray) {
            letterScore = 1;
        } else if (n.integerValue == kLetterTypeLightRed) {
            letterScore = 2;
        }
        [letterScores addObject:@(letterScore)];
    }
    
    for (NSString *word in words) {
        NSMutableArray *mLetters = letters.mutableCopy;
        NSMutableArray *mLetterScores = letterScores.mutableCopy;
        NSInteger wordScore = 0;
        NSInteger actualWordScore = 0;
        for (NSString *c in [self charactersFromString:word]) {
            __block NSInteger bestScore = 0;
            __block NSInteger bestIndex = 0;
            [mLetters enumerateObjectsUsingBlock:^(NSString *letter, NSUInteger idx, BOOL *stop) {
                if ([letter isEqualToString:c]) {
                    NSInteger letterScore = [[mLetterScores objectAtIndex:idx] integerValue];
                    if (letterScore > bestScore) {
                        bestScore = letterScore;
                        bestIndex = idx;
                    }
                }
            }];
            wordScore += bestScore;
            actualWordScore += bestScore ? 1 : 0;
            [mLetters removeObjectAtIndex:bestIndex];
            [mLetterScores removeObjectAtIndex:bestIndex];
        }
        [wordScores addObject:@(wordScore)];
        [actualWordScores addObject:@(actualWordScore)];
        [mWords addObject:[NSString stringWithFormat:@"%d/%d: %@", wordScore, actualWordScore, word]];
    }
    
    NSArray *sorter = kSortStrategyKill ? wordScores : actualWordScores;
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:sorter forKeys:mWords];
    NSArray *sortedWords = [dict keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        int int1 = [obj1 integerValue];
        int int2 = [obj2 integerValue];
        if (int1 == int2) return NSOrderedSame;
        return (int1 < int2 ? NSOrderedAscending : NSOrderedDescending);
    }];
    
    return [[sortedWords reverseObjectEnumerator] allObjects];
}

- (NSArray *)charactersFromString:(NSString *)string {
    NSMutableArray *characters = [[NSMutableArray alloc] initWithCapacity:string.length];
    for (int i = 0; i < string.length; i++) {
        [characters addObject:[string substringWithRange:NSMakeRange(i, 1)]];
    }
    return characters;
}

#pragma mark - Generate

- (void)generateArrays {
    [self letterArrayFromImage:[UIImage imageNamed:@"l13"]];
    NSLog(@"----------- the only one left is 'z', look for 'o'");
    [self letterArrayFromImage:[UIImage imageNamed:@"l2"]];
}

#pragma mark - Tests

- (void)runTests {
    for (int i = 0; i <= 13; i++) {
        NSString *imageName = [NSString stringWithFormat:@"l%d", i];
        NSArray *letterArray = [self letterArrayFromImage:[UIImage imageNamed:imageName]];
        BOOL valid = [self validateLetterArray:letterArray forTestImage:imageName];
        NSLog(@"%@ is %@", imageName, valid ? @"valid" : @"invalid");
        if (!valid) NSLog(@"letterArray: %@", letterArray);
    }
}

- (BOOL)validateLetterArray:(NSArray *)letterArray forTestImage:(NSString *)testImage {
    if ([testImage isEqualToString:@"l0"]) {
        return [letterArray isEqualToArray:@[@"k", @"k", @"o", @"p", @"w", @"q", @"h", @"v", @"a", @"i", @"a", @"e", @"d", @"r", @"l", @"s", @"h", @"k", @"e", @"w", @"l", @"x", @"e", @"a", @"v"]];
        
    } else if ([testImage isEqualToString:@"l1"]) {
        return [letterArray isEqualToArray:@[@"h", @"w", @"d", @"s", @"v", @"u", @"n", @"r", @"i", @"c", @"v", @"f", @"e", @"c", @"n", @"t", @"o", @"d", @"d", @"y", @"b", @"f", @"p", @"i", @"x"]];
        
    } else if ([testImage isEqualToString:@"l2"]) {
        return [letterArray isEqualToArray:@[@"e", @"w", @"a", @"k", @"r", @"p", @"i", @"b", @"d", @"t", @"a", @"c", @"r", @"p", @"z", @"d", @"y", @"e", @"s", @"f", @"g", @"t", @"t", @"s", @"a"]];
        
    } else if ([testImage isEqualToString:@"l3"]) {
        return [letterArray isEqualToArray:@[@"c", @"h", @"r", @"z", @"d", @"s", @"t", @"u", @"o", @"d", @"m", @"i", @"w", @"h", @"t", @"z", @"y", @"s", @"r", @"r", @"s", @"i", @"y", @"p", @"i"]];
        
    } else if ([testImage isEqualToString:@"l4"]) {
        return [letterArray isEqualToArray:@[@"n", @"m", @"m", @"n", @"n", @"n", @"n", @"d", @"o", @"w", @"p", @"m", @"w", @"s", @"o", @"d", @"u", @"g", @"i", @"c", @"e", @"z", @"l", @"g", @"r"]];
        
    } else if ([testImage isEqualToString:@"l5"]) {
        return [letterArray isEqualToArray:@[@"p", @"e", @"s", @"s", @"v", @"t", @"o", @"x", @"p", @"o", @"i", @"u", @"w", @"o", @"z", @"c", @"n", @"x", @"h", @"p", @"c", @"f", @"l", @"u", @"i"]];
        
    } else if ([testImage isEqualToString:@"l6"]) {
        return [letterArray isEqualToArray:@[@"y", @"f", @"u", @"m", @"v", @"x", @"p", @"a", @"v", @"x", @"o", @"n", @"m", @"m", @"n", @"m", @"i", @"q", @"h", @"e", @"a", @"i", @"g", @"m", @"c"]];
        
    } else if ([testImage isEqualToString:@"l7"]) {
        return [letterArray isEqualToArray:@[@"a", @"o", @"e", @"b", @"t", @"l", @"m", @"f", @"s", @"v", @"o", @"c", @"s", @"v", @"b", @"o", @"s", @"z", @"r", @"z", @"t", @"s", @"c", @"w", @"p"]];
        
    } else if ([testImage isEqualToString:@"l8"]) {
        return [letterArray isEqualToArray:@[@"s", @"t", @"n", @"w", @"c", @"h", @"v", @"b", @"r", @"p", @"g", @"i", @"h", @"n", @"u", @"h", @"m", @"u", @"k", @"t", @"o", @"t", @"j", @"i", @"e"]];
        
    } else if ([testImage isEqualToString:@"l9"]) {
        return [letterArray isEqualToArray:@[@"r", @"a", @"i", @"p", @"e", @"v", @"t", @"m", @"s", @"y", @"p", @"f", @"c", @"b", @"y", @"s", @"y", @"c", @"w", @"i", @"o", @"b", @"r", @"m", @"l"]];
        
    } else if ([testImage isEqualToString:@"l10"]) {
        return [letterArray isEqualToArray:@[@"o", @"z", @"s", @"d", @"a", @"t", @"l", @"s", @"g", @"y", @"y", @"e", @"t", @"l", @"t", @"b", @"i", @"f", @"y", @"s", @"y", @"a", @"v", @"c", @"t"]];
        
    } else if ([testImage isEqualToString:@"l11"]) {
        return [letterArray isEqualToArray:@[@"s", @"p", @"t", @"a", @"d", @"r", @"l", @"o", @"n", @"p", @"n", @"e", @"e", @"n", @"p", @"s", @"v", @"y", @"o", @"x", @"l", @"m", @"x", @"o", @"x"]];
        
    } else if ([testImage isEqualToString:@"l12"]) {
        return [letterArray isEqualToArray:@[@"q", @"g", @"e", @"f", @"j", @"v", @"i", @"f", @"b", @"w", @"m", @"k", @"r", @"m", @"e", @"n", @"s", @"i", @"p", @"p", @"m", @"v", @"v", @"u", @"e"]];
        
    } else if ([testImage isEqualToString:@"l13"]) {
        return [letterArray isEqualToArray:@[@"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i", @"j", @"k", @"l", @"m", @"n", @"o", @"p", @"q", @"r", @"s", @"t", @"u", @"v", @"w", @"x", @"y"]];
        
    }
    return NO;
}

@end
