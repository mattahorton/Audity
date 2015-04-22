//
//  AUDSettingsViewController.m
//  Audity
//
//  Created by Matthew Horton on 4/22/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDSettingsViewController.h"

@implementation AUDSettingsViewController

-(void) viewDidLoad {
    [super viewDidLoad];
    self.sigTextField.delegate = self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)backgroundToggle:(id)sender {
}
@end
