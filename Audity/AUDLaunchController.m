//
//  AUDLaunchController.m
//  Audity
//
//  Created by Matthew Horton on 4/23/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDLaunchController.h"
#import "AUDLocRequestController.h"
#import "AUDReach.h"

@implementation AUDLaunchController

-(void) viewDidLoad {
    self.reach = [AUDReach sharedInstance];
}

-(void) viewDidAppear:(BOOL)animated {
    // Find firstRun in defaults
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSObject *firstRunCheck = [defaults objectForKey:@"firstRun"];

    if (firstRunCheck == nil) {
        [self performSegueWithIdentifier:@"tutorial" sender:self];
    } else {
        switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusDenied:
            case kCLAuthorizationStatusRestricted:
                [self performSegueWithIdentifier:@"showLocReq" sender:self];
                break;
            case kCLAuthorizationStatusAuthorizedAlways:
            case kCLAuthorizationStatusAuthorizedWhenInUse:
            default:
                if (self.reach.online) {
                    [self performSegueWithIdentifier:@"map" sender:self];
                } else {
                    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(trigger:) userInfo:nil repeats:NO];
                }
                
                break;
                
        }
    }
}

-(void) trigger:(NSTimer *)timer {
    if (self.reach.online) {
        [self performSegueWithIdentifier:@"map" sender:self];
    } else {
        [self performSegueWithIdentifier:@"launchNoData" sender:self];
    }
}


@end