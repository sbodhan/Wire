//
//  ChatViewController.h
//  Wire
//
//  Created by DetroitLabs on 6/27/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSQMessagesViewController.h"
#import "UserProfile.h"

@interface ChatViewController : JSQMessagesViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property(strong, nonatomic) UserProfile *currentUserProfile;

@end
