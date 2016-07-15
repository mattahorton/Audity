//
//  AUDStorage.h
//  Audity
//
//  Created by Matthew Horton on 7/14/16.
//  Copyright © 2016 Matt Horton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MHCore.h"

@class MHCore;


@interface AUDStorage : NSObject

@property (strong, nonatomic) MHCore *core;
@property (strong, nonatomic) FIRStorage *storage;
@property (strong, nonatomic) FIRStorageReference *storageRef;

+ (id)sharedInstance;

-(void) uploadFile:(NSURL *)file withFilename:(NSString *)filename andSignature:(NSString *)signature;
-(void) uploadResponse:(NSURL *)file withFilename:(NSString *)filename andSignature:(NSString *)signature forAudity:(NSString *)audityKey;
// Add callback?
-(void) downloadFileWithFilename:(NSString *)filename isResponse:(BOOL)response;

@end
