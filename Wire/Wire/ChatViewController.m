//
//  ChatViewController.m
//  Wire
//
//  Created by DetroitLabs on 6/27/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import "ChatViewController.h"
@import FirebaseDatabase;

@interface ChatViewController ()
@property (nonatomic, strong) NSMutableArray *messages;
@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //THESE ARE ONLY FOR TESTING SO APP WON'T CRASH!
    self.senderId = @"3252646";
    self.senderDisplayName = @"user1";
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//Send Button Pressed.
-(void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date {
   
    NSString *timestamp = [NSString stringWithFormat:@"%@", date];
    NSDictionary *message = @{@"text": text, @"senderId": senderId, @"senderName": senderDisplayName, @"timestamp":timestamp};
    [self sendMessageToFirebase:message];
}

//Number of items in section
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_messages count];
}

#pragma mark Firebase Methods

-(void)sendMessageToFirebase:(NSDictionary *)message {
    FIRDatabaseReference *messagesRef = [[[[FIRDatabase database]reference]child:@"messages"]childByAutoId];
    [messagesRef setValue:message];
}

@end
