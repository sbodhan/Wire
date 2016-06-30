//
//  UserProfile.h
//  Wire
//
//  Created by Sarmila on 6/28/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserProfile : NSObject
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *uid;
@property (strong, nonatomic) NSMutableArray *userProfileArray;
@property (strong, nonatomic) NSString *profileImageDownloadURL;

-(instancetype)initUserProfile:(NSString *)email :(NSString *)username :(NSString *)uid;

@end
