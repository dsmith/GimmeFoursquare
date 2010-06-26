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

#import "NSData+Base64.h"
#import "NSDictionary_JSONExtensions.h"
#import "NSStringAdditions.h"

static SGGimmeFoursquare* sharedGimmeFoursquare = nil;
static int responseIdNumber = 0;

static NSString* foursquareURL = @"http://api.foursquare.com/v1";

typedef NSInteger SGFoursquareResponse;

@interface SGGimmeFoursquare (Private) <SGGimmeFoursquareDelegate>

- (void) sendHTTPRequest:(NSString*)type toURL:(NSString*)url withParams:(NSDictionary*)httpBody requestId:(NSString*)requestId;
- (void) pushInvocationWithArgs:(NSArray*)args;

- (NSString*) getNextRequestId;

- (NSString*) getEncodedAuthString;
- (NSMutableDictionary*) getLatLonParams:(CLLocationCoordinate2D)coordinate;

- (NSString*) normalizeRequestParams:(NSDictionary*)params;

- (NSString*) _updateStatus:(NSString*)status ofTip:(NSString*)tid;
- (NSString*) _updateFriendRequest:(NSString*)uid status:(NSString*)status;
- (NSString*) _findFriends:(NSString*)keyword byMedium:(NSString*)meduim;

@end

@implementation SGGimmeFoursquare
@synthesize operationQueue, username, password;

- (id) init
{
    if(self = [super init]) {
        username = nil;
        password = nil;
        validateUser = nil;
        
        delegates = [[NSMutableArray alloc] init];
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:1];
    }
    
    return self;
}

+ (SGGimmeFoursquare*) sharedGimmeFoursquare
{
    if(!sharedGimmeFoursquare) 
        sharedGimmeFoursquare = [[SGGimmeFoursquare alloc] init];
    
    [sharedGimmeFoursquare resumeSesssion];
    
    return sharedGimmeFoursquare;
}

+ (void) setSharedGimmeFoursquare:(SGGimmeFoursquare*)gimmeFoursquare
{
    if(sharedGimmeFoursquare)
        [sharedGimmeFoursquare release];
    
    sharedGimmeFoursquare = [gimmeFoursquare retain];
}

- (void) addDelegate:(id<SGGimmeFoursquareDelegate>)delegate
{
    [delegates addObject:delegate];
}

- (void) removeDelegate:(id<SGGimmeFoursquareDelegate>)delegate
{
    [delegates removeObject:delegate];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Validation methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (BOOL) resumeSesssion
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
 
    NSString* cachedUsername = [defaults stringForKey:@"SGFoursquare_Username"];
    NSString* cachedPassword = [defaults stringForKey:@"SGFoursquare_Password"];

    if(cachedPassword && ![cachedPassword isEqualToString:@""] && 
            cachedUsername && ![cachedUsername isEqualToString:@""]) {
 
        username = cachedUsername;
        password = cachedPassword;
        
        encodedAuthString = [[self getEncodedAuthString] retain];
        
        return YES;
    }
    
    return NO;
}

- (void) clearSession
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"" forKey:@"SGFoursquare_Username"];
    [defaults setObject:@"" forKey:@"SGFoursquare_Password"];
    [defaults setObject:@"" forKey:@"SGFoursquare_UserId"];
}

- (NSString*) validateUsername:(NSString*)name password:(NSString*)pw
{
    username = name;
    password = pw;
        
    encodedAuthString = [[self getEncodedAuthString] retain];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:name forKey:@"SGFoursquare_Username"];
    [defaults setObject:pw forKey:@"SGFoursquare_Password"];
    
    return [self userInformation:nil badges:NO mayor:NO];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Geo methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) activeCities
{
    NSString* responseId = [self getNextRequestId];    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     @"/cities.json",
                     [NSNull null],
                     responseId,
                     nil];
    
    [self pushInvocationWithArgs:args];
    
    return responseId;
}

- (NSString*) closestCityToCoordinate:(CLLocationCoordinate2D)coordinate cityId:(NSString*)cityId
{
    NSMutableDictionary* params = [self getLatLonParams:coordinate];
    NSString* responseId = [self getNextRequestId];
    if(cityId)
        [params setObject:cityId forKey:@"cityid"];
    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                        @"/checkcity",
                        params,
                     responseId,
                        nil];
    
    [self pushInvocationWithArgs:args];
    
    return responseId;
}

- (NSString*) updateDefaultCity:(NSString*)cityId
{
    NSString* responseId = [self getNextRequestId];
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:cityId, @"cityid", nil];
    NSArray* args = [NSArray arrayWithObjects:@"POST",
                        @"/switchcity",
                        params,
                     responseId,
                        nil];
    
    [self pushInvocationWithArgs:args];
    
    return responseId;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Check in methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) checkIns:(NSString*)cityId
{
    NSString* responseId = [self getNextRequestId];    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:cityId, @"cityid", nil];
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                        @"/checkins",
                        params,
                     responseId,
                        nil];
    
    [self pushInvocationWithArgs:args];
    
    return responseId;
}

- (NSString*) shoutMessage:(NSString*)message coordinate:(CLLocationCoordinate2D)coordinate twitter:(BOOL)enabled
{
    NSString* responseId = [self getNextRequestId];
    NSMutableDictionary* params = [self getLatLonParams:coordinate];
    [params setObject:[NSString stringWithFormat:@"%i", enabled] forKey:@"twitter"];
    [params setObject:message forKey:@"shout"];
    
    NSArray* args = [NSArray arrayWithObjects:@"POST",
                        @"/checkin",
                        params,
                     responseId,
                        nil];
    
    [self pushInvocationWithArgs:args];
    
    return responseId;
}

- (NSString*) checkIntoVenue:(NSString*)vid coordinate:(CLLocationCoordinate2D)coord
{
    NSString* responseId = [self getNextRequestId];
    NSMutableDictionary* params = [self getLatLonParams:coord];
    [params setObject:vid forKey:@"vid"];
    
    NSArray* args = [NSArray arrayWithObjects:@"POST",
                            @"/checkin",
                            params,
                            responseId,
                            nil];
    
    [self pushInvocationWithArgs:args];
    
    return responseId;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark User methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) userInformation:(NSString*)userId badges:(BOOL)badges mayor:(BOOL)mayor
{
    NSString* responseId = [self getNextRequestId];    
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%i", badges], @"badges",
                                   [NSString stringWithFormat:@"%i", badges], @"mayor",
                                   nil];
    if(userId)
        [params setObject:userId forKey:@"uid"];

    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     @"/user",
                     params,
                     responseId,
                     nil];
    
    [self pushInvocationWithArgs:args];
    
    return responseId;
}

- (NSString*) historySince:(NSString*)sinceid limit:(int)limit
{
    NSString* responseId = [self getNextRequestId];    
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    
    if(sinceid)
        [params setObject:sinceid forKey:@"sinceid"];
    
    if(limit > 0)
        [params setObject:[NSString stringWithFormat:@"%i", limit] forKey:@"l"];
    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     @"history",
                     params,
                     responseId,
                     nil];
    
    [self pushInvocationWithArgs:args];
    
    return responseId;
}

- (NSString*) friends:(NSString*)uid
{
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    NSString* responseId = [self getNextRequestId];
    if(uid)
        [params setObject:uid forKey:@"uid"];
    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     @"friends",
                     params,
                     responseId,
                     nil];
    
    [self pushInvocationWithArgs:args];    
    
    return responseId;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Venue methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) venuesNearbyCoordinate:(CLLocationCoordinate2D)coordinate limit:(int)limit keyword:(NSString*)keyword;
{
    NSMutableDictionary* params = [self getLatLonParams:coordinate];
    NSString* responseId = [self getNextRequestId];
    if(limit > 0)
        [params setObject:[NSString stringWithFormat:@"%i", limit] forKey:@"l"];
    
    if(keyword)
        [params setObject:keyword forKey:@"q"];
    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                        @"/venues",
                        params,
                     responseId,
                        nil];
    
    [self pushInvocationWithArgs:args];    
    
    return responseId;
}

- (NSString*) venueInformation:(NSString*)vid
{
    NSString* responseId = [self getNextRequestId];
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:vid, @"vid", nil];
    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                        @"/venue",
                        params,
                        responseId,
                        nil];
    
    [self pushInvocationWithArgs:args];    
    
    return responseId;
}

- (NSString*) addVenue:(NSString*)name addressDictionary:(NSDictionary*)addressDictionary
{
    NSString* responseId = [self getNextRequestId];
    NSMutableDictionary* params = [NSDictionary dictionaryWithDictionary:addressDictionary];
    [params setObject:name forKey:@"vid"];
    
    NSArray* args = [NSArray arrayWithObjects:@"POST",
                     @"/addvenue",
                     params,
                     responseId,
                     nil];
    
    [self pushInvocationWithArgs:args]; 
    
    return responseId;
}

- (NSString*) editVenue:(NSString*)vid addressDictionary:(NSDictionary*)addressDictionary
{
    NSString* responseId = [self getNextRequestId];
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithDictionary:addressDictionary];
    [params setValue:@"vid" forKey:vid];
    
    NSArray* args = [NSArray arrayWithObjects:@"POST",
                     @"/venue/proposeedit",
                     addressDictionary,
                     responseId,
                     nil];
    
    [self pushInvocationWithArgs:args];

    return responseId;
}

- (NSString*) venueClosed:(NSString*)vid
{
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:vid, @"vid", nil];
    NSString* responseId = [self getNextRequestId];
    NSArray* args = [NSArray arrayWithObjects:@"POST",
                        @"/venue/flagclosed",
                        params, 
                        responseId,
                        nil];

    [self pushInvocationWithArgs:args];
        
    return responseId;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Tips methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) tipsNearbyCoordinate:(CLLocationCoordinate2D)coordinate limit:(NSInteger)limit
{
    NSString* responseId = [self getNextRequestId];
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [NSString stringWithFormat:@"%f", coordinate.latitude], @"geolat",
                                    [NSString stringWithFormat:@"%f", coordinate.longitude], @"geolong",
                                        nil];
    if(limit > 0)
        [params setObject:[NSString stringWithFormat:@"%i", limit] forKey:@"limit"];

    NSArray* args = [NSArray arrayWithObjects:@"GET",
                        @"tips",
                        params,
                        responseId,
                        nil];
    
    [self pushInvocationWithArgs:args];
    
    return responseId;
}

- (NSString*) addTipToVenue:(NSString*)vid tip:(NSString*)tip type:(NSString*)type
{
    NSString* responseId = [self getNextRequestId];
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            vid, @"vid",
                            tip, @"tip",
                            type, @"type",
                            nil];
    
    NSArray* args = [NSArray arrayWithObjects:@"POST",
                     @"/addtip",
                     params,
                     responseId,
                     nil];
    
    [self pushInvocationWithArgs:args];
    
    return responseId;
}

- (NSString*) markTipAsToDo:(NSString*)tid
{
    return [self _updateStatus:@"marktodo" ofTip:tid];
}

- (NSString*) markTipAsDone:(NSString*)tid
{
    return [self _updateStatus:@"markdone" ofTip:tid];
}

- (NSString*) unmarkTip:(NSString*)tid
{
    return [self _updateStatus:@"unmark" ofTip:tid];
}

- (NSString*) _updateStatus:(NSString*)status ofTip:(NSString*)tid
{
    NSString* responseId = [self getNextRequestId];
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:tid, @"tid", nil];
    NSArray* args = [NSArray arrayWithObjects:@"POST",
                     [NSString stringWithFormat:@"/tip/%@", status],
                     params,
                     responseId,
                     nil];
    [self pushInvocationWithArgs:args];
    
    return responseId;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Friends methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) pendingFriendRequests
{
    NSString* responseId = [self getNextRequestId];
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     @"/friend/requests",
                     [NSNull null],
                     responseId,
                     nil];

    [self pushInvocationWithArgs:args];
    
    return responseId;
}

- (NSString*) approveFriendRequest:(NSString*)uid
{
    return [self _updateFriendRequest:uid status:@"approve"];
}

- (NSString*) denyFriendRequest:(NSString*)uid
{
    return [self _updateFriendRequest:uid status:@"deny"];
}

- (NSString*) sendFriendRequest:(NSString*)uid
{
    return [self _updateFriendRequest:uid status:@"sendrequest"];
}

- (NSString*) _updateFriendRequest:(NSString*)uid status:(NSString*)status
{
    NSString* responseId = [self getNextRequestId];
    NSArray* args = [NSArray arrayWithObjects:@"POST",
                     [NSString stringWithFormat:@"/friend/%@", status],
                     [NSNull null],
                     responseId,
                     nil];

    [self pushInvocationWithArgs:args];
    
    return responseId;
}

- (NSString*) findFriendsViaName:(NSString*)keyword
{
    return [self _findFriends:keyword byMedium:@"byname"];
}

- (NSString*) findFriendsViaTwitter:(NSString*)keyword
{
    return [self _findFriends:keyword byMedium:@"bytwitter"];
}

- (NSString*) findFriendsViaPhone:(NSString*)keyword
{
    return [self _findFriends:keyword byMedium:@"byphone"];
}

- (NSString*) _findFriends:(NSString*)keyword byMedium:(NSString*)meduim
{
    NSString* responseId = [self getNextRequestId];
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     [NSString stringWithFormat:@"/findfriends/%@", meduim],
                     [NSNull null],
                     responseId,
                     nil];

    [self pushInvocationWithArgs:args];

    return responseId;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark HTTPRequest recievers 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) failed:(NSDictionary*)response
{
    for(id<SGGimmeFoursquareDelegate> delegate in delegates)
        [delegate fourSquare:self requestFailed:[response objectForKey:@"requestId"] error:[response objectForKey:@"error"]];
}

- (void) succeeded:(NSDictionary*)response
{
    NSData* responseObject = [response objectForKey:@"responseObject"];
    NSDictionary* foursquareResponseObject = [NSDictionary dictionaryWithJSONData:responseObject error:nil];
    
    for(id<SGGimmeFoursquareDelegate> delegate in delegates)
        [delegate fourSquare:self
            requestSucceeded:[response objectForKey:@"requestId"]
              responseObject:foursquareResponseObject];
}

- (NSString*) getNextRequestId
{
    responseIdNumber++;
    return [[[NSString alloc] initWithFormat:@"SGGimmeFoursquare-%i", responseIdNumber] autorelease];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark SGGimmeFoursquare delegate methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) fourSquare:(SGGimmeFoursquare*)fourSquare requestSucceeded:(NSString*)requestId responseObject:(id)responseObject
{
    if(validateUser && [validateUser isEqualToString:requestId]) {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[[(NSDictionary*)responseObject objectForKey:@"user"] objectForKey:@"id"]
                     forKey:@"SGFoursquare-UserId"];
        
        validateUser = nil;
    }
}

- (void) fourSquare:(SGGimmeFoursquare*)fourSquare requestFailed:(NSString*)requestId error:(NSError*)error
{
    if(validateUser && [validateUser isEqualToString:requestId]) {
     
        validateUser = nil;
    }    
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Utility methods
////////////////////////////////////////////////////////////////////////////////////////////////

- (void) sendHTTPRequest:(NSString*)type toURL:(NSString*)file withParams:(NSDictionary*)params requestId:(NSString*)requestId
{	
    if(params && ![params isKindOfClass:[NSNull class]])
        file = [file stringByAppendingFormat:@".json?%@", [self normalizeRequestParams:params]];
    
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", foursquareURL, file]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:10];
	
    [request setHTTPMethod:type];
    [request setValue:[NSString stringWithFormat:@"Basic %@", encodedAuthString] forHTTPHeaderField:@"Authorization"];
    
    NSLog(@"GimmeFoursquare - Sending %@ to %@", type, file);    
    NSError* theError = nil;
    NSHTTPURLResponse* theResponse = nil;
    NSData* returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:&theError];
	
    // Possible loss of connection
    if(!returnData) {
		for(int i = 0; i < 3 && !returnData; i++) {
			NSLog(@"Retrying %@ request to %@...", type, [url description]);
			returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:&theError];	
            if(theError)
                break;
		}
    }
        
    if(theResponse && ([theResponse statusCode] >= 300 || [theResponse statusCode] < 200)) {
        if(!theError) {
            NSString* domain = nil;
            if(returnData)
                domain = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
            else
                domain = [NSHTTPURLResponse localizedStringForStatusCode:[theResponse statusCode]];
            
            theError = [NSError errorWithDomain:domain code:[theResponse statusCode] userInfo:[theResponse allHeaderFields]];
        }
    }
    
	if(theError) {
        NSDictionary* response = [NSDictionary dictionaryWithObjectsAndKeys:requestId, @"requestId", theError, @"error", nil];
        [self performSelectorOnMainThread:@selector(failed:) withObject:response waitUntilDone:NO];
    } else {
        NSDictionary* response = [NSDictionary dictionaryWithObjectsAndKeys:requestId, @"requestId", returnData, @"responseObject", nil];
        [self succeeded:response];
    }
}

- (NSString*) normalizeRequestParams:(NSDictionary*)params
{
    NSMutableArray *parameterPairs = [NSMutableArray arrayWithCapacity:([params count])];
    NSString* value;
    for(NSString* param in params) {
        value = [params objectForKey:param];
        param = [NSString stringWithFormat:@"%@=%@", [param URLEncodedString], [value URLEncodedString]];
        [parameterPairs addObject:param];
    }
    
    NSArray* sortedPairs = [parameterPairs sortedArrayUsingSelector:@selector(compare:)];
    return [sortedPairs componentsJoinedByString:@"&"];
}

- (void) pushInvocationWithArgs:(NSArray*)args
{	
    NSMethodSignature* methodSignature = [self methodSignatureForSelector:@selector(sendHTTPRequest:toURL:withParams:requestId:)];
    NSInvocation* httpRequestInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [httpRequestInvocation setSelector:@selector(sendHTTPRequest:toURL:withParams:requestId:)];
    [httpRequestInvocation setTarget:self];    
    
    NSString* arg;
	for(int i = 0; i < [args count]; i++) {
        arg = [args objectAtIndex:i];
		[httpRequestInvocation setArgument:&arg atIndex:i + 2];
    }
	
	NSInvocationOperation* opertaion = [[[NSInvocationOperation alloc] initWithInvocation:httpRequestInvocation] autorelease];
	[operationQueue addOperation:opertaion];			
}

- (NSMutableDictionary*) getLatLonParams:(CLLocationCoordinate2D)coordinate
{
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%f", coordinate.latitude], @"geolat",
                                   [NSString stringWithFormat:@"%f", coordinate.longitude], @"geolong",
                                   nil];
    return params;
}

- (NSString*) getEncodedAuthString
{
    NSString* authString = [NSString stringWithFormat:@"%@:%@", username, password];
    NSData* data = [authString dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t size;
    char* encodedString = NewBase64Encode([data bytes], [data length], NO, &size);
    
    return [NSString stringWithCString:encodedString encoding:NSUTF8StringEncoding];
}

- (void) dealloc
{
    [password release];
    [username release];
    [encodedAuthString release];
    
    [delegates release];
    [operationQueue release];
    
    [super dealloc];
}

@end
