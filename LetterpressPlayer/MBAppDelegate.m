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
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[MBViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
