//
//  MapViewController.h
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
#import <CoreLocation/CoreLocation.h>

@interface MapViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate> {
    CLLocationManager *locationManager;
}

@property (nonatomic, strong) NSMutableArray *users;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
- (IBAction)homeTapped:(id)sender;

@end
