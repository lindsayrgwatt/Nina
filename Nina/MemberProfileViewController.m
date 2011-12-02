//
//  MemberProfileViewController.m
//  placeling2
//
//  Created by Lindsay Watt on 11-06-16.
//  Copyright 2011 Placeling. All rights reserved.
//

#import "MemberProfileViewController.h"
#import "ASIHTTPRequest.h"
#import "JSON.h"
#import <QuartzCore/QuartzCore.h>
#import "FollowViewController.h"
#import "Perspective.h"
#import "PerspectiveTableViewCell.h"
#import "MyPerspectiveCellViewController.h"
#import "PlacePageViewController.h"
#import "PerspectivesMapViewController.h"
#import "ASIDownloadCache.h"
#import "NinaHelper.h"
#import "EditProfileViewController.h"
#import "LoginController.h"
#import "FullPerspectiveViewController.h"

@interface MemberProfileViewController() 
-(void) blankLoad;
-(void) toggleFollow;
-(IBAction)editUser;

@end


@implementation MemberProfileViewController

@synthesize username;
@synthesize user, profileImageView, headerView;
@synthesize usernameLabel, userDescriptionLabel;
@synthesize followButton, locationLabel;
@synthesize followersButton, followingButton, placeMarkButton;

#pragma mark - View lifecycle

- (void)viewDidLoad{    
    [[NSBundle mainBundle] loadNibNamed:@"ProfileHeaderView" owner:self options:nil];
    
    [super viewDidLoad];
    loadingMore = true;
    hasMore = true;
	
    self.tableView.tableHeaderView = self.headerView;
    
	[self blankLoad];
}

-(IBAction)editUser{
    
    EditProfileViewController *editProfileViewController = [[EditProfileViewController alloc] initWithStyle:UITableViewStyleGrouped];
    editProfileViewController.user = self.user;
    editProfileViewController.delegate = self;
    
    UINavigationController *navBar=[[UINavigationController alloc]initWithRootViewController:editProfileViewController];
    [StyleHelper styleNavigationBar:navBar.navigationBar];
    [self.navigationController presentModalViewController:navBar animated:YES];
    [navBar release];
    
    [editProfileViewController release]; 
    
}

-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [StyleHelper styleBackgroundView:self.tableView];
    
    self.profileImageView.layer.cornerRadius = 4.0f;
    self.profileImageView.layer.borderWidth = 1.0f;
    self.profileImageView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.profileImageView.layer.masksToBounds = YES; 
    
    [StyleHelper styleInfoView:self.headerView];
    
    for (Perspective *perspective in perspectives){
        if (perspective.modified){
            perspective.modified = false;            
            [self.tableView reloadData];
            break;
        }
    }
    
}

-(void) blankLoad{
    UIImage *profileImage = [UIImage imageNamed:@"default_profile_image.png"];
    self.profileImageView.image = profileImage;
    
    if ((self.user.username == (id)[NSNull null] || self.user.username.length == 0) && (self.username == (id)[NSNull null] || self.username.length == 0)) {
        self.usernameLabel.text = @"Your Name Here";
    } else {
        self.usernameLabel.text = @"";
    }
    self.locationLabel.text = @"";
    self.userDescriptionLabel.text = @"";
    
    self.followingButton.detailLabel.text = @"Following";    
    self.followersButton.detailLabel.text = @"Followers";
    self.placeMarkButton.detailLabel.text = @"Places";
    
    self.followingButton.numberLabel.text = @"-";
    self.followingButton.numberLabel.text = @"-";
    self.followingButton.numberLabel.text = @"-";
    
    self.placeMarkButton.enabled = false;
    self.followButton.enabled = false;
    self.followersButton.enabled = false;
    self.followingButton.enabled = false;
    
    [self mainContentLoad];
}

-(IBAction) userPerspectives{
    PerspectivesMapViewController *userPerspectives = [[PerspectivesMapViewController alloc] init];
    userPerspectives.username = self.user.username;
    userPerspectives.user = self.user;
    [self.navigationController pushViewController:userPerspectives animated:YES];
    [userPerspectives release];
}

-(IBAction) userFollowers{
    FollowViewController *followViewController = [[FollowViewController alloc] initWithUser:user andFollowing:false];
    [self.navigationController pushViewController:followViewController animated:YES];
    [followViewController release];
}

-(IBAction) userFollowing{
    FollowViewController *followViewController = [[FollowViewController alloc] initWithUser:user andFollowing:true];
    [self.navigationController pushViewController:followViewController animated:YES];
    [followViewController release];
}

-(void) loadData{
    self.usernameLabel.text = self.user.username;
    self.locationLabel.text = self.user.city;
    self.userDescriptionLabel.text = self.user.description;
    
    
    self.followingButton.detailLabel.text = @"Following";    
    self.followersButton.detailLabel.text = @"Followers";
    self.placeMarkButton.detailLabel.text = @"Places";
    
    self.placeMarkButton.enabled = true;
    self.followersButton.enabled = true;
    self.followingButton.enabled = true;
    
    [self.followButton setTitle:@"Follow" forState:UIControlStateNormal];
    [StyleHelper styleFollowButton:self.followButton];
        
    if (self.user.following){
        [self toggleFollow];
    } else {
        self.followButton.enabled = true;
    }
    
    self.followingButton.numberLabel.text = [NSString stringWithFormat:@"%i", self.user.followingCount];
    self.followersButton.numberLabel.text = [NSString stringWithFormat:@"%i", self.user.followerCount];
    self.placeMarkButton.numberLabel.text = [NSString stringWithFormat:@"%i", self.user.placeCount];
    
    if (perspectives == nil && self.user.placeCount != 0){
        loadingMore = true;
        NSString *urlString = [NSString stringWithFormat:@"%@/v1/users/%@/", [NinaHelper getHostname], self.username];		
        
        NSURL *url = [NSURL URLWithString:urlString];
        
        ASIHTTPRequest  *request =  [[[ASIHTTPRequest  alloc]  initWithURL:url] autorelease];
        
        [request setDelegate:self];
        [request setTag:13];
        [NinaHelper signRequest:request];
        [request startAsynchronous];
        
    } else {
        [self.tableView reloadData];
    }
    
    if ([self.username isEqualToString:[NinaHelper getUsername]]){
        UIBarButtonItem *editButton =  [[UIBarButtonItem  alloc]initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editUser)];
        self.navigationItem.rightBarButtonItem = editButton;
        [editButton release];
        
        [self.followButton removeFromSuperview];
    }
    
    self.profileImageView.photo = self.user.profilePic;
    [self.profileImageView loadImage];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void) mainContentLoad {
    NSString *currentUser = [NinaHelper getUsername];
    
    if ((currentUser || currentUser.length > 0) && (!self.username || currentUser.length == 0)) {
        self.username = currentUser;
    }
    
    if ((self.user.username == (id)[NSNull null] || self.user.username.length == 0) && (self.username == (id)[NSNull null] || self.username.length == 0)) {
        self.navigationItem.title = @"Your Profile";
    } else {
        NSString *getUsername;
        
        if (!self.user || self.user.username.length == 0) {
            getUsername = self.username;
        } else {
            getUsername = self.user.username;
            self.username = getUsername;
        }
        
        self.navigationItem.title = @"Profile";
        loadingMore = true;
        // Call url to get profile details
        NSString *urlText = [NSString stringWithFormat:@"%@/v1/users/%@", [NinaHelper getHostname], getUsername];
        
        NSURL *url = [NSURL URLWithString:urlText];
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request setDelegate:self];
        [request setTag:10];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [NinaHelper signRequest:request];
        [request startAsynchronous];
    }
}

#pragma mark -
#pragma mark Login Controller Delegate
-(void) loadContent {
    // Go back through navigation stack
    for (int i=[[[self navigationController] viewControllers] count] - 2; i > 0; i--) {
        NSObject *parentController = [[[self navigationController] viewControllers] objectAtIndex:i];
        
        if ([parentController isKindOfClass:[MemberProfileViewController class]]) {
            MemberProfileViewController *profile = (MemberProfileViewController *)[[[self navigationController] viewControllers] objectAtIndex:i];
            [profile mainContentLoad];
        } else if ([parentController isKindOfClass:[PlacePageViewController class]]) {
            PlacePageViewController *place = (PlacePageViewController *)[[[self navigationController] viewControllers] objectAtIndex:i];
            [place mainContentLoad];
        } else if ([parentController isKindOfClass:[FullPerspectiveViewController class]]) {
            FullPerspectiveViewController *perspective = (FullPerspectiveViewController *)[[[self navigationController] viewControllers] objectAtIndex:i];
            [perspective mainContentLoad];
        }
    }
    
    [self mainContentLoad];
}

#pragma mark -
#pragma mark Follow/Unfollow

-(IBAction) followUser{
    NSString *currentUser = [NinaHelper getUsername];
    
    if (currentUser == (id)[NSNull null] || currentUser.length == 0) {
        UIAlertView *baseAlert;
        NSString *alertMessage = @"Sign up or log in to follow people and get updates on places they love";
        baseAlert = [[UIAlertView alloc] 
                     initWithTitle:nil message:alertMessage 
                     delegate:self cancelButtonTitle:@"Not Now" 
                     otherButtonTitles:@"Let's Go", nil];
        
        [baseAlert show];
        [baseAlert release];
    } else {
        // Get the URL to call to follow/unfollow
        
        NSString *actionURL = [NSString stringWithFormat:@"%@/v1/users/%@/follow", [NinaHelper getHostname], self.user.username];
        DLog(@"Follow/unfollow url is: %@", actionURL);
        NSURL *url = [NSURL URLWithString:actionURL];
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request setRequestMethod:@"POST"];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [request setDelegate:self];
        [request setTag:11];
        [NinaHelper signRequest:request];
        [request startAsynchronous];
    }	
}

#pragma mark - Unregistered experience methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        LoginController *loginController = [[LoginController alloc] init];
        loginController.delegate = self;
        
        UINavigationController *navBar=[[UINavigationController alloc]initWithRootViewController:loginController];
        [self.navigationController presentModalViewController:navBar animated:YES];
        [navBar release];
        [loginController release];
    }
}

#pragma mark -
#pragma mark ASIHTTPRequest Delegate Methods

- (void)requestFinished:(ASIHTTPRequest *)request{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    loadingMore = false;
    if (request.responseStatusCode != 200){
        [NinaHelper handleBadRequest:request sender:self];
        return;
    }
    
    switch (request.tag){
        case 10:
        {    
            NSString *responseString = [request responseString];            
            DLog(@"profile get returned: %@", responseString);
            
            // Place an asynchronous request to get the profile image
            /*
             NSString *picURL = [NSString stringWithFormat:@"%@", [self.targetProfile objectForKey:@"pho"]];
             NSURL *targetURL = [NSURL URLWithString:picURL];
             ASIHTTPRequest *picRequest = [ASIHTTPRequest requestWithURL:targetURL];
             
             */
            
            NSDictionary *jsonDict =  [responseString JSONValue];
            
            self.user = [[[User alloc] initFromJsonDict:jsonDict]autorelease];    
            
            if (self.user.following || [self.username isEqualToString:[NinaHelper getUsername]] ){
                [self toggleFollow];
            }
            
            if ([jsonDict objectForKey:@"perspectives"]){
                //has perspectives in call, seed with to make quicker
                NSMutableArray *rawPerspectives = [jsonDict objectForKey:@"perspectives"];                
                perspectives = [[NSMutableArray alloc] initWithCapacity:[rawPerspectives count]];
                
                for (NSDictionary* dict in rawPerspectives){
                    Perspective* newPerspective = [[Perspective alloc] initFromJsonDict:dict];
                    newPerspective.user = self.user;
                    [perspectives addObject:newPerspective]; 
                    [newPerspective release];
                }
            }

            [self loadData];
            break;
        }
        case 11:
        {
            [self toggleFollow];
            break;
        }
            
        case 12:
        {
            DLog(@"Image request finished");
            // Get data and convert to image
            NSData *responseData = [request responseData];
            UIImage *newImage = [UIImage imageWithData:responseData];
            
            self.profileImageView.image = newImage;
        }
        case 13:
        {
            NSString *jsonString = [request responseString];
            
            DLog(@"Got JSON BACK: %@", jsonString);
            // Create a dictionary from the JSON string

            NSMutableArray *rawPerspectives = [[jsonString JSONValue] objectForKey:@"perspectives"];
            perspectives = [[NSMutableArray alloc] initWithCapacity:[rawPerspectives count]];
            
            for (NSDictionary* dict in rawPerspectives){
                Perspective* newPerspective = [[Perspective alloc] initFromJsonDict:dict];
                newPerspective.user = self.user;
                [perspectives addObject:newPerspective]; 
                [newPerspective release];
            }
            
            [self.tableView reloadData];            
        }
        case 14:
        {
            NSString *responseString = [request responseString];            
            DLog(@"perspectives get returned: %@", responseString);
                        
            NSDictionary *jsonDict =  [responseString JSONValue];
            
            
            if ([jsonDict objectForKey:@"perspectives"]){
                //has perspectives in call, seed with to make quicker
                NSMutableArray *rawPerspectives = [jsonDict objectForKey:@"perspectives"];               
                if ([rawPerspectives count] == 0){
                    hasMore = false;
                }
                for (NSDictionary* dict in rawPerspectives){
                    Perspective* newPerspective = [[Perspective alloc] initFromJsonDict:dict];
                    newPerspective.user = self.user;
                    [perspectives addObject:newPerspective]; 
                    [newPerspective release];
                }
            }
            
            loadingMore = false;
            [self loadData];
            break;
        }
    }

}

-(void) toggleFollow{
    self.followButton.enabled = FALSE;
    self.followButton.titleLabel.textColor = [UIColor grayColor];
}

- (void)requestFailed:(ASIHTTPRequest *)request{
    [NinaHelper handleBadRequest:request sender:self];
}


#pragma mark Tableview Methods

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{    
    //a visible perspective row PerspectiveTableViewCell
    if ((self.user.username == (id)[NSNull null] || self.user.username.length == 0) && (self.username == (id)[NSNull null] || self.username.length == 0)) {
        return 100;
    } else {
        if ((perspectives) && [perspectives count] == 0) {
            return 70;
        } else if (indexPath.row >= [perspectives count]){
            return 44;
        } else {
            Perspective *perspective;
            perspective = [perspectives objectAtIndex:indexPath.row];
            
            return [PerspectiveTableViewCell cellHeightForPerspective:perspective];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if ((self.user.username == (id)[NSNull null] || self.user.username.length == 0) && (self.username == (id)[NSNull null] || self.username.length == 0)) {
        return 1;
    } else {
        if (perspectives) {
            if (loadingMore){   
                return [perspectives count] +1;
            }else{
                return [perspectives count];
            }
        } else {
            return 1;
        }
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *perspectiveCellIdentifier = @"Cell";
    static NSString *loginCellIdentifier = @"LoginCell";
    static NSString *noActivityCellIdentifier = @"NoActivityCell";
    
    UITableViewCell *cell;
    
    if ((self.user.username == (id)[NSNull null] || self.user.username.length == 0) && (self.username == (id)[NSNull null] || self.username.length == 0)) {
        cell = [tableView dequeueReusableCellWithIdentifier:loginCellIdentifier];
    } else if ((perspectives) && [perspectives count] == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:noActivityCellIdentifier];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:perspectiveCellIdentifier];
    }
    
    if ((perspectives) && [perspectives count] == 0) {
        tableView.allowsSelection = NO;
    } else {
        tableView.allowsSelection = YES;
    }
    
    if (cell == nil) {
        if ((self.user.username == (id)[NSNull null] || self.user.username.length == 0) && (self.username == (id)[NSNull null] || self.username.length == 0)) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:loginCellIdentifier] autorelease];
            
            cell.detailTextLabel.text = @"";
            cell.textLabel.text = @"";
            
            UITextView *unregisteredText = [[UITextView alloc] initWithFrame:CGRectMake(10, 10, 300, 80)];
            
            unregisteredText.text = @"Sign up or log in to get your own profile and see places you recently placemarked.\n\nTap here to get started.";
            
            
            unregisteredText.font = [UIFont fontWithName:@"Helvetica" size:14.0];
            [unregisteredText setUserInteractionEnabled:NO];
            [unregisteredText setBackgroundColor:[UIColor clearColor]];
            
            unregisteredText.tag = 778;
            [cell addSubview:unregisteredText];
            [unregisteredText release];
            
            cell.accessoryType = UITableViewCellAccessoryNone;
            return cell;
        } else if ((perspectives) && [perspectives count] == 0) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:noActivityCellIdentifier] autorelease];
            
            cell.detailTextLabel.text = @"";
            cell.textLabel.text = @"";
            
            UITextView *errorText = [[UITextView alloc] initWithFrame:CGRectMake(10, 10, 300, 50)];
            
            if ([self.username isEqualToString:[NinaHelper getUsername]]) {
                errorText.text = @"You haven't bookmarked any places yet";
            } else {
                errorText.text = [NSString stringWithFormat:@"%@ hasn't bookmarked any places yet", self.username];
            }

            errorText.font = [UIFont fontWithName:@"Helvetica" size:14.0];
            [errorText setUserInteractionEnabled:NO];
            [errorText setBackgroundColor:[UIColor clearColor]];
            
            errorText.tag = 778;
            [cell addSubview:errorText];
            [errorText release];

            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
            return cell;
            
        } else if ( indexPath.row >= [perspectives count] ){
            NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"SpinnerTableCell" owner:self options:nil];
            
            for(id item in objects){
                if ( [item isKindOfClass:[UITableViewCell class]]){
                    cell = item;
                }
            }      
        } else {
            Perspective *perspective = [perspectives objectAtIndex:indexPath.row];
            
            NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"PerspectiveTableViewCell" owner:self options:nil];
            
            for(id item in objects){
                if ( [item isKindOfClass:[UITableViewCell class]]){
                    PerspectiveTableViewCell *pcell = (PerspectiveTableViewCell *)item;                  
                    [PerspectiveTableViewCell setupCell:pcell forPerspective:perspective userSource:true];
                    cell = pcell;
                    break;
                }
            }    
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ((self.user.username == (id)[NSNull null] || self.user.username.length == 0) && (self.username == (id)[NSNull null] || self.username.length == 0)) {
        LoginController *loginController = [[LoginController alloc] init];
        loginController.delegate = self;
        
        UINavigationController *navBar=[[UINavigationController alloc]initWithRootViewController:loginController];
        [self.navigationController presentModalViewController:navBar animated:YES];
        [navBar release];
        [loginController release];
    } else if (indexPath.row < [perspectives count]){ 
        //in case some jackass tries to click the spin wait
        Perspective *perspective = [perspectives objectAtIndex:indexPath.row];
        PlacePageViewController *placePageViewController = [[PlacePageViewController alloc] initWithPlace:perspective.place];
        placePageViewController.referrer = self.user;
        
        [[self navigationController] pushViewController:placePageViewController animated:YES];
        [placePageViewController release];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    
    float reload_distance = 10;
    if(hasMore && y > h + reload_distance && loadingMore == false) {
        loadingMore = true;
        
        // Call url to get profile details
        NSString *urlText = [NSString stringWithFormat:@"%@/v1/users/%@/perspectives?start=%i", [NinaHelper getHostname], self.username, [perspectives count]];
        
        NSURL *url = [NSURL URLWithString:urlText];
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request setDelegate:self];
        [request setTag:14];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [NinaHelper signRequest:request];
        [request startAsynchronous];
        
        [self.tableView reloadData];
    }
}



- (void)dealloc{
    [NinaHelper clearActiveRequests:10];
    
    [username release];
    [user release];
    
    [locationLabel release];
    [profileImageView release];
    [usernameLabel release];
    [userDescriptionLabel release];
    [followButton release];
    
    [super dealloc];
}

@end
