//
//  AUDTutorialController.h
//  Audity
//
//  Created by Matthew Horton on 4/23/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AUDTutorialController : UIPageViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource>

-(void) welcomeTappedWithEmail:(NSString *)email andPassword:(NSString *)password;

@end
