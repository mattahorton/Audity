//
//  AUDParse.h
//  Audity
//
//  Created by Matthew Horton on 6/21/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "MHCore.h"

@class MHCore;

@interface AUDParse : NSObject

@property (strong,nonatomic) MHCore *core;

+ (id)sharedInstance;

-(void) uploadFile:(NSURL *)file withFilename:(NSString *)filename andSignature:(NSString *)signature;
-(void) uploadResponse:(NSURL *)file withFilename:(NSString *)filename andSignature:(NSString *)signature forAudity:(NSString *)audityKey;
// Add callback?
-(void) downloadFileWithFilename:(NSString *)filename isResponse:(BOOL)response;


@end