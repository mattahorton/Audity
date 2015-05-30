//
//  AUDLaunchController.m
//  Audity
//
//  Created by Matthew Horton on 4/23/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDLaunchController.h"
#import "MHCore.h"
#import "AUDLocRequestController.h"

@implementation AUDLaunchController

-(void) viewDidAppear:(BOOL)animated {
    // Find firstRun in defaults
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSObject *firstRunCheck = [defaults objectForKey:@"firstRun"];
    NSLog(@"%@ firstRunCheck", firstRunCheck);
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
                [MHCore testInternetConnectionWithTarget:self
                                      andSuccessSelector:@selector(success)
                                       andFailedSelector:@selector(failure)];
                
                break;
                
        }
    }
}

#pragma mark Internet Connection Callbacks

-(void) success {
    NSLog(@"SUCCESS");
    
    [self performSegueWithIdentifier:@"map" sender:self];
}

-(void) failure {
    NSLog(@"FAILURE");
}


@end