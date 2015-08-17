//
//  AUDLocRequestController.m
//  Audity
//
//  Created by Matthew Horton on 5/30/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDLocRequestController.h"

@implementation AUDLocRequestController

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    float screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    if (screenHeight == 480.0f) {
        self.imageRight.constant = 67;
        self.imageLeft.constant = 67;
        self.imageTop.constant = 36;
        self.enableLeft.constant = 46;
        self.enableRight.constant = 46;
        self.buttonBottom.constant = 30;
        
        self.soundPlaceLabel.hidden = YES;
        self.enableLabel.font = [UIFont fontWithName:@"Avenir Next" size:18];
        
    } else if (screenHeight == 568.0f) {
        self.imageRight.constant = 67;
        self.imageLeft.constant = 67;
        self.imageTop.constant = 36;
        self.soundPlaceLeft.constant = 46;
        self.soundPlaceRight.constant = 46;
        self.enableLeft.constant = 46;
        self.enableRight.constant = 46;
        self.buttonBottom.constant = 30;
        
        self.soundPlaceLabel.font = [UIFont fontWithName:@"Avenir Next" size:20];
        self.enableLabel.font = [UIFont fontWithName:@"Avenir Next" size:20];
        
    } else if (screenHeight == 667.0f) {
        self.imageRight.constant = 67;
        self.imageLeft.constant = 67;
        self.imageTop.constant = 62;
        self.soundPlaceLeft.constant = 61;
        self.soundPlaceRight.constant = 60;
        self.enableLeft.constant = 61;
        self.enableRight.constant = 60;
        self.buttonBottom.constant = 50;
    }
    
}

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
