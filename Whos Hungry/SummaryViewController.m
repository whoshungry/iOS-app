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
    CLLocationCoordinate2D userCoor;
    int votedIndex;
    //NSString *groupid;
    NSString *voteid;
    UIImage *selfImage;
    NSMutableArray *placesCountArray;
    MKPointAnnotation *restaurantPin;
    BOOL viewload;
    BOOL votingDone;
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
    _currentLobby.voteid = hootlobby.voteid;
    NSMutableArray *placesIdArray = [NSMutableArray new];
    NSMutableArray *placesNamesArray = [NSMutableArray new];
    NSMutableArray *placesPicsArray = [NSMutableArray new];
    NSMutableArray *placesXArray = [NSMutableArray new];
    NSMutableArray *placesYArray = [NSMutableArray new];
    
    placesCountArray = [NSMutableArray new];
    _loaded = NO;
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [locationManager requestWhenInUseAuthorization];
    
    self.mapView.delegate = self;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSLog(@"vote id of show single vote is %@", _currentLobby.voteid);
    NSDictionary *params = @{@"vote_id": _currentLobby.voteid};
    [manager POST:[NSString stringWithFormat:@"%@apis/show_single_vote", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"responseObject!!: %@", responseObject);
        NSLog(@"responseObject!!: %@", responseObject[@"choices"]);
        //NSDictionary *results = (NSDictionary *)responseObject;
        id results = responseObject;
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
    [super viewDidLoad];
    
    if (viewload == NO) {
        if (FBSession.activeSession.isOpen)
        {
            [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me/picture?type=large&return_ssl_resources=1"]];
                selfImage = [UIImage imageWithImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:pictureURL]] scaledToSize:CGSizeMake(30.0, 30.0)];
            }];
        }
        
        _indexPathArray = [NSMutableArray new];
        
        [self.friendsGoingTable registerNib:[UINib nibWithNibName:@"RSVPFriendsTableViewCell" bundle:nil] forCellReuseIdentifier:@"MyCustomCell"];
        self.friendsGoingTable.delegate = self;
        self.friendsGoingTable.dataSource = self;
        self.friendsGoingTable.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
        
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
            //NSLog(@"currnet lobby is %@", _currentLobby);
            [self createAPIGroup];
        }
        viewload = YES;
    }
    
    //if (votingDone == NO) {
        self.theTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                    target:self
                                                  selector:@selector(updateTime:)
                                                  userInfo:nil
                                                   repeats:NO];
    //}
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
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
    [self.theTimer invalidate];
    self.theTimer = nil;
}

#pragma mark - Location methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    static NSString* AnnotationIdentifier = @"Annotation";
    MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
    
    if (!pinView) {
        MKPinAnnotationView *customPinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
        if (annotation == mapView.userLocation){
            if (selfImage != nil) {
                customPinView.image = [UIImage imageWithImage:selfImage scaledToSize:CGSizeMake(30.0, 30.0)];
            } else {
                customPinView.image = [UIImage imageWithImage:[UIImage imageNamed:@"jennifer.jpg"] scaledToSize:CGSizeMake(30.0, 30.0)];
            }
        }
        else{
            customPinView.image = [UIImage imageNamed:@"logosquare.png"];
            //customPinView.image = [UIImage imageNamed:@"mySomeOtherImage.png"];
        }
        customPinView.animatesDrop = NO;
        customPinView.canShowCallout = YES;
        return customPinView;
    } else {
        pinView.annotation = annotation;
    }
    
    return pinView;
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
    _currentLocation = newLocation;
    //[locationManager stopUpdatingLocation];
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
    //NSLog(@"current lobby is is is is %@", _currentLobby);
    
    NSDictionary *params = @{@"user_id": _currentLobby.facebookId,
                             @"invitations" : facebookString};
    
    [manager POST:[NSString stringWithFormat:@"%@apis/create_group", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *results = (NSDictionary *)responseObject;
        _currentLobby.groupid = results[@"group_id"];
        NSLog(@"group id is :%@", _currentLobby.groupid);
        NSLog(@"create group is :%@", responseObject);
        if (_currentLobby.groupid != nil)
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
            
            NSString *xstr = _currentLobby.placesXArray[i];
            NSNumber *xnum = [NSNumber numberWithFloat:[xstr floatValue]];
            restaurantX = [xnum stringValue];
            restaurantX = [restaurantX stringByAppendingString:@","];
            
            NSString *ystr = _currentLobby.placesYArray[i];
            NSNumber *ynum = [NSNumber numberWithFloat:[ystr floatValue]];
            restaurantY = [ynum stringValue];
            restaurantY = [restaurantY stringByAppendingString:@","];
        }
        else{
            restaurantIds = [restaurantIds stringByAppendingString:_currentLobby.placesIdArray[i]];
            restaurantNames = [restaurantNames stringByAppendingString:_currentLobby.placesNamesArray[i]];
            restaurantPics = [restaurantPics stringByAppendingString:_currentLobby.placesPicsArray[i]];
            NSString *xstr = _currentLobby.placesXArray[i];
            NSNumber *xnum = [NSNumber numberWithFloat:[xstr floatValue]];
            restaurantX = [restaurantX stringByAppendingString:[xnum stringValue]];
            NSString *ystr = _currentLobby.placesYArray[i];
            NSNumber *ynum = [NSNumber numberWithFloat:[ystr floatValue]];
            restaurantY = [restaurantY stringByAppendingString:[ynum stringValue]];
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
    
    if (endDate == nil) {
        endDate = [NSDate new];
    }
      NSDateComponents *components = [gregorian components:unitFlags fromDate:startDate
                                                  toDate:endDate options:0];
    NSInteger minsLeft = [components minute];
    
    NSLog(@"facebook id: %@",_currentLobby.facebookId);
    NSLog(@"group id: %@", groupId);
    NSLog(@"vote id: %@", _currentLobby.voteid);
    NSLog(@"expiratation time: %@",_currentLobby.expirationTime);
    
    
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
        NSDictionary *results = (NSDictionary *) responseObject;
        _currentLobby.voteid = results[@"vote_id"];
        NSLog(@"vote id assigned is :%@", _currentLobby.voteid);
        [self setSummaryTitle];
        [self.restaurantTable reloadData];
        //[self loadSummary];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

-(void)setSummaryTitle {
    NSString *englishVoteType;
    if ([@"cafe" isEqualToString:_currentLobby.voteType]) {
        englishVoteType = @"grab coffee";
    } else if ([@"drinks" isEqualToString:_currentLobby.voteType]) {
        englishVoteType = @"get some drinks";
    } else {
        englishVoteType = [NSString stringWithFormat:@"eat %@", _currentLobby.voteType];
    }
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *normalAtTime = [dateFormatter stringFromDate:_currentLobby.expirationTime];
    
    self.summaryTitleLbl.text = [NSString stringWithFormat:@"%@ wants to %@ today at %@", _currentLobby.facebookName, englishVoteType, normalAtTime];
}

- (IBAction)updateTime:(id)sender {
    NSInteger hoursLeft = 0;
    NSInteger minutesLeft = 0;

    //if ([[NSDate new] compare:_currentLobby.expirationTime] == NSOrderedDescending) {
    
    if (_currentLobby.expirationTime == nil)
        _currentLobby.expirationTime = [NSDate new];
    
        NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSUInteger unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
        NSDateComponents *components = [gregorianCalendar components:unitFlags
                                                            fromDate:[NSDate new]
                                                              toDate:_currentLobby.expirationTime
                                                             options:0];
        hoursLeft = components.hour;
        minutesLeft = components.minute + 0; //plus 1 to include the chosen time, plus 0 not t0
        
        NSLog(@"time left is :%ld hrs and %ld mins", (long)hoursLeft, (long)minutesLeft);
        
        self.whenTimeLbl.text = [NSString stringWithFormat:@"%ldhr %ld min left", (long)hoursLeft, (long)minutesLeft];
    //} else {
    //    self.whenTimeLbl.text = @"Lobby is closed!";
   // }

    //check if over...
    if (hoursLeft == 0 && minutesLeft <= 0) {
        NSLog(@"donnnneee!!");
        votingDone = YES;
        [self lobbyFinished];
        //[self performSelector:@selector(lobbyFinished) withObject:nil afterDelay:30.0];
    } else {
        [self performSelector:@selector(updateTime:) withObject:nil afterDelay:1.0];
    }
}

-(void) lobbyFinished {
   [self.theTimer invalidate];
    self.theTimer = nil;
    
    self.active = NO;
    self.mapView.hidden = NO;
    self.restaurantTable.hidden = YES;
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [locationManager requestWhenInUseAuthorization];
        [locationManager requestAlwaysAuthorization];
    }
    
    CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorized ||
        authorizationStatus == kCLAuthorizationStatusAuthorizedAlways ||
        authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        self.mapView.showsUserLocation = YES;
        [locationManager startUpdatingLocation];
        
    } else {
        NSLog(@"or nah");
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSLog(@"vote id of show single vote is %@", _currentLobby.voteid);
    NSDictionary *params = @{@"vote_id": _currentLobby.voteid};
    [manager POST:[NSString stringWithFormat:@"%@apis/show_single_vote", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *results = (NSDictionary *)responseObject;
        NSLog(@"results from FINISHED THING: %@", results);
        
        NSNumberFormatter * f = [NSNumberFormatter new];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        
        _currentLobby.winnerRestID = results[@"winner_restaurant_id"];
        _currentLobby.winnerRestName = results[@"winner_restaurant_name"];
        _currentLobby.winnerRestPic = results[@"winner_restaurant_picture"];
        _currentLobby.winnerRestX = [f numberFromString:(NSString *)results[@"winner_restaurant_location_x"]];
        _currentLobby.winnerRestY = [f numberFromString:(NSString *)results[@"winner_restaurant_location_y"]];

        NSLog(@"current lobby ids rrrr: %@", _currentLobby.winnerRestID);
        NSLog(@"current lobby names rrrr: %@", _currentLobby.winnerRestName);
        NSLog(@"current lobby pics rrrr: %@", _currentLobby.winnerRestPic);
        NSLog(@"current lobby x rrrr: %@", _currentLobby.winnerRestX);
        NSLog(@"current lobby y rrrr: %@", _currentLobby.winnerRestY);
        
        restaurantCoor = CLLocationCoordinate2DMake([_currentLobby.winnerRestX floatValue], [_currentLobby.winnerRestY floatValue]);
        restaurantPin = [[MKPointAnnotation alloc] init];
        restaurantPin.coordinate = restaurantCoor;
        NSLog(@"restaurant coordinates %f, %f", restaurantCoor.latitude, restaurantCoor.longitude);
        restaurantPin.title = _currentLobby.winnerRestName;
        [self.mapView addAnnotation:restaurantPin];
        
        NSLog(@"updated! %@", _currentLocation);
        CLLocation *user = [[CLLocation alloc] initWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
        CLLocation *locale = [[CLLocation alloc] initWithLatitude:restaurantCoor.latitude longitude:restaurantCoor.longitude];
        CLLocationDistance distance = [user distanceFromLocation:locale];
        
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(restaurantCoor, distance*2, distance*2);
        [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
        
        [_restaurantTable reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        {
            NSLog(@"FUCK DIS SHIT!");
        }
    }];
    
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
            break;
        case 1:
            NSLog(@"RSVP NO was pressed");
            theCell.arrow.image = [UIImage imageNamed:@"redarrow.png"];
            break;
        default:
            break;
    }
    [theCell setNeedsDisplay];
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