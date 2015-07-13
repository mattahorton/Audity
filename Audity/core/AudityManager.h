//
//  AudityManager.h
//  Audity
//
//  Created by Matthew Horton on 7/12/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Audity.h"

@interface AudityManager : NSObject

@property (strong, nonatomic) NSDictionary *audities;

+ (id)sharedInstance;

- (void)addAudity:(Audity *)audity withKey:(NSString *)key;
- (Audity *)removeAudityWithKey:(NSString *)key;


@end
