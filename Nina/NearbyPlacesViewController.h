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


@interface NearbyPlacesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ASIHTTPRequestDelegate, UISearchBarDelegate> {
    EGORefreshTableHeaderView *refreshHeaderView;
    
    IBOutlet UIView *tableFooterView;
    IBOutlet UITableView *placesTableView;
    IBOutlet UISearchBar *_searchBar;
    NSArray  *nearbyPlaces;
    
    BOOL needLocationUpdate;
    BOOL _reloading;
    
}

@property(assign,getter=isReloading) BOOL reloading;

- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;

@property(nonatomic, retain) IBOutlet UITableView *placesTableView;
@property(nonatomic, retain) IBOutlet IBOutlet UISearchBar *searchBar;
@property(nonatomic, retain) IBOutlet UIView *tableFooterView;

@end
