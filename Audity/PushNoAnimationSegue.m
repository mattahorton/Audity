
//
//  PushNoAnimationSegue.m
//  Audity
//
//  Created by Matthew Horton on 5/30/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "PushNoAnimationSegue.h"

@implementation PushNoAnimationSegue

-(void) perform{
    [self.sourceViewController presentViewController:self.destinationViewController animated:NO completion:nil];
}

@end