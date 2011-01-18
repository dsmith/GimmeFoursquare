//
//  SGGimmeFoursquare.h
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

#import "SGGimmeFoursquare.h"

#import "NSStringAdditions.h"

static NSString* foursquareURL = @"https://api.foursquare.com/v2";

@interface SGGimmeFoursquare (Private)

- (void) sendHTTPRequest:(NSString*)type 
                   toURL:(NSString*)url
              withParams:(NSDictionary*)httpBody 
                callback:(SGCallback*)callback;

- (NSMutableDictionary*) getLatLonParams:(CLLocationCoordinate2D)coordinate;

- (NSString*) normalizeRequestParams:(NSDictionary*)params;
- (void) reloadCache;

- (void) _updateStatus:(NSString*)status ofTip:(NSString*)tid callback:(SGCallback*)callback;
- (void) _updateFriendRequest:(NSString*)uid status:(NSString*)status callback:(SGCallback*)callback;
- (void) _findFriends:(NSString*)keyword byMedium:(NSString*)meduim callback:(SGCallback*)callback;

@end

@implementation SGGimmeFoursquare

- (id) initWithKey:(NSString*)key secret:(NSString*)secret delegate:(id<NXOAuth2ClientDelegate, NSObject>)del
{
    if(self = [super initWithClientID:key
                         clientSecret:secret
                         authorizeURL:[NSURL URLWithString:@"https://foursquare.com/oauth2/authenticate"]
                             tokenURL:[NSURL URLWithString:@"https://foursquare.com/oauth2/access_token"]
                             delegate:del])
        ;
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Geo methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) activeCitiesCallback:(SGCallback*)callback
{
    [self sendHTTPRequest:@"GET"
                    toURL:@"/cities"
               withParams:nil
                 callback:callback];
}

- (void) closestCityToCoordinate:(CLLocationCoordinate2D)coordinate cityId:(NSString*)cityId callback:(SGCallback*)callback
{
    NSMutableDictionary* params = [self getLatLonParams:coordinate];
    if(cityId)
        [params setObject:cityId forKey:@"cityid"];
    [self sendHTTPRequest:@"GET"
                    toURL:@"/checkcity"
               withParams:params
                 callback:callback];
}

- (void) updateDefaultCity:(NSString*)cityId callback:(SGCallback*)callback
{
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:cityId, @"cityid", nil];    
    [self sendHTTPRequest:@"POST"
                    toURL:@"/switchcity"
               withParams:params
                 callback:callback];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Check in methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) checkIns:(NSString*)cityId callback:(SGCallback*)callback
{
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:cityId, @"cityid", nil];    
    [self sendHTTPRequest:@"GET"
                    toURL:@"/checkins"
               withParams:params
                 callback:callback];
}

- (void) shoutMessage:(NSString*)message coordinate:(CLLocationCoordinate2D)coordinate twitter:(BOOL)enabled callback:(SGCallback*)callback
{
    NSMutableDictionary* params = [self getLatLonParams:coordinate];
    [params setObject:[NSString stringWithFormat:@"%i", enabled] forKey:@"twitter"];
    [params setObject:message forKey:@"shout"];
    [self sendHTTPRequest:@"POST"
                    toURL:@"/checkin"
               withParams:params
                 callback:callback];
}

- (void) checkIntoVenue:(NSString*)vid coordinate:(CLLocationCoordinate2D)coord callback:(SGCallback*)callback
{
    NSMutableDictionary* params = [self getLatLonParams:coord];
    [params setObject:vid forKey:@"vid"];
    
    [self sendHTTPRequest:@"POST"
                    toURL:@"/checkin"
               withParams:params
                 callback:callback];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark User methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) userInformation:(NSString*)userId badges:(BOOL)badges mayor:(BOOL)mayor callback:(SGCallback*)callback
{
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%i", badges], @"badges",
                                   [NSString stringWithFormat:@"%i", badges], @"mayor",
                                   nil];
    if(userId)
        [params setObject:userId forKey:@"uid"];

    [self sendHTTPRequest:@"GET"
                    toURL:@"/user"
               withParams:params
                 callback:callback];
}

- (void) historySince:(NSString*)sinceid limit:(int)limit callback:(SGCallback*)callback
{
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    
    if(sinceid)
        [params setObject:sinceid forKey:@"sinceid"];
    
    if(limit > 0)
        [params setObject:[NSString stringWithFormat:@"%i", limit] forKey:@"l"];
    
    [self sendHTTPRequest:@"GET"
                    toURL:@"/history"
               withParams:params
                 callback:callback];
}

- (void) friends:(NSString*)uid callback:(SGCallback*)callback
{
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    if(uid)
        [params setObject:uid forKey:@"uid"];
    
    [self sendHTTPRequest:@"GET"
                    toURL:@"/friends"
               withParams:params
                 callback:callback];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Venue methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) venuesNearbyCoordinate:(CLLocationCoordinate2D)coordinate limit:(int)limit keyword:(NSString*)keyword callback:(SGCallback*)callback
{
    NSMutableDictionary* params = [self getLatLonParams:coordinate];
    if(limit > 0)
        [params setObject:[NSString stringWithFormat:@"%i", limit] forKey:@"limit"];
    
    if(keyword)
        [params setObject:keyword forKey:@"query"];
    
    [self sendHTTPRequest:@"GET"
                    toURL:@"/venues/search"
               withParams:params
                 callback:callback];
}

- (void) venueInformation:(NSString*)vid callback:(SGCallback*)callback
{
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:vid, @"vid", nil];

    [self sendHTTPRequest:@"GET"
                    toURL:@"/venue"
               withParams:params
                 callback:callback];
}

- (void) addVenue:(NSString*)name addressDictionary:(NSDictionary*)addressDictionary callback:(SGCallback*)callback
{
    NSMutableDictionary* params = [NSDictionary dictionaryWithDictionary:addressDictionary];
    [params setObject:name forKey:@"vid"];
    
    [self sendHTTPRequest:@"POST"
                    toURL:@"/addvenue"
               withParams:params
                 callback:callback];
}

- (void) editVenue:(NSString*)vid addressDictionary:(NSDictionary*)addressDictionary callback:(SGCallback*)callback
{
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithDictionary:addressDictionary];
    [params setValue:@"vid" forKey:vid];

    [self sendHTTPRequest:@"POST"
                    toURL:@"/venue/proposeedit"
               withParams:addressDictionary
                 callback:callback];
}

- (void) venueClosed:(NSString*)vid callback:(SGCallback*)callback
{
    [self sendHTTPRequest:@"POST"
                    toURL:@"/venue/flagclosed"
               withParams:nil
                 callback:callback];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Tips methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) tipsNearbyCoordinate:(CLLocationCoordinate2D)coordinate limit:(NSInteger)limit callback:(SGCallback*)callback
{
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [NSString stringWithFormat:@"%f", coordinate.latitude], @"geolat",
                                    [NSString stringWithFormat:@"%f", coordinate.longitude], @"geolong",
                                        nil];
    if(limit > 0)
        [params setObject:[NSString stringWithFormat:@"%i", limit] forKey:@"limit"];

    [self sendHTTPRequest:@"GET"
                    toURL:@"/tips"
               withParams:params
                 callback:callback];
}

- (void) addTipToVenue:(NSString*)vid tip:(NSString*)tip type:(NSString*)type callback:(SGCallback*)callback
{
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            vid, @"vid",
                            tip, @"tip",
                            type, @"type",
                            nil];
    
    [self sendHTTPRequest:@"POST"
                    toURL:@"/addtip"
               withParams:params
                 callback:callback];
}

- (void) markTipAsToDo:(NSString*)tid callback:(SGCallback*)callback
{
    return [self _updateStatus:@"marktodo" ofTip:tid callback:callback];
}

- (void) markTipAsDone:(NSString*)tid callback:(SGCallback*)callback
{
    return [self _updateStatus:@"markdone" ofTip:tid callback:callback];
}

- (void) unmarkTip:(NSString*)tid callback:(SGCallback*)callback
{
    return [self _updateStatus:@"unmark" ofTip:tid callback:callback];
}

- (void) _updateStatus:(NSString*)status ofTip:(NSString*)tid callback:(SGCallback*)callback
{
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:tid, @"tid", nil];
    [self sendHTTPRequest:@"POST"
                    toURL:[NSString stringWithFormat:@"/tip/%@", status]
               withParams:params
                 callback:callback];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Friends methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) pendingFriendRequestsCallback:(SGCallback*)callback
{
    [self sendHTTPRequest:@"GET"
                    toURL:@"/friend/requests"
               withParams:nil
                 callback:callback];
}

- (void) approveFriendRequest:(NSString*)uid callback:(SGCallback*)callback
{
    [self _updateFriendRequest:uid status:@"approve" callback:callback];
}

- (void) denyFriendRequest:(NSString*)uid callback:(SGCallback*)callback
{
    [self _updateFriendRequest:uid status:@"deny" callback:callback];
}

- (void) sendFriendRequest:(NSString*)uid callback:(SGCallback*)callback
{
    [self _updateFriendRequest:uid status:@"sendrequest" callback:callback];
}

- (void) _updateFriendRequest:(NSString*)uid status:(NSString*)status callback:(SGCallback*)callback
{
    [self sendHTTPRequest:@"POST"
                    toURL:[NSString stringWithFormat:@"/friend/%@", status]
               withParams:nil
                 callback:callback];
}

- (void) findFriendsViaName:(NSString*)keyword callback:(SGCallback*)callback
{
    [self _findFriends:keyword byMedium:@"byname" callback:callback];
}

- (void) findFriendsViaTwitter:(NSString*)keyword callback:(SGCallback*)callback
{
    [self _findFriends:keyword byMedium:@"bytwitter" callback:callback];
}

- (void) findFriendsViaPhone:(NSString*)keyword callback:(SGCallback*)callback
{
    [self _findFriends:keyword byMedium:@"byphone" callback:callback];
}

- (void) _findFriends:(NSString*)keyword byMedium:(NSString*)meduim callback:(SGCallback*)callback
{
    [self sendHTTPRequest:@"GET"
                    toURL:[NSString stringWithFormat:@"/findfriends/%@", meduim]
               withParams:nil
                 callback:callback];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Utility methods
////////////////////////////////////////////////////////////////////////////////////////////////

- (void) sendHTTPRequest:(NSString*)type toURL:(NSString*)file withParams:(NSDictionary*)params callback:(SGCallback*)callback
{	
    file = [file stringByAppendingFormat:@".json"];
    NSMutableDictionary* oauthParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        self.accessToken.accessToken, @"oauth_token", nil];

    if(params)
        [oauthParams addEntriesFromDictionary:params];

    file = [file stringByAppendingFormat:@"?%@", [self normalizeRequestParams:oauthParams]];
    
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", foursquareURL, file]];
    NSLog(@"SGGimmeFoursquare - Sending %@ to %@", type, file);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:type];
    
    // We probably want to hold onto this object and release
    // it at some point.
    [[[NXOAuth2Connection alloc] initWithRequest:request
                                     oauthClient:self
                                        delegate:callback] autorelease];
}

- (NSString*) normalizeRequestParams:(NSDictionary*)params
{
    NSMutableArray* parameterPairs = [NSMutableArray arrayWithCapacity:([params count])];
    NSString* value;
    for(NSString* param in params) {
        value = [params objectForKey:param];
        param = [NSString stringWithFormat:@"%@=%@", [param URLEncodedString], [value URLEncodedString]];
        [parameterPairs addObject:param];
    }
    
    NSArray* sortedPairs = [parameterPairs sortedArrayUsingSelector:@selector(compare:)];
    return [sortedPairs componentsJoinedByString:@"&"];
}

- (NSMutableDictionary*) getLatLonParams:(CLLocationCoordinate2D)coordinate
{
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude], @"ll",
                                   nil];
    return params;
}

@end

@implementation SGCallback
@synthesize delegate, successMethod, failureMethod;

- (id) initWithDelegate:(id)d successMethod:(SEL)sMethod failureMethod:(SEL)fMethod
{
    if(self = [super init]) {
        delegate = d;
        successMethod = sMethod;
        failureMethod = fMethod;
    }
    
    return self;
}

+ (SGCallback*) callbackWithDelegate:(id)delegate successMethod:(SEL)successMethod failureMethod:(SEL)failureMethod
{
    return [[[SGCallback alloc] initWithDelegate:delegate successMethod:successMethod failureMethod:failureMethod] autorelease];
}

- (void) oauthConnection:(NXOAuth2Connection*)connection didFinishWithData:(NSData *)data
{
    [delegate performSelector:successMethod withObject:data];    
}

- (void) oauthConnection:(NXOAuth2Connection*)connection didFailWithError:(NSError *)error
{
    [delegate performSelector:failureMethod withObject:error];
}

@end

