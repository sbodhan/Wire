//
//  Message.h
//  Wire
//
//  Created by Sarmila on 6/28/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Message : NSObject

@property (strong, nonatomic) NSString *timeStamp;
@property (strong,nonatomic) NSString *text;
@property (strong,nonatomic) NSString *sender;
@property (strong,nonatomic) NSString *uid;
-(instancetype)initMessage:(NSString *)timeStamp :(NSString *)text :(NSString *)uid;



@end
