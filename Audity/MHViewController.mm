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

#define BUTTON_HEIGHT 80
#define BUTTON_WIDTH 80
#define BUTTON_BORDER_OFFSET 14

#define MIN_ZOOM 7
#define MAX_ZOOM 17

@interface MHViewController()

@property (strong, nonatomic) MHCore *core;

@end

@implementation MHViewController {
    float viewHeight;
    float viewWidth;
    RMMapView *mapView;
}

- (void) addAudityToMapWithLocation:(CLLocation *)loc andTitle:(NSString *)title andKey:(NSString *)key{
    RMPointAnnotation *annotation = [[RMPointAnnotation alloc] initWithMapView:mapView coordinate:loc.coordinate andTitle:title];
    
    [mapView addAnnotation:annotation];
    [self.core.audities[key] setObject:annotation forKey:@"annotation"];
}

-(void) removeAudityFromMapWithKey:(NSString *)key{
    [mapView removeAnnotation:self.core.audities[key][@"annotation"]];
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
    mapView.draggingEnabled = NO;
    mapView.zoomingInPivotsAroundCenter = YES;
//    mapView.clusteringEnabled = YES;
    mapView.showsUserLocation = YES;

    // init the dict for on-screen audities
    self.core.audities = [[NSMutableDictionary alloc] initWithDictionary:@{}];

    mapView.minZoom = MIN_ZOOM;
    mapView.maxZoom = MAX_ZOOM;
    mapView.bouncingEnabled = YES;
    
    [mapView setZoom:MAX_ZOOM animated:NO];
    
}

- (void) initButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(handleButtonPress:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Record Audity" forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"RecButton.png"] forState:UIControlStateNormal];
    button.frame = CGRectMake(viewWidth - BUTTON_WIDTH - (BUTTON_BORDER_OFFSET * 2),
                              viewHeight - BUTTON_HEIGHT - (BUTTON_BORDER_OFFSET / 2),
                              BUTTON_WIDTH, BUTTON_HEIGHT);
    [mapView addSubview:button];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Clear Temp Directory
    NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
    }
    
    viewHeight = [[UIScreen mainScreen] bounds].size.height;
    viewWidth = [[UIScreen mainScreen] bounds].size.width;
    
    self.core = [MHCore sharedInstance];
    self.core.vc = self;
    // initialize
    [self.core coreInit];

    //The setup code (in viewDidLoad in your view controller)
    [self initMapBox];
    [self initButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
    }
    
    // Dispose of any resources that can be recreated.
}

-(IBAction)handleButtonPress:(id)sender {
    UIButton *button = (UIButton *)sender;
    if(!self.core.isRecording) {
        NSLog(@"Recording");
        [self.core startRecording];
        [button setImage:[UIImage imageNamed:@"Stop.png"] forState:UIControlStateNormal];
    } else {
        [self.core endRecording];
        [button setImage:[UIImage imageNamed:@"RecButton.png"] forState:UIControlStateNormal];
    }
}

- (void)afterMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction {
    [self.core centerMap:self.core.geo.currentLoc];
}


@end
