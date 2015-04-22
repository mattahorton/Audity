//
//  AUDSettingsViewController.m
//  Audity
//
//  Created by Matthew Horton on 4/22/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDSettingsViewController.h"

@implementation AUDSettingsViewController {
    NSUserDefaults *defaults;
}

-(void) viewDidLoad {
    [super viewDidLoad];
    self.sigTextField.delegate = self;
    defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *text = [defaults stringForKey:@"defaultSig"];
    
    if (text != nil) {
        self.sigTextField.text = text;
    } else {
        self.sigTextField.text = @"anonymous";
        [defaults setValue:@"anonymous" forKey:@"defaultSig"];
    };
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)muteToggled:(id)sender {
}

- (IBAction)locationToggled:(id)sender {
}

- (IBAction)defaultSigChanged:(id)sender {
    UITextField *sig = (UITextField *)sender;
    [defaults setValue:sig.text forKey:@"defaultSig"];
}
@end
