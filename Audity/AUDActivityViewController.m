//
//  AUDActivityViewController.m
//  Audity
//
//  Created by Matthew Horton on 3/13/15.
//  Copyright (c) 2015 Matt Horton. All rights reserved.
//

#import "AUDActivityViewController.h"
#import "AUDNavViewController.h"
#import "MHCore.h"
#import <Firebase/Firebase.h>

@interface AUDActivityViewController ()

@property (strong, nonatomic) MHCore *core;
@property (strong, nonatomic) Firebase *firebase;

@end

@implementation AUDActivityViewController {
    Firebase *recordingsRef;
    AUDNavViewController *parent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _tblView.delegate = self;
    _tblView.dataSource = self;
    
    parent = (AUDNavViewController *)self.parentViewController;
    _audity = (NSMutableDictionary *)parent.info;
    if(_audity != nil) _viewTitle.title = _audity[@"signature"];
    
    self.core = [MHCore sharedInstance];
    _firebase = self.core.geo.fireRef;
    recordingsRef = [_firebase childByAppendingPath:@"recordings"];
    
    if(_audity != nil) {
        NSNumber *num = (NSNumber *)_audity[@"likes"];
        _likesLabel.text = [num stringValue];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark Table View Delegate Methods
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [[UITableViewCell alloc] init];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 10;
}

- (IBAction)dislike:(id)sender {
    Firebase *likesRef = [[recordingsRef childByAppendingPath:(NSString *)self.audity[@"key"]] childByAppendingPath:@"likes"];
    int current = 0;
    if(self.audity[@"likes"] != nil) {
        NSNumber *num = (NSNumber *)self.audity[@"likes"];
        current = [num intValue];
    }
    
    current = current - 1;
    self.audity[@"likes"] = [NSNumber numberWithInt:current];
    self.core.audities[self.audity[@"key"]] = self.audity;
    [likesRef setValue:(NSNumber *)self.audity[@"likes"]];
    self.likesLabel.text = [[NSNumber numberWithInt:current] stringValue];
}

- (IBAction)like:(id)sender {
    Firebase *likesRef = [[recordingsRef childByAppendingPath:(NSString *)self.audity[@"key"]] childByAppendingPath:@"likes"];
    int current = 0;
    if(self.audity[@"likes"] != nil) {
        NSNumber *num = (NSNumber *)self.audity[@"likes"];
        current = [num intValue];
    }
    
    current = current + 1;
    self.audity[@"likes"] = [NSNumber numberWithInt:current];
    self.core.audities[self.audity[@"key"]] = self.audity;
    [likesRef setValue:(NSNumber *)self.audity[@"likes"]];
    self.likesLabel.text = [[NSNumber numberWithInt:current] stringValue];
}
@end
