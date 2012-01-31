//
//  NearbySuggestedMapController.h
//  Nina
//
//  Created by Ian MacKinnon on 12-01-11.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SuggestedPlaceController.h"
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "NinaHelper.h"
#import "ASIHTTPRequest.h"
#import "User.h"
#import "LoginController.h"
#import "CMPopTipView.h"

@protocol SuggestedMapUserFilterProtocol
-(void) setUserFilter:(NSString*)username;
@end


@interface NearbySuggestedMapController : SuggestedPlaceController<MKMapViewDelegate, SuggestedMapUserFilterProtocol, CMPopTipViewDelegate> {
    MKMapView *_mapView;    
    CLLocationManager *locationManager;
    CLLocationCoordinate2D lastCoordinate;
    CLLocationDegrees lastLatSpan;
    UIActivityIndicatorView *spinnerView;
    UIToolbar *bottomToolBar;
    
    UIBarButtonItem *showPeopleButton;
    
    NSTimer *timer;
    NSString *userFilter;
    
    CMPopTipView *usernameButton;

}

@property(nonatomic, retain) IBOutlet MKMapView *mapView;
@property(nonatomic, retain) IBOutlet UIActivityIndicatorView *spinnerView;
@property(nonatomic, retain) CLLocationManager *locationManager;
@property(nonatomic, retain) IBOutlet UIToolbar *bottomToolBar;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *showPeopleButton;
@property(nonatomic, retain) CMPopTipView *usernameButton;

-(IBAction)recenter;
-(IBAction)reloadMap;

-(IBAction)showPeople;

@end
