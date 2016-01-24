//
//  VideoDownload.swift
//  table_template
//
//  Created by Shuchen Du on 2015/10/12.
//  Copyright (c) 2015年 Shuchen Du. All rights reserved.
//

import UIKit

class VideoDownload: NSObject, NSURLSessionDelegate,
    NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate {

    var session: NSURLSession!
    
    // identifier for background session configuration
    var configurationIdentifier: String {
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        // key to the identifier
        let key = "configurationIdentifier"
        let previousValue = userDefaults.stringForKey(key) as String?
        
        if let thePreviousValue = previousValue {
            
            return previousValue!
        } else {
            
            let newValue = NSDate().description
            userDefaults.setObject(newValue, forKey: key)
            userDefaults.synchronize()
            return newValue
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
                
    }
    
    init(coder aDecoder: NSCoder!) {
        
        super.init(coder: aDecoder)
        
        /* Create our configuration first */
        let configuration =
            NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(configurationIdentifier)
        configuration.timeoutIntervalForRequest = 15.0
        
        /* Now create a session that allows us to create the tasks */
        session =
            NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    /* Just a little method to help us display alert dialogs to the user */
    func displayAlertWithTitle(title: String, message: String) {
        
        let controller =
            UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        controller.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(controller, animated: true, completion: nil)
    }

}
