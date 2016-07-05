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


@end

@implementation ChatViewController

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

//-(UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
//    
//    JSQMessage *message = _messages[indexPath.row];
//
//    return cell;
//}

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

//-(JSQMessagesAvatarImage *)avatarImageWithImage:(UIImage *)image diameter:(NSUInteger)diameter {
//    
//    JSQMessagesAvatarImage *avatar = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"default_user"] diameter:5.0];
//    
//    return avatar;
//}

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
        NSLog(@"RESPONSE ************************ %@", responseData);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Error: %@", error);

    }];

}

@end
