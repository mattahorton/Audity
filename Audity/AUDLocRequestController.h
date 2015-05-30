//
//  AUDLocRequestController.h
//  Audity
//
//  Created by Matthew Horton on 5/30/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AUDTutorialController.h"

@interface AUDLocRequestController : UIViewController

@property (strong, nonatomic) AUDTutorialController *containerController;
@property (nonatomic) BOOL fromMap;

- (IBAction)enableLoc:(id)sender;

-(void) setFirstRunIfNeeded;

@end
