//
//  AUDNoDataController.m
//  Audity
//
//  Created by Matthew Horton on 5/30/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDNoDataController.h"
#import "AUDReach.h"

@implementation AUDNoDataController

-(void) viewDidLoad  {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange) name:kReachabilityChangedNotification object:nil];
}

#pragma mark Reachability

-(void) reachabilityDidChange {
    if ([[AUDReach sharedInstance] online]) {
        
        [self performSegueWithIdentifier:@"dismissNoData" sender:self];
    }
}

@end
