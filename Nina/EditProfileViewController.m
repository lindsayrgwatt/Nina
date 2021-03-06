//
//  EditProfileViewController.m
//  Nina
//
//  Created by Ian MacKinnon on 11-10-05.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "EditProfileViewController.h"
#import "EditableTableCell.h"
#import "NinaHelper.h"
#import "UIImage+Resize.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+WebCache.h"
#import "Flurry.h"
#import "UserManager.h"

@interface EditProfileViewController(Private)
-(IBAction)showActionSheet;
-(void)close;
@end


@implementation EditProfileViewController
@synthesize user, lat, lng, currentLocation, tableView = _tableView;



-(void)close{
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

-(IBAction)showActionSheet{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"New Profile Picture" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose From Library", nil];
        [actionSheet showInView:self.view];
        [actionSheet release];
    }
    else { // No camera, probably a touch or iPad 1
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        picker.allowsEditing = YES;
        [self presentModalViewController:picker animated:YES];
    }    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{

    if (buttonIndex == 0){
        UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
        imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imgPicker.delegate = self;
        imgPicker.allowsEditing = YES;
        [self presentModalViewController:imgPicker animated:YES];
        [imgPicker release];
 
    } else if (buttonIndex == 1){
        UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
        imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imgPicker.delegate = self;
        imgPicker.allowsEditing = YES;
        [self presentModalViewController:imgPicker animated:YES];
        [imgPicker release];
        
    }else if (buttonIndex == 2) {
        //cancel
    }

}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)img editingInfo:(NSDictionary *)editingInfo{
    [picker dismissModalViewControllerAnimated:YES];
    
    if (img.size.width > 960 || img.size.height > 960){
        img = [img
                 resizedImageWithContentMode:UIViewContentModeScaleAspectFit
                 bounds:CGSizeMake(960, 960)
                 interpolationQuality:kCGInterpolationHigh];
    } 
    
    uploadingImage = img;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    UIImageView *myImageView = (UIImageView*)[cell viewWithTag:1];
    myImageView.image = img;
}

- (void)didReceiveMemoryWarning{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];    
    // Release any cached data, images, etc that aren't in use.
}



-(IBAction)updateHomeLocation{
    CLLocationManager *locationManager = [LocationManagerManager sharedCLLocationManager];
    CLLocation *location =  locationManager.location;

    self.lat = [NSNumber numberWithFloat:location.coordinate.latitude];
    self.lng = [NSNumber numberWithFloat:location.coordinate.longitude];
    
    
    UITableViewCell *locationCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3]];
    
    locationCell.textLabel.text = [NSString stringWithFormat:@"Your map is centered right here."];
    
    [locationCell setNeedsDisplay];
    
}

-(IBAction)saveUser{
    EditableTableCell *cell = (EditableTableCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]];
    if (cell.textField.isFirstResponder) {
        [cell.textField resignFirstResponder];
    }
    cell = (EditableTableCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
    if (cell.textField.isFirstResponder) {
        [cell.textField resignFirstResponder];
    }
    
    NSString *urlText = [NSString stringWithFormat:@"/v1/users/%@", self.user.username];    

    
    NSString *user_url = ((EditableTableCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]]).textField.text;
    NSString *city = ((EditableTableCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]]).textField.text;
    NSString *description = ((EditableTableCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]]).textField.text;
    
    self.user.userDescription = description;
    self.user.url = user_url;
    
    if (uploadingImage){
        Photo *photo = [[Photo alloc] init];
        photo.thumb_image = uploadingImage;
        self.user.profilePic = photo;
        [photo release];
    }    
    
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:urlText usingBlock:^(RKObjectLoader* loader) {
        loader.method = RKRequestMethodPUT;
        RKParams* params = [RKParams params];
        if (uploadingImage){
            NSData* imgData = UIImageJPEGRepresentation(uploadingImage, 0.5);
            [params setData:imgData MIMEType:@"image/jpeg" fileName:@"image.jpg" forParam:@"image"];
        }
        [params setValue:description forParam:@"description"];
        [params setValue:user_url forParam:@"url"];
        [params setValue:city forParam:@"city"];
        [params setValue:[NSString stringWithFormat:@"%@", self.lat] forParam:@"user_lat"];
        [params setValue:[NSString stringWithFormat:@"%@", self.lng] forParam:@"user_lng"];
        
        
        loader.params = params;
        loader.delegate = self;
        loader.userData = [NSNumber numberWithInt:90];
    }];

    HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    // Set determinate mode
    HUD.labelText = @"Saving...";
    [HUD retain];
}

- (void)hudWasHidden{
    
}


- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    [HUD hide:TRUE];
    [NinaHelper handleBadRKRequest:objectLoader.response sender:self];
}


- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
    [HUD hide:TRUE];
    
    [UserManager setUser:[objects objectAtIndex:0]];
    [self.navigationController dismissModalViewControllerAnimated:TRUE];
}


#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Edit Profile";
    
    if (self.user.location && [self.user.location objectAtIndex:0] != nil && [self.user.location objectAtIndex:1] != nil){
        self.lat = [self.user.location objectAtIndex:0];
        self.lng = [self.user.location objectAtIndex:1];
    } else {
        self.lat = [NSNumber numberWithInt:0];
        self.lng = [NSNumber numberWithInt:0];
    }
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)];
    //button.tintColor = [UIColor blackColor];
    
    self.navigationItem.leftBarButtonItem = button;
    [button release];
    
    UIBarButtonItem *saveButton =  [[UIBarButtonItem  alloc]initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveUser)];
    self.navigationItem.rightBarButtonItem = saveButton;
    [saveButton release];
    
    // Create button at bottom of table
    // Could do as section footer, but couldn't make button work inside it so table footer instead - lw
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, 50.0)] autorelease];
    
    UIButton *update = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [update addTarget:self action:@selector(updateHomeLocation) forControlEvents:UIControlEventTouchUpInside];
    [update setTitle:@"Center Map Here" forState:UIControlStateNormal];
    update.enabled = YES;
    
    update.frame = CGRectMake(10.0, 0.0, screenRect.size.width - 20.0, 40.0);
    
    [footerView addSubview:update];

    self.tableView.tableFooterView = footerView;
    
    CLLocationManager *locationManager = [LocationManagerManager sharedCLLocationManager];
    self.currentLocation = locationManager.location;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [StyleHelper styleBackgroundView:self.tableView];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


-(void) dealloc{
    [[[[RKObjectManager sharedManager] client] requestQueue] cancelRequestsWithDelegate:self];    
    [user release];
    [lat release];
    [lng release];
    [_tableView release];
    [super dealloc];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    if (section == 0){
        return 1;
    } else if (section == 1){
        return 3;
    } else if (section ==2){
        return 1;
    } else if (section ==3){
        return 1;
    } else {
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
		return 70;
	} else {
		return 44;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *photoCellIdentifier = @"photoCell";
    static NSString *CellIdentifier = @"Cell";
    static NSString *homeCellIdentifier = @"HomeCell";
    static NSString *authCellIdentifier = @"AuthCell";
    
    UITableViewCell *cell;
    
    if (indexPath.section ==0){
        cell = [tableView dequeueReusableCellWithIdentifier:photoCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:photoCellIdentifier] autorelease];
        }
        
        CGRect myImageRect = CGRectMake(20, 10, 50, 50);
        UIImageView *myImage = [[UIImageView alloc] initWithFrame:myImageRect];
        
        // Here we use the new provided setImageWithURL: method to load the web image
        [myImage setImageWithURL:[NSURL URLWithString:user.profilePic.thumbUrl]
                       placeholderImage:[UIImage imageNamed:@"profile.png"]];
        myImage.tag = 1;
        
        [[myImage layer] setCornerRadius:1.0f];
        [[myImage layer] setMasksToBounds:YES];
        [[myImage layer] setBorderWidth:1.0f];
        [[myImage layer] setBorderColor: [UIColor lightGrayColor].CGColor];
        
        [cell addSubview:myImage];
        [myImage release];
        
        UILabel *headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(84, 13, 200, 40)] autorelease];
        headerLabel.text = @"profile picture";
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.font = [UIFont systemFontOfSize:17];
        [cell.contentView addSubview:headerLabel];

        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    } else if (indexPath.section == 1){
        EditableTableCell *eCell;
        
        eCell = (EditableTableCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (eCell == nil) {
            eCell = [[[EditableTableCell alloc] initWithReuseIdentifier:CellIdentifier] autorelease];   
        }

        eCell.textField.text = @"";
        eCell.textField.userInteractionEnabled = true;

        if (indexPath.row == 0){
            eCell.textLabel.text = @"url";
            eCell.textField.text = self.user.url;
            eCell.textField.delegate = self;
        }else if (indexPath.row == 1){
            eCell.textLabel.text = @"city";
            eCell.textField.text = self.user.city;
            eCell.textField.delegate = self;
        }else if (indexPath.row == 2){
            eCell.textLabel.text = @"description";
            eCell.textField.text = self.user.userDescription;
            eCell.textField.delegate = self;
            eCell.textField.userInteractionEnabled = false;
        }
        
        cell = eCell;
    } else if (indexPath.section == 2){
        cell = [tableView dequeueReusableCellWithIdentifier:authCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:authCellIdentifier] autorelease];
        }
        
        cell.textLabel.text = @"Facebook";
        
        if (user.facebook){
            [cell.imageView setImage:[UIImage imageNamed:@"facebook_icon.png"]];
            [cell.detailTextLabel setText: @"You are connected via Facebook"];
        } else {
            [cell.imageView setImage:[UIImage imageNamed:@"facebook_icon_bw.png"]];
            [cell.detailTextLabel setText: @"Tap to connect with Facebook"];
        }
    }  else if (indexPath.section == 3){
        cell = [tableView dequeueReusableCellWithIdentifier:authCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:authCellIdentifier] autorelease];
        }
        
        cell.textLabel.text = @"Twitter";
        
        if (user.twitter){
            [cell.imageView setImage:[UIImage imageNamed:@"twitter_icon.png"]];
            [cell.detailTextLabel setText: @"You are connected via Twitter"];
        } else {
            [cell.imageView setImage:[UIImage imageNamed:@"twitter_icon_bw.png"]];
            [cell.detailTextLabel setText: @"Tap to connect with Twitter"];
        }
    } else if (indexPath.section == 4){
        cell = [tableView dequeueReusableCellWithIdentifier:homeCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:homeCellIdentifier] autorelease];
        }   
        [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica" size:12]];
        
        CLLocationDegrees homeLat = [self.user.lat doubleValue];
        CLLocationDegrees homeLng = [self.user.lng doubleValue];
        CLLocation *homeLocation = [[CLLocation alloc] initWithLatitude:homeLat longitude:homeLng];        
        
        CLLocationDistance distance = [self.currentLocation distanceFromLocation:homeLocation];
        DLog(@"%f", distance);
        cell.textLabel.text = [NSString stringWithFormat:@"Your map is centered %@ from here (private)", [NinaHelper metersToLocalizedDistance:distance]];
        
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [homeLocation release];
    } 
    
    return cell;
}


- (void)popupTextView:(YIPopupTextView *)textView didDismissWithText:(NSString *)text
{
    self.user.userDescription = text;
    [self.tableView reloadData];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    if (indexPath.section == 0 && indexPath.row == 0){
        [self showActionSheet];
    } else if (indexPath.section == 1 && indexPath.row == 2){
        // NOTE: maxCount = 0 to hide count
        YIPopupTextView* popupTextView = [[YIPopupTextView alloc] initWithPlaceHolder:@"input here" maxCount:0];
        popupTextView.delegate = self;
        popupTextView.showCloseButton = YES;
        //popupTextView.caretShiftGestureEnabled = YES;   // default = NO
        popupTextView.text = self.user.userDescription;        
        [[self navigationController] setNavigationBarHidden:YES animated:YES];
        [popupTextView showInView:self.view];
        
    } else if (indexPath.section == 3 && indexPath.row == 1){
        [self updateHomeLocation];
    } else if (indexPath.section == 2 && indexPath.row == 0){
        
        if (self.user.facebook == nil){
            [FBSession openActiveSessionWithPublishPermissions:[NSArray arrayWithObjects:@"email", @"publish_actions", nil] defaultAudience:FBSessionDefaultAudienceFriends allowLoginUI:TRUE completionHandler:^(FBSession *session,
                                                                                                                                                                                                                  FBSessionState state, NSError *error) {
                [NinaHelper updateFacebookCredentials:session forUser:self.user];
            }];
        }
        
    } else if (indexPath.section == 3 && indexPath.row == 0){
        
        if (self.user.twitter == nil){
            [self authorizeTwitter];
        }
        
    }
}

-(void) handleTwitterCredentials:(NSDictionary *)creds{
    [super handleTwitterCredentials:creds];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


@end
