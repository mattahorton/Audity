
//
//  AUDTutorialController.m
//  Audity
//
//  Created by Matthew Horton on 4/23/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDTutorialController.h"
#import "AUDWelcomeController.h"
#import "AUDLocRequestController.h"
#import "AUDUser.h"

@implementation AUDTutorialController {
    NSArray *myViewControllers;
    AUDUser *audUser;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    audUser = [AUDUser sharedInstance];
    
    self.delegate = self;
    self.dataSource = self;
    
    AUDWelcomeController *p1 = [self.storyboard
                            instantiateViewControllerWithIdentifier:@"IntroTitle"];
    AUDLocRequestController *p2 = [self.storyboard
                                   instantiateViewControllerWithIdentifier:@"LocationRequest"];
    
    myViewControllers = @[p1,p2];
    
    p1.containerController = self;
    p2.containerController = self;
    
    [self setViewControllers:@[p1]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:NO completion:nil];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.4 green:0.2 blue:0.6 alpha:1];
}

-(void) viewDidAppear:(BOOL)animated {
}

-(UIViewController *)viewControllerAtIndex:(NSUInteger)index
{
    return myViewControllers[index];
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController
     viewControllerBeforeViewController:(UIViewController *)viewController
{
    if (!audUser.loggedIn) {
        return nil;
    }
    
    NSUInteger currentIndex = [myViewControllers indexOfObject:viewController];
    
    if (audUser.loggedIn && ((currentIndex-1) == 0)) {
        return nil;
    }
    
    if (!(currentIndex <= 0)) {
        --currentIndex;
        currentIndex = currentIndex % (myViewControllers.count);
    } else {
        return nil;
    }
    
    return [myViewControllers objectAtIndex:currentIndex];
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger currentIndex = [myViewControllers indexOfObject:viewController];
    
    if (!audUser.loggedIn && ((currentIndex+1) > 0)) {
        return nil;
    }
    
    if (!(currentIndex >= myViewControllers.count - 1)) {
        ++currentIndex;
        currentIndex = currentIndex % (myViewControllers.count);
    } else {
        return nil;
    }
    
    return [myViewControllers objectAtIndex:currentIndex];
}

//-(NSInteger)presentationCountForPageViewController:
//(UIPageViewController *)pageViewController
//{
//    return myViewControllers.count;
//}
//
//-(NSInteger)presentationIndexForPageViewController:
//(UIPageViewController *)pageViewController
//{
//    return 0;
//}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[NSClassFromString(@"_UIQueuingScrollView") class]]) {
            CGRect frame = view.frame;
            frame.size.height = view.superview.frame.size.height;
            view.frame = frame;
        }
    }
}

#pragma mark Helper Methods

-(void) welcomeTappedWithEmail:(NSString *)email andPassword:(NSString *)password {
    // Authenticate
    [audUser authWithEmail:email password:password target:self andSelector:@selector(afterAuth:)];
}

#pragma mark After Auth Callback
-(void)afterAuth:(FAuthData *)aData {
    if(aData) [self setViewControllers:@[myViewControllers[1]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
}


@end
