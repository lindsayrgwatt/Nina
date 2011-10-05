//
//  NearbySuggestedPlaceController.h
//  Nina
//
//  Created by Ian MacKinnon on 11-10-03.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NinaHelper.h"
#import "EGORefreshTableHeaderView.h"

@interface NearbySuggestedPlaceController : UIViewController<UITableViewDelegate,UITableViewDataSource, ASIHTTPRequestDelegate, UISearchBarDelegate>{
    EGORefreshTableHeaderView *refreshHeaderView;
    
    IBOutlet UISearchBar *_searchBar;
    IBOutlet UIBarButtonItem *popularPlacesButton;
    IBOutlet UIBarButtonItem *topLocalsButton;
    IBOutlet UITableView *placesTableView;
    IBOutlet UIToolbar *toolbar;
    
    BOOL _reloading;
    
    NSMutableArray  *nearbyPlaces;
}


@property(assign,getter=isReloading) BOOL reloading;
@property(nonatomic,retain) IBOutlet UISearchBar *searchBar;
@property(nonatomic,retain) IBOutlet UIBarButtonItem *popularPlacesButton;
@property(nonatomic,retain) IBOutlet UIBarButtonItem *topLocalsButton;
@property(nonatomic,retain) IBOutlet UIToolbar *toolbar;
@property(nonatomic,retain) IBOutlet UITableView *placesTableView;

-(IBAction)popularPlaces:(id)sender;
-(IBAction)topLocals:(id)sender;

- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;


@end