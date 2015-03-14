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

#define SRATE 24000
#define FRAMESIZE 512
#define NUM_CHANNELS 2


@implementation MHCore {
    long framesize;
    AEBlockChannel *audioOut;
    NSString *documentsFolder;
    NSUserDefaults *defaults;
    NSString *tempKey;
}

+ (id)sharedInstance {
    static MHCore *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(void) coreInit {
//    stk::Stk::setRawwavePath([[[NSBundle mainBundle] pathForResource:@"rawwaves" ofType:@"bundle"] UTF8String]);
    self.isRecording = NO;
    
    self.audities = @{};
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"keys" ofType:@"plist"];
    self.apiKeys = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    
    // Set up backend
    self.geo = [AUDGeo sharedInstance];
    self.firebase = [self.geo fireRef];
    self.s3 = [AUDS3 sharedInstance];
    Firebase *userRef = [self.firebase childByAppendingPath:@"users"];
    self.s3.core = self;
    
    // Find user ID in NSUserDefaults
    defaults = [NSUserDefaults standardUserDefaults];
    self.userID = [defaults stringForKey:@"userId"];
    
    if (!self.userID) {
        // Generate ID if there is none
        self.userID = [[NSUUID UUID] UUIDString];
        // Store ID in NSUserDefaults
        [defaults setValue:self.userID forKey:@"userId"];
        
        // Store ID in Firebase
        Firebase *thisUser = [userRef childByAppendingPath:self.userID];
        [thisUser setValue:@{@"userId":self.userID}];
    }

    
    // Set up audio controller
    self.audioController = [[AEAudioController alloc]
                            initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription]
                            inputEnabled:YES];
    
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

-(void) centerMap:(CLLocation *)loc{
    [self.vc changeMapCenterWithLocation:loc];
//    [self.vc moveAudityToLocation:loc forKey:@"You"];
}

-(void)unmute{
    [audioOut setChannelIsMuted:NO];
}

-(void)mute{
    [audioOut setChannelIsMuted:YES];
}

-(void) startRecording {
    if(!self.isRecording){
        self.isRecording = YES;
        self.recorder = [[AERecorder alloc] initWithAudioController:_audioController];
        NSString *filePath = [documentsFolder stringByAppendingPathComponent:@"Recording.aiff"];
        // Start the recording process
        NSError *error = NULL;
        if ( ![_recorder beginRecordingToFileAtPath:filePath
                                           fileType:kAudioFileAIFFType
                                              error:&error] ) {
            // Report error
            return;
        }
        
        [_audioController addInputReceiver:_recorder];
    }
}

- (void)endRecording {
    [_audioController removeInputReceiver:_recorder];
    [_audioController removeOutputReceiver:_recorder];
    [_recorder finishRecording];
    self.recorder = nil;
    
    UIAlertView *alertViewStopRecording = [[UIAlertView alloc]initWithTitle:@"Sign Your Audity" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Upload", nil];
    alertViewStopRecording.alertViewStyle=UIAlertViewStylePlainTextInput;
    [alertViewStopRecording show];
}

-(void) uploadNewAudity:(NSURL *)file withKey:(NSString *)key andSignature:(NSString *)signature{
    tempKey = [NSString stringWithString:key];
    key = [key stringByAppendingString:@".aiff"];
    [self.s3 uploadFile:file withKey:key andSignature:signature];
}

-(void) addLocAfterUploadWithSignature:(NSString *)signature {
    [self.geo addLoc:tempKey bySignature:signature];
    tempKey = nil;
    self.isRecording = NO;
}


//returns a scale factor between 1.0 (furthest) and 0.0 (nearest)
-(float) getScaleFactorFromDistance:(float)distance{
    float maxRadius = MAXRADIUS; //this max radius should be declared elsewhere. Right now it is 600m elsewhere
    float scale = logf(distance)/logf(maxRadius);
    if(scale > 1.0) scale = 1.0; //make sure we don't go below 100%
    return scale;
}

-(bool) isInFocusMode{
    NSArray *keys = [self.audities allKeys];
    
    for (NSString *key in keys){
        if(![self.audities[key] isEqual:@"taken"]){
            if([[[self.audities objectForKey:key] objectForKey:@"focus"] boolValue]){
    //            NSLog(@"We are in focus mode");
                return true;
            }
        }
    }
    return false;
}

-(void) setFilterParametersForReverb:(AEAudioUnitFilter *)reverb withDistance:(float)distance{
    
    float scl = [self getScaleFactorFromDistance:distance];
    float maxWetness = 100.0;
    
    AudioUnitSetParameter(reverb.audioUnit,
                          kReverb2Param_DryWetMix,
                          kAudioUnitScope_Global,
                          0,
                          maxWetness * scl,
                          0);
}

-(void) setFilterParametersForLP:(AEAudioUnitFilter *)lp withDistance:(float)distance{
    
    float scl = [self getScaleFactorFromDistance:distance];
    float maxCutoff = 20000; //20kHz max cutoff
    
    AudioUnitSetParameter(lp.audioUnit,
                          kLowPassParam_CutoffFrequency,
                          kAudioUnitScope_Global,
                          0,
                          maxCutoff * scl,
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

-(float) getPanFromBearing:(float) bearing{
    float pan = 0.0;
    bool neg = false;
    if(bearing < 0) neg = true; //left or right?
    
    float bear_abs = fabs(fabs(bearing/3.14159) - 0.5);
    pan = 1.0 - (2 * bear_abs);
    
    if(neg) pan = -pan;
    return pan;
}

double DegreesToRadians(double degrees) {return degrees * M_PI / 180;};
double RadiansToDegrees(double radians) {return radians * 180/M_PI;};

-(void) setAllAudioParametersForAudityWithKey:(NSString *)key{
    if(![self.audities[key]  isEqual: @"taken"]) {
        AEAudioFilePlayer *fp = [[self.audities objectForKey:key] valueForKey:@"filePlayer"];
        CLLocation *AudLoc = [[self.audities objectForKey:key] valueForKey:@"location"];
        CLLocation *SelfLoc = self.geo.currentLoc;
        
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
        
        //set pan based on theta
        float real_pan = [self getPanFromBearing:radiansBearing];
        //float pan = ((1.0 - (scl)) * 0.5) + ((scl) * real_pan); // the closer the sound is (lower scl) the less pan will affect it.
        float pan = real_pan;
        [fp setPan:pan];
        
        AEAudioUnitFilter *reverb = [[self.audities objectForKey:key] valueForKey:@"reverb"];
        AEAudioUnitFilter *lp = [[self.audities objectForKey:key] valueForKey:@"lp"];
        
        //are we in focus mode? If so, call focus mode functions
        if([self isInFocusMode]){
            BOOL focus = [[[self.audities objectForKey:key] objectForKey:@"focus"] boolValue];
            if(focus){
                //NSLog(@"The scale factor for distance %f is %f", distance, scl);
                //NSLog(@"The bearing is %fpi which gives real pan of %f and final pan of %f", radiansBearing/3.14159, real_pan, pan);
                [fp setVolume:(0.6 - (scl * 0.5))]; //in focus, make it a bit louder
            }else{
                [fp setVolume:(0.3 - (scl * 0.5))]; //out of focus, make it a bit softer
            }
            [self setFilterParametersForLP:lp withFocus: focus];
            [self setFilterParametersForReverb:reverb withDistance:distance];
        }else{
            [fp setVolume:(0.5 - (scl * 0.5))]; //set volume solely based on distance
            [self setFilterParametersForLP:lp withDistance:distance];
            [self setFilterParametersForReverb:reverb withDistance:distance];
        }
    }
}

-(void) playAudio:(NSURL *)file withKey:(NSString *)key {
    // Play audio
    if(!self.audities[key][@"filePlayer"] && !self.audities[key]){
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
        [[self.audities objectForKey:key] setValue:filePlayer forKey:@"filePlayer"];
        [[self.audities objectForKey:key] setValue:reverb forKey:@"reverb"];
        [[self.audities objectForKey:key] setValue:lp forKey:@"lp"];
        
        
        [self setAllAudioParametersForAudityWithKey:key];
        
        
        [self.audioController addFilter:reverb toChannel:filePlayer];
        [self.audioController addFilter:lp toChannel:filePlayer];

        
    }
}

-(void) stopAudioWithKey:(NSString *)key {
    NSLog(@"stopping %@", key);
    if(self.audities[key] && ![self.audities[key] isEqual:@"taken"]) {
        AEAudioFilePlayer *filePlayer = self.audities[key][@"filePlayer"];
        [filePlayer setVolume:0.0];
        if(filePlayer) {
            [self.audioController removeChannels:@[filePlayer]];
            [self.audities removeObjectForKey:key];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    UITextField *textfield = [alertView textFieldAtIndex:0];
    if(buttonIndex != [alertView cancelButtonIndex]) {
        NSString *signature = textfield.text;
        if (!signature) signature = @"anonymous";
        if ([signature isEqualToString:@""]) signature = @"anonymous";
        
        NSURL *file = [NSURL fileURLWithPath:[documentsFolder stringByAppendingPathComponent:@"Recording.aiff"]];
        NSString *uuid = [[NSUUID UUID] UUIDString];
        [self uploadNewAudity:file withKey:uuid andSignature:signature];
    } else {
        self.isRecording = NO;
    }
}

@end