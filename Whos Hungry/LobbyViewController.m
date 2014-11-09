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

@interface LobbyViewController () {
    NSDate *whenDate;
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
    whenDate = thirtyMinsLater;
    
    UIBarButtonItem *inviteFriendsBtn = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Invite Friends"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(inviteFriends:)];
    self.navigationItem.rightBarButtonItem = inviteFriendsBtn;
}

-(IBAction)inviteFriends:(id)sender {
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
        [chosenFriends addObject:user];
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
    [ActionSheetDatePicker showPickerWithTitle:@"" datePickerMode:UIDatePickerModeTime selectedDate:whenDate doneBlock:^(ActionSheetDatePicker *picker, id selectionDate, id origin) {
        NSLog(@"when date is %@", selectionDate);
        whenDate = (NSDate *)selectionDate;
    } cancelBlock:nil origin:sender];
}

- (IBAction)lunchBtnPressed:(id)sender {
    [self.lunchBtn setImage: [UIImage imageNamed:@"lunchPressed.jpeg"] forState:UIControlStateNormal];
    [self.dinnerBtn setImage: [UIImage imageNamed:@"dinner"] forState:UIControlStateNormal];
    [self.coffeeBtn setImage: [UIImage imageNamed:@"coffee.jpeg"] forState:UIControlStateNormal];
    [self.drinksBtn setImage: [UIImage imageNamed:@"drinks"] forState:UIControlStateNormal];
}

- (IBAction)dinnerBtnPressed:(id)sender {
    [self.lunchBtn setImage: [UIImage imageNamed:@"lunch.gif"] forState:UIControlStateNormal];
    [self.dinnerBtn setImage: [UIImage imageNamed:@"dinnerPressed.jpeg"] forState:UIControlStateNormal];
    [self.coffeeBtn setImage: [UIImage imageNamed:@"coffee.jpeg"] forState:UIControlStateNormal];
    [self.drinksBtn setImage: [UIImage imageNamed:@"drinks"] forState:UIControlStateNormal];
}

- (IBAction)coffeeBtnPressed:(id)sender {
    [self.lunchBtn setImage: [UIImage imageNamed:@"lunch.gif"] forState:UIControlStateNormal];
    [self.dinnerBtn setImage: [UIImage imageNamed:@"dinner"] forState:UIControlStateNormal];
    [self.coffeeBtn setImage: [UIImage imageNamed:@"coffeePressed.jpeg"] forState:UIControlStateNormal];
    [self.drinksBtn setImage: [UIImage imageNamed:@"drinks"] forState:UIControlStateNormal];
}

- (IBAction)drinksBtnPressed:(id)sender {
    [self.lunchBtn setImage: [UIImage imageNamed:@"lunch.gif"] forState:UIControlStateNormal];
    [self.dinnerBtn setImage: [UIImage imageNamed:@"dinner"] forState:UIControlStateNormal];
    [self.coffeeBtn setImage: [UIImage imageNamed:@"coffee.jpeg"] forState:UIControlStateNormal];
    [self.drinksBtn setImage: [UIImage imageNamed:@"drinksPressed"] forState:UIControlStateNormal];
}


@end
