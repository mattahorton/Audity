//
//  AUDAnnotation.h
//  Audity
//
//  Created by Andrew Forsyth on 3/11/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMAnnotation.h"
#import "RMMarker.h"
#import "RMMapView.h"

@interface AUDAnnotation : RMAnnotation

- (id)initWithMapView:(RMMapView *)aMapView coordinate:(CLLocationCoordinate2D)aCoordinate title:(NSString *)aTitle andKey:(NSString *)key;
-(void)handleFocus;
-(void)handleResponse;

@end
