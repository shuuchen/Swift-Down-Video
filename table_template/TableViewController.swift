//
//  TableViewController.swift
//  table_view
//
//  Created by Shuchen Du on 2015/09/05.
//  Copyright (c) 2015年 Shuchen Du. All rights reserved.
//

import UIKit
import CoreData

func formatDuration(var duration: String) -> String {
    
    duration = duration.stringByReplacingOccurrencesOfString("H", withString: ":", options: [], range: nil)
    duration = duration.stringByReplacingOccurrencesOfString("M", withString: ":", options: [], range: nil)
    duration = duration.stringByReplacingOccurrencesOfString("S", withString: "", options: [], range: nil)
    duration = duration.stringByReplacingOccurrencesOfString("PT", withString: "", options: [], range: nil)
    
    var elements = split(duration) {$0 == ":"}
    
    var lastElement = elements.last
    
    if lastElement!.toInt() < 10 {
        
        var elementWithZeroPrefix = "0" + lastElement!
        
        elements[elements.count - 1] = elementWithZeroPrefix
        
        duration = ""
        
        for var i = 0; i < elements.count; i++ {
            
            duration += elements[i]
            
            if i != elements.count - 1 {
                
                duration += ":"
            }
        }
    }
    
    if elements.count == 1 {
        
        duration = "0:" + duration
    }
    
    return duration
}

class TableViewController: UITableViewController {
    
    let cell_id = "cell_id_0"
    var selected: String = ""
    let fileManager = NSFileManager()
    
    var isVideoOrImgFolderExists: Bool!
    var videoArr: [VideoData]? = []
    
    var appDelegate: AppDelegate!
    var managedContext: NSManagedObjectContext!
    var entityVideoData: String!
    
    // urls of video and image folders
    var urlOfDocumentFolder: NSURL {
        var error: NSError?
        var url = fileManager.URLForDirectory(.DocumentDirectory,
            inDomain: .UserDomainMask,
            appropriateForURL: nil,
            create: true,
            error: &error)!
    
        if let theErr = error {
            print("[TableViewController]cannot get the url of document folder: \(theErr.description)")
        }
        
        return url
    }
    var urlOfVideoFolder: NSURL {
        return urlOfDocumentFolder.URLByAppendingPathComponent("videos",
            isDirectory: true)
    }
    var urlOfImgFolder: NSURL {
        return urlOfDocumentFolder.URLByAppendingPathComponent("imgs",
            isDirectory: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register header and footer class
        self.tableView.registerClass(UITableViewHeaderFooterView.self,
            forHeaderFooterViewReuseIdentifier: "header")
        self.tableView.registerClass(UITableViewHeaderFooterView.self,
            forHeaderFooterViewReuseIdentifier: "footer")
        
        // init core data
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext
        entityVideoData = NSStringFromClass(VideoData.classForCoder())
    }
    
    // video info from core data
    func fetchVideoInfo() {
        // error
        var error: NSError?
        
        // create a fetch request
        let fetchRequest = NSFetchRequest(entityName: entityVideoData)
        
        // execute fetch
        videoArr = managedContext.executeFetchRequest(fetchRequest, error: &error) as? [VideoData]
        
        // check the array
        if let theErr = error {
            print("[TableViewController]cannot fetch video info from core data: \(theErr.description)")
        } else {
            if videoArr!.count == 0 {
                // no items found in core data
                print("[TableViewController]no items in core data")
                return
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // video or image folder does not exist
        if !fileManager.fileExistsAtPath(urlOfVideoFolder.path!) ||
           !fileManager.fileExistsAtPath(urlOfImgFolder.path!) {
            print("[TableViewController]there is no video folder")
            return
        }
        
        // video info
        fetchVideoInfo()
        
        // update table cells
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // table cells
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return videoArr!.count
    }
    
    override func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cell_id,
            forIndexPath: indexPath) as! MyCell
        
        // video info at the cell
        let video = videoArr![indexPath.row]
        let comp = video.title + "_" + video.size + "." + video.format

        // url of video and image
        let urlOfVideo = urlOfVideoFolder.URLByAppendingPathComponent(comp)
        let urlOfImg = urlOfImgFolder.URLByAppendingPathComponent(comp)
        
        // image
        if let imgData = NSData(contentsOfURL: urlOfImg) {
            cell.imgView_d.image = UIImage(data: imgData)
        } else {
            cell.imgView_d.image = UIImage(contentsOfFile: "nut")
        }
        
        cell.vidTitleLabel_d.text = video.title
        cell.duration_d.text = formatDuration(video.duration)
        cell.format_d.text = video.format
        cell.size_d.text = video.size
        
        // cell background color highlight if the real files do not exist (not fully downloaded yet)
        if !fileManager.fileExistsAtPath(urlOfVideo.path!) {
            // hot pink
            cell.backgroundColor = UIColor(red: CGFloat(255)/255.0,
                green: CGFloat(105)/255.0, blue: CGFloat(180)/255.0, alpha: 0.5)
            cell.downloaded = false
        } else {
            cell.backgroundColor = UIColor.whiteColor()
            cell.downloaded = true
        }
        
        return cell
    }
    
    // segue from table cell
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let id = segue.identifier {
            switch id {
            case "segue_cell2detail":
                
                let nvc = segue.destinationViewController as! UINavigationController
                let dvc = nvc.childViewControllers[0] as! DetailViewController
                
                if let idp = self.tableView.indexPathForCell(sender as! MyCell) {
                    
                    let comp = videoArr![idp.row].title + "_" + videoArr![idp.row].size + "." + videoArr![idp.row].format

                    dvc.videoUrl = urlOfVideoFolder.URLByAppendingPathComponent(comp)
                    
                    dvc.videoDownloaded = (sender as! MyCell).downloaded
                    dvc.backgroundImgPath =
                        urlOfImgFolder.URLByAppendingPathComponent(comp).path
                    dvc.videoTitle = videoArr![idp.row].title
                    dvc.videoFormat = videoArr![idp.row].format
                    dvc.videoSize = videoArr![idp.row].size
                }
                
            default:
                break
            }
        }
    }

    // delete handler
    override func tableView(tableView: UITableView,
        commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath) {
        
        // if not delete
        if editingStyle != UITableViewCellEditingStyle.Delete {
            return
        }
        
        // object to be deleted
        var error: NSError?
        let video = videoArr![indexPath.row]
        let comp = video.title + "_" + video.size + "." + video.format
            
        // notify the session to cancel the unfinished task
        let notif = NSNotification(name: "cancelUnfinishedTask",
            object: self,
            userInfo: [
                "originalUrl": video.originalUrl
            ])
            
        NSNotificationCenter.defaultCenter().postNotification(notif)
            
        // delete from video and image folders
        let videoUrlToDelete = urlOfVideoFolder.URLByAppendingPathComponent(comp)
        
        if fileManager.fileExistsAtPath(videoUrlToDelete.path!) {
            if !fileManager.removeItemAtURL(videoUrlToDelete, error: nil) {
                print("cannot delete from video folder: \(videoUrlToDelete)")
            }
        } else {
            print("no such video in the folder")
        }
        
        let imgUrlToDelete = urlOfImgFolder.URLByAppendingPathComponent(comp)
        if fileManager.fileExistsAtPath(imgUrlToDelete.path!)
        {
            if !fileManager.removeItemAtURL(imgUrlToDelete, error: nil) {
                print("cannot delete from image folder: \(imgUrlToDelete)")
            }
        } else {
            print("no such img in the folder")
        }
        
        // delete from core data and save
        managedContext.deleteObject(video)
        managedContext.save(error)
        
        // error happens
        if let theErr = error {
            print("[TVC]cannot delete from core data")
        }
        
        // video info
        fetchVideoInfo()
        
        // update table
        self.tableView.reloadData()
    }
    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String! {
        return "delete"
    }
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}

