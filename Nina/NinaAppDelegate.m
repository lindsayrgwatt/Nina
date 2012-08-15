//
//  NinaAppDelegate.m
//  Nina
//
//  Created by Ian MacKinnon on 11-07-19.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NinaAppDelegate.h"
#import <CoreLocation/CoreLocation.h>
#import "LocationManagerManager.h"
#import "FlurryAnalytics.h"
#import "NinaHelper.h"
#import <RestKit/RestKit.h>
#import "User.h"
#import "Place.h"
#import "Perspective.h"
#import "Advertisement.h"
#import "PlacePageViewController.h"
#import "MemberProfileViewController.h"
#import "NearbySuggestedMapController.h"
#import "ASIHTTPRequest.h"
#import "Appirater.h"
#import "FindFacebookFriendsController.h"
#import "Crittercism.h"
#import "FacebookRegetViewController.h"
#import "Notification.h"
#import "Activity.h"
#import "Question.h"
#import "Answer.h"
#import "PlacemarkComment.h"
#import "UserManager.h"
#import "Suggestion.h"


@implementation NinaAppDelegate


@synthesize window=_window;
@synthesize facebook;

@synthesize navigationController=_navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    
    DLog(@"Launching with options %@", launchOptions);
    
    //Restkit initialization  
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:[NSURL URLWithString:[NinaHelper getHostname] ] ];
    [[objectManager client] setOAuth1AccessToken:[NinaHelper getAccessToken]];
    [[objectManager client] setOAuth1AccessTokenSecret:[NinaHelper getAccessTokenSecret]];
    [[objectManager client] setOAuth1ConsumerKey:[NinaHelper getConsumerKey]];
    [[objectManager client] setOAuth1ConsumerSecret:[NinaHelper getConsumerSecret]];
    //[objectManager client] set
    objectManager.client.authenticationType = RKRequestAuthenticationTypeOAuth1;  
    objectManager.client.requestQueue.showsNetworkActivityIndicatorWhenBusy = YES;
    //[[RKClient sharedClient].cache invalidateAll];
    NSError *error = nil;
    NSString *filePath = [[NSHomeDirectory() 
                            stringByAppendingPathComponent:@"Documents"] 
                           stringByAppendingPathComponent:@"NinaRestCache.sqlite"];        
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    
    DLog(@"Initializing restkit with base url: %@", objectManager.client.baseURL);
    
    //RKManagedObjectStore* objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"NinaRestCache.sqlite"];
    //objectManager.objectStore = objectStore;
    
    //objectManager.objectStore.managedObjectCache = [[DBManagedObjectCache new] autorelease];
    
    //set cache policy for restkit
    //[[objectManager client] setCachePolicy:RKRequestCachePolicyEtag | RKRequestCachePolicyTimeout|RKRequestCachePolicyLoadIfOffline ];
    //[[objectManager client] setCacheTimeout:5]; //5 seconds for now
    
    
    [objectManager.mappingProvider setMapping:[User getObjectMapping] forKeyPath:@"users"];
    [objectManager.mappingProvider setMapping:[User getObjectMapping] forKeyPath:@"followers"];
    [objectManager.mappingProvider setMapping:[User getObjectMapping] forKeyPath:@"following"];
    [objectManager.mappingProvider setMapping:[User getObjectMapping] forKeyPath:@"suggested"];
    
    [objectManager.mappingProvider setMapping:[Place getObjectMapping] forKeyPath:@"suggested_places"];
    [objectManager.mappingProvider setMapping:[Place getObjectMapping] forKeyPath:@"places"];
    [objectManager.mappingProvider setMapping:[Place getObjectMapping] forKeyPath:@"place"];
    
    [objectManager.mappingProvider setMapping:[Perspective getObjectMapping] forKeyPath:@"perspective"];
    [objectManager.mappingProvider setMapping:[Perspective getObjectMapping] forKeyPath:@"perspectives"];
    [objectManager.mappingProvider setMapping:[Perspective getObjectMapping] forKeyPath:@"referring_perspectives"];
    
    [objectManager.mappingProvider setMapping:[Advertisement getObjectMapping] forKeyPath:@"ad"];
    
    [objectManager.mappingProvider setMapping:[Activity getObjectMapping] forKeyPath:@"home_feed"];
    [objectManager.mappingProvider setMapping:[Notification getObjectMapping] forKeyPath:@"notifications"];
    
    [objectManager.mappingProvider setMapping:[Question getObjectMapping] forKeyPath:@"questions"];
    [objectManager.mappingProvider setMapping:[Answer getObjectMapping] forKeyPath:@"answers"];
    [objectManager.mappingProvider setMapping:[PlacemarkComment getObjectMapping] forKeyPath:@"placemark_comment"];
    
    RKObjectRouter *router = [RKObjectManager sharedManager].router;
    
    [router routeClass:[PlacemarkComment class] toResourcePath:@"/v1/perspectives/:perspectiveId/placemark_comments" forMethod:RKRequestMethodPOST];
    
    [objectManager.mappingProvider setMapping:[Suggestion getObjectMapping] forKeyPath:@"suggestion"];
    [objectManager.mappingProvider setMapping:[Suggestion getObjectMapping] forKeyPath:@"suggestions"];
    
    [router routeClass:[Suggestion class] toResourcePath:@"/v1/users/:userId/suggestions" forMethod:RKRequestMethodPOST];
    
    DLog(@"RKClient singleton : %@", [RKClient sharedClient]);
    
    if ([NinaHelper isProductionRun]){
        [FlurryAnalytics startSession:@"TF6YH8QMRQDXBXR9APF9"];            
    
        [Crittercism initWithAppID: @"4f2892c1b093157f7200076d" andKey:@"4f2892c1b093157f7200076dhknlm6lr" andSecret:@"bdrh0sax6ofnuwjq8zvl47omwirpe9sq"];
    }
    
    // Override point for customization after application launch.
    // Add the tab bar controller's current view as a subview of the window
    
    if (![CLLocationManager locationServicesEnabled]) {
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Disabled" message:@"Location services are disabled on your device " delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [servicesDisabledAlert show];
        [servicesDisabledAlert release];
    } else {
        CLLocationManager *manager = [LocationManagerManager sharedCLLocationManager];
        [manager setDesiredAccuracy:kCLLocationAccuracyBest];
        [manager startUpdatingLocation];
    }
    
    facebook = [[Facebook alloc] initWithAppId:[NinaHelper getFacebookAppId] andDelegate:self];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"] 
        && [defaults objectForKey:@"FBExpirationDateKey"]) {
        facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
    }
    
    
    if ( [NinaHelper getUsername] ){
        [application registerForRemoteNotificationTypes: 
         UIRemoteNotificationTypeBadge |
         UIRemoteNotificationTypeAlert |             
         UIRemoteNotificationTypeSound];
        [Crittercism setUsername:[NinaHelper getUsername]];
    }
    
    [FlurryAnalytics logAllPageViews:self.navigationController];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];    
    
    if ( [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] ){        
        NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        
        [self application:application didReceiveRemoteNotification:userInfo];
    }
    
    [Appirater appLaunched:YES];
    
    //refresh the local "me" from servers    
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/v1/users/me.json" usingBlock:^(RKObjectLoader* loader) {
        RKObjectMapping *userMapping = [User getObjectMapping];
        loader.objectMapping = userMapping;
        [loader setOnDidLoadObjects:^(NSArray *objects){
            User *user = [objects objectAtIndex:0];
            [UserManager setUser:user];
        }];
    }];
    
    
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    DLog(@"handling open url: %@", url);
    
    if ( [[url scheme] isEqualToString:@"fb280758755284342"] ){    
        return [facebook handleOpenURL:url]; 
    } else {
        if ( [[url host] isEqualToString:@"users"] ){
            NSString *username = [[url path] stringByReplacingOccurrencesOfString:@"/" withString:@""];
            MemberProfileViewController *userProfile = [[MemberProfileViewController alloc] init];
            userProfile.username = username;
            [self.navigationController pushViewController:userProfile animated:false];
            [userProfile release];
            
        } else if ( [[url host] isEqualToString:@"places"] ){
            NSString *placeId = [[url path] stringByReplacingOccurrencesOfString:@"/" withString:@""];
            
            NearbySuggestedMapController *nearbySuggestedMapController = [[NearbySuggestedMapController alloc] init];    
            nearbySuggestedMapController.category = @"";
            nearbySuggestedMapController.place_id = placeId;
            nearbySuggestedMapController.navTitle = @"My Map";
            nearbySuggestedMapController.initialIndex = 0; //start on my bookmarks
            [self.navigationController popToRootViewControllerAnimated:false];
            [self.navigationController pushViewController:nearbySuggestedMapController animated:false];
            [nearbySuggestedMapController release];
            
            //NSString *urlText = [NSString stringWithFormat:@"/v1/places/%@/unhighlight", placeId]; //unhilight, so we don't send again
            
            //[[RKClient sharedClient] post:urlText params:nil delegate:nil]; 
        } else if ( [[url host] isEqualToString:@"facebookfriends"] ){
            FindFacebookFriendsController *findFacebookFriendsController = [[FindFacebookFriendsController alloc] init];
            
            [self.navigationController pushViewController:findFacebookFriendsController animated:true];
            [findFacebookFriendsController release];        
        }
        return true;
    }
}

- (void)fbDidLogin {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
    
    NSString *currentUser = [NinaHelper getUsername];
    
    if ( currentUser ){
        NSString *urlString = [NSString stringWithFormat:@"%@/v1/auth/facebook/add", [NinaHelper getHostname]];
        NSURL *url = [NSURL URLWithString:urlString];
        
        ASIFormDataRequest *request =  [[[ASIFormDataRequest  alloc]  initWithURL:url] autorelease];
        [request setPostValue:[facebook accessToken] forKey:@"token" ];
        [request setPostValue:[facebook expirationDate] forKey:@"expiry" ];
        
        [NinaHelper signRequest:request];
        
        [request startAsynchronous];//fire and forget        
    }    
}

- (void)fbDidNotLogin:(BOOL)cancelled{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [FlurryAnalytics logEvent:@"REJECTED_PERMISSIONS"];
} 


-(void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt{
    
}

-(void)fbSessionInvalidated{
    
}

-(void)fbDidLogout{
    
}

-(void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground){
        DLog(@"Got background location update: %@", newLocation);
        NSString *currentUser = [NinaHelper getUsername];
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if ( [defaults objectForKey:@"last_location_update"]  ){
            NSNumber *timestamp = [defaults objectForKey:@"last_location_update"];
            if ( currentTime - (60*5) < [timestamp floatValue] ){
                return; //skip if last was sent less than 5 min ago
            }
        }
        
        if ( currentUser ){ //only update location if logged in
            DLog(@"Processing updated location");
            // [self localNotification:newLocation]; only for testing
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];            
            if ( [defaults objectForKey:@"ios_notification_token"] && newLocation.horizontalAccuracy < 500 ){
                //only send if possible
                [self sendBackgroundLocationToServer:newLocation];            
            }
            
            [defaults setObject:[NSNumber numberWithDouble: currentTime] forKey:@"last_location_update"];
            [defaults synchronize];
            
        }
    }
}

-(void) sendBackgroundLocationToServer:(CLLocation *)location
{
    // REMEMBER. We are running in the background if this is being executed.
    // We can't assume normal network access.
    // bgTask is defined as an instance variable of type UIBackgroundTaskIdentifier
    
    // Note that the expiration handler block simply ends the task. It is important that we always
    // end tasks that we have started.
    DLog(@"ACTIVE - updating server with location: %@", location);
    
    NSString *urlString = [NSString stringWithFormat:@"%@/v1/ios/update_location", [NinaHelper getHostname]];
    NSURL *url = [NSURL URLWithString:urlString];
    
    ASIFormDataRequest *request =  [[[ASIFormDataRequest  alloc]  initWithURL:url] autorelease];
    [request setPostValue:[NSString stringWithFormat:@"%f", location.coordinate.latitude] forKey:@"lat" ];
    [request setPostValue:[NSString stringWithFormat:@"%f", location.coordinate.longitude] forKey:@"lng" ];
        [request setPostValue:[NSString stringWithFormat:@"%f", location.horizontalAccuracy] forKey:@"accuracy" ];
    
    [NinaHelper signRequest:request];
    [request startAsynchronous];//fire and forget    
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    if ( application.applicationState == UIApplicationStateActive ){
        DLog(@"ACTIVE - received notification of %@", userInfo);
    } else {
        NSURL *url = [NSURL URLWithString:[userInfo objectForKey:@"url"]];
        [self application:application handleOpenURL:url];
    }
}

- (void)application:(UIApplication *)application 
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {    
    
    DLog(@"Registered with device token %@", newDeviceToken);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ( [defaults objectForKey:@"ios_notification_token"] ){
        if ( [[NSString stringWithFormat:@"%@", newDeviceToken] isEqualToString:[defaults objectForKey:@"ios_notification_token"]] ){
            return;            
        }            
    }
    [defaults setObject:[NSString stringWithFormat:@"%@", newDeviceToken] forKey:@"ios_notification_token"];
    
    [NinaHelper uploadNotificationToken:[NSString stringWithFormat:@"%@", newDeviceToken]];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

-(void) applicationDidEnterBackground:(UIApplication *) application
{
    // You will also want to check if the user would like background location
    // tracking and check that you are on a device that supports this feature.
    // Also you will want to see if location services are enabled at all.
    // All this code is stripped back to the bare bones to show the structure
    // of what is needed.
    User *user = [UserManager sharedMeUser];
    
    if ( [NinaHelper getUsername] && user && [user.highlightedCount intValue] > 0 ){
        CLLocationManager *locationManager = [LocationManagerManager sharedCLLocationManager];
        [locationManager startMonitoringSignificantLocationChanges];
        locationManager.delegate = self;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    [Appirater appEnteredForeground:YES];
}

-(void) applicationDidBecomeActive:(UIApplication *) application
{
    if ( [UIApplication sharedApplication].applicationState != UIApplicationStateBackground ){
        CLLocationManager *locationManager = [LocationManagerManager sharedCLLocationManager];
        [locationManager stopMonitoringSignificantLocationChanges];
        [locationManager startUpdatingLocation];
        locationManager.delegate = nil;
    }
    
    NSString *current_user = [NinaHelper getUsername];
    NinaAppDelegate *appDelegate = (NinaAppDelegate*)[[UIApplication sharedApplication] delegate];
    Facebook *_facebook = appDelegate.facebook;

    if ( current_user && _facebook.accessToken != nil && ![_facebook isSessionValid] ){
        FacebookRegetViewController *regetController = [[FacebookRegetViewController alloc] init];
        
        UINavigationController *navBar=[[UINavigationController alloc]initWithRootViewController:regetController];
        [FlurryAnalytics logAllPageViews:navBar];
        [self.navigationController presentModalViewController:navBar animated:YES];
        [navBar release];
        [regetController release];
    }    
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc{
    [_window release];
    [_navigationController release];
    [facebook release];
    [super dealloc];
}

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

@end
