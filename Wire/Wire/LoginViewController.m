//
//  LoginViewController.m
//  Wire
//
//  Created by DetroitLabs on 6/27/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import "LoginViewController.h"
@import Firebase;

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *emailTF;
@property (weak, nonatomic) IBOutlet UITextField *passwordTF;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonPressed:(id)sender {
    NSLog(@"Login Pressed");
    [[FIRAuth auth] signInWithEmail:@"email@gmail.com"
                           password:@"password"
                         completion:^(FIRUser *user, NSError *error) {
                             NSLog(@"%@ %@", user, error);
                             // ...
                         }];
    
}



@end
