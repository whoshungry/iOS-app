//
//  SummaryViewController.m
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import "SummaryViewController.h"
#import "UIImage+Resize.h"

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
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [locationManager requestWhenInUseAuthorization];
    
    self.mapView.delegate = self;
    
    CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorized ||
        authorizationStatus == kCLAuthorizationStatusAuthorizedAlways ||
        authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        NSLog(@"we in here");
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
    [locationManager stopUpdatingLocation];
    /*CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude);
     PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude
     longitude:coordinate.longitude];
     
     PFQuery *query = [PFQuery queryWithClassName:@"User"];
     [query getObjectInBackgroundWithId:[[PFUser currentUser] objectId] block:^(PFObject *user, NSError *error) {
     user[@"location"] = geoPoint;
     NSLog(@"new loca is %f %f", geoPoint.latitude, geoPoint.longitude);
     [user saveInBackground];
     }];*/
    
}

/*- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    static NSString* AnnotationIdentifier = @"Annotation";
    MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
    
    if (!pinView) {
        MKPinAnnotationView *customPinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
        if (annotation == mapView.userLocation) {
            if (FBSession.activeSession.isOpen)
            {
                [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    NSString *facebookID = result[@"id"];
                    NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
                    customPinView.image = [UIImage imageWithImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:pictureURL]] scaledToSize:CGSizeMake(30.0, 30.0)];
                }];
                
            }
        } else {
            customPinView.image = [UIImage imageWithImage:[UIImage imageNamed:@"final thumbnail"] scaledToSize:CGSizeMake(30.0, 30.0)];
        }
        customPinView.animatesDrop = NO;
        customPinView.canShowCallout = YES;
        customPinView.draggable = YES;
        
        return customPinView;
        
    } else {
        pinView.annotation = annotation;
    }
    
    return pinView;
}*/

- (IBAction)goHome:(id)sender {
    [locationManager stopUpdatingLocation];
}

@end
