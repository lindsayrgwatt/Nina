//
//  LoginController.h
//  
//
//  Created by Ian MacKinnon on 11-08-03.
//  Copyright 2011 placeling. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASIHTTPRequestDelegate.h"
#import "ASIHTTPRequest.h"
#import "NinaHelper.h"
#import "Facebook.h"


@interface LoginController : UIViewController<UITextFieldDelegate, ASIHTTPRequestDelegate, UITextFieldDelegate, FBRequestDelegate>{
    IBOutlet UITextField *username;
    IBOutlet UITextField *password;
    IBOutlet UIButton *submitButton;
    UIViewController *delegate; //for telling to refresh
}

@property(nonatomic, retain) IBOutlet UITextField *username;
@property(nonatomic, retain) IBOutlet UITextField *password;
@property(nonatomic, retain) IBOutlet UIButton *submitButton;
@property(nonatomic, retain) UIViewController *delegate;


-(IBAction)cancel;

-(IBAction) submitLogin;
-(IBAction) signupFacebook;
-(IBAction) signupOldSchool;


@end
