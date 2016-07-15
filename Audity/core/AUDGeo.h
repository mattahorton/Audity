//
//  AUDGeo.h
//  Audity
//
//  Created by Matthew Horton on 3/1/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>
#import "GeoFire.h"
#import <CoreLocation/CoreLocation.h>
#import "MHCore.h"

@class MHCore;

@interface AUDGeo : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) FIRDatabaseReference *recordingsRef;
@property (nonatomic, strong) FIRDatabaseReference *geofireRef;
@property (nonatomic, strong) GeoFire *geoFire;
@property (nonatomic, strong) CLLocation *currentLoc;
@property (nonatomic) CLLocationDirection currentHeading;
@property (nonatomic, strong) MHCore *core;
@property (nonatomic) BOOL inGodMode;
@property (nonatomic, strong) CLLocation *godModeCenter;
@property (nonatomic, strong) CLLocation *localCenter;
@property (nonatomic) BOOL locationSetting;

+ (id)sharedInstance;
-(void) geoInit;
-(void)addLoc:(NSString *) uuid bySignature:(NSString *)signature;
-(void)updateAfterDragWithCenter:(CLLocation *)center;

@end
