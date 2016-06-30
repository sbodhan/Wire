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
NSString *newPwd;
NSString *newRepeatPwd;

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)signUpButtonPressed:(id)sender {
    [self signUpUserToFirebase];
}

-(void)signUpUserToFirebase{
    [self removeSpaceFromPassword];
    [self validateInputs];
}

-(void)removeSpaceFromPassword{
     newPwd = [_passwordTF.text stringByReplacingOccurrencesOfString:@" " withString:@""];
     newRepeatPwd = [_repeatPasswordTF.text stringByReplacingOccurrencesOfString:@" " withString:@""];
}

-(void)validateInputs{
    if(![newPwd isEqualToString:newRepeatPwd]){
        _invalidEntry.hidden = false;
        _invalidEntry.text=@"Unmatched password";
    }
    else{
        [[FIRAuth auth]
         createUserWithEmail:_emailTF.text
         password:newPwd
         completion:^(FIRUser *_Nullable user,
                  NSError *_Nullable error) {
         
             if(error.code == 17007){
             _invalidEntry.hidden = false;
             _invalidEntry.text = @"Email already in use";
             }
             else if(error.code == 17026){
             _invalidEntry.hidden = false;
             _invalidEntry.text = @"Invalid password";
             }
             else if(error){
             _invalidEntry.hidden = false;
             _invalidEntry.text=@"Invalid email or password";
             }
         }];
    }
}

@end
