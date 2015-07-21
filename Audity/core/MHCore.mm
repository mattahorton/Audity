//
//  MHCore.m
//  Audity
//
//  Created by Matthew Horton on 1/16/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "MHCore.h"
#import "AEBlockAudioReceiver.h"
#import "AEAudioFilePlayer.h"
#import "AEUtilities.h"
#import "AUDActivityViewController.h"
#import <DLAlertView/DLAVAlertView.h>
#import "Secrets.h"
#import "AUDFirebase.h"
#import "AUDUser.h"

#define SRATE 24000
#define FRAMESIZE 512
#define NUM_CHANNELS 2


@implementation MHCore {
    long framesize;
    AEBlockChannel *audioOut;
    NSString *documentsFolder;
    NSUserDefaults *defaults;
    NSString *tempKey;
    AUDActivityViewController *audVC;
    UIButton *replayButton;
    NSTimer *recordingTimer;
    AUDUser *audUser;
}

+ (id)sharedInstance {
    static MHCore *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(id) init {
    if(self = [super init]) {
        self.audityManager = [AudityManager sharedInstance];
    }
    return self;
}

-(void) coreInit {
    
    // Initialize
    self.isRecording = NO;
    self.muteAudities = NO;
    self.firstSoundPlayed = NO;
    self.replaying = NO;
    
    // Get API keys
    Secrets *secrets = [Secrets sharedInstance];
    self.apiKeys = secrets.apiKeys;
    
    
    // Get and set mute setting
    defaults = [NSUserDefaults standardUserDefaults];
    NSObject *boolCheck = [defaults objectForKey:@"muteSetting"];
    if (boolCheck) {
        _muteSetting = [defaults boolForKey:@"muteSetting"];
    } else {
        _muteSetting = NO;
        [defaults setBool:_muteSetting forKey:@"muteSetting"];
    }
    
    
    // Authenticate
    audUser = [AUDUser sharedInstance];
    [audUser authAnonWithTarget:self andSelector:@selector(afterAuth:)];
//    [audUser authTwitterWithTarget:self andSelector:@selector(afterAuth:)];
    
    // Set up audio controller
    self.audioController = [[AEAudioController alloc]
                            initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription]
                            inputEnabled:NO];
    
    NSError *errorAudioSetup = NULL;
    BOOL result = [[self audioController] start:&errorAudioSetup];
    if ( !result ) {
        NSLog(@"Error starting audio engine: %@", errorAudioSetup.localizedDescription);
    }
    
    // Set up documents folder
    documentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
                                 objectAtIndex:0];
    
    
    // Convenience data
    NSTimeInterval dur = self.audioController.currentBufferDuration;
    
    framesize = AEConvertSecondsToFrames(self.audioController, dur);

    // A buffer in case we need it
    audioOut = [AEBlockChannel channelWithBlock:^(const AudioTimeStamp  *time,
                                                           UInt32 frames,
                                                           AudioBufferList *audio) {
        
        for ( int i=0; i<frames; i++ ) {
            ((float*)audio->mBuffers[0].mData)[i] = ((float*)audio->mBuffers[1].mData)[i] = 0;
        }
    }];
}

#pragma mark Authentication Callback
-(void)afterAuth:(FAuthData *) aData {
    
    self.userID = audUser.userID;
    NSLog(@"%@", self.userID);
    
    // Set up geo
    self.geo = [AUDGeo sharedInstance];
    self.firebase = [AUDFirebase sharedInstance].firebase;
    self.geo.recordingsRef = [self.firebase childByAppendingPath:@"recordings"];
    self.geo.geofireRef = [self.firebase childByAppendingPath:@"geofire"];
    self.geo.geoFire = [[GeoFire alloc] initWithFirebaseRef:self.geo.geofireRef];
    [self.geo geoInit];
    
    // Set up s3
    self.parse = [AUDParse sharedInstance];
    self.parse.core = self;

}




#pragma mark Audio Methods

-(void) recorderInit{
    self.recordingController = [[AEAudioController alloc]
                                initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription]
                                inputEnabled:YES];
    
    NSError *errorRecorderSetup = NULL;
    BOOL result = [[self recordingController] start:&errorRecorderSetup];
    if ( !result ) {
        NSLog(@"Error starting recording engine: %@", errorRecorderSetup.localizedDescription);
    }
}

-(void) destroyRecorder{
    self.recordingController = nil;
}

-(void) startRecording {
    if(!self.isRecording){
        [self recorderInit];
        self.isRecording = YES;
        self.recorder = [[AERecorder alloc] initWithAudioController:_recordingController];
        NSString *filePath = [documentsFolder stringByAppendingPathComponent:@"Recording.m4a"];
        // Start the recording process
        NSError *error = NULL;
        if ( ![_recorder beginRecordingToFileAtPath:filePath
                                           fileType:kAudioFileM4AType
                                              error:&error] ) {
            // Report error
            return;
        }
        
        [_recordingController addInputReceiver:_recorder];
    }
    
    recordingTimer = [NSTimer scheduledTimerWithTimeInterval:60.0
                                                      target:self
                                                    selector:@selector(endRecording)
                                                    userInfo:nil
                                                     repeats:NO];
}

- (void)endRecording {
    NSLog(@"entered endrecording");
    if (recordingTimer.valid) [recordingTimer invalidate];
    
    if (self.isRecording) {
        
        [_recordingController removeInputReceiver:_recorder];
        [_recordingController removeOutputReceiver:_recorder];
        [_recorder finishRecording];
        self.recorder = nil;
        
        //NSLog(@"about to do dis alert view");
        
        replayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [replayButton addTarget:self action:@selector(replayPress:) forControlEvents:UIControlEventTouchUpInside];
        [replayButton setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
        [replayButton setTitle:@"replay" forState:UIControlStateNormal];
        replayButton.frame = CGRectMake(0,0,80,80);
        
        NSLog(@"we make it to the middle of endrecording");
        
        DLAVAlertView *alertViewStopRecording = [[DLAVAlertView alloc]initWithTitle:@"Sign Your Audity" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Upload", nil];
        alertViewStopRecording.alertViewStyle=DLAVAlertViewStylePlainTextInput;
        [alertViewStopRecording textFieldAtIndex:0].delegate = self.vc;
        [alertViewStopRecording show];
        
        /* UIImageView *content = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Focus.png"]];
         content.frame = CGRectMake(0,0,80,80);
         alertViewStopRecording.contentView = content;
         */
        
        alertViewStopRecording.contentView = replayButton;
        
        self.isRecording = NO;
        [self destroyRecorder];
    }
}

-(void)endResponseWithDelegate:(UIViewController *)vc{
    if (recordingTimer.valid) [recordingTimer invalidate];
    
    [_recordingController removeInputReceiver:_recorder];
    [_recordingController removeOutputReceiver:_recorder];
    [_recorder finishRecording];
    self.recorder = nil;
    
    audVC = (AUDActivityViewController *)vc;
    
    replayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [replayButton addTarget:audVC action:@selector(replayPress:) forControlEvents:UIControlEventTouchUpInside];
    [replayButton setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
    [replayButton setTitle:@"replay" forState:UIControlStateNormal];
    replayButton.frame = CGRectMake(0,0,80,80);
    
    DLAVAlertView *alertViewStopRecording = [[DLAVAlertView alloc]initWithTitle:@"Sign Your Response" message:nil delegate:vc cancelButtonTitle:@"Cancel" otherButtonTitles:@"Upload", nil];
    alertViewStopRecording.alertViewStyle=DLAVAlertViewStylePlainTextInput;
    [alertViewStopRecording textFieldAtIndex:0].delegate = (AUDActivityViewController *)vc;
    //    alertViewStopRecording.textField
    [alertViewStopRecording show];
    
    alertViewStopRecording.contentView = replayButton;
}

-(void)unmute{
    [audioOut setChannelIsMuted:NO];
}

-(void)mute{
    [audioOut setChannelIsMuted:YES];
}









#pragma mark Location Methods

-(void) centerMap:(CLLocation *)loc{
    [self.vc changeMapCenterWithLocation:loc];
//    [self.vc moveAudityToLocation:loc forKey:@"You"];
}







-(void) uploadNewAudity:(NSURL *)file withKey:(NSString *)key andSignature:(NSString *)signature{
    tempKey = [NSString stringWithString:key];
    NSString *filename = [key stringByAppendingString:@".m4a"];
    [self.parse uploadFile:file withFilename:filename andSignature:signature];
}

-(void) uploadNewAudityResponse:(NSURL *)file withKey:(NSString *)key andSignature:(NSString *)signature forAudity:(NSString *) audityKey {
    tempKey = [NSString stringWithString:key];
    NSString *filename = [key stringByAppendingString:@".m4a"];
    [self.parse uploadResponse:file withFilename:filename andSignature:signature forAudity:audityKey];
}

-(void) addLocAfterUploadWithSignature:(NSString *)signature {
    [self.geo addLoc:tempKey bySignature:signature];
    tempKey = nil;
    self.isRecording = NO;
}

-(void)addResponseToViewAfterUploadWithSignature:(NSString *)signature{
    [audVC addResponseToAudityWithSignature:signature andKey:tempKey];
    tempKey = nil;
    self.isRecording = NO;
}

//returns a scale factor between 1.0 (furthest) and 0.0 (nearest)
-(float) getScaleFactorFromDistance:(float)distance{
    float maxRadius = MAXRADIUS; //this max radius should be declared elsewhere. Right now it is 600m elsewhere
    float scale = logf(distance)/logf(maxRadius);
    if(scale > 1.0) scale = 1.0; //make sure we don't go below 100%
    if(scale < 0.0) scale = 0.01;
    return scale;
}

-(bool) isInFocusMode{
    NSArray *keys = [self.audityManager allKeys];
    
    for (NSString *key in keys){
        Audity *audity = [self.audityManager audities][key];
        
        if(audity && audity.downloaded){
            if(audity.focused){
    //            NSLog(@"We are in focus mode");
                return true;
            }
        }
    }
    return false;
}

-(long) getTotalNumLikes{
    NSArray *keys = [self.audityManager allKeys];
    long num_likes = 0;
    
    for (NSString *key in keys){
        Audity *audity = [self.audityManager audities][key];
        
        if(audity && audity.downloaded){
            num_likes += audity.likes;
        }
    }
    return num_likes;
}










#pragma mark Filtering Methods

-(void) setFilterParametersForReverb:(AEAudioUnitFilter *)reverb withScaleFactor:(float)scl{

    float maxWetness = 100.0;
    
    AudioUnitSetParameter(reverb.audioUnit,
                          kReverb2Param_DryWetMix,
                          kAudioUnitScope_Global,
                          0,
                          maxWetness * scl,
                          0);
}

-(void) setFilterParametersForLP:(AEAudioUnitFilter *)lp withScaleFactor:(float)scl{
    
    float maxCutoff = 20000; //20kHz max cutoff
    
    AudioUnitSetParameter(lp.audioUnit,
                          kLowPassParam_CutoffFrequency,
                          kAudioUnitScope_Global,
                          0,
                          maxCutoff * (1.0 - scl),
                          0);
}

-(void) setFilterParametersForLP:(AEAudioUnitFilter *)lp withFocus:(BOOL)focus{
//    NSLog(@"made it all the way to focused lp assignment, assignment is %d", focus);
    float cutoff = 0.0;
    if(focus) cutoff = 20000;
    else cutoff = 100;
    
    AudioUnitSetParameter(lp.audioUnit,
                          kLowPassParam_CutoffFrequency,
                          kAudioUnitScope_Global,
                          0,
                          cutoff,
                          0);
}

-(void) setVolumeForFP:(AEAudioFilePlayer *)fp withScaleFactor:(float)scl andLikes:(int)likes andBackFrontScaling:(float)bfs{
    int total_likes = [self getTotalNumLikes];
    float volume = 0.5 + (float)likes/(float)total_likes; //set the base volume based on likes
    if (total_likes == 0) volume = 0.75;
    if(volume > 1.0) volume = 1.0;
    volume = volume * .3 + volume * (bfs) * .7; // scale volume based on back/front position
    volume = volume - (scl * volume); //scale volume based on distance
    if(volume <= 0.0) volume = 0.0;
    //NSLog(@"volume being set to %f because it has %d likes and %f scale factor", volume, likes, scl);
    if(volume == NAN) volume = 0.0;
    [fp setVolume:volume];
}

-(float) getPanFromBearing:(float) bearing{
    float pan = 0.0;
    bool neg = false;
    if(bearing < 0) neg = true; //left or right?
    
    float bear_abs = fabs(fabs(bearing/M_PI) - 0.5);
    pan = 1.0 - (2 * bear_abs);
    
    if(neg) pan = -pan;
    return pan;
}

double DegreesToRadians(double degrees) {return degrees * M_PI / 180;};
double RadiansToDegrees(double radians) {return radians * 180/M_PI;};

-(void) setAllAudioParametersForAudityWithKey:(NSString *)key{
    Audity *audity = [self.audityManager audities][key];
    
    if(audity && audity.downloaded){
        AEAudioFilePlayer *fp = audity.filePlayer;
        CLLocation *AudLoc = audity.location;
        CLLocation *SelfLoc = self.geo.currentLoc;
        long num_likes = audity.likes;
        
        //gotta get that theta
        float lat1 = DegreesToRadians(SelfLoc.coordinate.latitude);
        float lon1 = DegreesToRadians(SelfLoc.coordinate.longitude);
            
        float lat2 = DegreesToRadians(AudLoc.coordinate.latitude);
        float lon2 = DegreesToRadians(AudLoc.coordinate.longitude);
            
        float dLon = lon2 - lon1;
        
        float y = sin(dLon) * cos(lat2);
        float x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        float radiansBearing = atan2(y, x);
        float distance = [AudLoc distanceFromLocation:SelfLoc];
        
        float scl = [self getScaleFactorFromDistance:distance]; // scale based on log(distance)
        
        //Get CLLocationDirection for heading
        double heading = self.geo.currentHeading;
        //Convert heading to radians
        heading = DegreesToRadians(heading);
        radiansBearing = radiansBearing + M_PI;
        
        double trueBearing = heading - radiansBearing;
        double backFrontVolumeScale = fabs(1.0 - (fabs(trueBearing + M_PI)) / M_PI); //how behind of you is the thing?
        
        
        //set pan based on theta
        float pan = [self getPanFromBearing:trueBearing];
        [fp setPan:pan];
        
        AEAudioUnitFilter *reverb = audity.reverb;
        AEAudioUnitFilter *lp = audity.lp;
        
        if([self isInFocusMode] && !self.muteAudities && !self.muteSetting){
            BOOL focus = audity.focused;
            if(focus){
//                NSLog(@"%f radiansBearing", radiansBearing);
//                NSLog(@"%f trueBearing", trueBearing); //if truebearing is
//                NSLog(@"%f backFromtVolumeScale", backFrontVolumeScale);
                //NSLog(@"The scale factor for distance %f is %f", distance, scl);
                //NSLog(@"The bearing is %fpi which gives real pan of %f and final pan of %f", radiansBearing/3.14159, real_pan, pan);
                [fp setVolume:(0.8 - (scl * 0.5))]; //in focus, make it a bit louder
                [self setVolumeForFP:fp withScaleFactor:scl andLikes:num_likes andBackFrontScaling:backFrontVolumeScale];
            }else{
                [fp setVolume:(0.3 - (scl * 0.5))]; //out of focus, make it a bit softer
            }
            [self setFilterParametersForLP:lp withFocus: focus];
            [self setFilterParametersForReverb:reverb withScaleFactor:scl];
        }else if (!self.muteAudities && !self.muteSetting){
            [self setVolumeForFP:fp withScaleFactor:scl andLikes:num_likes andBackFrontScaling:backFrontVolumeScale];
            [self setFilterParametersForLP:lp withScaleFactor:scl];
            [self setFilterParametersForReverb:reverb withScaleFactor:scl];
        }else if (self.muteAudities || self.muteSetting){
            [fp setVolume:0];
        }
    }
}

-(void) setAllAudioParameters {
    NSArray *keys = [self.audityManager allKeys];
    
    for (NSString *key in keys){
        [self setAllAudioParametersForAudityWithKey:key];
    }
}









#pragma mark Play/Stop Audio

-(void) playRecorded:(NSURL *)file withButton:(UIButton *)button{
    //NSLog(@"time to play this response");
    NSError *errorFilePlayer = NULL;
    
    self.recordedPlayer = [AEAudioFilePlayer audioFilePlayerWithURL:file audioController:[self audioController] error:&errorFilePlayer];
    [self.recordedPlayer setVolume:0.8];
    [self.recordedPlayer setLoop:NO];
    self.recordedPlayer.removeUponFinish = YES;
    
    __weak UIButton *replayButtonWeak = replayButton;
    __weak MHCore *weakSelf = self;
    if (button) {
        replayButtonWeak = button;
    }
    
    self.recordedPlayer.completionBlock = ^ () {
        weakSelf.replaying = NO;
        [replayButtonWeak setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
    };
    
    if(self.recordedPlayer)[self.audioController addChannels:@[self.recordedPlayer]];
    else NSLog(@"could not initialize fileplayer, it was nil or null or something");
}

-(void) playResponse:(NSURL *)file {
    //NSLog(@"time to play this response");
    NSError *errorFilePlayer = NULL;
    
    AEAudioFilePlayer *filePlayer = [AEAudioFilePlayer audioFilePlayerWithURL:file audioController:[self audioController] error:&errorFilePlayer];
    [filePlayer setVolume:0.8];
    [filePlayer setLoop:NO];
    filePlayer.removeUponFinish = YES;
    
    if(filePlayer)[self.audioController addChannels:@[filePlayer]];
    else NSLog(@"could not initialize fileplayer, it was nil or null or something");
}

-(void) playAudio:(NSURL *)file withKey:(NSString *)key {
    // Play audio
    Audity *audity = [self.audityManager audities][key];

    if(audity && !audity.filePlayer){
//        NSLog(@" play %@ ", file);
        NSError *errorFilePlayer = NULL;

        AEAudioFilePlayer *filePlayer = [AEAudioFilePlayer audioFilePlayerWithURL:file audioController:[self audioController] error:&errorFilePlayer];
        [filePlayer setVolume:0];
        [filePlayer setLoop:YES];
        
        [self.audioController addChannels:@[filePlayer]];
        
        AudioComponentDescription desc = AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple,
                                                                         kAudioUnitType_Effect,
                                                                         kAudioUnitSubType_Reverb2);
        
        NSError *error = NULL;
        AEAudioUnitFilter *reverb = [[AEAudioUnitFilter alloc] initWithComponentDescription:desc audioController:self.audioController error:&error];
        
        desc = AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple,
                                               kAudioUnitType_Effect,
                                               kAudioUnitSubType_LowPassFilter);
        
        AEAudioUnitFilter *lp = [[AEAudioUnitFilter alloc] initWithComponentDescription:desc audioController:self.audioController error:&error];
        

        // Save file player and filters to the audities object
        key = [key stringByDeletingPathExtension];
        audity.filePlayer = filePlayer;
        audity.reverb = reverb;
        audity.lp = lp;
        
        [self setAllAudioParametersForAudityWithKey:key];
        
        [self.audioController addFilter:reverb toChannel:filePlayer];
        [self.audioController addFilter:lp toChannel:filePlayer];

        [self.vc setPlayingColorForAnnotation:audity.annotation];
    }
    
    if(!self.firstSoundPlayed)[self.vc stopSpinner];
    self.firstSoundPlayed = YES;
}

-(void) stopAudioWithKey:(NSString *)key {
    NSLog(@"stopping %@", key);
    Audity *audity = [self.audityManager audities][key];

    if(audity && audity.filePlayer) {
        AEAudioFilePlayer *filePlayer = audity.filePlayer;
        [filePlayer setVolume:0.0];
        if(filePlayer) {
            [self.audioController removeChannels:@[filePlayer]];
            [self.audityManager removeAudityWithKey:key];
        }
        
        [self.vc setNotPlayingColorForAnnotation:audity.annotation];
    }
}

-(void) muteAuditiesWithBool:(BOOL)val {
    self.muteAudities = val;
    [self setAllAudioParameters];
}








#pragma mark View Callbacks

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    UITextField *textfield = [alertView textFieldAtIndex:0];
    if(buttonIndex != [alertView cancelButtonIndex]) {
        NSString *signature = textfield.text;
        if (!signature ||[signature isEqualToString:@""]) {
            signature = [defaults stringForKey:@"defaultSig"];
            if (!signature ||[signature isEqualToString:@""]) {
                signature = @"anonymous";
                [defaults setValue:@"anonymous" forKey:@"defaultSig"];
            }
        }
        
        NSURL *file = [NSURL fileURLWithPath:[documentsFolder stringByAppendingPathComponent:@"Recording.m4a"]];
        NSString *uuid = [[NSUUID UUID] UUIDString];
        [self uploadNewAudity:file withKey:uuid andSignature:signature];
    }
    
    [self.vc resetNewAudityButton];
    
    [self muteAuditiesWithBool:NO]; // Set mute and trigger mute
}

- (IBAction)replayPress:(id)sender {
    NSLog(@"replay pressed");
    if (!self.replaying) {
        self.replaying = YES;
        [replayButton setImage:[UIImage imageNamed:@"Pause.png"] forState:UIControlStateNormal];
        NSURL *file = [NSURL fileURLWithPath:[documentsFolder stringByAppendingPathComponent:@"Recording.m4a"]];
        [self playRecorded:file withButton:nil];
    } else {
        self.recordedPlayer.channelIsPlaying = !self.recordedPlayer.channelIsPlaying;
        if(self.recordedPlayer.channelIsPlaying) {
            [replayButton setImage:[UIImage imageNamed:@"Pause.png"] forState:UIControlStateNormal];
        } else {
            [replayButton setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
        }
    }
}

@end