//
//  AUDS3.h
//  Audity
//
//  Created by Matthew Horton on 3/2/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CognitoIdentity.h"
#import "AWSS3TransferManager.h"
#import "MHCore.h"

@class MHCore;

@interface AUDS3 : NSObject

@property (strong,nonatomic) AWSCognitoCredentialsProvider *credentialsProvider;
@property (strong,nonatomic) AWSServiceConfiguration *configuration;
@property (strong,nonatomic) AWSS3TransferManager *transferManager;
@property (strong,nonatomic) MHCore *core;
@property (nonatomic, strong) NSString *s3Secret;
@property (nonatomic, strong) NSString *awsAccessKey;

+ (id)sharedInstance;

-(void) uploadFile:(NSURL *)file withKey:(NSString *)key andSignature:(NSString *)signature;
-(void) uploadResponse:(NSURL *)file withKey:(NSString *)key andSignature:(NSString *)signature forAudity:(NSString *)audityKey;
-(NSURL *) downloadFileWithKey:(NSString *)key;

@end
