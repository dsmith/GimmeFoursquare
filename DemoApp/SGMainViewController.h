//
//  SGMainViewController.h
//  SGGimmeFoursquare
//
//  Created by Derek Smith on 1/7/11.
//  Copyright 2011 Dsmitts. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SGGimmeFoursquare.h"

@interface SGMainViewController : UIViewController <NXOAuth2ClientDelegate> {

    UIButton* accessTokenButton;
    UIButton* requestTokenButton;
    UIButton* nearbyVenuesButton;
    
    SGGimmeFoursquare* gimmeFoursquare;
    CLLocationManager* locationManager;
    
    @private
    BOOL flipped;
}

@property (nonatomic, readonly) SGGimmeFoursquare* gimmeFoursquare;

@end
