//
//  AUDWelcomeController.h
//  Audity
//
//  Created by Matthew Horton on 5/30/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AUDTutorialController.h"

@interface AUDWelcomeController : UIViewController

@property (strong, nonatomic) AUDTutorialController *containerController;

- (IBAction)welcomeTapped:(id)sender;

@end
