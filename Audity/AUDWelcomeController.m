//
//  AUDWelcomeController.m
//  Audity
//
//  Created by Matthew Horton on 5/30/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDWelcomeController.h"

@implementation AUDWelcomeController

- (void)updateViewConstraints {
    [super updateViewConstraints];
    float screenHeight = [UIScreen mainScreen].bounds.size.height;
    NSLog(@"%f", screenHeight);
    
    if (screenHeight == 480.0f) {
        self.audityTop.constant = 43;
        self.loginBottom.constant = 69;
        self.passwordLeft.constant = 28;
        self.passwordRight.constant = 28;
        self.emailLeft.constant = 28;
        self.emailRight.constant = 28;
    } else if (screenHeight == 568.0f) {
        self.audityTop.constant = 106;
        self.loginBottom.constant = 69;
        self.passwordLeft.constant = 28;
        self.passwordRight.constant = 28;
        self.emailLeft.constant = 28;
        self.emailRight.constant = 28;

    }
}

- (IBAction)welcomeTapped:(id)sender {
    [self.containerController welcomeTappedWithEmail:self.email.text andPassword:self.password.text];
}

-(void) viewDidLoad {
    [super viewDidLoad];
    
    [self styleTextField:self.password];
    [self styleTextField:self.email];
}

-(void) styleTextField:(UITextField *)textField {
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, textField.frame.size.height - 1, textField.frame.size.width, 1.0f);
    bottomBorder.backgroundColor = [UIColor whiteColor].CGColor;
    [textField.layer addSublayer:bottomBorder];
    
    UIColor *color = [UIColor whiteColor];
    textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{NSForegroundColorAttributeName: color}];
}

@end
