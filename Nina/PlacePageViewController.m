//
//  PlacePageViewController.m
//  placeling2
//
//  Created by Lindsay Watt on 11-06-23.
//  Copyright 2011 Placeling. All rights reserved.
//

#import "PlacePageViewController.h"

#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

#import <QuartzCore/QuartzCore.h>

#import "Perspective.h"
#import "Photo.h"
#import "Place.h"

#import "NSString+SBJSON.h"
#import <CoreLocation/CoreLocation.h>

#define kMinCellHeight 60

@interface PlacePageViewController ()
-(void) loadData;
-(void) blankLoad;
-(void) toggleBookmarked;
@end

@implementation PlacePageViewController

@synthesize dataLoaded;
@synthesize google_id, google_ref;
@synthesize place=_place, mapImage;
@synthesize bookmarkButton, phoneButton;
@synthesize nameLabel, addressLabel, cityLabel, categoriesLabel;
@synthesize segmentedControl;
@synthesize mapImageView, googlePlacesButton, websiteButton;

- (id) initWithPlace:(Place *)place{
    if(self = [super init]){
        self.place = place;
        self.google_id = place.google_id;
	}
	return self;
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
    // Initializations
    [self blankLoad];
    
    NSString *urlText = [NSString stringWithFormat:@"%@/v1/places/%@?google_ref=%@", [NinaHelper getHostname], self.google_id, self.google_ref];
    
    NSURL *url = [NSURL URLWithString:urlText];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [NinaHelper signRequest:request];
    
    [request setDelegate:self];
    [request startAsynchronous];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

#pragma mark - Selectors for responding to initial URLs

-(void)requestFailed:(ASIHTTPRequest *)request{
    [NinaHelper handleBadRequest:request sender:self];
}


- (void)requestFinished:(ASIHTTPRequest *)request{    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    if (200 != [request responseStatusCode]){
		[NinaHelper handleBadRequest:request sender:self];
	} else {
        NSString *responseString = [request responseString];        
        DLog(@"%@", responseString);
        
        NSDictionary *json_place = [responseString JSONValue];  
        
        Place *newPlace = [[Place alloc] initFromJsonDict:json_place];
        
        self.place = newPlace;
        [newPlace release];
        
        [self loadData];
        
        if (self.place.bookmarked){
            [self toggleBookmarked];
        }
	}
}

- (void)mapDownloaded:(ASIHTTPRequest *)request{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    int statusCode = [request responseStatusCode];
    NSString *responseBody = [request responseString];
    if ([request responseStatusCode] != 200){
        DLog(@"%i - %@", statusCode, responseBody);
    } else {
        NSData *responseData = [request responseData];
        self.mapImage = [UIImage imageWithData:responseData];
        
        self.mapImageView.image = self.mapImage;
    }
}


#pragma mark - Image Lazy Loader Helpers


#pragma mark - UIScrollViewDelegate


#pragma mark - Table view delegate
-(void) blankLoad{
    //puts empty values to show while data being downloaded
    self.nameLabel.text = @"";
    self.addressLabel.text = @"";
    self.phoneButton.titleLabel.text = @"";
    self.googlePlacesButton.titleLabel.textColor = [UIColor grayColor];
    self.categoriesLabel.text = @"";
    self.cityLabel.text = @"";
}

-(void) loadData{
    self.nameLabel.text = self.place.name;
    self.addressLabel.text = self.place.address;
    
    // Call asychronously to get image
    NSString* lat = [NSString stringWithFormat:@"%f",self.place.location.coordinate.latitude];
    NSString* lng = [NSString stringWithFormat:@"%f",self.place.location.coordinate.longitude];    
    
    NSString* imageMapWidth = [NSString stringWithFormat:@"%i", (int)self.mapImageView.frame.size.width ];
    NSString* imageMapHeight = [NSString stringWithFormat:@"%i", (int)self.mapImageView.frame.size.height ];
    
    NSString *mapURL = [NSString stringWithFormat:@"http://maps.google.com/maps/api/staticmap?center=%@,%@&zoom=15&size=%@x%@&&markers=color:red%%7C%@,%@&sensor=false", lat, lng, imageMapWidth, imageMapHeight, lat, lng];
    NSURL *url = [NSURL URLWithString:mapURL];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDidFinishSelector:@selector(mapDownloaded:)];
    [request setDidFailSelector:@selector(requestWentWrong:)];
    [request setDelegate:self];
    [request startAsynchronous];
        
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    self.phoneButton.titleLabel.text = self.place.phone;
    self.cityLabel.text = self.place.city;
    self.categoriesLabel.text = [self.place.categories componentsJoinedByString:@","];
}


#pragma mark - IBActions

-(IBAction) changedSegment{
    if(self.segmentedControl.selectedSegmentIndex ==0){
        
    }
}

-(IBAction) googlePlacePage{
    NSURL *webURL = [NSURL URLWithString:self.place.googlePlacesUrl];
    [[UIApplication sharedApplication] openURL: webURL];
    
}

- (IBAction) phonePlace {    
    UIDevice *device = [UIDevice currentDevice];
    if ([[device model] isEqualToString:@"iPhone"] ) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", self.place.phone]]];
    } else {
        UIAlertView *Notpermitted=[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Your device doesn't support this feature." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [Notpermitted show];
        [Notpermitted release];
    }
}


-(IBAction) bookmark {
    NSString *urlText = [NSString stringWithFormat:@"%@/v1/places/%@/perspectives", [NinaHelper getHostname], self.place.pid];

    NSURL *url = [NSURL URLWithString:urlText];
    
    CLLocationManager *locationManager = [LocationManagerManager sharedCLLocationManager];
    CLLocation *location =  locationManager.location;
    
    NSString* lat = [NSString stringWithFormat:@"%f", location.coordinate.latitude];
    NSString* lng = [NSString stringWithFormat:@"%f", location.coordinate.longitude];
    float accuracy = pow(location.horizontalAccuracy,2)  + pow(location.verticalAccuracy,2);
    accuracy = sqrt( accuracy ); //take accuracy as single vector, rather than 2 values -iMack
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:lat forKey:@"lat"];
    [request setPostValue:lng forKey:@"long"];
    [request setPostValue:[NSString stringWithFormat:@"%f", accuracy] forKey:@"accuracy"];
    
    [request setRequestMethod:@"POST"];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(bookmarkFinished:)];
    [request setDidFailSelector:@selector(requestFailed:)];
    
    [NinaHelper signRequest:request];
    [request startAsynchronous];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)bookmarkFinished:(ASIFormDataRequest *)request{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    NSString *responseString = [request responseString];
    DLog(@"Returned: %@", responseString);
    // NSDictionary *placeOutcome = [responseString JSONValue];  
    [self toggleBookmarked];
}

-(void) toggleBookmarked{
    
    self.bookmarkButton.enabled = false;
    self.bookmarkButton.titleLabel.textColor = [UIColor grayColor];
    self.bookmarkButton.titleLabel.text = @"bookmarked";
}


- (void)dealloc{
    [google_id release];
    [google_ref release];
    [_place release];
    [mapImage release];
    [googlePlacesButton release];
    [bookmarkButton release];
    [phoneButton release];
    [nameLabel release];
    [addressLabel release];
    [mapImageView release];
    [websiteButton release];
    [cityLabel release];
    
    [super dealloc];
}

@end
