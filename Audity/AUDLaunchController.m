//
//  AUDLaunchController.m
//  Audity
//
//  Created by Matthew Horton on 4/23/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDLaunchController.h"

@implementation AUDLaunchController

-(void) viewDidAppear:(BOOL)animated {
    // Find firstRun in defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSObject *firstRunCheck = [defaults objectForKey:@"firstRun"];
    NSLog(@"%@ firstRunCheck", firstRunCheck);
    if (firstRunCheck != nil) {
        [self performSegueWithIdentifier:@"map" sender:self];
    } else {
        [defaults setObject:@"firstRun" forKey:@"firstRun"];
        [self performSegueWithIdentifier:@"tutorial" sender:self];
    }
}

@end
