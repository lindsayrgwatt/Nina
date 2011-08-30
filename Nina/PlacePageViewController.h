//
//  PlacePageViewController.h
//  placeling2
//
//  Created by Lindsay Watt on 11-06-23.
//  Copyright 2011 Placeling. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Perspective.h"
#import "Place.h"
#import "User.h"
#import "ASIHTTPRequestDelegate.h"
#import "NinaHelper.h"
#import "BookmarkTableViewCell.h"

typedef enum {
    home,
    following,
    everyone
} PerspectiveTypes;


//#import "EditViewController.h"

@interface PlacePageViewController : UITableViewController <UIActionSheetDelegate,BookmarkTableviewCellDelegate> {        
    NSString *google_id; 
    NSString *google_ref;
    
    Place *_place;
    UIImage *mapImage; // Static Google Map of Location
    BOOL mapRequested;
    PerspectiveTypes perspectiveType;
    
    IBOutlet UIButton *googlePlacesButton;
    IBOutlet UILabel *nameLabel;
    IBOutlet UILabel *addressLabel;
    IBOutlet UILabel *cityLabel;
    IBOutlet UILabel *categoriesLabel;
    
    IBOutlet UIImageView *mapImageView;
    IBOutlet UISegmentedControl *segmentedControl; 
    IBOutlet UIView *tableHeaderView;
    IBOutlet UIView *tableFooterView;

    NSArray *perspectives;
    NSMutableArray *homePerspectives;
    NSMutableArray *followingPerspectives;
    NSMutableArray *everyonePerspectives;
    
}

@property BOOL dataLoaded;

@property (nonatomic, retain) NSString *google_id;
@property (nonatomic, retain) NSString *google_ref;
@property (nonatomic, retain) Place *place;
@property (nonatomic, retain) UIImage *mapImage;

@property (nonatomic, retain) IBOutlet UIButton *googlePlacesButton;
@property (nonatomic, retain) IBOutlet UILabel *nameLabel;
@property (nonatomic, retain) IBOutlet UILabel *addressLabel;
@property (nonatomic, retain) IBOutlet UILabel *cityLabel;
@property (nonatomic, retain) IBOutlet UILabel *categoriesLabel;
@property (nonatomic, retain) IBOutlet UIImageView *mapImageView;
@property (nonatomic, retain) IBOutlet UIView *tableHeaderView;
@property (nonatomic, retain) IBOutlet UIView *tableFooterView;
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, assign) PerspectiveTypes perspectiveType;

@property (nonatomic, assign) NSMutableArray *homePerspectives;
@property (nonatomic, assign) NSMutableArray *followingPerspectives;
@property (nonatomic, assign) NSMutableArray *everyonePerspectives;

-(IBAction) googlePlacePage;
-(IBAction) changedSegment;
-(IBAction) bookmark;

- (id) initWithPlace:(Place *)place;

@end
