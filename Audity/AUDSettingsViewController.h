//
//  AUDSettingsViewController.h
//  Audity
//
//  Created by Matthew Horton on 4/22/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MHCore.h"

@interface AUDSettingsViewController : UITableViewController <UITextFieldDelegate>

@property (strong, nonatomic) MHCore *core;
@property (strong, nonatomic) IBOutlet UITextField *sigTextField;
@property (strong, nonatomic) IBOutlet UISwitch *muteSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *locationSwitch;

- (IBAction)muteToggled:(id)sender;
- (IBAction)locationToggled:(id)sender;
- (IBAction)defaultSigChanged:(id)sender;


@end
