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
#import "TwitterAuthHelper.h"

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
    }
    
    return self;
}

-(NSString *)findUserID {
    // Find user ID in keychain
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.mattahorton.Audity"];
    return [keychain stringForKey:@"userId"];

}

-(void)storeUserID: (NSString *)id {
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.mattahorton.Audity"];
    
    // Store ID in keychain
    [keychain setString:id forKey:@"userId"];
    
    // Store ID in Firebase
    Firebase *thisUser = [[self.userRef childByAppendingPath:id] childByAppendingPath:@"userId"];
    [thisUser setValue:id];
}

-(FAuthData *)authFacebook {
    __block FAuthData *aData;
    
    self.userID = [self findUserID];
    
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
    
    if(aData) {
        self.userRef = [self.firebase childByAppendingPath:@"users"];
        
        if (!self.userID) {
            self.userID = self.authData.uid;
            [self storeUserID:self.userID];
        }
        
        Firebase *fbRef = [[self.userRef childByAppendingPath:self.userID] childByAppendingPath:@"facebook"];
        [fbRef setValue:aData.providerData];
    }
    
    return aData;
}

-(FAuthData *)authTwitter {
    __block FAuthData *aData;
    
    self.userID = [self findUserID];
    
    Secrets *secrets = [Secrets sharedInstance];
    NSDictionary *apiKeys = secrets.apiKeys;
    
    TwitterAuthHelper *twitterAuthHelper = [[TwitterAuthHelper alloc] initWithFirebaseRef:self.firebase
                                                                                   apiKey:apiKeys[@"TWCONSUMERKEY"]];
    
    [twitterAuthHelper selectTwitterAccountWithCallback:^(NSError *error, NSArray *accounts) {
        if (error) {
            // Error retrieving Twitter accounts
            aData = nil;
            NSLog(@"Error retrieving accounts");
        } else if ([accounts count] == 0) {
            // No Twitter accounts found on device
            aData = nil;
            NSLog(@"No accounts found");
        } else {
            // Select an account. Here we pick the first one for simplicity
            ACAccount *account = [accounts firstObject];
            [twitterAuthHelper authenticateAccount:account withCallback:^(NSError *error, FAuthData *authData) {
                if (error) {
                    // Error authenticating account
                    aData = nil;
                    NSLog(@"Error authenticating");
                } else {
                    // User logged in!
                    aData = authData;
                }
            }];
        }
    }];
    
    self.authData = aData;
    NSLog(@"authData %@", aData);
    
    if (aData) {
        self.userRef = [self.firebase childByAppendingPath:@"users"];

        if (!self.userID) {
            self.userID = self.authData.uid;
            [self storeUserID:self.userID];
        }
        
        Firebase *twRef = [[self.userRef childByAppendingPath:self.userID] childByAppendingPath:@"twitter"];
        [twRef setValue:aData.providerData];
    }
    
    return aData;
}

-(FAuthData *)authAnon {
    
    __block FAuthData *aData;
    
    self.userID = [self findUserID];
    
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
    
    if(aData) {
        self.userRef = [self.firebase childByAppendingPath:@"users"];

        if (!self.userID) {
            self.userID = self.authData.uid;
            [self storeUserID:self.userID];
        }
    }
    
    return aData;
}

@end