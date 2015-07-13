//
//  Audity.m
//  Audity
//
//  Created by Matthew Horton on 7/12/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "Audity.h"

@implementation Audity

-(id)init {
    if(self = [super init]) {
        self.downloaded = NO;
        self.likes = 0;
    }
    return self;
}

@end
