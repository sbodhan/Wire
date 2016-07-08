//
//  ChatViewController.m
//  Wire
//
//  Created by DetroitLabs on 6/27/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import "ChatViewController.h"

#import "FullPreviewViewController.h"

#import "JSQMessage.h"
#import "Message.h"
#import "JSQPhotoMediaItem.h"
#import "JSQMessagesBubbleImage.h"
#import "JSQMessagesAvatarImage.h"
#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesAvatarImageFactory.h"
#import "JSQMessagesCollectionViewCell.h"
#import "NSString+JSQMessages.h"
#import "UIImageView+AFNetworking.h"
#import "AFNetworking.h"
@import FirebaseStorage;
@import FirebaseDatabase;
@import FirebaseAuth;
@import FirebaseStorage;

@interface ChatViewController ()
@property (nonatomic, strong) UIImage *avatarImageToPass;
@property (nonatomic, strong) NSURL *avatarImageURL;
@property (nonatomic, strong) UserProfile *userProfileToPass;

@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) JSQMessagesBubbleImage *outgoingBubbleImage;
@property (nonatomic, strong) JSQMessagesBubbleImage *incomingBubbleImage;
@property (nonatomic, strong) NSMutableDictionary *avatars;
@property (nonatomic, strong) UserProfile *userProfile;
@property (nonatomic, strong) NSString *profilePhotoDownloadURL;
@property (strong, nonatomic) FIRStorageReference *firebaseStorageRef;
@property (strong, nonatomic) FIRStorage *firebaseStorage;

@end

@implementation ChatViewController
UIImage *resizedImg;
NSString *imageURL;
<<<<<<< HEAD
JSQMessage *message;
=======
Message *message;
NSData *localfile;
>>>>>>> aa18acec0aa999512f25ba1594372c65f05920d0

- (void)viewDidLoad {
    [self setJSQsenderIdAndDisplayName];
    [super viewDidLoad];
    [self retrieveMessagesFromFirebase];
    [self JSQMessageBubbleSetup];
    _messages = [[NSMutableArray alloc]init];
    _avatars = [[NSMutableDictionary alloc]init];
    
    self.showTypingIndicator = !self.showTypingIndicator;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark JSQMessagesViewController Required Protocols.
//Send Button Pressed.

-(void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date{
    self.showTypingIndicator = !self.showTypingIndicator;
    [self firebaseSetUp];
    //send text messsage
    NSString *timestamp = [NSString stringWithFormat:@"%@", date];
    NSDictionary *messageDictionary = @{@"text": text, @"senderId": senderId, @"senderName": senderDisplayName, @"timestamp":timestamp};
    [self sendMessageToFirebase:messageDictionary];
    
    [self scrollToBottomAnimated:YES];
    
}

//Number of items in section **How many items in each section - in our case it will be however many messages we have** - REQUIRED
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_messages count];
}

//Message Data for item at indexPath **Data source for the messages** - REQUIRED
-(id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
<<<<<<< HEAD
    
    return _messages[indexPath.row];
=======

    return _messages[indexPath.item];
>>>>>>> aa18acec0aa999512f25ba1594372c65f05920d0
}

//MessageBubbleImageData for item at indexPath **this is for the bubble image behind each text** - REQUIRED
-(id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = _messages[indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImage;
    } else {
        return self.incomingBubbleImage;
    }
}

//AvatarImageData for item at indexPath **this is the avatarImage that needs to be supplied for each text** - REQUIRED - return nil if you want to override this and have no avatarImage.

-(id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
<<<<<<< HEAD
    
    JSQMessage *message = [_messages objectAtIndex:indexPath.row];
    
    if (_avatars[message.senderId] == nil) {
        
        return [self setPlaceHolderAvatars:message.senderDisplayName];
    }
    
    return _avatars[message.senderId];
=======

    Message *message = [_messages objectAtIndex:indexPath.item];
    
//    if (_avatars[message.senderId] == nil) {
//
//        return [self setPlaceHolderAvatars:message.senderDisplayName];
//    }
    return message.avatarImage;
>>>>>>> aa18acec0aa999512f25ba1594372c65f05920d0
}

-(CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 20.0f;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage *message = [_messages objectAtIndex:indexPath.item];

    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [_messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

//Sets up the colors for the outgoing and incoming message bubbles.
-(void)JSQMessageBubbleSetup {
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc]init];
    _outgoingBubbleImage = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor blueColor]];
    _incomingBubbleImage = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor grayColor]];
}

-(JSQMessagesAvatarImage *)avatarImageWithImage:(UIImage *)image diameter:(NSUInteger)diameter {
    
    JSQMessagesAvatarImage *avatar = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"default_user"] diameter:5.0];
    return avatar;
}

//***************************************************************************************************************************

/*
 Detects if the avatar image is tapped. This grabs the message at that indexPath,
 uses the senderId and passed it to the 'getCurrentUserProfileFromFirebase' function
 to get the UserProfile to then gain access to the profile photo.
 Once it does that then we pass the photo to the FullPreviewVC and display the profile
 photo in a full screen mode.
*/
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath {
    
    Message *message = _messages[indexPath.item];

    [self getCurrentUserProfileFromFirebase:message.senderId completion:^(UserProfile *userProfile) {
        _avatarImageToPass = userProfile.profileImage;
        [self performSegueWithIdentifier:@"FullPreviewVCSegue" sender:self];
    }];

}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Tapped message bubble!");
}

/*
 Accepts the message's senderId and uses it to retrieve the UserProfile for that sender.
 With this UserProfile we can gain access to the profilePhotoDownloadURL and
 get the profile photo to then pass to the next screen.
 */
-(void)getCurrentUserProfileFromFirebase:(NSString *)messageSenderId completion:(void(^)(UserProfile *userProfile))completion {
    
    FIRDatabaseReference *userProfileRef = [[[FIRDatabase database]reference]child:@"userprofile"];
    FIRDatabaseQuery *userProfileToPassQuery = [[userProfileRef queryOrderedByChild:@"userId"] queryEqualToValue:messageSenderId];
    [userProfileToPassQuery observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        
        _userProfileToPass = [[UserProfile alloc]initUserProfileWithEmail:snapshot.value[@"email"] username:snapshot.value[@"username"] uid:snapshot.value[@"userId"]];
        _userProfileToPass.profileImageDownloadURL = snapshot.value[@"profilePhotoDownloadURL"];
        _userProfileToPass.profileImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:snapshot.value[@"profilePhotoDownloadURL"]]]];
        
        completion(_userProfileToPass);
        
    }];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"FullPreviewVCSegue"]) {
        FullPreviewViewController *destVC = [segue destinationViewController];
        destVC.imagePassed = _avatarImageToPass;
    }
}



//***************************************************************************************************************************


#pragma mark Firebase Methods

-(void)sendMessageToFirebase:(NSDictionary *)message {
    FIRDatabaseReference *messagesRef = [[[[FIRDatabase database]reference]child:@"messages"]childByAutoId];
    [messagesRef setValue:message];
}


-(void)retrieveMessagesFromFirebase {
    
    FIRDatabaseReference *messagesRef = [[[FIRDatabase database]reference]child:@"messages"];
    [messagesRef observeEventType:FIRDataEventTypeChildAdded withBlock:
     ^(FIRDataSnapshot *snapshot) {
         
         if (snapshot.value[@"imageURL"] != nil) {
             [self downloadImageFromFirebaseWithAFNetworking:snapshot.value[@"imageURL"] completion:^(UIImage *messageImage) {
                 resizedImg = messageImage;
                 JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:resizedImg];
                 message = [[Message alloc]initWithSenderId:snapshot.value[@"senderId"] senderDisplayName:snapshot.value[@"senderName"] date:snapshot.value[@"timestamp"]media:photoItem];
             }];
             
         } else {
             message = [[Message alloc]initWithSenderId:snapshot.value[@"senderId"] senderDisplayName:snapshot.value[@"senderName"] date:snapshot.value[@"timestamp"] text:snapshot.value[@"text"]];
         }
         
<<<<<<< HEAD
         if ([message.senderId isEqualToString:self.senderId]) {
             
             NSLog(@"CURRENT USER PROFILE DOWNLOAD URL: %@", _currentUserProfile.profileImageDownloadURL);
             
             [self downloadImageFromFirebaseWithAFNetworking:_currentUserProfile.profileImageDownloadURL completion:^(UIImage *profileImage) {
                 [self setUpAvatarImages:message.senderId image:profileImage incoming:FALSE];
                 [self.collectionView reloadData];
             }];
         } else {
             [self getIncomingUserProfilePhotoDownloadURLFromFirebaseWithSenderId:message.senderId completion:^(NSString *urlString) {
                 [self downloadImageFromFirebaseWithAFNetworking:urlString completion:^(UIImage *profileImage) {
                     [self setUpAvatarImages:message.senderId image:profileImage incoming:TRUE];
                     [self.collectionView reloadData];
                 }];
             }];
         }
         
         [self.collectionView reloadData];
     }];
=======
        [self assignAvatarsToMessages:message];

        [self.collectionView reloadData];
    }];
>>>>>>> aa18acec0aa999512f25ba1594372c65f05920d0
}

-(void)assignAvatarsToMessages:(Message *)message {
    if ([message.senderId isEqualToString:self.senderId]) {
        
        [self downloadImageFromFirebaseWithAFNetworking:_currentUserProfile.profileImageDownloadURL completion:^(UIImage *profileImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setUpAvatarImages:message image:profileImage incoming:FALSE];
                [_messages addObject:message];
                [self.collectionView reloadData];
            });
        }];
    } else {
        [self getIncomingUserProfilePhotoDownloadURLFromFirebaseWithSenderId:message.senderId completion:^(NSString *urlString) {
            [self downloadImageFromFirebaseWithAFNetworking:urlString completion:^(UIImage *profileImage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setUpAvatarImages:message image:profileImage incoming:TRUE];
                    [_messages addObject:message];
                    [self.collectionView reloadData];
                });
            }];
        }];
    }
}

-(void)setUpAvatarImages:(Message *)message image:(UIImage *)image incoming:(BOOL)incoming {
    double diameter;
<<<<<<< HEAD
=======

    NSLog(@"MESSAGE TEXT: %@", message.text);
>>>>>>> aa18acec0aa999512f25ba1594372c65f05920d0
    
    if (incoming == TRUE) {
        diameter = self.collectionView.collectionViewLayout.incomingAvatarViewSize.width;
    } else {
        diameter = self.collectionView.collectionViewLayout.outgoingAvatarViewSize.width;
    }
    
    JSQMessagesAvatarImage *avatarImage = [JSQMessagesAvatarImageFactory
                                           avatarImageWithImage:image
                                           diameter:diameter];
    
    message.avatarImage = avatarImage;
}

-(void)getIncomingUserProfilePhotoDownloadURLFromFirebaseWithSenderId:(NSString *)senderId completion:(void(^)(NSString *urlString))completion {
    
    FIRDatabaseReference *userprofileRef = [[[FIRDatabase database]reference]child:@"userprofile"];
    FIRDatabaseQuery *userThatSentMessageQuery = [[userprofileRef queryOrderedByChild:@"userId"]queryEqualToValue:senderId];
    [userThatSentMessageQuery observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        completion(snapshot.value[@"profilePhotoDownloadURL"]);
    }];
}

//Downloads the photo using AFNetworking. returns a UIImage in the completion handler.
-(void)downloadImageFromFirebaseWithAFNetworking:(NSString *)imageURL completion:(void(^)(UIImage *profileImage))completion {
    NSURL *url = [NSURL URLWithString:imageURL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFImageResponseSerializer serializer];
    [manager GET:url.absoluteString parameters:nil progress:nil success:^(NSURLSessionDataTask *task, UIImage *responseData) {
        completion(responseData);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
}

//Creates placeholderAvatars, which is just the first initial of the user's display name.
-(JSQMessagesAvatarImage *)setPlaceHolderAvatars:(NSString *)senderDisplayName {
    JSQMessagesAvatarImage *placeholderAvatarImage = [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:[senderDisplayName substringToIndex:1] backgroundColor:[UIColor blackColor] textColor:[UIColor whiteColor] font:[UIFont systemFontOfSize:12] diameter:self.collectionView.collectionViewLayout.incomingAvatarViewSize.width];
    
    return placeholderAvatarImage;
}

-(void)setJSQsenderIdAndDisplayName {
    self.senderId = [FIRAuth auth].currentUser.uid;
    if (_currentUserProfile == nil) {
        self.senderDisplayName = @"User";
    } else {
        self.senderDisplayName = _currentUserProfile.username;
    }
}

- (void)didPressAccessoryButton:(UIButton *)sender{
    UIAlertController * view=   [UIAlertController
                                 alertControllerWithTitle:@"Where do you want the photos from?"
                                 message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"Gallery"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [self chooseFromGallery];
//                             //Do some thing here
//                             UIImage *image = [UIImage imageNamed:@"car4.jpg"];
//                             NSData *localfile =  UIImageJPEGRepresentation(image, .50);
//                             [self uploadPhotoToFirebase:localfile];
                             
                             [view dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Take a photo"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [self takePicture];
                                 [view dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    
    
    [view addAction:ok];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}

<<<<<<< HEAD
-(NSString *)uploadPhotoToFirebase:(NSData *)imageData{
    NSString *uniqueID = [[NSUUID UUID]UUIDString];
    NSString *newImageReference = [NSString stringWithFormat:@"images/%@.jpg", uniqueID];
    __block NSString *url;
    
    FIRStorage *storage = [FIRStorage storage];
    FIRStorageReference *storageRef = [storage referenceForURL:@"gs://wire-e0cde.appspot.com"];
    FIRStorageReference *imageRef = [storageRef child:newImageReference];
    FIRStorageUploadTask *uploadTask = [imageRef putData:imageData metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error){
        if(error){
            NSLog(@"%@", error.description);
        }
        
        else{
            NSString *photoTimeStamp = [self createFormattedTimeStamp];
            Message *photo = [[Message alloc]initPhotoWithDownloadURL:[NSString stringWithFormat:@"%@", metadata.downloadURL] andTimestamp:photoTimeStamp];
            NSLog(@"PHOTO time stamp is %@", photo.timeStamp);
            url = [NSString stringWithFormat:@"%@",photo.downloadURL];
        }
    }];
=======
-(void)uploadPhotoToFirebase:(NSData *)imageData{

        FIRStorage *storage = [FIRStorage storage];
        FIRStorageReference *storageRef = [storage referenceForURL:@"gs://wire-e0cde.appspot.com"];
        FIRStorageReference *imageRef = [storageRef child:@"images/car4.jpg"];
        FIRStorageUploadTask *uploadTask = [imageRef putData:imageData metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error){
            if(error){
            }
    
            else{
                NSURL *downloadURL = metadata.downloadURL;
                NSString *photoTimeStamp = [self createFormattedTimeStamp];
            }
        }];
>>>>>>> aa18acec0aa999512f25ba1594372c65f05920d0
    [uploadTask resume];
    return url;
}

<<<<<<< HEAD

=======
>>>>>>> aa18acec0aa999512f25ba1594372c65f05920d0
- (void)takePicture{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    [self presentViewController:imagePicker animated:NO completion:nil];
    imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    [imagePicker setDelegate:self];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
}

- (void)chooseFromGallery{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    [imagePicker setDelegate:self];
    [self presentViewController:imagePicker animated:NO completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    //grab the image we just took or chosen from gallery
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    //reduce size of the image, optional
    resizedImg = [self reduceImageSize:image];
    
    NSData *resizedImgData =  UIImageJPEGRepresentation(resizedImg, .50);
    NSString *url = [self uploadPhotoToFirebase:resizedImgData];
    

    NSString *timestamp = [NSString stringWithFormat:@"%@", [NSDate date]];
    NSDictionary *messageDictionary = @{@"text":@" ", @"senderId": self.senderId, @"senderName": self.senderDisplayName, @"timestamp":timestamp, @"ImageURL":@"https://firebasestorage.googleapis.com/v0/b/wire-e0cde.appspot.com/o/images%2Fplaceholder.jpg?alt=media&token=a5a6f1b3-b434-40fb-bc59-0e596f07bb6a"};
    [self sendMessageToFirebase:messageDictionary];
    
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:resizedImg];
    message = [[Message alloc]initWithSenderId:self.senderId senderDisplayName:self.senderDisplayName date:[NSDate date] media:photoItem];
    [_messages addObject:message];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.collectionView reloadData];
}


-(UIImage *)reduceImageSize:(UIImage *)image {
    //creating a frame
    CGSize newSize = CGSizeMake(image.size.width/6, image.size.height/6);
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
    //Where to the frame the new painting is going to be placed
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    resizedImg = UIGraphicsGetImageFromCurrentImageContext();
    return resizedImg;
}

-(void)firebaseSetUp {
    _firebaseStorage = [FIRStorage storage];
    _firebaseStorageRef = [_firebaseStorage referenceForURL:@"gs://wire-e0cde.appspot.com"];
}

<<<<<<< HEAD
=======
//-(void)uploadPhotoToFirebase:(NSData *)imageData {
//    //Create a uniqueID for the image and add it to the end of the images reference.
//    NSString *uniqueID = [[NSUUID UUID]UUIDString];
//    NSString *newImageReference = [NSString stringWithFormat:@"images/%@.jpg", uniqueID];
//    //imagesRef creates a reference for the images folder and then adds a child to that folder, which will be every time a photo is taken.
//    FIRStorageReference *imagesRef = [_firebaseStorageRef child:newImageReference];
//    //This uploads the photo's NSData onto Firebase Storage.
//    FIRStorageUploadTask *uploadTask = [imagesRef putData:imageData metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error) {
//        if (error) {
//            NSLog(@"ERROR: %@", error.description);
//        } else {
//            imageURL = [NSString stringWithFormat:@"%@", metadata.downloadURL];
//        }
//    }];
//    [uploadTask resume];
//}

>>>>>>> aa18acec0aa999512f25ba1594372c65f05920d0

#pragma mark Timestamp and Date Formatter Methods
-(NSString *)createFormattedTimeStamp {
    NSDate *timestamp = [NSDate date];
    NSString *stringTimestamp = [self formatDate:timestamp];
    return stringTimestamp;
}


-(NSString *)formatDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"MM/dd/YYYY HH:mm:ss"];
    NSString *formattedDate = [dateFormatter stringFromDate:date];
<<<<<<< HEAD
    NSLog(@"FORMAT DATE################= %@", formattedDate);
=======
>>>>>>> aa18acec0aa999512f25ba1594372c65f05920d0
    return formattedDate;
}

@end
