//
//  ContainerViewController.swift
//  table_template
//
//  Created by Shuchen Du on 2015/10/07.
//  Copyright (c) 2015年 Shuchen Du. All rights reserved.
//

import UIKit
import CoreData

class ContainerViewController: UIViewController {
    
    @IBOutlet weak var containerVisualView: UIVisualEffectView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var videoCollectionView: UICollectionView!
    @IBOutlet weak var underLabel: UILabel!
    
    var videoMaps: NSMutableArray!
    var videoJson: UNIJsonNode!
    
    var videoTitle: String!
    var videoFormat: String!
    var videoSize: String!
    var videoDuration: String!
    var originalUrl: String!
    var _originalUrl: String!
    let defaultResume = "default resume".dataUsingEncoding(NSUTF8StringEncoding)!
    var videoID: String!
    var videoImgUrlStr: String!
    
    var cellBackgroundColor: UIColor!
    var hilightedCellBackgroundColor = UIColor(
        red: 255/255.0, green: 52/255.0, blue: 179/255.0, alpha: 1)
    
    var url: NSURL!
    var manager: NSFileManager!
    var urlOfDocumentFolder: NSURL!
    var urlOfVideoFolder: NSURL!
    var urlOfImgFolder: NSURL!
    
    var session: NSURLSession!
    var configuration: NSURLSessionConfiguration!

    
    var appDelegate: AppDelegate!
    var managedContext: NSManagedObjectContext!
    var entityVideoData: String!
    
    // recover unfinished download
    func recoverDownload() {
        
        let error: NSError?
        var videoArr: [VideoData]
        
        // fetch existing videos from core data
        let fetchRequest = NSFetchRequest(entityName: entityVideoData)
        videoArr = (try! managedContext.executeFetchRequest(fetchRequest)) as! [VideoData]
        
        // error happens
        if let theErr = error {
        } else {
            if videoArr.count > 0 {
                for v in videoArr {

                    if v.resumeData != self.defaultResume {

                        let task = session.downloadTaskWithResumeData(v.resumeData)
                        task.resume()
                    }
                }
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //recoverDownload()
    }
    
    // session operation
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // invalidate session if no tasks exist
        session.finishTasksAndInvalidate()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // kick off session
        let configurationIdentifier = NSDate().description
        configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(configurationIdentifier)
        configuration.timeoutIntervalForRequest = 15.0
        session = NSURLSession(configuration:
            configuration, delegate: self, delegateQueue: nil)
        
        underLabel.hidden = true
    }
    
    // init
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        // file manager
        manager = NSFileManager()
        
        // url of Document folder
        var error: NSError?
        urlOfDocumentFolder =
            try! manager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask,
                appropriateForURL: nil, create: true)
        
        if let theErr = error {
            print("cannot get the url of Document folder: \(theErr.description))")
        }
        
        // url of video folder
        urlOfVideoFolder =
            urlOfDocumentFolder.URLByAppendingPathComponent("videos", isDirectory: true)
        if !manager.fileExistsAtPath(urlOfVideoFolder.path!) {
            
            do {
                // create video folder
                try manager.createDirectoryAtURL(urlOfVideoFolder, withIntermediateDirectories: true,
                    attributes: nil)
            } catch let error1 as NSError {
                error = error1
            }
            
            if let theErr = error {
                print("cannot create video folder: \(theErr.description)")
            }
        }
        
        // url of image folder
        urlOfImgFolder =
            urlOfDocumentFolder.URLByAppendingPathComponent("imgs", isDirectory: true)
        if !manager.fileExistsAtPath(urlOfImgFolder.path!) {

            do {
                // create image folder
                try manager.createDirectoryAtURL(urlOfImgFolder, withIntermediateDirectories: true,
                    attributes: nil)
            } catch let error1 as NSError {
                error = error1
            }
            if let theErr = error {
                print("cannot create image folder: \(theErr.description)")
            }
        }
        
        // init core data
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext
        entityVideoData = NSStringFromClass(VideoData.classForCoder())
    }
    
    // video json download
    func downloadVideoJSON() {
        
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_async(queue, {
            
            dispatch_sync(queue, {
                
                self.videoJson = FetchVideo.fetch(self.videoID)
                
                if self.videoJson == nil {
                    print("json nil 1")
                    return
                }
                
                self.videoTitle = self.videoJson.object["title"] as? String
                
                self.videoImgUrlStr = self.videoJson.object["img"] as! String
                
                if let map = self.videoJson.object["map"] as? NSArray {
                
                    self.videoMaps = map.mutableCopy() as! NSMutableArray
                    
                } else {
                    
                    return
                }
                
                // remove "0B" items from videoMaps
                for v in self.videoMaps {
                    
                    let size = v.objectAtIndex(4) as! String
                        
                    if size == "0B" {
                            
                        self.videoMaps.removeObject(v)
                    }
                }
            })
            
            dispatch_sync(dispatch_get_main_queue(), {
                
                self.indicator.stopAnimating()
                self.indicator.hidden = true
                
                if self.videoJson == nil {
                    print("json nil 2")
                    return
                }
                
                self.updateLabelText()
                self.videoCollectionView.reloadData()
                
            })
        })
    }
    
    // display alert dialog on the top view controller
    func displayAlertWithTitle(title: String, message: String) {
                    
        let controller =
            UIAlertController(title: title, message: message, preferredStyle: .Alert)
                    
        controller.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        
        var topVC = UIApplication.sharedApplication().keyWindow?.rootViewController
        
        while let preVC = topVC?.presentedViewController {
            topVC = preVC
        }
        
        topVC!.presentViewController(controller, animated: true, completion: nil)
    }
    
    // update the label above collection view
    func updateLabelText() {
        
        if label.hidden {
            label.hidden = false
        }
        
        if videoMaps == nil || videoMaps.count == 0 {
            
            label.text = "No videos available"
            
        } else {
            
            label.text = "\(videoMaps.count) video files available"
            underLabel.hidden = false
        }
    }
    
}

// collection view extension
extension ContainerViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    // cells in collection view
    func collectionView(collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
            
            if self.videoMaps == nil {
                return 0
            } else {
                
                return self.videoMaps.count
            }
    }
    func getVideoFormat(row: Int) -> String {
        let videoType = self.videoMaps.objectAtIndex(row).objectAtIndex(0) as? String
        let type = videoType?.componentsSeparatedByString("/")
        return type![1]
    }
    func getVideoSize(row: Int) -> String {
        let size = self.videoMaps.objectAtIndex(row).objectAtIndex(4) as! String
        return size
    }
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
            let videoCell = self.videoCollectionView.dequeueReusableCellWithReuseIdentifier("videoCell", forIndexPath: indexPath) as! MyVideoCell
        
            if self.videoMaps != nil {
                
                // video type and size
                videoCell.videoTypeLabelView.text = getVideoFormat(indexPath.row)
                videoCell.videoSizeLabelView.text = self.videoMaps.objectAtIndex(indexPath.row).objectAtIndex(4) as? String
            }
        
            return videoCell
    }
    
    // (un)highlight background color update
    func collectionView(collectionView: UICollectionView,
        didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        
            let highlightedCell =
                collectionView.cellForItemAtIndexPath(indexPath)
            
            self.cellBackgroundColor = highlightedCell?.backgroundColor
            highlightedCell?.backgroundColor = self.hilightedCellBackgroundColor
            
    }
    func collectionView(collectionView: UICollectionView,
        didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        
            let highlightedCell =
                collectionView.cellForItemAtIndexPath(indexPath)
            
            highlightedCell?.backgroundColor = self.cellBackgroundColor
    }
    
    // download selected
    func alreadyDownloaded() -> Bool {
        
        let error: NSError?
        var videoArr: [VideoData]
        
        // fetch existing videos from core data
        let fetchRequest = NSFetchRequest(entityName: entityVideoData)
        videoArr = (try! managedContext.executeFetchRequest(fetchRequest)) as! [VideoData]
        
        // error happens
        if let theErr = error {
            print("cannot fetch video info from core data: \(theErr.description)")
            return true
        } else {
            if videoArr.count > 0 {
                for v in videoArr {
                    if v.title == self.videoTitle &&
                        v.format == self.videoFormat && v.size == self.videoSize {
                        // dupilication found
                        return true
                    }
                }
            }
            return false
        }
    }
    func collectionView(collectionView: UICollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
            // video url and format
            let videoUrl = self.videoMaps.objectAtIndex(indexPath.row).objectAtIndex(2) as! String
            self.videoFormat = getVideoFormat(indexPath.row)
            self.videoSize = getVideoSize(indexPath.row)
            
            // check duplication in core data
            if alreadyDownloaded() {
                displayAlertWithTitle("OK", message: "the video is already downloaded")
                return
            }
            
            // download video and image
            self.downloadVideoFile(videoUrl)
            self.downloadImgFile(self.videoImgUrlStr)
    }
}

// download extension
extension ContainerViewController: NSURLSessionDelegate,
    NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate {
    
    // download video and image
    func downloadVideoFile(videoURL: String) {

        url = NSURL(string: videoURL)
        let task = session.downloadTaskWithURL(url!)
        task.resume()
    }
    func downloadImgFile(imgURL: String) {
        
        url = NSURL(string: imgURL)
        let task = session.downloadTaskWithURL(url!)
        task.resume()
    }
    
    func removeCancelledData() {
        
    }
    func cancelCompHandler(dataTasks: [AnyObject]!, upTasks: [AnyObject]!, downTasks: [AnyObject]!) {
        
        for v in downTasks {
            let task = v as! NSURLSessionDownloadTask
            let url = task.originalRequest!.URL?.absoluteString

            if url == self._originalUrl {
                
                task.cancel()
                // remove the corresponding item in core data & files
                removeCancelledData()
            }
        }
    }
    func cancelUnfinishedTask(notif: NSNotification) {
        let url = notif.userInfo!["originalUrl" ] as! String
        self._originalUrl = url
        //session.getTasksWithCompletionHandler(cancelCompHandler)
    }
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64){
    
        let d = Double(totalBytesWritten)
        let e = Double(totalBytesExpectedToWrite)
        
        // ~1.0 in double
        let p = d / e

        // video download task
        if downloadTask.taskIdentifier % 2 == 1 {
            
            // insert to core data
            if !alreadyDownloaded() {
                self.originalUrl = downloadTask.originalRequest!.URL?.absoluteString
                
                saveToCoreData()
            }
            
            // send notification of current condition
            let notif = NSNotification(name: "videoDownloadPercentNotif",
                object: self,
                userInfo: ["percent": p,
                    "title": videoTitle,
                    "format": videoFormat,
                    "size": videoSize
                ])
            NSNotificationCenter.defaultCenter().postNotification(notif)
            
            // observe cancel notification
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "cancelUnfinishedTask:", name: "cancelUnfinishedTask", object: nil)
            
        }
        
    }
    
    // error check when completed
    func insertResumeDataToCoreData(resumeData: NSData) {
        
        let error: NSError?
        var videoArr: [VideoData]
        
        // fetch existing videos from core data
        let fetchRequest = NSFetchRequest(entityName: entityVideoData)
        videoArr = (try! managedContext.executeFetchRequest(fetchRequest)) as! [VideoData]
        
        // error happens
        if let _ = error {
        } else {
            if videoArr.count > 0 {
                for v in videoArr {
                    if v.title == self.videoTitle &&
                        v.format == self.videoFormat && v.size == self.videoSize {
                            // insert
                            v.resumeData = resumeData
                            do {
                                try managedContext!.save()
                            } catch _ {
                                print("cannot save resume data to core data")
                            }
                            break
                    }
                }
            }
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask,
        didCompleteWithError error: NSError?) {
        
        print("Finished ", terminator: "")
            
        if error == nil {
            
            print("without an error")
            
        } else {
            
            // save the resume data to core data
            if let _ = error?.userInfo {
            }
        }
    }
    
    // save to file system and core data when succeeded
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        var destUrl: NSURL!
        let taskID = downloadTask.taskIdentifier
        let comp = self.videoTitle + "_"  +  self.videoSize + "." + self.videoFormat
        var messageOK = ""
        var messageFail = ""

        // form the url of downloaded files
        if taskID % 2 == 1 {
            // video task
            destUrl = urlOfVideoFolder.URLByAppendingPathComponent(comp)
            messageOK = "successfully download video " + self.videoTitle
            messageFail = "cannot download video " + self.videoTitle

        } else if taskID % 2 == 0 {
            // image task
            destUrl = urlOfImgFolder.URLByAppendingPathComponent(comp)
            messageOK = "successfully download thumbnail " + self.videoTitle
            messageFail = "cannot download thumbnail " + self.videoTitle
        }
        
        // move to file system
        var error: NSError?
        do {
            try manager.moveItemAtURL(location, toURL: destUrl)
            // alert success message
            displayAlertWithTitle("OK", message: messageOK)
        } catch let error1 as NSError {
            error = error1
            
            if let _ = error {
                //println("cannot move downloaded file with task \(taskID): \(error?.description)")
                displayAlertWithTitle("OK", message: messageFail)
            }
        }
        
        
    }

}

// core data extension
extension ContainerViewController {
    
    // save video title, duration and format to core data
    func saveToCoreData() {

        // error
        var error: NSError?
        
        // insert video object to context
        let video = NSEntityDescription.insertNewObjectForEntityForName(entityVideoData,
            inManagedObjectContext: managedContext!) as! VideoData
        
        // send values to video object
        video.title = self.videoTitle
        video.format = self.videoFormat
        video.size = self.videoSize
        video.duration = self.videoDuration
        video.resumeData = self.defaultResume
        video.originalUrl = self.originalUrl

        do {
            try managedContext!.save()
            print("Successfully saved in core data")
        } catch let error1 as NSError {
            error = error1
            if let theErr = error {
                print("Failed to save the new video. Error = \(theErr.description)")
            }
        }
    }
}
