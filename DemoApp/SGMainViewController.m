//
//  SGMainViewController.m
//  SGGimmeFoursquare
//
//  Created by Derek Smith on 1/7/11.
//  Copyright 2011 Dsmitts. All rights reserved.
//

#import "SGMainViewController.h"

#import "SGAuthorizeWebViewController.h"

static NSString* key = @"my_key";
static NSString* secret = @"my_secret";

@implementation SGMainViewController
@synthesize gimmeFoursquare;

- (id) init
{
    if(self = [super init]) {
        gimmeFoursquare = [[SGGimmeFoursquare alloc] initWithKey:key secret:secret delegate:self];
        locationManager = [[CLLocationManager alloc] init];
        [locationManager startUpdatingLocation];
        flipped = NO;
    }
    
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    requestTokenButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    [requestTokenButton setTitle:@"Request Access Token" forState:UIControlStateNormal];
    requestTokenButton.frame = CGRectMake(20.0, 10.0, 280.0, 44.0);
    [requestTokenButton addTarget:self
                           action:@selector(authorize)
                 forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:requestTokenButton];
        
    nearbyVenuesButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    [nearbyVenuesButton setTitle:@"Nearby Venues" forState:UIControlStateNormal];
    nearbyVenuesButton.frame = CGRectMake(20.0, 190.0, 280.0, 44.0);
    [nearbyVenuesButton addTarget:self 
                          action:@selector(nearbyVenues) 
                forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nearbyVenuesButton];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark OAuth 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) flip
{
    // Update this code if you do not want the default
    // behavior after a request token has been recieved.
    UIWindow* window = [[UIApplication sharedApplication] keyWindow];
    if(flipped) {
        [UIView beginAnimations:@"authorize_web_page" context:nil];
        [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:window cache:NO];
        [UIView setAnimationDuration:1.5];
        [window.rootViewController.view removeFromSuperview];
        [UIView commitAnimations];    
    } else {
        NSURL* url = [gimmeFoursquare authorizationURLWithRedirectURL:[NSURL URLWithString:@"gimmefoursquare://"]];
        SGAuthorizeWebViewController* webViewController = [[SGAuthorizeWebViewController alloc] initWithURL:url];
        UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:webViewController];
        
        UIWindow* window = [[UIApplication sharedApplication] keyWindow];
        window.rootViewController = navigationController;
        [UIView beginAnimations:@"authorize_web_page" context:nil];
        [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:window cache:NO];
        [UIView setAnimationDuration:1.5];
        [window addSubview:navigationController.view];
        [UIView commitAnimations];    
    }
    
    flipped = !flipped;
}

- (void) authorize
{ 
    [gimmeFoursquare requestAccess];
}

- (void) nearbyVenues
{
    SGCallback* callback = [[SGCallback callbackWithDelegate:self
                                              successMethod:@selector(didFinishWithData:)
                                              failureMethod:@selector(didFailWithError:)] retain];
    CLLocationCoordinate2D currentLocation = [locationManager location].coordinate;
    [gimmeFoursquare venuesNearbyCoordinate:currentLocation
                                      limit:10
                                    keyword:nil 
                                   callback:callback];
    
}

- (void) didFinishWithData:(NSData*)data
{
    NSLog(@"Incoming payload: \n\n%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
}

- (void) didFailWithError:(NSError*)error
{
    NSLog(@"Error fetching nearby results: %@", [error description]);
}

- (void) oauthClientNeedsAuthentication:(NXOAuth2Client*)client
{
    [self flip];
}

- (void) oauthClientDidGetAccessToken:(NXOAuth2Client*)client
{
    if(flipped)
        [self flip];
}

- (void) oauthClientDidLoseAccessToken:(NXOAuth2Client*)client
{
    NSLog(@"Lost the access token");
}

- (void) dealloc
{
    [gimmeFoursquare release];
    [locationManager release];
    [super dealloc];
}

@end
