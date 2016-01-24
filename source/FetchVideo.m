//
//  FetchVideo.m
//  table_template
//
//  Created by Shuchen Du on 2015/10/04.
//  Copyright (c) 2015年 Shuchen Du. All rights reserved.
//

#import "FetchVideo.h"

@implementation FetchVideo

// for the tutorials:
// https://github.com/Mashape/unirest-obj-c

+ (UNIJsonNode *)fetch: (NSString *)videoID {
    
    // headers
    NSDictionary *headers = @{@"X-Mashape-Key": @"T9hlKVPni0mshmL7UlDiBnWicKv3p1Yz0jtjsnMBpbkoOmKQJ7", @"Accept": @"application/json"};
    
    // url
    NSString *url = @"https://zazkov-youtube-grabber-v1.p.mashape.com/download.video.php?id=";
    url = [url stringByAppendingString: videoID];
    
    // time out
    [UNIRest timeout: 15];
    
    // sync request
    UNIHTTPJsonResponse *response = [[UNIRest post:^(UNISimpleRequest *request) {
        
        [request setUrl: url];
        [request setHeaders:headers];
    }] asJson];
    
    // return json
    return response.body;
}

+ (UNIJsonNode *)fetch_async: (NSString *)videoID {
    
    return nil;
}

@end
