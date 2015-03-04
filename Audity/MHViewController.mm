//
//  MHViewController.m
//  Audity
//
//  Created by Matthew Horton on 1/19/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "MHViewController.h"
#import "MHCore.h"
#import "Mapbox.h"

@interface MHViewController()

@property (strong, nonatomic) MHCore *core;

@end

@implementation MHViewController {
    float viewHeight;
    float viewWidth;
    RMMapView *mapView;
}

- (void) addAudityToMapWithLocation:(CLLocation *)loc andTitle:(NSString *)title{
    RMPointAnnotation *annotation = [[RMPointAnnotation alloc] initWithMapView:mapView coordinate:loc.coordinate andTitle:title];
    
    [mapView addAnnotation:annotation];
    // OMG CHANGE THIS. MAKE THE KEY UNIQUE. THIS IS A STAND-IN
    [self.core.audities setObject:annotation forKey:title];
}

-(void) moveAudityToLocation:(CLLocation*)loc forKey:(NSString *)key{
    RMPointAnnotation *audity = (RMPointAnnotation *)[self.core.audities objectForKey:key];
    [audity setCoordinate:loc.coordinate];
}

- (void) changeMapCenterWithLocation:(CLLocation *)loc{
    [mapView setCenterCoordinate:loc.coordinate animated:YES];
    //mapView.centerCoordinate = loc.coordinate;
}

- (void)initMapBox {
    //public key access token for mapbox
    NSString *token = @"pk.eyJ1IjoiZm9yc3l0aGFjIiwiYSI6InZtbU51b28ifQ.zb7d5t9yri__gm8IPK0d6Q";
    [[RMConfiguration sharedInstance] setAccessToken:token];
    
    //get source for tiles
    RMMapboxSource *source = [[RMMapboxSource alloc] initWithMapID:@"forsythac.lbjne02n"];
    
    //get our mapview and add it to our view
    mapView = [[RMMapView alloc] initWithFrame:self.view.bounds andTilesource:source];
    [self.view addSubview:mapView];
    
    // disable dragging on the map
    mapView.draggingEnabled = false;
    
    // init the dict for on-screen audities
    self.core.audities = [[NSMutableDictionary alloc] initWithDictionary:@{}];
    
    // get the center location
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:mapView.centerCoordinate.latitude longitude:mapView.centerCoordinate.longitude];
    
    // add center loc to screen. We'll change this loc later.
    [self addAudityToMapWithLocation:loc andTitle:@"You"];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    viewHeight = [[UIScreen mainScreen] bounds].size.height;
    viewWidth = [[UIScreen mainScreen] bounds].size.width;
    
    self.core = [[MHCore alloc] initWithViewController:self];
    // initialize
    [self.core coreInit];

    //The setup code (in viewDidLoad in your view controller)
    [self initMapBox];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
    }
    
    // Dispose of any resources that can be recreated.
}

//The event handling method
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
//    CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    [self.core startRecording];
}
//maps code here



@end
