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
    self.core = [MHCore sharedInstance];
    
    self.sigTextField.delegate = self;
    defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *text = [defaults stringForKey:@"defaultSig"];
    NSObject *boolCheck = [defaults objectForKey:@"muteSetting"];
    
    if (text != nil) {
        self.sigTextField.text = text;
    } else {
        self.sigTextField.text = @"anonymous";
        [defaults setValue:@"anonymous" forKey:@"defaultSig"];
    };
    
    if (self.core.muteSetting) {
        [self.muteSwitch setOn:self.core.muteSetting animated:YES];
    } else {
        if (boolCheck) {
            self.core.muteSetting = [defaults boolForKey:@"muteSetting"];
            [self.muteSwitch setOn:self.core.muteSetting animated:YES];
        } else {
            self.core.muteSetting = NO;
            [defaults setBool:self.core.muteSetting forKey:@"muteSetting"];
            [self.muteSwitch setOn:self.core.muteSetting animated:YES];
        }
    }
    
    if (self.core.geo.locationSetting) {
        [self.locationSwitch setOn:self.core.geo.locationSetting animated:YES];
    } else {
        if (boolCheck) {
            self.core.geo.locationSetting = [defaults boolForKey:@"locationSetting"];
            [self.locationSwitch setOn:self.core.geo.locationSetting animated:YES];
        } else {
            self.core.geo.locationSetting = YES;
            [defaults setBool:self.core.geo.locationSetting forKey:@"locationSetting"];
            [self.locationSwitch setOn:self.core.geo.locationSetting animated:YES];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)muteToggled:(id)sender {
    self.core.muteSetting = !self.core.muteSetting;
    [defaults setBool:self.core.muteSetting forKey:@"muteSetting"];
}

- (IBAction)locationToggled:(id)sender {
    self.core.geo.locationSetting = !self.core.geo.locationSetting;
    [defaults setBool:self.core.geo.locationSetting forKey:@"locationSetting"];
}

- (IBAction)defaultSigChanged:(id)sender {
    UITextField *sig = (UITextField *)sender;
    [defaults setValue:sig.text forKey:@"defaultSig"];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // Prevent crashing undo bug – see note below.
    if(range.length + range.location > textField.text.length)
    {
        return NO;
    }
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return newLength <= 22;
}

@end
