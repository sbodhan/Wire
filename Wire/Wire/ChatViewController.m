//
//  ChatViewController.m
//  Wire
//
//  Created by DetroitLabs on 6/27/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import "ChatViewController.h"
#import "JSQMessage.h"
#import "JSQMessagesBubbleImage.h"
#import "JSQMessagesAvatarImage.h"
#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesAvatarImageFactory.h"
@import FirebaseStorage;
@import FirebaseDatabase;
@import FirebaseAuth;

@interface ChatViewController ()
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) JSQMessagesBubbleImage *outgoingBubbleImage;
@property (nonatomic, strong) JSQMessagesBubbleImage *incomingBubbleImage;
@property (nonatomic, strong) NSMutableDictionary *avatars;
@property (nonatomic, strong) UserProfile *userProfile;
@property (nonatomic, strong) NSMutableArray *userProfiles;
@property (nonatomic, strong) NSString *profilePhotoDownloadURL;
@property (strong, nonatomic) FIRStorageReference *firebaseStorageRef;
@property (strong, nonatomic) FIRStorage *firebaseStorage;



@end

@implementation ChatViewController
UIImage *smallImage;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self retrieveUsersInChatRoom];
    
    [self retrieveMessagesFromFirebase];
    [self JSQMessageBubbleSetup];
    _messages = [[NSMutableArray alloc]init];
    _avatars = [[NSMutableDictionary alloc]init];

    //THESE ARE ONLY FOR TESTING SO APP WON'T CRASH!
    self.senderId = _currentUserProfile.uid;
    self.senderDisplayName = _currentUserProfile.username;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark JSQMessagesViewController Required Protocols.
//Send Button Pressed.

-(void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date {
    
    NSString *timestamp = [NSString stringWithFormat:@"%@", date];
    NSDictionary *message = @{@"text": text, @"senderId": senderId, @"senderName": senderDisplayName, @"timestamp":timestamp};
    [self sendMessageToFirebase:message];
    
}

//Number of items in section **How many items in each section - in our case it will be however many messages we have** - REQUIRED
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_messages count];
}

//Message Data for item at indexPath **Data source for the messages** - REQUIRED
-(id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {

    return [_messages objectAtIndex:indexPath.row];
}

//MessageBubbleImageData for item at indexPath **this is for the bubble image behind each text** - REQUIRED
-(id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage *message = _messages[indexPath.row];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImage;
    } else {
        return self.incomingBubbleImage;
    }
}

//AvatarImageData for item at indexPath **this is the avatarImage that needs to be supplied for each text** - REQUIRED - return nil if you want to override this and have no avatarImage.

-(id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {

    JSQMessage *message = [_messages objectAtIndex:indexPath.row];

    return _avatars[message.senderId];
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

#pragma mark Firebase Methods

-(void)sendMessageToFirebase:(NSDictionary *)message {
    FIRDatabaseReference *messagesRef = [[[[FIRDatabase database]reference]child:@"messages"]childByAutoId];
    [messagesRef setValue:message];
}

-(void)retrieveMessagesFromFirebase {
    FIRDatabaseReference *messagesRef = [[[FIRDatabase database]reference]child:@"messages"];
    [messagesRef observeEventType:FIRDataEventTypeChildAdded withBlock:
     ^(FIRDataSnapshot *snapshot) {
         
        JSQMessage *message = [[JSQMessage alloc]initWithSenderId:snapshot.value[@"senderId"] senderDisplayName:snapshot.value[@"senderName"] date:snapshot.value[@"timestamp"] text:snapshot.value[@"text"]];
         
         /*************************************************************************************

        Option 1: AFNetworking and the placeholder image for the avatar. - look into what other apps do.
          
         ***************************************************************************************/
         
         if ([message.senderId isEqualToString:self.senderId]) {
             [self setUpAvatarImages:message.senderId imageURL:[NSURL URLWithString:_currentUserProfile.profileImageDownloadURL] incoming:FALSE];
         } else {
             [self getIncomingUserProfilePhotoDownloadURLFromFirebaseWithSenderId:message.senderId completion:^(NSString *urlString) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self setUpAvatarImages:message.senderId imageURL:[NSURL URLWithString:urlString] incoming:TRUE];
                     [self.collectionView reloadData];
                 });
             }];
         }
         
        [_messages addObject:message];
        [self.collectionView reloadData];
    }];
}

-(NSMutableArray *)retrieveUsersInChatRoom{

    FIRDatabaseReference *userprofileRef = [[[FIRDatabase database]reference]child:@"userprofile"];
    [userprofileRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        
        _userProfile = [[UserProfile alloc]initUserProfileWithEmail:snapshot.value[@"email"] username:snapshot.value[@"username"] uid:snapshot.value[@"userId"]];
        _userProfile.profileImageDownloadURL = snapshot.value[@"profilePhotoDownloadURL"];
        [_userProfiles addObject:_userProfile];
    }];
    return _userProfiles;
}

-(void)setUpAvatarImages:(NSString *)senderId imageURL:(NSURL *)imageURL incoming:(BOOL)incoming {
    double diameter;
    
    if (incoming == TRUE) {
        diameter = self.collectionView.collectionViewLayout.incomingAvatarViewSize.width;
    } else {
        diameter = self.collectionView.collectionViewLayout.outgoingAvatarViewSize.width;
    }
        
    JSQMessagesAvatarImage *avatarImage = [JSQMessagesAvatarImageFactory
                                           avatarImageWithImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]]
                                           diameter:diameter];

    [_avatars setValue:avatarImage forKey:senderId];
}

-(void)getIncomingUserProfilePhotoDownloadURLFromFirebaseWithSenderId:(NSString *)senderId completion:(void(^)(NSString *urlString))completion {

    FIRDatabaseReference *userprofileRef = [[[FIRDatabase database]reference]child:@"userprofile"];
    FIRDatabaseQuery *userThatSentMessageQuery = [[userprofileRef queryOrderedByChild:@"userId"]queryEqualToValue:senderId];
    [userThatSentMessageQuery observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        completion(snapshot.value[@"profilePhotoDownloadURL"]);
    }];
}


- (void)didPressAccessoryButton:(UIButton *)sender{
    NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    
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



- (void)takePicture{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    [self presentViewController:imagePicker animated:NO completion:nil];
    imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    [imagePicker setDelegate:self];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    NSLog(@"photo taken");
//    [self firebaseSetUp];
//    [self uploadPhotoToFirebase:resizedImgData];
}

- (void)chooseFromGallery{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    [imagePicker setDelegate:self];
    [self presentViewController:imagePicker animated:NO completion:nil];
    NSLog(@"photo chosen");
    //[self firebaseSetUp];
    //[self uploadPhotoToFirebase:resizedImgData];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    smallImage = [self reduceImageSize:image];
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(UIImage *)reduceImageSize:(UIImage *)image {
    NSLog(@"ORIGINAL IMAGE: width-%f, height-%f", image.size.width, image.size.height);
    //creating a frame
    CGSize newSize = CGSizeMake(image.size.width/6, image.size.height/6);
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
    //Where to the frame the new painting is going to be placed
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    smallImage = UIGraphicsGetImageFromCurrentImageContext();
    NSLog(@"SMALL IMAGE: width-%f, height-%f", smallImage.size.width, smallImage.size.height);
    return smallImage;
}

//-(void)firebaseSetUp {
//    _firebaseStorage = [FIRStorage storage];
//    _firebaseStorageRef = [_firebaseStorage referenceForURL:@"gs://wire-e0cde.appspot.com"];
//    NSData *resizedImgData =  UIImageJPEGRepresentation(_imageView.image, .50);
//    
//}

//-(void)uploadPhotoToFirebase:(NSData *)imageData {
//    
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
//            Photo *photo = [[Photo alloc]initPhotoWithDownloadURL:[NSString stringWithFormat:@"%@", metadata.downloadURL] andTimestamp:[self createFormattedTimeStamp]];
//            [self savePhotoObjectToFirebaseDatabase:photo];
//        }
//    }];
//    [uploadTask resume];
//}



@end
