//
//  RestaurantsViewController.m
//  Who's Hungry
//
//  Created by administrator on 10/19/14.
//  Copyright (c) 2014 Who's Hungry. All rights reserved.
//

#import "RestaurantsViewController.h"

#define GOOGLE_API_KEY @"AIzaSyAdB2MtdRCGDZNfIcd-uR22hkmCmniA6Oc"

@interface RestaurantsViewController ()

@end

@implementation RestaurantsViewController

@synthesize locationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*PFUser *currentUser = [PFUser currentUser];
    PFQuery *query = [PFQuery queryWithClassName:@"Group"];
    [query getObjectInBackgroundWithId:[currentUser[@"group"] objectId] block:^(PFObject *group, NSError *error) {
        NSLog(@"object ID is = %@", [currentUser username]);
        //NSLog(@"Admin ID is = %@", group[@"adminID"]);
        if ([[currentUser username] isEqualToString:group[@"adminID"]]) {
            NSLog(@"I'M AN ADMIN");
            _isAdmin = TRUE;
            

            //Get the places from GOOGLE API --> COMPLETE
            //Create Group with restaurants --> COMPLETE
            //Send PUSH notifications to Friends --> COMPLETE
        }
        else{
            NSLog(@"I'M NOT ADMIN");
            _isAdmin = FALSE;
            
            //Retrieve RESTAURANTS and make sure we update the votes (not create votes again)
            //Retrieve time Remaining and place it at the top of the viewcontroller (if less than 30 seconds add 30 seconds
            //Try to add a 1-second-interrupt to modify the timer on top of view controller
        }
        _isAdmin = TRUE;   //THIS IS A TEST CASE
        [self initRestaurants];
    }];*/
    

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
    if (authorizationStatus == kCLAuthorizationStatusAuthorized ||
        authorizationStatus == kCLAuthorizationStatusAuthorizedAlways ||
        authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        [self.locationManager startUpdatingLocation];
        self.mapView.showsUserLocation = YES;
    }

    //[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]]];
    // Do any additional setup after loading the view.
    self.restaurantsTable.backgroundColor = [UIColor clearColor];
    self.restaurantsTable.opaque = NO;
    self.restaurantsTable.backgroundView = nil;
    _allPlaces = [NSMutableArray new];
}

-(void) queryGooglePlaces: (NSString *) googleType {
    NSLog(@"going through google places!!!");
    // Build the url string to send to Google. NOTE: The kGOOGLE_API_KEY is a constant that should contain your own API key that you obtain from Google. See this link for more info:
    // https://developers.google.com/maps/documentation/places/#Authentication
    NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/search/json?location=%f,%f&radius=%@&types=%@&sensor=true&key=%@", _currentCentre.latitude, _currentCentre.longitude, [NSString stringWithFormat:@"%i", 1000], googleType, GOOGLE_API_KEY];
    
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
        [tempDictionary setObject:@(0) forKey:[response objectForKey:@"name"]];
    }
    /*PFUser *currentUser = [PFUser currentUser];
    PFQuery *query = [PFQuery queryWithClassName:@"Group"];
    [query getObjectInBackgroundWithId:[currentUser[@"group"] objectId] block:^(PFObject *group, NSError *error) {
        group[@"votes"] = tempDictionary;
        group[@"restaurants"] = _allPlaces;
        [group saveInBackground];
    }];*/
    [self.restaurantsTable reloadData];
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //Finds location for the first time only and ONLY if it is ADMIN
    if (!_locationFound) {
        NSLog(@"going through it man %@", locations[0]);
        _currentLocation = locations[0];
        _currentCentre = _currentLocation.coordinate;
        _locationFound = TRUE;
        [self queryGooglePlaces:@"food"];
    }
    /*NSLog(@"going through it man %@", locations[0]);
    if (_isAdmin && !_locationFound) {
        _currentLocation = locations[0];
        _currentCentre = _currentLocation.coordinate;
        _locationFound = TRUE;
        [self queryGooglePlaces:@"food"];
    }*/
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
    
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(concurrentQueue, ^{
        NSDictionary *photoDict = [[response objectForKey:@"photos"] objectAtIndex:0];
        NSString *photoRef = [photoDict objectForKey:@"photo_reference"];
        NSString *urlStr = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/photo?photoreference=%@&key=%@&sensor=false&maxwidth=320", photoRef, GOOGLE_API_KEY];
        NSURL * imageURL = [NSURL URLWithString:urlStr];
        
        NSData * imageData = [NSData dataWithContentsOfURL:imageURL];
        UIImage * image = [UIImage imageWithData:imageData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.image.image = image;
        });
    });
    
    cell.name.text = response[@"name"];
    int priceLevel = [[response objectForKey:@"price_level"] intValue];
    if (!priceLevel) {
        priceLevel = 3;
    }
    NSString* priceString = @"";
    for (int i = 0; i < priceLevel; i++) {
        priceString = [priceString stringByAppendingString:@"$"];
    }
    cell.price.text = priceString;
    NSDictionary* loc  = [[NSDictionary alloc] init];
    loc = [response objectForKey:@"geometry"];
    NSDictionary* locTwo  = [[NSDictionary alloc] init];
    locTwo = loc[@"location"
                 ];
    CLLocation* placeLocation = [[CLLocation alloc] initWithLatitude:(CLLocationDegrees)[locTwo[@"lat"] doubleValue] longitude:(CLLocationDegrees)[locTwo[@"lng"] doubleValue]];
    //NSLog(@"Latitude %@ and Longitude %@", locTwo[@"lat"], locTwo[@"lng"]);
    CLLocation* userLocation = [[CLLocation alloc] initWithLatitude:_currentCentre.latitude longitude:_currentCentre.longitude];
    float distance = [placeLocation distanceFromLocation:userLocation] / 1609.0;
    cell.distance.text = [NSString stringWithFormat:@"%1.2f mi.",distance];
    
    if([self.tickedIndexPaths containsObject:indexPath])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
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
    
    if(![self.tickedIndexPaths containsObject:indexPath]){
        if (_selectionCount < 3) {
            [self.tickedIndexPaths addObject:indexPath];
            _selectionCount++;
        }
    }//tickedIndexPaths is an array
    else{
        [self.tickedIndexPaths removeObject:indexPath];
        _selectionCount--;
    }
    [self.restaurantsTable reloadData];
}

- (IBAction)doneTapped:(id)sender {
     //[(UINavigationController *)self.presentingViewController  popViewControllerAnimated:NO];
     [self dismissViewControllerAnimated:YES completion:nil];
    
    /*if (_isAdmin) {
        if (self.tickedIndexPaths.count == 3) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            // This loop goes through every place of the 15 places in the list
            for (int i = 0; i < _allPlaces.count; i++) {
                NSDictionary *response = [_allPlaces objectAtIndex:i];
                
                //This loop goes through the 3 selected cells and checks if the current cell from the above loop was selected
                for (int k = 0 ; k < _tickedIndexPaths.count; k++){
                    _isSelected = FALSE;
                    RestaurantCell *tempCell = [_restaurantsTable cellForRowAtIndexPath:_tickedIndexPaths[k]];
                    if(response[@"name"] == tempCell.name.text){
                        [dictionary setObject:@(1) forKey:[response objectForKey:@"name"]];
                        _isSelected = TRUE;
                    }
                }
                if (!_isSelected) {
                    [dictionary setObject:@(0) forKey:[response objectForKey:@"name"]];
                }
            }
            
            PFUser* currentUser = [PFUser currentUser];
            // update group info to include when and lobby length
            PFQuery *query = [PFQuery queryWithClassName:@"Group"];
            [query getObjectInBackgroundWithId:[currentUser[@"group"] objectId] block:^(PFObject *group, NSError *error) {
                if (!group[@"votes"]) {
                    group[@"votes"] = dictionary;
                    group[@"restaurants"] = _allPlaces;
                }
                [group saveInBackground];
            }];
            [self performSegueWithIdentifier:@"mapSegue" sender:nil];
        }
    }
    
    //IF it is not an Admin
    else{
            
    }*/

        //Add alert to tell Admin that friends have been notified and they have X amount of time to reply.
        //If not admin, tell friends that votes have been casted and wait till lobby is closed
}


@end
