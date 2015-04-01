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
#import "MapBox.h"

@interface MHViewController : UIViewController <RMMapViewDelegate>

@property (nonatomic, strong) NSString *mapboxKey;
@property (nonatomic, strong) NSString *mapID;

- (void)addAudityToMapWithLocation:(CLLocation *)loc andTitle:(NSString *)title andKey:(NSString *)key;
-(void) removeAudityFromMapWithKey:(NSString *)key;
-(void) moveAudityToLocation:(CLLocation*)loc forKey:(NSString *)key;
- (void) changeMapCenterWithLocation:(CLLocation *)loc;

-(void) viewWillAppear:(BOOL)animated;
-(void) viewWillDisappear:(BOOL)animated;
- (void) stopSpinner;

@end
