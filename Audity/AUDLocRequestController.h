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
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageTop;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageRight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageLeft;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *soundPlaceRight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *soundPlaceLeft;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *enableLeft;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *enableRight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonBottom;

@property (strong, nonatomic) IBOutlet UILabel *soundPlaceLabel;
@property (strong, nonatomic) IBOutlet UILabel *enableLabel;

@property (strong, nonatomic) AUDTutorialController *containerController;
@property (strong, nonatomic) CLLocationManager *locManager;

- (IBAction)enableLoc:(id)sender;

-(void) setFirstRunIfNeeded;

@end
