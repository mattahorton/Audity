//
//  AUDReach.h
//  Audity
//
//  Created by Matthew Horton on 5/30/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AUDLaunchController.h"
#import "Reachability.h"

@interface AUDReach : NSObject

@property (strong, nonatomic) Reachability *reach;
@property (nonatomic) BOOL online;

+ (id)sharedInstance;

@end
