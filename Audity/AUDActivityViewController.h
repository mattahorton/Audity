//
//  AUDActivityViewController.h
//  Audity
//
//  Created by Matthew Horton on 3/13/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AUDActivityViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tblView;
@property (strong, nonatomic) IBOutlet UINavigationItem *viewTitle;
@property (strong, nonatomic) IBOutlet UILabel *likesLabel;
@property (strong, nonatomic) NSMutableDictionary *audity;

- (IBAction)dislike:(id)sender;
- (IBAction)like:(id)sender;


@end
