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
    
    }
    
    return self;
}

@end
