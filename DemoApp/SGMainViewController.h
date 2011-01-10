//
//  SGMainViewController.h
//  SGGimmeFoursquare
//
//  Created by Derek Smith on 1/7/11.
//  Copyright 2011 Dsmitts. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SGGimmeFoursquare.h"

@interface SGMainViewController : UIViewController {

    UIButton* accessTokenButton;
    UIButton* requestTokenButton;
    
    SGGimmeFoursquare* gimmeFoursquare;
}

@property (nonatomic, readonly) SGGimmeFoursquare* gimmeFoursquare;

@end
