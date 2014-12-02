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
#define GOOGLE_API_KEY_FOUR @"AIzaSyDF0gj_1xGofM8BriMNH-uHbNYBVjI3g70"


@interface SummaryViewController (){
    CLLocationCoordinate2D restaurantCoor;
    int votedIndex;
    //NSString *groupid;
    NSString *voteid;
    NSMutableArray *placesCountArray;
    NSTimer *theTimer;
}

@end

@implementation SummaryViewController

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        
    }
    return self;
}

-(void)initWithHootLobby:(HootLobby *)hootlobby {
    _currentLobby = hootlobby;
    NSMutableArray *placesIdArray = [NSMutableArray new];
    NSMutableArray *placesNamesArray = [NSMutableArray new];
    NSMutableArray *placesPicsArray = [NSMutableArray new];
    NSMutableArray *placesXArray = [NSMutableArray new];
    NSMutableArray *placesYArray = [NSMutableArray new];
    
    placesCountArray = [NSMutableArray new];
    _loaded = YES;
    _isSummary = YES;
    self.whenTimeLbl.text = @"okay man";
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSLog(@"vote id of show single vote is %@", _currentLobby.voteid);
    NSDictionary *params = @{@"vote_id": _currentLobby.voteid};
    [manager POST:[NSString stringWithFormat:@"%@apis/show_single_vote", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *results = (NSDictionary *)responseObject;
        NSArray *choices = results[@"choices"];
        NSLog(@"response count: %lu", (unsigned long)choices.count);
        NSLog(@"response objectcttctctct: %@", choices);
        for (int i = 0; i < choices.count; i++) {
            NSDictionary *currentRest = choices[i];
            [placesIdArray addObject:currentRest[@"restaurant_id"]];
            [placesNamesArray addObject:currentRest[@"restaurant_name"]];
            [placesPicsArray addObject:currentRest[@"restaurant_picture"]];
            [placesXArray addObject:currentRest[@"restaurant_location_x"]];
            [placesYArray addObject:currentRest[@"restaurant_location_y"]];
            [placesCountArray addObject:currentRest[@"count"]];
        }
        
        _currentLobby.placesIdArray = placesIdArray;
        _currentLobby.placesNamesArray = placesNamesArray;
        _currentLobby.placesPicsArray = placesPicsArray;
        _currentLobby.placesXArray = placesXArray;
        _currentLobby.placesYArray = placesYArray;
        
        NSLog(@"current lobby ids rrrr: %@", _currentLobby.placesIdArray);
        NSLog(@"current lobby names rrrr: %@", _currentLobby.placesNamesArray);
        NSLog(@"current lobby pics rrrr: %@", _currentLobby.placesPicsArray);
        
        [self setSummaryTitle];
        [_restaurantTable reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)viewDidLoad {
    if (!_isSummary) {
        [super viewDidLoad];
        if (!_loaded) {
            _indexPathArray = [NSMutableArray new];
            
            [self.friendsGoingTable registerNib:[UINib nibWithNibName:@"RSVPFriendsTableViewCell" bundle:nil] forCellReuseIdentifier:@"MyCustomCell"];
            self.friendsGoingTable.delegate = self;
            self.friendsGoingTable.dataSource = self;
            self.friendsGoingTable.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(makeVote:)
                                                         name:@"MakeVote"
                                                       object:nil];
            
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
                NSLog(@"currnet lobby is %@", _currentLobby);
                [self createAPIGroup];
            }
            
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
    
    NSLog(@"restaurant list ids: %@", _currentLobby.placesIdArray);
    NSLog(@"voted restaurant id : %@", _currentLobby.placesIdArray[sender.index]);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{
                             @"user_id": _currentLobby.facebookId,
                             @"group_id":_currentLobby.groupid,
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
    NSLog(@"current lobby is is is is %@", _currentLobby);
    
    NSDictionary *params = @{@"user_id": _currentLobby.facebookId,
                             @"invitations" : facebookString};
    
    [manager POST:[NSString stringWithFormat:@"%@apis/create_group", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *results = (NSDictionary *)responseObject;
        _currentLobby.groupid = results[@"group_id"];
        NSLog(@"group id is :%@", _currentLobby.groupid);
        NSLog(@"create group is :%@", responseObject);
        [self createAPIVoteWithGroupId:_currentLobby.groupid];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void) createAPIVoteWithGroupId:(NSNumber*)groupId{
    NSString* restaurantIds = @"";
    NSString* restaurantNames = @"";
    NSString* restaurantPics = @"";
    NSString* restaurantX = @"";
    NSString* restaurantY = @"";

    for (int i = 0; i < _currentLobby.placesIdArray.count; i++) {
        if (i != _currentLobby.placesIdArray.count - 1) {
            restaurantIds = [restaurantIds stringByAppendingString:_currentLobby.placesIdArray[i]];
            restaurantIds = [restaurantIds stringByAppendingString:@","];
            
            restaurantNames = [restaurantNames stringByAppendingString:_currentLobby.placesNamesArray[i]];
            restaurantNames = [restaurantNames stringByAppendingString:@","];
            
            restaurantPics = [restaurantPics stringByAppendingString:_currentLobby.placesPicsArray[i]];
            restaurantPics = [restaurantPics stringByAppendingString:@","];
            
            restaurantX = [restaurantX stringByAppendingString:(NSString *)[_currentLobby.placesXArray[i]stringValue]];
            restaurantX = [restaurantX stringByAppendingString:@","];
            
            restaurantY = [restaurantY stringByAppendingString:(NSString *)[_currentLobby.placesYArray[i]stringValue]];
            restaurantY = [restaurantY stringByAppendingString:@","];
        }
        else{
            restaurantIds = [restaurantIds stringByAppendingString:_currentLobby.placesIdArray[i]];
            restaurantNames = [restaurantNames stringByAppendingString:_currentLobby.placesNamesArray[i]];
            restaurantPics = [restaurantPics stringByAppendingString:_currentLobby.placesPicsArray[i]];
            restaurantX = [restaurantX stringByAppendingString:(NSString *)[_currentLobby.placesXArray[i]stringValue]];
            restaurantY = [restaurantY stringByAppendingString:(NSString *)[_currentLobby.placesYArray[i]stringValue]];
        }
    }
    
    NSLog(@"rest ids: %@", restaurantIds);
    NSLog(@"rest names: %@", restaurantNames);
    NSLog(@"rest pics: %@", restaurantPics);
    NSLog(@"rest x: %@", restaurantX);
    NSLog(@"rest y: %@", restaurantY);
    
    NSDate *startDate = [NSDate new];
    NSDate *endDate = _currentLobby.expirationTime;
    NSCalendar *gregorian = [[NSCalendar alloc]initWithCalendarIdentifier:NSGregorianCalendar];
    unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit;
    NSDateComponents *components = [gregorian components:unitFlags fromDate:startDate
                                                  toDate:endDate options:0];
    NSInteger minsLeft = [components minute];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    /*user_id : <facebook_id>
    group_id : <group_id>
    vote_type : <lunch, dinner ..> # lunch, dinner, coffee, beer
    expiration_time : <absolute expiration time>
    expiration_time_number : <relative expiration time : minute>
    ex. 15, 30, 45, 60, 120 ...
    restaurant_ids : <string of ids of restaurants>
    ex. “12341234,12312341234”
    restaurant_names : <stringof names>
    restaurant_pics : <string of pic_urls>
    restaurant_locations_x : strings of x
    restaurant_locations_y : strings of y*/
    
    NSDictionary *params = @{@"user_id": _currentLobby.facebookId,
                             @"group_id": groupId,
                             @"vote_type": _currentLobby.voteType,
                             @"expiration_time_number": @(minsLeft),
                             @"expiration_time": _currentLobby.expirationTime,
                             @"restaurant_ids": restaurantIds,
                             @"restaurant_names": restaurantNames,
                             @"restaurant_pictures":restaurantPics,
                             @"restaurant_locations_x":restaurantX,
                             @"restaurant_locations_y":restaurantY
                             };
    NSLog(@"params for create vote :%@", params);
    [manager POST:[NSString stringWithFormat:@"%@apis/create_vote", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"create vote is :%@", responseObject);
        [self setSummaryTitle];
        [self.restaurantTable reloadData];
        //[self loadSummary];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

-(void)setSummaryTitle {
    NSString *englishVoteType;
    if ([_currentLobby.voteType isEqualToString:@"cafe"]) {
        englishVoteType = @"grab coffee";
    } else if ([_currentLobby.voteType isEqualToString:@"drinks"]){
        englishVoteType = @"get some drinks";
    } else {
        englishVoteType = [NSString stringWithFormat:@"eat %@", _currentLobby.voteType];
    }
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *normalAtTime = [dateFormatter stringFromDate:_currentLobby.expirationTime];
    
    theTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:theTimer forMode:NSRunLoopCommonModes];
    
    self.summaryTitleLbl.text = [NSString stringWithFormat:@"%@ wants to %@ today at %@", _currentLobby.facebookName, englishVoteType, normalAtTime];
}

-(void)updateTime {
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSUInteger unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSCalendarUnit unitCal = (NSCalendarUnit)unitFlags;
    
    NSDateComponents *components = [gregorianCalendar components:unitCal
                                                        fromDate:[NSDate new]
                                                          toDate:_currentLobby.expirationTime
                                                         options:0];
    NSInteger hoursLeft = components.hour;
    NSInteger minutesLeft = components.minute + 1; //a bug, i'm not sure why...

    NSLog(@"time left is :%ld hrs and %ld mins", hoursLeft, minutesLeft);

    self.whenTimeLbl.text = [NSString stringWithFormat:@"%ldhr %ld min left", (long)hoursLeft, minutesLeft];
    
    //check if over...
    if (hoursLeft == 0 && minutesLeft == 0) {
        NSLog(@"donnnneee!!");
        [theTimer invalidate];
        theTimer = nil;
        
        self.active = NO;
        self.mapView.hidden = NO;
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
}

/*- (void)loadSummary{
    //Goes through all place_id's and stores them in _allPlaces array
    for (int i = 0; i < _currentLobby.placesIdArray.count; i++) {
        [self queryGooglePlacesWithPlaceId:_currentLobby.placesIdArray[i]];
    }
}

-(void)loadRestaurantNames{
    NSLog(@"count is %li", (unsigned long)_allPlaces.count);
    for (int j = 0; j < _allPlaces.count; j++) {
        UpDownVoteView *tempCell = [UpDownVoteView new];
        NSIndexPath *tempIndex = _indexPathArray[j];
        tempCell = (UpDownVoteView*)[_restaurantTable cellForRowAtIndexPath:tempIndex];
        //UpDownVoteView *cell = [self.restaurantTable cellForRowAtIndexPath:_indexPathArray[j]];

        tempCell.restaurantLabel.text = _allPlaces[j][@"name"];
    }
}

-(void) queryGooglePlacesWithPlaceId:(NSString*)placeId{
    NSLog(@"going through google places!!!");
    NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/details/json?placeid=%@&key=%@",placeId,GOOGLE_API_KEY];
    NSURL *googleRequestURL=[NSURL URLWithString:url];
    
    // Retrieve the results of the URL.
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL: googleRequestURL];
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
    });
}

-(void)fetchedData:(NSData *)responseData {
    //parse out the json data
    NSLog(@"fetched data is @!!:!! %@: ", responseData);
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          
                          options:kNilOptions
                          error:&error];
    NSLog(@"placccccccce: %@", json);
    
    NSLog(@"ferrror %@ ", error);

    //NSLog(@"JSON is %@",json);
    //The results from Google will be an array obtained from the NSDictionary object with the key "results".
    NSArray* place = [json objectForKey:@"result"];
    NSLog(@"placcce: %@", place);
    
    [_allPlaces addObject:place];
    if (_allPlaces.count == _currentLobby.placesIdArray.count) {
        [self loadRestaurantNames];
        //[_restaurantTable reloadData];
    }
    NSLog(@"places is %@",_allPlaces);
}*/

#pragma mark - Table View methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([tableView isEqual:self.restaurantTable]) {
        return _currentLobby.placesIdArray.count;
    }
    
    else {
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([tableView isEqual:self.restaurantTable]) {
        return 100;
    } else {
        return 75;
    }
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"chosen: %li", indexPath.row);
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
        if (_currentLobby && _currentLobby.placesIdArray.count > 0) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.index = (int)indexPath.row;
        }
        
        NSLog(@"ALL PLACES: %@", _allPlaces);
        NSLog(@"places %@", _currentLobby);
        
        if (!_loaded) {
            CLLocation *placeLocation = [[CLLocation alloc] initWithLatitude:(CLLocationDegrees)[_currentLobby.placesXArray[indexPath.row] doubleValue] longitude:(CLLocationDegrees)[_currentLobby.placesYArray[indexPath.row] doubleValue]];
            //CLLocation* placeLocation = [[CLLocation alloc] initWithLatitude:(CLLocationDegrees)[_allPlaces[indexPath.row][@"geometry"][@"location"][@"lat"] doubleValue] longitude:(CLLocationDegrees)[_allPlaces[indexPath.row][@"geometry"][@"location"][@"lng"] doubleValue]];
            float distance = [placeLocation distanceFromLocation:_currentLocation] / 1609.0;
            //float distance = 50.0f;
            cell.distanceLabel.text = [NSString stringWithFormat:@"%1.2f mi.",distance];
            cell.restaurantLabel.text = _currentLobby.placesNamesArray[indexPath.row];
        } else {
            CLLocation* placeLocation = [[CLLocation alloc] initWithLatitude:(CLLocationDegrees)[_currentLobby.placesXArray[indexPath.row] doubleValue] longitude:(CLLocationDegrees)[_currentLobby.placesYArray[indexPath.row] doubleValue]];
            float distance = [placeLocation distanceFromLocation:_currentLocation] / 1609.0;
            cell.distanceLabel.text = [NSString stringWithFormat:@"%1.2f mi.",distance];
            cell.restaurantLabel.text = _currentLobby.placesNamesArray[indexPath.row];
            cell.votes = (int)placesCountArray[indexPath.row];
            cell.voteLbl.text = [NSString stringWithFormat:@"%i", cell.votes];
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
            [self.friendsGoingTable setEditing:NO animated:NO];
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
    RSVPFriendsTableViewCell *theCell = (RSVPFriendsTableViewCell *)cell;
    NSIndexPath *path = [NSIndexPath indexPathWithIndex:index];
    switch (index) {
        case 0:
            NSLog(@"RVSP YES was pressed");
            theCell.arrow.image = [UIImage imageNamed:@"greenarrow.png"];
            theCell.backgroundColor = [UIColor greenColor];
            break;
        case 1:
            NSLog(@"RSVP NO was pressed");
            theCell.arrow.image = [UIImage imageNamed:@"redarrow.png"];
            theCell.backgroundColor = [UIColor redColor];
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