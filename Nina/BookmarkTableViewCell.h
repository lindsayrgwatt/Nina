//
//  BookmarkTableViewCell.h
//  Nina
//
//  Created by Ian MacKinnon on 11-08-23.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NinaHelper.h"
#import "LocationManagerManager.h"
#import "Place.h"

@interface BookmarkTableViewCell : UITableViewCell{
    Place *place;
    IBOutlet UIButton *bookmarkButton;
}

@property(nonatomic, retain) Place *place;
@property(nonatomic, retain) IBOutlet UIButton *bookmarkButton;

-(IBAction) bookmark;

@end
