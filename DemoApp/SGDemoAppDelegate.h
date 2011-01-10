//
//  SGDemoAppDelegate.h
//  SGGimmeFoursquare
//
//  Created by Derek Smith on 1/7/11.
//  Copyright 2011 Dsmitts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SGMainViewController.h"

@interface SGDemoAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;

    @private
    SGMainViewController* mvc;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

