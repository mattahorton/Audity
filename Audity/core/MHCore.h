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
#import "AUDLaunchController.h"
#import "AERecorder.h"
#import "AUDGeo.h"
#import "AUDParse.h"
#import <Firebase/Firebase.h>

#define MAXRADIUS 500.0

@class AUDGeo;
@class AUDParse;

@interface MHCore : NSObject <UIAlertViewDelegate>

@property (nonatomic) MHViewController* vc;
@property (nonatomic) BOOL fromFile;
@property (nonatomic) AEAudioController *audioController;
@property (nonatomic) AEAudioController *recordingController;
@property (nonatomic,strong) AUDGeo *geo;
@property (nonatomic,strong) Firebase *firebase;
@property (nonatomic,strong) AUDParse *parse;
@property (nonatomic,strong) AERecorder *recorder;
@property (nonatomic, strong) NSMutableDictionary *audities;
@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSDictionary *apiKeys;
@property (nonatomic) BOOL isRecording;
@property (nonatomic) BOOL muteAudities;
@property (nonatomic) BOOL muteSetting;
@property (nonatomic) BOOL firstSoundPlayed;
@property (strong, nonatomic) AEAudioFilePlayer *recordedPlayer;
@property (nonatomic) BOOL replaying;

+(id) sharedInstance;

-(void) setAllAudioParametersForAudityWithKey:(NSString *)key;
-(void) setAllAudioParameters;
-(void)uploadNewAudity:(NSURL *)file withKey:(NSString *)key andSignature:(NSString *)signature;
-(void) uploadNewAudityResponse:(NSURL *)file withKey:(NSString *)key andSignature:(NSString *)signature forAudity:(NSString *)audityKey;
-(void) centerMap:(CLLocation *)loc;
-(void) playAudio:(NSURL *)file withKey:(NSString *)key;
-(void) stopAudioWithKey:(NSString *)key;
-(void) addLocAfterUploadWithSignature:(NSString *)signature;
-(void) addResponseToViewAfterUploadWithSignature:(NSString *)signature;
-(void) startRecording;
-(void) endRecording;
-(void)endResponseWithDelegate:(UIViewController *)vc;
-(void) coreInit;
-(void) unmute;
-(void) mute;
-(void) playResponse:(NSURL *)file;
-(void) muteAuditiesWithBool:(BOOL)val;
-(void) playRecorded:(NSURL *)file withButton:(UIButton *)button;

@end
