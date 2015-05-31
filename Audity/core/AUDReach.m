//
//  AUDReach.m
//  Audity
//
//  Created by Matthew Horton on 5/30/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDReach.h"

@implementation AUDReach

+ (id)sharedInstance {
    static AUDReach *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(id) init {
    if (self = [super init]) {
        self.online = NO;
        self.reach = [Reachability reachabilityWithHostname:@"www.google.com"];
        
        __weak AUDReach *weakSelf = self;
        // Internet is reachable
        self.reach.reachableBlock = ^(Reachability*reach)
        {
            // Update the UI on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                //NSLog(@"Yayyy, we have the interwebs!");
                weakSelf.online = YES;
            });
        };
        
        // Internet is not reachable
        self.reach.unreachableBlock = ^(Reachability*reach)
        {
            // Update the UI on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                //NSLog(@"Someone broke the internet :(");
                weakSelf.online = NO;
            });
        };
        
        [self.reach startNotifier];
    }
    return self;
}


@end
