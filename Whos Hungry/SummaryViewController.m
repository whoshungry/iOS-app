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
    
    HootLobby *lobby;
    BOOL isAdmin;
}

@end

@implementation SummaryViewController

typedef enum accessType
{
    ADMIN_FIRST,
    ADMIN_RETURNS,
    FRIEND_FIRST,
    FRIEND_RETURNS
} accessType;

/*
 Need to check for 4 different access
 1. Initial access from ADMIN when when/where/who is first selected
 2. Access from the ADMIN after going HOME and trying to modify vote or, if done, check map
 3. Access from FRIENDS to initially vote.
 4. Access from FRIENDS after already voting to modify vote or, if done, check map.
 */

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        
    }
    return self;
}

//This method is accessed ONLY when user is coming from MainVC. This means the lobby was already made.
//Need to check for 2 things:
//  1. If it is FRIEND, then 
-(void)initWithHootLobby:(HootLobby *)hootlobby withOption:(int)accessType{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    _voteArray = [NSMutableArray new];

    if (accessType == ADMIN_FIRST) {
        //Initialize all the groups and create vote
        _currentLobby = [self loadCustomObjectWithKey:LOBBY_KEY];
        [self createAPIGroup];
        _voteArray = nil;

    }
    else if (accessType == ADMIN_RETURNS){
        NSString *strFromInt = [NSString stringWithFormat:@"%d",hootlobby.groupid.intValue];
        _voteArray = [prefs mutableArrayValueForKey:strFromInt];

    }
    else if (accessType == FRIEND_FIRST){
        //Load clean view and be ready to make vote
        _voteArray = nil;
        
    }
    else if (accessType == FRIEND_RETURNS){
        NSString *strFromInt = [NSString stringWithFormat:@"%d",hootlobby.groupid.intValue];
        _voteArray = [prefs mutableArrayValueForKey:strFromInt];
    }

    

    
    
    
     _loaded = NO;
    

   
    
    if (accessType != ADMIN_FIRST) {
        
        /***************************************************************************************/
        //Temporary fix for expirationTime
        PFQuery *query = [PFQuery queryWithClassName:@"GroupExpiration"];
        [query whereKey:@"groupId" equalTo:hootlobby.groupid];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!object) {
                NSLog(@"The getFirstObject request failed.");
            } else {
                // The find succeeded.
                NSLog(@"Successfully retrieved the object.");
                NSLog(@"Expiration time is: %@",object[@"expirationTime"]);
                hootlobby.expirationTime = object[@"expirationTime"];
                
            }
        }];
        
        
        //accesses restaurants names and vote counts and saves it in "currentLobby" variable
        /***************************************************************************************/
        lobby = [HootLobby new];
        lobby = [hootlobby copy];
        _currentLobby = [HootLobby new];
        _currentLobby = [hootlobby copy];
        NSMutableArray *placesIdArray = [NSMutableArray new];
        NSMutableArray *placesNamesArray = [NSMutableArray new];
        NSMutableArray *placesPicsArray = [NSMutableArray new];
        NSMutableArray *placesXArray = [NSMutableArray new];
        NSMutableArray *placesYArray = [NSMutableArray new];
        placesCountArray = [NSMutableArray new];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
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
            
            lobby.placesIdArray = placesIdArray;
            lobby.placesNamesArray = placesNamesArray;
            lobby.placesPicsArray = placesPicsArray;
            lobby.placesXArray = placesXArray;
            lobby.placesYArray = placesYArray;
            
            NSLog(@"current lobby ids rrrr: %@", lobby.placesIdArray);
            NSLog(@"current lobby names rrrr: %@", lobby.placesNamesArray);
            NSLog(@"current lobby pics rrrr: %@", lobby.placesPicsArray);
            
            _currentLobby = [lobby copy];
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
    }

}




- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setSummaryTitle];
    
    //Get picture of user
    /***************************************************************************************/
    if (FBSession.activeSession.isOpen)
    {
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me/picture?type=large&return_ssl_resources=1"]];
            selfImage = [UIImage imageWithImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:pictureURL]] scaledToSize:CGSizeMake(30.0, 30.0)];
        }];
    }
    
    //Map initialization and authorization
    /***************************************************************************************/
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager requestWhenInUseAuthorization];
    self.mapView.delegate = self;
    
    //Set the timer
    /***************************************************************************************/
    self.theTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                     target:self
                                                   selector:@selector(updateTime:)
                                                   userInfo:nil
                                                    repeats:NO];
    
    //Initializes and creates table
    /***************************************************************************************/
    [self.friendsGoingTable registerNib:[UINib nibWithNibName:@"RSVPFriendsTableViewCell" bundle:nil] forCellReuseIdentifier:@"MyCustomCell"];
    self.friendsGoingTable.delegate = self;
    self.friendsGoingTable.dataSource = self;
    self.friendsGoingTable.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    
    
    _indexPathArray = [NSMutableArray new];
    self.votingCompleteView.hidden = YES;
    self.votingIncompleteView.hidden = NO;
    
    [_restaurantTable reloadData];
    
    viewload = YES;
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
    
    //Update array with group ID key
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:_voteArray forKey:[NSString stringWithFormat:@"%d",_currentLobby.groupid.intValue]];
    [prefs synchronize];
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

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    NSLog(@"updated! %@", userLocation);
    CLLocation *user = [[CLLocation alloc] initWithLatitude:userLocation.coordinate.latitude longitude:userLocation.coordinate.longitude];
    CLLocation *locale = [[CLLocation alloc] initWithLatitude:restaurantCoor.latitude longitude:restaurantCoor.longitude];
    CLLocationDistance distance = [user distanceFromLocation:locale];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(restaurantCoor, distance*2, distance*2);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"didFailWithError: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSLog(@"New Location %f %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    _currentLocation = newLocation;
    //[locationManager stopUpdatingLocation];
}

#pragma mark - NSUserDefaults methods

-(void)saveCustomObject:(HootLobby *)object{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSData *myEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
    [prefs setObject:myEncodedObject forKey:LOBBY_KEY];
}

-(HootLobby *)loadCustomObjectWithKey:(NSString*)key{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSData *myEncodedObject = [prefs objectForKey:key];
    HootLobby *obj = (HootLobby *)[NSKeyedUnarchiver unarchiveObjectWithData: myEncodedObject];
    return obj;
}

#pragma mark - AWS API methods

-(void) createAPIGroup {
    isAdmin = YES;
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

-(void) createAPIVoteWithGroupId:(NSNumber*)groupId{
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
    NSLog(@"EXPIRATION TIME IS %@",_currentLobby.expirationTime);
    
    /////////
    //Temporary solution to date issue
    PFObject *expObject = [PFObject objectWithClassName:@"GroupExpiration"];
    expObject[@"expirationTime"] = _currentLobby.expirationTime;
    expObject[@"groupId"] = groupId;
    [expObject saveInBackground];
    /////////

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
    
    //if (_currentLobby.expirationTime == nil)
        _currentLobby.expirationTime = [[NSDate date] dateByAddingTimeInterval:30*60];
    
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
        self.votingIncompleteView.hidden = YES;
        self.votingCompleteView.hidden = NO;
        [self lobbyFinished];

        
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
    self.votingCompleteView.hidden = NO;
    self.votingIncompleteView.hidden = YES;
    
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

#pragma mark - UIScrollViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Cell is from Restaurant's Table
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
            NSLog(@"Current row is %d", indexPath.row);
            cell.distanceLabel.text = [NSString stringWithFormat:@"%1.2f mi.",distance];
            cell.restaurantLabel.text = _currentLobby.placesNamesArray[indexPath.row];
        } else {
            CLLocation* placeLocation = [[CLLocation alloc] initWithLatitude:(CLLocationDegrees)[_currentLobby.placesXArray[indexPath.row] doubleValue] longitude:(CLLocationDegrees)[_currentLobby.placesYArray[indexPath.row] doubleValue]];
            float distance = [placeLocation distanceFromLocation:_currentLocation] / 1609.0;
            cell.distanceLabel.text = [NSString stringWithFormat:@"%1.2f mi.",distance];
            cell.restaurantLabel.text = _currentLobby.placesNamesArray[indexPath.row];
            if (_voteArray && indexPath.row < _voteArray.count) {
                
                cell.votes = (int)_voteArray[indexPath.row];
                cell.voteLbl.text = [NSString stringWithFormat:@"%i", cell.votes];
            }
            else{
                cell.voteLbl.text = @"0";
            }
        }
        
        return cell;
    }
    
    //Cell is from Friends Table
    else {
        static NSString *cellIdentifier = @"MyCustomCell";
        
        RSVPFriendsTableViewCell *cell = (RSVPFriendsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        
        cell.leftUtilityButtons = [self leftButtons];
        cell.rightUtilityButtons = [self rightButtons];
        cell.delegate = self;
        
        return cell;
    }
    
}

- (NSArray *)rightButtons{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                title:@"More"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Delete"];
    
    return rightUtilityButtons;
}

- (NSArray *)leftButtons{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.07 green:0.75f blue:0.16f alpha:1.0]
                                                icon:[UIImage imageNamed:@"check.png"]];
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188f alpha:1.0]
                                                icon:[UIImage imageNamed:@"cross.png"]];
    
    return leftUtilityButtons;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Set background color of cell here if you don't want default white
}

#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state{
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

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index{
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

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index{
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

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell{
    // allow just one cell's utility button to be open at once
    return YES;
}

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state{
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