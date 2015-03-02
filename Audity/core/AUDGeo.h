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

@interface AUDGeo : NSObject

@property (nonatomic, strong) Firebase *geofireRef;
@property (nonatomic, strong) GeoFire *geoFire;

@end
