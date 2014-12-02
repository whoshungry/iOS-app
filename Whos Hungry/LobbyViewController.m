//
//  LobbyViewController.m
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import "LobbyViewController.h"
#import "ActionSheetDatePicker.h"
#import "SummaryViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "RestaurantsViewController.h"

#define LOBBY_KEY  @"currentlobby"

@interface LobbyViewController () {
    int lobbylength;
    
    UIDatePicker *theDatePicker;
    UIView *pickerView;
    UIColor *greenColor;
}

@end

@implementation LobbyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    greenColor = [UIColor colorWithRed:(91.0/255.0) green:(186.0/255.0) blue:(71.0/255.0) alpha:1.0];
    
    NSDate *thirtyMinsLater = [[NSDate date] dateByAddingTimeInterval:60*30];
    _whenDate = thirtyMinsLater;
    
    UIBarButtonItem *inviteFriendsBtn = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Invite Friends"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(inviteFriends:)];
    self.navigationItem.rightBarButtonItem = inviteFriendsBtn;
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_voteType == nil)
        [self lunchBtnPressed:nil];
}

-(IBAction)inviteFriends:(id)sender {
    //Transfer WhenTime to HootLobby
    //Transfer voteType to HootLobby
    HootLobby* tempLobby = [self loadCustomObjectWithKey:LOBBY_KEY];
    
    if (!tempLobby) {
        tempLobby = [HootLobby new];
        NSLog(@"Current Lobby is empty");
        tempLobby.expirationTime = _whenDate;
        tempLobby.voteType = _voteType;
        [self saveCustomObject:tempLobby];
    }
    else{
        NSLog(@"Current Lobby has DATA!");
        tempLobby.expirationTime = _whenDate;
        tempLobby.voteType = _voteType;
        [self saveCustomObject:tempLobby];
    }
    
    
    if (!FBSession.activeSession.isOpen) {
        // if the session is closed, then we open it here, and establish a handler for state changes
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"user_friends"]
                                           allowLoginUI:YES
                                      completionHandler:^(FBSession *session,
                                                          FBSessionState state,
                                                          NSError *error) {
                                          
                                          if (error) {
                                              UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                                  message:error.localizedDescription
                                                                                                 delegate:nil
                                                                                        cancelButtonTitle:@"OK"
                                                                                        otherButtonTitles:nil];
                                              [alertView show];
                                          } else if (session.isOpen) {
                                              [self inviteFriends:sender];
                                          }
                                      }];
        return;
    }
    
    if (self.friendPickerController == nil) {
        // Create friend picker, and get data loaded into it.
        self.friendPickerController = [[FBFriendPickerViewController alloc] init];
        self.friendPickerController.title = @"Pick Friends";
        self.friendPickerController.delegate = self;
    }
    
    [self.friendPickerController loadData];
    [self.friendPickerController clearSelection];
    
    [self presentViewController:self.friendPickerController animated:YES completion:nil];
}

- (void)facebookViewControllerDoneWasPressed:(id)sender {
    //NSMutableString *text = [[NSMutableString alloc] init];
    
    // we pick up the users from the selection, and create a string that we use to update the text view
    // at the bottom of the display; note that self.selection is a property inherited from our base class
    NSMutableArray *chosenFriends = [NSMutableArray new];
    
    for (id<FBGraphUser> user in self.friendPickerController.selection) {
        [chosenFriends addObject:user.objectID];
    }
    
    HootLobby* tempLobby = [self loadCustomObjectWithKey:LOBBY_KEY];
    if (!tempLobby) {
        NSLog(@"Current Lobby is empty");
        tempLobby = [HootLobby new];
        tempLobby.facebookbInvitatitions = chosenFriends;
        [self saveCustomObject:tempLobby];
    }
    else{
        NSLog(@"Current Lobby has DATA!");
        tempLobby.facebookbInvitatitions = chosenFriends;
        [self saveCustomObject:tempLobby];
    }
    
    if (chosenFriends.count > 0) {
        [self presentSummaryVC];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Select Friends!" message:@"You have to select some friends first!" delegate:nil cancelButtonTitle: @"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)facebookViewControllerCancelWasPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)presentSummaryVC {
    SummaryViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SummaryViewController"];
    [self.friendPickerController presentViewController:vc animated:YES completion:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return YES;
}

- (IBAction)chooseWhenDate:(id)sender {
    [ActionSheetDatePicker showPickerWithTitle:@"" datePickerMode:UIDatePickerModeTime selectedDate:_whenDate doneBlock:^(ActionSheetDatePicker *picker, id selectionDate, id origin) {
        
        NSLog(@"when date is %@", selectionDate);
        _whenDate = (NSDate *)selectionDate;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm"];
        NSString *formattedDateString = [dateFormatter stringFromDate:_whenDate];
        NSLog(@"formattedDateString: %@", formattedDateString);
        [_whenButton setTitle:[NSString stringWithFormat:@"When: %@", formattedDateString] forState:UIControlStateNormal];
    } cancelBlock:nil origin:sender];
    
    
    /*NSInteger minuteInterval = 5;
    //clamp date
    NSInteger referenceTimeInterval = (NSInteger)[self.whenDate timeIntervalSinceReferenceDate];
    NSInteger remainingSeconds = referenceTimeInterval % (minuteInterval *60);
    NSInteger timeRoundedTo5Minutes = referenceTimeInterval - remainingSeconds;
    if(remainingSeconds>((minuteInterval*60)/2)) {/// round up
        timeRoundedTo5Minutes = referenceTimeInterval +((minuteInterval*60)-remainingSeconds);
    }
    
    self.whenDate = [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)timeRoundedTo5Minutes];
    
    ActionSheetDatePicker *datePicker = [[ActionSheetDatePicker alloc] initWithTitle:@"Select a time" datePickerMode:UIDatePickerModeTime selectedDate:self.whenDate target:self action:@selector(timeWasSelected:element:) origin:sender];
    datePicker.minuteInterval = minuteInterval;
    //[datePicker addCustomButtonWithTitle:@"value" value:[NSDate date]];
    //  [datePicker addCustomButtonWithTitle:@"sel" target:self selector:@selector(dateSelector:)];
    //  [datePicker addCustomButtonWithTitle:@"Block" actionBlock:^{
    //      NSLog(@"Block invoked");
    //  }];
    [datePicker showActionSheetPicker];*/
}

-(void)timeWasSelected:(NSDate *)selectedTime element:(id)element {
    _whenDate = selectedTime;
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"HH:mm"];
    [self.whenButton setTitle:[dateFormatter stringFromDate:selectedTime] forState:UIControlStateNormal];
}

- (IBAction)lunchBtnPressed:(id)sender {
    self.lunchBtn.layer.borderColor = greenColor.CGColor;
    self.lunchBtn.layer.borderWidth = 3.0f;
    self.dinnerBtn.layer.borderColor = greenColor.CGColor;
    self.dinnerBtn.layer.borderWidth = 0.0f;
    self.coffeeBtn.layer.borderColor = greenColor.CGColor;
    self.coffeeBtn.layer.borderWidth = 0.0f;
    self.drinksBtn.layer.borderColor = greenColor.CGColor;
    self.drinksBtn.layer.borderWidth = 0.0f;
    _voteType = @"lunch";
}

- (IBAction)dinnerBtnPressed:(id)sender {
    self.lunchBtn.layer.borderColor = greenColor.CGColor;
    self.lunchBtn.layer.borderWidth = 0.0f;
    self.dinnerBtn.layer.borderColor = greenColor.CGColor;
    self.dinnerBtn.layer.borderWidth = 3.0f;
    self.coffeeBtn.layer.borderColor = greenColor.CGColor;
    self.coffeeBtn.layer.borderWidth = 0.0f;
    self.drinksBtn.layer.borderColor = greenColor.CGColor;
    self.drinksBtn.layer.borderWidth = 0.0f;
    _voteType = @"dinner";
}

- (IBAction)coffeeBtnPressed:(id)sender {
    self.lunchBtn.layer.borderColor = greenColor.CGColor;
    self.lunchBtn.layer.borderWidth = 0.0f;
    self.dinnerBtn.layer.borderColor = greenColor.CGColor;
    self.dinnerBtn.layer.borderWidth = 0.0f;
    self.coffeeBtn.layer.borderColor = greenColor.CGColor;
    self.coffeeBtn.layer.borderWidth = 3.0f;
    self.drinksBtn.layer.borderColor = greenColor.CGColor;
    self.drinksBtn.layer.borderWidth = 0.0f;
    _voteType = @"cafe";
}

- (IBAction)drinksBtnPressed:(id)sender {
    self.lunchBtn.layer.borderColor = greenColor.CGColor;
    self.lunchBtn.layer.borderWidth = 0.0f;
    self.dinnerBtn.layer.borderColor = greenColor.CGColor;
    self.dinnerBtn.layer.borderWidth = 0.0f;
    self.coffeeBtn.layer.borderColor = greenColor.CGColor;
    self.coffeeBtn.layer.borderWidth = 0.0f;
    self.drinksBtn.layer.borderColor = greenColor.CGColor;
    self.drinksBtn.layer.borderWidth = 3.0f;
    _voteType = @"drinks";
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"WhereSegue"]) {
        UINavigationController *nav = [segue destinationViewController];
        RestaurantsViewController *restVC = (RestaurantsViewController *)nav.topViewController;
        restVC.voteType = _voteType;
    }
}

-(void)saveCustomObject:(HootLobby *)object
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSData *myEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
    [prefs setObject:myEncodedObject forKey:LOBBY_KEY];
}

-(HootLobby *)loadCustomObjectWithKey:(NSString*)key
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSData *myEncodedObject = [prefs objectForKey:key ];
    HootLobby *obj = (HootLobby *)[NSKeyedUnarchiver unarchiveObjectWithData: myEncodedObject];
    return obj;
}


@end
