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

@interface AUDS3 : NSObject

@property (strong,nonatomic) AWSCognitoCredentialsProvider *credentialsProvider;
@property (strong,nonatomic) AWSServiceConfiguration *configuration;
@property (strong,nonatomic) AWSS3TransferManager *transferManager;

+ (id)sharedInstance;

-(NSURL *) uploadFile:(NSURL *)file withKey:(NSString *)key;

@end
