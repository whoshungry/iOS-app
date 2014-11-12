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

static NSString * const BaseURLString = @"http://54.215.240.73:3000/";

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    //[self testAPIGroup];
    [self testAPIRegister];
    
}

-(void) testAPIRegister {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{
                             @"username": @"Gilad Oved",
                             @"facebook_id" : @"10205081533016987",
                             @"expiration_date": @"2016-10-31T23:58:49.846Z",
                             @"access_token": @"CAALLA0rdSeABAAWZBGe0J91YCm2dZBgCwtnrMKvZC0LxCO7kojwNX4LBH0E3fIaAtacFfGgemBYywyabMGMYEe7TIoNLR4gQAOxO3AzWQBTASJ9jxOxd8pN2L8HCVHrZCDfn1QZAhtmsmWM5ozztcC60oQNHOzZBMH1snWbrFQ8cw7UszUmJXwTl4xQY3o2NCB2v30w1gHR6t5UoKkZBvum4Xa5cbKSSirjpXRZALHQGJkrZAGjT8YT8v"};
    [manager POST:[NSString stringWithFormat:@"%@apis/register", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

-(void) testAPIGroup {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{@"user_id": @"10205081533016987",
                             @"invitations" : @"10154793475270002,10154793475270003,10154793475270004"};
    [manager POST:[NSString stringWithFormat:@"%@create_group", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 8;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 248;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"HootGroupCell";
    
    HootGroupCell *cell = (HootGroupCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"HootGroupCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    cell.whereLabel.text = @"Chipotle";
    cell.whenLabel.text = [NSString stringWithFormat:@"7:3%li", (long)indexPath.row];
    cell.titleLabel.text = @"Dinner";
    cell.subtitleLabel.text = @"Jennifer Aniston invited you ;)";
    cell.backgroundImage.image = [UIImage imageNamed:@"chipotle.JPG"];
    cell.friendsImage.image = [UIImage imageNamed:@"friendsicon"];
    cell.hostImage.image = [UIImage imageNamed:@"jennifer.jpg"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"index path is: ");
}

@end
