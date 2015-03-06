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
#import "AUDS3.h"
#import <Firebase/Firebase.h>

@class AUDGeo;

@interface MHCore : NSObject

@property (nonatomic) MHViewController* vc;
@property (nonatomic) BOOL fromFile;
@property (nonatomic) AEAudioController *audioController;
@property (nonatomic,strong) AUDGeo *geo;
@property (nonatomic,strong) Firebase *firebase;
@property (nonatomic,strong) AUDS3 *s3;
@property (nonatomic,strong) AERecorder *recorder;
@property (nonatomic, strong) NSMutableDictionary *audities;
@property (nonatomic, strong) NSString *userID;

-(instancetype)initWithViewController:(MHViewController *)vc;
-(NSString *)uploadNewAudity:(NSURL *)file withKey:(NSString *)key;
-(void) centerMap:(CLLocation *)loc;
-(void) startRecording;
-(void) endRecording;
-(void) coreInit;
-(void) unmute;
-(void) mute;

@end
