//
//  AUDGeo.m
//  Audity
//
//  Created by Matthew Horton on 3/1/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDGeo.h"

@implementation AUDGeo

#pragma mark Singleton Methods

+ (id)sharedInstance {
    static AUDGeo *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)init {
    if (self = [super init]) {
        self.geofireRef = [[Firebase alloc] initWithUrl:@"https://audity.firebaseio.com/"];
        self.geoFire = [[GeoFire alloc] initWithFirebaseRef:self.geofireRef];
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

@end