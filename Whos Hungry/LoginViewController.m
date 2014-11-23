//
//  ViewController.m
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import "LoginViewController.h"
#import "AFNetworking.h"
#import "AFHTTPRequestOperation.h"

static NSString * const BaseURLString = @"http://54.215.240.73:3000/";

@interface LoginViewController ()

@end

@implementation LoginViewController

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.loginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    self.loginButton.delegate = self;
    
    /*NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];*/
    
    //[self.view setTranslatesAutoresizingMaskIntoConstraints:NO];
}

//fetched the facebook info
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    //NSString *firstTime = [[NSUserDefaults standardUserDefaults] stringForKey:@"firstTime"];
    //if (firstTime == nil) {
        NSLog(@"user id is :%@", user.objectID);
        NSLog(@"username is %@", user.name);
        NSString *pushToken = [[NSUserDefaults standardUserDefaults]
                                 stringForKey:@"pushToken"];
        [self registerUser:user andPushID:pushToken];
    //}
}

-(void) registerUser:(id<FBGraphUser>)user andPushID:(NSString *)pushID{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{
                             @"username": user.name,
                             @"push_id":pushID,
                             @"facebook_id" : user.objectID,
                             @"os_type" : @"IOS"};
    [manager POST:[NSString stringWithFormat:@"%@apis/register", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *results = (NSDictionary *)responseObject;
        NSLog(@"resultssS:S %@", results);
        NSString *username = results[@"user_id"];
        [[NSUserDefaults standardUserDefaults] setObject:username forKey:@"username"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    [[NSUserDefaults standardUserDefaults] setObject:@"nah" forKey:@"firstTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self performSegueWithIdentifier:@"mainScreenSegue" sender:self];
}

// Logged-out user experience
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    
}

// Handle possible errors that can occur during login
- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    NSString *alertMessage, *alertTitle;
    
    // If the user should perform an action outside of you app to recover,
    // the SDK will provide a message for the user, you just need to surface it.
    // This conveniently handles cases like Facebook password change or unverified Facebook accounts.
    if ([FBErrorUtility shouldNotifyUserForError:error]) {
        alertTitle = @"Facebook error";
        alertMessage = [FBErrorUtility userMessageForError:error];
        
        // This code will handle session closures that happen outside of the app
        // You can take a look at our error handling guide to know more about it
        // https://developers.facebook.com/docs/ios/errors
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
        
        // If the user has cancelled a login, we will do nothing.
        // You can also choose to show the user a message if cancelling login will result in
        // the user not being able to complete a task they had initiated in your app
        // (like accessing FB-stored information or posting to Facebook)
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
        NSLog(@"user cancelled login");
        
        // For simplicity, this sample handles other errors with a generic message
        // You can checkout our error handling guide for more detailed information
        // https://developers.facebook.com/docs/ios/errors
    } else {
        alertTitle  = @"Something went wrong";
        alertMessage = @"Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }
    
    if (alertMessage) {
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

@end

