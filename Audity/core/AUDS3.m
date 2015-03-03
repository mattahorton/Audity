//
//  AUDS3.m
//  Audity
//
//  Created by Matthew Horton on 3/2/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDS3.h"

@implementation AUDS3

#pragma mark Singleton Methods

+ (id)sharedInstance {
    static AUDS3 *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)init {
    if (self = [super init]) {
        [self s3Init];
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

#pragma mark Initialization 

-(void) s3Init {
    
    _credentialsProvider = [AWSCognitoCredentialsProvider credentialsWithRegionType:AWSRegionUSEast1
                                                                    identityPoolId:@"us-east-1:933227fb-7780-48c8-9250-c0fa1c1c1459"];
    
    _configuration = [AWSServiceConfiguration configurationWithRegion:AWSRegionUSEast1
                                                                          credentialsProvider:_credentialsProvider];
    
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = _configuration;
    
    _transferManager = [[AWSS3TransferManager alloc] initWithConfiguration:_configuration identifier:@"S3"];
}

-(NSURL *) uploadFile:(NSURL *)file withKey:(NSString *)key {
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = @"audity";
    uploadRequest.key = key;
    uploadRequest.body = file;
    
    [[self.transferManager upload:uploadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor]
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
               NSLog(@"file uploaded successfully");
               
               NSFileManager *fileManager = [NSFileManager defaultManager];
               NSString *documentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
                                            objectAtIndex:0];
               [fileManager removeItemAtPath:[documentsFolder stringByAppendingPathComponent:@"Recording.aiff"] error:nil];
           }
           return nil;
       }];
    NSString *url = @"https://s3.amazonaws.com/audity/";
    url = [[url stringByAppendingString:key] stringByAppendingString:@".aiff"];
    return [NSURL URLWithString:url];
}

@end
