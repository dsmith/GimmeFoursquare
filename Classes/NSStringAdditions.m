//
//  NSStringAdditions.m
//  defensively
//
//  Created by Derek Smith on 6/5/10.
//  Copyright 2010 BlunderMove. All rights reserved.
//

#import "NSStringAdditions.h"

@implementation NSString (BlunderMove)

- (NSString*) URLEncodedString 
{
    
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (CFStringRef)self,
                                                                           NULL,
                                                                           CFSTR("!*'();:@&=+$,/?#[]"),
                                                                           kCFStringEncodingUTF8);
    return result;
}

- (NSString*) MinimalURLEncodedString {
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (CFStringRef)self,
                                                                           CFSTR("%"),             
                                                                           CFSTR("?=&+"),          
                                                                           kCFStringEncodingUTF8); 
    [result autorelease];
    return result;
}

- (NSString*) URLDecodedString
{
    NSString *result = (NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                           (CFStringRef)self,
                                                                                           CFSTR(""),
                                                                                           kCFStringEncodingUTF8);
    [result autorelease];
    return result;  
}

@end
