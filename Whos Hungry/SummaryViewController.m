//
//  SummaryViewController.m
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import "SummaryViewController.h"
#import "UIImage+Resize.h"

#define LOBBY_KEY  @"currentlobby"
static NSString * const BaseURLString = @"http://54.215.240.73:3000/";

@interface SummaryViewController (){
    CLLocationCoordinate2D restaurantCoor;
}

@end

@implementation SummaryViewController

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _currentLobby = [HootLobby new];
    _currentLobby = [self loadCustomObjectWithKey:LOBBY_KEY];
    if (!_currentLobby) {
        NSLog(@"Current Lobby is empty");
        _currentLobby = [HootLobby new];
    }
    else{
        NSLog(@"Current Lobby has DATA!");
        NSLog(@"%@", _currentLobby);
        [self createAPIGroup];
        
    }
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [locationManager requestWhenInUseAuthorization];
    
    self.mapView.delegate = self;
    
    CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorized ||
        authorizationStatus == kCLAuthorizationStatusAuthorizedAlways ||
        authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        NSLog(@"we in here");
        self.mapView.showsUserLocation = YES;
        [locationManager startUpdatingLocation];
        
        restaurantCoor = CLLocationCoordinate2DMake(30.285647, -97.742081);
        MKPointAnnotation *restaurantPin = [[MKPointAnnotation alloc] init];
        restaurantPin.coordinate = restaurantCoor;
        NSLog(@"restaurant coordinates %f, %f", restaurantCoor.latitude, restaurantCoor.longitude);
        restaurantPin.title = @"Chipotle!";
        [self.mapView addAnnotation:restaurantPin];
    } else {
        NSLog(@"or nah");
        [self viewDidLoad];
    }
}


- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    NSLog(@"updated! %@", userLocation);
    CLLocation *user = [[CLLocation alloc] initWithLatitude:userLocation.coordinate.latitude longitude:userLocation.coordinate.longitude];
    CLLocation *locale = [[CLLocation alloc] initWithLatitude:restaurantCoor.latitude longitude:restaurantCoor.longitude];
    CLLocationDistance distance = [user distanceFromLocation:locale];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(restaurantCoor, distance*2, distance*2);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSLog(@"New Location %f %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    [locationManager stopUpdatingLocation];

    
}


- (IBAction)goHome:(id)sender {
    [locationManager stopUpdatingLocation];
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

-(void) createAPIGroup {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString* facebookString = @"";
    for (int i = 0; i < _currentLobby.facebookbInvitatitions.count; i++) {
        if (i != _currentLobby.facebookbInvitatitions.count - 1) {
            facebookString = [facebookString stringByAppendingString:_currentLobby.facebookbInvitatitions[i]];
            facebookString = [facebookString stringByAppendingString:@","];
        }
        else{
            facebookString = [facebookString stringByAppendingString:_currentLobby.facebookbInvitatitions[i]];
            
        }
    }
    NSLog(@"user_id is %@", _currentLobby.facebookId);
    NSLog(@"invitations is %@", facebookString);
    
    NSDictionary *params = @{@"user_id": _currentLobby.facebookId,
                             @"invitations" : facebookString};
    [manager POST:[NSString stringWithFormat:@"%@apis/create_group", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        [self createAPIVoteWithGroupId:responseObject[@"group_id"]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void) createAPIVoteWithGroupId:(NSString*)groupId{
    NSString* restaurantString = @"";
    for (int i = 0; i < _currentLobby.placesIdArray.count; i++) {
        if (i != _currentLobby.placesIdArray.count - 1) {
            restaurantString = [restaurantString stringByAppendingString:_currentLobby.placesIdArray[i]];
            restaurantString = [restaurantString stringByAppendingString:@","];
        }
        else{
            restaurantString = [restaurantString stringByAppendingString:_currentLobby.placesIdArray[i]];
            
        }
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{@"user_id": _currentLobby.facebookId,
                             @"group_id": groupId,
                             @"vote_type": _currentLobby.voteType,
                             @"expiration_time": _currentLobby.expirationTime,
                             @"restaurants": restaurantString};
    [manager POST:[NSString stringWithFormat:@"%@apis/create_vote", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
