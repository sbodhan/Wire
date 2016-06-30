//
//  UserProfile.m
//  Wire
//
//  Created by Sarmila on 6/28/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import "UserProfile.h"

@implementation UserProfile

-(instancetype)initUserProfileWithEmail:(NSString *)email username:(NSString *)username uid:(NSString *)uid {
    self = [super init];
    if (self){
    _email = email;
    _username = username;
    _uid = uid;
    _profileImageDownloadURL = @"https://firebasestorage.googleapis.com/v0/b/wire-e0cde.appspot.com/o/default_user.png?alt=media&token=d351d796-3f49-4f8f-8ca8-7d)1cd17f510";
    }
    
    return self;
}

@end

//Firebase Storage URL for the default user image.
//    https://firebasestorage.googleapis.com/v0/b/wire-e0cde.appspot.com/o/default_user.png?alt=media&token=d351d796-3f49-4f8f-8ca8-7d)1cd17f510

