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
@import FirebaseStorage;

@interface ChatDirectoryTableViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (strong, nonatomic) UIImagePickerController *imagePicker;
//FIRStorageReference represents a reference to a Google Cloud Storage object.
@property (strong, nonatomic) FIRStorageReference *firebaseStorageRef;
@property (strong, nonatomic) NSString *currentUserProfileKey;
//An instance of FIRStorage will initialize with the default FIRApp
@property (strong, nonatomic) FIRStorage *firebaseStorage;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *currentUserProfilePhoto;


@property(strong, nonatomic) UserProfile *currentUser;

@end

@implementation ChatDirectoryTableViewController

- (void)viewDidLoad {
    [self firebaseSetUp];
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
        NSLog(@"SNAPSHOT %@", snapshot);
        _currentUserProfileKey = snapshot.key;
        
        _currentUser = [[UserProfile alloc]initUserProfileWithEmail:snapshot.value[@"email"] username:snapshot.value[@"username"] uid:snapshot.value[@"userId"]];
        _currentUser.profileImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:snapshot.value[@"profilePhotoDownloadURL"]]]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_currentUserProfilePhoto setImage:_currentUser.profileImage];
            [_usernameLabel setText:[NSString stringWithFormat:@"Hello, %@!", _currentUser.username]];
        });
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ChatViewController *destVC = [segue destinationViewController];
    destVC.currentUserProfile = _currentUser;
}

    -(void)presentCamera {
        _imagePicker = [[UIImagePickerController alloc] init];
        [_imagePicker setDelegate:self];
        [_imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        [self presentViewController:_imagePicker animated:true completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSData *imageData = UIImageJPEGRepresentation([info objectForKey:@"UIImagePickerControllerOriginalImage"], 1);
    UIImage *image = [UIImage imageWithData:imageData];
    NSData *resizedImgData =  UIImageJPEGRepresentation([self reduceImageSize:image], .50);
    [self uploadPhotoToFirebase:resizedImgData];
    [self dismissViewControllerAnimated:true completion:nil];
}

-(UIImage *)reduceImageSize:(UIImage *)image {
    CGSize newSize = CGSizeMake(image.size.width/6, image.size.height/6);
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    return smallImage;
}

#pragma mark Firebase Methods

-(void)firebaseSetUp {
    _firebaseStorage = [FIRStorage storage];
    _firebaseStorageRef = [_firebaseStorage referenceForURL:@"gs://wire-e0cde.appspot.com"];
}

-(void)uploadPhotoToFirebase:(NSData *)imageData {
    //Create a uniqueID for the image and add it to the end of the images reference.
    NSString *uniqueID = [[NSUUID UUID]UUIDString];
    NSString *newImageReference = [NSString stringWithFormat:@"profilePhotos/%@.jpg", uniqueID];
    //imagesRef creates a reference for the images folder and then adds a child to that folder, which will be every time a photo is taken.
    FIRStorageReference *imagesRef = [_firebaseStorageRef child:newImageReference];
    //This uploads the photo's NSData onto Firebase Storage.
    FIRStorageUploadTask *uploadTask = [imagesRef putData:imageData metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error) {
        if (error) {
            NSLog(@"ERROR: %@", error.description);
        } else {
            _currentUser.profileImageDownloadURL = metadata.downloadURL.absoluteString;
            [self updateCurrentUserProfileImageDownloadURLOnFirebaseDatabase:_currentUser];
        }
    }];
    [uploadTask resume];
}

-(void)updateCurrentUserProfileImageDownloadURLOnFirebaseDatabase:(UserProfile *)userProfile {
    
    FIRDatabaseReference *firebaseRef = [[FIRDatabase database] reference];
//
//    NSString *key = [firebaseRef child:[NSString stringWithFormat:@"userprofile/%@", _currentUserProfileKey]].key;
    
    NSDictionary *userProfileToUpdate = @{@"profilePhotoDownloadURL": userProfile.profileImageDownloadURL,
                                          @"email": userProfile.email,
                                          @"userId": userProfile.uid,
                                          @"username": userProfile.username};
    
//    NSDictionary *childUpdates = @{[@"/userprofile/" stringByAppendingString:_currentUserProfileKey]: userProfileToUpdate,
//                                   [NSString stringWithFormat:@"profilePhotoDownloadURL/%@/%@/", userProfile.profileImageDownloadURL, _currentUserProfileKey]: userProfileToUpdate};
    
    NSDictionary *childUpdates = @{[@"/userprofile/" stringByAppendingString:_currentUserProfileKey]: userProfileToUpdate};
    
    //,[NSString stringWithFormat:@"/userprofile/%@/%@/", userProfile.profileImageDownloadURL, _currentUserProfileKey]: userProfileToUpdate
    
    NSLog(@"Child Updates**********: %@", childUpdates);
    
    [firebaseRef updateChildValues:childUpdates];

}

- (IBAction)profilePhotoSelected:(id)sender {
    [self presentCamera];
    
    
}

@end
