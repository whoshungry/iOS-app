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

#define LOBBY_KEY  @"currentlobby"

@interface LobbyViewController () {
    int lobbylength;
    
    UIDatePicker *theDatePicker;
    UIView *pickerView;
}

@end

@implementation LobbyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self lunchBtnPressed:nil];
    
    NSDate *thirtyMinsLater = [[NSDate date] dateByAddingTimeInterval:60*30];
    _whenDate = thirtyMinsLater;
    
    UIBarButtonItem *inviteFriendsBtn = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Invite Friends"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(inviteFriends:)];
    self.navigationItem.rightBarButtonItem = inviteFriendsBtn;
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
    NSMutableString *text = [[NSMutableString alloc] init];
    
    // we pick up the users from the selection, and create a string that we use to update the text view
    // at the bottom of the display; note that self.selection is a property inherited from our base class
    NSMutableArray *chosenFriends = [NSMutableArray new];
    
    for (id<FBGraphUser> user in self.friendPickerController.selection) {
        [chosenFriends addObject:user.id];
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
        [self fillTextBoxAndDismiss:text];
    } else {
        [self fillTextBoxAndDismiss:@"<None>"];
    }
}

- (void)facebookViewControllerCancelWasPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)fillTextBoxAndDismiss:(NSString *)text {
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
}



- (IBAction)lunchBtnPressed:(id)sender {
    [self.lunchBtn setImage: [UIImage imageNamed:@"lunchPressed.jpeg"] forState:UIControlStateNormal];
    [self.dinnerBtn setImage: [UIImage imageNamed:@"dinner"] forState:UIControlStateNormal];
    [self.coffeeBtn setImage: [UIImage imageNamed:@"coffee.jpeg"] forState:UIControlStateNormal];
    [self.drinksBtn setImage: [UIImage imageNamed:@"drinks"] forState:UIControlStateNormal];
    _voteType = @"lunch";
}

- (IBAction)dinnerBtnPressed:(id)sender {
    [self.lunchBtn setImage: [UIImage imageNamed:@"lunch.gif"] forState:UIControlStateNormal];
    [self.dinnerBtn setImage: [UIImage imageNamed:@"dinnerPressed.jpeg"] forState:UIControlStateNormal];
    [self.coffeeBtn setImage: [UIImage imageNamed:@"coffee.jpeg"] forState:UIControlStateNormal];
    [self.drinksBtn setImage: [UIImage imageNamed:@"drinks"] forState:UIControlStateNormal];
    _voteType = @"dinner";
}

- (IBAction)coffeeBtnPressed:(id)sender {
    [self.lunchBtn setImage: [UIImage imageNamed:@"lunch.gif"] forState:UIControlStateNormal];
    [self.dinnerBtn setImage: [UIImage imageNamed:@"dinner"] forState:UIControlStateNormal];
    [self.coffeeBtn setImage: [UIImage imageNamed:@"coffeePressed.jpeg"] forState:UIControlStateNormal];
    [self.drinksBtn setImage: [UIImage imageNamed:@"drinks"] forState:UIControlStateNormal];
    _voteType = @"coffee";
}

- (IBAction)drinksBtnPressed:(id)sender {
    [self.lunchBtn setImage: [UIImage imageNamed:@"lunch.gif"] forState:UIControlStateNormal];
    [self.dinnerBtn setImage: [UIImage imageNamed:@"dinner"] forState:UIControlStateNormal];
    [self.coffeeBtn setImage: [UIImage imageNamed:@"coffee.jpeg"] forState:UIControlStateNormal];
    [self.drinksBtn setImage: [UIImage imageNamed:@"drinksPressed"] forState:UIControlStateNormal];
    _voteType = @"drinks";
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
