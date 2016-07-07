//
//  Message.h
//  Wire
//
//  Created by Sarmila on 6/28/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSQMessagesViewController.h"
#import "JSQMessagesAvatarImage.h"
#import "JSQMessage.h"

@interface Message : JSQMessage

@property (strong, nonatomic) JSQMessagesAvatarImage *avatarImage;


@end
