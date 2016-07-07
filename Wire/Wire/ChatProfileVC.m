//
//  ChatProfileNavController".m
//  Wire
//
//  Created by DetroitLabs on 6/27/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import "ChatProfileVC.h"
#import "ChatViewController.h"
#import "UserProfile.h"
@import FirebaseDatabase;
@import Firebase;
@import FirebaseStorage;

@interface ChatProfileVC ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (strong, nonatomic) UIImagePickerController *imagePicker;
//FIRStorageReference represents a reference to a Google Cloud Storage object.
@property (strong, nonatomic) FIRStorageReference *firebaseStorageRef;
@property (strong, nonatomic) NSString *currentUserProfileKey;
//An instance of FIRStorage will initialize with the default FIRApp
@property (strong, nonatomic) FIRStorage *firebaseStorage;
@property(strong, nonatomic) UserProfile *currentUser;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *currentUserProfilePhoto;

@end

@implementation ChatProfileVC

- (void)viewDidLoad {
    [self firebaseSetUp];
    [self listenForChangesInUserProfile];
    [self getCurrentUserProfileFromFirebase];
    [super viewDidLoad];
        
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
        _currentUser.profileImageDownloadURL = snapshot.value[@"profilePhotoDownloadURL"];
        NSLog(@"DOWNLOADED: %@", snapshot.value[@"profilePhotoDownloadURL"]);
        _currentUser.profileImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:snapshot.value[@"profilePhotoDownloadURL"]]]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_currentUserProfilePhoto setImage:_currentUser.profileImage];
            [_usernameLabel setText:[NSString stringWithFormat:@"Hello, %@!", _currentUser.username]];
        });
    }];
}

-(void)listenForChangesInUserProfile {
    FIRDatabaseReference *UserProfileRef = [[[FIRDatabase database]reference]child:@"userprofile"];
    FIRDatabaseQuery *currentUserProfileChangedQuery = [[UserProfileRef queryOrderedByChild:@"userId"] queryEqualToValue:[FIRAuth auth].currentUser.uid];

    [currentUserProfileChangedQuery observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot) {
        _currentUser = [[UserProfile alloc]initUserProfileWithEmail:snapshot.value[@"email"] username:snapshot.value[@"username"] uid:snapshot.value[@"userId"]];
        _currentUser.profileImageDownloadURL = snapshot.value[@"profilePhotoDownloadURL"];
        _currentUser.profileImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:snapshot.value[@"profilePhotoDownloadURL"]]]];
        NSLog(@"_current user URL: %@", _currentUser.profileImageDownloadURL);
        dispatch_async(dispatch_get_main_queue(), ^{
            [_currentUserProfilePhoto setImage:_currentUser.profileImage];
            [_usernameLabel setText:[NSString stringWithFormat:@"Hello, %@!", _currentUser.username]];
        });
    }];
    
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
    
    //Need every value filled or it will just remove what we didn't put in the dictionary. For an example if the profileImageDownloadURL was the only thing we put in this dictionary and used this dictionary to update the child node then the email, userId and the username would be removed and only the profilePhotoDownloadURL would be in that child node.
    NSDictionary *userProfileToUpdate = @{@"profilePhotoDownloadURL": userProfile.profileImageDownloadURL,
                                          @"email": userProfile.email,
                                          @"userId": userProfile.uid,
                                          @"username": userProfile.username};
    
    NSDictionary *childUpdates = @{[@"/userprofile/" stringByAppendingString:_currentUserProfileKey]: userProfileToUpdate};

    [firebaseRef updateChildValues:childUpdates];

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"DOWNLOAD URL PREPARE FOR SEGUE: %@", _currentUser.profileImageDownloadURL);
    ChatViewController *destVC = [segue destinationViewController];
    destVC.currentUserProfile = _currentUser;
}

-(void)viewWillLayoutSubviews {
    _currentUserProfilePhoto.layer.borderWidth = 4.0;
    _currentUserProfilePhoto.layer.borderColor = [[UIColor blackColor] CGColor];
    _currentUserProfilePhoto.layer.cornerRadius = _currentUserProfilePhoto.frame.size.width/2;
    _currentUserProfilePhoto.layer.masksToBounds = TRUE;
}

- (IBAction)profilePhotoSelected:(id)sender {
    [self presentCamera];
    
}

@end
