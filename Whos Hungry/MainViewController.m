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
#import <FacebookSDK/FacebookSDK.h>

static NSString * const BaseURLString = @"http://54.215.240.73:3000/";

@interface MainViewController () {
    NSMutableArray *lobbies;
    NSMutableArray *hostImages;
}

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    lobbies = [NSMutableArray new];
    hostImages = [NSMutableArray new];
    [self getGroups];
}

-(void) getGroups {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{@"user_id": @"10154793475270002"};
    [manager POST:[NSString stringWithFormat:@"%@apis/show_lobby_friend", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseData) {
        NSLog(@"JSON: %@", responseData);
        NSDictionary *data = responseData;
        if (data) {
            NSArray *groups = data[@"lobbies"];
            NSLog(@"found sooooo many groups: %li", groups.count);
            for (int i = 0; i < groups.count; i++) {
                HootLobby *lobby = [[HootLobby alloc] init];
                NSString *facebookId = [groups objectAtIndex:i][@"admin_user"];
                __block NSString *facebookName;
                if (facebookId) {
                    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", facebookId]];
                    NSData *data = [NSData dataWithContentsOfURL:url];
                    UIImage *image = [UIImage imageWithData:data];
                    [hostImages addObject:image];
                }
                NSLog(@"ost immmagier:  %li", hostImages.count);
                NSDate *expectedDate = [groups objectAtIndex:i][@"expected_time"];
                NSString *voteType = [groups objectAtIndex:i][@"vote_type"];
                lobby.facebookId = facebookId;
                lobby.facebookName = facebookName;
                lobby.expirationTime = expectedDate;
                lobby.voteType = voteType;
                [lobbies addObject:lobby];
            }
            [self.tableView reloadData];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

/*
 
 
 if (FBSession.activeSession.isOpen)
 {
 [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
 facebookName = result[@"name"];
 NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", result[@"id"]]];
 UIImage *facebookImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:pictureURL]];
 [hostImages addObject:facebookImage];
 }];
 
 }*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return lobbies.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 200;
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
    cell.whereLabel.text = @"Chipotle";
    cell.whenLabel.text = [NSString stringWithFormat:@"7:3%li", (long)indexPath.row];
    cell.titleLabel.text = chosenLobby.voteType;
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ invited you ;)", chosenLobby.facebookName];
    cell.backgroundImage.image = [UIImage imageNamed:@"chipotle.JPG"];
    cell.friendsImage.image = hostImages[indexPath.row];
    //cell.hostImage.image = hostImages[indexPath.row];
    //NSLog(@"cell isi :%@ ", cell);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"index path is: %@", lobbies[indexPath.row]);
}

@end
