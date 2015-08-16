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


- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    float screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    if (screenHeight == 480.0f) {
        self.pinTop.constant = 30;
        self.pinLeft.constant = 73;
        self.pinRight.constant = 73;
        self.textBottom.constant = 50;
    } else if (screenHeight == 568.0f) {
        self.pinLeft.constant = 73;
        self.pinRight.constant = 73;
        self.textBottom.constant = 60;
    } else if (screenHeight == 667.0f) {
        self.textBottom.constant = 90;
        self.pinLeft.constant = 76;
        self.pinRight.constant = 75;
    }
}


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
