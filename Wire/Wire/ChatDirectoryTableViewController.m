//
//  ChatDirectoryTableViewController.m
//  Wire
//
//  Created by DetroitLabs on 6/27/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import "ChatDirectoryTableViewController.h"
#import "ChatViewController.h"
#import "UserProfile.h"
@import FirebaseDatabase;
@import Firebase;

@interface ChatDirectoryTableViewController () <UITableViewDelegate, UITableViewDataSource>

@property(strong, nonatomic) UserProfile *currentUser;

@end

@implementation ChatDirectoryTableViewController

- (void)viewDidLoad {
    [self getCurrentUserProfileFromFirebase];
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source
    - (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatDirectoryCell" forIndexPath:indexPath];
    return cell;
}

- (IBAction)signOutBtnPressed:(id)sender {
    NSError *error;
    [[FIRAuth auth] signOut:&error];
    if (!error) {

    }
}


-(void)getCurrentUserProfileFromFirebase {
    FIRDatabaseReference *UserProfileRef = [[[FIRDatabase database]reference]child:@"userprofile"];
    FIRDatabaseQuery *currentUserProfileQuery = [[UserProfileRef queryOrderedByChild:@"userId"] queryEqualToValue:[FIRAuth auth].currentUser.uid];
    [currentUserProfileQuery observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
    
        _currentUser = [[UserProfile alloc]initUserProfileWithEmail:snapshot.value[@"email"] username:snapshot.value[@"username"] uid:snapshot.value[@"userId"]];
        _currentUser.profileImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:snapshot.value[@"profilePhotoDownloadURL"]]]];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"PROFILE IMAGE: %@", _currentUser.profileImage.description);

        });
    }];
}

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ChatViewController *destVC = [segue destinationViewController];
    destVC.currentUserProfile = _currentUser;
    
}

@end
