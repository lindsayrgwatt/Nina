//
//  AboutUsController.m
//  Nina
//
//  Created by Lindsay Watt on 11-10-17.
//  Copyright 2011 Placeling. All rights reserved.
//

#import "AboutUsController.h"
#import "GenericWebViewController.h"

@implementation AboutUsController

@synthesize contactButton, termsButton, privacyButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"About Placeling";
    [StyleHelper styleBookmarkButton:self.contactButton];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc
{
    [contactButton release];
    [termsButton release];
    [privacyButton release];
    [super dealloc];
}

-(IBAction) crashPressed:(id) sender { [NSException raise:NSInvalidArgumentException format:@"Foo must not be nil"]; }

#pragma mark -
#pragma mark Contact Us

- (IBAction)contactUs:(id) sender
{
	MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
	controller.mailComposeDelegate = self;
	[controller setSubject:@"Greetings Placeling!"];
    [controller setToRecipients:[NSArray arrayWithObject:@"contact@placeling.com"]];
	if (controller) [self presentModalViewController:controller animated:YES];
	[controller release];	
}

- (void)mailComposeController:(MFMailComposeViewController*)controller  
          didFinishWithResult:(MFMailComposeResult)result 
                        error:(NSError*)error;
{
	[self dismissModalViewControllerAnimated:YES];
}

-(IBAction) showTerms {
    GenericWebViewController *genericWebViewController = [[GenericWebViewController alloc] initWithUrl:[NSString stringWithFormat:@"%@/terms_of_service", [NinaHelper getHostname]]];
    
    genericWebViewController.title = @"Terms & Conditions";
    [self.navigationController pushViewController:genericWebViewController animated:true];
    
    [genericWebViewController release];
}

-(IBAction) showPrivacy {
    GenericWebViewController *genericWebViewController = [[GenericWebViewController alloc] initWithUrl:[NSString stringWithFormat:@"%@/privacy_policy", [NinaHelper getHostname]]];
    
    genericWebViewController.title = @"Privacy Policy";
    [self.navigationController pushViewController:genericWebViewController animated:true];
    
    [genericWebViewController release];
}

@end
