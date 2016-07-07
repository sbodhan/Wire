//
//  SignUpViewController.m
//  Wire
//
//  Created by DetroitLabs on 6/27/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import "SignUpViewController.h"
#import "UserProfile.h"
@import Firebase;
@import FirebaseAuth;

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
         
             [self createUserProfileOnFirebase];
             
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

-(void)createUserProfileOnFirebase {
    if ([FIRAuth auth].currentUser != nil) {
        
        FIRDatabaseReference *currentUserProfileRef = [[[[FIRDatabase database]reference]child:@"userprofile"]childByAutoId];
        UserProfile *newUserProfile = [[UserProfile alloc]initUserProfileWithEmail:_emailTF.text username:_usernameTF.text uid:[FIRAuth auth].currentUser.uid];
        
        newUserProfile.profileImageDownloadURL = @"https://firebasestorage.googleapis.com/v0/b/wire-e0cde.appspot.com/o/default_user.png?alt=media&token=d351d796-3f49-4f8f-8ca8-7d)1cd17f510";

        NSDictionary *newUserProfileDict = @{@"email": newUserProfile.email, @"username": newUserProfile.username, @"userId": newUserProfile.uid, @"profilePhotoDownloadURL": newUserProfile.profileImageDownloadURL};
        
        [currentUserProfileRef setValue:newUserProfileDict];
    }
}


@end
