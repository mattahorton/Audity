//
//  AUDGeo.m
//  Audity
//
//  Created by Matthew Horton on 3/1/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDGeo.h"

@implementation AUDGeo {
    CLLocationManager *locManager;
    CLLocation *center;
    GFCircleQuery *circleQuery;
    FirebaseHandle enteredHandle;
    FirebaseHandle exitedHandle;
}

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

#pragma mark Initialization

-(void)geoInit {
    locManager = [[CLLocationManager alloc] init];
    locManager.delegate = self;
    locManager.distanceFilter = kCLDistanceFilterNone;
    locManager.desiredAccuracy = kCLLocationAccuracyBest;
    if ([locManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locManager requestWhenInUseAuthorization];
    }
    [locManager startUpdatingLocation];
}

#pragma mark Location Delegate Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    self.currentLoc = newLocation;
    center = self.currentLoc;
    [circleQuery setCenter:center];
    
    if (!oldLocation) {
        center = [[CLLocation alloc] initWithLatitude:center.coordinate.latitude longitude:center.coordinate.longitude];
        // Query locations at [37.7832889, -122.4056973] with a radius of 600 meters
        circleQuery = [self.geoFire queryAtLocation:center withRadius:0.6];
        
        enteredHandle = [circleQuery observeEventType:GFEventTypeKeyEntered withBlock:^(NSString *key, CLLocation *location) {
            CLLocationDistance distance = [location distanceFromLocation:self.currentLoc];
            NSLog(@"Key '%@' entered the search area and is at location '%@'", key, location);
            NSLog(@"It is %f meters away from you",distance);
            [self.core.vc addAudityToMapWithLocation:location andTitle:@"Audity"];
        }];
        
        exitedHandle = [circleQuery observeEventType:GFEventTypeKeyExited withBlock:^(NSString *key, CLLocation *location) {
            NSLog(@"Key '%@' exited the search area and is at location '%@'", key, location);
//            [self.core.vc addAudityToMapWithLocation:location];
        }];

    }
    
    [self.core centerMap:self.currentLoc];    
}

#pragma mark Interaction Methods

-(void) addLoc:(NSString *) uuid {
    
    [self.geoFire setLocation:self.currentLoc
                       forKey:uuid
          withCompletionBlock:^(NSError *error) {
              if (error != nil) {
                  NSLog(@"An error occurred: %@", error);
              } else {
                  NSLog(@"Saved location successfully!");
              }
    }];
    
    NSString *url = @"https://s3.amazonaws.com/audity/";
    url = [[url stringByAppendingString:uuid] stringByAppendingString:@".aiff"];
    
    NSDictionary *dict = @{@"recording":url};
    Firebase *hqRef = [self.recordingsRef childByAppendingPath:uuid];
    
    [hqRef setValue:dict];
}

@end