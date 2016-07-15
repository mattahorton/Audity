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
    FIRDatabaseReference *thisUser = [[self.userRef child:storeThisId] child:@"userId"];
    [thisUser setValue:storeThisId];
}

-(void)authAnonWithTarget:(NSObject *)target andSelector:(SEL)selector {
    
    __block FIRUser *fUser;
    
    self.userID = [self findUserID];
    
    [[FIRAuth auth] signInAnonymouslyWithCompletion:^(FIRUser *firUser, NSError *error) {
        if (error) {
            //NSLog(@"Login Failed! %@", error);
            self.loggedIn = NO;
            
            fUser = nil;
        } else {
            //NSLog(@"Login succeeded! %@", authData);
            self.loggedIn = YES;
            
            fUser = firUser;
            
            self.firUser = fUser;
            
            if(fUser) {
                self.userRef = [self.firebase child:@"users"];
                
                if (!self.userID) {
                    self.userID = self.firUser.uid;
                    [self storeUserID:self.userID];
                }                
            }
            
            if([target respondsToSelector:selector]) {
                [target performSelector:selector withObject:fUser];
            }
        }
    }];
}

-(void)authWithEmail:(NSString *)email password:(NSString *)pwd target:(NSObject *)target andSelector:(SEL)selector {
    
    __block FIRUser *fUser;
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.mattahorton.Audity"];
    
    self.userID = [self findUserID];

    [[FIRAuth auth] signInWithEmail:email password:pwd completion:^(FIRUser *firUser, NSError *error) {
        if (error) {
            //NSLog(@"Login Failed! %@", error);
            self.loggedIn = NO;
            
            fUser = nil;
        } else {
            //NSLog(@"Login succeeded! %@", authData);
            self.loggedIn = YES;
            
            fUser = firUser;
            
            self.firUser = fUser;
            
            if(fUser) {
                self.userRef = [self.firebase child:@"users"];
                
                if (!self.userID) {
                    self.userID = self.firUser.uid;
                    [self storeUserID:self.userID];
                }
                
               
//                [keychain setString:aData.token forKey:@"token"];
//                [keychain setValue:aData.expires forKey:@"tokenExpires"];
            }
            
            if([target respondsToSelector:selector]) {
                [target performSelector:selector withObject:fUser];
            }
        }

    }];
}

@end