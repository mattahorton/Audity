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
#import "AWSS3TransferManager.h"

#define SRATE 24000
#define FRAMESIZE 512
#define NUM_CHANNELS 2


@implementation MHCore {
    long framesize;
    AEBlockChannel *audioOut;
    AEAudioFilePlayer *filePlayer;
    NSString *documentsFolder;
    NSString *filePath;
    NSURL *file;
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
    
    self.geo = [AUDGeo sharedInstance];
    self.firebase = [self.geo fireRef];
    
    file = [[NSBundle mainBundle] URLForResource:@"alley" withExtension:@"m4a"];
    NSURL *postcards = [[NSBundle mainBundle] URLForResource:@"Postcards" withExtension:@"mp3"];
    NSURL *ethan = [[NSBundle mainBundle] URLForResource:@"rightRecord" withExtension:@"wav"];
    NSLog(@"%@ file",file);
    
    AWSCognitoCredentialsProvider *credentialsProvider = [AWSCognitoCredentialsProvider
                                                          credentialsWithRegionType:AWSRegionUSEast1
                                                          identityPoolId:@"us-east-1:933227fb-7780-48c8-9250-c0fa1c1c1459"];
    
    AWSServiceConfiguration *configuration = [AWSServiceConfiguration configurationWithRegion:AWSRegionUSEast1
                                                                          credentialsProvider:credentialsProvider];
    
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    
    AWSS3TransferManager *transferManager = [[AWSS3TransferManager alloc] initWithConfiguration:configuration identifier:@"S3"];
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = @"audity";
    uploadRequest.key = @"Postcards.mp3";
    uploadRequest.body = postcards;
    
    [[transferManager upload:uploadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor]
                                                       withBlock:^id(BFTask *task) {
                                                           if (task.error) {
                                                               if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                                                                   switch (task.error.code) {
                                                                       case AWSS3TransferManagerErrorCancelled:
                                                                       case AWSS3TransferManagerErrorPaused:
                                                                           break;
                                                                           
                                                                       default:
                                                                           NSLog(@"Error: %@", task.error);
                                                                           break;
                                                                   }
                                                               } else {
                                                                   // Unknown error.
                                                                   NSLog(@"Error: %@", task.error);
                                                               }
                                                           }
                                                           
                                                           if (task.result) {
                                                               AWSS3TransferManagerUploadOutput *uploadOutput = task.result;
                                                               // The file uploaded successfully.
                                                               NSLog(@"The file uploaded successfully.");
                                                           }
                                                           return nil;
                                                       }];
    
    self.audioController = [[AEAudioController alloc]
                            initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription]
                            inputEnabled:NO];
    
    NSError *errorAudioSetup = NULL;
    BOOL result = [[self audioController] start:&errorAudioSetup];
    if ( !result ) {
        NSLog(@"Error starting audio engine: %@", errorAudioSetup.localizedDescription);
    }
    
    NSTimeInterval dur = self.audioController.currentBufferDuration;
    
    framesize = AEConvertSecondsToFrames(self.audioController, dur);

    
    audioOut = [AEBlockChannel channelWithBlock:^(const AudioTimeStamp  *time,
                                                           UInt32 frames,
                                                           AudioBufferList *audio) {
        
        for ( int i=0; i<frames; i++ ) {
            ((float*)audio->mBuffers[0].mData)[i] = ((float*)audio->mBuffers[1].mData)[i] = 0;
        }
    }];
    
    NSError *errorFilePlayer = NULL;
    
    filePlayer = [AEAudioFilePlayer audioFilePlayerWithURL:file audioController:[self audioController] error:&errorFilePlayer];
    [filePlayer setPan:-1.0];
    [filePlayer setVolume:0.1];
    [filePlayer setLoop:YES];
    
    AEAudioFilePlayer *postcardsPlayer = [AEAudioFilePlayer audioFilePlayerWithURL:postcards audioController:self.audioController error:NULL];
    
    [postcardsPlayer setPan:0.0];
    [postcardsPlayer setVolume:0.9];
    [postcardsPlayer setLoop:YES];
    
    AEAudioFilePlayer *ethanPlayer = [AEAudioFilePlayer audioFilePlayerWithURL:ethan audioController:self.audioController error:NULL];
    [ethanPlayer setPan:1.0];
    [ethanPlayer setVolume:0.1];
    [ethanPlayer setLoop:YES];
    
    [audioOut setChannelIsMuted:YES];
    [self.audioController addChannels:@[filePlayer,postcardsPlayer,ethanPlayer]];
    
}

-(void)unmute{
    [audioOut setChannelIsMuted:NO];
}

-(void)mute{
    [audioOut setChannelIsMuted:YES];
}

-(NSString *) uploadNewAudity {
    return @"";
}

@end