//
//  ChatDirectoryTableViewController.m
//  Wire
//
//  Created by DetroitLabs on 6/27/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import "ChatDirectoryTableViewController.h"
@import FirebaseDatabase;
@import Firebase;

@interface ChatDirectoryTableViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation ChatDirectoryTableViewController

- (void)viewDidLoad {
    [self setValuesToDatabase];
    [super viewDidLoad];
  
  //ref = [[FIRDatabase database] reference];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return 1;
}


-(void)setValuesToDatabase{
    
    UserProfile *newUserProfile = [[UserProfile alloc]init];
    newUserProfile.username = @"Sarmila";
    newUserProfile.email = @"something@hotmail.com";
   // newUserProfile.userProfileArray =  [[NSMutableArray alloc]init];
    NSLog(@"username %@\n email %@\n",newUserProfile.username, newUserProfile.email);
 
    NSDictionary *newUserProfileInfo = @{@"username": newUserProfile.username, @"email": newUserProfile.email};
    FIRDatabaseReference *ref = [[FIRDatabase database] reference];
    FIRDatabaseReference *userProfileRef = [ref child:@"userprofile"].childByAutoId;
    [userProfileRef setValue:newUserProfileInfo];

}

//- (IBAction)signOut:(id)sender {
//    NSLog(@"signout pressed");
//    NSError *error;
//    [[FIRAuth auth] signOut:&error];
//    if (!error) {
//        NSLog(@"%@", error)
//        // Sign-out succeeded
//    }
//    
//}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatDirectoryCell" forIndexPath:indexPath];
    
    
    return cell;
}
- (IBAction)signOutBtnPressed:(id)sender {
    NSError *error;
    [[FIRAuth auth] signOut:&error];
    if (!error) {
        // Sign-out succeeded
    }
}




/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

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

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
