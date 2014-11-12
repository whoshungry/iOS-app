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

@interface SummaryViewController : UIViewController<CLLocationManagerDelegate, MKMapViewDelegate> {
    CLLocationManager *locationManager;
}

@property (strong, nonatomic) HootLobby* currentLobby;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
- (IBAction)goHome:(id)sender;

@end
