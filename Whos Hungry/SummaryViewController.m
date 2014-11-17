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
#define GOOGLE_API_KEY @"AIzaSyAdB2MtdRCGDZNfIcd-uR22hkmCmniA6Oc"
#define GOOGLE_API_KEY_TWO @"AIzaSyBBQSs-ALwZ3Za7nioFPYXsByMDsMFq-68"
#define GOOGLE_API_KEY_THREE @"AIzaSyA6gixyCg9D-9nEJ8q7PQJiJ9Nk5LzcltI"



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
    _allPlaces = [NSMutableArray new];
    _indexPathArray = [NSMutableArray new];
    //_restaurantTable = [UITableView new];
    _currentLobby = [HootLobby new];
    _currentLobby = [self loadCustomObjectWithKey:LOBBY_KEY];
    
    //HootLobby doesn't exist
    if (!_currentLobby) {
        NSLog(@"Current Lobby is empty");
        _currentLobby = [HootLobby new];
    }
    //HootLobby exists
    else{
        NSLog(@"Current Lobby has DATA!");
        NSLog(@"%@", _currentLobby);
        //[self createAPIGroup];
        [self loadSummary];
        //[_restaurantTable reloadData];
        
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


- (IBAction)goHome:(id)sender {
    [locationManager stopUpdatingLocation];
}

#pragma mark - Location methods

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
    _currentLocation = newLocation;
    [locationManager stopUpdatingLocation];

    
}


#pragma mark - NSUserDefaults methods

-(void)saveCustomObject:(HootLobby *)object
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSData *myEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
    [prefs setObject:myEncodedObject forKey:LOBBY_KEY];
}

-(HootLobby *)loadCustomObjectWithKey:(NSString*)key
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSData *myEncodedObject = [prefs objectForKey:key];
    HootLobby *obj = (HootLobby *)[NSKeyedUnarchiver unarchiveObjectWithData: myEncodedObject];
    return obj;
}

#pragma mark - AWS API methods

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

- (void)loadSummary{
    //Goes through all place_id's and stores them in _allPlaces array
    for (int i = 0; i < _currentLobby.placesIdArray.count; i++) {
        [self queryGooglePlacesWithPlaceId:_currentLobby.placesIdArray[i]];
    }
}

-(void)loadRestaurantNames{
    //[_restaurantTable reloadData];
    for (int j = 0; j < _indexPathArray.count; j++) {
        UpDownVoteView *tempCell = [UpDownVoteView new];
        NSIndexPath *tempIndex = _indexPathArray[j];
        tempCell = (UpDownVoteView*)[_restaurantTable cellForRowAtIndexPath:tempIndex];
        //UpDownVoteView *cell = [self.restaurantTable cellForRowAtIndexPath:_indexPathArray[j]];
        tempCell.restaurantLabel.text = _allPlaces[j][@"name"];
    }
}

-(void) queryGooglePlacesWithPlaceId:(NSString*)placeId{
    NSLog(@"going through google places!!!");
    NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/details/json?placeid=%@&key=%@",placeId,GOOGLE_API_KEY_THREE];
    NSURL *googleRequestURL=[NSURL URLWithString:url];
    
    // Retrieve the results of the URL.
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL: googleRequestURL];
        NSLog(@"data found is :%@", data);
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
    });
}

-(void)fetchedData:(NSData *)responseData {
    //parse out the json data
    NSLog(@"fetched data is @!!:!!");
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          
                          options:kNilOptions
                          error:&error];
    
    
    //NSLog(@"JSON is %@",json);
    //The results from Google will be an array obtained from the NSDictionary object with the key "results".
    NSArray* place = [json objectForKey:@"result"];
    
    [_allPlaces addObject:place];
    if (_allPlaces.count == _currentLobby.placesIdArray.count) {
        //[self loadRestaurantNames];
        [_restaurantTable reloadData];
    }
    //NSLog(@"places is %@",place);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _currentLobby.placesIdArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"UpDownVoteView";
    
    UpDownVoteView *cell = (UpDownVoteView *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"updownvote" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    [cell layoutIfNeeded];
    [_indexPathArray addObject:indexPath];
    if (_allPlaces.count == _currentLobby.placesIdArray.count) {
        CLLocation* placeLocation = [[CLLocation alloc] initWithLatitude:(CLLocationDegrees)[_allPlaces[indexPath.row][@"geometry"][@"location"][@"lat"] doubleValue] longitude:(CLLocationDegrees)[_allPlaces[indexPath.row][@"geometry"][@"location"][@"lng"] doubleValue]];
        float distance = [placeLocation distanceFromLocation:_currentLocation] / 1609.0;
        cell.distanceLabel.text = [NSString stringWithFormat:@"%1.2f mi.",distance];
        cell.restaurantLabel.text = _allPlaces[indexPath.row][@"name"];
        
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"index path is: ");
}


@end
