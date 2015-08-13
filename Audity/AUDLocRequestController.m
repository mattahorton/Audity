//
//  AUDLocRequestController.m
//  Audity
//
//  Created by Matthew Horton on 5/30/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDLocRequestController.h"

@implementation AUDLocRequestController

-(void) viewDidLoad {
    self.locManager = [[CLLocationManager alloc] init];
    self.locManager.delegate = self;
}

-(void) viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (IBAction)enableLoc:(id)sender {
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        if ([self.locManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locManager requestWhenInUseAuthorization];
        }
    } else {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }
}

-(void) setFirstRunIfNeeded {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSObject *firstRunCheck = [defaults objectForKey:@"firstRun"];
    if (firstRunCheck == nil) [defaults setObject:@"firstRun" forKey:@"firstRun"];
}

-(void) appWillEnterForeground {
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self performSegueWithIdentifier:@"dismissLoc" sender:self];
            break;
        default:
            break;
    }
}

#pragma mark Location Delegate Methods
-(void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            if (self.containerController != nil) {
                [self setFirstRunIfNeeded];
                [self.containerController performSegueWithIdentifier:@"finishTutorial" sender:self.containerController];
            } else {
                [self performSegueWithIdentifier:@"dismissLoc" sender:self];
            }
            break;
        default:
            break;
    }
}

@end
