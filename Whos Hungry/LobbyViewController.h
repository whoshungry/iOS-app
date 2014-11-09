//
//  LobbyViewController.h
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface LobbyViewController : UIViewController <FBFriendPickerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *lunchBtn;
@property (weak, nonatomic) IBOutlet UIButton *dinnerBtn;
@property (weak, nonatomic) IBOutlet UIButton *coffeeBtn;
@property (weak, nonatomic) IBOutlet UIButton *drinksBtn;
- (IBAction)lunchBtnPressed:(id)sender;
- (IBAction)dinnerBtnPressed:(id)sender;
- (IBAction)coffeeBtnPressed:(id)sender;
- (IBAction)drinksBtnPressed:(id)sender;
- (IBAction)chooseWhenDate:(id)sender;

@property (retain, nonatomic) FBFriendPickerViewController *friendPickerController;

@end
