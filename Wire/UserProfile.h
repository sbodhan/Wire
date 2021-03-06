//
//  UserProfile.h
//  Wire
//
//  Created by Sarmila on 6/28/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UserProfile : NSObject
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *uid;
@property (strong, nonatomic) NSMutableArray *userProfileArray;
@property (strong, nonatomic) NSString *profileImageDownloadURL;
@property (strong, nonatomic) UIImage *profileImage;

-(instancetype)initUserProfileWithEmail:(NSString *)email username:(NSString *)username uid:(NSString *)uid;

@end
