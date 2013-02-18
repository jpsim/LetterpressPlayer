//
//  MBViewController.h
//  LetterpressPlayer
//
//  Created by Jean-Pierre Simard on 1/23/13.
//  Copyright (c) 2013 Magnetic Bear Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MBViewController : UITableViewController {
    NSArray *masterWordList;
    NSArray *currentLetters;
    NSArray *possibleWords;
    NSArray *finalWords;
}

@end
