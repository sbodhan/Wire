//
//  SignUpViewController.m
//  Wire
//
//  Created by DetroitLabs on 6/27/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import "SignUpViewController.h"
@import Firebase;

@interface SignUpViewController ()
@property (weak, nonatomic) IBOutlet UITextField *emailTF;
@property (weak, nonatomic) IBOutlet UITextField *usernameTF;
@property (weak, nonatomic) IBOutlet UITextField *passwordTF;
@property (weak, nonatomic) IBOutlet UITextField *repeatPasswordTF;
@property (weak, nonatomic) IBOutlet UILabel *invalidEntry;

@end

@implementation SignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)signUpButtonPressed:(id)sender {
    NSLog(@"SignUp Clicked");
    if(![_passwordTF.text isEqualToString:_repeatPasswordTF.text]){
        _invalidEntry.hidden = false;
        _invalidEntry.text=@"Unmatched password";
        
        
    }
    else{
    [[FIRAuth auth]
     createUserWithEmail:_emailTF.text
     password:_passwordTF.text
     completion:^(FIRUser *_Nullable user,
                  NSError *_Nullable error) {
         NSLog(@"$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$USER= %@ ERROR=%@", user, error );
         
        if(error.code == 17007){
             NSLog(@"DUPLICATE: %ld", error.code);
             _invalidEntry.hidden = false;
             _invalidEntry.text = @"Email already in use";
         }
        else if(error.code == 17026){
             NSLog(@"PASSWORDFORMAT: %ld", error.code);
             _invalidEntry.hidden = false;
             _invalidEntry.text = @"Invalid password";
         }
         else if(error){
             NSLog(@"OtherErrors: %ld", error.code);
             _invalidEntry.hidden = false;
             _invalidEntry.text=@"Invalid email or password";
         }
         
         
     }
     ];
    }

    
}



@end
