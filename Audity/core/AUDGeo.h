//
//  AUDGeo.h
//  Audity
//
//  Created by Matthew Horton on 3/1/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>
#import <GeoFire/GeoFire.h>
#import <CoreLocation/CoreLocation.h>
#import "MHCore.h"

@class MHCore;

@interface AUDGeo : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) Firebase *fireRef;
@property (nonatomic, strong) Firebase *recordingsRef;
@property (nonatomic, strong) Firebase *geofireRef;
@property (nonatomic, strong) GeoFire *geoFire;
@property (nonatomic, strong) CLLocation *currentLoc;
@property (nonatomic, strong) MHCore *core;

+ (id)sharedInstance;
-(void)addLoc:(NSString *) uuid;

@end
