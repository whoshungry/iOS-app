//
//  MainViewController.m
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import "MainViewController.h"
#import "HootGroupCell.h"
#import "AFNetworking.h"
#import "AFHTTPRequestOperation.h"
#import "HootLobby.h"
#import "SummaryViewController.h"
#import <FacebookSDK/FacebookSDK.h>

static NSString * const BaseURLString = @"http://54.215.240.73:3000/";

@interface MainViewController () {
    NSMutableArray *lobbies;
    NSMutableArray *hostImages;
    HootLobby *chosenHoot;
}

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    chosenHoot = [HootLobby new];
    //[self.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    lobbies = [NSMutableArray new];
    hostImages = [NSMutableArray new];
    
    [self.tableView reloadData];
    
    __block NSString *facebookID;
    
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // Success! Include your code to handle the results here
            NSLog(@"user info: %@", result);
            facebookID = result[@"id"];
            [self getGroupsWithID:facebookID];
        } else {
            // An error occurred, we need to handle the error
            // See: https://developers.facebook.com/docs/ios/errors
        }
    }];
}

-(void) getGroupsWithID:(NSString *) fbid {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{@"user_id": fbid};
    [manager POST:[NSString stringWithFormat:@"%@apis/show_lobby_friend", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseData) {
        NSLog(@"JSON: %@", responseData);
        NSDictionary *data = responseData;
        if (data != nil) {
            NSArray *groups = data[@"lobbies"];
            NSLog(@"found sooooo many groups: %li", (unsigned long)groups.count);
            for (int i = 0; i < groups.count; i++) {
                HootLobby *lobby = [[HootLobby alloc] init];
                NSLog(@"gorups object ids: %@", [groups objectAtIndex:i]);
                NSString *facebookId = [groups objectAtIndex:i][@"admin_user"];
                NSString *facebookName = [groups objectAtIndex:i][@"admin_name"];
                NSString *facebookPicture = [groups objectAtIndex:i][@"admin_picture"];
                
                NSDate *expectedDate = [groups objectAtIndex:i][@"expected_time"];
                NSString *voteType = [groups objectAtIndex:i][@"vote_type"];
                NSString *voteid = [groups objectAtIndex:i][@"vote_id"];
                NSNumber *groupid = [groups objectAtIndex:i][@"group_id"];
                NSString *winnerRestID = [groups objectAtIndex:i][@"winner_restaurant_id"];
                
                UIImage *image;
                if (![facebookPicture isEqual:[NSNull null]]) {
                    NSURL *url = [NSURL URLWithString:facebookPicture];
                    NSData *data = [NSData dataWithContentsOfURL:url];
                    image = [UIImage imageWithData:data];
                }
                else
                    image = [UIImage imageNamed:@"bae2.jpg"];
                [hostImages addObject:image];
                
                lobby.facebookPic = facebookPicture;
                lobby.facebookId = facebookId;
                lobby.facebookName = facebookName;
                lobby.winnerRestID = winnerRestID;
                lobby.expirationTime = expectedDate;
                lobby.voteType = voteType;
                lobby.voteid = voteid;
                lobby.groupid = groupid;
                [lobbies addObject:lobby];
                
                [self.tableView reloadData];
            }
            
            /*NSArray *sortedArray = [lobbies sortedArrayUsingSelector:@selector(compare:)];
            lobbies = [NSMutableArray arrayWithArray:sortedArray];
            for (int i =0; i < lobbies.count; i++) {
                NSLog(@"lobbie vote id : %@", [[lobbies objectAtIndex:i] voteid]);
            }*/
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return lobbies.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 200.0;
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"HootGroupCell";
    
    HootGroupCell *cell = (HootGroupCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"HootGroupCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    HootLobby *chosenLobby = (HootLobby *)lobbies[indexPath.row];
    NSLog(@"chosen lobby is :::::: %@", chosenLobby);
    cell.whereLabel.text = @"Chipotle"; //winner restaurant
    cell.backgroundImage.image = [UIImage imageNamed:@"chipotle.jpg"]; //winner restaurant pic
<<<<<<< HEAD
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //NSDate *atTime = [NSDate*]chosenLobby.expirationTime;
    [dateFormatter setDateFormat:@"HH:mm a"];
    NSString *formattedWhenTime = [dateFormatter stringFromDate:chosenLobby.expirationTime];
    NSLog(@"at time :%@", chosenLobby.expirationTime);
    cell.whenLabel.text = [NSString stringWithFormat:@"%@", formattedWhenTime];
=======

    //when isn't working :(
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *formattedWhenTime = [dateFormatter stringFromDate:chosenLobby.expirationTime];
    cell.whenLabel.text = [NSString stringWithFormat:@"%@", formattedWhenTime];
    

>>>>>>> 946c3583a90d2eaee61399cd719b94c98a7cd222
    cell.titleLabel.text = chosenLobby.voteType;
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ invited you", chosenLobby.facebookName];
    cell.friendsImage.image = hostImages[indexPath.row];
    //cell.hostImage.image = hostImages[indexPath.row];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"index path is: %@", lobbies[indexPath.row]);
    chosenHoot = (HootLobby *)lobbies[indexPath.row];

    [self performSegueWithIdentifier:@"maintosummary" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"maintosummary"])
    {
        SummaryViewController *vc = [segue destinationViewController];
        vc.loaded = YES;
        NSLog(@"the chosen group id is :%@", chosenHoot.groupid);
        NSLog(@"the chosen vote id is :%@", chosenHoot.voteid);
        [vc initWithHootLobby:chosenHoot];
    }
}

@end
