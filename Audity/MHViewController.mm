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
#import "AUDNavViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>

#define BUTTON_HEIGHT 60
#define BUTTON_WIDTH 60
#define BUTTON_BORDER_OFFSET 10

#define MIN_ZOOM 7
#define MAX_ZOOM 17

@interface MHViewController()

@property (strong, nonatomic) MHCore *core;

@end

@implementation MHViewController {
    float viewHeight;
    float viewWidth;
    RMMapView *mapView;
    NSMutableArray *focusButtons;
    UIButton *addButton;
    UIButton *godButton;
    UIButton *settingsButton;
    UIImageView *centerGodMarker;
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.core muteAuditiesWithBool:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    //NSLog(@"going away now");
}

-(void) viewWillAppear:(BOOL)animated {
    //NSLog(@"appearing now");
    [self.core muteAuditiesWithBool:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [super viewWillAppear:animated];
}

- (void) addAudityToMapWithLocation:(CLLocation *)loc andTitle:(NSString *)title andKey:(NSString *)key{
    if (![self.core.audities[key] isEqual:@"taken"]) {
        RMAnnotation *annotation = [[RMAnnotation alloc] initWithMapView:mapView coordinate:loc.coordinate andTitle:title];
        
        [mapView addAnnotation:annotation];
        [self.core.audities[key] setObject:annotation forKey:@"annotation"];
    }
}

-(void) removeAudityFromMapWithKey:(NSString *)key{
    if (![self.core.audities[key] isEqual:@"taken"]) [mapView removeAnnotation:self.core.audities[key][@"annotation"]];
}

-(void) moveAudityToLocation:(CLLocation*)loc forKey:(NSString *)key{
    if (![self.core.audities[key] isEqual:@"taken"]) {
        RMAnnotation *audity = (RMAnnotation *)[self.core.audities objectForKey:key];
        [audity setCoordinate:loc.coordinate];
    }
}

- (void) changeMapCenterWithLocation:(CLLocation *)loc{
    [mapView setCenterCoordinate:loc.coordinate animated:YES];
    //mapView.centerCoordinate = loc.coordinate;
}

- (void)initMapBox {
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"keys" ofType:@"plist"];
    NSDictionary *keys = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    
    self.mapboxKey = keys[@"MAPBOX"];
    self.mapID = keys[@"MAPID"];
    
    //public key access token for mapbox
    NSString *token = self.mapboxKey;
    [[RMConfiguration sharedInstance] setAccessToken:token];
    
    //get source for tiles
    RMMapboxSource *source = [[RMMapboxSource alloc] initWithMapID:self.mapID];
    
    //get our mapview and add it to our view
    mapView = [[RMMapView alloc] initWithFrame:self.view.bounds andTilesource:source];
    NSLog(@"%@ MAPVIEW", mapView);
    mapView.delegate = self;
    [self.view addSubview:mapView];
    
    // disable dragging on the map
    mapView.draggingEnabled = NO;
    mapView.zoomingInPivotsAroundCenter = YES;
//    mapView.clusteringEnabled = YES;
    mapView.userInteractionEnabled = NO;
    mapView.showsUserLocation = YES;

    // init the dict for on-screen audities
    self.core.audities = [[NSMutableDictionary alloc] initWithDictionary:@{}];

    mapView.minZoom = MIN_ZOOM;
    mapView.maxZoom = MAX_ZOOM;
    mapView.bouncingEnabled = YES;
    
    [mapView setZoom:MAX_ZOOM animated:NO];
    
    [MBProgressHUD showHUDAddedTo:mapView animated:YES];
    
}

- (void) initButton {
    addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [addButton addTarget:self action:@selector(handleButtonPress:) forControlEvents:UIControlEventTouchUpInside];
    [addButton setTitle:@"Record Audity" forState:UIControlStateNormal];
    [addButton setImage:[UIImage imageNamed:@"RecButton.png"] forState:UIControlStateNormal];
    addButton.frame = CGRectMake(viewWidth - BUTTON_WIDTH - (BUTTON_BORDER_OFFSET * 2),
                              viewHeight - BUTTON_HEIGHT - (BUTTON_BORDER_OFFSET / 2),
                              BUTTON_WIDTH, BUTTON_HEIGHT);
    [addButton setEnabled:NO];
    [mapView addSubview:addButton];
    
    godButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [godButton addTarget:self action:@selector(godModePress:) forControlEvents:UIControlEventTouchUpInside];
    [godButton setTitle:@"God Mode" forState:UIControlStateNormal];
    [godButton setImage:[UIImage imageNamed:@"GodMode.png"] forState:UIControlStateNormal];
    godButton.frame = CGRectMake(viewWidth - BUTTON_WIDTH - (BUTTON_BORDER_OFFSET * 2),
                              viewHeight - 2*BUTTON_HEIGHT - BUTTON_BORDER_OFFSET,
                              BUTTON_WIDTH, BUTTON_HEIGHT);
    [godButton setEnabled:NO];
    [mapView addSubview:godButton];
    
    //center button so I can see where the center is
    centerGodMarker = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Center.png"]];
    centerGodMarker.frame = CGRectMake(viewWidth/2 - BUTTON_WIDTH/8,
                                 viewHeight/2 - BUTTON_HEIGHT/8,
                                 BUTTON_WIDTH/4, BUTTON_HEIGHT/4);
    centerGodMarker.hidden = YES;
    [mapView addSubview:centerGodMarker];
    
    settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsButton addTarget:self action:@selector(settingsPress:) forControlEvents:UIControlEventTouchUpInside];
    [settingsButton setTitle:@"Settings" forState:UIControlStateNormal];
    [settingsButton setImage:[UIImage imageNamed:@"Settings.png"] forState:UIControlStateNormal];
    settingsButton.frame = CGRectMake(viewWidth - BUTTON_WIDTH,
                                 BUTTON_BORDER_OFFSET*2,
                                 BUTTON_WIDTH, BUTTON_HEIGHT);
    [settingsButton setEnabled:NO];
    [mapView addSubview:settingsButton];
    
}

-(void)initRadius{
    RMCircle *circle = [[RMCircle alloc] initWithView:mapView radiusInMeters:MAXRADIUS];
    
//do some stuff
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

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    //Init the core
    self.core = [MHCore sharedInstance];
    self.core.vc = self;
    // initialize
    [self.core coreInit];
    
    
    focusButtons = [NSMutableArray arrayWithArray:@[]];
    
    [self.core testInternetConnectionWithTarget:self
                               andSuccessSelector:@selector(success)
                                andFailedSelector:@selector(failure)];
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
        [self.core muteAuditiesWithBool:YES];
        
        [self.core startRecording];
        [button setImage:[UIImage imageNamed:@"Stop.png"] forState:UIControlStateNormal];
    } else {
        [self.core endRecording];
        [button setImage:[UIImage imageNamed:@"RecButton.png"] forState:UIControlStateNormal];
    }
}

-(IBAction)godModePress:(id)sender {
    UIButton *button = (UIButton *)sender;
    self.core.geo.godModeCenter = [[CLLocation alloc] initWithLatitude:mapView.centerCoordinate.latitude longitude:mapView.centerCoordinate.longitude];
    
    if(!self.core.geo.inGodMode) {
        NSLog(@"Entering God Mode");
        self.core.geo.inGodMode = YES;
        mapView.draggingEnabled = YES;
        self.core.geo.localCenter = self.core.geo.currentLoc;
        self.core.geo.currentLoc = self.core.geo.godModeCenter;
        [button setImage:[UIImage imageNamed:@"LocalMode.png"] forState:UIControlStateNormal];
        addButton.enabled = false;
    } else {
        NSLog(@"Entering Local Mode");
        self.core.geo.inGodMode = NO;
        mapView.draggingEnabled = NO;
        self.core.geo.godModeCenter = nil;
        self.core.geo.currentLoc = self.core.geo.localCenter;
        [button setImage:[UIImage imageNamed:@"GodMode.png"] forState:UIControlStateNormal];
        [self.core centerMap:self.core.geo.currentLoc];
        addButton.enabled = true;
    }
    
    [self.core setAllAudioParameters]; // update sound params for location
}

-(IBAction)settingsPress:(id)sender {
    NSLog(@"settings");
    [self performSegueWithIdentifier:@"settingsShow" sender:nil];
}

- (void)afterMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction {
    if (!self.core.geo.inGodMode) [self.core centerMap:self.core.geo.currentLoc];
}

-(void)afterMapMove:(RMMapView *)map byUser:(BOOL)wasUserAction {
//    NSLog(@"map moved");
    [self.core.geo updateAfterDragWithCenter:[[CLLocation alloc] initWithLatitude:mapView.centerCoordinate.latitude longitude:mapView.centerCoordinate.longitude]];
}

#pragma mark MapView Delegate Methods
//37.42077700331567, -122.1722705104595

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{
    if (annotation.isUserLocationAnnotation){
        
        RMCircle *circle = [[RMCircle alloc] initWithView:mapView radiusInMeters:MAXRADIUS];
        circle.lineColor = [UIColor colorWithRed:102.0/255.0 green:51.0/255.0 blue:153.0/255.0 alpha:1.0];
        circle.fillColor = [UIColor colorWithRed:226.0/255.0 green:220.0/255.0 blue:255.0/255.0 alpha:0.2];
        circle.lineWidthInPixels = 2.0;
        annotation.enabled= NO;
        
        return circle;
    }
    
    RMMarker *marker = [[RMMarker alloc] initWithMapboxMarkerImage:nil tintColor:[UIColor colorWithRed:102.0/255.0 green:51.0/255.0 blue:153.0/255.0 alpha:1.0]];
    
    marker.canShowCallout = YES;
    
    UIButton *respond = [UIButton buttonWithType:UIButtonTypeCustom];
    [respond setImage:[UIImage imageNamed:@"Respond.png"] forState:UIControlStateNormal];
    [respond setTitle:@"respond" forState:UIControlStateNormal];
    respond.frame = CGRectMake(0,0,30,30);
    
    marker.leftCalloutAccessoryView = respond;
    
    UIButton *focus = [UIButton buttonWithType:UIButtonTypeCustom];
    [focus setImage:[UIImage imageNamed:@"Focus.png"] forState:UIControlStateNormal];
    [focus setTitle:@"focus" forState:UIControlStateNormal];
    focus.frame = CGRectMake(0,0,30,30);
    [focusButtons addObject:focus];
    
    marker.rightCalloutAccessoryView = focus;
    
    return marker;
}

- (void)tapOnCalloutAccessoryControl:(UIControl *)control forAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map
{
    UIButton * button = (UIButton *)control;
    if([[button currentTitle] isEqualToString:@"respond"]){
        NSArray *keys = [self.core.audities allKeys];
        
        for (NSString *key in keys){ // Iterate through keys
            if (![self.core.audities[key] isEqual:@"taken"]) {
                NSDictionary *audity = (NSDictionary *)[self.core.audities objectForKey:key];
                if([audity objectForKey:@"annotation"] == annotation){  // This is the Audity we want
        
//                    NSDictionary *dict = @{@"key":key,@"signature":(NSString *)audity[@"signature"]};
                    [self performSegueWithIdentifier:@"activity" sender:audity];
                }
            }
        }
    }
    if([[button currentTitle] isEqualToString:@"focus"]){
        NSArray *keys = [self.core.audities allKeys];
        
        for (NSString *key in keys){ // Iterate through keys
            if (![self.core.audities[key] isEqual:@"taken"]) {
                if([[self.core.audities objectForKey:key] objectForKey:@"annotation"] == annotation){ // we want to toggle this focus
                    if([[[self.core.audities objectForKey:key] objectForKey:@"focus"] boolValue]){ //if it is already being focused on, unfocus
                        //NSLog(@"setting focus to false");
                        NSNumber *num = [NSNumber numberWithBool:NO];
                        [[self.core.audities objectForKey:key] setObject:num forKey:@"focus"];
                        [button setImage:[UIImage imageNamed:@"Focus.png"] forState:UIControlStateNormal];
                    }else{                                                              //This audity is not focused on, so focus on it
                        //NSLog(@"setting focus to true");
                        NSNumber *num = [NSNumber numberWithBool:YES];
                        [[self.core.audities objectForKey:key] setObject:num forKey:@"focus"];
                        [button setImage:[UIImage imageNamed:@"Unfocus.png"] forState:UIControlStateNormal];
                    }
                    
                } else { //This iteration is not the audity we tapped on
                    
                    if([[[self.core.audities objectForKey:key] objectForKey:@"focus"] boolValue]){ //if it's focused, unfocus
                        NSNumber *num = [NSNumber numberWithBool:NO];
                        [[self.core.audities objectForKey:key] setObject:num forKey:@"focus"];
                    }
                    
                }
            }
        }
        
        // update parameters after setting focus variables
        [self.core setAllAudioParameters];
        
        // reset button states
        for (UIButton *b in focusButtons){
            if (![b isEqual:button]) {
                [b setImage:[UIImage imageNamed:@"Focus.png"] forState:UIControlStateNormal];
            }
        }
    }
    //NSLog(@"You tapped the callout button!");
}

#pragma mark Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"activity"]) {
        NSDictionary *dict = (NSDictionary *)sender;
        AUDNavViewController *destViewController = segue.destinationViewController;
        destViewController.info = dict;
    }
}

#pragma mark Outside Access to Views
- (void) stopSpinner {
    [addButton setEnabled:YES];
    [godButton setEnabled:YES];
    [settingsButton setEnabled:YES];
    mapView.userInteractionEnabled = YES;
    centerGodMarker.hidden = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:mapView animated:YES];
    });
}

-(void)resetNewAudityButton {
    [addButton setImage:[UIImage imageNamed:@"RecButton.png"] forState:UIControlStateNormal];
}

#pragma mark Internet Connection Callbacks

-(void) success {
    NSLog(@"SUCCESS");
    
    //The setup code (in viewDidLoad in your view controller)
    [self initMapBox];
    [self initButton];
    [self initRadius];
}

-(void) failure {
    NSLog(@"FAILURE");
}

@end
