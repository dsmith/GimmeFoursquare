//
//  SGAuthorizeWebViewController.h
//  SGGimmeFoursquare
//
//  Created by Derek Smith on 1/9/11.
//  Copyright 2011 Dsmitts. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SGAuthorizeWebViewController : UIViewController {

    NSURL* url;

}

@property (nonatomic, retain) NSURL* url;

- (id) initWithURL:(NSURL*)url;

@end
