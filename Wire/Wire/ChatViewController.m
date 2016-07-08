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

#pragma mark Properties
@property (nonatomic, strong) UIImage *avatarImageToPass;
@property (nonatomic, strong) NSURL *avatarImageURL;
@property (nonatomic, strong) UserProfile *userProfileToPass;
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) NSArray *sortedArray;
@property (nonatomic, strong) JSQMessagesBubbleImage *outgoingBubbleImage;
@property (nonatomic, strong) JSQMessagesBubbleImage *incomingBubbleImage;
@property (nonatomic, strong) UserProfile *userProfile;
@property (nonatomic, strong) NSString *profilePhotoDownloadURL;
@property (strong, nonatomic) FIRStorageReference *firebaseStorageRef;
@property (strong, nonatomic) FIRStorage *firebaseStorage;

@end

@implementation ChatViewController
UIImage *resizedImg;
NSString *imageURL;
Message *message;
NSData *localfile;
NSString *randomMessageKey;
NSString *oldPhotoTimestamp;
NSDictionary *messageToUpdate;

- (void)viewDidLoad {

    _messages = [[NSMutableArray alloc]init];
    [self setJSQsenderIdAndDisplayName];
    [super viewDidLoad];
    [self retrieveMessagesFromFirebase];
    [self JSQMessageBubbleSetup];
    
    [self scrollToBottomAnimated:true];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark JSQMessagesViewController Required Protocols.
//Send Button Pressed.
-(void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date{
    NSLog(@"DATE: %@", date);
    [self firebaseSetUp];
    //send text messsage
    NSString *timestamp = [NSString stringWithFormat:@"%@", date];
    NSDictionary *messageDictionary = @{@"text": text, @"senderId": senderId, @"senderName": senderDisplayName, @"timestamp":timestamp};
    [self sendMessageToFirebase:messageDictionary];
    
}

//Number of items in section **How many items in each section - in our case it will be however many messages we have** - REQUIRED
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_sortedArray count];
}

//Message Data for item at indexPath **Data source for the messages** - REQUIRED
-(id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {

    return _sortedArray[indexPath.item];
}

//MessageBubbleImageData for item at indexPath **this is for the bubble image behind each text** - REQUIRED
-(id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = _sortedArray[indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImage;
    } else {
        return self.incomingBubbleImage;
    }
}

//AvatarImageData for item at indexPath **this is the avatarImage that needs to be supplied for each text** - REQUIRED - return nil if you want to override this and have no avatarImage.

-(id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {

    Message *message = [_sortedArray objectAtIndex:indexPath.item];
    
    return message.avatarImage;
}

-(CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 20.0f;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [_sortedArray objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        Message *previousMessage = [_sortedArray objectAtIndex:indexPath.item - 1];
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

/*
 Detects if the avatar image is tapped. This grabs the message at that indexPath,
 uses the senderId and passed it to the 'getCurrentUserProfileFromFirebase' function
 to get the UserProfile to then gain access to the profile photo.
 Once it does that then we pass the photo to the FullPreviewVC and display the profile
 photo in a full screen mode.
 */
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath {
    
    Message *message = _sortedArray[indexPath.item];

    [self getCurrentUserProfileFromFirebase:message.senderId completion:^(UserProfile *userProfile) {
        _avatarImageToPass = userProfile.profileImage;
        [self performSegueWithIdentifier:@"FullPreviewVCSegue" sender:self];
    }];
    
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Tapped message bubble!");
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"FullPreviewVCSegue"]) {
        FullPreviewViewController *destVC = [segue destinationViewController];
        destVC.imagePassed = _avatarImageToPass;
    }
}


#pragma mark Firebase Methods

//Sets up Firebase Storage and the reference (called in viewDidLoad)
-(void)firebaseSetUp {
    _firebaseStorage = [FIRStorage storage];
    _firebaseStorageRef = [_firebaseStorage referenceForURL:@"gs://wire-e0cde.appspot.com"];
}

-(void)sendMessageToFirebase:(NSDictionary *)message {
    FIRDatabaseReference *messagesRef = [[[[FIRDatabase database]reference]child:@"messages"]childByAutoId];
    [messagesRef setValue:message];
}

-(void)sendPhotoMessageToFirebase:(NSDictionary *)message {
    [[[[FIRDatabase database]reference]child:@"messages"] updateChildValues:message];
}


-(void)retrieveMessagesFromFirebase {
    FIRDatabaseReference *messagesRef = [[[FIRDatabase database]reference]child:@"messages"];
    [messagesRef observeEventType:FIRDataEventTypeChildAdded withBlock:
     ^(FIRDataSnapshot *snapshot) {
         
         if (snapshot.value[@"imageURL"] != nil){
             [self downloadImageFromFirebaseWithAFNetworking:snapshot.value[@"imageURL"] completion:^(UIImage *messageImage) {
                 resizedImg = messageImage;
                 JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:resizedImg];
                 message = [[Message alloc]initWithSenderId:snapshot.value[@"senderId"] senderDisplayName:snapshot.value[@"senderName"] date:snapshot.value[@"timestamp"]media:photoItem];
             }];
             
         } else {
             message = [[Message alloc]initWithSenderId:snapshot.value[@"senderId"] senderDisplayName:snapshot.value[@"senderName"] date:snapshot.value[@"timestamp"] text:snapshot.value[@"text"]];
         }
         
        [self assignAvatarsToMessages:message];

        [self.collectionView reloadData];
    }];
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

//update the sender's profile photo.
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

#pragma mark Helper Methods

//Assigns avatars to the messages.
-(void)assignAvatarsToMessages:(Message *)message {
    if ([message.senderId isEqualToString:self.senderId]) {
        
        [self downloadImageFromFirebaseWithAFNetworking:_currentUserProfile.profileImageDownloadURL completion:^(UIImage *profileImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setUpAvatarImages:message image:profileImage incoming:FALSE];
                [_messages addObject:message];
                [self sortMessagesArray:_messages];
            });
        }];
    } else {
        [self getIncomingUserProfilePhotoDownloadURLFromFirebaseWithSenderId:message.senderId completion:^(NSString *urlString) {
            [self downloadImageFromFirebaseWithAFNetworking:urlString completion:^(UIImage *profileImage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setUpAvatarImages:message image:profileImage incoming:TRUE];
                    [_messages addObject:message];
                    [self sortMessagesArray:_messages];
                });
            }];
        }];
    }
}

//Creates the avatars for the messages. This is called in assignAvatarsToMessages func (which is called when we retrieve the messages).
-(void)setUpAvatarImages:(Message *)message image:(UIImage *)image incoming:(BOOL)incoming {
    double diameter;
    
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

//Used to sort the messages.
-(void)sortMessagesArray:(NSMutableArray *)messagesArray {
    _sortedArray = [messagesArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDate *firstDate = [(Message*)obj1 date];
        NSDate *secondDate = [(Message*)obj2 date];
        return [firstDate compare:secondDate];
    }];
    [self.collectionView reloadData];
}

//Creates placeholderAvatars, which is just the first initial of the user's display name.
-(JSQMessagesAvatarImage *)setPlaceHolderAvatars:(NSString *)senderDisplayName {
    JSQMessagesAvatarImage *placeholderAvatarImage = [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:[senderDisplayName substringToIndex:1] backgroundColor:[UIColor blackColor] textColor:[UIColor whiteColor] font:[UIFont systemFontOfSize:12] diameter:self.collectionView.collectionViewLayout.incomingAvatarViewSize.width];
    
    return placeholderAvatarImage;
}

//Sets the JSQMessenger's required senderId and senderDisplayName (called in viewDidLoad).
-(void)setJSQsenderIdAndDisplayName {
    self.senderId = [FIRAuth auth].currentUser.uid;
    if (_currentUserProfile == nil) {
        self.senderDisplayName = @"User";
    } else {
        self.senderDisplayName = _currentUserProfile.username;
    }
}

//Used to show the action sheet when the attachment button is pressed.
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

//Uploads the photo to Firebase
-(void)uploadPhotoToFirebase:(NSData *)imageData{
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
            url = [NSString stringWithFormat:@"%@",metadata.downloadURL];
            [self updateMessageImageUrlToFB:url];
        }
    }];
    [uploadTask resume];
}


//Updates the message's photo URL on Firebase
-(void)updateMessageImageUrlToFB: (NSString *)url {
    FIRDatabaseReference *firebaseRef = [[FIRDatabase database] reference];
    messageToUpdate = @{@"imageURL": url,
                                      @"senderId":self.senderId,
                                      @"senderName": self.senderDisplayName,
                                      @"text": @"test",
                                      @"timestamp": oldPhotoTimestamp
                                      };
    NSDictionary *childUpdates = @{[@"/messages/" stringByAppendingString:randomMessageKey ]: messageToUpdate};
    
    [firebaseRef updateChildValues:childUpdates];
}

#pragma mark Camera Methods
//Launches the UIImagePickerController
- (void)takePicture{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    [self presentViewController:imagePicker animated:NO completion:nil];
    imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    [imagePicker setDelegate:self];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
}

//Used to choose an image from the gallery
- (void)chooseFromGallery{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    [imagePicker setDelegate:self];
    [self presentViewController:imagePicker animated:NO completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//Occurs when the imagePickerController is finished picking the image.
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    //grab the image we just took or chosen from gallery
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    //reduce size of the image, optional
    resizedImg = [self reduceImageSize:image];
    
    NSData *resizedImgData =  UIImageJPEGRepresentation(resizedImg, .50);
    [self uploadPhotoToFirebase:resizedImgData];
    
    NSString *timestamp = [NSString stringWithFormat:@"%@", [NSDate date]];
    
    NSLog(@"Photo Date; %@", timestamp);
    
    oldPhotoTimestamp = timestamp;
    
    NSDictionary *aDictionary = @{@"text":@" ", @"senderId": self.senderId, @"senderName": self.senderDisplayName, @"timestamp":timestamp, @"imageURL":@"https://firebasestorage.googleapis.com/v0/b/wire-e0cde.appspot.com/o/car4.jpg?alt=media&token=e99baf6a-0b49-4439-960a-591d72bc21df"};
    randomMessageKey = [[NSUUID UUID] UUIDString];
    NSDictionary *messageDictionary = @{randomMessageKey:aDictionary};
    [self sendPhotoMessageToFirebase:messageDictionary];
    
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:resizedImg];
    message = [[Message alloc]initWithSenderId:self.senderId senderDisplayName:self.senderDisplayName date:[NSDate date] media:photoItem];
    [_messages addObject:message];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.collectionView reloadData];
}

//Reduces the image size.
-(UIImage *)reduceImageSize:(UIImage *)image {
    //creating a frame
    CGSize newSize = CGSizeMake(image.size.width/6, image.size.height/6);
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
    //Where to the frame the new painting is going to be placed
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    resizedImg = UIGraphicsGetImageFromCurrentImageContext();
    return resizedImg;
}


@end
