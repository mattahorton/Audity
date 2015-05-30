//
//  AUDLocRequestController.h
//  Audity
//
//  Created by Matthew Horton on 5/30/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AUDTutorialController.h"
#import <CoreLocation/CoreLocation.h>

@interface AUDLocRequestController : UIViewController <CLLocationManagerDelegate>

@property (strong, nonatomic) AUDTutorialController *containerController;
@property (strong, nonatomic) CLLocationManager *locManager;

- (IBAction)enableLoc:(id)sender;

-(void) setFirstRunIfNeeded;

@end
