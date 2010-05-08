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

@protocol SGGimmeFoursquareDelegate;

@interface SGGimmeFoursquare : NSObject {

    @private
    NSString* username;
    NSString* password;
    NSString* encodedAuthString;
    
    NSOperationQueue* operationQueue;
    
    NSMutableArray* delegates;
}

@property (nonatomic, readonly) NSOperationQueue* operationQueue;

+ (SGGimmeFoursquare*) sharedGimmeFoursquare;
+ (void) setSharedGimmeFoursquare:(SGGimmeFoursquare*)gimmeFoursquare;

- (void) addDelegate:(id<SGGimmeFoursquareDelegate>)delegate;
- (void) removeDelegate:(id<SGGimmeFoursquareDelegate>)delegate;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Validation methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (BOOL) resumeSesssion;
- (void) clearSession;
- (NSString*) validateUsername:(NSString*)username password:(NSString*)password;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Geo methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) activeCities; 
- (NSString*) closestCityToCoordinate:(CLLocationCoordinate2D)coordinate cityId:(NSString*)cityId;
- (NSString*) updateDefaultCity:(NSString*)cityId;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Check in methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) checkIns:(NSString*)cityId;
- (NSString*) shoutMessage:(NSString*)message coordinate:(CLLocationCoordinate2D)coordinate twitter:(BOOL)enabled;
- (NSString*) checkIntoVenue:(NSString*)venueId coordinate:(CLLocationCoordinate2D)coordinate;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark User methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) userInformation:(NSString*)userId badges:(BOOL)badges mayor:(BOOL)mayor;
- (NSString*) historySince:(NSString*)sinceid limit:(int)limit;
- (NSString*) friends:(NSString*)uid;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Venue methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) venuesNearbyCoordinate:(CLLocationCoordinate2D)coordinate limit:(int)limit keyword:(NSString*)keyword;
- (NSString*) venueInformation:(NSString*)vid;
- (NSString*) addVenue:(NSString*)vid addressDictionary:(NSDictionary*)addressDictionary;
- (NSString*) editVenue:(NSString*)vid addressDictionary:(NSDictionary*)addressDictionary;
- (NSString*) venueClosed:(NSString*)vid;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Tips methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) tipsNearbyCoordinate:(CLLocationCoordinate2D)coordinate limit:(NSInteger)limit;
- (NSString*) addTipToVenue:(NSString*)vid tip:(NSString*)tip type:(NSString*)type;
- (NSString*) markTipAsToDo:(NSString*)tid;
- (NSString*) markTipAsDone:(NSString*)tid;
- (NSString*) unmarkTip:(NSString*)tid;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Friends methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) pendingFriendRequests;
- (NSString*) approveFriendRequest:(NSString*)uid;
- (NSString*) denyFriendRequest:(NSString*)uid;
- (NSString*) sendFriendRequest:(NSString*)uid;
- (NSString*) findFriendsViaName:(NSString*)keyword;
- (NSString*) findFriendsViaTwitter:(NSString*)keyword;
- (NSString*) findFriendsViaPhone:(NSString*)keyword;

@end

@protocol SGGimmeFoursquareDelegate

- (void) fourSquare:(SGGimmeFoursquare*)fourSquare requestSucceeded:(NSString*)requestId responseObject:(id)responseObject;
- (void) fourSquare:(SGGimmeFoursquare*)fourSquare requestFailed:(NSString*)requestId error:(NSError*)error;

@end

