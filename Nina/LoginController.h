//
//  LoginController.h
//  
//
//  Created by Ian MacKinnon on 11-08-03.
//  Copyright 2011 placeling. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@protocol LoginControllerDelegate;

@interface LoginController : UIViewController<UITextFieldDelegate, RKObjectLoaderDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, MBProgressHUDDelegate, UIAlertViewDelegate>{
    IBOutlet UITextField *username;
    IBOutlet UITextField *password;
    IBOutlet UIButton *submitButton;
    IBOutlet UIButton *forgotPasswordButton;
    id <LoginControllerDelegate> delegate;
    MBProgressHUD *HUD;
    NSString *savedUsername;
}

@property(nonatomic, retain) IBOutlet UITextField *username;
@property(nonatomic, retain) IBOutlet UITextField *password;
@property(nonatomic, retain) IBOutlet UIButton *submitButton;
@property(nonatomic, retain) IBOutlet UIButton *forgotPasswordButton;
@property(nonatomic, assign) id <LoginControllerDelegate> delegate;

-(IBAction)cancel;

-(IBAction) submitLogin;
-(IBAction) forgotPassword;
-(IBAction) signupFacebook;
-(IBAction) signupOldSchool;

@end

@protocol LoginControllerDelegate
- (void) loadContent;
@end
