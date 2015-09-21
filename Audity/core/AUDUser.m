//
//  AUDUser.m
//  Audity
//
//  Created by Matthew Horton on 6/23/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDUser.h"
#import "AUDFirebase.h"
#import "UICKeychainStore.h"
#import "Secrets.h"

@implementation AUDUser

+(id) sharedInstance{
    static AUDUser *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(id)init {
    self = [super init];
    if(self) {
        self.firebase = [AUDFirebase sharedInstance].firebase;
        self.loggedIn = NO;
    }
    
    return self;
}

-(NSString *)findUserID {
    // Find user ID in keychain
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.mattahorton.Audity"];
    return [keychain stringForKey:@"userId"];

}

-(void)storeUserID: (NSString *)toStore {
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.mattahorton.Audity"];
    
    NSString *storeThisId = toStore;
    
    if(!storeThisId) {
        // Generate ID if there is none
        self.userID = [[NSUUID UUID] UUIDString];
        storeThisId = self.userID;
    }
    
    // Store ID in keychain
    [keychain setString:storeThisId forKey:@"userId"];
    
    // Store ID in Firebase
    Firebase *thisUser = [[self.userRef childByAppendingPath:storeThisId] childByAppendingPath:@"userId"];
    [thisUser setValue:storeThisId];
}

-(void)authAnonWithTarget:(NSObject *)target andSelector:(SEL)selector {
    
    __block FAuthData *aData;
    
    self.userID = [self findUserID];
    
    [self.firebase authAnonymouslyWithCompletionBlock:^(NSError *error, FAuthData *authData) {
        if (error) {
            //NSLog(@"Login Failed! %@", error);
            self.loggedIn = NO;
            
            aData = nil;
        } else {
            //NSLog(@"Login succeeded! %@", authData);
            self.loggedIn = YES;
            
            aData = authData;
            
            self.authData = aData;
            
            if(aData) {
                self.userRef = [self.firebase childByAppendingPath:@"users"];
                
                if (!self.userID) {
                    self.userID = self.authData.uid;
                    [self storeUserID:self.userID];
                }                
            }
            
            if([target respondsToSelector:selector]) {
                [target performSelector:selector withObject:aData];
            }
        }
    }];
}

-(void)authWithEmail:(NSString *)email password:(NSString *)pwd target:(NSObject *)target andSelector:(SEL)selector {
    
    __block FAuthData *aData;
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.mattahorton.Audity"];
    
    self.userID = [self findUserID];

    [self.firebase authUser:email password:pwd withCompletionBlock:^(NSError *error, FAuthData *authData) {
        if (error) {
            //NSLog(@"Login Failed! %@", error);
            self.loggedIn = NO;
            
            aData = nil;
        } else {
            //NSLog(@"Login succeeded! %@", authData);
            self.loggedIn = YES;
            
            aData = authData;
            
            self.authData = aData;
            
            if(aData) {
                self.userRef = [self.firebase childByAppendingPath:@"users"];
                
                if (!self.userID) {
                    self.userID = self.authData.uid;
                    [self storeUserID:self.userID];
                }
                
               
//                [keychain setString:aData.token forKey:@"token"];
//                [keychain setValue:aData.expires forKey:@"tokenExpires"];
            }
            
            if([target respondsToSelector:selector]) {
                [target performSelector:selector withObject:aData];
            }
        }

    }];
}

@end