//
//  AppDelegate.m
//  Audity
//
//  Created by Ge Wang on 1/15/15.
//  Copyright (c) 2015 Ge Wang. All rights reserved.
//

#import "AppDelegate.h"
#import "HockeySDK.h"
#import "Secrets.h"
#import "RNOpenSSLDecryptor.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Get path to encrypted data
    NSString *encryptedPlistPath = [[NSBundle mainBundle] pathForResource:@"keys" ofType:@"enc"];
    
    // Read in encrypted data
    NSData *encryptedData = [NSData dataWithContentsOfFile:encryptedPlistPath];
    
    // Decrypt data
    NSError *error;
    NSData *decryptedData = [RNOpenSSLDecryptor decryptData:encryptedData
                                               withSettings:kRNCryptorAES256Settings
                                                   password:secretPwdForPlist
                                                      error:&error];
    
    // Log any errors in decryption
    if(error) {
        NSLog(@"%@", error);
    }
    
    // Get api keys
    NSString *errr;
    NSPropertyListFormat format;
    NSDictionary *apiKeys = [NSPropertyListSerialization propertyListFromData:decryptedData mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&errr];
    
    // Log any errors in serialization
    if(errr) {
        NSLog(@"%@", errr);
    }
    
    NSString *HOCKEYID = apiKeys[@"HOCKEYID"];
    
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:HOCKEYID];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator
     authenticateInstallation];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
