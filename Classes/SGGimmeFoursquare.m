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
#import "JSON.h"

static SGGimmeFoursquare* sharedGimmeFoursquare = nil;
static int responseIdNumber = 0;

static NSString* foursquareURL = @"http://api.playfoursquare.com/v1";

enum SGFoursquareResponse {
    
    kSGFoursquareResponse_Validation = 0,
    kSGFoursquareResponse_Cities,
    kSGFoursquareResponse_City,
    kSGFoursquareResponse_Data,
    kSGFoursquareResponse_Checkins,
    kSGFoursquareResponse_Checkin,
    kSGFoursquareResponse_User,
    kSGFoursquareResponse_Friends,
    kSGFoursquareResponse_Venues,
    kSGFoursquareResponse_Venue,
    kSGFoursquareResponse_Tips,
    kSGFoursquareResponse_Tip,
    kSGFoursquareResponse_Favorite
    
};

typedef NSInteger SGFoursquareResponse;

@interface SGGimmeFoursquare (Private)

- (void) sendHTTPRequest:(NSString*)type toURL:(NSString*)url withParams:(NSString*)httpBody requestId:(NSString*)requestId;
- (void) pushInvocationWithArgs:(NSArray*)args;

- (NSString*) getNextRequestId;
- (NSString*) appendResponseType:(SGFoursquareResponse)type toRequestId:(NSString*)requestId;
- (NSString*) removeResponseTypeFromRequestId:(NSString*)requestId;
- (SGFoursquareResponse) getResponseTypeFromRequestId:(NSString*)requestId;

@end


@implementation SGGimmeFoursquare

@synthesize operationQueue;

- (id) init
{
    if(self = [super init]) {
        
        username = nil;
        password = nil;
        
        delegates = [[NSMutableArray alloc] init];
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:1];
        
        [self resumeSesssion];
        
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
 
    if([defaults boolForKey:@"SGFourSquare_Valid"]) {
    
        NSString* cachedUsername = [defaults stringForKey:@"SGFourSquare_Username"];
        NSString* cachedPassword = [defaults stringForKey:@"SGFourSquare_Password"];
    
        if(cachedPassword && cachedUsername) {
     
            username = cachedUsername;
            password = cachedPassword;
            
            return YES;
        }
        
    }
    
    return NO;
}

- (void) clearSession
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:@"SGFourSquare_Valid"];
}

- (NSString*) validateUsername:(NSString*)name password:(NSString*)pw
{
    NSString* requestId = nil;
    
    if(name && pw) {
        
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        
        username = [name copy];
        password = [pw copy];
        
        [defaults setObject:name forKey:@"SGFourSquare_Username"];
        [defaults setObject:pw forKey:@"SGFourSquare_Password"];
        requestId = [self getNextRequestId];
        
        NSArray* args = [NSArray arrayWithObjects:@"GET", 
                         [foursquareURL stringByAppendingString:@"/user.json"], 
                         @"badges=1&mayor=1", 
                         [self appendResponseType:kSGFoursquareResponse_Validation toRequestId:requestId],
                         nil];
        
        [self pushInvocationWithArgs:args];
        
    }
    
    return requestId;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Geo methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) activeCities
{
    NSString* requestId = [self getNextRequestId];
    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     [foursquareURL stringByAppendingString:@"/cities.json"],
                     @"",
                     [self appendResponseType:kSGFoursquareResponse_Cities toRequestId:requestId],
                     nil];
    
    [self pushInvocationWithArgs:args];
    
    return requestId;
}

- (NSString*) closestCityToCoordinate:(CLLocationCoordinate2D)coordinate cityId:(NSString*)cityId
{
    NSString* requestId = [self getNextRequestId];
    
    if(!cityId || [cityId isKindOfClass:[NSNull class]])
        cityId = @"";
    else
        cityId = [NSString stringWithFormat:@"cityid=%@&", cityId];

    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     [foursquareURL stringByAppendingString:@"/checkcity.json"],
                     [NSString stringWithFormat:@"%@geolat=%f&geolong=%f", cityId, coordinate.latitude, coordinate.longitude],
                     [self appendResponseType:kSGFoursquareResponse_City toRequestId:requestId],
                     nil];
    
    [self pushInvocationWithArgs:args];
    
    return requestId;
}

- (NSString*) updateDefaultCity:(NSString*)cityId
{
    NSString* requestId = [self getNextRequestId];
    
    NSArray* args = [NSArray arrayWithObjects:@"POST",
                     [foursquareURL stringByAppendingString:@"/switchcity.json"],
                     [NSString stringWithFormat:@"cityid=%@", cityId],
                     [self appendResponseType:kSGFoursquareResponse_Data toRequestId:requestId],
                     nil];
    
    [self pushInvocationWithArgs:args];
    
    return requestId;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Check in methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) checkIns:(NSString*)cityId
{
    NSString* requestId = [self getNextRequestId];
    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     [foursquareURL stringByAppendingString:@"/checkins.json"],
                    [NSString stringWithFormat:@"cityid=%@", cityId],
                    [self appendResponseType:kSGFoursquareResponse_Checkins toRequestId:requestId],
                    nil];
    
    [self pushInvocationWithArgs:args];
    
    return requestId;
}

- (NSString*) shoutMessage:(NSString*)message coordinate:(CLLocationCoordinate2D)coordinate twitter:(BOOL)enabled
{
    NSString* requestId = [self getNextRequestId];
    
    NSMutableString* httpBody = [NSMutableString string];
    
    
    [httpBody appendFormat:@"geolat=%f&geolong=%f", coordinate.latitude, coordinate.longitude];
    [httpBody appendFormat:@"&twitter=%i", enabled ? 1 : 0];
    
    if(!message)
        message = @"";
    
    [httpBody appendFormat:@"&shout=%@", message];
    
    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     [foursquareURL stringByAppendingString:@"/checkin.json"],
                     httpBody,
                     [self appendResponseType:kSGFoursquareResponse_Checkin toRequestId:requestId],
                     nil];
    
    [self pushInvocationWithArgs:args];
    
    return requestId;
}

- (NSString*) checkIntoVenue:(NSString*)vid coordinate:(CLLocationCoordinate2D)coord
{
    NSString* requestId = [self getNextRequestId];
    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     [foursquareURL stringByAppendingString:@"/checkin.json"],
                     [NSString stringWithFormat:@"vid=%@&geolat=%f&geolong=%f", vid, coord.latitude, coord.longitude],
                     [self appendResponseType:kSGFoursquareResponse_Checkin toRequestId:requestId],
                     nil];
    
    [self pushInvocationWithArgs:args];
    
    return requestId;
    
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark User methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) userInformation:(NSString*)userId badges:(BOOL)badges mayor:(BOOL)mayor
{
    NSString* requestId = [self getNextRequestId];
    
    if(userId)
        userId = [NSString stringWithFormat:@"uid=%@&", userId];
    else
        userId = @"";

    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     [foursquareURL stringByAppendingString:@"/user.json"],
                     [NSString stringWithFormat:@"%@badges=%i&mayor=%i", userId, badges ? 1 : 0, mayor ? 1 : 0],
                     [self appendResponseType:kSGFoursquareResponse_User toRequestId:requestId],
                     nil];
    
    [self pushInvocationWithArgs:args];
    
    return requestId;
}

- (NSString*) friends
{
    NSString* requestId = [self getNextRequestId];
    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     [foursquareURL stringByAppendingString:@"/friends.json"],
                     @"",
                     [self appendResponseType:kSGFoursquareResponse_Friends toRequestId:requestId],
                     nil];
    
    [self pushInvocationWithArgs:args];    
    
    return requestId;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Venue methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) venuesNearbyCoordinate:(CLLocationCoordinate2D)coordinate withinRadius:(double)radius amount:(int)amount keyword:(NSString*)keyword;
{
    NSString* requestId = [self getNextRequestId];
    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     [foursquareURL stringByAppendingString:@"/venues.json"],
                     [NSString stringWithFormat:@"geolat=%f&geolong=%f&r=%f&q=%@&l=%i", coordinate.latitude, coordinate.longitude, radius, keyword, amount],
                     [self appendResponseType:kSGFoursquareResponse_Venues toRequestId:requestId],
                     nil];
    
    [self pushInvocationWithArgs:args];    
    
    return requestId;
}

- (NSString*) venueInformation:(NSString*)vid
{
    NSString* requestId = [self getNextRequestId];
    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     [foursquareURL stringByAppendingString:@"/venue.json"],
                     [NSString stringWithFormat:@"vid=%@", vid],
                     [self appendResponseType:kSGFoursquareResponse_Venue toRequestId:requestId],
                     nil];
    
    [self pushInvocationWithArgs:args];    
    
    return requestId;
}

- (NSString*) addVenue:(NSString*)name addressDictionary:(NSDictionary*)addressDictionary
{
    NSString* requestId = [self getNextRequestId];
    
    NSMutableString* httpBody = [[NSMutableString alloc] init];
    NSString* value;
    for(NSString* key in addressDictionary) {
        
        value = [addressDictionary objectForKey:key];
        if(![value isKindOfClass:[NSNull class]]) 
            [httpBody appendFormat:@"&%@=%@", key, [addressDictionary objectForKey:key]];
    }
            
    if([httpBody length])
        [httpBody deleteCharactersInRange:NSRangeFromString(@"0,1")];
    
    NSArray* args = [NSArray arrayWithObjects:@"POST",
                     [foursquareURL stringByAppendingString:@"/addvenue.json"],
                     httpBody,
                     [self appendResponseType:kSGFoursquareResponse_Venue toRequestId:requestId],
                     nil];
    
    [self pushInvocationWithArgs:args]; 
    
    [httpBody release];
    
    return requestId;
                     
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Tips methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSString*) tipsNearbyCoordinate:(CLLocationCoordinate2D)coordinate limit:(NSInteger)limit
{
    NSString* requestId = [self getNextRequestId];
    
    NSArray* args = [NSArray arrayWithObjects:@"GET",
                     [foursquareURL stringByAppendingString:@"/tips.json"],
                     [NSString stringWithFormat:@"geolat=%f&geolong=%f&l=%i", coordinate.latitude, coordinate.longitude, limit],
                     [self appendResponseType:kSGFoursquareResponse_Tips toRequestId:requestId],
                     nil];
    
    [self pushInvocationWithArgs:args];
    
    return requestId;
    
}

- (NSString*) addTipToVenue:(NSString*)vid tip:(NSString*)tip type:(NSString*)type
{
    NSString* requestId = [self getNextRequestId];
    
    NSArray* args = [NSArray arrayWithObjects:@"POST",
                     [foursquareURL stringByAppendingFormat:@"/addtip.json"],
                     [NSString stringWithFormat:@"vid=%@&tip=%@&type=%i", vid, tip, type],
                     [self appendResponseType:kSGFoursquareResponse_Tip toRequestId:requestId],
                     nil];
    
    [self pushInvocationWithArgs:args];
    
    return requestId;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark HTTPRequest recievers 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) failed:(NSDictionary*)response
{
    NSString* requestId = [response objectForKey:@"requestId"];
    
    SGFoursquareResponse type = [self getResponseTypeFromRequestId:requestId];
    
    if(type == kSGFoursquareResponse_Favorite)
        NSLog([response description]);
    
    for(id<SGGimmeFoursquareDelegate> delegate in delegates)
        [delegate fourSquare:self
               requestFailed:[self removeResponseTypeFromRequestId:[response objectForKey:@"requestId"]]
                       error:[response objectForKey:@"error"]];
    
    
}

- (void) succeeded:(NSDictionary*)response;
{
    NSString* requestId = [response objectForKey:@"requestId"];
    NSString* responseObject = [response objectForKey:@"responseObject"];
    
    SGFoursquareResponse type = [self getResponseTypeFromRequestId:requestId];
    
    NSDictionary* foursquareResponseObject = (NSDictionary*)[responseObject JSONValue];
        
    requestId = [self removeResponseTypeFromRequestId:requestId];
    
    switch (type) {
            
        case kSGFoursquareResponse_Validation:
        {
            foursquareResponseObject = [foursquareResponseObject objectForKey:@"user"];
            
            NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
            
            if(!foursquareResponseObject) {
                
                [self failed:response];
                [defaults setBool:NO forKey:@"SGFourSquare_Valid"];
                return;
                
            } else {
                            
                [defaults setBool:YES forKey:@"SGFourSquare_Valid"];
            }
            
            
//            NSArray* args = [NSArray arrayWithObjects:@"POST",
//                             [favoritesURL stringByAppendingFormat:@"/ihe/foursquare/user"],
//                             [NSString stringWithFormat:@"username=%@&password=%@", username, password],
//                             [self appendResponseType:kSGFoursquareResponse_Favorite toRequestId:[self getNextRequestId]],
//                             nil];
//            
//            [self pushInvocationWithArgs:args];
                     
                                
            break;
        }
            
        case kSGFoursquareResponse_Cities:
        {
            foursquareResponseObject = [foursquareResponseObject objectForKey:@"cities"];
            break;
        }

        case kSGFoursquareResponse_City:
        {
            foursquareResponseObject = [foursquareResponseObject objectForKey:@"city"];
            break;
        }
            
        case kSGFoursquareResponse_Data:
        {
            foursquareResponseObject = [foursquareResponseObject objectForKey:@"data"];
            break;
        }
            
        case kSGFoursquareResponse_Checkins:
        {
            foursquareResponseObject = [foursquareResponseObject objectForKey:@"checkins"];
            break;
        }
            
        case kSGFoursquareResponse_Checkin:
        {
            foursquareResponseObject = [foursquareResponseObject objectForKey:@"checkin"];
            break;
        }
            
        case kSGFoursquareResponse_User:
        {            
            if(!foursquareResponseObject) {
                
                responseObject = [responseObject stringByAppendingString:@"}"];
                foursquareResponseObject = [responseObject JSONValue];
                
            }            
            
            foursquareResponseObject = [foursquareResponseObject objectForKey:@"user"];
            
            break;
        }
            
        case kSGFoursquareResponse_Friends:
        {
            foursquareResponseObject = [foursquareResponseObject objectForKey:@"friends"];
            break;
        }
            
        case kSGFoursquareResponse_Venues:
        {
            foursquareResponseObject = [foursquareResponseObject objectForKey:@"venues"];
            break;
        }
            
        case kSGFoursquareResponse_Venue:
        {
            foursquareResponseObject = [foursquareResponseObject objectForKey:@"venue"];
            break;
        }
            
        case kSGFoursquareResponse_Tips:
        {
            if(!foursquareResponseObject) {
                
                responseObject = [responseObject stringByReplacingOccurrencesOfString:@"},{" withString:@"}},{"];
                responseObject = [responseObject stringByReplacingOccurrencesOfString:@"{\"group\":" withString:@""];
                responseObject = [responseObject stringByReplacingOccurrencesOfString:@"}]}" withString:@"}}]"];
                responseObject = [responseObject stringByReplacingOccurrencesOfString:@"}}}" withString:@"}}"];
                responseObject = [responseObject stringByReplacingOccurrencesOfString:@"\":\"id\"" withString:@"\":{\"id\""];
                
                foursquareResponseObject = [responseObject JSONValue];
                
            }                        
            
            foursquareResponseObject = [foursquareResponseObject objectForKey:@"tips"];
            break;
        }
            
        case kSGFoursquareResponse_Tip:
        {
            foursquareResponseObject = [foursquareResponseObject objectForKey:@"tip"];
            break;
        }
                        
        default:
            NSLog(@"Unknown type");
            
    }
    
    for(id<SGGimmeFoursquareDelegate> delegate in delegates)
        [delegate fourSquare:self requestSucceeded:requestId responseObject:foursquareResponseObject];
}

- (NSString*) getNextRequestId
{
    responseIdNumber++;
    return [[NSString alloc] initWithFormat:@"%i", responseIdNumber];
}

- (NSString*) appendResponseType:(SGFoursquareResponse)type toRequestId:(NSString*)requestId
{
    return [NSString stringWithFormat:@"%i-%@", type, requestId];
}

- (NSString*) removeResponseTypeFromRequestId:(NSString*)requestId
{
    return [[requestId componentsSeparatedByString:@"-"] objectAtIndex:1];
}

- (SGFoursquareResponse) getResponseTypeFromRequestId:(NSString*)requestId
{
    return [[[requestId componentsSeparatedByString:@"-"] objectAtIndex:0] intValue];
}


////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Utility methods
////////////////////////////////////////////////////////////////////////////////////////////////

- (void) sendHTTPRequest:(NSString*)type toURL:(NSString*)file withParams:(NSString*)params requestId:(NSString*)requestId
{
	NSData *returnData;
    NSHTTPURLResponse *theResponse;
    NSError *theError;
	
    NSString* authString = [NSString stringWithFormat:@"%@:%@", username, password];
    NSData* data = [authString dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t size;
    char* encodedString = NewBase64Encode([data bytes], [data length], NO, &size);
    
    NSString* encodedAuthString = [NSString stringWithCString:encodedString encoding:NSUTF8StringEncoding];
        
    if(params) {
        params = [params stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        file = [file stringByAppendingFormat:@"?%@", params];
    }
    
    NSURL* url = [NSURL URLWithString:file];
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:10];
	
	[request setHTTPMethod:type];
    [request setValue:[NSString stringWithFormat:@"Basic %@", encodedAuthString] forHTTPHeaderField:@"Authorization"];
    	
	returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:&theError];
	
	// Possible loss of connection
	if(!returnData) {
		for(int i = 0; i < 3 && !returnData; i++) {
			NSLog(@"Retrying %@ request to %@...", type, [url description]);
			returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:&theError];	
            
            if(theError)
                break;
		}
	}
	
    NSString* payload = nil;
    
    if(returnData)
        payload = [[[NSString alloc] initWithData:returnData encoding:NSASCIIStringEncoding] autorelease];
    
    if(theResponse && ([theResponse statusCode] >= 300 || [theResponse statusCode] < 200)) {
     
        if(!theError)
            theError = [NSError errorWithDomain:payload ? payload : [NSHTTPURLResponse localizedStringForStatusCode:[theResponse statusCode]]
                                           code:[theResponse statusCode]
                                       userInfo:[theResponse allHeaderFields]];
            
     
    }
    
	if(theError) {
        
        NSDictionary* response = [NSDictionary dictionaryWithObjectsAndKeys:requestId, @"requestId", theError, @"error", nil];
        [self performSelectorOnMainThread:@selector(failed:) withObject:response waitUntilDone:NO];
        
    } else {
	
        NSDictionary* response = [NSDictionary dictionaryWithObjectsAndKeys:requestId, @"requestId", payload, @"responseObject", nil];
        [self succeeded:response];
    }
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

- (void) dealloc
{
    [password release];
    [username release];
    
    [delegates release];
    [operationQueue release];
    
    [super dealloc];
}

@end
