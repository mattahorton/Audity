//
//  AUDActivityViewController.h
//  Audity
//
//  Created by Matthew Horton on 3/13/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Audity.h"

@interface AUDActivityViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tblView;
@property (strong, nonatomic) IBOutlet UINavigationItem *viewTitle;
@property (strong, nonatomic) IBOutlet UILabel *likesLabel;
@property (strong, nonatomic) IBOutlet UIButton *likeButton;
@property (strong, nonatomic) IBOutlet UIButton *dislikeButton;
@property (strong, nonatomic) Audity *audity;

- (IBAction)dislike:(id)sender;
- (IBAction)like:(id)sender;

- (IBAction)respondButtonPressed:(id)sender;

-(void)addResponseToAudityWithSignature:(NSString *)signature andKey:(NSString *)key;


@end
