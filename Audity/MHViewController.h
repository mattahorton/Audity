//
//  MHViewController.h
//  Audity
//
//  Created by Matthew Horton on 1/19/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

@class AEAudioController;

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MHViewController : UIViewController

- (void)addAudityToMapWithLocation:(CLLocation *)coord;
- (void) changeMapCenterWithLocation:(CLLocation *)loc;

@end
