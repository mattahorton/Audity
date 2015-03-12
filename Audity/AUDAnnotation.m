//
//  AUDAnnotation.m
//  Audity
//
//  Created by Andrew Forsyth on 3/11/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDAnnotation.h"

@interface AUDAnnotation()

@property (strong, nonatomic) NSString *key;

@end

@implementation AUDAnnotation

- (id)initWithMapView:(RMMapView *)aMapView coordinate:(CLLocationCoordinate2D)aCoordinate
                title:(NSString *)aTitle andKey:(NSString *)key{
    
    self = [super initWithMapView:(RMMapView *)aMapView coordinate:(CLLocationCoordinate2D)aCoordinate andTitle:(NSString *)aTitle];
    if(self){
        self.key = key;
    }
    return self;
}

-(void)handleFocus{
    NSLog(@"focus button pressed for key %@", self.key);
}

-(void)handleResponse{
    NSLog(@"response button pressed for key %@", self.key);
}

@end
