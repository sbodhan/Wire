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
@import FirebaseDatabase;
@import FirebaseAuth;

@interface ChatViewController ()
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) JSQMessagesBubbleImage *outgoingBubbleImage;
@property (nonatomic, strong) JSQMessagesBubbleImage *incomingBubbleImage;
@property (nonatomic, strong) NSMutableArray *avatars;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self retrieveMessagesFromFirebase];
    [self JSQMessageBubbleSetup];
    _messages = [[NSMutableArray alloc]init];
    _avatars = [[NSMutableArray alloc]init];

    //THESE ARE ONLY FOR TESTING SO APP WON'T CRASH!
    self.senderId = @"325222222";
    self.senderDisplayName = @"user1";
    
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

//AvatarImageData for item at indexPath **this is the avatarImage that needs to be supplied for each text** - REQUIRED
-(id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UIImage *avatarImage = [UIImage imageNamed:@"default_user"];
    
    JSQMessagesAvatarImage *avatar = [JSQMessagesAvatarImage avatarWithImage:avatarImage];
    [_avatars addObject:avatar];
    
    return avatar;
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
         
        [_messages addObject:message];
         
        [self.collectionView reloadData];
    }];
}

@end
