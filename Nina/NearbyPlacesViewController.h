//
//  NearbyPlacesViewController.h
//  Nina
//
//  Created by Ian MacKinnon on 11-07-19.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGORefreshTableHeaderView.h"
#import "ASIHTTPRequest.h"
#import "User.h"
#import "NinaHelper.h"
#import "MBProgressHUD.h"


@interface NearbyPlacesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ASIHTTPRequestDelegate, UISearchBarDelegate, CLLocationManagerDelegate, MBProgressHUDDelegate> {
    EGORefreshTableHeaderView *refreshHeaderView;
    
    IBOutlet UIView *tableFooterView;
    IBOutlet UITableView *placesTableView;
    IBOutlet UISearchBar *_searchBar;
    IBOutlet UIToolbar *toolBar;
    IBOutlet UILabel *gpsLabel;
    CLLocation *_location;
    
    NSMutableArray  *nearbyPlaces;
    NSMutableArray  *predictivePlaces;
    
    BOOL showPredictive;
    BOOL narrowed;
    BOOL dataLoaded;

    BOOL locationEnabled;
    BOOL _reloading;
    MBProgressHUD *HUD;
    
    NSTimer *timer;
}

@property(assign,getter=isReloading) BOOL reloading;

- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;

@property(nonatomic, retain) IBOutlet UITableView *placesTableView;
@property(nonatomic, retain) IBOutlet IBOutlet UISearchBar *searchBar;
@property(nonatomic, retain) IBOutlet IBOutlet UIToolbar *toolBar;
@property(nonatomic, retain) IBOutlet UIView *tableFooterView;
@property(nonatomic, retain) IBOutlet UILabel *gpsLabel;
@property(nonatomic,assign) BOOL dataLoaded;

@property(nonatomic, assign) BOOL locationEnabled;
@property(nonatomic, retain) CLLocation *location;

@end
