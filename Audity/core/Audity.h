//
//  Audity.h
//  Audity
//
//  Created by Matthew Horton on 7/12/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import "Mapbox.h"
#import "AEAudioFilePlayer.h"
#import "AEAudioUnitFilter.h"

@interface Audity : NSObject

@property (nonatomic) NSInteger likes;
@property (nonatomic) BOOL downloaded;
@property (nonatomic) BOOL focused;

@property (strong, nonatomic) NSString *key;
@property (strong, nonatomic) NSString *recording;
@property (strong, nonatomic) NSString *signature;
@property (strong, nonatomic) NSString *uploaded;
@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSDictionary *responses;
@property (strong, nonatomic) AEAudioFilePlayer *filePlayer;
@property (strong, nonatomic) AEAudioUnitFilter *reverb;
@property (strong, nonatomic) AEAudioUnitFilter *lp;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) RMAnnotation *annotation;

@end
