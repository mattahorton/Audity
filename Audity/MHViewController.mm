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
#import "AUDLocRequestController.h"
#import "AUDReach.h"
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
    AudityManager *audityManager;
}

#pragma mark View Delegate Methods

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup notifications for background, foreground, and lost Internet connection
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange) name:kReachabilityChangedNotification object:nil];
    
    
    // Clear Temp Directory
    NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
    }
    
    
    // Init size values for MapBox
    viewHeight = [[UIScreen mainScreen] bounds].size.height;
    viewWidth = [[UIScreen mainScreen] bounds].size.width;
    
    // Set status bar style
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    // Set AudityManager
    audityManager = [AudityManager sharedInstance];
    
    // Init the core
    self.core = [MHCore sharedInstance];
    self.core.vc = self;
    
    // initialize core
    [self.core coreInit];
    
    focusButtons = [NSMutableArray arrayWithArray:@[]];
    
    [self initMapBox];
    [self initButtons];
    [self initRadius];
    
}

-(void) redraw {
    [mapView setNeedsDisplay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
    }
    
    // Dispose of any resources that can be recreated.
}







#pragma mark UI Init Methods

- (void)initMapBox {
    self.mapboxKey = self.core.apiKeys[@"MAPBOX"];
    self.mapID = self.core.apiKeys[@"MAPID"];
    
    //public key access token for mapbox
    NSString *token = self.mapboxKey;
    [[RMConfiguration sharedInstance] setAccessToken:token];
    
    //get source for tiles
    RMMapboxSource *source = [[RMMapboxSource alloc] initWithMapID:self.mapID];
    
    //get our mapview and add it to our view
    mapView = [[RMMapView alloc] initWithFrame:self.view.bounds andTilesource:source];
    mapView.delegate = self;
    [self.view addSubview:mapView];
    
    // disable dragging on the map
    mapView.draggingEnabled = NO;
    mapView.zoomingInPivotsAroundCenter = YES;
//    mapView.clusteringEnabled = YES;
    mapView.userInteractionEnabled = NO;
    mapView.showsUserLocation = NO;
    
    mapView.minZoom = MIN_ZOOM;
    mapView.maxZoom = MAX_ZOOM;
    mapView.bouncingEnabled = YES;
    
    [mapView setZoom:MAX_ZOOM animated:NO];
    
    [MBProgressHUD showHUDAddedTo:mapView animated:YES];
    
}

- (void) initButtons {
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
    //do some stuff
}






#pragma Audity Methods

-(RMMarker *) newAudityMarkerWithColor:(UIColor *)color {
    RMMarker *marker = [[RMMarker alloc] initWithMapboxMarkerImage:nil tintColor:color];
    
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

- (void) addAudityToMapWithLocation:(CLLocation *)loc andTitle:(NSString *)title andKey:(NSString *)key{
    Audity *audity = [audityManager audities][key];
    
    if (audity && audity.downloaded) {
        RMAnnotation *annotation = [[RMAnnotation alloc] initWithMapView:mapView coordinate:loc.coordinate andTitle:title];
        
        [mapView addAnnotation:annotation];
        audity.annotation = annotation;
    }
}

-(void) removeAudityFromMapWithKey:(NSString *)key{
    Audity *audity = [audityManager audities][key];
    
    if (audity && audity.downloaded) [mapView removeAnnotation:audity.annotation];
}

-(void) moveAudityToLocation:(CLLocation*)loc forKey:(NSString *)key{
    Audity *audity = [audityManager audities][key];
    
    if (audity && audity.downloaded) {
        RMAnnotation *audityAnnotation = audity.annotation;
        [audityAnnotation setCoordinate:loc.coordinate];
    }
}

-(void) setPlayingColorForAnnotation:(RMAnnotation *)annotation {
    [self setColor:[UIColor colorWithRed:102.0/255.0 green:51.0/255.0 blue:153.0/255.0 alpha:1.0] forAnnotation:annotation];
}

-(void) setNotPlayingColorForAnnotation:(RMAnnotation *)annotation {
    [self setColor:[UIColor colorWithRed:102.0/255.0 green:51.0/255.0 blue:153.0/255.0 alpha:0.2] forAnnotation:annotation];
}

-(void) setColor:(UIColor *)color forAnnotation:(RMAnnotation *)annotation {
    RMMarker *marker = [self newAudityMarkerWithColor:color];
    [annotation setLayer:marker];
}

- (void) changeMapCenterWithLocation:(CLLocation *)loc{
    [mapView setCenterCoordinate:loc.coordinate animated:YES];
    //mapView.centerCoordinate = loc.coordinate;
}





#pragma mark UI Interactions

-(IBAction)handleButtonPress:(id)sender {
    UIButton *button = (UIButton *)sender;
    if(!self.core.isRecording) {
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
    [self performSegueWithIdentifier:@"settingsShow" sender:nil];
}

- (void)afterMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction {
    if (!self.core.geo.inGodMode) [self.core centerMap:self.core.geo.currentLoc];
}

-(void)afterMapMove:(RMMapView *)map byUser:(BOOL)wasUserAction {
    [self.core.geo updateAfterDragWithCenter:[[CLLocation alloc] initWithLatitude:mapView.centerCoordinate.latitude longitude:mapView.centerCoordinate.longitude]];
}








#pragma mark MapView Delegate Methods
//37.42077700331567, -122.1722705104595

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{
    if (annotation.isUserLocationAnnotation){
        return nil;
    }
    
//    if (annotation.isClusterAnnotation) {
//        
//        RMMarker *layer = [self newAudityMarkerWithColor:[UIColor colorWithRed:150.0/255.0 green:150.0/255.0 blue:150.0/255.0 alpha:1.0]];
//        
//        layer.opacity = 0.75;
//        
//        // set the size of the circle
//        layer.bounds = CGRectMake(0, 0, 50, 50);
//        
//        // change the size of the circle depending on the cluster's size
//        if ([annotation.clusteredAnnotations count] > 2) {
//            layer.bounds = CGRectMake(0, 0, 70, 70);
//        } else if ([annotation.clusteredAnnotations count] > 3) {
//            layer.bounds = CGRectMake(0, 0, 100, 100);
//        } else if ([annotation.clusteredAnnotations count] > 5) {
//            layer.bounds = CGRectMake(0, 0, 120, 120);
//        }
//        
//        [(RMMarker *)layer setTextForegroundColor:[UIColor whiteColor]];
//        
//        [(RMMarker *)layer changeLabelUsingText:[NSString stringWithFormat:@"%lu",
//                                                 (unsigned long)[annotation.clusteredAnnotations count]]];
//        
//        return layer;
//    }
    
    RMMarker *marker =  [self newAudityMarkerWithColor:[UIColor colorWithRed:150.0/255.0 green:150.0/255.0 blue:150.0/255.0 alpha:1.0]];
    
    return marker;
}

- (void)tapOnCalloutAccessoryControl:(UIControl *)control forAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map
{
    UIButton * button = (UIButton *)control;
    
    if([[button currentTitle] isEqualToString:@"respond"]){
        NSArray *keys = [audityManager allKeys];
        
        for (NSString *key in keys){ // Iterate through keys
            Audity *audity = [audityManager audities][key];

            if(audity && audity.downloaded){
                if(audity.annotation == annotation){  // This is the Audity we want
                    [self performSegueWithIdentifier:@"activity" sender:audity.key];
                }
            }
        }
    }
    if([[button currentTitle] isEqualToString:@"focus"]){
        NSArray *keys = [audityManager allKeys];
        
        for (NSString *key in keys){ // Iterate through keys
            Audity *audity = [audityManager audities][key];
            
            if (audity && audity.downloaded) {
                if(audity.annotation == annotation){ // we want to toggle this focus
                    if(audity.focused){ //if it is already being focused on, unfocus
                        audity.focused = NO;
                        [button setImage:[UIImage imageNamed:@"Focus.png"] forState:UIControlStateNormal];
                    } else { //This audity is not focused on, so focus on it
                        audity.focused = YES;
                        [button setImage:[UIImage imageNamed:@"Unfocus.png"] forState:UIControlStateNormal];
                    }
                    
                } else { //This iteration is not the audity we tapped on
                    
                    if(audity.focused){ //if it's focused, unfocus
                        audity.focused = NO;
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
}






#pragma mark Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"activity"]) {
        NSString *key = (NSString *)sender;
        AUDNavViewController *destViewController = segue.destinationViewController;
        destViewController.info = key;
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










#pragma mark Background/Foreground

-(void) appDidEnterBackground {
    if(!self.core.geo.locationSetting) {
        NSLog(@"USER LOCATION JUST SET TO NO, THIS MAY BE AN ISSUE");
        mapView.showsUserLocation = NO;
    }
}

-(void) appWillEnterForeground {
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
            [self performSegueWithIdentifier:@"mapToLoc" sender:self];
            break;
        default:
            break;
            
    }
    
    if(!self.core.geo.locationSetting) {
        mapView.showsUserLocation = NO;
    }
}









#pragma mark Text Field Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // Prevent crashing undo bug – see note below.
    if(range.length + range.location > textField.text.length)
    {
        return NO;
    }
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return newLength <= 22;
}








#pragma mark Reachability

-(void) reachabilityDidChange {
    if (![[AUDReach sharedInstance] online]) {
        NSLog(@"DISCONNECTED");
        
        [self performSegueWithIdentifier:@"noData" sender:self];
    }
}

@end
