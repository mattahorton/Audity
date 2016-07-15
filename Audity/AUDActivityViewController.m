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
#import "AudityManager.h"
#import <Firebase/Firebase.h>

@interface AUDActivityViewController ()

@property (strong, nonatomic) MHCore *core;
@property (strong, nonatomic) FIRDatabaseReference *firebase;
@property (strong, nonatomic) AudityManager* audityManager;

@end

@implementation AUDActivityViewController {
    FIRDatabaseReference *recordingsRef;
    FIRDatabaseReference *responsesRef;
    AUDNavViewController *parent;
    NSUserDefaults *defaults;
    NSMutableArray *dataArray;
    NSMutableArray *localURLS;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _tblView.delegate = self;
    _tblView.dataSource = self;
    
    defaults = [NSUserDefaults standardUserDefaults];
    _audityManager = [AudityManager sharedInstance];
    
    parent = (AUDNavViewController *)self.parentViewController;
    _audity = [_audityManager audities][parent.info];
    if(_audity != nil) _viewTitle.title = _audity.signature;
    
    self.core = [MHCore sharedInstance];
    _firebase = self.core.firebase;
    recordingsRef = [_firebase child:@"recordings"];
    responsesRef = [_firebase child:@"responses"];
    
    if(_audity != nil) {
        NSNumber *num = [NSNumber numberWithLong:self.audity.likes];
        _likesLabel.text = [num stringValue];
    }
    
    NSMutableDictionary *dict = [[defaults dictionaryForKey:@"audityLikes"] mutableCopy];
    NSString *key = self.audity.key;

    if((dict != nil) && (dict[key] != nil)) {
        self.likeButton.enabled = NO;
        self.dislikeButton.enabled = NO;
    }
    
    [self.likeButton setTitle:@"Voted" forState:UIControlStateDisabled];
    [self.dislikeButton setTitle:@"You" forState:UIControlStateDisabled];
    
    
    // setup TableView data
    dataArray = [[NSMutableArray alloc] init];
    localURLS = [[NSMutableArray alloc] init];
    
    [[[responsesRef queryOrderedByChild:@"audity"] queryEqualToValue:self.audity.key]
        observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
//        NSLog(@"%@", snapshot.value[@"recording"]);
            
        [dataArray addObject:(NSDictionary *)snapshot.value];
        [self reloadData];
        [_tblView reloadData];
            
    }];
}

-(void)reloadData{    
    if (!localURLS || ([localURLS count] < [dataArray count])) {

        for (int index = (int)[localURLS count]; index < [dataArray count]; index++) {
            NSDictionary *respDict = [dataArray objectAtIndex:index];

            NSString *filePath = (NSString *)[respDict objectForKey:@"recording"];
            
            // Lets add a callback here and only make the cell enabled after download is done
            [self.core.storage downloadFileWithFilename:filePath isResponse:YES];
            NSURL *localURL = [NSURL URLWithString:filePath];
            [localURLS addObject:localURL];
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            UITableViewCell *cell = [self tableView:self.tblView cellForRowAtIndexPath:indexPath];
            [self setEnabled:YES forCell:cell];
        }
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
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *response = dataArray[indexPath.row];
    cell.textLabel.text = response[@"signature"];
    cell.detailTextLabel.text = response[@"uploaded"];

    if (!localURLS || indexPath.row >= localURLS.count || !localURLS[indexPath.row]) [self setEnabled:NO forCell:cell];

    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [dataArray count];
}

#pragma mark Cell Enable/Disable

-(void) setEnabled:(BOOL)enabled forCell:(UITableViewCell *)cell {
    cell.userInteractionEnabled = enabled;
    cell.selectionStyle = (enabled) ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;;
    cell.textLabel.enabled = enabled;
    cell.detailTextLabel.enabled = enabled;
}

#pragma mark Buttons

- (IBAction)dislike:(id)sender {
    NSMutableDictionary *dict = [[defaults dictionaryForKey:@"audityLikes"] mutableCopy];
    NSString *key = self.audity.key;
    
    if(!dict || !dict[key]) {
        FIRDatabaseReference*likesRef = [[recordingsRef child:self.audity.key] child:@"likes"];
        long current = 0;
        
        current = self.audity.likes;
        current = current - 1;
        self.audity.likes = current;
        
        [self.audityManager setAudity:self.audity forKey:self.audity.key];
        
        [likesRef setValue:[NSNumber numberWithInteger:self.audity.likes]];
        self.likesLabel.text = [[NSNumber numberWithLong:current] stringValue];
        
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
    NSString *key = self.audity.key;
    
    if(!dict || !dict[key]) {
        FIRDatabaseReference *likesRef = [[recordingsRef child:self.audity.key] child:@"likes"];
        long current = 0;
        
        current = self.audity.likes;
        current = current + 1;
        self.audity.likes = current;
        
        [self.audityManager setAudity:self.audity forKey:self.audity.key];
        
        [likesRef setValue:[NSNumber numberWithInteger:self.audity.likes]];
        self.likesLabel.text = [[NSNumber numberWithLong:current] stringValue];
        
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
        if (!signature ||[signature isEqualToString:@""]) {
            signature = [defaults stringForKey:@"defaultSig"];
            if (!signature ||[signature isEqualToString:@""]) {
                signature = @"anonymous";
                [defaults setValue:@"anonymous" forKey:@"defaultSig"];
            }
        }
        
        NSString *documentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
    objectAtIndex:0];
        NSURL *file = [NSURL fileURLWithPath:[documentsFolder stringByAppendingPathComponent:@"Recording.m4a"]];
        NSString *uuid = [[NSUUID UUID] UUIDString];
        [self.core uploadNewAudityResponse:file withKey:uuid andSignature:signature forAudity:self.audity.key];
    } else {
        self.core.isRecording = NO;
    }
}

- (IBAction)replayPress:(id)sender {
//    NSLog(@"replay pressed");
    UIButton *replayButton = (UIButton *)sender;
    NSString *documentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
                                 objectAtIndex:0];

    if (!self.core.replaying) {
        self.core.replaying = YES;
        
        [replayButton setImage:[UIImage imageNamed:@"Pause.png"] forState:UIControlStateNormal];
        NSURL *file = [NSURL fileURLWithPath:[documentsFolder stringByAppendingPathComponent:@"Recording.m4a"]];
        [self.core playRecorded:file withButton:replayButton];
    } else {
        self.core.recordedPlayer.channelIsPlaying = !self.core.recordedPlayer.channelIsPlaying;
        if(self.core.recordedPlayer.channelIsPlaying) {
            [replayButton setImage:[UIImage imageNamed:@"Pause.png"] forState:UIControlStateNormal];
        } else {
            [replayButton setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
        }
    }
}


#pragma mark Add Response

-(void)addResponseToAudityWithSignature:(NSString *)signature andKey:(NSString *)key{
    NSString *url = [key stringByAppendingString:@".m4a"];
    
    NSDictionary *dict = @{@"recording":url,
                           @"userId":self.core.userID,
                           @"signature":signature,
                           @"uploaded":[[NSDate date] description],
                           @"audity":self.audity.key,
                           };
    FIRDatabaseReference *respRef = [responsesRef child:key];
    
    [respRef setValue:dict];
    
    FIRDatabaseReference *recRespRef = [[[recordingsRef child:self.audity.key] child:@"responses"] child:key];
    
    [recRespRef setValue:key];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    unsigned long index = [indexPath indexAtPosition:1];
    if([localURLS count] > index){
        NSURL *localURL = [localURLS objectAtIndex:index];
        NSString *localString = [localURL absoluteString];
        NSString *downloadingFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:localString];
        if (!self.core.muteSetting) [self.core playResponse:[NSURL URLWithString:downloadingFilePath]];
    }
}

#pragma mark Text Field Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // Prevent crashing undo bug – see note below.
    if(range.length + range.location > textField.text.length)
    {
        return NO;
    }
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return newLength <= 22;
}


@end
