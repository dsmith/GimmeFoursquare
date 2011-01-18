//
//  SGAuthorizeWebViewController.m
//  SGGimmeFoursquare
//
//  Created by Derek Smith on 1/9/11.
//  Copyright 2011 Dsmitts. All rights reserved.
//

#import "SGAuthorizeWebViewController.h"

@implementation SGAuthorizeWebViewController
@synthesize url;

- (id) initWithURL:(NSURL*)url
{
    if(self = [super init]) {
        self.url = url;
    }
    
    return self;
}

- (void) viewDidLoad
{
    UIBarButtonItem* closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                 target:self
                                                                                 action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem = closeButton;
    [closeButton release];
    self.navigationItem.title = @"Authorization";

    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    CGFloat barHeight = self.navigationController.navigationBar.frame.size.height;
    CGRect viewBounds = self.view.bounds;
    UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectMake(0.0, 
                                                                     0.0,
                                                                     viewBounds.size.width,
                                                                     viewBounds.size.height - barHeight)];
    [self.view addSubview:webView];
    [webView loadRequest:request];    
}

- (void) cancel:(id)button
{
    UIWindow* window = [[UIApplication sharedApplication] keyWindow];
    [UIView beginAnimations:@"authorize_web_page" context:nil];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:window cache:NO];
    [UIView setAnimationDuration:1.5];
    [self.navigationController.view removeFromSuperview];
    [UIView commitAnimations];    
}

- (void) dealloc
{
    [url release];
    [super dealloc];
}

@end
