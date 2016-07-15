//
//  AUDFirebase.m
//  Audity
//
//  Created by Matthew Horton on 6/23/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDFirebase.h"

@implementation AUDFirebase

+ (id)sharedInstance{
    static AUDFirebase *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(instancetype) init {
    self = [super init];
    if(self) {
        self.firebase = [[FIRDatabase database] reference];
    }
    
    return self;
}

@end
