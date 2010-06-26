//
//  NSStringAdditions.h
//  defensively
//
//  Created by Derek Smith on 6/5/10.
//  Copyright 2010 BlunderMove. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (BlunderMove) 

- (NSString*) URLEncodedString;
- (NSString*) MinimalURLEncodedString;
- (NSString*) URLDecodedString;

@end
