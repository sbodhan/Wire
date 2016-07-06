//
//  Message.m
//  Wire
//
//  Created by Sarmila on 6/28/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import "Message.h"

@implementation Message
-(instancetype)initMessage:(NSString *)timeStamp :(NSString *)text :(NSString *)uid{
    self = [super init];
    
    if (self) {
        _timeStamp = timeStamp;
        _text = text;
        _uid = uid;
    }

    return self;
}

-(instancetype)initPhotoWithDownloadURL:(NSString *)downloadURL andTimestamp:(NSString *)timeStamp {
    self = [super init];
    if (self) {
        _downloadURL = downloadURL;
        _timeStamp = timeStamp;
    }
    return self;
}
@end
