//
//  ChatViewController.m
//  Wire
//
//  Created by DetroitLabs on 6/27/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import "ChatViewController.h"
#import "JSQMessage.h"

#import "JSQPhotoMediaItem.h"
#import "JSQMessagesBubbleImage.h"
#import "JSQMessagesAvatarImage.h"
#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesAvatarImageFactory.h"
@import FirebaseStorage;
#import "JSQMessagesCollectionViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "AFNetworking.h"
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
UIImage *resizedImg;
NSString *imageURL;
JSQMessage *message;

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
    
    self.showTypingIndicator = !self.showTypingIndicator;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark JSQMessagesViewController Required Protocols.
//Send Button Pressed.

-(void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date {
    
    self.showTypingIndicator = !self.showTypingIndicator;
    [self firebaseSetUp];
    NSData *resizedImgData =  UIImageJPEGRepresentation(resizedImg, .50);
    [self uploadPhotoToFirebase:resizedImgData];
    
    NSString *timestamp = [NSString stringWithFormat:@"%@", date];
    NSDictionary *message = @{@"text": text, @"senderId": senderId, @"senderName": senderDisplayName, @"timestamp":timestamp, @"ImageURL": @" "};
    [self sendMessageToFirebase:message];
    
}

//Number of items in section **How many items in each section - in our case it will be however many messages we have** - REQUIRED
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_messages count];
}

//Message Data for item at indexPath **Data source for the messages** - REQUIRED
-(id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {

    return _messages[indexPath.row];
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
    
    if (_avatars[message.senderId] == nil) {

        return [self setPlaceHolderAvatars:message.senderDisplayName];
    }
    
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
    
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:resizedImg];
    message = [[JSQMessage alloc]initWithSenderId:self.senderId senderDisplayName:self.senderDisplayName date:[NSDate date] media:photoItem];

    FIRDatabaseReference *messagesRef = [[[FIRDatabase database]reference]child:@"messages"];
    [messagesRef observeEventType:FIRDataEventTypeChildAdded withBlock:
     ^(FIRDataSnapshot *snapshot) {
         
         
         if (snapshot.value[@"imageURL"] != nil){
//             JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:resizedImg];
//             message = [[JSQMessage alloc]initWithSenderId:snapshot.value[@"senderId"] senderDisplayName:snapshot.value[@"senderName"] date:snapshot.value[@"timestamp"]media:photoItem];

         }else{
             message = [[JSQMessage alloc]initWithSenderId:snapshot.value[@"senderId"] senderDisplayName:snapshot.value[@"senderName"] date:snapshot.value[@"timestamp"] text:snapshot.value[@"text"]];}

         if ([message.senderId isEqualToString:self.senderId]) {
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
        [_messages addObject:message];
        [self.collectionView reloadData];
    }];
}

-(NSMutableArray *)retrieveUsersInChatRoom {

    FIRDatabaseReference *userprofileRef = [[[FIRDatabase database]reference]child:@"userprofile"];
    [userprofileRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        
        _userProfile = [[UserProfile alloc]initUserProfileWithEmail:snapshot.value[@"email"] username:snapshot.value[@"username"] uid:snapshot.value[@"userId"]];
        _userProfile.profileImageDownloadURL = snapshot.value[@"profilePhotoDownloadURL"];
        [_userProfiles addObject:_userProfile];
    }];
    return _userProfiles;
}

-(void)setUpAvatarImages:(NSString *)senderId image:(UIImage *)image incoming:(BOOL)incoming {
    double diameter;

    if (incoming == TRUE) {
        diameter = self.collectionView.collectionViewLayout.incomingAvatarViewSize.width;
    } else {
        diameter = self.collectionView.collectionViewLayout.outgoingAvatarViewSize.width;
    }

    JSQMessagesAvatarImage *avatarImage = [JSQMessagesAvatarImageFactory
                                           avatarImageWithImage:image
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

-(JSQMessagesAvatarImage *)setPlaceHolderAvatars:(NSString *)senderDisplayName {

 JSQMessagesAvatarImage *placeholderAvatarImage = [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:[senderDisplayName substringToIndex:1] backgroundColor:[UIColor blackColor] textColor:[UIColor whiteColor] font:[UIFont systemFontOfSize:12] diameter:self.collectionView.collectionViewLayout.incomingAvatarViewSize.width];
    
    return placeholderAvatarImage;
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
    NSLog(@"photo taking starts");
}

- (void)chooseFromGallery{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    [imagePicker setDelegate:self];
    [self presentViewController:imagePicker animated:NO completion:nil];
    NSLog(@"photo choosing starts");
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    resizedImg = [self reduceImageSize:image];
    [self dismissViewControllerAnimated:YES completion:nil];
//    self.inputToolbar.contentView.textView.text = @"badbad";
}


-(UIImage *)reduceImageSize:(UIImage *)image {
    NSLog(@"ORIGINAL IMAGE: width-%f, height-%f", image.size.width, image.size.height);
    //creating a frame
    CGSize newSize = CGSizeMake(image.size.width/6, image.size.height/6);
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
    //Where to the frame the new painting is going to be placed
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    resizedImg = UIGraphicsGetImageFromCurrentImageContext();
    NSLog(@"SMALL IMAGE: width-%f, height-%f", resizedImg.size.width, resizedImg.size.height);
    return resizedImg;
}

-(void)firebaseSetUp {
    _firebaseStorage = [FIRStorage storage];
    _firebaseStorageRef = [_firebaseStorage referenceForURL:@"gs://wire-e0cde.appspot.com"];
}

-(void)uploadPhotoToFirebase:(NSData *)imageData {
    
    //Create a uniqueID for the image and add it to the end of the images reference.
    NSString *uniqueID = [[NSUUID UUID]UUIDString];
    NSString *newImageReference = [NSString stringWithFormat:@"images/%@.jpg", uniqueID];
    //imagesRef creates a reference for the images folder and then adds a child to that folder, which will be every time a photo is taken.
    FIRStorageReference *imagesRef = [_firebaseStorageRef child:newImageReference];
    //This uploads the photo's NSData onto Firebase Storage.
    FIRStorageUploadTask *uploadTask = [imagesRef putData:imageData metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error) {
        if (error) {
            NSLog(@"ERROR: %@", error.description);
        } else {
            imageURL = [NSString stringWithFormat:@"%@", metadata.downloadURL];
        }
    }];
    [uploadTask resume];
}



@end
