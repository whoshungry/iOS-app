//
//  RestaurantsViewController.m
//  Who's Hungry
//
//  Created by administrator on 10/19/14.
//  Copyright (c) 2014 Who's Hungry. All rights reserved.
//

#import "RestaurantsViewController.h"

#define GOOGLE_API_KEY @"AIzaSyAdB2MtdRCGDZNfIcd-uR22hkmCmniA6Oc"
#define GOOGLE_API_KEY_TWO @"AIzaSyBBQSs-ALwZ3Za7nioFPYXsByMDsMFq-68"
#define GOOGLE_API_KEY_THREE @"AIzaSyA6gixyCg9D-9nEJ8q7PQJiJ9Nk5LzcltI"
#define LOBBY_KEY  @"currentlobby"

@interface RestaurantsViewController () {
    NSMutableArray *restImages;
}

@end

@implementation RestaurantsViewController

@synthesize locationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    _restaurantIdArray = [NSMutableArray new];
    _restaurantNameArray = [NSMutableArray new];
    _restaurantPicArray = [NSMutableArray new];
    restImages = [NSMutableArray new];
    _allPlaces = [NSMutableArray new];
    
    [self initRestaurants];
}

- (void)initRestaurants{
    _isAdmin = TRUE;   //THIS IS A TEST CASE
    NSLog(@"initing restuarants");
    _tickedIndexPaths = [[NSMutableArray alloc] init];
    _locationFound = FALSE;
    _selectionCount = 0;
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [locationManager requestWhenInUseAuthorization];
    [locationManager requestAlwaysAuthorization];
    self.mapView.delegate = self;
    
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedAlways ||
        authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        [self.locationManager startUpdatingLocation];
        self.mapView.showsUserLocation = YES;
    }

    // Do any additional setup after loading the view.
    self.restaurantsTable.backgroundColor = [UIColor clearColor];
    self.restaurantsTable.opaque = NO;
    self.restaurantsTable.backgroundView = nil;
    _allPlaces = [NSMutableArray new];
}

-(void) queryGooglePlaces: (NSString *) googleType {
    NSLog(@"going through google places!!! with loc: %f", _currentCentre.latitude);
    // Build the url string to send to Google. NOTE: The kGOOGLE_API_KEY is a constant that should contain your own API key that you obtain from Google. See this link for more info:
    // https://developers.google.com/maps/documentation/places/#Authentication
    NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/search/json?location=%f,%f&radius=%@&types=%@&sensor=true&key=%@", _currentCentre.latitude, _currentCentre.longitude, [NSString stringWithFormat:@"%i", 1000], googleType, GOOGLE_API_KEY_THREE];
    
    //Formulate the string as a URL object.
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
    if (responseData != nil) {
    NSLog(@"fetched data is @!!:!!");
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          
                          options:kNilOptions
                          error:&error];
    
    //The results from Google will be an array obtained from the NSDictionary object with the key "results".
    NSArray* places = [json objectForKey:@"results"];
    NSMutableDictionary* tempDictionary = [[NSMutableDictionary alloc] init];
    NSDictionary *response = [NSDictionary new];
    for (int j = 0; j < 15; j++) {
        [_allPlaces addObject:places[j]];
    }
    for (int k = 0; k < _allPlaces.count; k++) {
        response = [_allPlaces objectAtIndex:k];
        NSLog(@"response for the places are  %@     ", response);
        NSDictionary *photoDict = [response objectForKey:@"photos"][0];
        NSString *photoRef = [photoDict objectForKey:@"photo_reference"];
        NSString *urlStr = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/photo?photoreference=%@&key=%@&sensor=false&maxwidth=320", photoRef, GOOGLE_API_KEY_THREE];
        NSURL * imageURL = [NSURL URLWithString:urlStr];
        NSData * imageData = [NSData dataWithContentsOfURL:imageURL];
        UIImage * image = [UIImage imageWithData:imageData];
        [restImages addObject:image];
        
        
        /*dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(concurrentQueue, ^{
            NSData * imageData = [NSData dataWithContentsOfURL:imageURL];
            UIImage * image = [UIImage imageWithData:imageData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [restImages addObject:image];
            });
        });*/
        [tempDictionary setObject:@(0) forKey:[response objectForKey:@"name"]];
    }
        
    [self.restaurantsTable reloadData];
}
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //Finds location for the first time only and ONLY if it is ADMIN
    if (!_locationFound) {
        NSLog(@"going through it man %@", locations[0]);
        _currentLocation = locations[0];
        _currentCentre = _currentLocation.coordinate;
        _locationFound = TRUE;
        if (![self.voteType isEqualToString:@"coffee"]) {
            [self queryGooglePlaces:@"food"];
        } else {
            [self queryGooglePlaces:@"cafe"];
        }
    }

}

# pragma mark - tableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.allPlaces.count == 0) {
        return  0;
    }
    else{
        return _allPlaces.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"mainCell";
    RestaurantCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSDictionary *response = [_allPlaces objectAtIndex:indexPath.row];
    
    cell.backgroundColor = [UIColor clearColor];
    

    
    //////////
    //Load image into the cell
    /*
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(concurrentQueue, ^{
        NSDictionary *photoDict = [[response objectForKey:@"photos"] objectAtIndex:0];
        NSString *photoRef = [photoDict objectForKey:@"photo_reference"];
        NSString *urlStr = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/photo?photoreference=%@&key=%@&sensor=false&maxwidth=320", photoRef, GOOGLE_API_KEY_THREE];
        NSURL * imageURL = [NSURL URLWithString:urlStr];
        
        NSData * imageData = [NSData dataWithContentsOfURL:imageURL];
        UIImage * image = [UIImage imageWithData:imageData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.image.image = image;
        });
    });
    */
    if (restImages.count > 0) {
        cell.image.image = restImages[indexPath.row];
    }
    cell.name.text = response[@"name"];
    
    /////////
    //Price level signs
    int priceLevel = [[response objectForKey:@"price_level"] intValue];
    if (!priceLevel) {
        priceLevel = 3;
    }
    NSString* priceString = @"";
    for (int i = 0; i < priceLevel; i++) {
        priceString = [priceString stringByAppendingString:@"$"];
    }
    cell.price.text = priceString;
    
    ///////////
    //Loading distance from current location
    NSDictionary* loc  = [[NSDictionary alloc] init];
    loc = [response objectForKey:@"geometry"];
    NSDictionary* locTwo  = [[NSDictionary alloc] init];
    locTwo = loc[@"location"];
    CLLocation* placeLocation = [[CLLocation alloc] initWithLatitude:(CLLocationDegrees)[locTwo[@"lat"] doubleValue] longitude:(CLLocationDegrees)[locTwo[@"lng"] doubleValue]];
    //NSLog(@"Latitude %@ and Longitude %@", locTwo[@"lat"], locTwo[@"lng"]);
    CLLocation* userLocation = [[CLLocation alloc] initWithLatitude:_currentCentre.latitude longitude:_currentCentre.longitude];
    float distance = [placeLocation distanceFromLocation:userLocation] / 1609.0;
    cell.distance.text = [NSString stringWithFormat:@"%1.2f mi.",distance];
    
    
    ///////////
    //Add or remove checkmark
    if([self.tickedIndexPaths containsObject:indexPath])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [cell setBackgroundColor:[UIColor colorWithRed:255.0/255.0 green:228.0/255.0 blue:171.0/255.0 alpha:1.0]];
        [_restaurantIdArray addObject:response[@"place_id"]];
        [_restaurantNameArray addObject:response[@"name"]];
        [_restaurantPicArray addObject:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/photo?photoreference=%@&key=%@&sensor=false&maxwidth=320", response[@"place_id"], GOOGLE_API_KEY_THREE]];
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //If cell is not already in list of checkmark
    if(![self.tickedIndexPaths containsObject:indexPath]){
        
        //If it is an there is less than 3 selected, just add it to the array
        if (_selectionCount < 3) {
            [self.tickedIndexPaths addObject:indexPath];
            _selectionCount++;
        }
        
        //If it is the 4th to be selected, remove the first from the array and shift the rest and add this one in first location
        else if (_selectionCount == 3){
            id object = [self.tickedIndexPaths objectAtIndex:1];
            [self.tickedIndexPaths removeObjectAtIndex:0];
            [self.tickedIndexPaths insertObject:object atIndex:0];
            object = [self.tickedIndexPaths objectAtIndex:2];
            [self.tickedIndexPaths removeObjectAtIndex:1];
            [self.tickedIndexPaths insertObject:object atIndex:1];
            [self.tickedIndexPaths removeObjectAtIndex:2];
            [self.tickedIndexPaths insertObject:indexPath atIndex:2];
        }
    }
    
    //If cell is already selected, deselect it.
    else{
        [self.tickedIndexPaths removeObject:indexPath];
        _selectionCount--;
    }
    
    //////////
    //Reset array of restaurant id's
    [_restaurantIdArray removeAllObjects];
    [_restaurantNameArray removeAllObjects];
    [_restaurantPicArray removeAllObjects];
    
    //reload data again to display checkmarks
    [self.restaurantsTable reloadData];
}

- (IBAction)doneTapped:(id)sender {
    [self.locationManager stopUpdatingLocation];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
    ///////////
    //Retrieving FB user Id
    if (FBSession.activeSession.isOpen)
    {
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            _facebookId = result[@"id"];
            NSLog(@"FB ID is: %@", _facebookId);
            
            HootLobby* tempLobby = [self loadCustomObjectWithKey:LOBBY_KEY];
            if (!tempLobby) {
                NSLog(@"Current Lobby is empty");
                tempLobby = [HootLobby new];
                tempLobby.facebookId = _facebookId;
                [self saveCustomObject:tempLobby];
            }
            else{
                NSLog(@"Current Lobby has DATA!");
                tempLobby.facebookId = _facebookId;
                [self saveCustomObject:tempLobby];
            }
        }];
        
    }
    
    //transfer restaurantsIdArray to hootLobby
    //transfer facebookId to HootLobby
    
    HootLobby* tempLobby = [self loadCustomObjectWithKey:LOBBY_KEY];
    if (!tempLobby) {
        NSLog(@"Current Lobby is empty");
        tempLobby = [HootLobby new];
        tempLobby.placesIdArray = _restaurantIdArray;
        tempLobby.placesNamesArray = _restaurantNameArray;
        tempLobby.placesPicsArray = _restaurantPicArray;
        [self saveCustomObject:tempLobby];
    }
    else{
        NSLog(@"Current Lobby has DATA!");
        tempLobby.placesIdArray = _restaurantIdArray;
        tempLobby.placesNamesArray = _restaurantNameArray;
        tempLobby.placesPicsArray = _restaurantPicArray;
        [self saveCustomObject:tempLobby];
    }
    

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






@end
