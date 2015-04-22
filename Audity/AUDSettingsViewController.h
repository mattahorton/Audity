//
//  AUDSettingsViewController.h
//  Audity
//
//  Created by Matthew Horton on 4/22/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AUDSettingsViewController : UITableViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *sigTextField;

- (IBAction)muteToggled:(id)sender;
- (IBAction)locationToggled:(id)sender;
- (IBAction)defaultSigChanged:(id)sender;


@end
