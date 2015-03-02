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
        self.fireRef = [[Firebase alloc] initWithUrl:@"https://audity.firebaseio.com/"];
        self.recordingsRef = [self.fireRef childByAppendingPath:@"recordings"];
        self.geofireRef = [self.fireRef childByAppendingPath:@"geofire"];
        self.geoFire = [[GeoFire alloc] initWithFirebaseRef:self.geofireRef];
        [self geoInit];
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

-(void)geoInit {
    CLLocation *center = [[CLLocation alloc] initWithLatitude:37.7832889 longitude:-122.4056973];
    // Query locations at [37.7832889, -122.4056973] with a radius of 600 meters
    GFCircleQuery *circleQuery = [self.geoFire queryAtLocation:center withRadius:0.6];
}

-(void) addLoc {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    [self.geoFire setLocation:[[CLLocation alloc] initWithLatitude:37.7853889 longitude:-122.4056973]
                       forKey:uuid
          withCompletionBlock:^(NSError *error) {
              if (error != nil) {
                  NSLog(@"An error occurred: %@", error);
              } else {
                  NSLog(@"Saved location successfully!");
              }
    }];
    
    NSDictionary *dict = @{@"recording":@"url"};
    Firebase *hqRef = [self.recordingsRef childByAppendingPath:uuid];
    
    [hqRef setValue:dict];
    
}

@end