//
//  SummaryViewController.m
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import "SummaryViewController.h"
#import "UIImage+Resize.h"
#import "RSVPFriendsTableViewCell.h"
#import "AFNetworking.h"
#import "AFHTTPRequestOperation.h"

#define LOBBY_KEY  @"currentlobby"
static NSString * const BaseURLString = @"http://54.215.240.73:3000/";
#define GOOGLE_API_KEY @"AIzaSyAdB2MtdRCGDZNfIcd-uR22hkmCmniA6Oc"
#define GOOGLE_API_KEY_TWO @"AIzaSyBBQSs-ALwZ3Za7nioFPYXsByMDsMFq-68"
#define GOOGLE_API_KEY_THREE @"AIzaSyA6gixyCg9D-9nEJ8q7PQJiJ9Nk5LzcltI"



@interface SummaryViewController (){
    CLLocationCoordinate2D restaurantCoor;
    int votedIndex;
    NSString *groupid;
    NSString *voteid;
}

@end

@implementation SummaryViewController

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        
    }
    return self;
}

-(void)initFromGroupID:(NSString *)gid andVoteID:(NSString *)vid {
    /*groupid = gid;
    voteid = vid;
    
    _currentLobby = [HootLobby new];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{@"vote_id": voteid};
    [manager POST:[NSString stringWithFormat:@"%@apis/show_single_vote", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        NSDictionary *results = (NSDictionary *)responseObject;
        NSArray *choices = results[@"choices"];
        for (int i = 0; i < choices.count; i++) {
            NSDictionary *currentRest = choices[i];
            [_currentLobby.placesIdArray addObject:currentRest[@"restaurant_id"]];
        }
        
        //[self loadSummary];
        //[_restaurantTable reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];*/
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!_loaded) {
    _allPlaces = [NSMutableArray new];
    _indexPathArray = [NSMutableArray new];
    //_restaurantTable = [UITableView new];
    _currentLobby = [HootLobby new];
    _currentLobby = [self loadCustomObjectWithKey:LOBBY_KEY];

    [self.friendsGoingTable registerNib:[UINib nibWithNibName:@"RSVPFriendsTableViewCell" bundle:nil] forCellReuseIdentifier:@"MyCustomCell"];
    self.friendsGoingTable.delegate = self;
    self.friendsGoingTable.dataSource = self;
    self.friendsGoingTable.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(makeVote:)
                                                 name:@"MakeVote"
                                               object:nil];
    
    self.mapView.hidden = YES;
    
    if (self.mapView.hidden == NO) {
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
    
    //HootLobby doesn't exist
    if (!_currentLobby) {
        NSLog(@"Current Lobby is empty");
        _currentLobby = [HootLobby new];
    }
    //HootLobby exists
    else{
        NSLog(@"Current Lobby has DATA!");
        NSLog(@"%@", _currentLobby);
        [self createAPIGroup];
        
        //[self loadSummary];
        //NSLog(@"%@", _currentLobby);
        [_restaurantTable reloadData];
    }
    }
}

-(void) makeVote:(NSNotification *)note {
    NSLog(@"making vote!!" );
    
    UpDownVoteView *sender;
    NSDictionary *theData = [note userInfo];
    if (theData != nil) {
        sender = (UpDownVoteView *)[theData objectForKey:@"sender"];
    }
    
    //user_id : <facebook_id>
    //group_id : <group_id>
    //choice : <id of restaurant>
    //status :  <status “+1”, “0”, “-1”>
    
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    if (username != nil) {
        username = @"";
    }
    if (groupid == nil) {
        groupid = [[NSUserDefaults standardUserDefaults] stringForKey:@"groupid"];
        if (groupid != nil) {
            groupid = @"";
        }
    }
    
    NSLog(@"restaurant list ids: %@", _currentLobby.placesIdArray);
    NSLog(@"voted restaurant id : %@", _currentLobby.placesIdArray[sender.index]);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{
                             @"user_id": username,
                             @"group_id":groupid,
                             @"choice" : _currentLobby.placesIdArray[sender.index],
                             @"status" : sender.status};
    [manager POST:[NSString stringWithFormat:@"%@apis/make_vote", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
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
                             //@"timeleft" : @(minsLeft),
                             //@"expiration date" : _currentLobby.expirationTime,
                             @"invitations" : facebookString};
    
    [manager POST:[NSString stringWithFormat:@"%@apis/create_group", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        NSDictionary *results = (NSDictionary *)responseObject;
        NSString *groupID = results[@"group_id"];
        if (groupID != nil) {
            [[NSUserDefaults standardUserDefaults] setObject:groupID forKey:@"groupid"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
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
    
    NSDate *startDate = [NSDate new];
    NSDate *endDate = _currentLobby.expirationTime;
    NSCalendar *gregorian = [[NSCalendar alloc]initWithCalendarIdentifier:NSGregorianCalendar];
    unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit;
    NSDateComponents *components = [gregorian components:unitFlags fromDate:startDate
                                                  toDate:endDate options:0];
    NSInteger minsLeft = [components minute];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{@"user_id": _currentLobby.facebookId,
                             @"group_id": groupId,
                             @"vote_type": _currentLobby.voteType,
                             @"expiration_time_number": @(minsLeft),
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
    NSLog(@"placcce: %@", place);
    
    [_allPlaces addObject:place];
    if (_allPlaces.count == _currentLobby.placesIdArray.count) {
        [self loadRestaurantNames];
        [_restaurantTable reloadData];
    }
    //NSLog(@"places is %@",place);
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([tableView isEqual:self.restaurantTable]) {
        return _currentLobby.placesIdArray.count;
    }
    
    else {
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.restaurantTable]) {
        return 100;
    } else {
        return 75;
    }
}


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"chosen: %li", indexPath.row);
    
    votedIndex = (int)indexPath.row;
}



#pragma mark - UIScrollViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isEqual:self.restaurantTable]) {
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
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.index = (int)indexPath.row;
        }
        
        return cell;
    }
    else {
        static NSString *cellIdentifier = @"MyCustomCell";
        
        RSVPFriendsTableViewCell *cell = (RSVPFriendsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        
        cell.leftUtilityButtons = [self leftButtons];
        cell.rightUtilityButtons = [self rightButtons];
        cell.delegate = self;
        
        return cell;
    }
    
}

- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                title:@"More"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Delete"];
    
    return rightUtilityButtons;
}

- (NSArray *)leftButtons
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.07 green:0.75f blue:0.16f alpha:1.0]
                                                icon:[UIImage imageNamed:@"check.png"]];
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188f alpha:1.0]
                                                icon:[UIImage imageNamed:@"cross.png"]];
    
    return leftUtilityButtons;
}

// Set row height on an individual basis

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    return [self rowHeightForIndexPath:indexPath];
//}
//
//- (CGFloat)rowHeightForIndexPath:(NSIndexPath *)indexPath {
//    return ([indexPath row] * 10) + 60;
//}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Set background color of cell here if you don't want default white
}

#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state
{
    switch (state) {
        case 0:
            NSLog(@"utility buttons closed");
            break;
        case 1:
            NSLog(@"left utility buttons open");
            break;
        case 2:
            NSLog(@"right utility buttons open");
            break;
        default:
            break;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            NSLog(@"RVSP YES was pressed");
            break;
        case 1:
            NSLog(@"RSVP NO was pressed");
            break;
        default:
            break;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
        {
            NSLog(@"More button was pressed");
            UIAlertView *alertTest = [[UIAlertView alloc] initWithTitle:@"Hello" message:@"More more more" delegate:nil cancelButtonTitle:@"cancel" otherButtonTitles: nil];
            [alertTest show];
            
            [cell hideUtilityButtonsAnimated:YES];
            break;
        }
        case 1:
        {
            // Delete button was pressed
            /*NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            
            [_testArray[cellIndexPath.section] removeObjectAtIndex:cellIndexPath.row];
            [self.tableView deleteRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationLeft];*/
            break;
        }
        default:
            break;
    }
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
{
    // allow just one cell's utility button to be open at once
    return YES;
}

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state
{
    switch (state) {
        case 1:
            // set to NO to disable all left utility buttons appearing
            return YES;
            break;
        case 2:
            // set to NO to disable all right utility buttons appearing
            return NO;
            break;
        default:
            break;
    }
    
    return YES;
}

@end