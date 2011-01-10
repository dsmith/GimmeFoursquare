//
//  SGAuthorizeWebViewController.h
//  SGGimmeFoursquare
//
//  Created by Derek Smith on 1/9/11.
//  Copyright 2011 Dsmitts. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OAToken.h"

@interface SGAuthorizeWebViewController : UIViewController {

    OAToken* requestToken;
}

@property (nonatomic, retain) OAToken* requestToken;

@end
