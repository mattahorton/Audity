//
//  AUDFirebase.h
//  Audity
//
//  Created by Matthew Horton on 6/23/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>

@interface AUDFirebase : NSObject

@property (nonatomic,strong) Firebase *firebase;

+(instancetype) sharedInstance;

@end
