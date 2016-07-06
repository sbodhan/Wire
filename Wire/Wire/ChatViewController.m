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
#import "JSQMessagesCollectionViewCell.h"
#import "NSString+JSQMessages.h"
#import "UIImageView+AFNetworking.h"
#import "AFNetworking.h"
@import FirebaseDatabase;
@import FirebaseAuth;
@import FirebaseStorage;

@interface ChatViewController ()
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) JSQMessagesBubbleImage *outgoingBubbleImage;
@property (nonatomic, strong) JSQMessagesBubbleImage *incomingBubbleImage;
@property (nonatomic, strong) NSMutableDictionary *avatars;
@property (nonatomic, strong) UserProfile *userProfile;
@property (nonatomic, strong) NSMutableArray *userProfiles;
@property (nonatomic, strong) NSString *profilePhotoDownloadURL;
@property (nonatomic, strong) FIRStorageReference *firebaseStorageRef;
@property (nonatomic, strong) FIRStorage *firebaseStorage;

@end

@implementation ChatViewController
NSData *localfile;

- (void)viewDidLoad {
    [self setJSQsenderIdAndDisplayName];
    [super viewDidLoad];
    [self retrieveUsersInChatRoom];
    [self retrieveMessagesFromFirebase];
    [self JSQMessageBubbleSetup];
    _messages = [[NSMutableArray alloc]init];
    _avatars = [[NSMutableDictionary alloc]init];
    
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

-(void)setJSQsenderIdAndDisplayName {
    self.senderId = [FIRAuth auth].currentUser.uid;
    if (_currentUserProfile == nil) {
        self.senderDisplayName = @"User";
    } else {
        self.senderDisplayName = _currentUserProfile.username;
    }
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
                             //Do some thing here
                             UIImage *image = [UIImage imageNamed:@"car4.jpg"];
                             localfile =  UIImageJPEGRepresentation(image, .50);
                             [self uploadPhotoToFirebase:localfile];
                             
                             [view dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Take a photo"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [view dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    
    
    [view addAction:ok];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}

-(void)uploadPhotoToFirebase:(NSData *)imageData{
    NSLog(@"UPLOAD PHOTO TO FIREBASE");
    
        NSString *fileName = @"car4.jpg";
        FIRStorage *storage = [FIRStorage storage];
        FIRStorageReference *storageRef = [storage referenceForURL:@"gs://wire-e0cde.appspot.com"];
        FIRStorageReference *imageRef = [storageRef child:@"images/car4.jpg"];
        FIRStorageUploadTask *uploadTask = [imageRef putData:imageData metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error){
            if(error){
                NSLog(@"ERROR&&&&&&&&&&&&&&&&= %@", error.description);
            }
    
            else{
                NSURL *downloadURL = metadata.downloadURL;
                NSLog(@"DOWNLOADURL &&&&&&&&&&&&&&=%@", downloadURL);
                NSString *photoTimeStamp = [self createFormattedTimeStamp];
                NSLog(@"############photoTimeStamp=%@", photoTimeStamp);
                Message *photo = [[Message alloc]initPhotoWithDownloadURL:[NSString stringWithFormat:@"%@", metadata.downloadURL] andTimestamp:photoTimeStamp];

                NSLog(@"PHOTO=%@", photo.timeStamp);
                [self savePhotoObjectToFirebaseDatabase:photo];
    
                
            }
        }];
    NSLog(@"************************MARK**********************");
    [uploadTask resume];
}

-(void)savePhotoObjectToFirebaseDatabase:(Message *)photo {
    NSLog(@"SAVE PHOTO TO DATABASE");
    
   //  NSString *photoName = @"car4.jpg";
    FIRDatabaseReference *fireDatabaseRef = [[FIRDatabase database] reference];
    FIRDatabaseReference *photosDatabaseRef = [fireDatabaseRef child:@"photos"].childByAutoId;
    NSLog(@"PHOTO DOWNLOADURL **********************=%@", photo.downloadURL);
    NSLog(@"PHOTO TIMESTAMP &&&&&&&&&&&&&&&&&=%@", photo.timeStamp);
    NSDictionary *photoDict = @{@"downloadURL": photo.downloadURL, @"timestamp": photo.timeStamp};
 
    
    NSLog(@"PHOTO DICT=%@", photoDict.description);
    [photosDatabaseRef setValue:photoDict];
}

#pragma mark Timestamp and Date Formatter Methods
-(NSString *)createFormattedTimeStamp {
    NSLog(@"CREATE FORMATTED TIMESTAMP");
    NSDate *timestamp = [NSDate date];
    NSLog(@"TIMESTAMP ##############= %@", timestamp);
    NSString *stringTimestamp = [self formatDate:timestamp];
    NSLog(@"STRINGTIMESTAMP################= %@", stringTimestamp);
    return stringTimestamp;
}


-(NSString *)formatDate:(NSDate *)date {
    NSLog(@"FORMAT DATE");
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"MM/dd/YYYY HH:mm:ss"];
    NSString *formattedDate = [dateFormatter stringFromDate:date];
     NSLog(@"FORMAT DATE################= %@", formattedDate);
    return formattedDate;
}

@end
