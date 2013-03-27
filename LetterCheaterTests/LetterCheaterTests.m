//
//  LetterCheaterTests.m
//  LetterCheaterTests
//
//  Created by Jean-Pierre Simard on 3/27/13.
//  Copyright (c) 2013 Magnetic Bear Studios. All rights reserved.
//

#import "LetterCheaterTests.h"
#import "MBViewController.h"

@implementation LetterCheaterTests

- (void)testReferenceImages {
    STAssertTrue([[[MBViewController alloc] init] runTests], @"All reference images are properly analyzed.");
}

@end
