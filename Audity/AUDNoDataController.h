//
//  AUDNoDataController.h
//  Audity
//
//  Created by Matthew Horton on 5/30/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AUDReach;

@interface AUDNoDataController : UIViewController

@property (strong, nonatomic) AUDReach *reach;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *pinTop;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *pinLeft;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *pinRight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textBottom;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *pinHeight;

@end
