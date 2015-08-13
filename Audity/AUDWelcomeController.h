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

// constraints
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *audityTop;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *loginBottom;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *passwordLeft;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *passwordRight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *emailLeft;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *emailRight;

// views
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UITextField *email;

- (IBAction)welcomeTapped:(id)sender;

@end
