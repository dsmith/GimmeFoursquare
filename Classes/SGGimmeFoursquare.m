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
#import "SGAuthorizeWebViewController.h"

#import "NSDictionary_JSONExtensions.h"
#import "NSStringAdditions.h"

#import "OAServiceTicket.h"
#import "OAToken.h"
#import "OADataFetcher.h"

static NSString* foursquareURL = @"http://api.foursquare.com/v2";

@interface SGGimmeFoursquare (Private)

- (void) sendHTTPRequest:(NSString*)type 
                   toURL:(NSString*)url
              withParams:(NSDictionary*)httpBody 
                callback:(SGCallback*)callback;

- (NSMutableDictionary*) getLatLonParams:(CLLocationCoordinate2D)coordinate;

- (NSString*) normalizeRequestParams:(NSDictionary*)params;

- (void) _updateStatus:(NSString*)status ofTip:(NSString*)tid callback:(SGCallback*)callback;
- (void) _updateFriendRequest:(NSString*)uid status:(NSString*)status callback:(SGCallback*)callback;
- (void) _findFriends:(NSString*)keyword byMedium:(NSString*)meduim callback:(SGCallback*)callback;

@end

@implementation SGGimmeFoursquare
@synthesize consumer;

- (id) initWithKey:(NSString*)key secret:(NSString*)secret
{
    if(self = [super init]) {
        consumer = [[OAConsumer alloc] initWithKey:key secret:secret];
    }
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark OAuth 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) getOAuthRequestToken
{    
    OAMutableURLRequest* request = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://foursquare.com/oauth/request_token"]
                                                                   consumer:consumer
                                                                      token:nil
                                                                      realm:nil
                                                          signatureProvider:nil];
    
    OADataFetcher* fetcher = [[[OADataFetcher alloc] init] autorelease];
    [fetcher fetchDataWithRequest:request delegate:self didFinishSelector:@selector(requestTokenTicket:didFinishWithData:) didFailSelector:@selector(requestTokenTicket:didFailWithError:)];
}

- (void) requestTokenTicket:(OAServiceTicket*)ticket didFinishWithData:(NSData*)data
{
    if (ticket.didSucceed) {
        NSString* responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        requestToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
        NSUserDefaults* standardUserDefaults = (NSUserDefaults *)[NSUserDefaults standardUserDefaults];
        [standardUserDefaults setObject:requestToken.key forKey:@"requestTokenKey"];
        [standardUserDefaults setObject:requestToken.secret forKey:@"requestTokenSecret"];        
        [responseBody release];
        
        // Update this code if you do not want the default
        // behavior after a request token has been recieved.
        SGAuthorizeWebViewController* webViewController = [[SGAuthorizeWebViewController alloc] init];
        UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:webViewController];

        UIWindow* window = [[UIApplication sharedApplication] keyWindow];
        [UIView beginAnimations:@"authorize_web_page" context:nil];
        [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:window cache:NO];
        [UIView setAnimationDuration:1.5];
        [window addSubview:navigationController.view];
        [UIView commitAnimations];
    } else {
        NSString* responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];   
        NSLog(@"SGGimmeFoursquare - Request Token Failed: %@", responseBody);
    }
}

- (void) requestTokenTicket:(OAServiceTicket*)ticket didFailWithError:(NSError*)error
{
    NSLog(@"SGGimmeFoursquare - Request Token Failed: %@", error);
}

- (void) getOAuthAccessToken
{
    NSURL* url = [NSURL URLWithString:@"http://foursquare.com/oauth/access_token"];
    
    OAToken* token = [[OAToken alloc] initWithKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"requestTokenKey"] 
                                           secret:[[NSUserDefaults standardUserDefaults] stringForKey:@"requestTokenSecret"]];
    
    OAMutableURLRequest* request = [[OAMutableURLRequest alloc] initWithURL:url
                                                                   consumer:consumer
                                                                      token:token
                                                                      realm:nil
                                                          signatureProvider:nil];
    
    OADataFetcher* fetcher = [[[OADataFetcher alloc] init] autorelease];
    [request setHTTPMethod:@"GET"];    
    [fetcher fetchDataWithRequest:request
                         delegate:self 
                didFinishSelector:@selector(requestAccessTokenTicket:didFinishWithData:)
                  didFailSelector:@selector(requestAccessTokenTicket:didFailWithError:)];
}

- (void) requestAccessTokenTicket:(OAServiceTicket*)ticket didFailWithError:(NSError*)error
{
    NSLog(@"SGGimmeFoursquare - Request Access Token Failed: %@", error);
}

- (void) requestAccessTokenTicket:(OAServiceTicket*)ticket didFinishWithData:(NSData*)data
{    
    if(ticket.didSucceed) {
        NSString* responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
        [responseBody release];
        
        NSUserDefaults* standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setObject:accessToken.key forKey:@"accessTokenKey"];
        [standardUserDefaults setObject:accessToken.secret forKey:@"accessTokenSecret"];
    } else {
        NSString* responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"SGGimmeFoursquare - Request Access Token Failed: %@", responseBody);
    }
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
        [params setObject:[NSString stringWithFormat:@"%i", limit] forKey:@"l"];
    
    if(keyword)
        [params setObject:keyword forKey:@"q"];
    
    [self sendHTTPRequest:@"GET"
                    toURL:@"/venues"
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
               withParams: nil
                 callback:callback];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Utility methods
////////////////////////////////////////////////////////////////////////////////////////////////

- (void) sendHTTPRequest:(NSString*)type toURL:(NSString*)file withParams:(NSDictionary*)params callback:(SGCallback*)callback
{	
    file = [file stringByAppendingFormat:@".json"];
    if(params)
        file = [file stringByAppendingFormat:@"?%@", [self normalizeRequestParams:params]];
    
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", foursquareURL, file]];
    
    NSLog(@"SGGimmeFoursquare - Sending %@ to %@", type, file);    
    OAMutableURLRequest* request = [[OAMutableURLRequest alloc] initWithURL:url
                                                                   consumer:consumerToken
                                                                      token:accessToken
                                                                      realm:nil
                                                          signatureProvider:nil];
    [request setHTTPMethod:type];
    OADataFetcher* fetcher = [[[OADataFetcher alloc] init] autorelease];
    [fetcher fetchDataWithRequest:request delegate:callback.delegate didFinishSelector:callback.successMethod didFailSelector:callback.failureMethod];
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
                                   [NSString stringWithFormat:@"%f", coordinate.latitude], @"geolat",
                                   [NSString stringWithFormat:@"%f", coordinate.longitude], @"geolong",
                                   nil];
    return params;
}

- (void) dealloc
{
    [consumer release];
    [super dealloc];
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

@end

