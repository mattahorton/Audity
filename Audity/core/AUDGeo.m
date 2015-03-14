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
    self.core = [MHCore sharedInstance];
    self.inGodMode = NO;
    
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
    if (!self.inGodMode) {
        self.currentLoc = newLocation;
    } else {
        //set loc by center
        self.currentLoc = self.godModeCenter;
    }
    center = self.currentLoc;
    [circleQuery setCenter:center];
    
    if (!oldLocation) {
        center = [[CLLocation alloc] initWithLatitude:center.coordinate.latitude longitude:center.coordinate.longitude];
        // Query locations at [37.7832889, -122.4056973] with a radius of 600 meters
        //circleQuery = [self.geoFire queryAtLocation:center withRadius:MAXRADIUS/100.0]; //I believe this should be 1000, not 100.
        circleQuery = [self.geoFire queryAtLocation:center withRadius:MAXRADIUS/1000.0];
        
        enteredHandle = [circleQuery observeEventType:GFEventTypeKeyEntered withBlock:^(NSString *key, CLLocation *location) {
            CLLocationDistance distance = [location distanceFromLocation:self.currentLoc];
            NSLog(@"Key '%@' entered the search area and is at location '%@'", key, location);
            NSLog(@"It is %f meters away from you",distance);
            
            if ([self.core.audities objectForKey:key] == nil){
                NSLog(@"adding %@", key);
                NSLog(@"audity value %@",self.core.audities[key]);
                
                self.core.audities[key] = @"taken";
            
                NSURL *localUrl = [self.core.s3 downloadFileWithKey:[key stringByAppendingString:@".aiff"]];
                
                Firebase *audityRef = [self.recordingsRef childByAppendingPath:key];
                
                [audityRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                    [self.core.audities setObject:[NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                 @"location":location,
                                                                                                 @"key":key,
                                                                                                 @"signature":snapshot.value[@"signature"],
                                                                                                 @"userId":snapshot.value[@"userId"],
                                                                                                 @"localUrl": localUrl,
                                                                                                 @"focus": [NSNumber numberWithBool:NO],
                                                                                                 @"likes": @0,
                                                                                                 }]
                                           forKey:key];
                    if (snapshot.value[@"likes"] != nil) {
                        NSNumber *likes = (NSNumber *) snapshot.value[@"likes"];
                        self.core.audities[key][@"likes"] = likes;
                    }
                    
                    [self.core.vc addAudityToMapWithLocation:location andTitle:snapshot.value[@"signature"] andKey:key];
                }];
            } else {
                NSLog(@"Not adding %@", key);
            }
        }];
        
        exitedHandle = [circleQuery observeEventType:GFEventTypeKeyExited withBlock:^(NSString *key, CLLocation *location) {
            NSLog(@"Key '%@' exited the search area and is at location '%@'", key, location);
            [self.core.vc removeAudityFromMapWithKey:key];
            [self.core stopAudioWithKey:key]; // Also removes the audity from the array. Call last!
            
            // Remove file from temp directory
            [[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:key] error:NULL];
        }];

    }
    
    if(!self.inGodMode)[self.core centerMap:self.currentLoc];
    
    NSArray *keys = [self.core.audities allKeys];
    
    for (NSString *key in keys){
        [self.core setAllAudioParametersForAudityWithKey:key];
    }
}

#pragma mark Interaction Methods

-(void) addLoc:(NSString *) uuid bySignature:(NSString *)signature{
    
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
    
    NSDictionary *dict = @{@"recording":url,@"userId":self.core.userID,@"signature":signature, @"uploaded":[[NSDate date] description]};
    Firebase *locRef = [self.recordingsRef childByAppendingPath:uuid];
    
    [locRef setValue:dict];
}

-(void) updateAfterDragWithCenter:(CLLocation *)dragCenter {
    self.godModeCenter = dragCenter;
    self.currentLoc = self.godModeCenter;
    [circleQuery setCenter:self.currentLoc];
    
    
    NSArray *keys = [self.core.audities allKeys];
    
    for (NSString *key in keys){
        [self.core setAllAudioParametersForAudityWithKey:key];
    }
}

@end