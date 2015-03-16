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
    Firebase *responsesRef;
    AUDNavViewController *parent;
    NSUserDefaults *defaults;
    NSMutableArray *dataArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _tblView.delegate = self;
    _tblView.dataSource = self;
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    parent = (AUDNavViewController *)self.parentViewController;
    _audity = (NSMutableDictionary *)parent.info;
    if(_audity != nil) _viewTitle.title = _audity[@"signature"];
    
    self.core = [MHCore sharedInstance];
    _firebase = self.core.geo.fireRef;
    recordingsRef = [_firebase childByAppendingPath:@"recordings"];
    responsesRef = [_firebase childByAppendingPath:@"responses"];
    
    if(_audity != nil) {
        NSNumber *num = (NSNumber *)_audity[@"likes"];
        _likesLabel.text = [num stringValue];
    }
    
    NSMutableDictionary *dict = [[defaults dictionaryForKey:@"audityLikes"] mutableCopy];
    NSString *key = self.audity[@"key"];

    if((dict != nil) && (dict[key] != nil)) {
        self.likeButton.enabled = NO;
        self.dislikeButton.enabled = NO;
    }
    
    [self.likeButton setTitle:@"Voted" forState:UIControlStateDisabled];
    [self.dislikeButton setTitle:@"You" forState:UIControlStateDisabled];
    
    
    // setup TableView data
    dataArray = [[NSMutableArray alloc] init];
    
    [[[responsesRef queryOrderedByChild:@"audity"] queryEqualToValue:(NSString *)self.audity[@"key"]]
        observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"%@", snapshot.value[@"recording"]);
            
        [dataArray addObject:(NSDictionary *)snapshot.value];
        [_tblView reloadData];
    }];
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
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *response = dataArray[indexPath.row];
    cell.textLabel.text = response[@"signature"];
    cell.detailTextLabel.text = response[@"uploaded"];
    
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [dataArray count];
}

- (IBAction)dislike:(id)sender {
    NSMutableDictionary *dict = [[defaults dictionaryForKey:@"audityLikes"] mutableCopy];
    NSString *key = self.audity[@"key"];
    
    if(!dict || !dict[key]) {
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
        
        if (dict) {
            dict[key] = @1;
        } else {
            dict = [NSMutableDictionary dictionaryWithDictionary:@{}];
            dict[key] = @1;
        }
        
        [defaults setObject:dict forKey:@"audityLikes"];
        [defaults synchronize];
        
        self.likeButton.enabled = NO;
        self.dislikeButton.enabled = NO;
        self.dislikeButton.titleLabel.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:.2];
    }
}

- (IBAction)like:(id)sender {
    NSMutableDictionary *dict = [[defaults dictionaryForKey:@"audityLikes"] mutableCopy];
    NSString *key = self.audity[@"key"];
    
    if(!dict || !dict[key]) {
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
        
        if (dict) {
            dict[key] = @1;
        } else {
            dict = [NSMutableDictionary dictionaryWithDictionary:@{}];
            dict[key] = @1;
        }
        
        [defaults setObject:dict forKey:@"audityLikes"];
        [defaults synchronize];
        
        self.likeButton.enabled = NO;
        self.dislikeButton.enabled = NO;
        self.dislikeButton.titleLabel.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:.2];
    }
}

- (IBAction)respondButtonPressed:(id)sender {
    UIBarButtonItem *item = (UIBarButtonItem *)sender;
    
    if (self.core.isRecording) {
        [self.core endResponseWithDelegate:self];
        item.title = @"Respond";
    } else {
        [self.core startRecording];
        item.title = @"Finish";
    }
}

#pragma mark Alert View Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    UITextField *textfield = [alertView textFieldAtIndex:0];
    if(buttonIndex != [alertView cancelButtonIndex]) {
        NSString *signature = textfield.text;
        if (!signature) signature = @"anonymous";
        if ([signature isEqualToString:@""]) signature = @"anonymous";
        
        NSString *documentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
    objectAtIndex:0];
        NSURL *file = [NSURL fileURLWithPath:[documentsFolder stringByAppendingPathComponent:@"Recording.aiff"]];
        NSString *uuid = [[NSUUID UUID] UUIDString];
        [self.core uploadNewAudityResponse:file withKey:uuid andSignature:signature forAudity:(NSString *)self.audity[@"key"]];
    } else {
        self.core.isRecording = NO;
    }
}

#pragma mark Add Response

-(void)addResponseToAudityWithSignature:(NSString *)signature andKey:(NSString *)key{
    NSString *url = @"https://s3.amazonaws.com/audity/";
    url = [[url stringByAppendingString:key] stringByAppendingString:@".aiff"];
    
    NSDictionary *dict = @{@"recording":url,
                           @"userId":self.core.userID,
                           @"signature":signature,
                           @"uploaded":[[NSDate date] description],
                           @"audity":(NSString *)self.audity[@"key"],
                           };
    Firebase *respRef = [responsesRef childByAppendingPath:key];
    
    [respRef setValue:dict];
    
    Firebase *recRespRef = [[[recordingsRef childByAppendingPath:(NSString *)self.audity[@"key"]] childByAppendingPath:@"responses"] childByAppendingPath:key];
    
    [recRespRef setValue:key];
}

@end