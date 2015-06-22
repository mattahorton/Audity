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
    FirebaseHandle readyHandle;
    NSNumber *objectEnteredQuery;
    NSUserDefaults *defaults;
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
        // Setup foreground and background notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
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
    locManager.distanceFilter = 50.0;
    locManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [locManager startUpdatingLocation];
    
    if ([CLLocationManager headingAvailable]) {
        locManager.headingFilter = 5;
        [locManager startUpdatingHeading];
    }
    
    defaults = [NSUserDefaults standardUserDefaults];
    NSObject *boolCheck = [defaults objectForKey:@"locationSetting"];
    if (boolCheck) {
        _locationSetting = [defaults boolForKey:@"locationSetting"];
    } else {
        _locationSetting = YES;
        [defaults setBool:_locationSetting forKey:@"locationSetting"];
    }

}

#pragma mark Location Delegate Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    CLLocationAccuracy accuracy = newLocation.horizontalAccuracy;
    
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
        
        circleQuery = [self.geoFire queryAtLocation:center withRadius:MAXRADIUS/1000.0];
        
        objectEnteredQuery = @0;
        
        enteredHandle = [circleQuery observeEventType:GFEventTypeKeyEntered withBlock:^(NSString *key, CLLocation *location) {
            
            objectEnteredQuery = nil;
            
//            NSLog(@"Key '%@' entered the search area and is at location '%@'", key, location);
//            NSLog(@"It is %f meters away from you",distance);
            
            if ([self.core.audities objectForKey:key] == nil){
//                NSLog(@"adding %@", key);
//                NSLog(@"audity value %@",self.core.audities[key]);
                
                self.core.audities[key] = @"taken";
            
                [self.core.parse downloadFileWithFilename:[key stringByAppendingString:@".aiff"] isResponse:NO];
                NSURL *localUrl = [NSURL URLWithString:[key stringByAppendingString:@".aiff"]];
                
                Firebase *audityRef = [self.recordingsRef childByAppendingPath:key];
                
                [audityRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                    NSLog(@"adding %@", key);
                    NSLog(@"sig %@", snapshot.value[@"signature"]);
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
                    
                    if ([objectEnteredQuery isEqualToNumber:@0] && (accuracy < 50.0)) objectEnteredQuery = @1;
                }];
            } else {
//                NSLog(@"Not adding %@", key);
            }
        }];
        
        exitedHandle = [circleQuery observeEventType:GFEventTypeKeyExited withBlock:^(NSString *key, CLLocation *location) {
//            NSLog(@"Key '%@' exited the search area and is at location '%@'", key, location);
            [self.core.vc removeAudityFromMapWithKey:key];
            [self.core stopAudioWithKey:key]; // Also removes the audity from the array. Call last!
            
            // Remove file from temp directory
            [[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:key] error:NULL];
        }];
        
        readyHandle = [circleQuery observeReadyWithBlock:^{
            if((objectEnteredQuery != nil) && [objectEnteredQuery isEqualToNumber:@0]) {
                [self.core.vc stopSpinner];
            }
        }];

    }
    
    if(!self.inGodMode)[self.core centerMap:self.currentLoc];
    
    NSArray *keys = [self.core.audities allKeys];
    
    for (NSString *key in keys){
        [self.core setAllAudioParametersForAudityWithKey:key];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    if (newHeading.headingAccuracy < 0)
        return;
    
    // Use the true heading if it is valid.
    CLLocationDirection  theHeading = ((newHeading.trueHeading > 0) ?
                                       newHeading.trueHeading : newHeading.magneticHeading);
    
    self.currentHeading = theHeading;
    
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
    NSLog(@"dict %@", dict);
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

-(void) appDidEnterBackground {
    if(!self.locationSetting) {
        [locManager stopUpdatingLocation];
    }
}

-(void) appWillEnterForeground {
    if(!self.locationSetting) {
        [locManager startUpdatingLocation];
    }
}

@end