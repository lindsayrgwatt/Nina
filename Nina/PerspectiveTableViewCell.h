//
//  PerspectiveTableViewCell.h
//  Nina
//
//  Created by Ian MacKinnon on 11-08-23.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Perspective.h"
#import "NinaHelper.h"

@interface PerspectiveTableViewCell : UITableViewCell{
    Perspective *perspective;
    IBOutlet UIImageView *userImage;
    IBOutlet UIButton *upvoteButton;
    IBOutlet UITextView *memoText;
    IBOutlet UILabel *titleLabel;
}

@property(nonatomic,retain) Perspective *perspective; 
@property(nonatomic,retain) IBOutlet UIImageView *userImage;
@property(nonatomic,retain) IBOutlet UIButton *upvoteButton;
@property(nonatomic,retain) IBOutlet UITextView *memoText;
@property(nonatomic,retain) IBOutlet UILabel *titleLabel;

-(IBAction)toggleStarred;

//for calculating heights
+(CGFloat) cellHeightForPerspective:(Perspective*)perspective;
+(void) setupCell:(PerspectiveTableViewCell*)cell forPerspective:(Perspective*)perspective  userSource:(BOOL)userSource;

@end
