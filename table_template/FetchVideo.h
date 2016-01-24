//
//  FetchVideo.h
//  table_template
//
//  Created by Shuchen Du on 2015/10/04.
//  Copyright (c) 2015年 Shuchen Du. All rights reserved.
//

#ifndef table_template_FetchVideo_h
#define table_template_FetchVideo_h

#import <Foundation/Foundation.h>
#import "UNIRest.h"

@interface FetchVideo : NSObject {
    // Protected instance variables (not recommended)
}


@property UNIUrlConnection *asyncConnection;
+ (UNIJsonNode *)fetch: (NSString *)videoID;
+ (UNIJsonNode *)fetch_async: (NSString *)videoID;

@end

#endif
