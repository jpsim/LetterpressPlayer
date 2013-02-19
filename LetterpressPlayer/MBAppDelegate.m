//
//  MBAppDelegate.m
//  LetterpressPlayer
//
//  Created by Jean-Pierre Simard on 1/23/13.
//  Copyright (c) 2013 Magnetic Bear Studios. All rights reserved.
//

#import "MBAppDelegate.h"
#import "MBViewController.h"

@implementation MBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[[UIAlertView alloc] initWithTitle:@"Welcome" message:@"To use this app, take a screenshot of a Letterpress game and tap \"Analyze\".\n\nTap \"Refresh\" to update the score of game you last analyzed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[MBViewController alloc] init]];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
