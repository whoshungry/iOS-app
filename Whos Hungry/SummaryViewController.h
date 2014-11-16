//
//  SummaryViewController.h
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//



#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import <Parse/Parse.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <MapKit/MapKit.h>
#import "HootLobby.h"
#import <CoreLocation/CoreLocation.h>
#import "AFNetworking.h"
#import "AFHTTPRequestOperation.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)


@interface SummaryViewController : UIViewController<CLLocationManagerDelegate, MKMapViewDelegate> {
    CLLocationManager *locationManager;
}

@property (strong, nonatomic) HootLobby* currentLobby;
@property (strong, nonatomic) NSMutableArray* allPlaces;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
- (IBAction)goHome:(id)sender;

@end
