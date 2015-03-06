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

#define SRATE 24000
#define FRAMESIZE 512
#define NUM_CHANNELS 2


@implementation MHCore {
    long framesize;
    AEBlockChannel *audioOut;
    NSString *documentsFolder;
    NSUserDefaults *defaults;
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
    
    [NSTimer scheduledTimerWithTimeInterval:30.0
                                     target:self
                                   selector:@selector(endRecording)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)endRecording {
    [_audioController removeInputReceiver:_recorder];
    [_audioController removeOutputReceiver:_recorder];
    [_recorder finishRecording];
    self.recorder = nil;
    
    NSURL *file = [NSURL URLWithString:[documentsFolder stringByAppendingPathComponent:@"Recording.aiff"]];
    NSString *uuid = [[NSUUID UUID] UUIDString];
    [self uploadNewAudity:file withKey:uuid];
}

-(NSString *) uploadNewAudity:(NSURL *)file withKey:(NSString *)key {
    NSString *uuid = key;
    key = [key stringByAppendingString:@".aiff"];
    NSURL * s3url = [self.s3 uploadFile:file withKey:key];
    [self.geo addLoc:uuid];
    return [s3url absoluteString];
}

-(void) playAudio:(NSURL *)file withKey:(NSString *)key {
    // Play audio
    if(!self.audities[key][@"filePlayer"]){
        NSLog(@" play %@ ", file);
        NSError *errorFilePlayer = NULL;

        AEAudioFilePlayer *filePlayer = [AEAudioFilePlayer audioFilePlayerWithURL:file audioController:[self audioController] error:&errorFilePlayer];
        [filePlayer setPan:-1.0];
        [filePlayer setVolume:0.5];
        [filePlayer setLoop:YES];
        
        [[self.audities objectForKey:key] setValue:filePlayer forKey:@"filePlayer"];
        
        [self.audioController addChannels:@[filePlayer]];
    }
}

-(void) stopAudioWithKey:(NSString *)key {
    NSLog(@"stopping %@", key);
    AEAudioFilePlayer *filePlayer = self.audities[key][@"filePlayer"];
    [filePlayer setVolume:0.0];
    [self.audioController removeChannels:@[filePlayer]];
    [self.audities[key] removeObjectForKey:@"filePlayer"];
}

@end