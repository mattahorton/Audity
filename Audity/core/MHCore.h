//
//  MHCore.h
//  Audity
//
//  Created by Matthew Horton on 1/16/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MHViewController.h"
#import "AERecorder.h"
#import "AUDGeo.h"
#import <Firebase/Firebase.h>
#import "CognitoIdentity.h"


@interface MHCore : NSObject

@property (nonatomic) MHViewController* vc;
@property (nonatomic) BOOL fromFile;
@property (nonatomic) AEAudioController *audioController;
@property (nonatomic,strong) AUDGeo *geo;
@property (nonatomic,strong) Firebase *firebase;

-(instancetype)initWithViewController:(MHViewController *)vc;
-(void) coreInit;
-(void) unmute;
-(void) mute;

@end
