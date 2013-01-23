//
//  LetterpressLetter.h
//  LetterpressPlayer
//
//  Created by Jean-Pierre Simard on 1/23/13.
//  Copyright (c) 2013 Magnetic Bear Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kLetterTypeDarkRed,
    kLetterTypeLightRed,
    kLetterTypeGray,
    kLetterTypeLightBlue,
    kLetterTypeDarkBlue,
    kLetterTypeUnknown
} kLetterType;

@interface LetterpressLetter : NSObject

@property (nonatomic, assign) NSString *letter;
@property (nonatomic) kLetterType type;

@end
