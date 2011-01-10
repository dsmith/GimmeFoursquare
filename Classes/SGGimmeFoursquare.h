//
//  SGGimmeFoursquare.m
//  GimmeFoursquare
//
//  Copyright (c) 2009-2010, SimpleGeo
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without 
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, 
//  this list of conditions and the following disclaimer. Redistributions 
//  in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution.
//  
//  Neither the name of the SimpleGeo nor the names of its contributors may
//  be used to endorse or promote products derived from this software 
//  without specific prior written permission.
//   
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS 
//  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
//  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
//  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  Created by Derek Smith.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "OAToken.h"
#import "OAConsumer.h"

@interface SGCallback : NSObject
{
    @private
    id delegate;
    SEL successMethod;
    SEL failureMethod;
}

@property (nonatomic, readonly) id delegate;
@property (nonatomic, readonly) SEL successMethod;
@property (nonatomic, readonly) SEL failureMethod;

- (id) initWithDelegate:(id)delegate successMethod:(SEL)method failureMethod:(SEL)method;

@end

@interface SGGimmeFoursquare : NSObject {

    OAConsumer* consumerToken;

    @private
    OAToken* requestToken;
    OAToken* accessToken;

}

@property (nonatomic, readonly) OAConsumer* consumer;

// The key/secret pair should be your consumer key and secret that 
// you were issued when you registered your application with Foursquare.
- (id) initWithKey:(NSString*)key secret:(NSString*)secret;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark OAuth methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

// Fetches the access token. Upon a successful request,
// the class will send the user to the mobile authenticate page
// using the SGAuthorizeWebViewController.
- (void) getOAuthAccessToken;

// Once the application recieves a valid request from the callback
// URL that is registered with Foursquare, this method should be called
// so we can begin to make requests to Foursquare's API.
- (void) getOAuthRequestToken;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Geo methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) activeCitiesCallback:(SGCallback*)callback;
- (void) closestCityToCoordinate:(CLLocationCoordinate2D)coordinate cityId:(NSString*)cityId callback:(SGCallback*)callback;
- (void) updateDefaultCity:(NSString*)cityId callback:(SGCallback*)callback;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Check in methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) checkIns:(NSString*)cityId callback:(SGCallback*)callback;
- (void) shoutMessage:(NSString*)message coordinate:(CLLocationCoordinate2D)coordinate twitter:(BOOL)enabled callback:(SGCallback*)callback;
- (void) checkIntoVenue:(NSString*)venueId coordinate:(CLLocationCoordinate2D)coordinate callback:(SGCallback*)callback;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark User methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) userInformation:(NSString*)userId badges:(BOOL)badges mayor:(BOOL)mayor callback:(SGCallback*)callback;
- (void) historySince:(NSString*)sinceid limit:(int)limit callback:(SGCallback*)callback;
- (void) friends:(NSString*)uid callback:(SGCallback*)callback;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Venue methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) venuesNearbyCoordinate:(CLLocationCoordinate2D)coordinate limit:(int)limit keyword:(NSString*)keyword callback:(SGCallback*)callback;
- (void) venueInformation:(NSString*)vid callback:(SGCallback*)callback;
- (void) addVenue:(NSString*)vid addressDictionary:(NSDictionary*)addressDictionary callback:(SGCallback*)callback;
- (void) editVenue:(NSString*)vid addressDictionary:(NSDictionary*)addressDictionary callback:(SGCallback*)callback;
- (void) venueClosed:(NSString*)vid callback:(SGCallback*)callback;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Tips methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) tipsNearbyCoordinate:(CLLocationCoordinate2D)coordinate limit:(NSInteger)limit callback:(SGCallback*)callback;
- (void) addTipToVenue:(NSString*)vid tip:(NSString*)tip type:(NSString*)type callback:(SGCallback*)callback;
- (void) markTipAsToDo:(NSString*)tid callback:(SGCallback*)callback;
- (void) markTipAsDone:(NSString*)tid callback:(SGCallback*)callback;
- (void) unmarkTip:(NSString*)tid callback:(SGCallback*)callback;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Friends methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) pendingFriendRequestsCallback:(SGCallback*)callback;
- (void) approveFriendRequest:(NSString*)uid callback:(SGCallback*)callback;
- (void) denyFriendRequest:(NSString*)uid callback:(SGCallback*)callback;
- (void) sendFriendRequest:(NSString*)uid callback:(SGCallback*)callback;
- (void) findFriendsViaName:(NSString*)keyword callback:(SGCallback*)callback;
- (void) findFriendsViaTwitter:(NSString*)keyword callback:(SGCallback*)callback;
- (void) findFriendsViaPhone:(NSString*)keyword callback:(SGCallback*)callback;

@end
