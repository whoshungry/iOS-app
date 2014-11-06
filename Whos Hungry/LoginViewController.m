//
//  ViewController.m
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import "LoginViewController.h"
#import <Parse/Parse.h>

@interface LoginViewController ()

@end

@implementation LoginViewController

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Check if user is cached and linked to Facebook, if so, bypass login
    if ([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        NSLog(@"cached login, skip login page");
        [self presentUserDetailsViewControllerAnimated];
    }
}

- (void)presentUserDetailsViewControllerAnimated {
    [self performSegueWithIdentifier:@"mainScreenSegue" sender:nil];
}

- (IBAction)loginWithFacebook:(id)sender {
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[@"public_profile", @"user_friends"];
    
    // Login PFUser using Facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        [_activityIndicator stopAnimating]; // Hide loading indicator
        
        if (!user) {
            NSString *errorMessage = nil;
            if (!error) {
                NSLog(@"Uh oh. The user cancelled the Facebook login.");
                errorMessage = @"Uh oh. The user cancelled the Facebook login.";
            } else {
                NSLog(@"Uh oh. An error occurred: %@", error);
                errorMessage = [error localizedDescription];
            }
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error"
                                                            message:errorMessage
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Dismiss", nil];
            [alert show];
        } else {
            if (user.isNew) {
                NSLog(@"User with facebook signed up and logged in!");
                PFInstallation *installation = [PFInstallation currentInstallation];
                installation[@"user"] = [PFUser currentUser];
                [installation saveInBackground];
            } else {
                NSLog(@"User with facebook logged in!");
            }
            [self presentUserDetailsViewControllerAnimated];
        }
    }];
    
    [_activityIndicator startAnimating]; // Show loading indicator until login is finished
}
@end

