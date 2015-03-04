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
}

-(instancetype)initWithViewController:(MHViewController *) viewController {
    self.vc = viewController;
    self.fromFile = NO;
    return self;
}

-(instancetype)init {
    return [[MHCore alloc] initWithViewController:nil];
}

-(void) coreInit {
//    stk::Stk::setRawwavePath([[[NSBundle mainBundle] pathForResource:@"rawwaves" ofType:@"bundle"] UTF8String]);
    
    // Set up backend
    self.geo = [AUDGeo sharedInstance];
    self.geo.core = self;
    self.firebase = [self.geo fireRef];
    self.s3 = [AUDS3 sharedInstance];

    
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
    
//    NSError *errorFilePlayer = NULL;
//    
//    filePlayer = [AEAudioFilePlayer audioFilePlayerWithURL:file audioController:[self audioController] error:&errorFilePlayer];
//    [filePlayer setPan:-1.0];
//    [filePlayer setVolume:0.1];
//    [filePlayer setLoop:YES];

    
}

-(void) centerMap:(CLLocation *)loc{
    [self.vc changeMapCenterWithLocation:loc];
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
    [self.geo addLoc:uuid];
    [self uploadNewAudity:file withKey:uuid];
}

-(NSString *) uploadNewAudity:(NSURL *)file withKey:(NSString *)key {
    key = [key stringByAppendingString:@".aiff"];
    NSURL * s3url = [self.s3 uploadFile:file withKey:key];
    return [s3url absoluteString];
}

@end