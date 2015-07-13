//
//  AudityManager.m
//  Audity
//
//  Created by Matthew Horton on 7/12/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AudityManager.h"

@implementation AudityManager {
    NSMutableDictionary *_mutableAudities;
}

+ (id)sharedInstance {
    static AudityManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(instancetype) init {
    if (self = [super init]) {
        _mutableAudities = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (NSDictionary *)audities {
    return [NSDictionary dictionaryWithDictionary:_mutableAudities];
}

- (void)setAudities:(NSDictionary *)audities {
    _mutableAudities = [audities mutableCopy];
}

- (void) addAudity:(Audity *)audity withKey:(NSString *)key {
    [_mutableAudities setObject:audity forKey:key];
}

- (Audity *) removeAudityWithKey:(NSString *)key {
    Audity * audity = _mutableAudities[key];
    [_mutableAudities removeObjectForKey:key];
   return audity;
}

@end
