//
//  AUDParse.m
//  Audity
//
//  Created by Matthew Horton on 6/21/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDParse.h"

@implementation AUDParse

+ (id)sharedInstance{
    static AUDParse *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(void) uploadFile:(NSURL *)file withFilename:(NSString *)filename andSignature:(NSString *)signature {

    PFObject *fileObject = [PFObject objectWithClassName:@"Audity"];
    PFFile *parseFile = [PFFile fileWithName:filename contentsAtPath:[file path]];
    fileObject[@"audio"] = parseFile;
    fileObject[@"key"] = [filename stringByDeletingPathExtension];
    
    [fileObject saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *documentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
                                     objectAtIndex:0];
        [fileManager removeItemAtPath:[documentsFolder stringByAppendingPathComponent:@"Recording.aiff"] error:nil];
        
        [self.core addLocAfterUploadWithSignature:signature];
        
    }];
}

-(void) uploadResponse:(NSURL *)file withFilename:(NSString *)filename andSignature:(NSString *)signature forAudity:(NSString *)audityKey {
    
    NSLog(@"Uploading");
    PFObject *fileObject = [PFObject objectWithClassName:@"Response"];
    NSLog(@"%@ filename | %@ file", filename, file);
    PFFile *parseFile = [PFFile fileWithName:filename contentsAtPath:[file path]];
    fileObject[@"audio"] = parseFile;
    fileObject[@"key"] = [filename stringByDeletingPathExtension];
    fileObject[@"audity"] = audityKey;
    
    [fileObject saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *documentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
                                     objectAtIndex:0];
        [fileManager removeItemAtPath:[documentsFolder stringByAppendingPathComponent:@"Recording.aiff"] error:nil];
        
        [self.core addResponseToViewAfterUploadWithSignature:signature];
        
    }];
    
    
    
}

-(void) downloadFileWithFilename:(NSString *)filename isResponse:(BOOL)response {

    // Construct the NSURL for the download location.
    NSString *downloadingFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    NSURL *downloadingFileURL = [NSURL URLWithString:downloadingFilePath];
    [[NSFileManager defaultManager] removeItemAtPath:downloadingFilePath error:NULL];
    
    // Query for object
    NSString *key = [filename stringByDeletingPathExtension];
    
    __weak AUDParse *weakSelf = self;
    
    PFQuery *query;
    if(!response) {
         query = [PFQuery queryWithClassName:@"Audity"];
    } else {
        query = [PFQuery queryWithClassName:@"Response"];
    }
    
    [query whereKey:@"key" equalTo:key];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            PFObject *object = objects[0];
            
            // Download audio
            PFFile *file = object[@"audio"];
            [file getDataInBackgroundWithBlock: ^(NSData *data, NSError *error) {
                [data writeToFile:downloadingFilePath atomically:NO];
                
                if(!response)[weakSelf.core playAudio:downloadingFileURL withKey:key];

            } progressBlock:^(int percentDone) {
                
            }];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

@end
