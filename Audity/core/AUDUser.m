//
//  AUDUser.m
//  Audity
//
//  Created by Matthew Horton on 6/23/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDUser.h"
#import "AUDFirebase.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
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
        self.userRef = [self.firebase childByAppendingPath:@"users"];
    }
    
    return self;
}

-(void)storeUserID {
    // Find user ID in keychain
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.mattahorton.Audity"];
    self.userID = [keychain stringForKey:@"userId"];
    
    if (!self.userID) {
        // Generate ID if there is none
        self.userID = [[NSUUID UUID] UUIDString];
        // Store ID in keychain
        [keychain setString:self.userID forKey:@"userId"];
        
        // Store ID in Firebase
        Firebase *thisUser = [self.userRef childByAppendingPath:self.userID];
        [thisUser setValue:@{@"userId":self.userID}];
    }
}

-(FAuthData *)authFacebook {
    __block FAuthData *aData;
    
    [self storeUserID];
    
    FBSDKLoginManager *facebookLogin = [[FBSDKLoginManager alloc] init];
    
    [facebookLogin logInWithReadPermissions:@[@"email"]
                                    handler:^(FBSDKLoginManagerLoginResult *facebookResult, NSError *facebookError) {
                                        
                                        if (facebookError) {
                                            
                                            NSLog(@"Facebook login failed. Error: %@", facebookError);
                                            aData = nil;
                                            
                                        } else if (facebookResult.isCancelled) {
                                            
                                            NSLog(@"Facebook login got cancelled.");
                                            aData = nil;
                                            
                                        } else {
                                            
                                            NSString *accessToken = [[FBSDKAccessToken currentAccessToken] tokenString];
                                            
                                            [_firebase authWithOAuthProvider:@"facebook" token:accessToken
                                                         withCompletionBlock:^(NSError *error, FAuthData *authData) {
                                                             if (error) {
                                                                 NSLog(@"Login failed. %@", error);
                                                                 aData = nil;
                                                             } else {
                                                                 NSLog(@"Logged in! %@", authData);
                                                                 aData = authData;
                                                             }
                                                         }];
                                        }
                                    }];
    self.authData = aData;
    return aData;
}

-(FAuthData *)authTwitter {
    return nil;
}

-(FAuthData *)authAnon {
    
    __block FAuthData *aData;
    
    [self storeUserID];
    
    Secrets *secrets = [Secrets sharedInstance];
    NSDictionary *apiKeys = secrets.apiKeys;
    
    NSString *FBSECRET = apiKeys[@"FBSECRET"];
    [self.firebase authWithCustomToken:FBSECRET withCompletionBlock:^(NSError *error, FAuthData *authData) {
        if (error) {
            //NSLog(@"Login Failed! %@", error);
            aData = nil;
        } else {
            //NSLog(@"Login succeeded! %@", authData);
            aData = authData;
        }
    }];
    
    self.authData = aData;
    return aData;
}

@end