//
//  SGDemoAppDelegate.m
//  SGGimmeFoursquare
//
//  Created by Derek Smith on 1/7/11.
//  Copyright 2011 Dsmitts. All rights reserved.
//

#import "SGDemoAppDelegate.h"

@implementation SGDemoAppDelegate
@synthesize window;

- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions 
{    
    mvc = [[SGMainViewController alloc] init];
    [window addSubview:mvc.view];
    [window makeKeyAndVisible];
    return YES;
}

- (BOOL) application:(UIApplication *)application handleOpenURL:(NSURL*)url 
{
    [mvc.gimmeFoursquare openRedirectURL:url];
    return YES;
}

- (void) dealloc
{
    [window release];
    [super dealloc];
}

@end
