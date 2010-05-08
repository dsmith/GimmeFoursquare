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
- (NSString*) friends;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Venue methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) venuesNearbyCoordinate:(CLLocationCoordinate2D)coordinate withinRadius:(double)radius amount:(int)amount keyword:(NSString*)keyword;
- (NSString*) venueInformation:(NSString*)vid;

//name - the name of the venue
//address - the address of the venue (e.g., "202 1st Avenue")
//crossstreet - the cross streets (e.g., "btw Grand & Broome")
//city - the city name where this venue is
//state - the state where the city is
//zip - (optional) the ZIP code for the venue
//cityid - (required) the foursquare cityid where the venue is
//phone - (optional) the phone number for the venue

- (NSString*) addVenue:(NSString*)name addressDictionary:(NSDictionary*)addressDictionary;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Tips methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) tipsNearbyCoordinate:(CLLocationCoordinate2D)coordinate limit:(NSInteger)limit;
- (NSString*) addTipToVenue:(NSString*)vid tip:(NSString*)tip type:(NSString*)type;


////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Favorites 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) getFavorites:(NSString*)username;
- (NSString*) addFavorite:(NSString*)venueId;
- (NSString*) removeFavorite:(NSString*)venueId;

@end

@protocol SGGimmeFoursquareDelegate

- (void) fourSquare:(SGGimmeFoursquare*)fourSquare requestSucceeded:(NSString*)requestId responseObject:(id)responseObject;
- (void) fourSquare:(SGGimmeFoursquare*)fourSquare requestFailed:(NSString*)requestId error:(NSError*)error;

@end

