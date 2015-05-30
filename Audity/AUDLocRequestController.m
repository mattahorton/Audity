//
//  AUDLocRequestController.m
//  Audity
//
//  Created by Matthew Horton on 5/30/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDLocRequestController.h"
#import <CoreLocation/CoreLocation.h>

@implementation AUDLocRequestController

-(void) viewDidLoad {
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self performSegueWithIdentifier:@"dismissLoc" sender:self];
            break;
        default:
            break;
    }
}

-(void) viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (IBAction)enableLoc:(id)sender {
    [self setFirstRunIfNeeded];
    if (self.containerController != nil) {
        [self.containerController performSegueWithIdentifier:@"tutToMap" sender:self.containerController];
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
            if(self.fromMap) {
                [self performSegueWithIdentifier:@"locToMap" sender:self];
            } else {
                [self performSegueWithIdentifier:@"dismissLoc" sender:self];
            }
            break;
        default:
            break;
    }
}

@end
