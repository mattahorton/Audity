//
//  AUDStorage.m
//  Audity
//
//  Created by Matthew Horton on 7/14/16.
//  Copyright © 2016 Matt Horton. All rights reserved.
//

#import "AUDStorage.h"

@implementation AUDStorage

+ (id)sharedInstance{
    static AUDStorage *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)init {
    if (self = [super init]) {
        self.storage = [FIRStorage storage];
        self.storageRef = [self.storage referenceForURL:@"gs://project-4975153547445793666.appspot.com"];
    }
    return self;
}

- (void) downloadFileWithFilename:(NSString *)filename isResponse:(BOOL)response {
    
    // Construct the NSURL for the download location.
    NSString *downloadingFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    NSURL *downloadingFileURL = [NSURL URLWithString:[@"file://" stringByAppendingString:downloadingFilePath]];
    [[NSFileManager defaultManager] removeItemAtPath:downloadingFilePath error:NULL];
    
    NSString *key = [filename stringByDeletingPathExtension];
    
    __weak AUDStorage *weakSelf = self;
    
    FIRStorageReference *ref;
    if(!response) {
        ref = [[self.storageRef child:@"recordings"] child:filename];
    } else {
        ref = [[self.storageRef child:@"responses"] child:filename];
    }
    
    NSLog(@"%@", downloadingFileURL);
    
    // Download to the local filesystem
    FIRStorageDownloadTask *downloadTask = [ref writeToFile:downloadingFileURL completion:^(NSURL *URL, NSError *error){
        if (error != nil) {
            // Uh-oh, an error occurred!
             NSLog(@"Error: %@ %@", error, [error userInfo]);
        } else {
            if(!response)[weakSelf.core playAudio:downloadingFileURL withKey:key];
        }
    }];
}

@end
