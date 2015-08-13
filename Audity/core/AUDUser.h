//
//  AUDUser.h
//  Audity
//
//  Created by Matthew Horton on 6/23/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>

@interface AUDUser : NSObject

@property (nonatomic,strong) Firebase *firebase;
@property (nonatomic,strong) Firebase *userRef;
@property (nonatomic,strong) NSString *userID;
@property (nonatomic,strong) FAuthData *authData;
@property (nonatomic) BOOL loggedIn;

+(id) sharedInstance;

-(void)authAnonWithTarget:(NSObject *)target andSelector:(SEL)selector;
-(void)authWithEmail:(NSString *)email password:(NSString *)pwd target:(NSObject *)target andSelector:(SEL)selector;

@end
