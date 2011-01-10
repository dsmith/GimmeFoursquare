//
//  SGMainViewController.m
//  SGGimmeFoursquare
//
//  Created by Derek Smith on 1/7/11.
//  Copyright 2011 Dsmitts. All rights reserved.
//

#import "SGMainViewController.h"

static NSString* key = @"my_key";
static NSString* secret = @"my_secret";

@implementation SGMainViewController
@synthesize gimmeFoursquare;

- (id) init
{
    if(self = [super init]) {
        gimmeFoursquare = [[SGGimmeFoursquare alloc] initWithKey:key secret:secret];
    }
    
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    requestTokenButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    [requestTokenButton setTitle:@"Request Token" forState:UIControlStateNormal];
    requestTokenButton.frame = CGRectMake(20.0, 10.0, 280.0, 44.0);
    [requestTokenButton addTarget:gimmeFoursquare
                           action:@selector(getOAuthRequestToken)
                 forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:requestTokenButton];
    
    accessTokenButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    [accessTokenButton setTitle:@"Access Token" forState:UIControlStateNormal];
    accessTokenButton.frame = CGRectMake(20.0, 100.0, 280.0, 44.0);
    [accessTokenButton addTarget:gimmeFoursquare 
                          action:@selector(getOAuthAccessToken) 
                forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:accessTokenButton];
}

- (void) dealloc
{
    [gimmeFoursquare release];
    [super dealloc];
}

@end
